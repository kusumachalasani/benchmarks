#!/bin/bash
#
# Copyright (c) 2020, 2021 IBM Corporation, RedHat and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
### Script to parse prometheus query data###


CURRENT_DIR="$(dirname "$(realpath "$0")")"
source ${CURRENT_DIR}/../utils/common.sh

# Parse CPU, memeory and cluster information
# input:type of run(warmup|measure), total number of runs, iteration number
# output:Creates cpu, memory and cluster information in the form of log files for each run
function parsePromMetrics()  {
	TYPE=$1
	TOTAL_RUNS=$2
	ITR=$3

	for (( run=0 ; run<"${TOTAL_RUNS}" ;run++))
	do
		for poddatalog in "${POD_CPU_LOGS[@]}"
		do
			# Parsing CPU, app metric logs for pod
			parsePodDataLog ${poddatalog} ${TYPE} ${run} ${ITR}
		done
		for podmemlog in "${POD_MEM_LOGS[@]}"
		do
			# Parsing Mem logs for pod
			parsePodMemLog ${podmemlog} ${TYPE} ${run} ${ITR}
		done
	done

	for podmmlog in "${MICROMETER_LOGS[@]}"
	do
		parsePodMicroMeterLog ${podmmlog} ${TYPE} ${ITR}
	done

	## Calculate response time
        if [ -s ${RESULTS_DIR_J}/app_timer_sum-${TYPE}-${ITR}.log ]; then
                total_seconds_sum=`cat ${RESULTS_DIR_J}/app_timer_sum-${TYPE}-${ITR}.log`
                # Convert seconds to ms to avoid 0 as response time.
                total_milliseconds_sum=$(echo ${total_seconds_sum}*1000 | bc -l)
                total_seconds_count=`cat ${RESULTS_DIR_J}/app_timer_count-${TYPE}-${ITR}.log`
                rsp_time=$(echo ${total_milliseconds_sum}/${total_seconds_count}| bc -l)
                throughput=$(echo ${total_seconds_count}/${total_seconds_sum}| bc -l)
                echo ${rsp_time} > ${RESULTS_DIR_J}/app_timer_rsp_time-${TYPE}-${ITR}.log
                echo ${throughput} > ${RESULTS_DIR_J}/app_timer_thrpt-${TYPE}-${ITR}.log
        fi

        ## Calculate rsp_time_rate and thrpt_rate
        if [ -s ${RESULTS_DIR_J}/app_timer_sum_rate_3m-${TYPE}-${ITR}.log ]; then
                app_sum_rate_3m=`cat ${RESULTS_DIR_J}/app_timer_sum_rate_3m-${TYPE}-${ITR}.log`
                # Convert seconds to ms to avoid 0 as response time.
                app_sum_rate_3m_inms=$(echo ${app_sum_rate_3m}*1000 | bc -l)
                app_count_rate_3m=`cat ${RESULTS_DIR_J}/app_timer_count_rate_3m-${TYPE}-${ITR}.log`
                rsp_time_rate_3m=$(echo ${app_sum_rate_3m_inms}/${app_count_rate_3m}| bc -l)
                throughput_rate_3m=$(echo ${app_count_rate_3m}| bc -l)
                echo ${rsp_time_rate_3m} > ${RESULTS_DIR_J}/app_timer_rsp_time_rate_3m-${TYPE}-${ITR}.log
                echo ${throughput_rate_3m} > ${RESULTS_DIR_J}/app_timer_thrpt_rate_3m-${TYPE}-${ITR}.log
        fi

	## Raw data
        echo "${ITR}, ${throughput} , ${rsp_time} , ${throughput_rate_3m} , ${rsp_time_rate_3m} " >> ${RESULTS_DIR_J}/../app-calc-metrics-${TYPE}-raw.log

	## Calculate response time
        if [ -s ${RESULTS_DIR_J}/server_requests_sum-${TYPE}-${ITR}.log ]; then
                total_seconds_sum=`cat ${RESULTS_DIR_J}/server_requests_sum-${TYPE}-${ITR}.log`
                # Convert seconds to ms to avoid 0 as response time.
                total_milliseconds_sum=$(echo ${total_seconds_sum}*1000 | bc -l)
                total_seconds_count=`cat ${RESULTS_DIR_J}/server_requests_count-${TYPE}-${ITR}.log`
                rsp_time=$(echo ${total_milliseconds_sum}/${total_seconds_count}| bc -l)
                throughput=$(echo ${total_seconds_count}/${total_seconds_sum}| bc -l)
                echo ${rsp_time} > ${RESULTS_DIR_J}/server_requests_rsp_time-${TYPE}-${ITR}.log
                echo ${throughput} > ${RESULTS_DIR_J}/server_requests_thrpt-${TYPE}-${ITR}.log
        fi

        ## Calculate rsp_time_rate and thrpt_rate
        if [ -s ${RESULTS_DIR_J}/server_requests_sum_rate_3m-${TYPE}-${ITR}.log ]; then
                app_sum_rate_3m=`cat ${RESULTS_DIR_J}/server_requests_sum_rate_3m-${TYPE}-${ITR}.log`
                # Convert seconds to ms to avoid 0 as response time.
                app_sum_rate_3m_inms=$(echo ${app_sum_rate_3m}*1000 | bc -l)
                app_count_rate_3m=`cat ${RESULTS_DIR_J}/server_requests_count_rate_3m-${TYPE}-${ITR}.log`
                rsp_time_rate_3m=$(echo ${app_sum_rate_3m_inms}/${app_count_rate_3m}| bc -l)
                throughput_rate_3m=$(echo ${app_count_rate_3m}| bc -l)
                echo ${rsp_time_rate_3m} > ${RESULTS_DIR_J}/server_requests_rsp_time_rate_3m-${TYPE}-${ITR}.log
                echo ${throughput_rate_3m} > ${RESULTS_DIR_J}/server_requests_thrpt_rate_3m-${TYPE}-${ITR}.log
        fi

	## Raw data
	echo "${ITR}, ${throughput} , ${rsp_time} , ${throughput_rate_3m} , ${rsp_time_rate_3m} " >> ${RESULTS_DIR_J}/../server_requests-metrics-${TYPE}-raw.log
}

