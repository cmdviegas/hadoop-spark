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
## This Dockerfile creates an image of Apache Hadoop 3.3.5 and Apache Spark 3.4.0
## Optionally, it includes Apache Hive 3.1.3 with Postgresql 15.2
#
### How it works:
## This file uses ubuntu linux as base system and then downloads hadoop, spark and hive (if needed)
## and copy all the configuration files on config_folders to the image being created.
## The docker image will contain a fully distributed hadoop deployment ready to work, where a cluster 
## is created with multiple wokers.
#

# Import base image
FROM ubuntu:22.04

LABEL org.opencontainers.image.authors="(C) 2023 CARLOS M D VIEGAS https://github.com/cmdviegas"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Get username and password from build arguments
ARG USER
ARG PASS
ARG PGUSER
ARG PGPASSWORD
ARG HIVEEXTERNAL
ARG REPLICAS
ENV USERNAME "${USER}"
ENV PASSWORD "${PASS}"
ENV POSTGRESUSER "${PGUSER}"
ENV POSTGRESPASS "${PGPASSWORD}"
ENV HIVEINSTALL "${HIVEEXTERNAL}"
ENV WORKERS "${REPLICAS}"

# Update system and install required packages
#RUN sed -i -e 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//mirror:\/\/mirrors\.ubuntu\.com\/mirrors\.txt/' /etc/apt/sources.list
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1br.\2/" /etc/apt/sources.list
RUN apt-get update && apt-get install -y \
            --no-install-recommends sudo \ 
                                    ssh \
                                    vim \
                                    nano \
                                    wget \
                                    openjdk-11-jdk-headless \
                                    python3.10-minimal \
                                    iproute2 \
                                    iputils-ping \
                                    dos2unix
RUN if ${HIVEINSTALL}; then apt-get install -y --no-install-recommends postgresql-client; fi
RUN apt clean && rm -rf /var/lib/apt/lists/*

# Create symbolic link to make 'python' and 'python3' recognized as a system command
RUN ln -sf /usr/bin/python3.10 /usr/bin/python
RUN ln -sf /usr/bin/python /usr/bin/python3

# Creates spark user, add it to sudoers 
RUN adduser --disabled-password --gecos "" ${USERNAME}
RUN echo "${USERNAME}:${PASSWORD}" | chpasswd
RUN usermod -aG sudo ${USERNAME}
USER ${USERNAME}

# Set working dir
ENV MYDIR /home/${USERNAME}
WORKDIR ${MYDIR}

# Configure Hadoop enviroment variables
ENV HADOOP_HOME "${MYDIR}/hadoop"
ENV HADOOP_CONF_DIR "${HADOOP_HOME}/etc/hadoop"
ENV SPARK_HOME "${HADOOP_HOME}/spark"
ENV HIVE_HOME "${HADOOP_HOME}/hive"

# Copy all files from local folder to container, except the ones in .dockerignore
COPY . .

# Set permissions
RUN echo "${PASSWORD}" | sudo -S chown "${USERNAME}:${USERNAME}" -R ${MYDIR}

# Extract Hadoop to container filesystem
# Download Hadoop 3.3.5 from Apache servers (if needed)
ENV FILENAME hadoop-3.3.5.tar.gz
RUN wget -nc --no-check-certificate https://dlcdn.apache.org/hadoop/common/$(echo "${FILENAME}" | sed "s/\.tar\.gz$//")/${FILENAME}
RUN tar -zxf ${FILENAME} -C ${MYDIR} && rm -rf $FILENAME
RUN ln -sf hadoop-3* hadoop

# Extract Spark to container filesystem
# Download Spark 3.4.0 from Apache server (if needed)
ENV FILENAME spark-3.4.0-bin-hadoop3.tgz
RUN wget -nc --no-check-certificate https://dlcdn.apache.org/spark/$(echo "${FILENAME}" | sed -E 's/^spark-([0-9]+\.[0-9]+\.[0-9]+).*/spark-\1/')/${FILENAME}
RUN tar -zxf ${FILENAME} -C ${HADOOP_HOME} && rm -rf ${FILENAME}
RUN ln -sf ${HADOOP_HOME}/spark-3*-bin-hadoop3 ${SPARK_HOME}

