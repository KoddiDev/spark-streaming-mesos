---
post_title: Limitations
menu_order: 100
---

*   DC/OS Spark only supports submitting jars.  It does not support
Python or R.

*   Spark jobs run in Docker containers. The first time you run a
Spark job on a node, it might take longer than you expect because of
the `docker pull`.

*   Spark shell is not supported. For interactive analytics, we
recommend Zeppelin, which supports visualizations and dynamic
dependency management.