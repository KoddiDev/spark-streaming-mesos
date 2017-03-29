import logging

import dcos
import shakedown


class AbstractSparkTest(object):
    def __init__(self, spark_job, predicate, LOGGER=logging.getLogger(__name__)):
        self.spark_job = spark_job  # SparApplicaton object
        self.predicate = predicate  # function that decides whether the tests passes
        self.LOGGER    = LOGGER

    def _require_package(self, pkg_name, options=None):
        pkg_manager    = dcos.package.get_package_manager()
        installed_pkgs = dcos.package.installed_packages(pkg_manager, None, None, False)

        if any(pkg['name'] == pkg_name for pkg in installed_pkgs):
            self.LOGGER.info("Package {} already installed.".format(pkg_name))
        else:
            self.LOGGER.info("Installing package {}".format(pkg_name))
            shakedown.install_package(pkg_name,
                                      options_json=(options if options is not None else {}),
                                      wait_for_completion=True)

    def 
