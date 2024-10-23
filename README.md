## Deploying a cluster with Apache Hadoop 3.4.x + Apache Spark 3.5.x

This is a script that deploys a cluster with Apache Hadoop and Apache Spark in fully distributed mode using Docker as infrastructure.

### :rocket: How to build and run

⚠️ Before you begin: you MUST pre-download Apache Hadoop and Apache Spark by running `download.sh` script before invoking docker compose build.

By default, it creates three containers: one node-master and two worker nodes. The number of worker nodes can be changed by setting `$NODE_REPLICAS` to the desired value in `.env` file. 

⚠️ You should edit `.env` file in order to set several parameters for the cluster, like username and password, memory resources, and other definitions. Basically you just need to edit this file.

#### To build and run this option:
```
docker compose build && docker compose up 
```

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

#### 23/10/2024 
 - :package: Updated `Apache Spark` version to 3.5.3;
 - :package: Updated `Java JDK` version to 11;
 - :package: Updated `PostgresSQL JDBC driver` to 42.7.4;
 - :package: Updated `graphframes` to 0.8.4;
 - :rotating_light: Apache Hive (external) removed from this repository; 
 - :lipstick: Folder apps now called myfiles;
 - :lipstick: Minor fixes and several optimizations.

#### 16/08/2024 
 - :package: Updated `Apache Spark` version to 3.5.2;

#### 15/04/2024 
 - :package: Updated `Apache Hadoop` version to 3.4.0;
 - :package: Updated `Apache Spark` version to 3.5.1;

#### 14/05/2023
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

#### 23/04/2023 
 - :package: Updated `Apache Hadoop` version to 3.3.5;
 - :package: Updated `Apache Spark` version to 3.4.0;
 - :package: Updated `Python` version to 3.10;
 - :sparkles: Added `.env` file with some build environment variables as user definitions (should be edited with username and password for spark and postgres);
 - :sparkles: Slave/worker nodes were renamed to node-X (i.e.: node-1, node-2, ...);
 - :sparkles: The number of worker nodes should be defined in `.env` file by setting an integer value for `$NODE_REPLICAS`;
 - :sparkles: /data folder was renamed to /hdfs-data;
 - :sparkles: Added `Hive` 3.1.3 with PostgreSQL as MetastoreDB (optional, according to user preference through `$HIVEEXTERNAL` var);
 - :sparkles: Added `$HIVEEXTERNAL` env var to indicate whether to use Hive 3.1.3 (external) or Hive 2.3.9 (builtin) [set it `true` or `false`, respectively];
 - :sparkles: By default `spark-warehouse` folder is stored in HDFS;
 - :rotating_light: If using Hive builtin, derby-metastore is placed alongside user home folder (locally);
 - :rotating_light: Auto download Hadoop, Spark and Hive (if needed);
 - :lipstick: Added a `sql` folder with config files for PostgreSQL configuration as metastore of Hive;
 - :lipstick: Added sub-folders to `config_files` with specific configuration files for hadoop, spark, hive and system;
 - :lipstick: Other improvements.

### :page_facing_up: License

Copyright (c) 2022-2025 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is free and open-source software licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE). 

`Apache Hadoop`, `Apache Spark` and `Apache Hive` are free and open-source software licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache).
