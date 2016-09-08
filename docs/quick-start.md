---
post_title: Quick Start
menu_order: 10
---

1.  Install DC/OS Spark via the DC/OS CLI:

        $ dcos package install spark

1.  Run a Spark job:

        $ dcos spark run --submit-args="--class org.apache.spark.examples.SparkPi http://downloads.mesosphere.com.s3.amazonaws.com/assets/spark/spark-examples_2.10-1.4.0-SNAPSHOT.jar 30"

1.  View your job:

    Visit the Spark cluster dispatcher at
`http://<dcos-url>/service/spark/` to view the status of your job.
Also visit the Mesos UI at `http://<dcos-url>/mesos/` to see job logs.