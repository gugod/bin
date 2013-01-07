#!/bin/sh

git tag --contains $(git log -1 --format=%h --author $(git config user.email))