# Parsing micrometer metrics logs for pod
# input: app_timer logs array element, type of run(warmup|measure), run(warmup|measure) number, iteration number
# output:creates cpu log for pod
function parsePodMicroMeterLog()
{
	MODE=$1
	TYPE=$2
	ITR=$3
	RESULTS_LOG=${MODE}-${TYPE}-${ITR}.log
	data_sum=0
	data_min=0
	data_max=0
		if [ ${TYPE} == "measure" ]; then
			last_measure_number=$(echo ${MEASURES}-1 | bc)
		elif [ ${TYPE} == "warmup" ]; then
			last_measure_number=$(echo ${WARMUPS}-1 | bc)
		fi
		
		if [ ${MODE} == "app_timer_count" ] || [ ${MODE} == "app_timer_sum" ] || [ ${MODE} == "server_requests_count" ] || [ ${MODE} == "server_requests_sum" ]; then
                        if [ -s "${RESULTS_DIR_P}/${MODE}-${TYPE}-0.json" ]; then
                                cat ${RESULTS_DIR_P}/${MODE}-${TYPE}*.json | cut -d ";" -f4 | cut -d '"' -f1 | uniq | grep -v "^$" | sort -n  > ${RESULTS_DIR_P}/temp-data.log
                                start_counter=`cat ${RESULTS_DIR_P}/temp-data.log | head -1`
                                end_counter=`cat ${RESULTS_DIR_P}/temp-data.log | tail -1`
                                counter_val=$(echo ${end_counter}-${start_counter}| bc -l)
                                echo "${counter_val}" > ${RESULTS_DIR_J}/${MODE}-${TYPE}-${ITR}.log
                        fi
                elif [[ ${MODE} == *"app_timer_count_rate"* ]] || [[ ${MODE} == *"app_timer_sum_rate"* ]] || [[ ${MODE} == *"server_requests_count_rate"* ]] || [[ ${MODE} == *"server_requests_sum_rate"* ]]; then
                        if [ -s "${RESULTS_DIR_P}/${MODE}-${TYPE}-${last_measure_number}.json" ]; then
                                cat ${RESULTS_DIR_P}/${MODE}-${TYPE}-${last_measure_number}.json | cut -d ";" -f4 | cut -d "\"" -f1 | tail -1 > ${RESULTS_DIR_J}/${MODE}-${TYPE}-${ITR}.log
                        fi
                elif [ ${MODE} == "latency_seconds_max" ] || [ ${MODE} == "server_requests_max" ]; then
                        if [ -s "${RESULTS_DIR_P}/${MODE}-${TYPE}-0.json" ]; then
                                cat ${RESULTS_DIR_P}/${MODE}-* | cut -d ";" -f4 | cut -d "\"" -f1 | uniq | grep -v "^$" | sort -n | tail -1 > ${RESULTS_DIR_J}/${MODE}-${TYPE}-${ITR}.log
                        fi
                elif [[ ${MODE} == *"latency_seconds_quan"* ]] ; then
                        if [ -s "${RESULTS_DIR_P}/${MODE}-${TYPE}-${last_measure_number}.json" ]; then
                                cat ${RESULTS_DIR_P}/${MODE}-${TYPE}-${last_measure_number}.json | cut -d ";" -f4 | cut -d "\"" -f1 | uniq | grep -v "^$" | sort -n |  tail -1 > ${RESULTS_DIR_J}/${MODE}-${TYPE}-${ITR}.log
                        fi
                fi
}

