#!/bin/sh
#

# Generating bobblemazes using xjobs (multi-threaded environment)
# Usage: xmazes.sh filename count masks-set

F=$1
C=$2
S=$3

if test -e $F; then echo "File already exists!"; exit; fi

for I in `seq 1 $C`
do
#	echo octave --silent --eval "\"f='$F'; c=$I; s='$S';\"" xmazes.m
	echo octave --silent --eval "\"f='$F'; c=$I; s='$S'; source('xmazes.m');\""
done | xjobs

grep -vhs Octave $F-* > $F
rm $F-*
