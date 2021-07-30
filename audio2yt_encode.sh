#!/bin/bash

TEMP_DIR="/mnt/free-tekno.com/tmp"
mkdir -p $TEMP_DIR

STORAGE="/mnt/free-tekno.com/storage"
VIDEO_STORAGE="/mnt/free-tekno.com/storage" # backward compatibility
mkdir -p $VIDEO_STORAGE # backward compatibility

LOCKFILE=$TEMP_DIR/encode.lock

if [ -f "$LOCKFILE" ]; then
    echo "$LOCKFILE found, exiting.."
    exit
fi

touch $LOCKFILE

# set env
SQL="mysql -u $MYSQL_USER -p$MYSQL_PASS $DB_NAME -h $DB_HOST"
myvar=$($SQL -se "SELECT id,owner_id,url,image,yt_status,yt_url FROM tracks WHERE yt_status IS NULL ORDER BY id ASC LIMIT 1;")

ID=$(echo $myvar | awk '{print $1}')
OWNER_ID=$(echo $myvar | awk '{print $2}')
URL=$(echo $myvar | awk '{print $3}')
IMAGE=$(echo $myvar | awk '{print $4}')
YT_STATUS=$(echo $myvar | awk '{print $5}')
YT_URL=$(echo $myvar | awk '{print $6}')

# cli debug
echo "ID: "$ID
echo "URL: "$URL
echo "IMAGE: "$IMAGE
echo "YT_STATUS: "$YT_STATUS
echo "YT_URL: "$YT_URL

# filenames
echo $URL | sed 's/storage\/track_media\///g' > $TEMP_DIR/temp_id
cat $TEMP_DIR/temp_id | sed 's/\.mp3//g' > $TEMP_DIR/id
REAL_ID=$(cat $TEMP_DIR/id)
echo $URL | sed 's/storage\/track_image\///g' > $TEMP_DIR/temp_image
IMAGE_NAME=$(cat $TEMP_DIR/temp_image)

# save track id to video storage
echo $ID > $VIDEO_STORAGE/$REAL_ID.id

WEBSITE_PUBLIC_STORAGE_PATH="/var/www/free-tekno.com/public"
# convert audio to video (ffmpeg waveforms recipe) and save mp4 file to storage
ffmpeg -i $WEBSITE_PUBLIC_STORAGE_PATH/$URL -filter_complex "[0:a]showwaves=s=1280x720:mode=line:rate=25,format=yuv420p[v]" -map "[v]" -map 0:a $VIDEO_STORAGE/$REAL_ID.mp4
$SQL -se "UPDATE tracks SET yt_status = 1 WHERE id = $ID;"

rm $LOCKFILE