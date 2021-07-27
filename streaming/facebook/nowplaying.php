<?php
// run every minute via crontab
$url = "https://radio.freeundergroundtekno.org/api/nowplaying/free_underground_tekno";
$data = file_get_contents($url);
$data = json_decode($data);
$title= $data->now_playing->song->title;
// this file will be processed by ffmpeg
$file = "/mnt/streaming/facebook/nowplaying.txt";
file_put_contents($file, $title);
?>
