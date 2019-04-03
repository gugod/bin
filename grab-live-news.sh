#!/bin/bash

cd $(dirname $0)

duration=${1:-00:03:00}

sources=(
    setn  'https://www.youtube.com/watch?v=4ZVUmEUFwaY'
    tvbs  'https://www.youtube.com/watch?v=Hu1FkdAOws0'
    ctitv 'https://www.youtube.com/watch?v=wUPPkSANpyo'
    ttv   'https://www.youtube.com/watch?v=yk2CUjbyyQY'
    ebc   'https://www.youtube.com/watch?v=dxpWqjvEKaM'
    ctv   'https://www.youtube.com/watch?v=DVOHYy_m_qU'
)

now=$(date +%Y%m%d%H%M%S)
for (( i=0; i<${#sources[@]} ; i+=2 ))
do
    mkdir -p "${sources[$i]}"
    streamlink "${sources[$i+1]}" 240p --hls-duration "$duration" -o "${sources[$i]}/$now.mp4" &
done

wait
