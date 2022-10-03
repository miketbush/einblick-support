#!/bin/bash
#
# Author: Mike Bush
# Company: ECCO Select
# Description: Make Einblick support bundle web viewable
#
baseName=/app/support
supportName=$(basename $(ls $baseName/support-bundle-*))
removeString=".tar.gz"
shortName=$(echo "${supportName//"$removeString"}")
echo $supportName
echo $shortName
rm -f -R $baseName/logs/$shortName
mkdir $baseName/logs
# extract logs from bundle
tar -xzf $baseName/$supportName -C $baseName/logs
rm -f -R $baseName/einblick-logs/*
cp -R $baseName/logs/$shortName/einblick*/* $baseName/einblick-logs
rm -f -R $baseName/logs/*
#
# Create index.html page by looping over extracted logs
#
echo "<html><header><title>Einblick Logs</title></header><body>" > $baseName/einblick-logs/index.html
for f in $baseName/einblick-logs/*
do
  fileName=$(basename $f)
  echo $fileName
  echo "<a href='$fileName'>$fileName</a><br>" >> $baseName/einblick-logs/index.html
done
echo "</body></html>" >> $baseName/einblick-logs/index.html
