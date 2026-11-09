#!/bin/sh
pkill -f 'MediaRemoteAdapterTestClient stream'
media-control stream --no-artwork --debounce=250 | while read -r _; do
  sketchybar --trigger now_playing_change
done
