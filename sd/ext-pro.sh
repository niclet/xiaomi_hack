#!/bin/sh

export XIAOMI_DEVICE_NAME=mijia360

##### XIAOMI COMMON HACK

# When script is started without any arguments, we assume it is the official startup
# We restart it with useless param and redirect output to log file on sdcard

if [ $# -eq 0 ]; then
   export XIAOMI_HACK_HOME=/sdcard/xiaomi_hack
   export XIAOMI_DEVICE_HOME=${XIAOMI_HACK_HOME}/${XIAOMI_DEVICE_NAME}
   export XIAOMI_LOGS_HOME=${XIAOMI_HACK_HOME}/logs
   mkdir -p "${XIAOMI_LOGS_HOME}"
   $0 nop > "${XIAOMI_LOGS_HOME}/${XIAOMI_DEVICE_NAME}_hack.log" 2>&1
   exit $?
fi

# Export all available variables from ${XIAOMI_HACK_HOME}/config.cfg
if [ -f ${XIAOMI_DEVICE_HOME}/config.cfg ]; then
   echo "### Export variables from ${XIAOMI_DEVICE_HOME}/config.cfg ..."
   while read env_var; do
      if [ "${env_var:0:12}" = "XIAOMI_HACK_" ]; then
         echo -e "export \"${env_var}\""
         export "${env_var}"
      fi
   done < ${XIAOMI_DEVICE_HOME}/config.cfg
   echo
else
   echo "Error: ${XIAOMI_DEVICE_HOME}/config.cfg is not available"
fi

##### MIJIA360 CUSTOM HACK

# Change root password
if [ "${XIAOMI_HACK_ROOT_PASSWORD}" != "" ]; then
   echo "### Set root password ..."
   # Save current date
   current_date=$(date +%Y.%m.%d-%H:%M:%S)
   # Set current date to 2013 June 19th to make "last changed date" unchanged in /etc/shadow
   date -s 2013-06-19
   # Change password of current user which is root
   echo -e "${XIAOMI_HACK_ROOT_PASSWORD}\n${XIAOMI_HACK_ROOT_PASSWORD}\n" | passwd
   # Restore original date
   date -s $current_date
else
   echo "Error: XIAOMI_HACK_ROOT_PASSWORD is not set"
fi

# Launch ftp server
if [ "$XIAOMI_HACK_FTP_SERVER" = "YES" ]; then
   if [ -f ${XIAOMI_DEVICE_HOME}/bin/tcpsvd ]; then
      echo "### Activating FTP server ..."
      ${XIAOMI_DEVICE_HOME}/bin/tcpsvd -vE 0.0.0.0 21 ftpd -w / &
      sleep 1
      echo
   else
      echo "Error: Unable to activate FTP server, ${XIAOMI_DEVICE_HOME}/bin/tcpsvd is not available"
   fi
fi

