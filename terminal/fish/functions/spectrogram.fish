function spectrogram --description 'Generate a spectrogram next to the source file'
    set -l file $argv[1]

    if not command -q ffmpeg
        printf 'ffmpeg not found in PATH\n' >&2
        return 127
    end

    if not test -f "$file"
        printf 'Usage: spectrogram FILE\n' >&2
        return 2
    end

    set -l output (path change-extension '' -- $file)-spectrogram.png
    ffmpeg -hide_banner -loglevel error -n -i $file \
        -lavfi 'showspectrumpic=s=2048x1024:legend=1:color=intensity' \
        -frames:v 1 $output
    and printf 'Created %s\n' $output
end
