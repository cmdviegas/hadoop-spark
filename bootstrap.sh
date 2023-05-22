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

### Description:
# This is a bash script to initialize services

### How it works:
# On first startup:
# - Load .bashrc
# - Start SSH server
# - Format namenode HDFS (node-master only)
# - Creates HDFS folders and copy files to them (node-master only)
# - Edit HADOOP/SPARK/HIVE properties in .xml/.conf files according to values defined in .env
# - Start HDFS, YARN and HISTORY SERVER (and, if enabled, initialize HIVE server and configure HIVE schema at metastore)

# In the next startups:
# - Load .bashrc
# - Start SSH server
# - Edit HADDOP/SPARK/HIVE properties in .xml/.conf files according to values defined in .env/.env.hive
# - Start HDFS, YARN and HISTORY SERVER (and, if enabled, initialize HIVE server)

# Some coloring
RED_COLOR=$(tput setaf 1)
GREEN_COLOR=$(tput setaf 2) 
YELLOW_COLOR=$(tput setaf 3)
LIGHTBLUE_COLOR=$(tput setaf 6)
RESET_COLORS=$(tput sgr0)
INFO="[${GREEN_COLOR}INFO${RESET_COLORS}]${LIGHTBLUE_COLOR}"
WARN="[${RED_COLOR}ERROR${RESET_COLORS}]${YELLOW_COLOR}"

if [[ "$1" != "HIVE" && "$1" != "HADOOP" ]]; then
    printf "${WARN} Invalid parameter. You should call ./bootstrap.sh HIVE or ./bootstrap.sh HADOOP. Exiting.${RESET_COLORS}\n"
    exit 1
fi

###
#### Load env variables
if [[ -f "${HOME}/.env" ]]; then 
    source "${HOME}/.env"
fi
###

###
#### .bashrc
# Replace username in the .bashrc (HDFS_NAMENODE_USER)
sed -i "s/^export\? HDFS_NAMENODE_USER=.*/export HDFS_NAMENODE_USER=${USERNAME}/" "${HOME}/.bashrc"
# Replace or remove HIVE_HOME vars accordingly input $1 parameter HIVE or HADDOP
case "$1" in
    HIVE)
        sed -i 's|^export\? HIVE_HOME=.*|export HIVE_HOME="${HOME}/hive"|' "${HOME}/.bashrc"
        ;;
    HADOOP)
        sed -i 's|^export\? HIVE_HOME=.*|export HIVE_HOME=|' "${HOME}/.bashrc"
        ;;
esac
# Load .bashrc
eval "$(tail -n +10 ${HOME}/.bashrc)" # Workaround for ubuntu .bashrc (i.e. source .bashrc)
###

###
#### Init ssh server
sudo service ssh start
###

###
#### /etc/hosts and ~/hadoop/etc/hadoop/workers
# Creates /etc/hosts dynamically according to number of replicas and update hadoop workers file accordingly.
truncate -s 0 ${HADOOP_CONF_DIR}/workers
{
    echo "127.0.0.1 localhost"
    echo "${IP_NODEMASTER} node-master"
    for i in $(seq 1 "${NODE_REPLICAS}"); do
        echo "${IP_RANGE%0/*}$((i+2)) node-$i"
        echo "node-$i" >> "${HADOOP_CONF_DIR}/workers"
    done
    echo "${IP_HIVE} hive-server"
    echo "${IP_DB} postgres-db"
} > "${HOME}/.hosts"
# Copy hosts file to /etc/hosts
sudo bash -c "cat ${HOME}/.hosts > /etc/hosts"
{
    echo "node-master"
    cat "${HADOOP_CONF_DIR}/workers"
} > "${HOME}/.hostlist"
###

###
#### Hadoop and Spark properties
# Functions to update hadoop and spark properties dynamically according vars in .env file.
function update_xml_values() {
    sed -i "/<name>$1<\/name>/{n;s/<value>.*<\/value>/<value>$2<\/value>/;}" "$3"
}
function update_spark_defaults() {
    sed -i "s|^\($1[[:space:]]*\)[^[:space:]]*|\1$2|" "${SPARK_HOME}/conf/spark-defaults.conf"
}
function append_spark_config() {
    echo "$1 $2" >> "${SPARK_HOME}/conf/spark-defaults.conf"
}

