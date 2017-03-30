import logging

import shakedown
import dcos.package

# constants
STRICT_MODE_ARGS = [
    "--conf",
    "spark.mesos.driverEnv.MESOS_MODULES=file:///opt/mesosphere/etc/mesos-scheduler-modules/dcos_authenticatee_module.json",
    "--conf",
    "spark.mesos.driverEnv.MESOS_AUTHENTICATEE=com_mesosphere_dcos_ClassicRPCAuthenticatee",
    "--conf",
    "spark.mesos.principal=service-acct"]

DCOS_SPARK_RUN = "dcos --log-level=DEBUG spark --verbose run --submit-args=\"{spark_submit}\""


# functions
def requirePackage(pkg_name, options, install_required, LOGGER=None):
    if LOGGER is None:
        LOGGER = logging.getLogger(__name__)

    pkg_manager = dcos.package.get_package_manager()
    installed_pkgs = dcos.package.installed_packages(pkg_manager, None, None, False)

    if any(pkg['name'] == pkg_name for pkg in installed_pkgs):
        LOGGER.info("Package {} already installed.".format(pkg_name))
        return True
    else:
        LOGGER.info("Installing package {}".format(pkg_name))
        if install_required:
            try:
                return shakedown.install_package(pkg_name, options_json=options, wait_for_completion=True)
            except Exception:
                return False
        return False
