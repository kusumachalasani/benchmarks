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
### Script to get pod and cluster information through prometheus queries###
#
# checks if the previous command is executed successfully
# input:Return value of previous command
# output:Prompts the error message if the return value is not zero
function err_exit() 
{
	if [ $? != 0 ]; then
		printf "$*"
		echo 
		exit -1
	fi
}

## Collect CPU data
function get_cpu()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/cpu-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
#		echo "curl --silent -G -kH Authorization: Bearer ${TOKEN} --data-urlencode 'query=sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate) by (pod)' ${URL} "		 
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/cpu-${ITER}.json
		err_exit "Error: could not get cpu details of the pod" >>setup.log
	done
}

## Collect MEM_RSS
function get_mem_rss()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/mem-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(node_namespace_pod_container:container_memory_rss) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/mem-${ITER}.json
		err_exit "Error: could not get memory details of the pod" >>setup.log
	done
}

## Collect Memory Usage
function get_mem_usage()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/memusage-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(container_memory_working_set_bytes) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/memusage-${ITER}.json
		err_exit "Error: could not get memory details of the pod" >>setup.log
	done
}

## Collect network bytes received
function get_receive_bandwidth()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/receive_bandwidth-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(irate(container_network_receive_bytes_total[30s])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/receive_bandwidth-${ITER}.json
		err_exit "Error: could not get bandwidth details of the pod" >>setup.log
	done
}

## Collect network bytes transmitted
function get_transmit_bandwidth()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/transmit_bandwidth-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(irate(container_network_transmit_bytes_total[30s])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/transmit_bandwidth-${ITER}.json
		err_exit "Error: could not get bandwidth details of the pod" >>setup.log
	done
}

## Collect server errors
function get_server_errors()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/server_errors-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_errors_total) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_errors-${ITER}.json
		err_exit "Error: could not get server error details of the pod" >>setup.log
	done
}

## Collect server errors
function get_server_errors_rate()
{
        URL=$1
        TOKEN=$2
        RESULTS_DIR=$3
        ITER=$4
        APP_NAME=$5
        # Delete the old json file if any
        rm -rf ${RESULTS_DIR}/server_errors-${ITER}.json
	# Processing curl output "timestamp value" using jq tool.
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_errors_total[3m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_errors-rate-${ITER}.json
        err_exit "Error: could not get server error details of the pod" >>setup.log
}


## Collect http_server_requests_sum seconds for all methods
function get_server_requests_sum()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/server_requests_sum-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/db"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-db.json
#		err_exit "Error: could not get server_requests_sum details of the pod" >>setup.log
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/json"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-json.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/fortunes"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-fortunes.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/queries"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-queries.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/plaintext"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-plaintext.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/updates"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-updates.json
	done
}

## Collect server_requests_count for all methods
function get_server_requests_count()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/server_requests_count-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/db"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-db.json
#		err_exit "Error: could not get server_requests_count details of the pod" >>setup.log
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/json"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-json.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/fortunes"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-fortunes.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/queries"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-queries.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/plaintext"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-plaintext.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/updates"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-updates.json
		
	done
}

## Collect server_requests_max of all methods
function get_server_requests_max()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Delete the old json file if any
	rm -rf ${RESULTS_DIR}/server_requests_max-${ITER}.json
	while true
	do
		# Processing curl output "timestamp value" using jq tool.
#		if [[ ${ENDPOINT} == "db" ]]; then
			curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/db"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-db.json
#		elif [[ ${ENDPOINT} == "json" ]]; then
                        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/json"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-${ENDPOINT}.json
#		elif [[ ${ENDPOINT} == "fortunes" ]]; then
                        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/fortunes"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-${ENDPOINT}.json
#		elif [[ ${ENDPOINT} == "queries" ]]; then
                        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/queries"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-${ENDPOINT}.json
#		elif [[ ${ENDPOINT} == "plaintext" ]]; then
                        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/plaintext"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-${ENDPOINT}.json
#		elif [[ ${ENDPOINT} == "updates" ]]; then
                        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/updates"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-${ENDPOINT}.json
#		fi
	done
}


#### Collect per server_requests_sum for last 1,3,5,6 mins.
function get_server_requests_sum_rate()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Processing curl output "timestamp value" using jq tool.
#	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/db"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_1m-${ITER}.json
#	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/db"}[5m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_5m-${ITER}.json

	echo "-----------Running sum rate for ${ENDPOINT}..............................."
#	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="${ENDPOINT}"}[30s])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate-${ITER}-${ENDPOINT}.json

	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/db"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_1m-${ITER}-db.json
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/json"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_1m-${ITER}-json.json
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/fortunes"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_1m-${ITER}-fortunes.json
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/queries"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_1m-${ITER}-queries.json
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/plaintext"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_1m-${ITER}-plaintext.json
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/updates"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate_1m-${ITER}-updates.json

	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/db"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate-${ITER}-db.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/json"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate-${ITER}-json.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/fortunes"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate-${ITER}-fortunes.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/queries"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate-${ITER}-queries.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/plaintext"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate-${ITER}-plaintext.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_sum{status="200",uri="/updates"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum_rate-${ITER}-updates.json

	echo "-----------Completed sum rate for ${ENDPOINT}..............................."
}