# Update core-site.xml, yarn-site.xml, mapred-site.xml, hdfs-site.xml
update_xml_values "hadoop.http.staticuser.user" "${SYS_USERNAME}" "${HADOOP_CONF_DIR}/core-site.xml"
update_xml_values "yarn.nodemanager.resource.memory-mb" "${MEM_RM}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.scheduler.maximum-allocation-mb" "${MEM_MAX}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.scheduler.minimum-allocation-mb" "${MEM_MIN}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.scheduler.capacity.maximum-am-resource-percent" "${MAX_SCHED}" "${HADOOP_CONF_DIR}/yarn-site.xml"
update_xml_values "yarn.app.mapreduce.am.resource.mb" "${MEM_AM}" "${HADOOP_CONF_DIR}/mapred-site.xml"
update_xml_values "mapreduce.map.memory.mb" "${MEM_MAP}" "${HADOOP_CONF_DIR}/mapred-site.xml"
update_xml_values "mapreduce.reduce.memory.mb" "${MEM_RED}" "${HADOOP_CONF_DIR}/mapred-site.xml"
update_xml_values "dfs.namenode.name.dir" "\/home\/${SYS_USERNAME}\/hdfs-data\/nameNode" "${HADOOP_CONF_DIR}/hdfs-site.xml"
update_xml_values "dfs.datanode.data.dir" "\/home\/${SYS_USERNAME}\/hdfs-data\/dataNode" "${HADOOP_CONF_DIR}/hdfs-site.xml"
if [ "$NODE_REPLICAS" -eq 1 ]; then
    update_xml_values "dfs.replication" "1" "${HADOOP_CONF_DIR}/hdfs-site.xml"
elif [ "$NODE_REPLICAS" -ge 2 ]; then
    update_xml_values "dfs.replication" "2" "${HADOOP_CONF_DIR}/hdfs-site.xml"
fi

# Update spark-defaults.conf
update_spark_defaults "spark.sql.warehouse.dir" "hdfs://node-master:9000/user/${SYS_USERNAME}/spark-warehouse" 
update_spark_defaults "spark.driver.memory" "${MEM_DRV}"
update_spark_defaults "spark.executor.memory" "${MEM_EXE}"
sed -i -e "/^spark.sql.catalogImplementation/d" \
        -e "/^spark.sql.hive.metastore.version/d" \
        -e "/^spark.sql.hive.metastore.sharedPrefixes/d" \
        -e "/^spark.sql.hive.metastore.jars/d" \
        -e "/^spark.sql.hive.metastore.jars.path/d" \
        -e "/^spark.driver.extraJavaOptions/d" \
        "${SPARK_HOME}/conf/spark-defaults.conf" # Remove parameters related to hive. These values will be replaced later, if hive external is enabled.
if grep -q "^spark.driver.extraJavaOptions" "${SPARK_HOME}/conf/spark-defaults.conf"; then
    update_spark_defaults "spark.driver.extraJavaOptions" "-Dderby.system.home=${HOME}/derby-metastore -Dderby.stream.error.file=${HOME}/derby-metastore/derby.log"
else
    append_spark_config "spark.driver.extraJavaOptions" "-Dderby.system.home=${HOME}/derby-metastore -Dderby.stream.error.file=${HOME}/derby-metastore/derby.log"
fi
###

