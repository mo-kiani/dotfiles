#!/bin/sh

pinentry_program="/mnt/c/Program Files (x86)/Gpg4win/bin/pinentry.exe"
if [ "$PINENTRY_USER_DATA" = "TERMINAL" ]; then
    pinentry_program="/usr/bin/pinentry"
fi

exec "$pinentry_program" "$@"
