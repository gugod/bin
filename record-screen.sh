#!/bin/sh

avconv -f x11grab -r 25 -s 1280x800 -i :0.0+0,0 -pre lossless_ultrafast -threads 0 screen.mkv

