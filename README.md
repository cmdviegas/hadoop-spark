## Deploying a cluster with Apache Hadoop 3.3.5 + Apache Spark 3.4.0 + Apache Hive 3.1.3

This is a script to deploy a cluster with Apache Hadoop and Apache Spark + Apache Hive in distributed mode using Docker as infrastructure.

### :rocket: How to build/run

#### [Hadoop + Spark + Hive (builtin) + Derby as Metastore (locally)]
```
docker compose build && docker compose up 
```

#### [Hadoop + Spark + Hive (external) + PostgreSQL as Metastore (in a container)]
```
docker compose build --build-arg HIVEEXTERNAL=true && docker compose --profile hiveexternal up 
```

⚠️ You should edit `.env` file in order to set username and password for hadoop and postgresql (if needed) and also the number of worker nodes in the cluster (and other definitions too).

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

#### v5 - 23/04/2023 
 - :package: Updated Apache Hadoop version to 3.5.5;
 - :package: Updated Apache Spark version to 3.4.0;
 - :package: Updated Python version to 3.10;
 - :sparkles: Added '.env' file with some build environment variables as user definitions (should be edited with username and password for spark and postgres);
 - :sparkles: Slave/worker nodes were renamed to node-X (i.e.: node-1, node-2, ...);
 - :sparkles: The number of worker nodes should be defined in .env file by setting an integer value for '$REPLICAS';
 - :sparkles: /data folder was renamed to /hdfs-data;
 - :sparkles: Added Hive 3.1.3 with PostgreSQL as MetastoreDB (optional, according to user preference through '$HIVEEXTERNAL' var);
 - :sparkles: Added '$HIVEEXTERNAL' env var to indicate whether to use Hive 3.1.3 (external) or Hive 2.3.9 (builtin) [set it 'true' or 'false', respectively];
 - :sparkles: By default spark-warehouse folder is stored in HDFS;
 - :rotating_light: If using Hive builtin, derby-metastore is placed alongside user home folder (locally);
 - :rotating_light: Auto download Hadoop, Spark and Hive (if needed);
 - :lipstick: Added a sql folder with config files for PostgreSQL configuration as metastore of Hive;
 - :lipstick: Added sub-folders to config_files with specific configuration files for hadoop, spark, hive and system;
 - :lipstick: Other improvements.


### :page_facing_up: License

Copyright (c) 2023 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is free and open-source software licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE). 

`Apache Hadoop` and `Apache Spark` are free and open-source software licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache).
