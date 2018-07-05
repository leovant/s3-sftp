#!/bin/bash
function checkVars() {
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set."
    return 1
  fi
  
  if [ -z "$S3_BUCKET" ]; then
    echo "S3_BUCKET must be set"
    return 1
  fi
  
  return 0
}

checkVars || exit 1

# Mount bucket with s3fs
echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" >  "$S3FS_CONF_FILE"

s3fs "$S3_BUCKET" "$FTP_DIRECTORY" -o passwd_file="$S3FS_CONF_FILE" -o allow_other -o mp_umask="0022" -o dbglevel=info -f -o curldbg || exit 2
