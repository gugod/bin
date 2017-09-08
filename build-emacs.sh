#!/bin/sh

NCPU=$(grep processor /proc/cpuinfo | wc -l)

cd ~/src/emacs

./autogen.sh &&
    ./configure --prefix ~/apps/emacs-$(git describe --tags) &&
    make -j$NCPU &&
    make install
