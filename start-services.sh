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
# This is a bash script to initialize services

# Some coloring
RED_COLOR=$(tput setaf 1)
GREEN_COLOR=$(tput setaf 2) 
YELLOW_COLOR=$(tput setaf 3)
LIGHTBLUE_COLOR=$(tput setaf 6)
RESET_COLORS=$(tput sgr0)
INFO="[${GREEN_COLOR}INFO${RESET_COLORS}]${LIGHTBLUE_COLOR}"
WARN="[${RED_COLOR}ERROR${RESET_COLORS}]${YELLOW_COLOR}"
BOOT_STATUS=false

# Format HDFS
if [ ! -d "$(grep -A2 '<name>dfs.namenode.name.dir</name>' "${HADOOP_CONF_DIR}/hdfs-site.xml" | grep '<value>' | sed -E 's/.*<value>(.*)<\/value>.*/\1/')/current" ]; then
    printf "${INFO} Formatting filesystem${RESET_COLORS}...\n"
    HADOOP_ROOT_LOGGER=ERROR,console hdfs namenode -format -nonInteractive
fi

# Start HDFS and YARN services
# Test if all workers are alive and ready to create the cluster
ATTEMPTS=0
while true
do
    printf "${INFO} Waiting for WORKERS to be ready${RESET_COLORS}...\n"
    WORKERS_REACHABLE=true
    # Read the file containing the IP addresses
    while IFS= read -r worker; do
        if ! ssh -o "ConnectTimeout=3" "$worker" exit >/dev/null 2>&1; then
            # If any worker node is not reachable, set WORKERS_REACHABLE to false and break the loop
            WORKERS_REACHABLE=false
            break
        fi
    done < ${HADOOP_CONF_DIR}/workers
    if ${WORKERS_REACHABLE}; then
        # If all worker nodes are reachable, start hdfs and yarn and exit the loop
        printf "${INFO} Starting HDFS and YARN services${RESET_COLORS}...\n"
        sleep 1
        start-dfs.sh && start-yarn.sh
        sleep 1
        mapred --daemon start historyserver
        break
    fi
    # Wait before checking again
    sleep 5

    ATTEMPTS=$((ATTEMPTS+1))
    if [ ${ATTEMPTS} -ge 10 ]; then
        printf "${WARN} There are no reachable WORKERS. Please, check config files.${RESET_COLORS}\n"
    fi
done

sleep 1

# Creating /user folders inside HDFS
if ! hdfs dfs -test -d "/user/${HDFS_NAMENODE_USER}"; then
    # Check if there are live datanodes in the cluster
    if hdfs dfsadmin -report | grep -q "Live datanodes"; then
        printf "${INFO} Creating folders in HDFS${RESET_COLORS}...\n"
        hdfs dfs -mkdir -p "/user/${HDFS_NAMENODE_USER}" /spark-logs /spark-libs
        printf "${INFO} Copying spark libs to HDFS${RESET_COLORS}...\n"
        hdfs dfs -put "${SPARK_HOME}/jars/"*.jar /spark-libs/
        BOOT_STATUS=true
    else
        printf "${WARN} There are no live nodes in the cluster. Please, check config files.${RESET_COLORS}\n"
        BOOT_STATUS=false
    fi
else
    BOOT_STATUS=true
fi

# Starting SPARK history server
printf "${INFO} Starting SPARK history server${RESET_COLORS}...\n"
start-history-server.sh > /dev/null 2>&1

# Starting spark connect server (optional)
if [[ "${SPARK_CONNECT_SERVER}" == "enable" ]] ; then
    printf "${INFO} Starting SPARK CONNECT server${RESET_COLORS}...\n"
    start-connect-server.sh --packages org.apache.spark:spark-connect_2.12:${SPARK_VERSION}
fi

# Checking HDFS status (optional)
printf "${INFO} Checking HDFS nodes report${RESET_COLORS}...\n"
hdfs dfsadmin -report

# Checking YARN status (optional)
printf "${INFO} Checking YARN nodes list${RESET_COLORS}...\n"
yarn node -list

if [ "$BOOT_STATUS" = "true" ]; then
    printf "\n${INFO} ${GREEN_COLOR}$(tput blink)ALL SET!${RESET_COLORS}\n\n"
    printf "TIP: To access spark-master, type: ${YELLOW_COLOR}docker exec -it spark-master bash${RESET_COLORS}\n\n"
    printf "The following services are now available for access through web browser:\n
    http://localhost:${LIGHTBLUE_COLOR}9870 \t ${YELLOW_COLOR}HDFS${RESET_COLORS}
    http://localhost:${LIGHTBLUE_COLOR}8088 \t ${YELLOW_COLOR}YARN Scheduler${RESET_COLORS}
    http://localhost:${LIGHTBLUE_COLOR}19888 \t ${YELLOW_COLOR}MAPRED Job History${RESET_COLORS}
    http://localhost:${LIGHTBLUE_COLOR}18080 \t ${YELLOW_COLOR}SPARK History Server${RESET_COLORS}\n\n"
fi
