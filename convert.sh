#!/bin/bash

ffmpeg -i $1 \
       -video_size 1080x1350 \
       -c:v libx264 -preset medium -crf 23 -profile:v baseline -level 3.0 -pix_fmt yuv420p \
       -c:a aac -ac 2 -b:a 128k \
       -movflags faststart \
       $(date +%s%3N).mp4
