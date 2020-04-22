#!/bin/bash

# Cut video input $1 starting at time $2 and going until time #3
ffmpeg -i $1 -ss $2 -to $3 cut.mp4
