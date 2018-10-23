#!/bin/sh

curl --silent 'https://mirror.leaseweb.com/CPAN/modules/01modules.mtime.rss' | ack --output '$1' '<link>(.+?[^/]+)</link>' | headskip -1 | cut -c 48-
