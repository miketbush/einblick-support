#!/bin/bash
#
# Author: Mike Bush
# Company: ECCO Select
# Description: Extract Support Bundle from Einblick Pod
# 
# Thanks to:
# https://stackoverflow.com/questions/1496453/uploading-to-amazon-s3-using-curl-libcurl
#
# Possible crontab entry:
#
# 5 6,10,14,16,18 * * 1,2,3,4,5 /app/support/einblick-support-bundle.sh MY_KEY MY_SECRET &> /app/support/scheduled.log
# 
# See: https://crontab.guru/
#
export KUBECONFIG="/etc/kubernetes/admin.conf"
# get krew tools using:
# curl https://krew.sh/support-bundle | bash
# if you don't want it installed in ~/.krew, create symlink at ~/.krew to something else
# then run above
export PATH="${PATH}:${HOME}/.krew/bin"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
#
# 
#
baseName=/app/support
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
# AWS S3 URL
endpoint="${s3Bucket}.s3.${bucketLocation}.amazonaws.com"
# 

SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME=$(basename "$0")
echo "Einblick Support Bundle Utility"
echo "Removing Old Bundles..."
rm -f $SCRIPT_PATH/*.gz
echo "Generating Support Bundle"
cd $SCRIPT_PATH
kubectl support-bundle secret/default/kotsadm-einblick-supportbundle --interactive=false --redact=false --insecure-skip-tls-verify=true &> $SCRIPT_PATH/support-bundle.log
echo "Sending Support Bundle"
# get new bundles and send it
for f in $SCRIPT_PATH/*.gz
do
	fileName=$(basename $f)
	contentLength=`cat ${fileName} | wc -c`
	contentHash=`openssl sha256 -hex ${fileName} | sed 's/.* //'`

	canonicalRequest="PUT\n/${folder}/${fileName}\n\ncontent-length:${contentLength}\nhost:${endpoint}\nx-amz-content-sha256:${contentHash}\nx-amz-date:${isoDate}\n\ncontent-length;host;x-amz-content-sha256;x-amz-date\n${contentHash}"
	canonicalRequestHash=`echo -en ${canonicalRequest} | openssl sha256 -hex | sed 's/.* //'`

	stringToSign="AWS4-HMAC-SHA256\n${isoDate}\n${yyyymmdd}/${bucketLocation}/s3/aws4_request\n${canonicalRequestHash}"

	echo "----------------- canonicalRequest --------------------"
	echo -e ${canonicalRequest}
	echo "----------------- stringToSign --------------------"
	echo -e ${stringToSign}
	echo "-------------------------------------------------------"

	# send file

	# calculate the signing key
	DateKey=`echo -n "${yyyymmdd}" | openssl sha256 -hex -hmac "AWS4${s3SecretKey}" | sed 's/.* //'`
	DateRegionKey=`echo -n "${bucketLocation}" | openssl sha256 -hex -mac HMAC -macopt hexkey:${DateKey} | sed 's/.* //'`
	DateRegionServiceKey=`echo -n "s3" | openssl sha256 -hex -mac HMAC -macopt hexkey:${DateRegionKey} | sed 's/.* //'`
	SigningKey=`echo -n "aws4_request" | openssl sha256 -hex -mac HMAC -macopt hexkey:${DateRegionServiceKey} | sed 's/.* //'`
	# HMAC
	signature=`echo -en ${stringToSign} | openssl sha256 -hex -mac HMAC -macopt hexkey:${SigningKey} | sed 's/.* //'`

	authoriz="Authorization: AWS4-HMAC-SHA256 Credential=${s3AccessKey}/${yyyymmdd}/${bucketLocation}/s3/aws4_request, SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date, Signature=${signature}"

	echo "Processing $f to http://${endpoint}/${folder}/${fileName}"

	curl -v -X PUT -T "${fileName}" \
	-H "Host: ${endpoint}" \
	-H "Content-Length: ${contentLength}" \
	-H "x-amz-date: ${isoDate}" \
	-H "x-amz-content-sha256: ${contentHash}" \
	-H "${authoriz}" \
	http://${endpoint}/${folder}/${fileName}
done

echo "Export Workspace"
/bin/bash $baseName/einblick-dump.sh workspace &> $baseName/export.log
echo "Send Workspace"
/bin/bash $baseName/einblick-s3send.sh $s3AccessKey $s3SecretKey extract workspace.zip  &> $baseName/s3send.log
echo "Export logs..."
/bin/bash $baseName/einblick-elogs.sh &> $baseName/elogs.log
echo "Complete"
