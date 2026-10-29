function audioinfo --description 'Show main audio stream properties'
    ffprobe -v error -select_streams a:0 \
        -show_entries 'format=filename,duration,size,bit_rate:stream=codec_name,profile,sample_rate,channels,channel_layout,bits_per_sample,bits_per_raw_sample' \
        -of default=noprint_wrappers=1 $argv[1]
end
