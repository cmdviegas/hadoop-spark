# Hadoop and Spark Cluster Deployment

This project deploys a cluster with `Apache Hadoop 3.4.1` and `Apache Spark 3.5.6` in fully distributed mode using `Docker` containers as the underlying infrastructure. This setup is primarily intended for teaching and experimentation, but it may also be suitable for scalable data processing workloads in controlled environments.

In addition, `JupyterLab` is integrated into the cluster, allowing users to interact with the Spark through notebooks, making development, testing, and data exploration more convenient and user-friendly.

## 🏗️ Architecture

The cluster consists of **one master node** and a configurable number of **worker nodes**. All containers share a custom Docker network. The cluster uses **YARN** for resource scheduling and **HDFS** for distributed file storage. All Spark applications use YARN as the underlying resource manager. Below are the key services on each node:

#### Master Node (`spark-master`)
- Responsible for coordinating the cluster, managing resources (via YARN), and serving as the Spark Master and HDFS NameNode.
- Services:
  - **ResourceManager** (YARN)
  - **NameNode** (HDFS)
  - **Spark Master**

#### Worker Nodes (`spark-worker-<id>`)
- Multiple containers acting as Spark Workers, HDFS DataNodes, and YARN NodeManagers, where `<id>` denotes the worker instance ID.
- Services:
  - **DataNode** (HDFS)
  - **NodeManager** (YARN)
  - **Spark Worker**


## ⚙️ Services & Ports

| Service                    | Node           | Port    | Purpose                         |
|----------------------------|----------------|---------|---------------------------------|
| HDFS Web UI                | `spark-master` | 9870    | View HDFS status                |
| YARN ResourceManager UI    | `spark-master` | 8088    | Manage cluster resources        |
| Spark History Server UI    | `spark-master` | 18080   | View completed Spark jobs       |
| MAPRED Job History UI      | `spark-master` | 19888   | MapReduce job tracking          |
| Spark Connect (optional)   | `spark-master` | 15002   | Remote SparkSession connection  |
| JupyterLab                 | `spark-master` | 8888    | Interactive notebooks           |


## :rocket: How to build and run

### Prerequisites

- Docker + Docker Compose CLI (v1.28.0+ recommended).

### Configuration

- **Number of workers**: Set the desired number of worker nodes by changing `NUM_WORKER_NODES` variable in `.env` file.
- **Cluster initialization**: Use `docker compose run --rm init` to download Hadoop/Spark and regenerate `docker-compose.yml` according to the `NUM_WORKER_NODES` variable.
> [!IMPORTANT]\
> Re-run `docker compose run --rm init` every time you change `NUM_WORKER_NODES`.
- **Spark connect**: If needed, enable spark connect server by setting `SPARK_CONNECT_SERVER` variable to true in `.env` file.
> [!WARNING]\
> Please be advised that enabling Spark Connect Server will prevent local PySpark terminal and JupyterLab usage.

### To build and run:

```
docker compose run --rm init
docker compose build && docker compose up
```

> [!NOTE]\
> #### Description: 
> - `docker compose run --rm init` - updates the `docker-compose.yml` file based on the number of worker nodes and downloads the Hadoop and Spark distributions.
>
>  - If needed, you can run `docker compose run --rm init default` to restore the `docker-compose.yml` file to its default configuration.
>
> - `docker compose build && docker compose up` - builds the hadoop-spark image and then starts the containers running Hadoop and Spark services.

## 💻 Services usage:

### Accessing the Cluster

After deploying the containers, you can use the cluster by accessing the `spark-master` node via terminal and run `pyspark` or `spark-submit`. To access the `spark-master`, run the following command in a terminal:
```
docker exec -it spark-master bash
```

> [!NOTE]\
> Alternatively, you can access `JupyterLab` through a web browser: http://localhost:8888

> [!NOTE]\
> Additionally, if you have enabled `Spark Connect` (in the .env file), you can connect remotely by creating a SparkSession that points to the master node at `sc://{IP_ADDRESS}:15002`.

## :memo: Changelog

### 01/06/2025
- :package: Updated `Apache Spark` version to 3.5.6;
- :sparkles: A new method to initialize the cluster has been introduced. Simply run `docker compose run --rm init` to update the `docker-compose.yml` file according to the `NUM_WORKER_NODES` variable and download all Hadoop and Spark resources. The old download scripts have been removed;
- :wrench: The `Dockerfile` was optimized. Hadoop and Spark are no longer downloaded during the build process, as it was very slow. Instead, this is now handled by the new init service described above;
- :wrench: Minor fixes and optimizations.
- :clipboard: Build Summary:
  * hadoop:3.4.1
  * spark:3.5.6+2.12
  * psql-jdbc:42.7.5
  * graphframes:0.8.4
  * jdk:11
  * python:3.12
  * ubuntu:24.04
  * jupyterlab:4.4.2
