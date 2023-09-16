#!/bin/bash

snap=$(mktemp /tmp/qrscan.XXXXXXXXXX || exit 1)

echo "Camera shot in 3 second"

imagesnap -w 3 $snap &&
    echo &&
    zbarimg --raw -q -1 $snap | pbcopy

status=$?

if [[ $status -eq 0 ]]; then
    echo Copied
else
    echo Failed
fi

echo
rm $snap

exit $status
