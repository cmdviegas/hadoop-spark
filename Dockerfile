# ██████╗  ██████╗ █████╗
# ██╔══██╗██╔════╝██╔══██╗
# ██║  ██║██║     ███████║
# ██║  ██║██║     ██╔══██║
# ██████╔╝╚██████╗██║  ██║
# ╚═════╝  ╚═════╝╚═╝  ╚═╝
# DEPARTAMENTO DE ENGENHARIA DE COMPUTACAO E AUTOMACAO
# UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE, NATAL/RN
#
# (C) 2022 CARLOS M D VIEGAS
#
# This Dockerfile creates an image of Apache Hadoop 3.x.x and Apache Spark 3.x.x
#

# Import base image
FROM ubuntu:22.04

# Defines user and working dir
USER root
ENV MYDIR /root
WORKDIR ${MYDIR}

# Copy all files from local folder to container, except the ones in .dockerignore
COPY . .

# Update system and install required packages (silently)
RUN apt-get update && apt-get install -y python3.9 ssh openjdk-11-jdk-headless vim net-tools iputils-ping dos2unix

# Create a symbolic link to make 'python' be recognized as a system command
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Configure Hadoop enviroment variables
ENV HADOOP_HOME "${MYDIR}/hadoop"
ENV HADOOP_COMMON_HOME "${HADOOP_HOME}"
ENV HADOOP_HDFS_HOME "${HADOOP_HOME}"
ENV HADOOP_MAPRED_HOME "${HADOOP_HOME}"
ENV HADOOP_YARN_HOME "${HADOOP_HOME}"
ENV HADOOP_CONF_DIR "${HADOOP_HOME}/etc/hadoop"
ENV HADOOP_COMMON_LIB_NATIVE_DIR "${HADOOP_HOME}/lib/native"
ENV HADOOP_OPTS "${HADOOP_OPTS} -XX:-PrintWarnings -Djava.net.preferIPv4Stack=true -Djava.library.path=${HADOOP_COMMON_LIB_NATIVE_DIR}"
ENV LD_LIBRARY_PATH "${HADOOP_COMMON_LIB_NATIVE_DIR}"
ENV JAVA_HOME "/usr/lib/jvm/java-11-openjdk-amd64"
#ENV _JAVA_OPTIONS "-Xmx2048m"
ENV HDFS_NAMENODE_USER "root"
ENV HDFS_DATANODE_USER "${HDFS_NAMENODE_USER}"
ENV HDFS_SECONDARYNAMENODE_USER "${HDFS_NAMENODE_USER}"
ENV YARN_RESOURCEMANAGER_USER "${HDFS_NAMENODE_USER}"
ENV YARN_NODEMANAGER_USER "${HDFS_NAMENODE_USER}"
ENV SPARK_HOME "${HADOOP_HOME}/spark"
ENV PATH "$PATH:${HADOOP_HOME}/sbin:${HADOOP_HOME}/bin:${JAVA_HOME}/bin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin"

# Copy and extract Hadoop to container filesystem
# Download hadoop-3.3.5.tar.gz from Apache (if needed)
#RUN wget --no-check-certificate https://dlcdn.apache.org/hadoop/common/hadoop-3.3.5/hadoop-3.3.5.tar.gz
RUN tar -zxf hadoop-3*.tar.gz -C ${MYDIR} && rm -rf hadoop-3*.tar.gz
RUN ln -sf hadoop-3* hadoop

# Download spark-3.3.2-bin-hadoop3.tgz from Apache (if needed)
#RUN wget --no-check-certificate https://dlcdn.apache.org/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz
RUN tar -zxf spark-3*-bin-hadoop3.tgz -C ${HADOOP_HOME} && rm -rf spark-3*-bin-hadoop3.tgz
RUN ln -sf ${HADOOP_HOME}/spark-3*-bin-hadoop3 ${HADOOP_HOME}/spark

# Optional (convert charset from UTF-16 to UTF-8)
RUN dos2unix config_files/*

# Load environment variables into .bashrc file
RUN cat config_files/bashrc >> .bashrc

# Copy config files to Hadoop config folder
COPY config_files/*.xml ${HADOOP_CONF_DIR}/
COPY config_files/workers ${HADOOP_CONF_DIR}/
COPY config_files/hadoop-env.sh ${HADOOP_CONF_DIR}/
RUN chmod 0755 ${HADOOP_CONF_DIR}/*.sh
COPY config_files/spark-defaults.conf ${SPARK_HOME}/conf
COPY config_files/spark-env.sh ${SPARK_HOME}/conf
RUN chmod 0755 ${SPARK_HOME}/conf/*.sh

# Configure ssh for passwordless access
RUN mkdir -p ./.ssh && cat config_files/ssh_config >> .ssh/config && chmod 0600 .ssh/config
RUN ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa
RUN cp .ssh/id_rsa.pub .ssh/authorized_keys && chmod 0600 .ssh/authorized_keys

# Run a script on boot
RUN chmod 0700 config_files/bootstrap.sh
CMD ${MYDIR}/config_files/bootstrap.sh
