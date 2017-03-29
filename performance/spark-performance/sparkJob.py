import os

import s3


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

    def run():
        raise NotImplementedError

    @staticmethod
    def uploadApplicationFile(file_path):
        if not os.path.exists(file_path):
            return None, False
        s3.upload_file(file_path)
        return s3.http_url(os.path.basename(file_path))

    def requirePackages(required_pkgs):



class ScalaSparkApplication(AbstractSparkApplication):
    def __init__(self, app_url, applicaion_args, strict=False, upload=True):
        super(AbstractSparkApplication)
        pass


class PythonSparkApplication(AbstractSparkApplication):
    def __init__(self, ):
        pass


class RSparkApplication(AbstractSparkApplication):
    def __init__(self, ):
        pass

