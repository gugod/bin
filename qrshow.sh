#!/bin/sh

function qrshow_pasteboard() {
    pbpaste | qrencode -o - | mpv - --pause --geometry=512x512
}

function qrshow() {
    local text=$1
    echo "$text" | qrencode -o - | mpv - --pause --geometry=512x512
}

text=$1

if [[ -z $text ]]; then
    qrshow_pasteboard
else
    qrshow $text
fi
