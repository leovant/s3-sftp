#!/bin/bash
FTP_USERS_DIR="${FTP_DIRECTORY}/users"
FTP_USERS_FILE="${FTP_DIRECTORY}/users.conf"

# Disable an user
function disable_user() {
  local USER=$1
  local PASS=$(date | md5sum | head -c8)
  # Actually, mantain all the user data, just changing the password
  # so the user could not connect anymore
  set_pass "$USER" "$PASS"
}
# Set an user's password
function set_pass() {
  local USER=$1
  local PASS=$2
  
  echo "${USER}:${PASS}" | chpasswd 
}
# Set permissions to files added directly in the bucket
function set_permissions() {
  local USER=$1
  local FILE_PERMISSIONS=644
  local DIRECTORY_PERMISSIONS=755

  chown root:ftpaccess "${FTP_USERS_DIR}/${USER}"
  chmod 750 "${FTP_USERS_DIR}/${USER}"
  chown $USER:ftpaccess "${FTP_USERS_DIR}/${USER}/data"
  chmod 750 "${FTP_USERS_DIR}/${USER}/data"

  # Search for files and directories not owned correctly
  find "$FTP_USERS_DIR"/"$USER"/data/* \( \! -user "$USER" \! -group "$USER" \) -print0 | xargs -0 chown "$USER:$USER"

  # Search for files with incorrect permissions
  find "$FTP_USERS_DIR"/"$USER"/data/* -type f \! -perm "$FILE_PERMISSIONS" -print0 | xargs -0 chmod "$FILE_PERMISSIONS"

  # Search for directories with incorrect permissions
  find "$FTP_USERS_DIR"/"$USER"/data/* -type d \! -perm "$DIRECTORY_PERMISSIONS" -print0 | xargs -0 chmod "$DIRECTORY_PERMISSIONS"
}
# Create an user
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
  mkdir -p "${FTP_USERS_DIR}/${USER}/data"

  echo "${USER}:${PASS}" | chpasswd

  return 0
}
# Read the users file
function read_users() {
  if [ -f "$FTP_USERS_FILE" ]; then
    while read USER_DATA
    do
        read USERNAME PASSWORD STATUS <<< $(echo "$USER_DATA" | sed 's/:/ /g')
        case "$STATUS" in
        "1") # Active user
            create_user "$USERNAME" "$PASSWORD"
            ;;
        "0") # User with access disabled
            disable_user "$USERNAME"
            ;;
        *)
            echo "Invalid status for user ${USERNAME}"
        esac
    done < "$FTP_USERS_FILE"
  fi
}
#
# Main script
#
while true; do
  read_users
  sleep 60
done

