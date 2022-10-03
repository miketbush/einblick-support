#!/bin/bash
#
# Author: Mike Bush
# Company: ECCO Select
# Description: Send Einblick MongoDB export to S3 folder
# 
baseName=/app/support
s3bucketName=extract
# export file
FILE=$3
#
echo "Collecting $FILE..."
/bin/bash $baseName/einblick-dump.sh $FILE
/bin/bash $baseName/einblick-s3send.sh $1 $2 $s3bucketName $FILE.zip

