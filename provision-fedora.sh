#!/bin/bash

dnf install -y ripgrep perl-Try-Tiny perlbrew perl-File-Copy perl-JSON msmtp kubectl fossil mozilla-openh264 openh264 maildir-utils isync lm_sensors ibm-plex-mono-fonts yt-dlp zsh pass ibus-mozc syncthing emacs ibus-rime openssl openssl-dev zopfli libdeflate zlib-devel git-annex git-annex-docs
dnf remove -y ibus-libzhuyin