# Parsing CPU logs for pod
# input: podcpulogs array element, type of run(warmup|measure), run(warmup|measure) number, iteration number
# output:creates cpu log for pod
function parsePodDataLog()
{
	MODE=$1
	TYPE=$2
	RUN=$3
	ITR=$4
	RESULTS_LOG=${MODE}-${TYPE}-${ITR}.log
	data_sum=0
	data_min=0
	data_max=0
	DATA_LOG=${RESULTS_DIR_P}/${MODE}-${TYPE}-${RUN}.json
	RUN_PODS=($(cat ${DATA_LOG} | cut -d ";" -f2 | sort | uniq))
	for run_pod in "${RUN_PODS[@]}"
	do
		if [ -s "${DATA_LOG}" ]; then
                        cat ${DATA_LOG} | grep ${run_pod} | cut -d ";" -f4 | cut -d '"' -f1 > ${RESULTS_DIR_P}/temp-data.log
                        each_pod_data_avg=$( echo `calcAvg ${RESULTS_DIR_P}/temp-data.log | cut -d "=" -f2`  )
                        each_pod_data_min=$( echo `calcMin ${RESULTS_DIR_P}/temp-data.log` )
                        each_pod_data_max=$( echo `calcMax ${RESULTS_DIR_P}/temp-data.log` )
                        data_sum=$(echo ${data_sum}+${each_pod_data_avg}| bc -l)
                        data_min=$(echo ${data_min}+${each_pod_data_min}| bc -l)
                        data_max=$(echo ${data_max}+${each_pod_data_max} | bc -l)
                fi
	done
	echo "${run} , ${data_sum}, ${data_min} , ${data_max}" >> ${RESULTS_DIR_J}/${RESULTS_LOG}
	echo ",${data_sum} , ${data_min} , ${data_max}" >> ${RESULTS_DIR_J}/${MODE}-${TYPE}-raw.log
}

