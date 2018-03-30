#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    map.set PARAMS[testName][name] "test"
    map.set PARAMS[testName][description] "run single test"
    map.set PARAMS[testName][required] "false"
}

# Input variables
#   ARGS | map | arguments values
run() {
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

    if false; then
        map.set ala[ma][kota] "to nie prawda"
        declare -p | grep ala
    fi

    if true; then
        map.set ala[ma][kota] "to nie prawda"
        map.set ala[ma][psa] "pieska"
        map.set ala[dzieci][marta] "7 lat"

        get_and_print() {
            require "$1"
            statement="$1"
            map.get "$1"

            case "$?" in
            0)
                echo "${statement}='${RETURN_VALUE}'. Return code: 0"
                ;;
            1)
                echo "${statement}=Array. Return code: 1"
                for key in "${RETURN_VALUE[@]}"; do
                    echo "key: '${key}'"
                done
                ;;
            2)
                echo "${statement} NOT DEFINED. Return code: 2. RETURN_VALUE=${RETURN_VALUE}"
                ;;
            esac
            echo
        }

        get_and_print ala[ma][psa]
        get_and_print ala[ma][kota]
        get_and_print ala[dzieci][marta]
        get_and_print ala[dzieci][krzysiek]
        #keys
        get_and_print ala[ma]
        get_and_print ala
        get_and_print maciek


    fi
}