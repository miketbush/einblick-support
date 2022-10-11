#!/bin/bash
set -eu
s3receive() {
  local AWS_ACCESS_KEY_ID="$1"
  local AWS_SECRET_ACCESS_KEY="$2"
  local s3url="$3"
  local file="${5:--}"
  local s3location="$4"

  if [ "${s3url:0:5}" != "s3://" ]; then
    echo "Need an s3 s3url"
    return 1
  fi

  local path="${s3url:4}"

  IFS='/' read -ra PPART <<< "${path:1}"
  
  local length=${#PPART[@]}
  uri=""

  local resource=""
  local s3bucket="${PPART[0]}" 
  
  local j=0	 
  for i in "${PPART[@]}"; do
     resource=$resource"/${i}"
	 if [[ $j -gt 0 ]]
	 then
	    uri=$uri"/${i}"
	 fi
	 j=$j+1
  done
	 
  #echo "URI: ${uri}"
  #echo "RESOURCE: ${resource}"
  #local resource="/${s3bucket}${uri}"

  local method md5 args
  method="GET"
  md5=""
  args="-o $file"

  local date="$(date -u '+%a, %e %b %Y %H:%M:%S +0000')"
  local string_to_sign
  printf -v string_to_sign "%s\n%s\n\n%s\n%s" "$method" "$md5" "$date" "${resource}"
  local signature=$(echo -n "$string_to_sign" | openssl sha1 -binary -hmac "${AWS_SECRET_ACCESS_KEY}" | openssl base64)
  local authorization="AWS ${AWS_ACCESS_KEY_ID}:${signature}"

  #echo $s3url
  #echo $uri
  #echo $file
  #echo $path
  #echo $md5
  #echo $date
  #echo $s3bucket 
  #echo $s3location
  #echo "RESOURCE:${resource}"
  
  local url="https://${s3bucket}.s3-${s3location}.amazonaws.com${uri}"
  echo "Downloading from URL: ${url}"
  
  curl $args -s -f -H Date:"${date}" -H Authorization:"${authorization}" $url
}

s3receive "$@"