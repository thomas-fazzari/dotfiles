#!/bin/sh
set -u
cache="${TMPDIR:-/tmp/}stablebar-now-playing"
# Browsers can send a track's artwork a few seconds after its title.
artwork_tries=10

case "${1:-}" in
  seek | skip)
    media-control get --now --no-artwork |
      jq -r --arg mode "$1" --arg n "$2" '
        ($n | sub(","; ".") | tonumber) as $n
        | (.duration // 0) as $duration
        | if $mode == "seek" then $n * $duration
          elif .elapsedTimeNow == null then empty
          else .elapsedTimeNow + $n end
        | [., 0] | max
        | if $duration > 0 then [., $duration] | min else . end
        | . * 100 | round / 100' |
      xargs media-control seek
    exit
    ;;
esac

now=$(media-control get --now --no-artwork)
if [ -z "$now" ] || [ "$now" = null ] || [ "$(printf '%s' "$now" | jq -r '.title // ""')" = "" ]; then
  echo '{"text":"","hidden":true,"interval":5}'
  exit
fi
mkdir -p "$cache"

# A browser's media plays in a helper process: name and open the browser instead.
{
  read -r bundle
  read -r track
} <<EOF
$(printf '%s' "$now" | jq -r '.parentApplicationBundleIdentifier // .bundleIdentifier // "", ([.title, .artist, .album] | @json)')
EOF
app=""
if [ -n "$bundle" ]; then
  [ -e "$cache/$bundle.path" ] || mdfind "kMDItemCFBundleIdentifier == '$bundle'" | head -1 >"$cache/$bundle.path"
  app=$(cat "$cache/$bundle.path")
fi

# One file per track, so StableBar reloads the image only when the track changes.
key=$(printf '%s' "$track" | md5 -q)
artwork="$cache/$key.jpg"
tries="$cache/$key.tries"
if [ ! -s "$artwork" ] && [ "$(wc -c <"$tries" 2>/dev/null || echo 0)" -lt "$artwork_tries" ]; then
  [ -e "$tries" ] || find "$cache" \( -name '*.jpg' -o -name '*.tries' \) -delete
  printf . >>"$tries"
  media-control get | jq -r '.artworkData // empty' | base64 -d >"$artwork.tmp"
  if [ -s "$artwork.tmp" ]; then mv "$artwork.tmp" "$artwork"; else rm -f "$artwork.tmp"; fi
fi
[ -s "$artwork" ] || artwork=$app

printf '%s' "$now" | jq -c --arg app "$app" --arg bundle "$bundle" --arg artwork "$artwork" '
  def pad: tostring | if length < 2 then "0" + . else . end;
  def clock: floor as $s
    | if $s >= 3600 then "\($s / 3600 | floor):\($s % 3600 / 60 | floor | pad):\($s % 60 | pad)"
      else "\($s / 60 | floor):\($s % 60 | pad)" end;
  (.duration // 0) as $duration
  | ([.elapsedTimeNow // 0, $duration] | min) as $elapsed
  | {
      text: .title,
      interval: (if .playing then 1 else 5 end),
      fields: {
        title,
        artist: (.artist // ""),
        album: (.album // ""),
        control: (if .playing then "pause.fill" else "play.fill" end),
        playing: (if .playing then "1" else "" end),
        paused: (if .playing then "" else "1" end),
        source: (if $app == "" then $bundle else $app | split("/") | last | rtrimstr(".app") end),
        app: $bundle,
        appIcon: $app,
        artwork: $artwork,
        elapsed: (if $duration > 0 then $elapsed | clock else "" end),
        duration: (if $duration > 0 then $duration | clock else "" end)
      },
      values: (if $duration > 0 then { progress: ($elapsed / $duration) } else {} end)
    }'
