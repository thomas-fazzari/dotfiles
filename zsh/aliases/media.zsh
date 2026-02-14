# Convert all FLAC files in current directory to Apple Lossless
2alac() {
  mkdir -p alac && for f in *.flac; do
    ffmpeg -i "$f" -c:a alac -c:v copy "alac/${f%.flac}.m4a"
  done
}
