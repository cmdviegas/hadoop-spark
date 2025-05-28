#!/usr/bin/env bash
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

# Description: Manages individual Hadoop/Spark/Jupyter services

# Log helpers
log_info()  { printf "%b %s\n" "${INFO}" "$1"; }
log_error() { printf "%b %s\n" "${ERROR}" "$1"; }

[ -f "${HOME}/.env" ] && . "${HOME}/.env" # Load environment variables

BOOT_STATUS="false" # Used to indicate if the script was run without any errors

# Sets JAVA_HOME dynamically based on Java version installed
setup_java_home() {
    local hadoop_env_file="${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
    local current_java_home
    
    # Check if hadoop-env.sh exists
    if [ ! -f "${hadoop_env_file}" ]; then
        log_error "hadoop-env.sh not found at ${hadoop_env_file}"
        return 1
    fi
    
    # Extract current JAVA_HOME from hadoop-env.sh
    current_java_home=$(grep "^export JAVA_HOME=" "${hadoop_env_file}" 2>/dev/null | sed 's/^export JAVA_HOME="\(.*\)"/\1/' | sed "s/^export JAVA_HOME=\(.*\)/\1/")
    
    # Remove quotes if present
    current_java_home=$(echo "${current_java_home}" | sed 's/^"\(.*\)"$/\1/')
    
    # Check if JAVA_HOME is already correctly set
    if [ "${current_java_home}" = "${JAVA_HOME}" ]; then
        # log_info "JAVA_HOME already correctly configured in hadoop-env.sh: ${JAVA_HOME}"
        return 0
    fi
    
    # Perform the update
    if sed "s|^export JAVA_HOME=.*|export JAVA_HOME=\"${JAVA_HOME}\"|" "${hadoop_env_file}" > "${hadoop_env_file}.tmp_hadoop_env"; then
        if cp "${hadoop_env_file}.tmp_hadoop_env" "${hadoop_env_file}" && rm "${hadoop_env_file}.tmp_hadoop_env"; then
            # log_info "JAVA_HOME successfully updated in hadoop-env.sh"
            return 0
        else
            log_error "Failed to update hadoop-env.sh. JAVA_HOME may not be set correctly."
            rm -f "${hadoop_env_file}.tmp_hadoop_env" 2>/dev/null
            return 1
        fi
    else
        log_error "Failed to process hadoop-env.sh. JAVA_HOME may not be set correctly."
        return 1
    fi
}

# Starts JAVA_HOME setup
setup_java_home

# Check worker nodes connectivity
check_workers() {
    local worker_count=0
    while IFS= read -r worker || [[ -n "${worker}" ]]; do
        [ -z "${worker}" ] && continue
        #printf "${INFO} Connecting to ${YELLOW_COLOR}%s${RESET_COLORS}..." "$worker"
        if ssh -o "ConnectTimeout=1" "${worker}" "exit" >/dev/null 2>&1 < /dev/null; then
            #printf " ${GREEN_COLOR}successful${RESET_COLORS}!\n"
            worker_count=$((worker_count + 1))
        #else
            #printf " ${RED_COLOR}failed${RESET_COLORS}!\n"
        fi
    done < "${HADOOP_CONF_DIR}/workers"
    
    if [ "${worker_count}" -ge 1 ]; then
        #log_info "Found ${YELLOW_COLOR}${worker_count}${RESET_COLORS} active worker(s)"
        return 0
    else
        log_error "There are no worker nodes active. You need at least one active worker to start HDFS or YARN services."
        return 1
    fi
}

# HDFS Service Management
start_hdfs() {
    local hdfs_status

    # Format HDFS (if necessary)
    printf "%b %s" "${INFO}" "Checking HDFS in namenode..."
    # Check if there is any existing NameNode process
    if [ -n "$(pgrep -f 'org.apache.hadoop.hdfs.server.namenode.NameNode')" ]; then
        stop_hdfs # Stop any existing NameNode process
    fi
    hdfs_status=$(HADOOP_ROOT_LOGGER=ERROR,console hdfs namenode -format -nonInteractive 2>&1)
    if echo "$hdfs_status" | grep -q "Not formatting."; then
        printf " already formatted! Skipping...\n"
    else
        printf " format done!\n"
    fi
    
    log_info "Starting HDFS service..."
    # Check workers before starting
    if ! check_workers; then
        # log_error "Cannot start HDFS without reachable workers."
        BOOT_STATUS=false
        return 1
    fi
    
    start-dfs.sh
    sleep 1
    
    # Creates HDFS directories
    if hdfs dfsadmin -report | grep -q "Live datanodes"; then
        log_info "Preparing HDFS directories..."
        hdfs dfs -mkdir -p \
            "/user/${HDFS_NAMENODE_USER}" \
            "/user/${HDFS_NAMENODE_USER}/hadoopLogs" \
            "/user/${HDFS_NAMENODE_USER}/sparkLogs" \
            "/user/${HDFS_NAMENODE_USER}/sparkWarehouse" \
            "/sparkLibs"
        hdfs dfs -put "${SPARK_HOME}/jars/"*.jar /sparkLibs/ 2>/dev/null
        printf "       HDFS user folder: ${YELLOW_COLOR}$(hdfs getconf -confKey fs.defaultFS)/user/${HDFS_NAMENODE_USER}${RESET_COLORS}\n"
        printf "       Local folder for namenode: ${YELLOW_COLOR}$(hdfs getconf -confKey dfs.namenode.name.dir | tr '\n' ' ')${RESET_COLORS}\n"
        printf "       Local folder for datanode: ${YELLOW_COLOR}$(hdfs getconf -confKey dfs.datanode.data.dir | tr '\n' ' ')${RESET_COLORS}\n"
        BOOT_STATUS=true
    else
        BOOT_STATUS=false
        log_error "HDFS has no live datanodes. Please check the configuration."
        return 1
    fi
}

