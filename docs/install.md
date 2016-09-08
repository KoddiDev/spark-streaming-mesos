---
post_title: Install
menu_order: 20
--------------



To start a basic Spark cluster, run the following command on the DC/OS
CLI. This command installs the dispatcher, and, optionally, the
history server. See [Custom Installation][7] to install the history
server.

    $ dcos package install spark

Monitor the deployment at `http://<dcos-url>/marathon`. Once it is
complete, visit Spark at `http://<dcos-url>/service/spark/`.

You can also
[install Spark via the DC/OS web interface](/usage/services/install/).
**Note:** If you install Spark via the web interface, run the
following command from the DC/OS CLI to install the Spark CLI:

    $ dcos package install spark --cli

<a name="custom"></a>

# Custom Installation

You can customize the default configuration properties by creating a
JSON options file and passing it to `dcos package install --options`.
For example, to install the history server, create a file called
`options.json`:

    {
      "history-server": {
        "enabled": true
      }
    }

Then, install Spark with your custom configuration:

    $ dcos package install --options=options.json spark

Run the following command to see all configuration options:

    $ dcos package describe spark --config

## Minimal Installation

For development purposes, you may wish to install Spark on a local
DC/OS cluster. For this, you can use [dcos-vagrant][16].

1. Install DC/OS Vagrant:

   Install a minimal DC/OS Vagrant according to the instructions
[here][16].

1. Install Spark:

        $ dcos package install spark

1. Run a simple Job:

        $ dcos spark run --submit-args="--class org.apache.spark.examples.SparkPi http://downloads.mesosphere.com.s3.amazonaws.com/assets/spark/spark-examples_2.10-1.5.0.jar"

NOTE: A limited resource environment such as DC/OS Vagrant restricts
some of the features available in DC/OS Spark.  For example, unless you
have enough resources to start up a 5-agent cluster, you will not be
able to install DC/OS HDFS, and you thus won't be able to enable the
history server.

Also, a limited resource environment can restrict how you size your
executors, for example with `spark.executor.memory`.

<a name="hdfs"></a>

## HDFS

By default, DC/OS Spark jobs are configured to read from DC/OS HDFS. To
submit Spark jobs that read from a different HDFS cluster, customize
`hdfs.config-url` to be a URL that serves `hdfs-site.xml` and
`core-site.xml`. [Learn more][8].

For DC/OS HDFS, these configuration files are served at
`http://<hdfs.framework-name>.marathon.mesos:<port>/config/`, where
`<hdfs.framework-name>` is a configuration variable set in the HDFS
package, and `<port>` is the port of its marathon app.

## HDFS Kerberos

You can access external (i.e. non-DC/OS) Kerberos-secured HDFS clusters
from Spark on Mesos.

### HDFS Configuration

