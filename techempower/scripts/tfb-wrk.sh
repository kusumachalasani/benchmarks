#!/bin/bash

NAMESPACE="default"
#SERVER_HOST=`oc status -n ${NAMESPACE} | grep tfb-qrh | grep port | cut -d " " -f1`
SERVER_HOST=`minikube ip`
PORT=($(kubectl -n ${NAMESPACE} get svc | grep "tfb-qrh" | tr -s " " | cut -d " " -f5 | cut -d ":" -f2 | cut -d "/" -f1))
ACCEPT="application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7"
DURATION=15
MAX_CONCURRENCY=512
LEVELS="16 32 64 128 256"

TFB_IMAGE="tfb.wrk:may"

# Run with db url
URL="http://${SERVER_HOST}:${PORT}/db"
docker run -e server_host=${SERVER_HOST} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" ${TFB_IMAGE} /concurrency.sh

# With json
URL="http://${SERVER_HOST}:${PORT}/json"
docker run -e server_host=${SERVER_HOST} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" ${TFB_IMAGE} /concurrency.sh

# With fortunes
URL="http://${SERVER_HOST}:${PORT}/fortunes"
docker run -e server_host=${SERVER_HOST} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" ${TFB_IMAGE} /concurrency.sh

# With queries
URL="http://${SERVER_HOST}:${PORT}/queries/query="
LEVELS="1 5 10 15 20"
docker run -e server_host=${SERVER_HOST} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" ${TFB_IMAGE} /query.sh

# With plaintext
URL="http://${SERVER_HOST}:${PORT}/plaintext"
LEVELS="256 512 1024 2048 4096 8192 16384"
PIPELINE=16
docker run -e server_host=${SERVER_HOST} -e url=${URL} -e accept=${ACCEPT} -e duration=${DURATION} -e max_concurrency=${MAX_CONCURRENCY} -e levels="${LEVELS}" -e pipeline=${PIPELINE} ${TFB_IMAGE} /pipeline.sh