stop_hdfs() {
    stop-dfs.sh > /dev/null 2>&1
}

# YARN Service Management
start_yarn() {
    log_info "Starting YARN service..."
       
    if ! check_workers; then
        # log_error "Cannot start YARN without reachable workers."
        return 1
    fi

    # Check if there is any existing ResourceManager process
    if [ -n "$(pgrep -f 'org.apache.hadoop.yarn.server.resourcemanager.ResourceManager')" ]; then
        stop_yarn # Stop any existing ResourceManager process
        sleep 1
    fi
    start-yarn.sh # Start YARN ResourceManager and NodeManagers    
}

stop_yarn() {
    stop-yarn.sh > /dev/null 2>&1
}

# MapReduce History Service Management
start_mapred_history() {   
    # Check if there is any existing NameNode process
    if [ -z "$(pgrep -f 'org.apache.hadoop.hdfs.server.namenode.NameNode')" ]; then
        log_error "HDFS is not running on NameNode. Please start HDFS first in order to run MapReduce History Server."
        return 1
    fi

    log_info "Starting MapReduce History Server..."
    # Check if there is any existing MapReduce JobHistoryServer process
    if [ -n "$(pgrep -f 'org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer')" ]; then
        stop_mapred_history
    fi
    # Starts the MapReduce History Server
    mapred --daemon start historyserver
}

stop_mapred_history() {
    # Stops the MapReduce History Server
    mapred --daemon stop historyserver
}

# Spark History Service Management
start_spark_history() {
    log_info "Starting Spark History Server..."  

    # Check if there is any existing HistoryServer process
    if [ -n "$(pgrep -f 'org.apache.spark.deploy.history.HistoryServer')" ]; then
        stop_spark_history
    fi
    # Starts the Spark History Server
    start-history-server.sh
}

stop_spark_history() {
    # Stops the Spark History Server
    stop-history-server.sh > /dev/null 2>&1
}

# Jupyter Lab Service Management
start_jupyterlab() {
    # Constants
    local server_ip="0.0.0.0"
    local port="8888"
    local root_dir="${HOME}/myfiles"

    # Check if already running
    if pgrep -f "jupyter-lab" > /dev/null; then
        log_info "Jupyter Lab is already running. Stop it first if you want to restart."
        return 0
    fi
    
    log_info "Starting Jupyter Lab..."
    mkdir -p "${HOME}/.jupyter"
    # Starts Jupyter Lab in the background
    nohup jupyter lab \
        --ServerApp.ip="${server_ip}" \
        --ServerApp.port="${port}" \
        --ServerApp.open_browser=False \
        --ServerApp.root_dir="${root_dir}" \
        --IdentityProvider.token='' \
        --PasswordIdentityProvider.password_required=False > "${HOME}/.jupyter/jupyter.log" 2>&1 &
}

stop_jupyterlab() {
    # Stops Jupyter Lab if running
    pgrep -f "jupyter-lab" | xargs -r kill
}

# Spark Connect Service Management
start_spark_connect() {    
    if [[ "${SPARK_CONNECT_SERVER}" == "enable" ]]; then
        log_info "Starting Spark Connect Server..."
        start-connect-server.sh --packages org.apache.spark:spark-connect_2.12:${SPARK_VERSION} 
    else
        log_error "Spark Connect Server is disabled in configuration"
        return 1
    fi
}

stop_spark_connect() {
    stop-connect-server.sh > /dev/null 2>&1
}

