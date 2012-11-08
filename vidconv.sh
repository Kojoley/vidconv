#!/usr/bin/env bash

# 1. Check if ffmpeg installed
# 2. Setup variables
# 3. Process ffmpeg convertation

VCODEC=libx264
ACODEC=aac
ADVARG="-strict experimental" # "-strict experimental" is required by using aac codec (use libfaac instead, if you can)

IN=$1
OUT=$2
SIZE=$3

if [ -z "$IN" ] || [ -z "$OUT" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
    ME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")" #"
    echo "usage: $ME <input> <output> [resolution] [-x </path/to/ffmpeg>]"
    exit
fi

if [ ! -f "$IN" ]
then
    echo "Input file '$IN' doesn't exists"
    exit
fi

ARGS=("$@")
for (( I = 0; I < ${#ARGS[@]}; I++)); do
    #echo "$I:${ARGS[${I}]}"
    case ${ARGS[${I}]} in
        "-x")
            ((I++))
            CUSTOM_PATH="${ARGS[${I}]}"
            echo "setting custom path to '$CUSTOM_PATH'"
            ;;
    esac
done

if [ -z "$CUSTOM_PATH" ]
then
    if [ -z "$FFMPEG" ]
    then
        FFMPEG="$(which ffmpeg)"
    fi
    if [ -z "$FFMPEG" ]
    then
        FFMPEG="$(whereis ffmpeg)"
    fi

    FFPROBE="$(dirname ${FFMPEG})/ffprobe"
else
    FFMPEG="$CUSTOM_PATH/ffmpeg"
    FFPROBE="$CUSTOM_PATH/ffprobe"
fi

echo "check for existing of '$FFMPEG'"
if [ ! -f "$FFMPEG" ]
then
    echo -e '\E[031;1m'"\033[1m"
    echo "ffpeg was not found in system"
    echo "please install it first"
    echo "or add it to you PATH"
    echo -en "\033[0m"
    exit
else
    echo "ffmpeg was found in system"
fi

if [ -n "$SIZE" ]
then
    # aquire input resolution
    IW="$($FFPROBE -v 0 -show_streams "$IN" 2>&1 | grep ^width | sed s/width=//)"
    IH="$($FFPROBE -v 0 -show_streams "$IN" 2>&1 | grep ^height | sed s/height=//)"
    # split bound resolution
    OW=${SIZE%x*}
    OH=${SIZE#*x}
    # calc input and bound aspect
    SA=$(echo "$IW / $IH" | bc -l)
    DA=$(echo "$OW / $OH" | bc -l)
    # calc result resolution
    if [ "$(echo "$SA > $DA" | bc)" == "1" ]
    then
        RW=$(echo "$OW / 4 * 4" | bc)
        RH=$(echo "$OW / $SA / 4 * 4" | bc)
    else
        RW=$(echo "$OH * $SA / 4 * 4" | bc)
        RH=$(echo "$OH / 4 * 4" | bc)
    fi

    echo "input size ${IW}x${IH}"
    echo "boundary size $SIZE"
    echo "aspect ratio $SA"

    RESULTSIZE="${RW}x${RH}"
    echo "result size $RESULTSIZE"
    IFRESIZE="-s $RESULTSIZE"
else
    echo "result size same as input"
    IFRESIZE=
fi

$FFMPEG \
    -i "$IN" \
    $IFRESIZE \
    -vcodec $VCODEC \
    -acodec $ACODEC \
    $ADVARG \
    "$OUT"
