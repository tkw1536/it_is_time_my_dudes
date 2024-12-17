#!/bin/bash
set -e

# word to put in!
WORD="$1"

# input file with original vine
ORIGINAL="/original.mp4"

# create a temporary direvtory
TEMPDIR=$(mktemp -d)
trap 'rm -rf -- "$TEMPDIR"' EXIT

ENCODING_FLAGS="-c:v libx264 -c:a aac"  # encoding for the final video

IT_IS_LENGTH="00:00:00.45"              # length of the 'It Is' Phrase
WEDNESDAY_LENGTH="00:00:00.60"          # length of the 'wednesday' word
IT_IS_WEDNESDAY_LENGTH="00:00:01.05"    # length of the previous two combined
WORD_SILENCE_TRIM="0"                 # number of seconds to trim from espeak output

(
    # split the original clip into different parts
    ffmpeg -y -i "$ORIGINAL" -t "$IT_IS_LENGTH" $ENCODING_FLAGS "$TEMPDIR/00_it_is.mp4"
    ffmpeg -y -i "$ORIGINAL" -ss "$IT_IS_LENGTH" -t "$WEDNESDAY_LENGTH" $ENCODING_FLAGS "$TEMPDIR/01_wednesday.mp4"
    ffmpeg -y -i "$ORIGINAL" -ss "$IT_IS_WEDNESDAY_LENGTH" $ENCODING_FLAGS "$TEMPDIR/02_my_dudes.mp4"

    # generate the new word
    echo "$WORD" | espeak --stdout | ffmpeg -y -i - -ar 44100 -ac 2 -ab 192k -f mp3 "$TEMPDIR/word_loud.mp3"

    # remove half a second from it
    ffmpeg -y -i "$TEMPDIR/word_loud.mp3" -t $(echo "$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMPDIR/word_loud.mp3") - $WORD_SILENCE_TRIM" | bc | awk '{printf "%f", $0}' ) -c copy "$TEMPDIR/word.mp3"


    # compute length of 'wednesday' and 'word' files, and their ratio
    VIDEO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMPDIR/01_wednesday.mp4")
    AUDIO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$TEMPDIR/word.mp3")
    FACTOR=$(echo "$AUDIO_DURATION / $VIDEO_DURATION" | bc -l)

    # replace the audio of the wednesday clip with the word
    ffmpeg -y -i "$TEMPDIR/01_wednesday.mp4" -i "$TEMPDIR/word.mp3" -filter_complex "[0:v]setpts=$FACTOR*PTS[v];[1:a]anull[a]" -map "[v]" -map "[a]"  $ENCODING_FLAGS "$TEMPDIR/01_word.mp4"

    # and put them all back together
    ffmpeg -y -f concat -safe 0 -i <(cat <<EOF
    file '$TEMPDIR/00_it_is.mp4'
    file '$TEMPDIR/01_word.mp4'
    file '$TEMPDIR/02_my_dudes.mp4'
EOF
    ) $ENCODING_FLAGS "$TEMPDIR/final.mp4"
) 1>&2
cat "$TEMPDIR/final.mp4"