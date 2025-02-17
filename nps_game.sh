#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>

# return codes:
# 1 user errors
# 3 game is only available physically
# 4 link or key missing.
# 5 game archive already exists

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

my_usage() {
    echo ""
    echo "Usage:"
    echo "${0} \"/path/to/GAME.tsv\" \"PCSE00986\""
}

MY_BINARIES="pkg2zip sed grep file t7z"
sha256_choose; downloader_choose

check_binaries "${MY_BINARIES}"

# Get variables from script parameters
TSV_FILE="${1}"
TITLE_ID="${2}"


if [ ! -f "${TSV_FILE}" ]
then
    echo "No TSV file found."
    my_usage
    exit 1
fi
if [ -z "${TITLE_ID}" ]
then
    echo "No game ID found."
    my_usage
    exit 1
fi

check_valid_psv_id "${TITLE_ID}"

# check if MEDIA ID is found in download list
if ! grep "^${TITLE_ID}" "${TSV_FILE}" > /dev/null
then
    echo "ERROR:"
    echo "Media ID is not found in your *.tsv file"
    echo "Check your input for a valid media ID"
    echo "Search on: \"https://renascene.com/psv/\" for"
    echo "Media IDs or simple open the *.tsv with your Office Suite."
    exit 1
fi

# get link, encryption key and sha256sum
LIST=$(grep "^${TITLE_ID}" "${TSV_FILE}" | cut -f"4,5,10")

# save those in separete variables
LINK=$(echo "${LIST}" | cut -f1)
KEY=$(echo "${LIST}" | cut -f2)
LIST_SHA256=$(echo "${LIST}" | cut -f3)

if [ "${LINK}" = "MISSING" ] && [ "${KEY}" = "MISSING" ]
then
    echo "Download link and zRIF key of \"${TITLE_ID}\" are missing."
    echo "Cannot proceed."
    exit 4
elif [ "${LINK}" = "MISSING" ]
then
    echo "Download link of \"${TITLE_ID}\" is missing."
    echo "Cannot proceed."
    exit 4
elif [ "${KEY}" = "MISSING" ]
then
    echo "zrif key of \"${TITLE_ID}\" is missing."
    echo "Cannot proceed."
    exit 4
elif [ "${LINK}" = "CART ONLY" ]
then
    echo "\"${GANE_ID}\" is only available via cartridge"
    exit 3
fi

echo "Game Key:"
echo "$KEY"

my_download_file "${LINK}" "${TITLE_ID}.pkg"
FILE_SHA256="$(my_sha256 "${TITLE_ID}.pkg")"
compare_checksum "${LIST_SHA256}" "${FILE_SHA256}"

# get file name and modify it
pkg2zip -l "${TITLE_ID}.pkg" | sed 's/.zip//g' > "${TITLE_ID}.txt"
MY_FILE_NAME="$(cat "${TITLE_ID}.txt")"
MY_FILE_NAME="$(region_rename "${MY_FILE_NAME}")"

echo "$KEY" >> "${MY_FILE_NAME}_game_key.txt"

test -d "app/" && rm -rf "app/"
pkg2zip -x "${TITLE_ID}.pkg" "${KEY}"
# add the -rs parameter until a bug on the t7z port for FreeBSD is fixed
# t7z -ba -rs a "${MY_FILE_NAME}.7z" "app/"
zip -r "${MY_FILE_NAME}.zip" "app/"
rm -rf "app/"
rm "${TITLE_ID}.pkg"
exit 0
