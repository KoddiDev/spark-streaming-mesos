### Building the streaming docker image

Install texlive using your package manager, e.g. for Linux:
```bash
# Package name may be different depending on your distro
$ sudo apt-get install texlive-core 
```

Download and extract the spark source and run the following from the root of the spark source:

```bash
# install required R dependencies
$ R -e "install.packages(c('knitr', 'rmarkdown', 'testthat', 'e1071', 'survival'), repos='http://cran.us.r-project.org')"

# Use the hadoop-2.7 profile with actual hadoop version 2.8
$ ./dev/make-distribution.sh --name spark-2.1.1-hadoop-2.8 --pip --r --tgz -Psparkr -Phadoop-2.7 -Pmesos -Dhadoop.version=2.8.0
```

Copy all files in this folder into the spark source root, where the dist folder lives after building:
```
$ cp docker/* spark-2.1.1
```

Build the docker image in the dist folder
```bash
$ cd spark-2.1.1 && docker build -t koddidev/spark:streaming-2.1.1-hadoop-2.8 .
```

Then push to the koddidev/spark dockerhub repo
```bash
$ docker push koddidev/spark:streaming-2.1.1-hadoop-2.8
```

If you have logged in in a while, you may be asked to run
```bash
$ docker login
```
