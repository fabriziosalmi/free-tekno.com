#!/bin/bash

NOTIFY_MAIL="fabrizio.salmi@gmail.com"
TEMP_DIR="/mnt/free-tekno.com/tmp"
mkdir -p $TEMP_DIR
VIDEO_STORAGE="/mnt/free-tekno.com/storage"
mkdir -p $VIDEO_STORAGE

LOCKFILE2=$TEMP_DIR/upload.lock

if [ -f "$LOCKFILE2" ]; then
    echo "$LOCKFILE2 found, exiting.."
    exit
fi

touch $LOCKFILE2

# set env

SQL="mysql -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB -h $MYSQL_HOST"
myvar=$($SQL -se "SELECT id,owner_id,url,image FROM tracks WHERE yt_status = 1 ORDER BY id ASC LIMIT 1;")

ID=$(echo $myvar | awk '{print $1}')
OWNER_ID=$(echo $myvar | awk '{print $2}')
URL=$(echo $myvar | awk '{print $3}')
IMAGE=$(echo $myvar | awk '{print $4}')

# retrieve info
echo $URL | sed 's/storage\/track_media\///g' > $TEMP_DIR/temp_id
cat $TEMP_DIR/temp_id | sed 's/\.mp3//g' > $TEMP_DIR/id
REAL_ID=$(cat $TEMP_DIR/id)
TRACK_NAME=$($SQL -se "SELECT name FROM tracks WHERE id = $ID;")
TRACK_ARTIST=$($SQL -se "SELECT first_name, last_name FROM users WHERE id = $OWNER_ID;")
VIDEO_PATH=$VIDEO_STORAGE/$REAL_ID.mp4

echo "Listen and download $TRACK_NAME by $TRACK_ARTIST for free on https://free-tekno.com\n\nSend your music: https://t.me/joinchat/pulxr-bv87szMTA0\n24/7 free tekno
radio, streaming and rave culture: https://www.freeundergroundtekno.org" > $TEMP_DIR/video_description

DESCRIPTION=$(cat $TEMP_DIR/video_description)
TAGS="tekno,freetekno,free-tekno.com,free underground tekno radio,taz,teknival,$TRACK_NAME,$TRACK_ARTIST,rave,free party,dj,mix,liveset"

# upload to YouTube
youtubeuploader_linux_amd64 -categoryId 10 -title "$TRACK_NAME by $TRACK_ARTIST" -description "$DESCRIPTION" -tags "$TAGS" -thumbnail "https://free-tekno.com/$IMAGE"  -filename $VIDEO_PATH > $TEMP_DIR/temp_upload

# retrieve YouTube video ID
YT_URL_CREATED=$(cat $TEMP_DIR/temp_upload | grep successful | awk '{print $5}')

# update DB
$SQL -se "UPDATE tracks SET yt_url = 'https\:\/\/www\.youtube\.com\/watch?v=$YT_URL_CREATED' WHERE id = $ID;"
$SQL -se "UPDATE tracks SET yt_status = 2 WHERE id = $ID;"

# notification - upload
echo "New track processed: " > $TEMP_DIR/mail
echo "Local video: $VIDEO_PATH" >> $TEMP_DIR/mail
echo "Remote URL: https://www.youtube.com/watch?v=$YT_URL_CREATED" >> $TEMP_DIR/mail
mail $NOTIFY_MAIL -s "youtube-upload [$ID]" < $TEMP_DIR/mail

rm $LOCKFILE2