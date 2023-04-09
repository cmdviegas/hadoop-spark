## Deploying APACHE HADOOP 3.x + APACHE SPARK 3.x

This is a script to deploy Apache Hadoop and Apache Spark in distributed mode using Docker as infrastructure.

⚠️ Before you begin, you must have to download Apache Hadoop 3.3.5 (`hadoop-3.3.5.tar.gz`) and Apache Spark 3.3.2 (`spark-3.3.2-bin-hadoop3.tgz`) and place them alongside the folder´s repo. There is a `download.sh` script to perform the download of both. Alternatively, you could edit `Dockerfile` by uncommenting lines 53 and 59 to perform the download.

### :desktop_computer: How to run

#### [auto mode]
#### docker-compose.yml file option

```
docker compose build && docker compose up --no-build
```

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

### :rocket: Tips

#### To access node-master
```
ssh -p 2222 spark@localhost
```
or
```
docker exec -it node-master /bin/bash
```

### 📜 License

Copyright (c) 2023 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is free and open-source software licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE). 

`Apache Hadoop` and `Apache Spark` are free and open-source software licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache).