# Status check functions - checks if services are running
check_service_status() {
    local service_name="$1"
    local process_name="$2"  
    local app_url="$3"

    local pid
    pid=$(pgrep -f "${process_name}" | head -n 1)
    printf "       ${YELLOW_COLOR}%-18s${RESET_COLORS}: " "${service_name}"
    if [ -n "${pid}" ]; then
        printf "${GREEN_COLOR}RUNNING${RESET_COLORS} (PID: %5d)   Available on: ${app_url}" "${pid}"
        printf "\n"
    else
        printf "${RED_COLOR}STOPPED${RESET_COLORS}\n"
    fi
}

status_all_services() {
    log_info "Checking status of all services..."    
    # Check HDFS
    check_service_status "HDFS" "org.apache.hadoop.hdfs.server.namenode.NameNode" "http://localhost:${LIGHTBLUE_COLOR}9870${RESET_COLORS}"
    # Check YARN
    check_service_status "YARN" "org.apache.hadoop.yarn.server.resourcemanager.ResourceManager" "http://localhost:${LIGHTBLUE_COLOR}8088${RESET_COLORS}"
    # Check MapReduce History Server
    check_service_status "MapReduce History" "org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer" "http://localhost:${LIGHTBLUE_COLOR}19888${RESET_COLORS}"
    # Check Spark History Server
    check_service_status "Spark History" "org.apache.spark.deploy.history.HistoryServer" "http://localhost:${LIGHTBLUE_COLOR}18080${RESET_COLORS}"
    # Check Jupyter Lab
    check_service_status "Jupyter Lab" "jupyter-lab" "http://localhost:${LIGHTBLUE_COLOR}8888${RESET_COLORS}"
    # Check Spark Connect Server (if enabled)
    if [[ "${SPARK_CONNECT_SERVER}" == "enable" ]]; then
        check_service_status "Spark Connect" "org.apache.spark.sql.connect.service.SparkConnectServer" "http://localhost:${LIGHTBLUE_COLOR}15002${RESET_COLORS}"
    fi
}

# Report functions - detailed reports for HDFS and YARN
report_hdfs() {
    log_info "Generating HDFS report..."
    hdfs dfsadmin -report
}

report_yarn() {
    log_info "Generating YARN report..."
    yarn node -list
}

report() {
    report_hdfs
    report_yarn
}

# Usage function
show_usage() {
    printf "Usage: $(basename "$0") [ACTION] [SERVICE]\n\n"
    printf "Actions:  start | stop | status | report\n"
    printf "Services: hdfs | yarn | mapred-history | spark-history | jupyterlab | spark-connect | all\n\n"
    printf "Examples:\n"
    printf "  $(basename "$0") start hdfs\n"
    printf "  $(basename "$0") stop yarn\n"
    printf "  $(basename "$0") status\n"
    printf "  $(basename "$0") report\n"
}

# Legacy functions for 'all' service
start_all_services() {
    start_hdfs && \
    start_yarn && \
    start_mapred_history && \
    start_spark_history && \
    start_jupyterlab && \
    if [[ "${SPARK_CONNECT_SERVER}" == "enable" ]]; then
        start_spark_connect
    fi
    sleep 2
    status_all_services

    if [[ "$BOOT_STATUS" == "true" ]]; then
        printf "\n"
        log_info "$(tput blink)ALL SET!${RESET_COLORS}"
        printf "\n       TIP: To access ${YELLOW_COLOR}spark-master${RESET_COLORS} terminal, type: ${YELLOW_COLOR}docker exec -it spark-master bash${RESET_COLORS}\n\n"
    else
        log_error "Some errors occurred. Please review them and try again."
    fi
}

stop_all_services() {
    stop_spark_connect
    stop_jupyterlab
    stop_spark_history
    stop_mapred_history
    stop_yarn
    stop_hdfs

    sleep 1

    status_all_services
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Handle legacy single parameter usage
if [ $# -eq 1 ]; then
    case "$1" in
        start)
            start_all_services
            ;;
        stop)
            stop_all_services
            ;;
        status)
            status_all_services
            ;;
        report)
            report
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
    exit 0
fi

# Handle new two parameter usage
if [ $# -eq 2 ]; then
    action="$1"
    service="$2"

    case "${action}" in
        start)
            case "${service}" in
                hdfs) start_hdfs ;;
                yarn) start_yarn ;;
                mapred-history) start_mapred_history ;;
                spark-history) start_spark_history ;;
                jupyterlab) start_jupyterlab ;;
                spark-connect) start_spark_connect ;;
                all) start_all_services ;;
                *) show_usage; exit 1 ;;
            esac
            ;;
        stop)
            case "${service}" in
                hdfs) stop_hdfs ;;
                yarn) stop_yarn ;;
                mapred-history) stop_mapred_history ;;
                spark-history) stop_spark_history ;;
                jupyterlab) stop_jupyterlab ;;
                spark-connect) stop_spark_connect ;;
                all) stop_all_services ;;
                *) show_usage; exit 1 ;;
            esac
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
    exit 0
fi

# If more than 2 parameters
show_usage
exit 1
