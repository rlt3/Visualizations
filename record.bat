START /B love.exe .
ffmpeg -f gdigrab^
       -framerate 30^
       -offset_x 0^
       -offset_y 0^
       -video_size 1280x720^
       -show_region 1^
       -i desktop^
       -c:v libx264 -preset medium -crf 23 -profile:v baseline -level 3.0 -pix_fmt yuv420p^
       -c:a aac -ac 2 -b:a 128k^
       -movflags faststart^
       -y^
       test.mp4

