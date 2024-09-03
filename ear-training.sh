#!/bin/bash -e
# ear-training.sh by defanor, 2024-09-03, MIT license

# Using bash for "read -n"

# Using "-t alsa" for play(1):
# https://github.com/floere/playa/issues/6#issuecomment-450951731
# https://groups.google.com/g/linux.debian.bugs.dist/c/jCqdwFWPUKk

# Common settings
TYPE=pluck

# For scale degrees
SCALE=('C' 'D' 'E' 'F' 'G' 'A' 'B')
DEGREES_NUM=4 # ${#SCALE[@]}
OCTAVE_START=3
OCTAVE_COUNT=3
DEGREE=
OCTAVE=

# For intervals, values relative to middle A (A4, 440 Hz)
INTERVALS=(4 7 12)
INTERVAL_LOWER_MIN=-21 # C3
INTERVAL_LOWER_MAX=3 # C5
INTERVAL_LOWER=
INTERVAL=


# I-IV-V-I
cadence() {
    play -q -n -t alsa synth \
         $TYPE "${SCALE[0]}4" $TYPE "${SCALE[2]}4" $TYPE "${SCALE[4]}4" \
         $TYPE "${SCALE[3]}4" $TYPE "${SCALE[5]}4" $TYPE "${SCALE[0]}5" \
         $TYPE "${SCALE[4]}4" $TYPE "${SCALE[6]}4" $TYPE "${SCALE[1]}5" \
         $TYPE "${SCALE[0]}4" $TYPE "${SCALE[2]}4" $TYPE "${SCALE[4]}4" \
         fade 0 0.6 0.1 \
         remix 1-3 4-6 7-9 10-12 \
         delay 0 0.5 1 1.5 \
         remix - \
         norm -1
}

play_note() {
    play -q -n -t alsa synth $TYPE "${SCALE[$DEGREE]}$OCTAVE" \
         fade 0 0.6 0.1 norm -1
}

next_note() {
    DEGREE=$((1 + RANDOM % DEGREES_NUM))
    OCTAVE=$((OCTAVE_START + RANDOM % OCTAVE_COUNT))
    cadence
    sleep 0.5
    play_note
}

play_interval() {
    play -q -n -t alsa synth \
         $TYPE "%$INTERVAL_LOWER" \
         $TYPE "%$((INTERVAL_LOWER + INTERVAL))" \
         $TYPE "%$INTERVAL_LOWER" \
         $TYPE "%$((INTERVAL_LOWER + INTERVAL))" \
         fade 0 0.6 0.1 \
         remix 1 2 3-4 \
         delay 0 0.5 1.2 \
         remix - \
         norm -1
}

next_interval() {
    INTERVAL_LOWER=$((INTERVAL_LOWER_MIN + RANDOM %
                      (INTERVAL_LOWER_MAX - INTERVAL_LOWER_MIN)))
    INTERVAL=${INTERVALS[$((RANDOM % ${#INTERVALS[@]}))]}
    play_interval
}

down_to_tonic() {
    while [ $DEGREE -gt 0 ]; do
        play_note
        ((DEGREE--))
    done
}

scale_degrees() {
    next_note
    while read -r -n 1 GUESS
    do
        if [ "$GUESS" == "q" ]; then
            break
        elif [ "$GUESS" == "r" ]; then
            play_note
        elif [ "$GUESS" == "c" ]; then
            cadence
            sleep 0.5
            play_note
        elif [ "$GUESS" == $DEGREE ]; then
            echo " correct"
            down_to_tonic
            sleep 1
            next_note
        else
            echo " incorrect"
        fi
    done
}

intervals() {
    next_interval
    while read -r GUESS
    do
        if [ "$GUESS" == "q" ]; then
            break
        elif [ "$GUESS" == "r" ]; then
            play_interval
        elif [ "$GUESS" == "$INTERVAL" ]; then
            echo "correct"
            next_interval
        else
            echo "incorrect"
        fi
    done
}

case "$1" in
    *int*) intervals ;;
    *sd*) scale_degrees ;;
    *) echo "Arguments: 'int' for intervals, 'sd' for scale degrees"
esac
