#!/bin/bash


INPUT_VIDEO=output.mp4
MAX_RATE=4000k
PRESET=veryfast
AUDIO_BITRATE=128k
FACEBOOK_STREAM_KEY=abcd

fmpeg -re -y \
-i $INPUT_VIDEO -c:a copy -ac 1 -ar 44100 -b:a $AUDIO_BITRATE -vcodec libx264 \
-pix_fmt yuv420p -vf scale=1080:-1 -r 30 -g 60 -tune zerolatency 
-f flv -maxrate $MAX_RATE -preset $PRESET \
"rtmps://live-api-s.facebook.com:443/rtmp/$FACEBOOK_STREAM_KEY"