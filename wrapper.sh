#!/bin/bash
until coffee reddittwitbot.coffee; do
    echo "'reddittwitbot' crashed with exit code $?. Restarting..." >&2
    sleep 1
done