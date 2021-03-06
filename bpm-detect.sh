#!/bin/bash


# set env
TEMP_DIR="tmp"
VIDEO_STORAGE=/mnt/free-tekno.com/storage
mkdir -p $TEMP_DIR
mkdir -p $VIDEO_STORAGE

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

# convert audio to video (ffmpeg waveforms recipe) and save mp4 file to storage
ffmpeg -i /var/www/free-tekno.com/public/$URL -filter_complex "[0:a]showwaves=s=1280x720:mode=line:rate=25,format=yuv420p[v]" -map "[v]" -map 0:a $VIDEO_STORAGE/$REAL_ID.mp4
$SQL -se "UPDATE tracks SET yt_status = 1 WHERE id = $ID;"

# prepare for YouTube
TRACK_NAME=$($SQL -se "SELECT name FROM tracks WHERE id = $ID;")
TRACK_ARTIST=$($SQL -se "SELECT first_name, last_name FROM users WHERE id = $OWNER_ID;")

echo "Join and download $TRACK_NAME by $TRACK_ARTIST for free on https://free-tekno.com\nSend your music: https://t.me/joinchat/pulxr-bv87szMTA0\n24/7 free tekno radio, streaming and rave culture: https://www.freeundergroundtekno.org" > $TEMP_DIR/video_description

DESCRIPTION=$(cat $TEMP_DIR/video_description)

# upload to YouTube
youtubeuploader_linux_amd64 -categoryId 10 -title "$TRACK_NAME by $TRACK_ARTIST" -description "$DESCRIPTION" -tags "tekno,freetekno,free-tekno.com,free underground tekno radio,taz,teknival,$TRACK_NAME,$TRACK_ARTIST,rave,free party,dj,mix,liveset" -thumbnail "https://free-tekno.com/$IMAGE"  -filename $VIDEO_STORAGE/$REAL_ID.mp4 > $TEMP_DIR/temp_upload

# retrieve YouTube video ID
YT_URL_CREATED=$(cat $TEMP_DIR/temp_upload | grep successful | awk '{print $5}')

# update DB
$SQL -se "UPDATE tracks SET yt_status = 2 WHERE id = $ID;"
$SQL -se "UPDATE tracks SET yt_url = 'https\:\/\/www\.youtube\.com\/watch?v=$YT_URL_CREATED' WHERE id = $ID;"
$SQL -se "UPDATE tracks SET yt_status = 3 WHERE id = $ID;"

# notification - upload
echo "New track uploaded to YouTube:\n" > $TEMP_DIR/mail
echo "FT URL: https://free-tekno.com/public/$URL\n" >> $TEMP_DIR/mail
echo "YT URL: https://www.youtube.com/watch?v=$YT_URL_CREATED" >> $TEMP_DIR/mail
mail fabrizio.salmi@gmail.com -s "youtube-upload [$ID]" < $TEMP_DIR/mail
