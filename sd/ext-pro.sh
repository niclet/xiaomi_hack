#!/bin/sh

export XIAOMI_HACK_DEVICE_NAME=mijia360

##### XIAOMI COMMON HACK ##### 

# When script is started without any arguments, we assume it is the official startup
# We restart it with useless param and redirect output to log file on sdcard

if [ $# -eq 0 ]; then
   export XIAOMI_HACK_HOME=/sdcard/xiaomi_hack
   export XIAOMI_HACK_DEVICE_HOME=${XIAOMI_HACK_HOME}/${XIAOMI_HACK_DEVICE_NAME}
   export XIAOMI_HACK_LOGS=${XIAOMI_HACK_HOME}/logs
   export XIAOMI_HACK_TMP=/tmp/xiaomi_hack
   mkdir -p "${XIAOMI_HACK_LOGS}"
   mkdir -p "${XIAOMI_HACK_TMP}"
   $0 nop > "${XIAOMI_HACK_LOGS}/${XIAOMI_HACK_DEVICE_NAME}.log" 2>&1
   exit $?
fi

# Export all available variables from ${XIAOMI_HACK_HOME}/config.cfg
if [ -f ${XIAOMI_HACK_HOME}/config.cfg ]; then
   echo "### Export variables from ${XIAOMI_HACK_HOME}/config.cfg ..."
   while read env_var; do
      if [ "${env_var:0:12}" = "XIAOMI_HACK_" ]; then
         echo -e "export \"${env_var}\""
         export "${env_var}"
      fi
   done < ${XIAOMI_HACK_HOME}/config.cfg
   echo
   # Create XIAOMI_HACK environment file
   export | grep XIAOMI_HACK_ > "${XIAOMI_HACK_TMP}/xiaomi_hack_env.sh"
else
   echo "Error: ${XIAOMI_HACK_HOME}/config.cfg is not available"
fi

##### MIJIA360 CUSTOM HACK #####

# In first versions of this hack, default root password was unknown.
# That's why we changed it to be able to connect using telnet.
# Now that default root password is known, we can revert back to it.
# We check if revert is needed only for the two first available firmwares:
#    3.3.2_2016071217
#    3.3.2_2016081814
# For future firmware, previous hack shouldn't be used anymore

FIRMWARE_VERSION=$(cat /etc/os-release)
XIAOMI_HACK_MIJIA360_SHADOW_BACKUP=${XIAOMI_HACK_DEVICE_HOME}/shadow.backup
if [ "${FIRMWARE_VERSION}" == "CHUANGMI_VERSION=3.3.2_2016071217" -o "${FIRMWARE_VERSION}" == "CHUANGMI_VERSION=3.3.2_2016081814" ]; then
   if [ -f "${XIAOMI_HACK_MIJIA360_SHADOW_BACKUP}" ]; then
      diff /etc/shadow "${XIAOMI_HACK_MIJIA360_SHADOW_BACKUP}" > /dev/null
      if [ $? -eq 1 ]; then
         cp "${XIAOMI_HACK_MIJIA360_SHADOW_BACKUP}" /etc/shadow
      fi
   fi
fi

# Manage Telnet server
if [ "$XIAOMI_HACK_TELNET_SERVER" == "NO" ]; then
   systemctl stop telnet.socket
fi

# Manage FTP server
if [ "$XIAOMI_HACK_FTP_SERVER" == "YES" ]; then
   if [ -f ${XIAOMI_HACK_DEVICE_HOME}/bin/tcpsvd ]; then
      echo "### Activating FTP server ..."
      ${XIAOMI_HACK_DEVICE_HOME}/bin/tcpsvd -vE 0.0.0.0 21 ftpd -w / &
      sleep 1
      echo
   else
      echo "Error: Unable to activate FTP server, ${XIAOMI_HACK_DEVICE_HOME}/bin/tcpsvd is not available"
   fi
fi

# Startup sequence is:
# /usr/local/bin/run.sh
#    /usr/imi/start.sh
#       /usr/local/bin/init.sh
#          /sdcard/ext-pro.sh
#       /usr/imi/miio.sh
#          /usr/imi/imiApp

# We virtually modify /usr/imi/miio.sh
# We create a modified version of /usr/imi/miio.sh in /tmp
# We mount the modified version in place of the official one, this modification is not persistent

# Create xiaomi_hack_env.sh / miio_pre.sh / miio.sh / miio_post.sh sequence
cat "${XIAOMI_HACK_TMP}/xiaomi_hack_env.sh" "${XIAOMI_HACK_DEVICE_HOME}/sh/miio_pre.sh" /usr/imi/miio.sh "${XIAOMI_HACK_DEVICE_HOME}/sh/miio_post.sh" > "${XIAOMI_HACK_TMP}/miio.sh"
# Make the modified version executable
chmod +x ${XIAOMI_HACK_TMP}/miio.sh
# Mount the modified version in place of the official one, this modification is not persistent
mount --bind ${XIAOMI_HACK_TMP}/miio.sh /usr/imi/miio.sh
