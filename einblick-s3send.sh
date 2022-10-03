#!/bin/bash
#
# Author: Mike Bush
# Company: ECCO Select
# Description: Send File to S3 bucket/folder
#
# Thanks to:
# https://stackoverflow.com/questions/1496453/uploading-to-amazon-s3-using-curl-libcurl
#
export KUBECONFIG="/etc/kubernetes/admin.conf"

yyyymmdd=`date +%Y%m%d`
isoDate=`date --utc +%Y%m%dT%H%M%SZ`
# edit vars to match the bucket AWS account
s3Bucket="my-s3-bucket"
bucketLocation="my-aws-region"
#
# AWS bucket Creds
#
s3AccessKey="$1"
s3SecretKey="$2"
# S3 Folder Name
folder="$3"
# File to send
adhocFile="$4"
# AWS S3 URL
endpoint="${s3Bucket}.s3.${bucketLocation}.amazonaws.com"
# 
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME=$(basename "$0")
echo "Einblick S3 Send Utility"
echo "Sending File to ${folder}"
#
# get new bundles and send it
#
contentLength=`cat ${adhocFile} | wc -c`
contentHash=`openssl sha256 -hex ${adhocFile} | sed 's/.* //'`

canonicalRequest="PUT\n/${folder}/${adhocFile}\n\ncontent-length:${contentLength}\nhost:${endpoint}\nx-amz-content-sha256:${contentHash}\nx-amz-date:${isoDate}\n\ncontent-length;host;x-amz-content-sha256;x-amz-date\n${contentHash}"
canonicalRequestHash=`echo -en ${canonicalRequest} | openssl sha256 -hex | sed 's/.* //'`

stringToSign="AWS4-HMAC-SHA256\n${isoDate}\n${yyyymmdd}/${bucketLocation}/s3/aws4_request\n${canonicalRequestHash}"

echo "----------------- canonicalRequest --------------------"
echo -e ${canonicalRequest}
echo "----------------- stringToSign --------------------"
echo -e ${stringToSign}
echo "-------------------------------------------------------"
#
# send file and
# calculate the signing key
#
DateKey=`echo -n "${yyyymmdd}" | openssl sha256 -hex -hmac "AWS4${s3SecretKey}" | sed 's/.* //'`
DateRegionKey=`echo -n "${bucketLocation}" | openssl sha256 -hex -mac HMAC -macopt hexkey:${DateKey} | sed 's/.* //'`
DateRegionServiceKey=`echo -n "s3" | openssl sha256 -hex -mac HMAC -macopt hexkey:${DateRegionKey} | sed 's/.* //'`
SigningKey=`echo -n "aws4_request" | openssl sha256 -hex -mac HMAC -macopt hexkey:${DateRegionServiceKey} | sed 's/.* //'`
# HMAC
signature=`echo -en ${stringToSign} | openssl sha256 -hex -mac HMAC -macopt hexkey:${SigningKey} | sed 's/.* //'`

authoriz="Authorization: AWS4-HMAC-SHA256 Credential=${s3AccessKey}/${yyyymmdd}/${bucketLocation}/s3/aws4_request, SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date, Signature=${signature}"

echo "Processing $adhocFile to http://${endpoint}/${folder}/${adhocFile}"

curl -v -X PUT -T "${adhocFile}" \
-H "Host: ${endpoint}" \
-H "Content-Length: ${contentLength}" \
-H "x-amz-date: ${isoDate}" \
-H "x-amz-content-sha256: ${contentHash}" \
-H "${authoriz}" \
http://${endpoint}/${folder}/${adhocFile}
