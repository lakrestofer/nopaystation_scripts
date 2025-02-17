#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>

# return codes:
# 1 user errors
# 2 no DLC available
# 4 not all keys or links available
# 5 game archive already exists

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "${0}")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

my_usage(){
    echo ""
    echo "Usage:"
    echo "${0} \"/path/to/DLC.tsv\" \"PCSE00986\""
}

MY_BINARIES="pkg2zip sed grep t7z file"
sha256_choose; downloader_choose

check_binaries "${MY_BINARIES}"

# Get variables from script parameters
TSV_FILE="${1}"
GAME_ID="${2}"

if [ ! -f "${TSV_FILE}" ]
then
    echo "No TSV file found."
    my_usage
    exit 1
fi
if [ -z "${GAME_ID}" ]
then
    echo "No game ID found."
    my_usage
    exit 1
fi

check_valid_psv_id "${GAME_ID}"
MY_PATH="$(pwd)"

# make DESTDIR overridable
if [ -z "${DESTDIR}" ]
then
    DESTDIR="${GAME_ID}"
fi

if ! grep -q "^${GAME_ID}" "${TSV_FILE}"
then
    exit 2
fi

LIST=$(grep "^${GAME_ID}" "${TSV_FILE}" | cut -f"4,5,9" | tr '\t' '%' | tr -d '\r')
# '\r' bytes interfere with string comparison later on, so we remove them

for i in ${LIST}
do
    LINK=$(echo "${i}" | cut -d"%" -f1)
    KEY=$(echo "${i}" | cut -d"%" -f2)
    LIST_SHA256=$(echo "${i}" | xargs | cut -d"%" -f3)

    MISSING_COUNT=0
    if [ "${LINK}" = "MISSING" ] && [ "${KEY}" = "MISSING" ]
    then
        >&2 echo "Download link and zRIF key are missing."
        MISSING_COUNT=$((${MISSING_COUNT} + 1))
    elif [ "${LINK}" = "MISSING" ]
    then
        >&2 echo "Download link is missing."
        MISSING_COUNT=$((${MISSING_COUNT} + 1))
    elif [ "${KEY}" = "MISSING" ]
    then
        >&2 echo "zRIF key is missing."
        MISSING_COUNT=$((${MISSING_COUNT} + 1))
    fi


    if [ ! -d "${MY_PATH}/${DESTDIR}_dlc" ]
    then
        mkdir "${MY_PATH}/${DESTDIR}_dlc"
    fi
    cd "${MY_PATH}/${DESTDIR}_dlc"

    my_download_file "${LINK}" "${GAME_ID}_dlc.pkg"
    FILE_SHA256="$(my_sha256 "${GAME_ID}_dlc.pkg")"
    compare_checksum "${LIST_SHA256}" "${FILE_SHA256}"

    # get file name and modify it
    pkg2zip -l "${GAME_ID}_dlc.pkg" | sed 's/\.zip//g' > "${GAME_ID}_dlc.txt"
    MY_FILE_NAME="$(cat "${GAME_ID}_dlc.txt")"
    MY_FILE_NAME="$(region_rename "${MY_FILE_NAME}")"


    # extract files and compress them with t7z
    test -d "addcont/" && rm -rf "addcont/"
    pkg2zip -x "${GAME_ID}_dlc.pkg" "${KEY}"
    # add the -rs parameter until a bug on the t7z port for FreeBSD is fixed
    # t7z -ba -rs a "${MY_FILE_NAME}.7z" "addcont/"
    zip -r "${MY_FILE_NAME}.zip" "addcont/"
    rm -rf "addcont/"
    rm "${GAME_ID}_dlc.pkg"
    rm "${GAME_ID}_dlc.txt"
    cd "${MY_PATH}"

    echo "$KEY" >> "${MY_FILE_NAME}_dlc_key.txt"
    
done
if [ ${MISSING_COUNT} -gt 0 ]
then
    exit 4
else
    exit 0
fi
