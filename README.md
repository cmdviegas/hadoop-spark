## Hadoop and Spark Cluster Deployment

This script deploys a cluster with `Apache Hadoop` 3.4.x and `Apache Spark` 3.5.x in fully distributed mode using `Docker` containers as the underlying infrastructure. 

This setup is designed for teaching, experimentation, and scalable data processing tasks.

It consists of **one master node** and a configurable number of **worker nodes**, deployed over a custom Docker network.

### 🗂️ Architecture

- **1 Master Node**: `spark-master`
- **N Worker Nodes**: `worker` service (replicated via `${NUM_WORKER_NODES}`)

Worker nodes are replicated dynamically using the `deploy.mode: replicated` directive, enabling scalable execution.

### ⚙️ Resource Management and Services

The cluster uses **YARN** for resource scheduling and **HDFS** for distributed file storage. Key services per node:

#### Master Node (`spark-master`)

- **ResourceManager** (YARN)
- **NameNode** (HDFS)
- **Spark Master**
- **Exposed Ports**:
  - `9870` – HDFS Web UI
  - `8088` – YARN ResourceManager UI
  - `18080` – Spark History Server UI
  - `15002` – Spark Connect

### Worker Nodes (`worker` service)

- **DataNode** (HDFS)
- **NodeManager** (YARN)
- **Spark Worker**

All nodes share a mounted volume for data exchange and run an initialization script (`bootstrap.sh`) on startup.

## 🧱 Build Configuration

Images are built from a Dockerfile with the following build arguments:

- `SPARK_VER=${SPARK_VERSION}`
- `HADOOP_VER=${HADOOP_VERSION}`
- `USER=${CONTAINER_USERNAME}`
- `PASS=${CONTAINER_PASSWORD}`

The image is tagged as: `sparkcluster/${IMAGE_NAME}`.

## 🗃️ Volumes and Persistence

- `master_volume`: Docker named volume attached to the master node to persist user files and configuration.

All nodes also mount a shared volume:

```yaml
./myfiles:/home/${CONTAINER_USERNAME}/myfiles
```












This cluster is structured in a master-slave architecture. By default, it creates three containers: one master node and two worker nodes.

Resource management is handled by Hadoop YARN, which coordinates the execution of Spark and Hadoop jobs across the cluster. In this setup:

- The master node hosts the ResourceManager (YARN) and also acts as NameNode for the Hadoop HDFS. Additionally, it runs the NodeManager service to allow task execution locally when required.

- Each slave node functions as a DataNode in the HDFS, storing blocks of data and participating in distributed storage. They also run NodeManager instances, enabling them to execute Spark and MapReduce tasks under YARN's coordination.

- Apache Spark operates in YARN cluster mode, leveraging YARN's scheduling capabilities to manage executors dynamically across the slave nodes. 

⚠️ Note: You can adjust cluster parameters such as username, password, memory resources, and other settings by editing the `.env` file. This file is the primary configuration source for your cluster setup.

### :rocket: How to build and run

⚠️ Optional (Recommended): Before starting, it is advised to pre-download Apache Hadoop and Apache Spark by running the `download.sh` script. This step will speed up the build process.

⚠️ Note: It is advised to use Docker Compose 1.18.0 or higher to ensure compatibility.

#### To build and run this option:
```
docker compose build && docker compose up 
```

### :bulb: Tips

#### Accessing the Master Node

To access the master node:
```
docker exec -it spark-master bash
```

### :memo: Changelog

#### 29/04/2025
- :package: Updated `Apache Spark` version to 3.5.5;
- :package: Updated `Python` version to 3.11;
- :wrench: Minor fixes and optimizations.
- :clipboard: Build Summary: hadoop:3.4.1 | spark:3.5.5+2.12 | psql-jdbc42.7.5 | graphframes:0.8.4 | jdk:11 | python3.11 | ubuntu22.04

#### 18/01/2025
- :package: Updated `Apache Spark` version to 3.5.4;
- :package: Updated `PostgresSQL JDBC driver` to 42.7.5;
- :package: Added support for Spark Connect. By default it is started at port 15002/tcp;
- :wrench: Minor fixes and optimizations.

#### 07/11/2024 
 - :package: Updated `Apache Hadoop` version to 3.4.1;
 - :rotating_light: Bug fix: `pyspark` not opening.

#### 06/11/2024 
 - :lipstick: `$NODE_REPLICAS` renamed to `$REPLICAS`;
 - :lipstick: `node-master` renamed to `spark-master`;
 - :lipstick: `node-*` renamed to `worker-*`;
 - :lipstick: Newer variables at `.env` file;
 - :wrench: Minor fixes and optimizations.

#### 23/10/2024 
 - :package: Updated `Apache Spark` version to 3.5.3;
 - :package: Updated `Java JDK` version to 11;
 - :package: Updated `PostgresSQL JDBC driver` to 42.7.4;
 - :package: Updated `graphframes` to 0.8.4;
 - :rotating_light: `Apache Hive` (external) removed from this repository; 
 - :lipstick: Folder `apps` now called `myfiles`;
 - :wrench: Minor fixes and optimizations.

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
 - :wrench: Other minor improvements.

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
 - :wrench: Other improvements.

### :page_facing_up: License

Copyright (c) 2022-2025 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE) and is free, open-source software.

`Apache Hadoop` and `Apache Spark` are licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache) and are also free, open-source software.
