# Convert all .flac files in current directory to Apple Lossless
flac2alac() {
	local files=(*.flac(N))
	local f=""
	local output=""
	local -i converted=0
	local -i skipped=0
	local -i failed=0

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
		output="alac/${f%.flac}.m4a"
		if [[ -e "$output" ]]; then
			printf 'Skipped existing %s\n' "$output"
			((++skipped))
			continue
		fi

		if ffmpeg -hide_banner -loglevel error -nostdin -n -i "$f" \
			-map 0:a:0 -map '0:v?' -map_metadata 0 \
			-c:a alac -c:v copy "$output"; then
			printf 'Created %s\n' "$output"
			((++converted))
		else
			rm -f -- "$output"
			printf 'Failed %s\n' "$f" >&2
			((++failed))
		fi
	done

	printf 'Converted: %d, skipped: %d, failed: %d\n' \
		"$converted" "$skipped" "$failed"
	((failed == 0))
}

# Show main audio stream properties
audioinfo() {
	local file="${1:-}"

	if ! command -v ffprobe >/dev/null 2>&1; then
		printf 'ffprobe not found in PATH\n' >&2
		return 127
	fi

	if [[ ! -f "$file" ]]; then
		printf 'Usage: audioinfo FILE\n' >&2
		return 2
	fi

	ffprobe -v error -select_streams a:0 \
		-show_entries 'format=filename,duration,size,bit_rate:stream=codec_name,profile,sample_rate,channels,channel_layout,bits_per_sample,bits_per_raw_sample' \
		-of default=noprint_wrappers=1 "$file"
}

# Generate a spectrogram next to the source file
spectrogram() {
	local file="${1:-}"
	local output="${file:r}-spectrogram.png"

	if ! command -v ffmpeg >/dev/null 2>&1; then
		printf 'ffmpeg not found in PATH\n' >&2
		return 127
	fi

	if [[ ! -f "$file" ]]; then
		printf 'Usage: spectrogram FILE\n' >&2
		return 2
	fi

	ffmpeg -hide_banner -loglevel error -n -i "$file" \
		-lavfi 'showspectrumpic=s=2048x1024:legend=1:color=intensity' \
		-frames:v 1 "$output" && printf 'Created %s\n' "$output"
}

# Measure loudness and true peak
loudness() {
	local file="${1:-}"

	if ! command -v ffmpeg >/dev/null 2>&1; then
		printf 'ffmpeg not found in PATH\n' >&2
		return 127
	fi

	if [[ ! -f "$file" ]]; then
		printf 'Usage: loudness FILE\n' >&2
		return 2
	fi

	ffmpeg -hide_banner -nostats -i "$file" \
		-filter_complex 'ebur128=peak=true:framelog=verbose' -f null - 2>&1 |
		awk '/Summary:/{show=1} show && !done {print} show && /Peak:/{done=1}'
	return "$pipestatus[1]"
}
