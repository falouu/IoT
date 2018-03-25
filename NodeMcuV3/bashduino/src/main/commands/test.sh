#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

if false; then
    rrr=( "a" "bb" "cc c" )
    join_by "--" "${rrr[@]}"
    echo "${RETURN_VALUE}"

    empty=()
    join_by "--" "${empty[@]}"
    echo "${RETURN_VALUE}"

    join_by "" "${rrr[@]}"
    echo "${RETURN_VALUE}"
fi

# # map tests
if false; then
    map._get_segments "dup[bip_][zip]"

    #trap 'echo pupa' ${ERROR_CODES["GENERAL/SYNTAX_ERROR"]}

    exit() {
      echo exit
    }
    test_map_segments() {
        local statement="$1"
        echo "Testing statement: ${statement}"

        map._get_segments "${statement}"

        for segment in "${RETURN_VALUE[@]}"; do
            echo "segment: '${segment}'"
        done

        echo "----"
    }

    test_map_segments "dup[bip_][zip]"
    test_map_segments "dup"
    test_map_segments "dup[][zip]"
    test_map_segments "dup[[]][zip]"
    test_map_segments "dup[ala ma kota][zip]"

fi

if false; then
    str="babcia][kapcia][one two three"
    #str="babka][ddd ddd ddd         dddd"
    split_by "][" "${str}"
    for segment in "${RETURN_VALUE[@]}"; do
        echo "Segment: '${segment}'"
    done
fi

if true; then
    map.set ala[ma][kota] "to nie prawda"
    declare -p | grep ala
fi