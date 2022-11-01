## Deploying APACHE HADOOP 3.x.x + APACHE SPARK 3.x.x

This is a script to deploy Apache Hadoop in distributed mode using Docker as infrastructure.

⚠️ You should download `Apache Hadoop 3.3.4` ("hadoop-3.3.4.tar.gz") and `Apache Spark 3.3.1` ("spark-3.3.1-bin-hadoop3") and place them alongside the folder´s repo, or edit Dockerfile to perform a wget from Apache servers.

### :desktop_computer: How to run

#### [auto mode]
#### docker-compose.yml file option

```
docker-compose up --build
```

#### [manual mode] 
#### Dockerfile option

1. Build image based on Dockerfile
```
docker build -t hadoopcluster/hadoop-spark:v3 .
```

2. Create an isolated network to run Hadoop nodes
```
docker network create --subnet=172.18.0.0/24 hadoop_network
```

3. Run Hadoop slaves (data nodes)
```
docker run -it -d --network=hadoop_network --ip 172.18.0.3 --name=slave1 --hostname=slave1 hadoopcluster/hadoop-spark:v3
docker run -it -d --network=hadoop_network --ip 172.18.0.4 --name=slave2 --hostname=slave2 hadoopcluster/hadoop-spark:v3
```

4. Run Hadoop master (name node)
```
docker run -it -p 9870:9870 -p 8088:8088 -p 18080:18080 --network=hadoop_network --ip 172.18.0.2 --name=node-master --hostname=node-master hadoopcluster/hadoop-spark:v3
```

### 📜 License

Copyright (c) 2022 [CARLOS M. D. VIEGAS](https://github.com/cmdviegas).

This script is free and open-source software licensed under the [MIT License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE). 

`Apache Hadoop` and `Apache Spark` are free and open-source software licensed under the [Apache License](https://github.com/cmdviegas/docker-hadoop-cluster/blob/master/LICENSE.apache).
