#!/bin/bash
# Script to check Proxmox storage replication
# ExitCode:
# 0 = Ok
# 1 = Warning
# 2 = Critical
# 4 = Ok (No replicatons configured)
#
# REF: https://forum.proxmox.com/threads/howto-monitoring-replication.41960/
#

EXITCODE=0

# Load job status to arrays
# Some error messages are multiline
# First line is aheader
i="-1"
JobID=()
Enabled=()
Target=()
LastSync=()
NextSync=()
Duration=()
FailCount=()
State=()
header=""
lines=()
while read line
do
    # if job number in the form of vmID-JobID
    if [[ "$line" =~ ^[0-9]+[-][0-9] ]]
    then
        ((i++))
        lines[$i]="$line"
        read JobID[$i] Enabled[$i] Target[$i] LastSync[$i] NextSync[$i] Duration[$i] FailCount[$i] State[$i] <<< "$line"

    # if not a job ID, but skip the first line, i = -1
    elif [ "$i" -ge 0  ]
    then
        State[$i]="${State[$i]}, ${line}"
        lines[$i]="${lines[$i]}, $line"
    else
        header="$line"
    fi
done <<< "$(/usr/bin/pvesr status)"

i="0"
for count in "${FailCount[@]}"
do
    #echo "${JobID[$i]} - \"${NextSync[$i]}\""
    if [ "$count" -gt 0 -a "$count" -lt 5 ] || [[ "${NextSync[$i]}" =~ ^[a-zA-Z]+ ]]
    then
        [ "$EXITCODE" -lt 1 ] && EXITCODE="1"
        [ -n "$header" ] && echo "$header" && header=""
        echo "${lines[$i]}"
    elif [ "$count" -gt 5 ]
    then
        [ -n "$header" ] && echo "$header" && header=""
        [ "$EXITCODE" -lt 2 ] && EXITCODE="2"
        echo "${lines[$i]}"
    fi
    ((i++))
done

if [ "${#FailCount[@]}" == 0 ]
then
    EXITCODE="4"
fi

if [ "$EXITCODE" -eq 2 ]
then
    echo "CRITICAL: Some replication jobs failed !"
elif [ "$EXITCODE" -eq 1 ]
then
    echo "WARNING: There is some errors with some replication jobs"
elif [ "$EXITCODE" -eq 4 ]
then
    echo "OK: No replication jobs configured"
elif [ "$EXITCODE" -eq 0 ]
then
    echo "OK: All replication jobs working as intented"
fi

exit "$EXITCODE"

