#!/bin/bash

// this should be set to 2500-4000k to achieve Full HD 1920x1080
VBR="1500k"
FPS="30"
QUAL="ultrafast"
YOUTUBE_URL="rtmp://a.rtmp.youtube.com/live2"
KEY="******************"
VIDEO_SOURCE="/mnt/streaming/youtube/video.mp4"
AUDIO_SOURCE="http://radio.freeundergroundtekno.org/radio/8000/radio.mp3"
// file created by nowplaying.php script
NP_SOURCE="/mnt/streaming/youtube/nowplaying.txt"

ffmpeg \
    -re -f lavfi -i "movie=filename=$VIDEO_SOURCE:loop=0, setpts=N/(FRAME_RATE*TB)" \
    -thread_queue_size 512 -i "$AUDIO_SOURCE" \
    -map 0:v:0 -map 1:a:0 \
    -map_metadata:g 1:g \
    -vf drawtext="fontfile=/home/ubuntu/unifont.ttf: fontsize=55: \
     box=0: boxcolor=black@0.5: boxborderw=20: \
     textfile=$NP_SOURCE: reload=1: fontcolor=white@0.8: x=315: y=960" \
    -vcodec libx264 -pix_fmt yuv420p -preset $QUAL -r $FPS -g $(($FPS * 2)) -b:v $VBR \
    -acodec libmp3lame -ar 44100 -threads 6 -qscale:v 3 -b:a 320000 -bufsize 512k \
    -f flv "$YOUTUBE_URL/$KEY"
