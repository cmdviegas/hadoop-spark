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
# (C) 2023 CARLOS M D VIEGAS
# https://github.com/cmdviegas
#
#
### Description:
## This is a bash script to initialize services
#
### How it works:
## On first startup:
## - Load .bashrc
## - Start SSH server
## - Format namenode HDFS (node-master only)
## - Creates HDFS folders and copy files to them (node-master only)
## - Start HDFS, YARN and HISTORY SERVER (and, if enabled, initialize HIVE schema) (node-master only)
#
## In the next startups:
## - Load .bashrc
## - Start SSH server
## - Start HDFS, YARN and HISTORY SERVER (and, if enabled, initialize HIVE schema) (node-master only)
#

# Some variables passed as arguments from Dockerfile
PASSWORD=$1
HIVEEXTERNAL=$2
PGUSER=$3
PGPASS=$4

# Internal var to indicate that first boot has already done
FILE=.first_boot

# Some coloring
GR=$(tput setaf 2)
LB=$(tput setaf 6)
RE=$(tput sgr0)
SYS="[${GR}SYSTEM${RE}]${LB}"
CLUSTER="[${GR}CLUSTER${RE}]${LB}"
EOF="${RE}...\n"

# Starting this script
printf "\n${SYS} Starting bootstrap.sh${EOF}"

# Loading .bashrc
printf "${SYS} Loading environment variables in .bashrc${EOF}"
eval "$(tail -n +10 ~/.bashrc)" # workaround for ubuntu .bashrc

# Starting SSH server
printf "${SYS} Starting ssh server${EOF}"
echo "${PASSWORD}" | sudo -S service ssh start

# Copying .hosts to hosts file (only on first boot)
printf "${SYS} Copying hosts file to /etc/hosts${EOF}"
echo "${PASSWORD}" | sudo -S bash -c "cat ${HOME}/.hosts > /etc/hosts"

# Do only at node-master
if [ "${HOSTNAME}" == "node-master" ] ; then

    # Formatting HDFS (only on first boot)
    if [ ! -e "${FILE}" ] ; then
        printf "${CLUSTER} Formatting filesystem${EOF}"
        hdfs namenode -format
    fi

    sleep 3

    # Starting HDFS and YARN services
    printf "${CLUSTER} Starting HDFS and YARN services${EOF}"
    start-dfs.sh && start-yarn.sh

    sleep 3

    # Creating /user folders inside HDFS
    if [ ! -e "${FILE}" ] ; then
        printf "${CLUSTER} Creating folders in HDFS${EOF}"
        hdfs dfs -mkdir -p /user/${HDFS_NAMENODE_USER}
        hdfs dfs -mkdir /spark-logs
        hdfs dfs -mkdir /spark-libs
        hdfs dfs -put ${SPARK_HOME}/jars/*.jar /spark-libs/
    fi
    
    # Starting SPARK history server
    printf "${CLUSTER} Starting SPARK history server${EOF}"
    start-history-server.sh

    # Checking HDFS status (optional)
    printf "${CLUSTER} Checking HDFS nodes report${EOF}"
    hdfs dfsadmin -report

    # Checking YARN status (optional)
    printf "${CLUSTER} Checking YARN nodes list${EOF}"
    yarn node -list

    # Creating hive schema for postgresql as metastore (if enabled)
    if ${HIVEEXTERNAL}; then
        printf "${CLUSTER} Checking hive metastore schema status${EOF}"
        CHECKSCHEMA=`echo "$(PGPASSWORD=$PGPASS psql -h postgres-db -U $PGUSER -d hive_metastore -c '\dt "BUCKETING_COLS"')" | grep -o "1 row" | wc -l`
        if [ $CHECKSCHEMA -eq 0 ]; then
            printf "${CLUSTER} Initializing hive metastore schema${EOF}"
            schematool -initSchema -dbType postgres
        fi
     fi

    printf "${CLUSTER} ${GR}$(tput blink)ALL SET!${RE}\n"
fi

# Creating .first_boot file as a flag to indicate that first boot has already done
if [ ! -e "${FILE}" ] ; then
    touch ${FILE}
fi

# Starting bash terminal
/bin/bash
