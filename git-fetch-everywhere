#!/bin/sh

for base in $*
do
        find $base -depth 2 -name .git -type d  | parallel  'cd $(dirname {}); git fetch -a'
done
