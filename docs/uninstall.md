---
post_title: Uninstall
menu_order: 40
---

Run the following command from the DC/OS CLI to uninstall Spark. Alternatively, you can uninstall Spark from the DC/OS web interface. [More information about uninstalling DC/OS services](/1.8/usage/managing-services/uninstall/).

    $ dcos package uninstall --app-id=<app-id> spark
    

The Spark dispatcher persists state in Zookeeper, so to fully uninstall the Spark DC/OS package, you must go to `http://<dcos-url>/exhibitor`, click on `Explorer`, and delete the znode corresponding to your instance of Spark. By default this is `spark_mesos_Dispatcher`.