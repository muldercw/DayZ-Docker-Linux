#!/bin/bash
# Update server files
if [ $UPDATE = true ]
then
    echo "Checking for server updates..."
    /usr/games/steamcmd +login anonymous +force_install_dir /server +app_update $STEAM_APP_ID validate +quit
fi

# Update mods
if [ $UPDATE_MODS = true ]
then
    echo "Checking for mod updates..."
    source /update_mods.sh -l $MOD_ID
fi

# Automatically load all mods
if [ $AUTO_MODS = true ]
then
    echo "Loading all mods..."
    $MODS_FOUND=""
    for d in "/server/mods"
    do
        echo "Found mod $d"
        $MODS_FOUND="${MODS_FOUND}mods/$d;"
    done
    MODS=${MODS_FOUND::-1}
fi

# Debug
if [ $DEBUG = true ]
then
    echo "Debug enabled, system variables:"
    echo "Steam App ID: $STEAM_APP_ID"
    echo "CPU Count: $CPU_COUNT"
    echo "Game Port: $GAME_PORT"
    echo "Mods: $MODS"
    sleep 5
fi

# Logs cleanup
if [ $DELETE_LOGS = true ]
then
    echo "Removing logs and error dumps..."
    rm -f /server/profile/*.log
    rm -f /server/profile/*.RPT
    rm -f /server/profile/*.ADM
    rm -f /server/profile/*.mdmp
    echo "Done!"
fi

# First run init
if [[ ! -d "./config/myserver/serverDZ.cfg" ]]; then
    echo "Template folder doesn't exist, creating...";
    source /init.sh
fi

# Copy mod keys
echo "Copying keys..."
find /server/mods -name '*.bikey' -exec cp -prv '{}' '/server/keys' ';' # | cpio -upm /server/keys

# Run server
echo "Starting server..."
/server/DayZServer -cpuCount=$CPU_COUNT -dologs -adminlog -netlog -freezecheck -port="${GAME_PORT}" -profiles="${PROFILE_DIR}" -config="${CONFIG_FILE}" "-mod=${MODS}"