###
#### Init services
case "$1" in
    HIVE)
        ###
        #### Hive properties
        # Add parameters to spark-defaults.conf to configure hive external with postgresql metastore
        sed -i "/^spark.driver.extraJavaOptions/d" "${SPARK_HOME}/conf/spark-defaults.conf"
        # Append configurations related to hive
        append_spark_config "spark.sql.catalogImplementation" "hive"
        append_spark_config "spark.sql.hive.metastore.version" "3.1.3"
        append_spark_config "spark.sql.hive.metastore.sharedPrefixes" "org.postgresql"
        append_spark_config "spark.sql.hive.metastore.jars" "path"
        append_spark_config "spark.sql.hive.metastore.jars.path" "file://${HIVE_HOME}/lib/*"

        # Update hive-site.xml
        update_xml_values "javax.jdo.option.ConnectionURL" "jdbc:postgresql:\/\/postgres-db:5432\/${PSQL_DBNAME}?createDatabaseIfNotExist=true" "${HIVE_HOME}/conf/hive-site.xml"
        update_xml_values "javax.jdo.option.ConnectionUserName" "${PSQL_PGUSER}" "${HIVE_HOME}/conf/hive-site.xml"
        update_xml_values "javax.jdo.option.ConnectionPassword" "${PSQL_PGPASSWORD}" "${HIVE_HOME}/conf/hive-site.xml"

        # Replicate hive-site.xml and spark-defaults.conf to all nodes in the cluster
        while IFS= read -r ip; do
            scp -q "${HIVE_HOME}/conf/hive-site.xml" "$ip:${HIVE_HOME}/conf/"
            scp -q "${SPARK_HOME}/conf/spark-defaults.conf" "$ip:${SPARK_HOME}/conf/"
        done < ${HOME}/.hostlist

        # Check if postgresql is ready to initialize hive metastore schema
        if ! ssh -o "ConnectTimeout=1" "${IP_DB}" exit >/dev/null 2>&1; then
            printf "${INFO} Checking hive metastore schema status${RESET_COLORS}...\n"
            CHECKSCHEMA=`echo "$(PGPASSWORD=${PSQL_PGPASSWORD} psql -h postgres-db -U ${PSQL_PGUSER} -d ${PSQL_DBNAME} -c '\dt "BUCKETING_COLS"')" | grep -o "1 row" | wc -l`
            if [ ${CHECKSCHEMA} -eq 0 ]; then
                printf "${INFO} Initializing hive metastore schema${RESET_COLORS}...\n"
                schematool -initSchema -dbType postgres
            fi
        else
            printf "${WARN} Metastore container is not responding. Cannot create schema. Exiting.${RESET_COLORS}\n"
            exit 1
        fi

        # Start hiveserver2
        /bin/bash ${HIVE_HOME}/bin/hiveserver2
        ;;

    HADOOP)
        # Initialize hadoop services (only at node-master)
        if [ "${HOSTNAME}" == "node-master" ] ; then

            # Format HDFS
            printf "${INFO} Formatting filesystem${RESET_COLORS}...\n"
            hdfs namenode -format -nonInteractive

            # Start HDFS and YARN services
            # Test if all workers are alive and ready to create the cluster
            ATTEMPTS=0
            while true
            do
                printf "${INFO} Waiting for WORKERS to be ready${RESET_COLORS}...\n"
                WORKERS_REACHABLE=true
                # Read the file containing the IP addresses
                while IFS= read -r ip; do
                    if ! ssh -o "ConnectTimeout=1" "$ip" exit >/dev/null 2>&1; then
                        # If any worker node is not reachable, set WORKERS_REACHABLE to false and break the loop
                        WORKERS_REACHABLE=false
                        break
                    fi
                done < ${HOME}/.hostlist
                if ${WORKERS_REACHABLE}; then
                    # If all worker nodes are reachable, start hdfs and yarn and exit the loop
                    printf "${INFO} Starting HDFS and YARN services${RESET_COLORS}...\n"
                    sleep 1
                    start-dfs.sh
                    sleep 1
                    start-yarn.sh
                    break
                fi
                # Wait before checking again
                sleep 5

                ATTEMPTS=$((ATTEMPTS+1))
                if [ ${ATTEMPTS} -ge 10 ]; then
                    printf "${WARN} There are no reachable WORKERS. Exiting.${RESET_COLORS}\n"
                    exit 1
                fi
            done

            sleep 1

            # Creating /user folders inside HDFS
            FILE=.first_boot
            if [ ! -e "${FILE}" ] ; then
                # Check if there are live datanodes in the cluster
                if hdfs dfsadmin -report | grep -q "Live datanodes"; then
                    printf "${INFO} Creating folders in HDFS${RESET_COLORS}...\n"
                    hdfs dfs -mkdir -p /user/${HDFS_NAMENODE_USER}
                    hdfs dfs -mkdir /spark-logs
                    hdfs dfs -mkdir /spark-libs
                    hdfs dfs -mkdir -p /tmp/hive
                    printf "${INFO} Copying spark libs to HDFS${RESET_COLORS}...\n"
                    hdfs dfs -put ${SPARK_HOME}/jars/*.jar /spark-libs/
                else
                    printf "${WARN} There are no live nodes in the cluster. Exiting.${RESET_COLORS}\n"
                    exit 1
                fi
                # Creating .first_boot file as a flag to indicate that first boot has already done
                touch ${FILE}
            fi
            
            # Starting SPARK history server
            printf "${INFO} Starting SPARK history server${RESET_COLORS}...\n"
            start-history-server.sh

            # Checking HDFS status (optional)
            printf "${INFO} Checking HDFS nodes report${RESET_COLORS}...\n"
            hdfs dfsadmin -report

            # Checking YARN status (optional)
            printf "${INFO} Checking YARN nodes list${RESET_COLORS}...\n"
            yarn node -list

            printf "\n${INFO} ${GREEN_COLOR}$(tput blink)ALL SET!${RESET_COLORS}\n\n"
            printf "TIP: To access node-master, type: ${YELLOW_COLOR}docker exec -it node-master /bin/bash${RESET_COLORS}\n"
        fi
        # Starting bash terminal
        /bin/bash
        ;;
esac

unset PSQL_PGUSER
unset PSQL_PGPASSWORD
unset USERNAME
unset PASSWORD
