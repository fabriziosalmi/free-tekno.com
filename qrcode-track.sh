#!/bin/bash

STORAGE="/mnt/free-tekno.com/storage"
API_URL="https://api.qrserver.com/v1/create-qr-code/?size=512x512&data=$1"
IMAGE_HASH=$(echo -n "$1" | md5sum | cut -d " " -f 1)
wget $API_URL -O "$STORAGE/$IMAGE_HASH.png"