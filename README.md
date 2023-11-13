## Deploying a cluster with Apache Hadoop 3.3.5 + Apache Spark 3.4.1 + Apache Hive 3.1.3

This is a script that deploys a cluster with Apache Hadoop and Apache Spark (+ Apache Hive) in fully distributed mode using Docker as infrastructure.

### :rocket: How to build and run

⚠️ You should edit `.env` file in order to set several parameters for the cluster, like username and password, memory resources, and other definitions. Basically you just need to edit this file.

Suggestion: before you begin, you can pre-download Apache Hadoop, Apache Spark and/or Apache Hive by running `download.sh` script before invoking docker compose build. However, this is optional, since Dockerfile may download they automatically during building process.

#### Option 1: Hadoop + Spark + Hive 2.3.9 (builtin) + Derby as Metastore (default)

By default, this option creates three containers: one as node-master and two as worker nodes. The number of worker nodes can be changed by setting `$NODE_REPLICAS` to the desired value in `.env` file.

To build and run this option:
```
docker compose build && docker compose up 
```

#### Option 2: Hadoop + Spark + Hive 3.1.3 (external) + PostgreSQL as Metastore

By default, this option creates five containers: one as node-master, two as worker nodes, one as hive server and one as hive metastore (with postgresql). The number of worker nodes can be changed by setting `$NODE_REPLICAS` to the desired value in `.env` file, as well as other definitions regarding postgresql.

To build and run this option:
```
docker compose build && docker compose --profile hive up 
```


<!-- 
#### [manual mode] 
#### Dockerfile option

1. Build image based on Dockerfile
```
docker build --build-arg USER=spark --build-arg PASS=spark -t hadoopcluster/hadoop-spark:v4 .
```

2. Create an isolated network to run Hadoop nodes
```
docker network create --subnet=172.18.0.0/24 hadoop_network
```

3. Run Hadoop slaves (data nodes)
```
docker run -it -d --network=hadoop_network --ip 172.18.0.3 --name=slave1 --hostname=slave1 hadoopcluster/hadoop-spark:v4
docker run -it -d --network=hadoop_network --ip 172.18.0.4 --name=slave2 --hostname=slave2 hadoopcluster/hadoop-spark:v4
```

4. Run Hadoop master (name node)
```
docker run -it -p 9870:9870 -p 8088:8088 -p 18080:18080 -p 2222:22 --network=hadoop_network --ip 172.18.0.2 --name=node-master --hostname=node-master hadoopcluster/hadoop-spark:v4
```
-->
### :bulb: Tips

#### To access node-master
```
ssh -p 2222 spark@localhost
```
or
```
docker exec -it node-master /bin/bash
```

### :memo: Changelog

#### v6 - 14/05/2023
 - :sparkles: `.env` file is now read during execution time, this way allowing to change parameters without the need to rebuild the whole image from scratch. Parameters like the number of worker nodes, amount of memory RAM, nodes IP range, and others;
 - :sparkles: `/etc/hosts` and hadoop `workers` files are automatically edited according to the number of worker nodes and the IP range defined by `$NODE_REPLICAS` and `$IP_RANGE` vars in `.env`;
 - :sparkles: Hadoop config files (`core-site.xml`, `hdfs-site.xml`, `yarn-site.xml` and `mapred-site.xml`) are automatically updated during execution time according to `.env` file;
 - :sparkles: Spark config files (`spark-defaults.conf`) is automatically updated during execution time according to `.env` file;
 - :sparkles: Hive config files (`hive-site.xml`) is automatically updated during execution time according to `.env` file;
 - :sparkles: `$HADOOP_ROOT_LOGGER` var is now set to `WARN,DFRA` (in `.bashrc`) in order to reduce the number of verbose output during HADOOP deployment;
 - :package: Added `python3-pip`;
 - :package: Added `pandas` to be used by Spark MLlib;
 - :package: Added `graphframes` to be used by Spark Graphframes;
 - :package: Downgraded to Java 8, since Hive does not support Java 11;
 - :rotating_light: `$HIVEEXTERNAL` does not exist anymore;
 - :lipstick: Other minor improvements.

#### v5 - 23/04/2023 
 - :package: Updated Apache Hadoop version to 3.5.5;
 - :package: Updated Apache Spark version to 3.4.0;
 - :package: Updated Python version to 3.10;
 - :sparkles: Added `.env` file with some build environment variables as user definitions (should be edited with username and password for spark and postgres);
 - :sparkles: Slave/worker nodes were renamed to node-X (i.e.: node-1, node-2, ...);
 - :sparkles: The number of worker nodes should be defined in `.env` file by setting an integer value for `$NODE_REPLICAS`;
 - :sparkles: /data folder was renamed to /hdfs-data;
 - :sparkles: Added Hive 3.1.3 with PostgreSQL as MetastoreDB (optional, according to user preference through `$HIVEEXTERNAL` var);
 - :sparkles: Added `$HIVEEXTERNAL` env var to indicate whether to use Hive 3.1.3 (external) or Hive 2.3.9 (builtin) [set it `true` or `false`, respectively];
 - :sparkles: By default `spark-warehouse` folder is stored in HDFS;
 - :rotating_light: If using Hive builtin, derby-metastore is placed alongside user home folder (locally);
 - :rotating_light: Auto download Hadoop, Spark and Hive (if needed);
 - :lipstick: Added a `sql` folder with config files for PostgreSQL configuration as metastore of Hive;
 - :lipstick: Added sub-folders to `config_files` with specific configuration files for hadoop, spark, hive and system;
 - :lipstick: Other improvements.


### :page_facing_up: License

Copyright (c) 2023 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is free and open-source software licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE). 

`Apache Hadoop`, `Apache Spark` and `Apache Hive` are free and open-source software licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache).
