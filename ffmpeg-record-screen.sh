#!/bin/bash

ffmpeg -y -f avfoundation -framerate 30 -video_size 1366x768 -i 1:0 -preset ultrafast -r 30 screen-$(date +%Y%m%d%H%M%S).mp4

