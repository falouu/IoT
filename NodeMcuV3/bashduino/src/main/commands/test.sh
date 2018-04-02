#!/usr/bin/env bash
# DO NOT CALL THIS FILE DIRECTLY!
# call run.sh in repository root instead!

# Output variables:
#   PARAMS | map | define params for command
setup() {
    map.set PARAMS[testName][name] "test"
    map.set PARAMS[testName][description] "run single test"
    map.set PARAMS[testName][required] "false"
    map.set PARAMS[testName][valuePlaceholder] "test name"
    map.set PARAMS[testName][defaultDescription] "run all tests"

    map.set PARAMS[list][name] "list"
    map.set PARAMS[list][description] "list all test names"
    map.set PARAMS[list][required] "false"
}

# Input variables
#   ARGS | map | arguments values
run() {
    run_tests() {
        test_functions=()
        pattern="^[[:space:]]*declare[[:space:]]+-f[[:space:]]+([a-zA-Z0-9_]+)$"
        while read -r line; do
            [[ "${line}" =~ $pattern ]] || continue
            local function_name="${BASH_REMATCH[1]}"
            [[ "${function_name}" == test_* ]] || continue
            test_functions+=( "${function_name}" )

        done <<< "$(declare -F)"

        local test_name="${ARGS[testName]}"
        local is_list_command="${ARGS[list]}"

        if [[ "${is_list_command}" == "true" ]]; then
            printf "All tests:\n"
            for test_function in "${test_functions[@]}"; do
                printf "  ${test_function#test_}\n"
            done
            return
        fi

        if [[ "${test_name}" ]]; then
            if containsElement "test_${test_name}" "${test_functions[@]}"; then
                printf "\n"
                log "Running test: '${test_name}'"
                printf "\n"
                "test_${test_name}"
            else
                die "test '${test_name}' not found!" "TEST/TEST_NOT_FOUND"
            fi
        else
            for test_function in "${test_functions[@]}"; do
                printf "\n"
                log "Running test: '${test_function#test_}'"
                printf "\n"
                "${test_function}"
            done
        fi

#        for test_function in "${test_functions[@]}"; do
#            debug "Found test: '${test_function}'"
#        done
    }


    test_basics() {
        rrr=( "a" "bb" "cc c" )
        join_by "--" "${rrr[@]}"
        echo "${RETURN_VALUE}"

        empty=()
        join_by "--" "${empty[@]}"
        echo "${RETURN_VALUE}"

        join_by "" "${rrr[@]}"
        echo "${RETURN_VALUE}"
    }

    test_map_segments() {
    # # map tests
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
    }

    test_split_by() {

        str="babcia][kapcia][one two three"
        #str="babka][ddd ddd ddd         dddd"
        split_by "][" "${str}"
        for segment in "${RETURN_VALUE[@]}"; do
            echo "Segment: '${segment}'"
        done
    }

    test_map_get_set() {
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
        get_and_print ala[rodzice][tata]
        #keys
        get_and_print ala[ma]
        get_and_print ala
        get_and_print maciek
    }

    test_map_unset() {
        map.set koty[liza][maslo] "czy koty liżą masło?"
        map.set koty[liza][chleb] "czt koty liżą chleb?"
        map.set koty[czyszcza][futro] "czy koty czyszczą futro?"
        map.set psy[aportuja][patyki] "czy psy aportują patyki"

        declare -p | grep map_

        echo -e "\n > map.unset koty[liza][chleb] \n"
        map.unset koty[liza][chleb]
        declare -p | grep map_

        echo -e "\n > map.unset koty[liza][maslo] \n"
        map.unset koty[liza][maslo]
        declare -p | grep map_

        echo -e "\n > map.unset psy \n"
        map.unset psy
        declare -p | grep map_

    }

    test_table_print() {

        map.set TABLE[header][id] "ID"
        map.set TABLE[header][name] "Nazwa"
        map.set TABLE[header][price] "Cena"

        map.set TABLE[items][0][id] "55"
        map.set TABLE[items][0][name] "Korniszony lubelskie"
        map.set TABLE[items][0][price] "12 zł"

        map.set TABLE[items][1][id] "254"
        map.set TABLE[items][1][name] "Persil"
        map.set TABLE[items][1][price] "999 zł"

        table.print TABLE
    }

    test_repeat() {
        echo
        repeat "#" 10
        echo
        repeat "nie jestem szalony! " 5
    }

    test_remove_array_first() {
        local arr=( "one" "two" "three")
        array_remove_first "two" "arr"
        declare -p arr
        array_remove_first "one" "arr"
        declare -p arr
        arr+=( "duck duck" "minus one" "duck duck" )
        declare -p arr
        array_remove_first "duck duck" "arr"
        declare -p arr
        array_remove_first "duck duck" "arr"
        declare -p arr
        array_remove_first "duck duck" "arr"
        declare -p arr
        array_remove_first "three" "arr"
        declare -p arr
        array_remove_first "one" "arr"
        declare -p arr
        array_remove_first "minus one" "arr"
        declare -p arr
        array_remove_first "minus one" "arr"
        declare -p arr
    }

    run_tests
}