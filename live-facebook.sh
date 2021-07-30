#!/bin/bash
VBR="3000k"
FPS="30"
QUAL="ultrafast"
STREAM_URL="rtmps://live-api-s.facebook.com:443/rtmp/" # Facebook live endpoint
STREAM_KEY="$(cat .stream_key_facebook)" # use a permanent stream key here 
VIDEO_SOURCE="$(cat .storage)/video.mp4" # local video file
AUDIO_SOURCE="http://radio.freeundergroundtekno.org/radio/8000/radio.mp3" # mp3 radio stream url
NP_SOURCE="$(cat .storage)/nowplaying.txt" # now playing data

while :
do

ffmpeg \
    -re -f lavfi -i "movie=filename=$VIDEO_SOURCE:loop=0, setpts=N/(FRAME_RATE*TB)" \
    -thread_queue_size 512 -i "$AUDIO_SOURCE" \
    -map 0:v:0 -map 1:a:0 \
    -map_metadata:g 1:g \
    -vf drawtext="fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf: fontsize=25: \
     box=0: boxcolor=black@0.5: boxborderw=20: \
     textfile=$NP_SOURCE: reload=1: fontcolor=white@0.8: x=50: y=th" \
    -vcodec libx264 -pix_fmt yuv420p -preset $QUAL -r $FPS -g $(($FPS * 2)) -b:v $VBR \
    -c:a aac -b:a 128k -ac 2 -ar 44100 -bufsize 4096k \
    -f flv "$STREAM_URL/$STREAM_KEY"

done
