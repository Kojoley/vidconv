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

if [ -n "$(which ffmpeg)" ]
then
    echo "ffmpeg was found in system"
else
    echo "ffpeg was not found in system"
    echo "please install it"
    exit
fi

ORIG="$(ffmpeg -i "$IN" 2>&1 | sed -e '/Video/!d; s/^.*,\s\([0-9]*x[0-9]*\).*/\1/')"
echo "input size $ORIG"

if [ -n "$SIZE" ]
then
    # split input resolution
    IW=${ORIG%x*}
    IH=${ORIG#*x}
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

    echo "boundary size $SIZE"
    echo "aspect ratio $SA"

    RESULTSIZE=${RW}x$RH
    echo "result size $RESULTSIZE"
    IFRESIZE="-s $RESULTSIZE"
else
    echo "result size same as input"
    IFRESIZE=
fi


ffmpeg \
    -i "$IN" \
    $IFRESIZE \
    -vcodec $VCODEC \
    -acodec $ACODEC \
    $ADVARG \
    "$OUT"