# Parsing memory logs for pod
# input: podmemlogs array element, type of run(warmup|measure), run(warmup|measure) number, iteration number
# output:creates memory log for pod
function parsePodMemLog()
{
	MODE=$1
	TYPE=$2
	RUN=$3
	ITR=$4
	RESULTS_LOG=${MODE}-${TYPE}-${ITR}.log
	mem_sum=0
	mem_min=0
	mem_max=0

	MEM_LOG=${RESULTS_DIR_P}/${MODE}-${TYPE}-${RUN}.json
	MEM_PODS=($(cat ${MEM_LOG} | cut -d ";" -f2 | sort | uniq))
	for mem_pod in "${MEM_PODS[@]}"
	do
		if [ -s "${MEM_LOG}" ]; then
                        cat ${MEM_LOG} | grep ${mem_pod} | cut -d ";" -f4 | cut -d '"' -f1 > ${RESULTS_DIR_P}/temp-mem.log
                        each_pod_mem_avg=$( echo `calcAvg_inMB ${RESULTS_DIR_P}/temp-mem.log | cut -d "=" -f2`  )
                        each_pod_mem_min=$( echo `calcMin ${RESULTS_DIR_P}/temp-mem.log`  )
                        each_pod_mem_min_inMB=$(echo ${each_pod_mem_min}/1024/1024 | bc)
                        each_pod_mem_max=$( echo `calcMax ${RESULTS_DIR_P}/temp-mem.log`  )
                        each_pod_mem_max_inMB=$(echo ${each_pod_mem_max}/1024/1024 | bc)
                        mem_sum=$(echo ${mem_sum}+${each_pod_mem_avg} | bc)
                        mem_min=$(echo ${mem_min}+${each_pod_mem_min_inMB} | bc)
                        mem_max=$(echo ${mem_max}+${each_pod_mem_max_inMB} | bc)
                fi
	done
	echo "${run} , ${mem_sum}, ${mem_min} , ${mem_max} " >> ${RESULTS_DIR_J}/${RESULTS_LOG}
	echo ", ${mem_sum} , ${mem_min} , ${mem_max} " >> ${RESULTS_DIR_J}/${MODE}-${TYPE}-raw.log
}

# Parsing memory logs for pod
# input: clusterlogs array element, json file with cluster information, result log file
# output:creates clsuter log file
function parseClusterLog() {
	MODE=$1
	CLUSTER_LOG=$2
	CLUSTER_RESULTS_LOG=$3
	if [ -s ${CLUSTER_LOG} ]; then
                cat ${CLUSTER_LOG}| cut -d ";" -f2 | cut -d '"' -f1 | grep -Eo '[0-9\.]+' > C_temp.log
                cluster_cpumem=$( echo `calcAvg_in_p C_temp.log | cut -d "=" -f2`  )
        fi
	echo "${run} , ${cluster_cpumem}" >> ${RESULTS_DIR_J}/${CLUSTER_RESULTS_LOG}
}

