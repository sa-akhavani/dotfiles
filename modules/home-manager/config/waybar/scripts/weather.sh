#!/usr/bin/env bash

location1="Boston"
location2="Tehran"
error="Service Unavailable"

get_weather() {
    curl -s "https://wttr.in/$1?m&format=1"
}

get_tooltip() {
    curl -s "https://wttr.in/$1?m&format=%C+%c+%t+%f+%w+%m+%h"
}

format_tooltip() {
    local location="$1"
    local tooltip="$(get_tooltip "$location")"
    printf "%-15s %s\n" "$location:" "$tooltip"
}

for i in {1..5}; do
    text=$(get_weather "$location1")

    if [[ $? -eq 0 ]]; then
        tooltip1=$(format_tooltip "$location1")
        tooltip2=$(format_tooltip "$location2")

        if [[ $? -eq 0 ]]; then
            text=$(echo "$text" | sed -E "s/\s+/ /g")
            # In case weather website returns unknown location when it's down
            if [[ $text == *"Unknown"* ]]; then
              echo ""
            else
              tooltip="$tooltip1\n$tooltip2"
              echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
            fi
            exit
        fi
    fi

    sleep 2
done

echo "{\"text\":\"$error\", \"tooltip\":\"$error\"}"
