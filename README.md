## Hadoop and Spark Cluster Deployment

This script deploys a cluster with `Apache Hadoop 3.4.x` and `Apache Spark 3.5.x` in fully distributed mode using `Docker` containers as the underlying infrastructure. This setup is primarily intended for teaching and experimentation, but it may also be suitable for scalable data processing workloads in controlled environments.

JupyterLab is now integrated, allowing users to interact with the Spark cluster through notebooks, making development, testing, and data exploration more convenient and user-friendly.

### 🗂️ Architecture

The cluster consists of **one master node** and a configurable number of **worker nodes**, deployed over a custom `Docker` network.

- **Master Node**: `spark-master` — responsible for coordinating the cluster, managing resources (via YARN), and serving as the Spark Master and HDFS NameNode.
- **Worker Nodes**: `spark-worker-<id>` — replicated containers acting as Spark Workers, HDFS DataNodes, and YARN NodeManagers, where `<id>` denotes the worker instance ID.

### ⚙️ Resource Management and Services

The cluster uses **YARN** for resource scheduling and **HDFS** for distributed file storage. Here are the key services on each node:

#### Master Node (`spark-master`)

- **ResourceManager** (YARN)
- **NameNode** (HDFS)
- **Spark Master**
- **Exposed Ports**:
  - `9870` – HDFS Web UI
  - `8088` – YARN ResourceManager UI
  - `19888` – MAPRED Job History UI
  - `18080` – Spark History Server UI
  - `15002` – Spark Connect
  - `8888` – Jupyter Lab

#### Worker Nodes (`spark-worker-<id>`)

- **DataNode** (HDFS)
- **NodeManager** (YARN)
- **Spark Worker**

### :rocket: How to build and run

⚠️ Note: All cluster parameters — such as the default user credentials, resource allocation (e.g., memory and CPU limits), number of worker nodes, and other deployment-specific settings — are configurable via the `.env` file. This file is the primary configuration source for the cluster setup.

⚠️ Optional (Recommended): Before starting, it is advised to pre-download Apache Hadoop and Apache Spark by running the `download.sh` script. This step will speed up the build process.

#### To build and run:
```
docker compose run --rm gen-compose
docker compose build && docker compose up
```

⚠️ Note: It is advised to use `Docker Compose 1.18.0` or higher to ensure compatibility.

⚠️ ⚠️ ⚠️ Important: It is recommended to run `docker compose run --rm gen-compose` command every time `$NUM_WORKER_NODES` variable is changed. This ensures that `docker-compose.yml` file is updated with the new cluster configuration.

### :bulb: Tips

#### Accessing the Master Node

To access the master node, run the following command:
```
docker exec -it spark-master bash
```

### :memo: Changelog

#### 19/05/2025
- :sparkles: For security reasons, the `$MY_PASSWORD` variable has been removed from the `.env` file. A dedicated secrets file (`.password`) has been introduced for setting the user password, if required;
- :sparkles: Each worker node is now deployed as a separate service with a specific hostname (`spark-worker-<id>`). A script generates `docker-compose.yml` dynamically based on `$NUM_WORKER_NODES` variable (change it at `.env` file). A new method for building and running the cluster has been defined. See the updated commands above;
- :clipboard: Build Summary: 
  * hadoop:3.4.1
  * spark:3.5.5+2.12
  * psql-jdbc:42.7.5
  * graphframes:0.8.4
  * jdk:11
  * python:3.12
  * ubuntu:24.04
  * jupyterlab:4.4.2
- :bug: Known issues:
  * File uploads via HDFS WebUI are currently non-functional (docker issue).
  * Node hostname links in Spark/HDFS WebUI are unresponsive (docker issue).

#### 16/05/2025
- :sparkles: Add `JupyterLab` version 4.4.2;

#### 14/05/2025
- :sparkles: Bug fix: `spark_shuffle` not detected by yarn, since Spark 3.5.x;
- :wrench: Minor fixes and optimizations.

#### 08/05/2025
- :sparkles: Added `MapReduce Job History`;
- :wrench: Minor fixes and optimizations.

#### 06/05/2025
- :package: Updated `Ubuntu` version to 24.04 LTS;
- :package: Updated `Python` version to 3.12;
- :wrench: Minor fixes and optimizations.

#### 29/04/2025
- :package: Updated `Apache Spark` version to 3.5.5;
- :package: Updated `Python` version to 3.11;
- :wrench: Minor fixes and optimizations.

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
