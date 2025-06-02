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
- **Spark connect server**: If needed, enable spark connect server by setting `SPARK_CONNECT_SERVER` variable to true in `.env` file.
- **Cluster initialization**: Use `docker compose run --rm init` to download Hadoop/Spark and regenerate `docker-compose.yml` according to the `NUM_WORKER_NODES` variable.
> [!IMPORTANT]\
> Re-run `docker compose run --rm init` every time you change `NUM_WORKER_NODES`.


### To build and run:

```
docker compose run --rm init
docker compose build && docker compose up
```

> [!NOTE]\
> `docker compose run --rm init` - updates the `docker-compose.yml` file based on the number of worker nodes and downloads the Hadoop and Spark distributions.
>
> `docker compose build && docker compose up` - builds the hadoop-spark image and then starts the containers running Hadoop and Spark services.

> [!IMPORTANT]\
> If needed, you can run `docker compose run --rm init default` to restore the `docker-compose.yml` file to its default configuration.


## 💻 Services usage:

### Accessing the Cluster

After deploying the containers, you can use the cluster by accessing the `spark-master` node via terminal and run `pyspark` or `spark-submit`. To access the `spark-master`, run the following command in a terminal:
```
docker exec -it spark-master bash
```

> [!NOTE]\
> Alternatively, you can access `JupyterLab` through a web browser: http://localhost:8888

> [!NOTE]\
> If you have enabled `Spark Connect Server` (in the `.env` file), you can connect remotely by creating a SparkSession that points to the master node at `sc://{IP_ADDRESS}:15002`.

> [!WARNING]\
> Please be advised that enabling `Spark Connect Server` prevent local `pyspark`/`spark-submit` and `JupyterLab` usage.

## :page_facing_up: License

Copyright (c) 2022-2025 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE) and is free, open-source software.

`Apache Hadoop` and `Apache Spark` are licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache) and are also free, open-source software.
