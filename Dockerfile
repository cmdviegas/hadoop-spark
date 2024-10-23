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
ENV USERNAME "${USER}"
ENV PASSWORD "${PASS}"

# Set working dir
ENV MYDIR /home/${USERNAME}
WORKDIR ${MYDIR}

# Configure Hadoop enviroment variables
ENV HADOOP_HOME "${MYDIR}/hadoop"
ENV SPARK_HOME "${MYDIR}/spark"

# Copy all files from local folder to container, except the ones in .dockerignore
COPY . .

# Extract Hadoop/Spark to the container filesystem
RUN echo "CHECKING HADOOP AND SPARK FILES..." \
    && HADOOP_FILE=$(ls hadoop-*.tar.gz 2>/dev/null) && \
    SPARK_FILE=$(ls spark-*.tgz 2>/dev/null) && \
    if [ -z "$HADOOP_FILE" ]; then \
        echo "🚨 ERROR: Hadoop file not found. Please download the required files by running download.sh"; \
        exit 1; \
    elif [ -z "$SPARK_FILE" ]; then \
        echo "🚨 ERROR: Spark file not found. Please download the required files by running download.sh"; \
        exit 1; \
    else \
        echo "EXTRACTING FILES..." && \
        tar -xzf "${HADOOP_FILE}" -C "${MYDIR}" && \
        tar -xzf "${SPARK_FILE}" -C "${MYDIR}" && \
        rm -f "${HADOOP_FILE}" "${SPARK_FILE}"; \
    fi

RUN ln -sf ${MYDIR}/hadoop-3*/ ${HADOOP_HOME}
RUN ln -sf ${MYDIR}/spark-3*-bin-hadoop3/ ${SPARK_HOME}

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
    sudo vim nano dos2unix ssh wget openjdk-11-jdk-headless \
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

# Set permissions to user folder
RUN echo "SETTING PERMISSIONS..." \
    && sudo -S chown "${USERNAME}:${USERNAME}" -R ${MYDIR}

# Additional libs for Spark
# PostgresSQL JDBC
RUN echo "DOWNLOADING JDBC..." \
    && wget -q -nc --no-check-certificate https://jdbc.postgresql.org/download/postgresql-42.7.4.jar -P ${SPARK_HOME}/jars
# Graphframes
RUN echo "DOWNLOADING GRAPHFRAMES..." \
    && wget -q -nc --no-check-certificate https://repos.spark-packages.org/graphframes/graphframes/0.8.4-spark3.5-s_2.12/graphframes-0.8.4-spark3.5-s_2.12.jar -P ${SPARK_HOME}/jars
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
