#!/bin/bash
# ██████╗  ██████╗ █████╗
# ██╔══██╗██╔════╝██╔══██╗
# ██║  ██║██║     ███████║
# ██║  ██║██║     ██╔══██║
# ██████╔╝╚██████╗██║  ██║
# ╚═════╝  ╚═════╝╚═╝  ╚═╝
# DEPARTAMENTO DE ENGENHARIA DE COMPUTACAO E AUTOMACAO
# UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE, NATAL/RN
#
# (C) 2022-2025 CARLOS M D VIEGAS
# https://github.com/cmdviegas
#

### Description:
# This script updates .xml config of hadoop and spark

###
#### Load env variables
[ -f "${HOME}/.env" ] && . "${HOME}/.env"
###

###
#### Hadoop and Spark properties
# Functions to update hadoop and spark properties dynamically according vars in .env file.
function update_xml_values() { 
    sed -i "/<name>$1<\/name>/{n;s#<value>.*</value>#<value>$2</value>#;}" "$3"
}
function update_spark_defaults() { 
    sed -i "s#^\($1[[:space:]]*\)[^[:space:]]*#\1$2#" "${SPARK_HOME}/conf/spark-defaults.conf"
}
function append_spark_config() { 
    echo "$1 $2" >> "${SPARK_HOME}/conf/spark-defaults.conf"
}

# Update core-site.xml, yarn-site.xml, mapred-site.xml, hdfs-site.xml
#update_xml_values "fs.defaultFS" "hdfs://${MASTER_HOSTNAME}:9000" "${HADOOP_CONF_DIR}/core-site.xml"
update_xml_values "hadoop.http.staticuser.user" "${USERNAME}" "${HADOOP_CONF_DIR}/core-site.xml"
#update_xml_values "yarn.resourcemanager.hostname" "${MASTER_HOSTNAME}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.nodemanager.resource.memory-mb" "${YARN_NODEMANAGER_RESOURCE_MEMORY_MB}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.scheduler.maximum-allocation-mb" "${YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.scheduler.minimum-allocation-mb" "${YARN_SCHEDULER_MINIMUM_ALLOCATION_MB}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.scheduler.capacity.maximum-am-resource-percent" "${YARN_SCHEDULER_CAPACITY_MAXIMUM_AM_RESOURCE_PERCENT}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.app.mapreduce.am.resource.mb" "${YARN_APP_MAPREDUCE_AM_RESOURCE_MB}" "${HADOOP_CONF_DIR}/mapred-site.xml"
update_xml_values "mapreduce.map.memory.mb" "${MAPREDUCE_MAP_MEMORY_MB}" "${HADOOP_CONF_DIR}/mapred-site.xml"
update_xml_values "mapreduce.reduce.memory.mb" "${MAPREDUCE_REDUCE_MEMORY_MB}" "${HADOOP_CONF_DIR}/mapred-site.xml"
update_xml_values "dfs.namenode.name.dir" "\/home\/${USERNAME}\/hdfs-data\/nameNode" "${HADOOP_CONF_DIR}/hdfs-site.xml"
update_xml_values "dfs.datanode.data.dir" "\/home\/${USERNAME}\/hdfs-data\/dataNode" "${HADOOP_CONF_DIR}/hdfs-site.xml"
[ "$NUM_WORKER_NODES" -ge 2 ] && update_xml_values "dfs.replication" "2" "${HADOOP_CONF_DIR}/hdfs-site.xml"

# Update spark-defaults.conf
#update_spark_defaults "spark.eventLog.dir" "hdfs://${MASTER_HOSTNAME}:9000/spark-logs"
#update_spark_defaults "spark.history.fs.logDirectory" "hdfs://${MASTER_HOSTNAME}:9000/spark-logs"
#update_spark_defaults "spark.yarn.stagingDir" "hdfs://${MASTER_HOSTNAME}:9000/user"
#update_spark_defaults "spark.yarn.jars" "hdfs://${MASTER_HOSTNAME}:9000/spark-libs/*"
#update_spark_defaults "spark.sql.warehouse.dir" "hdfs://${MASTER_HOSTNAME}:9000/user/${USERNAME}/spark-warehouse" 
update_spark_defaults "spark.driver.memory" "${SPARK_DRIVER_MEMORY}"
update_spark_defaults "spark.executor.memory" "${SPARK_EXECUTOR_MEMORY}"
update_spark_defaults "spark.yarn.am.memory" "${SPARK_YARN_AM_MEMORY}"
if grep -q "^spark.driver.extraJavaOptions" "${SPARK_HOME}/conf/spark-defaults.conf"; then
    update_spark_defaults "spark.driver.extraJavaOptions" "-Dderby.system.home=${HOME}/derby-metastore -Dderby.stream.error.file=${HOME}/derby-metastore/derby.log"
else
    append_spark_config "spark.driver.extraJavaOptions" "-Dderby.system.home=${HOME}/derby-metastore -Dderby.stream.error.file=${HOME}/derby-metastore/derby.log"
fi
###