## Collect per second server_requests_count for last 1,3,5,6 mins.
function get_server_requests_count_rate()
{
	URL=$1
	TOKEN=$2
	RESULTS_DIR=$3
	ITER=$4
	APP_NAME=$5
	# Processing curl output "timestamp value" using jq tool.
#	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/db"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_1m-${ITER}.json
#	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/db"}[5m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_5m-${ITER}.json

	echo "-----------Running count rate for ${ENDPOINT}..............................."
#	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="${ENDPOINT}"}[30s])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate-${ITER}-${ENDPOINT}.json

	echo "---------- count rate for db"
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/db"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_1m-${ITER}-db.json
	echo "---------- count rate for json"
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/json"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_1m-${ITER}-json.json
	echo "---------- count rate for fortunes"
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/fortunes"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_1m-${ITER}-fortunes.json
	echo "---------- count rate for queries"
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/queries"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_1m-${ITER}-queries.json
	echo "---------- count rate for plaintext"
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/plaintext"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_1m-${ITER}-plaintext.json
	echo "---------- count rate for updates"
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/updates"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate_1m-${ITER}-updates.json

	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/db"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate-${ITER}-db.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/json"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate-${ITER}-json.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/fortunes"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate-${ITER}-fortunes.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/queries"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate-${ITER}-queries.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/plaintext"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate-${ITER}-plaintext.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(rate(http_server_requests_seconds_count{status="200",uri="/updates"}[1m])) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count_rate-${ITER}-updates.json

	echo "-----------Completed count rate for ${ENDPOINT}..............................."
}

function get_http_quantiles() {

        URL=$1
        TOKEN=$2
        RESULTS_DIR=$3
        ITER=$4
        APP_NAME=$5

        # Processing curl output "timestamp value" using jq tool.
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.50, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_50_histo-${ITER}.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.75, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_75_histo-${ITER}.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_95_histo-${ITER}.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.97, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_97_histo-${ITER}.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.99, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_99_histo-${ITER}.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.999, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_999_histo-${ITER}.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.9999, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_9999_histo-${ITER}.json
        curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(0.99999, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_99999_histo-${ITER}.json
	curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=histogram_quantile(1.0, sum(rate(http_server_requests_seconds_bucket{uri="/db"}[3m])) by (le))' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' >> ${RESULTS_DIR}/http_seconds_quan_100_histo-${ITER}.json

}

ITER=$1
TIMEOUT=$2
RESULTS_DIR=$3
BENCHMARK_SERVER=$4
APP_NAME=$5
CLUSTER_TYPE=$6
ENDPOINT=$7

mkdir -p ${RESULTS_DIR}
#QUERY_APP=prometheus-k8s-openshift-monitoring.apps
if [[ ${CLUSTER_TYPE} == "openshift" ]]; then
	QUERY_APP=thanos-querier-openshift-monitoring.apps
	URL=https://${QUERY_APP}.${BENCHMARK_SERVER}/api/v1/query
	TOKEN=`oc whoami --show-token`
elif [[ ${CLUSTER_TYPE} == "minikube" ]]; then
	#QUERY_IP=`minikibe ip`
	QUERY_APP="${BENCHMARK_SERVER}:9090"
	URL=http://${QUERY_APP}/api/v1/query
	TOKEN=TOKEN
fi

#export -f err_exit get_cpu get_mem_rss get_mem_usage get_receive_bandwidth get_transmit_bandwidth
export -f get_server_errors get_server_requests_sum get_server_requests_count get_server_requests_max

echo "Collecting metric data" >> setup.log
#timeout ${TIMEOUT} bash -c  "get_cpu ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout ${TIMEOUT} bash -c  "get_mem_rss ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout ${TIMEOUT} bash -c  "get_mem_usage ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout ${TIMEOUT} bash -c  "get_receive_bandwidth ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout ${TIMEOUT} bash -c  "get_transmit_bandwidth ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout ${TIMEOUT} bash -c  "get_server_errors ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout 190 bash -c  "get_server_requests_sum ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout 190 bash -c  "get_server_requests_count ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}" &
#timeout 190 bash -c  "get_server_requests_max ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME} ${ENDPOINT}" &
#sleep ${TIMEOUT}
#sleep 30
#sleep 190
sleep 30
# Calculate the rate of metrics for the last 1,3,5,7,9,15,30 mins.
get_server_requests_sum_rate ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME} ${ENDPOINT} &
get_server_requests_count_rate ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME} ${ENDPOINT} 
#get_http_quantiles ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME} &
#get_server_errors_rate ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME} &

