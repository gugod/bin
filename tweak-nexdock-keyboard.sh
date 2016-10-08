#!/bin/bash

kbid=$(xinput -list | grep -i 'NexDock Keyboard' | grep -o 'id=[0-9]' | grep -o '[0-9]')
if [[ "$kbid" ]]
then
    setxkbmap -device $kbid -option altwin:swap_alt_win,ctrl:nocaps
fi

cat <<EOMODMAP | xmodmap -
keycode  51 = Alt_R Meta_R Alt_R Meta_R
keycode 119 = backslash bar backslash bar
EOMODMAP

