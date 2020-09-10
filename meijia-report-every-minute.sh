#!/bin/bash

say -v Mei-Jia "5, 4, 3, 2, 1";

say -v Mei-Jia "開始" &
echo 開始

n=1
while true
do
    message="$n 分鐘"
    sleep 60 && (
        say -v Mei-Jia $message &
        echo $(date) $message   &
    )
    n=$((n+1))
done
