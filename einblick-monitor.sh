#!/bin/bash
#
# Author: Mike Bush
# Company: ECCO Select
# Description: Monitor Einblick UI URL 
#
baseName=/app/support
# SITE is the URL used to view Einblick user URL
# https://myeinblick.com/
SITE=$3
VAR1=$(curl $SITE)
# bad page content
VAR2="no healthy upstream"
#
# echo page content
#
echo $VAR1
#
# if the site is down send a support bundle and data extract to S3 bucket
#
if [ "$VAR1" = "$VAR2" ]; then
    echo "UI is down.  Collecting bundle."
    /bin/bash $baseName/einblick-support-bundle.sh $1 $2 &> $baseName/scheduled.log
	#
	# dump workspace collection
	#
	COLLECTION_NAME=workspace
	/bin/bash $baseName/einblick-dump.sh $COLLECTION_NAME  &> $baseName/export.log
	/bin/bash $baseName/einblick-s3send.sh $1 $2 extract $COLLECTION_NAME.zip  &> $baseName/s3send.log
	#
	# dump user_operator collection
	#
	COLLECTION_NAME=user_operator
	/bin/bash $baseName/einblick-dump.sh $COLLECTION_NAME  &> $baseName/export.log
	/bin/bash $baseName/einblick-s3send.sh $1 $2 extract $COLLECTION_NAME.zip  &> $baseName/s3send.log
	# generate web page
    /bin/bash $baseName/einblick-elogs.sh &> $baseName/elogs.log
else
    echo "UI is UP"
fi

