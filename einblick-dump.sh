#!/bin/bash
#
# Author: Mike Bush
# Company: ECCO Select
# Description: Export Einblick MongoDB Collection
#
#  Example install of mongo tools needed:
#  wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel70-x86_64-100.6.0.tgz
#  tar -xzf mongodb-database-tools-rhel70-x86_64-100.6.0.tgz
#  mv mongodb-database-tools-rhel70-x86_64-100.6.0 /app/support/mongotools
export KUBECONFIG="/etc/kubernetes/admin.conf"
export PATH=$PATH:/app/support/mongotools/bin
export PORT=27017

COLLECTION_NAME=$1
#
# extract mongodn creds from pod description
#
item="MONGODB_PASSWORD"
mpass=$(desc=$(kubectl describe pods | grep -m 1 $item);bob=$(echo $desc | tr ":" " "); echo $bob |  sed "s/$item //")

item="MONGODB_USER_NAME"
muser=$(desc=$(kubectl describe pods | grep -m 1 $item);bob=$(echo $desc | tr ":" " "); echo $bob |  sed "s/$item //")
#
#get einblick pod name
#
POD_ID=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep einblick)
echo POD: $POD_ID
#
#start port forward mongodb port for external use and store PID
#
kubectl port-forward pod/$POD_ID  $PORT:$PORT --address 0.0.0.0 &
PF_PID=$!
echo PID:$PF_PID
#
#export the requested collection
#
mongoexport --uri="mongodb://localhost:$PORT/einblick?authSource=admin" --username=$muser --password=$mpass --collection=$COLLECTION_NAME --out=$COLLECTION_NAME.json --authenticationDatabase=admin
#
#compress data
#
rm $COLLECTION_NAME.zip
zip $COLLECTION_NAME $COLLECTION_NAME.json
rm $COLLECTION_NAME.json
#
# kill port forwarder
#
ps -Af | grep $PF_PID
kill -9 $PF_PID


