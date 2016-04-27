#!/bin/zsh

input_videofile="$1"
x=$(basename $input_videofile)
input_videofile_ext=${x##*.}
input_videofile_noext=$(basename $x .$input_videofile_ext)
output_videofile="${input_videofile_noext}.stablized.${input_videofile_ext}"

ffmpeg -i "$input_videofile" -vf vidstabdetect -f null -
ffmpeg -i "$input_videofile" -vf vidstabtransform $output_videofile