# Extract Hive to container filesystem
# Download Hive 3.1.3 from Apache server (if needed)
ENV FILENAME apache-hive-3.1.3-bin.tar.gz
RUN if ${HIVEINSTALL}; then wget -nc --no-check-certificate https://dlcdn.apache.org/hive/$(echo "${FILENAME}" | sed -E 's/^apache-hive-([0-9]+\.[0-9]+\.[0-9]+).*/hive-\1/')/${FILENAME}; fi
RUN if ${HIVEINSTALL}; then tar -zxf ${FILENAME} -C ${HADOOP_HOME}; fi
RUN if ${HIVEINSTALL}; then ln -sf ${HADOOP_HOME}/apache-hive-* ${HIVE_HOME}; fi
RUN if ${HIVEINSTALL}; then wget -nc --no-check-certificate https://jdbc.postgresql.org/download/postgresql-42.6.0.jar -P ${SPARK_HOME}/jars; fi
RUN if [ -f ${FILENAME} ]; then rm -rf ${FILENAME}; fi

# Optional (convert charset from UTF-16 to UTF-8)
RUN dos2unix config_files/*

# Load environment variables into .bashrc file
RUN cat config_files/system/bash_profile >> ${MYDIR}/.bashrc

# Hosts file
RUN cp config_files/system/hosts ${MYDIR}/.hosts

# Copy config files to Hadoop config folder
RUN cp config_files/hadoop/core-site.xml ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/hadoop-env.sh ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/hdfs-site.xml ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/mapred-site.xml ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/workers ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop/yarn-site.xml ${HADOOP_CONF_DIR}/
RUN chmod 0755 ${HADOOP_CONF_DIR}/*.sh

# Adjust workers file according to the number of replicas
RUN for i in $(seq 1 $WORKERS); do echo "node-$i" >> ${HADOOP_CONF_DIR}/workers; done

# Copy config files to Spark config folder
RUN cp config_files/spark/spark-defaults.conf ${SPARK_HOME}/conf
RUN if ${HIVEINSTALL}; then cat config_files/spark/spark-hive.conf >> ${SPARK_HOME}/conf/spark-defaults.conf; fi
RUN if ${HIVEINSTALL}; then echo "spark.sql.hive.metastore.jars.path file://${HIVE_HOME}/lib/*" >> ${SPARK_HOME}/conf/spark-defaults.conf; else echo "spark.driver.extraJavaOptions   -Dderby.system.home=${MYDIR}/derby-metastore -Dderby.stream.error.file=${MYDIR}/derby-metastore/derby.log" >> ${SPARK_HOME}/conf/spark-defaults.conf; fi
RUN cp config_files/spark/spark-env.sh ${SPARK_HOME}/conf
RUN chmod 0755 ${SPARK_HOME}/conf/*.sh

# Copy config files to Hive config folder
RUN if ${HIVEINSTALL}; then cp config_files/hive/hive-site.xml ${HIVE_HOME}/conf; fi
RUN if ${HIVEINSTALL}; then ln -sf ${SPARK_HOME}/jars/commons-collections-3.2.2.jar ${HIVE_HOME}/lib/commons-collections-3.2.2.jar; fi
RUN if ${HIVEINSTALL}; then ln -sf ${SPARK_HOME}/jars/commons-collections4-4.4.jar ${HIVE_HOME}/lib/commons-collections4-4.4.jar; fi

# Configure ssh for passwordless access
RUN mkdir -p ./.ssh && cat config_files/system/ssh_config >> .ssh/config && chmod 0600 .ssh/config
RUN ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa
RUN cp .ssh/id_rsa.pub .ssh/authorized_keys && chmod 0600 .ssh/authorized_keys

# Configuring username/password and hdfs folder according the values defined in .env file
RUN sed -i "s/USERNAME_REPLACE/${USERNAME}/g" ${MYDIR}/.bashrc
RUN sed -i "s/USERNAME_REPLACE/${USERNAME}/g" ${HADOOP_CONF_DIR}/core-site.xml
RUN sed -i "s/USERNAME_REPLACE/${USERNAME}/g" ${HADOOP_CONF_DIR}/hdfs-site.xml
RUN sed -i "s/USERNAME_REPLACE/${USERNAME}/g" ${SPARK_HOME}/conf/spark-defaults.conf
RUN if ${HIVEINSTALL}; then sed -i "s/USERNAME_REPLACE/${POSTGRESUSER}/g" ${HIVE_HOME}/conf/hive-site.xml; fi
RUN if ${HIVEINSTALL}; then sed -i "s/PASSWORD_REPLACE/${POSTGRESPASS}/g" ${HIVE_HOME}/conf/hive-site.xml; fi

# Cleaning
RUN rm -rf config_files/

# Run 'bootstrap.sh' script on boot
RUN chmod 0700 bootstrap.sh
CMD ${MYDIR}/bootstrap.sh ${PASSWORD} ${HIVEINSTALL} ${POSTGRESUSER} ${POSTGRESPASS}
