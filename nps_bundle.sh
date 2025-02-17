#!/bin/sh

# AUTHOR sigmaboy <j.sigmaboy@gmail.com>

# get directory where the scripts are located
SCRIPT_DIR="$(dirname "$(readlink -f "$(which "${0}")")")"

# source shared functions
. "${SCRIPT_DIR}/functions.sh"

### usage function
my_usage(){
    echo ""
    echo "Parameters:"
    echo "--nps-dir|-d <DIR>               path to the directory containing the tsv files"
    echo "--title-id|-t <ID>               ID of game"
}

### check if nps tsv file directory exists
test_nps_dir() {
    local NPS_DIR="${1}"
    if [ ! -d "${NPS_DIR}" ]
    then
        echo "Directory containing *.tsv files missing (\"${NPS_DIR}\"). Check your path parameter."
        my_usage
        exit 1
    fi
}

while [ ${#} -ge 1 ]
do
    opt=${1}
    shift
    case ${opt} in
        -t|--title-id)
            test -n "${1}"
            exit_if_fail "\"-t\" used without <TITLE ID>"
            check_valid_psv_id "${1}"
            TITLE_ID="${1}"
            shift
            ;;
        -d|--nps-dir)
            test -n "${1}"
            exit_if_fail "\"-d\" used without directory path argument used"
            test_nps_dir "${1}"
            NPS_DIR="${1}"
            shift
            ;;
        *)
            echo "Invalid parameter used."
            my_usage
            echo ""
            exit 1
            ;;
    esac
done

# check if necessary binaries are available
MY_BINARIES="pkg2zip sed"
check_binaries "${MY_BINARIES}"


if [ -z "${TITLE_ID}" ]
then
    echo "ERROR:"
    echo "<TITLE ID> is missing."
    echo 'Use "-t <TITLE ID>" parameter'
    exit 1
elif [ -z "${NPS_DIR}" ]
then
    echo "ERROR:"
    echo "<NPS DIR> is missing."
    echo 'Use "-d <NPS DIR>" parameter'
    exit 1
fi

### check if nps tsv file directory exists
if [ ! -d "${NPS_DIR}" ]
then
    echo "Directory containing *.tsv files missing (\"${NPS_DIR}\"). Check your path parameter."
    my_usage
    exit 1
fi

### check if the tsv files are available to call download scripts
tsv_files="PSV_GAMES.tsv PSV_DLCS.tsv PSV_UPDATES.tsv"
for tsv_file in $tsv_files
do
    if [ ! -f "${NPS_DIR}/${tsv_file}" ]
    then
        echo "*.tsv file \"${tsv_file}\" in path \"${NPS_DIR}\" missing."
        exit 1
    fi
done

### Download the chosen game
nps_game.sh "${NPS_DIR}/PSV_GAMES.tsv" "${TITLE_ID}"
if [ ${?} -ne 0 ]
then
    echo ""
    echo "Game cannot be downloaded. Skipping further steps."
    exit 1
fi

### Get name of the zip file from generated txt created via nps_game.sh
GAME_NAME="$(cat "${TITLE_ID}.txt")"
GAME_NAME="$(region_rename "${GAME_NAME}")"
ZIP_FILENAME="${GAME_NAME}.${ext}"

### Download available updates. With parameter -a all updates
DESTDIR="${GAME_NAME}" nps_update.sh "${TITLE_ID}"

### Download available DLC
DESTDIR="${GAME_NAME}" nps_dlc.sh "${NPS_DIR}/PSV_DLCS.tsv" "${TITLE_ID}"

### remove temporary game name file
rm "${TITLE_ID}.txt"

### Run post scripts
if [ -x ./nps_bundle_post.sh ]
then
    ./nps_bundle_post.sh "${GAME_NAME}"
fi