- :bug: Known issues:
  * File uploads via the HDFS WebUI are currently not functional (Docker limitation due to port forwarding);
  * Hostname links in Spark/YARN WebUI are unresponsive (Docker limitation due to port forwarding);
  * HDFS capacity information is inaccurate (Docker limitation).

### 28/05/2025
- :wrench: Refactored `services.sh` for better performance on managing services;
- :wrench: Minor fixes and optimizations.

### 24/05/2025
- :sparkles: All confguration files for Hadoop and Spark located in the `config_files` folder are now bind-mounted into the containers at their respective destination directories. This allows you to edit these files externally, and any changes will automatically apply across all containers (just restart them after any change). Due to this change, resource variables are no longer in the `.env` file. You can use `services.sh` `[start|stop]` to restart cluster services;
- :sparkles: Added new scripts (`download.bat` for Windows CMD and PowerShell, and `download.mac.sh` for macOS Terminal) to facilitate downloading Hadoop and Spark files;
- :wrench: Refactored some shell scripts for better maintainability and performance.

### 19/05/2025
- :sparkles: For security reasons, the `$MY_PASSWORD` variable has been removed from the `.env` file. A dedicated secrets file (`.password`) has been introduced for setting the user password, if required;
- :sparkles: Each worker node is now deployed as a separate service with a specific hostname (`spark-worker-<id>`). A script generates `docker-compose.yml` dynamically based on `$NUM_WORKER_NODES` variable (change it at `.env` file). A new method for building and running the cluster has been defined. See the updated commands above;

### 16/05/2025
- :sparkles: Add `JupyterLab` version 4.4.2;

### 14/05/2025
- :sparkles: Bug fix: `spark_shuffle` not detected by yarn, since Spark 3.5.x;
- :wrench: Minor fixes and optimizations.

### 08/05/2025
- :sparkles: Added `MapReduce Job History`;
- :wrench: Minor fixes and optimizations.

### 06/05/2025
- :package: Updated `Ubuntu` version to 24.04 LTS;
- :package: Updated `Python` version to 3.12;
- :wrench: Minor fixes and optimizations.

### 29/04/2025
- :package: Updated `Apache Spark` version to 3.5.5;
- :package: Updated `Python` version to 3.11;
- :wrench: Minor fixes and optimizations.

### 18/01/2025
- :package: Updated `Apache Spark` version to 3.5.4;
- :package: Updated `PostgresSQL JDBC driver` to 42.7.5;
- :package: Added support for Spark Connect. By default it is started at port 15002/tcp;
- :wrench: Minor fixes and optimizations.

### 07/11/2024 
 - :package: Updated `Apache Hadoop` version to 3.4.1;
 - :rotating_light: Bug fix: `pyspark` not opening.

### 06/11/2024 
 - :lipstick: `$NODE_REPLICAS` renamed to `$REPLICAS`;
 - :lipstick: `node-master` renamed to `spark-master`;
 - :lipstick: `node-*` renamed to `worker-*`;
 - :lipstick: Newer variables at `.env` file;
 - :wrench: Minor fixes and optimizations.

### 23/10/2024 
 - :package: Updated `Apache Spark` version to 3.5.3;
 - :package: Updated `Java JDK` version to 11;
 - :package: Updated `PostgresSQL JDBC driver` to 42.7.4;
 - :package: Updated `graphframes` to 0.8.4;
 - :rotating_light: `Apache Hive` (external) removed from this repository; 
 - :lipstick: Folder `apps` now called `myfiles`;
 - :wrench: Minor fixes and optimizations.

### 16/08/2024 
 - :package: Updated `Apache Spark` version to 3.5.2;

### 15/04/2024 
 - :package: Updated `Apache Hadoop` version to 3.4.0;
 - :package: Updated `Apache Spark` version to 3.5.1;

### 14/05/2023
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

### 23/04/2023 
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

## :page_facing_up: License

Copyright (c) 2022-2025 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE) and is free, open-source software.

`Apache Hadoop` and `Apache Spark` are licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache) and are also free, open-source software.
