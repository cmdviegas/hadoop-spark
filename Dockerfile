# ██████╗  ██████╗ █████╗
# ██╔══██╗██╔════╝██╔══██╗
# ██║  ██║██║     ███████║
# ██║  ██║██║     ██╔══██║
# ██████╔╝╚██████╗██║  ██║
# ╚═════╝  ╚═════╝╚═╝  ╚═╝
# DEPARTAMENTO DE ENGENHARIA DE COMPUTACAO E AUTOMACAO
# UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE, NATAL/RN
#
# (C) 2023 CARLOS M D VIEGAS
# https://github.com/cmdviegas

### Description:
# This Dockerfile creates an image of Apache Hadoop 3.3.5 and Apache Spark 3.4.0. Optionally, it includes Apache Hive 3.1.3 with Postgresql 15.2

### How it works:
# This file uses ubuntu linux as base system and then downloads hadoop, spark and hive (if needed). In installs all dependencies to run the cluster. The docker image will contain a fully distributed hadoop cluster with multiple worker nodes.

# Import base image
FROM ubuntu:22.04

# Label
LABEL org.opencontainers.image.authors="(C) 2023 CARLOS M D VIEGAS https://github.com/cmdviegas"

# Error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Get username and password from build arguments
ARG USER
ARG PASS
ENV USERNAME "${USER}"
ENV PASSWORD "${PASS}"

# Update system and install required packages
#RUN sed -i -e 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//mirror:\/\/mirrors\.ubuntu\.com\/mirrors\.txt/' /etc/apt/sources.list
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1br.\2/" /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
            --no-install-recommends sudo \ 
                                    ssh \
                                    vim \
                                    nano \
                                    wget \
                                    openjdk-8-jdk-headless \
                                    python3.10-minimal \
                                    python3-numpy \
                                    iproute2 \
                                    iputils-ping \
                                    net-tools \
                                    dos2unix \
                                    postgresql-client
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
ENV MYDIR /home/${USERNAME}
WORKDIR ${MYDIR}

# Configure Hadoop enviroment variables
ENV HADOOP_HOME "${MYDIR}/hadoop"
ENV HADOOP_CONF_DIR "${HADOOP_HOME}/etc/hadoop"
ENV SPARK_HOME "${MYDIR}/spark"
ENV HIVE_HOME "${MYDIR}/hive"

# Copy all files from local folder to container, except the ones in .dockerignore
COPY . .

# Set permissions to user folder
RUN sudo -S chown "${USERNAME}:${USERNAME}" -R ${MYDIR}

# Extract Hadoop to container filesystem
# Download Hadoop 3.3.5 from Apache servers (if needed)
ENV FILENAME hadoop-3.3.5.tar.gz
RUN wget -nc --no-check-certificate https://dlcdn.apache.org/hadoop/common/$(echo "${FILENAME}" | sed "s/\.tar\.gz$//")/${FILENAME}
RUN tar -zxf ${FILENAME} -C ${MYDIR} && rm -rf $FILENAME
RUN ln -sf hadoop-3* ${HADOOP_HOME}

# Extract Spark to container filesystem
# Download Spark 3.4.0 from Apache server (if needed)
ENV FILENAME spark-3.4.0-bin-hadoop3.tgz
RUN wget -nc --no-check-certificate https://dlcdn.apache.org/spark/$(echo "${FILENAME}" | sed -E 's/^spark-([0-9]+\.[0-9]+\.[0-9]+).*/spark-\1/')/${FILENAME}
RUN tar -zxf ${FILENAME} -C ${MYDIR} && rm -rf ${FILENAME}
RUN ln -sf ${MYDIR}/spark-3*-bin-hadoop3 ${SPARK_HOME}

# Extract Hive to container filesystem
# Download Hive 3.1.3 from Apache server (if needed)
ENV FILENAME apache-hive-3.1.3-bin.tar.gz
RUN wget -nc --no-check-certificate https://dlcdn.apache.org/hive/$(echo "${FILENAME}" | sed -E 's/^apache-hive-([0-9]+\.[0-9]+\.[0-9]+).*/hive-\1/')/${FILENAME}
RUN tar -zxf ${FILENAME} -C ${MYDIR} && rm -rf ${FILENAME}
RUN ln -sf ${MYDIR}/apache-hive-* ${HIVE_HOME}
RUN wget -nc --no-check-certificate https://jdbc.postgresql.org/download/postgresql-42.6.0.jar -P ${SPARK_HOME}/jars

# Optional (convert charset from UTF-16 to UTF-8)
RUN dos2unix config_files/*

# Load environment variables into .bashrc file
RUN cat config_files/system/bash_profile >> ${MYDIR}/.bashrc

# Copy config files to Hadoop config folder
RUN cp config_files/hadoop/core-site.xml ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/hadoop-env.sh ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/hdfs-site.xml ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/mapred-site.xml ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/yarn-site.xml ${HADOOP_CONF_DIR}/
RUN chmod 0755 ${HADOOP_CONF_DIR}/*.sh

# Copy config files to Spark config folder
RUN cp config_files/spark/spark-defaults.conf ${SPARK_HOME}/conf
RUN cp config_files/spark/spark-env.sh ${SPARK_HOME}/conf
RUN chmod 0755 ${SPARK_HOME}/conf/*.sh

# Copy config files to Hive config folder
RUN cp config_files/hive/hive-site.xml ${HIVE_HOME}/conf
RUN ln -sf ${SPARK_HOME}/jars/commons-collections-3.2.2.jar ${HIVE_HOME}/lib/commons-collections-3.2.2.jar

# Configure ssh for passwordless access
RUN mkdir -p ./.ssh && cat config_files/system/ssh_config >> .ssh/config && chmod 0600 .ssh/config
RUN ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa
RUN cp .ssh/id_rsa.pub .ssh/authorized_keys && chmod 0600 .ssh/authorized_keys

# Cleaning
RUN rm -rf config_files/

# Run 'bootstrap.sh' script on boot
RUN chmod 0700 bootstrap.sh
ENTRYPOINT ${MYDIR}/bootstrap.sh
CMD HADOOP
# CMD HIVE
