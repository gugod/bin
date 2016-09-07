#!/bin/bash

offlineimap

for f in ~/Maildir/INBOX/new/*
do
         spamc -c < $f
         is_spam=$?
         if [[ $is_spam -eq 1 ]]; then
             mv $f ~/Maildir/Junk/cur
         else
             mv $f ~/Maildir/INBOX/cur
         fi
done

offlineimap &

notmuch new
notmuch tag --batch --input=$HOME/etc/notmuch-initial-tags

wait
