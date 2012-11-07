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
    echo "usage: $ME <input> <output> [resolution]"
    exit
fi

if [ ! -f "$IN" ]
then
    echo "Input file '$IN' doesn't exists"
    exit
fi

FFMPEG="$(which ffmpeg)"
if [ -z "$FFMPEG" ]
then
    FFMPEG="$(whereis ffmpeg)"
fi

FFPROBE="$(which ffprobe)"
if [ -z "$FFPROBE" ]
then
    FFMPEG="$(whereis ffprobe)"
fi

if [ ! -z "$FFPROBE" ]
then
    echo "ffmpeg was found in system"
else
    echo "ffpeg was not found in system"
    echo "please install it first"
    echo "or add it to you PATH"
    exit
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

exit
$FFMPEG \
    -i "$IN" \
    $IFRESIZE \
    -vcodec $VCODEC \
    -acodec $ACODEC \
    $ADVARG \
    "$OUT"
