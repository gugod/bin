#!/bin/sh

remote=$1

ssh -f -L 5900:localhost:5900 $remote 'x11vnc -localhost -ncache 20 -display :1'
sleep 3
exec ssvncviewer -compresslevel 9 -quality 3 -16bpp -x11cursor -pipeline -encoding zywrle localhost:5900 