Once you've set up a Kerberos-enabled HDFS cluster, configure Spark to
connect to it. See instructions [here](#hdfs).

### Installation

1.  A krb5.conf file tells Spark how to connect to your KDC.  Base64
    encode this file:

        $ cat krb5.conf | base64

1.  Add the following to your JSON configuration file to enable
Kerberos in Spark:

        {
           "security": {
             "kerberos": {
              "krb5conf": "<base64 encoding>"
              }
           }
        }

1. If you've enabled the history server via `history-server.enabled`,
you must also configure the principal and keytab for the history
server.  **WARNING**: The keytab contains secrets, so you should
ensure you have SSL enabled while installing DC/OS Spark.

    Base64 encode your keytab:

        $ cat spark.keytab | base64

    And add the following to your configuration file:

         {
            "history-server": {
                "kerberos": {
                  "principal": "spark@REALM",
                  "keytab": "<base64 encoding>"
                }
            }
         }

1.  Install Spark with your custom configuration, here called
`options.json`:

        $ dcos package install --options=options.json spark

### Job Submission

To authenticate to a Kerberos KDC, DC/OS Spark supports keytab
files as well as ticket-granting tickets (TGTs).

Keytabs are valid infinitely, while tickets can expire. Especially for
long-running streaming jobs, keytabs are recommended.

#### Keytab Authentication

Submit the job with the keytab:

    $ dcos spark run --submit-args="--principal user@REALM --keytab <keytab-file-path>..."

#### TGT Authentication

Submit the job with the ticket:

    $ dcos spark run --principal user@REALM --tgt <ticket-file-path>

**Note:** These credentials are security-critical. We highly
recommended [configuring SSL encryption][9] between the Spark
components when accessing Kerberos-secured HDFS clusters.


## History Server

DC/OS Spark includes the [Spark history server][3]. Because the history
server requires HDFS, you must explicitly enable it.

1.  Install HDFS first:

        $ dcos package install hdfs

    **Note:** HDFS requires 5 private nodes.

1.  Create a history HDFS directory (default is `/history`). [SSH into
your cluster][10] and run:

        $ hdfs dfs -mkdir /history

1.  Enable the history server when you install Spark. Create a JSON
configuration file. Here we call it `options.json`:

        {
           "history-server": {
             "enabled": true
           }
        }

1.  Install Spark:

        $ dcos package install spark --options=options.json

1.  Run jobs with the event log enabled:

        $ dcos spark run --submit-args="-Dspark.eventLog.enabled=true -Dspark.eventLog.dir=hdfs://hdfs/history ... --class MySampleClass  http://external.website/mysparkapp.jar"

1.  Visit your job in the dispatcher at
`http://<dcos_url>/service/spark/Dispatcher/`. It will include a link
to the history server entry for that job.

<a name="ssl"></a>

## SSL

SSL support in DC/OS Spark encrypts the following channels:

*   From the [DC/OS admin router][11] to the dispatcher
*   From the dispatcher to the drivers
*   From the drivers to their executors

There are a number of configuration variables relevant to SSL setup.
List them with the following command:

    $ dcos package describe spark --config

There are only two required variables:

<table class="table">
  <tr>
    <th>
      Variable
    </th>

    <th>
      Description
    </th>
  </tr>

  <tr>
    <td>
      `spark.ssl.enabled`
    </td>

    <td>
      Set to true to enable SSL (default: false).
    </td>
  </tr>

  <tr>
    <td>
      spark.ssl.keyStoreBase64
    </td>

    <td>
      Base64 encoded blob containing a Java keystore.
    </td>
  </tr>
</table>

The Java keystore (and, optionally, truststore) are created using the
[Java keytool][12]. The keystore must contain one private key and its
signed public key. The truststore is optional and might contain a
self-signed root-ca certificate that is explicitly trusted by Java.

Both stores must be base64 encoded, e.g. by:

    $ cat keystore | base64 /u3+7QAAAAIAAAACAAAAAgA...

**Note:** The base64 string of the keystore will probably be much
longer than the snippet above, spanning 50 lines or so.

With this and the password `secret` for the keystore and the private
key, your JSON options file will look like this:

    {
      "security": {
        "ssl": {
          "enabled": true,
          "keyStoreBase64": "/u3+7QAAAAIAAAACAAAAAgA...”,
          "keyStorePassword": "secret",
          "keyPassword": "secret"
        }
      }
    }

Install Spark with your custom configuration:

    $ dcos package install --options=options.json spark

In addition to the described configuration, make sure to connect the
DC/OS cluster only using an SSL connection, i.e. by using an
`https://<dcos-url>`. Use the following command to set your DC/OS URL:

    $ dcos config set core.dcos_url https://<dcos-url>

# Multiple Install

Installing multiple instances of the DC/OS Spark package provides basic
multi-team support. Each dispatcher displays only the jobs submitted
to it by a given team, and each team can be assigned different
resources.

To install mutiple instances of the DC/OS Spark package, set each
`service.name` to a unique name (e.g.: "spark-dev") in your JSON
configuration file during installation:

    {
      "service": {
        "name": "spark-dev"
      }
    }

To use a specific Spark instance from the DC/OS Spark CLI:

    $ dcos config set spark.app_id <service.name>
    
 [1]: #custom
 [2]: https://github.com/mesosphere/dcos-vagrant
 [3]: http://spark.apache.org/docs/latest/configuration.html#inheriting-hadoop-cluster-configuration
 [4]: #hdfs
 [5]: #ssl
 [6]: http://spark.apache.org/docs/latest/monitoring.html#viewing-after-the-fact
 [7]: /1.8/administration/sshcluster/
 [8]: /1.8/administration/dcosarchitecture/components/
 [9]: http://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html