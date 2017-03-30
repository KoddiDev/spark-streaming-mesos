import os

from sparkperformance import requirePackage, STRICT_MODE_ARGS, DCOS_SPARK_RUN
import sparkperformace.s3 as s3


class AbstractSparkApplication(object):
    def __init__(self, app_url, applicaion_args, strict=False, upload=True):
        """app_url <str> URL to "uber" jar containing application
           application_args List<str> arguments to give to spark-submit as --submit-args
           strict <bool> add strict-mode args
           upload <bool> need to upload the URL from local, tests to make sure this exists and that you have
               both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY set (env vars)
        """
        self.app_url  = app_url
        self.app_args = applicaion_args
        self.strict   = strict
        self.upload   = upload
        self.uploaded = False

    def getCmd():
        raise NotImplementedError

    def uploadApplicationFile(self, file_path):
        if not os.path.exists(file_path):
            return None, False
        s3.upload_file(file_path)
        self.uploaded = True
        return s3.http_url(os.path.basename(file_path))

    def requirePackages(required_pkgs):
        # type (List<(string, dict)>) where the dict is the associated options with the package
        # defined by the string
        for package, options in required_pkgs:
            ok = requirePackage(package, options)
            if not ok:
                raise RuntimeError("Error installing required package" % package)


class ScalaSparkApplication(AbstractSparkApplication):
    def __init__(self, app_url, applicaion_args, strict=False, upload=True):
        super(AbstractSparkApplication, self).__init__(app_url, applicaion_args, strict, upload)

    def getCmd(self, required_packages, driver_mem):  # TODO add more spark configure options or abstract them
        if not self.uploaded:
            self.uploadApplicationFile(self.app_url)
        self.requirePackages(required_packages)
        spark_config_args = ["--conf", "spark.driver.memory=2g"]
        if self.strict:
            spark_config_args += STRICT_MODE_ARGS

        spark_submit_args = " ".join(spark_config_args, self.app_url, self.app_args)
        return DCOS_SPARK_RUN.format(spark_submit=spark_submit_args)


class PythonSparkApplication(AbstractSparkApplication):
    def __init__(self, ):
        raise NotImplementedError


class RSparkApplication(AbstractSparkApplication):
    def __init__(self, ):
        raise NotImplementedError
