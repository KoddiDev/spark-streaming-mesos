import logging

from abstractSparkTest import AbstractSparkTest


class SimpleSparkTest(AbstractSparkTest):
    def __init__(self, spark_job, predicate, required_frameworks, LOGGER=logging.getLogger(__name__)):
        super(AbstractSparkTest, self).__init__(spark_job=spark_job, predicate=predicate)
        
