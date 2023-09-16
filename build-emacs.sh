#!/bin/sh

NCPU=$(grep processor /proc/cpuinfo | wc -l)

cd ~/src/emacs

./autogen.sh &&
    ./configure --prefix ~/.local/apps/emacs-$(git describe) &&
    make -j$NCPU &&
    make install
