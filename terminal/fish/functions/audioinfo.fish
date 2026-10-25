function audioinfo --description 'Show main audio stream properties'
    set -l file $argv[1]

    if not command -q ffprobe
        printf 'ffprobe not found in PATH\n' >&2
        return 127
    end

    if not test -f "$file"
        printf 'Usage: audioinfo FILE\n' >&2
        return 2
    end

    ffprobe -v error -select_streams a:0 \
        -show_entries 'format=filename,duration,size,bit_rate:stream=codec_name,profile,sample_rate,channels,channel_layout,bits_per_sample,bits_per_raw_sample' \
        -of default=noprint_wrappers=1 $file
end