# Parse the results of jmeter load for each instance of application
# input: total number of iterations, result directory, Total number of instances
# output: Parse the results and generate the Metrics log files
function parseResults() {
	TOTAL_ITR=$1
	RESULTS_DIR_J=$2
	SCALE=$3
	WARMUPS=$4
	MEASURES=$5

	for (( itr=0 ; itr<${TOTAL_ITR} ;itr++))
	do
		RESULTS_DIR_P=${RESULTS_DIR_J}/ITR-${itr}
		parsePromMetrics warmup ${WARMUPS} ${itr}
		parsePromMetrics measure ${MEASURES} ${itr}

		for poddatalog in "${POD_CPU_LOGS[@]}"
		do
			if [ -s "${RESULTS_DIR_J}/${poddatalog}-measure-${itr}.log" ]; then
                                cat ${RESULTS_DIR_J}/${poddatalog}-measure-${itr}.log | cut -d "," -f2 >> ${RESULTS_DIR_J}/${poddatalog}-measure-temp.log
                                cat ${RESULTS_DIR_J}/${poddatalog}-measure-${itr}.log | cut -d "," -f3 >> ${RESULTS_DIR_J}/${poddatalog}_min-measure-temp.log
                                cat ${RESULTS_DIR_J}/${poddatalog}-measure-${itr}.log | cut -d "," -f4 >> ${RESULTS_DIR_J}/${poddatalog}_max-measure-temp.log
                        fi
		done
		for podmemlog in "${POD_MEM_LOGS[@]}"
		do
			if [ -s "${RESULTS_DIR_J}/${podmemlog}-measure-${itr}.log" ]; then
                                cat ${RESULTS_DIR_J}/${podmemlog}-measure-${itr}.log | cut -d "," -f2 >> ${RESULTS_DIR_J}/${podmemlog}-measure-temp.log
                                cat ${RESULTS_DIR_J}/${podmemlog}-measure-${itr}.log | cut -d "," -f3 >> ${RESULTS_DIR_J}/${podmemlog}_min-measure-temp.log
                                cat ${RESULTS_DIR_J}/${podmemlog}-measure-${itr}.log | cut -d "," -f4 >> ${RESULTS_DIR_J}/${podmemlog}_max-measure-temp.log
                        fi
		done
		for podmmlog in "${MICROMETER_LOGS[@]}"
		do
			if [ -s "${RESULTS_DIR_J}/${podmmlog}-measure-${itr}.log" ]; then
                                cat ${RESULTS_DIR_J}/${podmmlog}-measure-${itr}.log >> ${RESULTS_DIR_J}/${podmmlog}-measure-temp.log
                        fi
		done
		for podmetriclog in "${METRIC_LOGS[@]}"
		do
			if [ -s "${RESULTS_DIR_J}/${podmetriclog}-measure-${itr}.log" ]; then
                                cat ${RESULTS_DIR_J}/${podmetriclog}-measure-${itr}.log >> ${RESULTS_DIR_J}/${podmetriclog}-measure-temp.log
                        fi
		done
	done
	###### Add different raw logs we want to merge
	#Cumulative raw data
	paste ${RESULTS_DIR_J}/cpu-measure-raw.log ${RESULTS_DIR_J}/mem-measure-raw.log >> ${RESULTS_DIR_J}/../Metrics-cpumem-raw.log

	for metric in "${TOTAL_LOGS[@]}"
	do
		if [ -s ${RESULTS_DIR_J}/${metric}-measure-temp.log ]; then
		if [ ${metric} == "cpu_min" ] || [ ${metric} == "mem_min" ]; then
			minval=$(echo `calcMin ${RESULTS_DIR_J}/${metric}-measure-temp.log`)
			if [ ! -z ${minval} ]; then
				eval total_${metric}=${minval}
			else
				eval total_${metric}=0
			fi
		elif [ ${metric} == "cpu_max" ] || [ ${metric} == "mem_max" ] || [ ${metric} == "latency_seconds_max" ] || [ ${metric} == "server_requests_max" ]; then
			maxval=$(echo `calcMax ${RESULTS_DIR_J}/${metric}-measure-temp.log`)
			if [ ! -z ${maxval} ]; then
				eval total_${metric}=${maxval}
			else
				eval total_${metric}=0
			fi
		else
			val=$(echo `calcAvg ${RESULTS_DIR_J}/${metric}-measure-temp.log | cut -d "=" -f2`)
			if [ ! -z ${val} ]; then
				eval total_${metric}_avg=${val}
			else
				eval total_${metric}_avg=0
			fi
		fi
		# Calculate confidence interval
                        metric_ci=`php ${SCRIPT_REPO}/perf/ci.php ${RESULTS_DIR_J}/${metric}-measure-temp.log`
			if [ ! -z ${metric_ci} ]; then
	                        eval ci_${metric}=${metric_ci}
			else
				eval ci_${metric}=0
			fi

		## Convert latency_seconds_max into ms
		if [ ${metric} == "latency_seconds_max" ]; then
			total_latency_milliseconds_max=$(echo ${total_latency_seconds_max}*1000 | bc -l)
		elif [ ${metric} == "latency_seconds_quan_50" ]; then
			total_latency_ms_quan_50_avg=$(echo ${total_latency_seconds_quan_50_avg}*1000 | bc -l)
		elif [ ${metric} == "latency_seconds_quan_95" ]; then
                        total_latency_ms_quan_95_avg=$(echo ${total_latency_seconds_quan_95_avg}*1000 | bc -l)
                elif [ ${metric} == "latency_seconds_quan_98" ]; then
                        total_latency_ms_quan_98_avg=$(echo ${total_latency_seconds_quan_98_avg}*1000 | bc -l)
                elif [ ${metric} == "latency_seconds_quan_99" ]; then
                        total_latency_ms_quan_99_avg=$(echo ${total_latency_seconds_quan_99_avg}*1000 | bc -l)
                elif [ ${metric} == "latency_seconds_quan_999" ]; then
                        total_latency_ms_quan_999_avg=$(echo ${total_latency_seconds_quan_999_avg}*1000 | bc -l)
                elif [ ${metric} == "server_requests_max" ]; then
			total_server_requests_ms_max=$(echo ${total_server_requests_max}*1000 | bc -l)
		fi
			
		fi
	done

	echo "${SCALE} , ${total_server_requests_thrpt_rate_3m_avg} , ${total_server_requests_rsp_time_rate_3m_avg} , ${total_server_requests_ms_max} , ${total_latency_ms_quan_50_avg} , ${total_latency_ms_quan_95_avg} , ${total_latency_ms_quan_98_avg} , ${total_latency_ms_quan_99_avg} , ${total_latency_ms_quan_999_avg} , ${total_cpu_avg} , ${total_mem_avg} , ${total_cpu_min} , ${total_cpu_max} , ${total_mem_min} , ${total_mem_max} , ${ci_server_requests_thrpt_rate_3m} , ${ci_server_requests_rsp_time_rate_3m} " >> ${RESULTS_DIR_J}/../Metrics-prom.log
	echo "${SCALE} , ${total_server_requests_thrpt_rate_3m_avg} , ${total_server_requests_rsp_time_rate_3m_avg} , ${total_server_requests_thrpt_avg} , ${total_server_requests_rsp_time_avg} , ${total_server_requests_ms_max} , ${total_app_timer_thrpt_rate_3m_avg} , ${total_app_timer_rsp_time_rate_3m_avg} , ${total_app_timer_thrpt_avg} , ${total_app_timer_rsp_time_avg} , ${total_latency_milliseconds_max} , ${total_latency_ms_quan_50_avg} , ${total_latency_ms_quan_95_avg} , ${total_latency_ms_quan_98_avg} , ${total_latency_ms_quan_99_avg} , ${total_latency_ms_quan_999_avg} , ${total_mem_avg} , ${total_cpu_avg} , ${total_cpu_min} , ${total_cpu_max} , ${total_mem_min} , ${total_mem_max} , ${ci_server_requests_thrpt} , ${ci_server_requests_rsp_time} , ${ci_app_timer_thrpt} , ${ci_app_timer_rsp_time} " >> ${RESULTS_DIR_J}/../Metrics-prom-all.log
	echo "${SCALE} ,  ${total_mem_avg} , ${total_memusage_avg} " >> ${RESULTS_DIR_J}/../Metrics-mem-prom.log
	echo "${SCALE} ,  ${total_cpu_avg} " >> ${RESULTS_DIR_J}/../Metrics-cpu-prom.log
	echo ", ${total_latency_seconds_quan_50_avg} , ${total_latency_seconds_quan_95_avg} , ${total_latency_seconds_quan_98_avg} , ${total_latency_seconds_quan_99_avg} , ${total_latency_seconds_quan_999_avg}" >> ${RESULTS_DIR_J}/../Metrics-percentile-prom.log
#	echo "${SCALE} , ${total_c_cpu_avg} , ${total_c_cpurequests_avg} , ${total_c_cpulimits_avg} , ${total_c_mem_avg} , ${total_c_memrequests_avg} , ${total_c_memlimits_avg} " >> ${RESULTS_DIR_J}/../Metrics-cluster.log
	echo "${total_server_requests_thrpt_rate_1m_avg} , ${total_server_requests_rsp_time_rate_1m_avg} , ${total_server_requests_thrpt_rate_3m_avg} , ${total_server_requests_rsp_time_rate_3m_avg} , ${total_server_requests_thrpt_rate_5m_avg} , ${total_server_requests_rsp_time_rate_5m_avg} , ${total_server_requests_thrpt_rate_7m_avg} , ${total_server_requests_rsp_time_rate_7m_avg} , ${total_server_requests_thrpt_rate_9m_avg} , ${total_server_requests_rsp_time_rate_9m_avg} , ${total_server_requests_thrpt_rate_15m_avg} , ${total_server_requests_rsp_time_rate_15m_avg}" >> ${RESULTS_DIR_J}/../Metrics-rate-prom.log
}

