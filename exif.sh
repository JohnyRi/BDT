#!/bin/bash
TMPPATH="/tmp/$USER/images"
#mkdir -p "$TMPPATH"
mkdir -p "$TMPPATH/out"
hdfs dfs -get "/user/pascepet/data/images/" "/tmp/$USER/"
for I in `ls "$TMPPATH"`
do #Read all images from the tmp folder and put their exif data in out folder
	echo "Processing exif extracting for image $I"
	identify -verbose "$TMPPATH/$I" | grep exif > "$TMPPATH/out/$I.exif"
done
#Not necessary, exif data are filtered later
#find "$TMPPATH/out" -size  0 -print0 |xargs -0 rm -- #remove empty files
mkdir -p "$TMPPATH/final"
rm -f "$TMPPATH/final/exif.csv"
for I in `ls "$TMPPATH/out/"`
do #Read all exif from the out folder and filter them
        echo "Processing filtering for image $I"
	#Filtering out exif data
        DATETIME=`cat "$TMPPATH/out/$I" | grep exif:DateTime: | cut -d ' ' -f6,7`
        DATE=`echo "$DATETIME" | cut -d ' ' -f1 | sed s/:/-/g`
        TIME=`echo "$DATETIME" | cut -d ' ' -f2`
        EPOCH=`date --date="$DATE $TIME" +%s`
        EXPOSURETIME=`cat "$TMPPATH/out/$I" | grep exif:ExposureTime: | cut -d ' ' -f6`
        WIDTH=`cat "$TMPPATH/out/$I" | grep exif:ExifImageWidth: | cut -d ' ' -f6`
        HEIGHT=`cat "$TMPPATH/out/$I" | grep exif:ExifImageLength: | cut -d ' ' -f6`
	#All required fields exists
        if test -n "$DATETIME" && test -n "$EXPOSURETIME"  && test -n "$WIDTH"  && test -n "$HEIGHT"
        then
                echo "$DATE" "$TIME","$EXPOSURETIME","$WIDTH","$HEIGHT" >> "$TMPPATH/final/exif.csv"
        else
                echo "Image $I has not enough exif data!"
        fi
done
#DATE=`echo "$DATETIME" | cut -d ' ' -f1 | sed s/:/-/g`
#TIME=`echo "$DATETIME" | cut -d ' ' -f2`

hdfs dfs -put -f "$TMPPATH/final/exif.csv" "/user/$USER/data/exif.csv"

