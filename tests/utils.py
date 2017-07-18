import dcos.config
import dcos.http
import dcos.package

import json
import logging
import os
import re
import requests
import s3
import shakedown
import subprocess
import urllib


def _init_logging():
    logging.basicConfig(level=logging.INFO)
    logging.getLogger('dcos').setLevel(logging.WARNING)
    logging.getLogger('requests').setLevel(logging.WARNING)


_init_logging()
LOGGER = logging.getLogger(__name__)
DEFAULT_HDFS_TASK_COUNT=10
HDFS_PACKAGE_NAME='beta-hdfs'
HDFS_SERVICE_NAME='hdfs'
SPARK_PACKAGE_NAME='spark'

# Skip HDFS tests until a version of beta-hdfs containing the fix for HDFS-461 is released.
def hdfs_enabled():
    return False
    # return os.environ.get("HDFS_ENABLED") != "false"


def is_strict():
    return os.environ.get('SECURITY') == 'strict'


def require_hdfs():
    LOGGER.info("Ensuring HDFS is installed.")

    _require_package(HDFS_PACKAGE_NAME, _get_hdfs_options())
    _wait_for_hdfs()


def require_spark(options={}, service_name=None):
    LOGGER.info("Ensuring Spark is installed.")

    _require_package(SPARK_PACKAGE_NAME, service_name, _get_spark_options(options))
    _wait_for_spark(service_name)
    _require_spark_cli()


# This should be in shakedown (DCOS_OSS-679)
def _require_package(pkg_name, service_name=None, options = {}):
    pkg_manager = dcos.package.get_package_manager()
    installed_pkgs = dcos.package.installed_packages(
        pkg_manager,
        None,
        None,
        False)

    pkg = next((pkg for pkg in installed_pkgs if pkg['name'] == pkg_name), None)
    if (pkg is not None) and (service_name is None):
        LOGGER.info("Package {} is already installed.".format(pkg_name))
    elif (pkg is not None) and (service_name in pkg['apps']):
        LOGGER.info("Package {} with app_id={} is already installed.".format(
            pkg_name,
            service_name))
    else:
        LOGGER.info("Installing package {}".format(pkg_name))
        shakedown.install_package(
            pkg_name,
            options_json=options,
            wait_for_completion=True)


def _wait_for_spark(service_name=None):
    def pred():
        dcos_url = dcos.config.get_config_val("core.dcos_url")
        path = "/service{}".format(service_name) if service_name else "service/spark"
        spark_url = urllib.parse.urljoin(dcos_url, path)
        status_code = dcos.http.get(spark_url).status_code
        return status_code == 200

    shakedown.wait_for(pred)


def _require_spark_cli():
    LOGGER.info("Ensuring Spark CLI is installed.")
    installed_subcommands = dcos.package.installed_subcommands()
    if any(sub.name == SPARK_PACKAGE_NAME for sub in installed_subcommands):
        LOGGER.info("Spark CLI already installed.")
    else:
        LOGGER.info("Installing Spark CLI.")
        shakedown.run_dcos_command('package install --cli {}'.format(
            SPARK_PACKAGE_NAME))


def _get_hdfs_options():
    if is_strict():
        options = {'service': {'principal': 'service-acct', 'secret_name': 'secret'}}
    else:
        options = {"service": {}}

    options["service"]["beta-optin"] = True
    return options


def _wait_for_hdfs():
    shakedown.wait_for(_is_hdfs_ready, ignore_exceptions=False, timeout_seconds=900)


def _is_hdfs_ready(expected_tasks = DEFAULT_HDFS_TASK_COUNT):
    return is_service_ready(HDFS_SERVICE_NAME, expected_tasks)


def is_service_ready(service_name, expected_tasks):
    running_tasks = [t for t in shakedown.get_service_tasks(service_name) \
                     if t['state'] == 'TASK_RUNNING']
    return len(running_tasks) >= expected_tasks


def _get_spark_options(options = None):
    if options is None:
        options = {}

    if hdfs_enabled():
        options["hdfs"] = options.get("hdfs", {})
        options["hdfs"]["config-url"] = "http://api.hdfs.marathon.l4lb.thisdcos.directory/v1/endpoints"

    if is_strict():
        options["service"] = options.get("service", {})
        options["service"]["principal"] = "service-acct"

        options["security"] = options.get("security", {})
        options["security"]["mesos"] = options["security"].get("mesos", {})
        options["security"]["mesos"]["authentication"] = options["security"]["mesos"].get("authentication", {})
        options["security"]["mesos"]["authentication"]["secret_name"] = "secret"


    return options


def run_tests(app_url, app_args, expected_output, args=[]):
    task_id = submit_job(app_url, app_args, args)
    check_job_output(task_id, expected_output)


def check_job_output(task_id, expected_output):
    LOGGER.info('Waiting for task id={} to complete'.format(task_id))
    shakedown.wait_for_task_completion(task_id)
    stdout = _task_log(task_id)

    if expected_output not in stdout:
        stderr = _task_log(task_id, "stderr")
        LOGGER.error("task stdout: {}".format(stdout))
        LOGGER.error("task stderr: {}".format(stderr))
        raise Exception("{} not found in stdout".format(expected_output))


def delete_secret(name):
    LOGGER.info("Deleting secret name={}".format(name))

    dcos_url = dcos.config.get_config_val("core.dcos_url")
    url = dcos_url + "secrets/v1/secret/default/{}".format(name)
    dcos.http.delete(url)


def create_secret(name, value):
    LOGGER.info("Creating secret name={}".format(name))

    dcos_url = dcos.config.get_config_val("core.dcos_url")
    url = dcos_url + "secrets/v1/secret/default/{}".format(name)
    data = {"path": name, "value": value}
    dcos.http.put(url, data=json.dumps(data))


def upload_file(file_path):
    LOGGER.info("Uploading {} to s3://{}/{}".format(
        file_path,
        os.environ['S3_BUCKET'],
        os.environ['S3_PREFIX']))

    s3.upload_file(file_path)

    basename = os.path.basename(file_path)
    return s3.http_url(basename)


def submit_job(app_url, app_args, args=[]):
    if is_strict():
        args += ["--conf", 'spark.mesos.driverEnv.MESOS_MODULES=file:///opt/mesosphere/etc/mesos-scheduler-modules/dcos_authenticatee_module.json']
        args += ["--conf", 'spark.mesos.driverEnv.MESOS_AUTHENTICATEE=com_mesosphere_dcos_ClassicRPCAuthenticatee']
        args += ["--conf", 'spark.mesos.principal=service-acct']
    args_str = ' '.join(args + ["--conf", "spark.driver.memory=2g"])
    submit_args = ' '.join([args_str, app_url, app_args])
    cmd = 'dcos --log-level=DEBUG spark --verbose run --submit-args="{0}"'.format(submit_args)

    LOGGER.info("Running {}".format(cmd))
    stdout = subprocess.check_output(cmd, shell=True).decode('utf-8')

    LOGGER.info("stdout: {}".format(stdout))

    regex = r"Submission id: (\S+)"
    match = re.search(regex, stdout)
    return match.group(1)


def _task_log(task_id, filename=None):
    cmd = "dcos task log --completed --lines=1000 {}".format(task_id) + \
          ("" if filename is None else " {}".format(filename))

    LOGGER.info("Running {}".format(cmd))
    stdout = subprocess.check_output(cmd, shell=True).decode('utf-8')
    return stdout


def is_framework_completed(fw_name):
    # The framework is not Active or Inactive
    return shakedown.get_service(fw_name, True) is None
