#!/bin/bash

source "$(/usr/bin/dirname "$0")/functions.sh"

# warn if fan percent is thi value or higher
temp_warn="45"
#temp_warn="25"
card="nvme-pci-0400"

main()
{
    local val
    local scale
    local warn="no"
    local EV="0"

    temp="$(sensors -Aj $card 2>/dev/null | jq '.[][] | to_entries[] | select(.key | endswith("input")) | .value' | sort | tail -n1)"

    if [ -z "$temp" ]
    then
        err "$card: unable to read temperature"
        EV="1"

    elif [ "$(echo "$temp > $temp_warn" | bc -q)" == 1 ]
    then
        err "$card: temperature higher than $temp_warn: $temp"
        EV="2"

    else
        info "$card: ok: $temp"
    fi

    err_print
    return $EV
}

main "$@"

