#!/bin/bash

usage()
{
cat << EOF
usage: $0 [FileName]
Uploads files to Gofile
OPTIONS:
    -w        Steam workshop ID. If specified, it downloads a Steam workshop item instead of updating server files.
              Workshop content requires logging in with a Steam account that owns DayZ.

    -h        Show this message
EOF
}

WORKSHOP_ID="";
while getopts "hw:" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        w)
            WORKSHOP_ID="${OPTARG}";
            IS_WORKSHOP=1;
            echo "Attempting to download Steam workshop item: ${WORKSHOP_ID}";
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [[ -z "${BASE_DIR}" ]]; then
    BASE_DIR="$(dirname "$(realpath "$0")")";
fi
SERVER_FILES="${BASE_DIR}/server";
STEAMCMD_FILES="${BASE_DIR}/steamcmd";
WORKSHOP_FILES="${BASE_DIR}/workshop"

if [[ ! -d "${SERVER_FILES}" ]]; then
    if [ "$DEBUG" = true ]; then
        echo "Creating folder for storing server files: '${SERVER_FILES}'";
    fi
    mkdir -p "${SERVER_FILES}";
fi

if [[ ! -d "${STEAMCMD_FILES}" ]]; then
    if [ "$DEBUG" = true ]; then
        echo "Creating folder for storing workshop mod files: '${STEAMCMD_FILES}'";
    fi
    mkdir -p "${STEAMCMD_FILES}";
fi

# Check if already specified via environment variable
# Note: I have no idea what happens if you switch between exp/stable without clearing the
#       existing server files. Might be some conflicts?
if [[ -z "${STEAM_APP_ID}" ]]; then
    # Experimental
    STEAM_APP_ID=1042420

    # Stable
    # As of 2021-09-09, stable does NOT support Linux yet and therefore won't work.
    # STEAM_APP_ID=223350
fi

DATA_VOLUME="${SERVER_FILES}";
STEAMCMD_PARAMS="+app_update ${STEAM_APP_ID} validate";
STEAM_USERNAME="anonymous";

# Modify the command if a workshop ID is specified.
# Note: I am not entirely sure if this is the correct method.
if [[ ! -z "${WORKSHOP_ID}" ]]; then
    echo "Steam username: ";
    read -r STEAM_USERNAME;

    # echo "Name of mod (Steam workshop item):";
    # read WORKSHOP_MOD_NAME;

    DATA_VOLUME="${STEAMCMD_FILES}";
    STEAMCMD_PARAMS="+workshop_download_item 221100 ${WORKSHOP_ID} validate";
fi

# Run steamcmd in docker (wip)
docker run -it \
    -v "${DATA_VOLUME}":/data \
    -v "${BASE_DIR}/.steamcmd":/root/.steam \
    steamcmd/steamcmd:latest +login "${STEAM_USERNAME}" +force_install_dir /data \
    "$STEAMCMD_PARAMS" \
    +quit;


ORIG_MOD_FOLDER="${STEAMCMD_FILES}/steamapps/workshop/content/221100/${WORKSHOP_ID}";

# Get mod name from metadata
echo "Getting mod name from folder $ORIG_MOD_FOLDER..."
WORKSHOP_MOD_NAME=$(cat "$ORIG_MOD_FOLDER/meta.cpp" | grep name | grep -o -P '(?<=name = ").*(?=")')
echo "Found mod $WORKSHOP_MOD_NAME."
MOD_NAME=$(echo "$WORKSHOP_MOD_NAME" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
echo "Trimmed to: $WORKSHOP_MOD_NAME >> $MOD_NAME"
MOD_NAME_FOLDER="${WORKSHOP_FILES}/${MOD_NAME}";

# Get mod timestamp
echo "Checking if $WORKSHOP_MOD_NAME has updated..."
SOURCE_TIMESTAMP=$(cat "$ORIG_MOD_FOLDER/meta.cpp" | grep name | grep -o -P '(?<=timestamp = ").*(?=")')
if [ -d "$MOD_NAME_FOLDER" ]; then
    TARGET_TIMESTAMP=$(cat "$MOD_NAME_FOLDER/meta.cpp" | grep name | grep -o -P '(?<=timestamp = ").*(?=")')
    if (( SOURCE_TIMESTAMP > TARGET_TIMESTAMP )); then
        echo "Mod $WORKSHOP_MOD_NAME has been updated!"
        if [ "$DEBUG" = true ]; then
            echo "Copying $WORKSHOP_MOD_NAME to $MOD_NAME_FOLDER..."
        fi
        cp -rf "$ORIG_MOD_FOLDER" "$MOD_NAME_FOLDER"
    else
        if [ "$DEBUG" = true ]; then
            echo "Mod $WORKSHOP_MOD_NAME is already up to date."
        fi
    fi
else
    echo "New mod found, copying to $MOD_NAME_FOLDER..."
    cp -rf "$ORIG_MOD_FOLDER" "$MOD_NAME_FOLDER"
fi

# Trim folders and filenames to lower case
if [ "$DEBUG" = true ]; then
    echo "Trimming all folder and file names to lowercase..."
fi
# First, rename all folders
find "${MOD_NAME_FOLDER}" -depth ! -name CVS -type d | while read -r f; do
    g=$(dirname "$f")/$(basename "$f" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    if [ "xxx$f" != "xxx$g" ]; then
        if [ "$DEBUG" = true ]; then
            echo "Renaming folder $f to $g"
        fi
        mv -f "$f" "$g"
    fi
done

# Now, rename all files
find "${MOD_NAME_FOLDER}" ! -type d | while read -r f; do
    g=$(dirname "$f")/$(basename "$f" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    if [ "xxx$f" != "xxx$g" ]; then
        if [ "$DEBUG" = true ]; then
            echo "Renaming file $f to $g"
        fi
        mv -f "$f" "$g"
    fi
done
