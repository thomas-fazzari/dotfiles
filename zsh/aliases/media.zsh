# Convert all FLAC files in current directory to Apple Lossless
flac2alac() {
  local files=(*.flac(N))
  local f=""

  if ! command -v ffmpeg >/dev/null 2>&1; then
    printf 'ffmpeg not found in PATH\n' >&2
    return 127
  fi

  if [[ "${#files[@]}" -eq 0 ]]; then
    printf 'No .flac files found in %s\n' "$PWD"
    return 0
  fi

  mkdir -p alac
  for f in "${files[@]}"; do
    ffmpeg -i "$f" -c:a alac -c:v copy "alac/${f%.flac}.m4a"
  done
}

alias 2alac='flac2alac'
