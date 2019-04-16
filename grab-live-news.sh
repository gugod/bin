#!/bin/bash

duration=${1:-00:03:00}

sources=(
    ctitv 'https://www.youtube.com/watch?v=wUPPkSANpyo'
    ctv   'https://www.youtube.com/watch?v=DVOHYy_m_qU'
    ebc   'https://www.youtube.com/watch?v=dxpWqjvEKaM'
    ftv   'https://www.youtube.com/watch?v=XxJKnDLYZz4'
    setn  'https://www.youtube.com/watch?v=4ZVUmEUFwaY'
    ttv   'https://www.youtube.com/watch?v=yk2CUjbyyQY'
    tvbs  'https://www.youtube.com/watch?v=Hu1FkdAOws0'
)

now=$(date +%Y%m%d%H%M%S)
for (( i=0; i<${#sources[@]} ; i+=2 ))
do
    mkdir -p "${sources[$i]}"
    streamlink "${sources[$i+1]}" 240p --hls-duration "$duration" -o "${sources[$i]}/$now.mp4" &
done

wait
