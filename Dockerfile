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

### Description:
# This Dockerfile creates an image of Apache Hadoop 3.4.0 and Apache Spark 3.5.3.

### How it works:
# This file uses ubuntu linux as base system and then downloads hadoop and spark. In installs all dependencies to run the cluster. The docker image will contain a fully distributed hadoop cluster with multiple worker nodes.

# Import base image
FROM ubuntu:22.04

# Bash execution
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Get username and password from build arguments
ARG USER
ARG PASS
ENV USERNAME="${USER}"
ENV PASSWORD="${PASS}"

# Local mirror
#RUN sed -i -e 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//mirror:\/\/mirrors\.ubuntu\.com\/mirrors\.txt/' /etc/apt/sources.list

# BR Mirror
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1br.\2/" /etc/apt/sources.list

# Update system and install required packages
RUN echo "RUNNING APT UPDATE..." \
    && apt-get update -qq 
RUN echo "RUNNING APT-GET TO INSTALL REQUIRED RESOURCES..." \ 
    && DEBIAN_FRONTEND=noninteractive DEBCONF_NOWARNINGS=yes \
    apt-get install -qq --no-install-recommends \
    sudo vim nano dos2unix ssh wget aria2 openjdk-11-jdk-headless \
    python3.10-minimal python3-pip iproute2 iputils-ping net-tools \
    postgresql-client < /dev/null > /dev/null

# Clear apt cache and lists to reduce size
RUN apt clean && rm -rf /var/lib/apt/lists/*

# Creates symbolic link to make 'python' and 'python3' recognized as a system command
RUN ln -sf /usr/bin/python3.10 /usr/bin/python
RUN ln -sf /usr/bin/python /usr/bin/python3

# Creates user and add it to sudoers 
RUN adduser --disabled-password --gecos "" ${USERNAME}
RUN echo "${USERNAME}:${PASSWORD}" | chpasswd
RUN usermod -aG sudo ${USERNAME}
# Passwordless sudo for created user
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}
USER ${USERNAME}

# Set working dir
ENV MYDIR="/home/${USERNAME}"
WORKDIR ${MYDIR}

# Configure Hadoop enviroment variables
ENV HADOOP_HOME="${MYDIR}/hadoop"
ENV SPARK_HOME="${MYDIR}/spark"

# Copy all files from local folder to container, except the ones in .dockerignore
COPY . .

# Set permissions to user folder
RUN echo "SETTING PERMISSIONS..." \
    && sudo -S chown "${USERNAME}:${USERNAME}" -R ${MYDIR}

# Extract Hadoop/Spark to the container filesystem
ARG SPARK_VER
ARG HADOOP_VER
ENV SPARK_VERSION=${SPARK_VER}
ENV HADOOP_VERSION=${HADOOP_VER}

RUN if [ ! -f ${MYDIR}/hadoop-${HADOOP_VERSION}.tar.gz ]; then \
    aria2c -x 16 --check-certificate=false --allow-overwrite=false \
    https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz; \
    fi
RUN tar -zxf hadoop-${HADOOP_VERSION}.tar.gz -C ${MYDIR} && rm -rf hadoop-${HADOOP_VERSION}.tar.gz
RUN ln -sf ${MYDIR}/hadoop-3* ${HADOOP_HOME}

RUN if [ ! -f ${MYDIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz ]; then \
    aria2c -x 16 --check-certificate=false --allow-overwrite=false \
    https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz; \
    fi
RUN tar -zxf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C ${MYDIR} && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz
RUN ln -sf ${MYDIR}/spark-3*-bin-hadoop3 ${SPARK_HOME}

# Additional libs for Spark
# PostgresSQL JDBC
RUN echo "DOWNLOADING JDBC..." \
    && aria2c -x 16 --check-certificate=false --allow-overwrite=false \
    https://jdbc.postgresql.org/download/postgresql-42.7.4.jar -d ${SPARK_HOME}/jars
# Graphframes
RUN echo "DOWNLOADING GRAPHFRAMES..." \
    && aria2c -x 16 --check-certificate=false --allow-overwrite=false \
    https://repos.spark-packages.org/graphframes/graphframes/0.8.4-spark3.5-s_2.12/graphframes-0.8.4-spark3.5-s_2.12.jar -d ${SPARK_HOME}/jars
# Install graphframes / pandas (for Spark GraphX/Graphframes and MLlib)
RUN echo "INSTALLING PANDAS..." \
    && pip install --no-warn-script-location -q graphframes pandas

# Optional (convert charset from UTF-16 to UTF-8)
RUN dos2unix config_files/*

# Load environment variables into .bashrc file
RUN cat config_files/system/bash_profile >> ${MYDIR}/.bashrc
RUN sed -i "s/^export\? HDFS_NAMENODE_USER=.*/export HDFS_NAMENODE_USER=${USERNAME}/" "${MYDIR}/.bashrc"

# Copy config files to Hadoop config folder
RUN cp config_files/hadoop/* ${HADOOP_HOME}/etc/hadoop/
RUN chmod 0755 ${HADOOP_HOME}/etc/hadoop/*.sh

# Copy config files to Spark config folder
RUN cp config_files/spark/* ${SPARK_HOME}/conf
RUN chmod 0755 ${SPARK_HOME}/conf/*.sh

# Configure ssh for passwordless access
RUN mkdir -p ./.ssh && cat config_files/system/ssh_config >> .ssh/config && chmod 0600 .ssh/config
RUN ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa
RUN cat .ssh/id_rsa.pub >> .ssh/authorized_keys && chmod 0600 .ssh/authorized_keys

# Cleaning
RUN sudo rm -rf config_files/ /tmp/* /var/tmp/*

# Run 'bootstrap.sh' script on boot
RUN chmod 0700 bootstrap.sh config-xml.sh
ENTRYPOINT ${MYDIR}/bootstrap.sh
#CMD MASTER
