#!/bin/sh

CONNECTED_MONITOR=$(xrandr | grep " connected" | head -n 1 | cut -d " " -f 1)

if [ ! -z "$CONNECTED_MONITOR" ]; then
  xrandr --output "$CONNECTED_MONITOR" --primary --auto
fi

openbox-session &

exec emulationstation
