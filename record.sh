#!/bin/bash

# Produces a video that most devices will reconigze. Generates a video from the
# top-left of the screen spanning 800x600 pixels. The final video's file name
# is the current unix timestamp.

./love2d.AppImage . &
ffmpeg -f x11grab \
       -video_size 800x600 \
       -i :0.0 \
       -c:v libx264 -crf 23 -profile:v baseline -level 3.0 -pix_fmt yuv420p \
       -c:a aac -ac 2 -b:a 128k \
       -movflags faststart \
       $(date +%s%3N).mp4
