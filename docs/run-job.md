---
post_title: Run a Spark Job
menu_order: 60
---

1.  Before submitting your job, upload the artifact (e.g., jar file)
to a location visible to the cluster (e.g., S3 or HDFS). [Learn
more][13].

1.  Run the job

        $ dcos spark run --submit-args=`--class MySampleClass http://external.website/mysparkapp.jar 30`

    `dcos spark run` is a thin wrapper around the standard Spark
`spark-submit` script. You can submit arbitrary pass-through options
to this script via the `--submit-args` options.

    The first time you run a job, the CLI must download the Spark
distribution to your local machine. This may take a while.

    If your job runs successfully, you will get a message with the
job’s submission ID:

        Run job succeeded. Submission id: driver-20160126183319-0001

1.  View the Spark scheduler progress by navigating to the Spark
dispatcher at `http://<dcos-url>/service/spark/`

1.  View the job's logs through the Mesos UI at
`http://<dcos-url>/mesos/`

## Setting Spark properties

Spark job settings are controlled by configuring [Spark
properties][14]. You can set Spark properties during submission, or
you can create a configuration file.

### Submission

All properties are submitted through the `--submit-args` option to
`dcos spark run`. These are ultimately passed to the [`spark-submit`
script][13].

Certain common properties have their own special names. You can view
these through `dcos spark run --help`. Here is an example of using
`--supervise`:

    $ dcos spark run --submit-args="--supervise --class MySampleClass http://external.website/mysparkapp.jar 30`

Or you can set arbitrary properties as java system properties by using
`-D<prop>=<value>`:

    $ dcos spark run --submit-args="-Dspark.executor.memory=4g --class MySampleClass http://external.website/mysparkapp.jar 30`

### Configuration file

To set Spark properties with a configuration file, create a
`spark-defaults.conf` file and set the environment variable
`SPARK_CONF_DIR` to the containing directory. [Learn more][15].

 [1]: http://spark.apache.org/docs/latest/submitting-applications.html
 [2]: http://spark.apache.org/docs/latest/configuration.html#spark-properties
 [3]: http://spark.apache.org/docs/latest/configuration.html#overriding-configuration-directory