#!/bin/bash
FTP_USERS_DIR="/ftp/users"
FTP_USERS_FILE="/ftp/users.conf"

function remove_user() {
  return 0;
}

function set_pass() {
  local USER=$1
  local PASS=$2
  
  echo "${USER}:${PASS}" | chpasswd -e
}

function set_permissions() {
  local USER=$1
  local FILE_PERMISSIONS=644
  local DIRECTORY_PERMISSIONS=755

  # Search for files and directories not owned correctly
  find "$FTP_USERS_DIR"/"$USER"/files/* \( \! -user "$USER" \! -group "$USER" \) -print0 | xargs -0 chown "$USER:$USER"

  # Search for files with incorrect permissions
  find "$FTP_USERS_DIR"/"$USER"/files/* -type f \! -perm "$FILE_PERMISSIONS" -print0 | xargs -0 chmod "$FILE_PERMISSIONS"

  # Search for directories with incorrect permissions
  find "$FTP_USERS_DIR"/"$USER"/files/* -type d \! -perm "$DIRECTORY_PERMISSIONS" -print0 | xargs -0 chmod "$DIRECTORY_PERMISSIONS"
}

function create_user() {
  local USER=$1
  local PASS=$2
  # If the user already exists, just update it
  if getent passwd "$USER" >/dev/null 2>&1; then
    set_pass "$USER" "$PASS"
    set_permissions "$USER"
    return 0
  fi

  useradd -d "${FTP_USERS_DIR}/${USER}" -s /usr/sbin/nologin $USER
  usermod -G ftpaccess "$USER"

  mkdir -p "${FTP_USERS_DIR}/${USER}"
  chown root:ftpaccess "${FTP_USERS_DIR}/${USER}"
  chmod 750 "${FTP_USERS_DIR}/${USER}"

  mkdir -p "${FTP_USERS_DIR}/${USER}/files"
  chown $USER:ftpaccess "${FTP_USERS_DIR}/${USER}/files"
  chmod 750 "${FTP_USERS_DIR}/${USER}/files"

  return 0
}

function read_users() {
  while read USER_DATA
  do
    read USERNAME PASSWORD STATUS <<< $(echo "$USER_DATA" | sed 's/:/ /g')
    echo "Reading ${USERNAME} ${PASSWORD} ${STATUS} from ${USER_DATA}"
    case "$STATUS" in
      "1")
        create_user "$USERNAME" "$PASSWORD"
        ;;
      "0")
        remove_user "$USERNAME"
        ;;
      *)
        echo "Invalid status for user ${USERNAME}"
    esac
  done < "$FTP_USERS_FILE"
}

touch "$FTP_USERS_FILE" || exit 1

if [ ! -z "$FTP_USER" ]; then
  if [ -z "$FTP_PASSWORD" ]; then
    echo "FTP_PASSWORD must be set"
    exit 1
  fi
  echo "${FTP_USER}:${FTP_PASSWORD}:1" >> "$FTP_USERS_FILE"
fi

while true; do
  read_users
  sleep 60
done

