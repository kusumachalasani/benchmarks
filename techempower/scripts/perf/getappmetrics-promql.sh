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


## Collect server_Requests related data for all endpoints
function get_promdata_all()
{
        URL=$1
        TOKEN=$2
        RESULTS_DIR=$3
        ITER=$4
        APP_NAME=$5
        while true
        do
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/cpu-${ITER}.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(node_namespace_pod_container:container_memory_rss) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/mem-${ITER}.json
		curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(container_memory_working_set_bytes) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/memusage-${ITER}.json

                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/db"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-db.json
#               err_exit "Error: could not get server_requests_sum details of the pod" >>setup.log
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/json"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-json.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/fortunes"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-fortunes.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/queries"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-queries.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/plaintext"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-plaintext.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_sum{status="200",uri="/updates"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_sum-${ITER}-updates.json

                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/db"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-db.json
#               err_exit "Error: could not get server_requests_count details of the pod" >>setup.log
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/json"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-json.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/fortunes"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-fortunes.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/queries"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-queries.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/plaintext"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-plaintext.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_count{status="200",uri="/updates"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_count-${ITER}-updates.json

		
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/db"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-db.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/json"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-json.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/fortunes"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-fortunes.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/queries"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-queries.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/plaintext"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-plaintext.json
                curl --silent -G -kH "Authorization: Bearer ${TOKEN}" --data-urlencode 'query=sum(http_server_requests_seconds_max{status="200",uri="/updates"}) by (pod)' ${URL} | jq '[ .data.result[] | [ .value[0], .metric.namespace, .metric.pod, .value[1]|tostring] | join(";") ]' | grep "${APP_NAME}" >> ${RESULTS_DIR}/server_requests_max-${ITER}-updates.json


        done

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

get_promdata_all ${URL} ${TOKEN} ${RESULTS_DIR} ${ITER} ${APP_NAME}

