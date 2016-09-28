
# will run before /usr/imi/miio.sh

# Activate native hack traces
if [ "${XIAOMI_HACK_LANGUAGE_TRACES}" == "YES" ]; then
   export XIAOMI_HACK_LANGUAGE_TRACES_LOGFILE="${XIAOMI_HACK_LOGS}/${XIAOMI_HACK_DEVICE_NAME}_audio.log"
fi

# Activate new timezone
if [ "${XIAOMI_HACK_TIMEZONE}" != "" ]; then
   export "TZ=${XIAOMI_HACK_TIMEZONE}"
fi

# Let's native hack library be loaded in all forecoming processes
export LD_PRELOAD=${XIAOMI_HACK_DEVICE_HOME}/bin/libxiaomihack.so
