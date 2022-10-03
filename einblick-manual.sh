#!/bin/bash

baseName=/app/support
#
echo "Collecting bundle."
#
# generate support bundle
#
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
#
# update the web version of the logs
#
/bin/bash $baseName/einblick-elogs.sh &> $baseName/elogs.log