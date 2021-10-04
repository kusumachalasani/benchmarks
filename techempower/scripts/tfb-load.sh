#!/bin/bash
#
# Copyright (c) 2020, 2020 IBM Corporation, RedHat and others.
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
### Script to load test petclinic application on docker,minikube or openshift###
#
# Script to load test petclinic app
# 

CURRENT_DIR="$(dirname "$(realpath "$0")")"
source ${CURRENT_DIR}/petclinic-common.sh

function usage() {
	echo
	echo "Usage: -c CLUSTER_TYPE[docker|minikube|openshift] [-i SERVER_INSTANCES] [--iter=MAX_LOOP] [-n NAMESPACE] [-a IP_ADDR]"
	exit -1
}

while getopts c:i:a:n:-: gopts
do
	case ${gopts} in
	-)
		case "${OPTARG}" in
			iter=*)
				MAX_LOOP=${OPTARG#*=}
				;;
		esac
		;;
	c)
		CLUSTER_TYPE=${OPTARG}
		;;
	i)
		SERVER_INSTANCES="${OPTARG}"
		;;
	a)
		IP_ADDR="${OPTARG}"		
		;;
	n)
		NAMESPACE="${OPTARG}"		
		;;
	esac
done

if [ -z "${CLUSTER_TYPE}" ]; then
	usage
fi

if [ -z "${SERVER_INSTANCES}" ]; then
	SERVER_INSTANCES=1
fi

if [ -z "${MAX_LOOP}" ]; then
	MAX_LOOP=5
fi

if [ -z "${NAMESPACE}" ]; then
	NAMESPACE="${DEFAULT_NAMESPACE}"
fi

case ${CLUSTER_TYPE} in
docker)
	if [ -z "${IP_ADDR}" ]; then
		get_ip
	fi
	;;
icp|minikube)
	if [ -z "${IP_ADDR}" ]; then
		IP_ADDR=$(minikube ip)
	fi
	;;
openshift)
	if [ -z "${IP_ADDR}" ]; then
		IP_ADDR=($(oc status --namespace=${NAMESPACE} | grep "tfb-qrh" | grep port | cut -d " " -f1 | cut -d "/" -f3))
	fi
	;;
*)
	echo "Load is not determined"
	;;
esac	

LOG_DIR="${PWD}/logs/petclinic-$(date +%Y%m%d%H%M)"
mkdir -p ${LOG_DIR}

ACCEPT="application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7"
DURATION=15
MAX_CONCURRENCY=512
LEVELS="16 32 64 128 256"

for(( inst=1; inst<=${SERVER_INSTANCES}; inst++ ))
do	

	# Extra sleep time just to ensure all the pods has come up
	sleep 60
	# Check if the application is running
	check_app

	# Run with db url
	URL="${IP_ADDR}/db"
	docker run -e server_host=${SIP_ADDR} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" kusumach/tfb.wrk /concurrency.sh

	# With json
	URL="${IP_ADDR}/json"
	docker run -e server_host=${IP_ADDR} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" kusumach/tfb.wrk /concurrency.sh

	# With fortunes
	URL="${IP_ADDR}/fortunes"
	docker run -e server_host=${IP_ADDR} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" kusumach/tfb.wrk /concurrency.sh

	# With queries
	URL="${IP_ADDR}/queries/query="
	LEVELS="1 5 10 15 20"
	docker run -e server_host=${IP_ADDR} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" kusumach/tfb.wrk /query.sh

	# With plaintext
	URL="${IP_ADDR}/plaintext"
	LEVELS="256 512 1024 2048 4096 8192 16384"
	PIPELINE=16
	docker run -e server_host=${IP_ADDR} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" -e pipeline=${PIPELINE} kusumach/tfb.wrk /pipeline.sh

done