POD_CPU_LOGS=(cpu)
POD_MEM_LOGS=(mem memusage)
CLUSTER_LOGS=(c_mem c_cpu)
TIMER_RATE_LOGS=(app_timer_count_rate_1m app_timer_count_rate_3m app_timer_count_rate_5m app_timer_count_rate_7m app_timer_count_rate_9m app_timer_count_rate_15m app_timer_count_rate_30m app_timer_sum_rate_1m app_timer_sum_rate_3m app_timer_sum_rate_5m app_timer_sum_rate_7m app_timer_sum_rate_9m app_timer_sum_rate_15m app_timer_sum_rate_30m)
SERVER_REQUESTS_RATE_LOGS=(server_requests_count_rate_1m server_requests_count_rate_3m server_requests_count_rate_5m server_requests_count_rate_7m server_requests_count_rate_9m server_requests_count_rate_15m server_requests_count_rate_30m server_requests_sum_rate_1m server_requests_sum_rate_3m server_requests_sum_rate_5m server_requests_sum_rate_7m server_requests_sum_rate_9m server_requests_sum_rate_15m server_requests_sum_rate_30m)
LATENCY_P_LOGS=(latency_seconds_quan_50 latency_seconds_quan_95 latency_seconds_quan_98 latency_seconds_quan_99 latency_seconds_quan_999)
MICROMETER_LOGS=(app_timer_sum app_timer_count ${TIMER_RATE_LOGS[@]} server_requests_sum server_requests_count server_requests_max ${SERVER_REQUESTS_RATE_LOGS[@]} ${LATENCY_P_LOGS[@]} latency_seconds_max)
APP_CALC_METRIC_LOGS=(app_timer_rsp_time app_timer_thrpt app_timer_rsp_time_rate_3m app_timer_thrpt_rate_3m)
SERVER_REQUESTS_METRIC_LOGS=(server_requests_rsp_time server_requests_thrpt server_requests_rsp_time_rate_3m server_requests_thrpt_rate_3m)
METRIC_LOGS=(${APP_CALC_METRIC_LOGS[@]} ${SERVER_REQUESTS_METRIC_LOGS[@]})
TOTAL_LOGS=(${POD_CPU_LOGS[@]} ${POD_MEM_LOGS[@]} ${MICROMETER_LOGS[@]} ${METRIC_LOGS[@]} cpu_min cpu_max mem_min mem_max)


TOTAL_ITR=$1
RESULTS_DIR_J=$2
SCALE=$3
WARMUPS=$4
MEASURES=$5
SCRIPT_REPO=$6

parseResults ${TOTAL_ITR} ${RESULTS_DIR_J} ${SCALE} ${WARMUPS} ${MEASURES} ${SCRIPT_REPO}
