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

        printf "\n\n"

        map.set COUNTRIES[items][0][name] "Poland"
        map.set COUNTRIES[items][0][continent] "Europe"
        map.set COUNTRIES[items][0][language] "polish"
        map.set COUNTRIES[items][0][religion] "Catholic church"

        map.set COUNTRIES[items][1][name] "United States of America"
        map.set COUNTRIES[items][1][continent] "North America"
        map.set COUNTRIES[items][1][language] "english"
        map.set COUNTRIES[items][1][religion] "many"

        map.set COUNTRIES[items][2][name] "China"
        map.set COUNTRIES[items][2][continent] "Asia"
        map.set COUNTRIES[items][2][language] "Standard Chinese"
        map.set COUNTRIES[items][2][religion] "Confucianism and Taoism"

        map.set COUNTRIES[items][3][name] "Australia"
        map.set COUNTRIES[items][3][continent] "Australia"
        map.set COUNTRIES[items][3][language] "english"
        map.set COUNTRIES[items][3][religion] "Christian"

        table.print COUNTRIES
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

    test_indent() {

         text=$'Lorem ipsum\n'
        text+=$'Dolom est:\n'
        text+=$'  - one\n'
        text+=$'  - two:\n'
        text+=$'     a) nope\n'
        text+=$'     b) yes\n'
        text+=$'\n'
        text+=$'Thats all!\n'

        log "Original:"
        printf "${text}"
        log "End of Original\n"

        log "Indented:"
        echo -n "${text}" | indent 4
        log "End of Indented\n"
    }

    test_get_preferences() {
        import "bashduino/preferences/get_preferences" as "get_preferences"

        declare -A prefs
        get_preferences prefs

        for pref in "${!prefs[@]}"; do
            printf "pref: '%s'='%s'\n" "${pref}" "${prefs[${pref}]}"
        done

        unset prefs
    }

    test_apply_preferences() {
        import "bashduino/preferences/apply_preferences" as "apply_preferences"

        declare -A prefs
        prefs['port']=/dev/dev/dev
        prefs['run_twice']=true

        CONFIG_DIR="$(mktemp -d)"
        log "CONFIG_DIR: '${CONFIG_DIR}'"

        local prefs_file="${CONFIG_DIR}/preferences.txt"

        printf "%s\n" "## PREFERENCES" >> "${prefs_file}"
        printf "%s\n" "board_name=nodemcu" >> "${prefs_file}"
        printf "%s\n" " run_twice=false" >> "${prefs_file}"
        printf "%s\n" "" >> "${prefs_file}"
        printf "%s\n" "# these prefs don't make sense! " >> "${prefs_file}"
        printf "%s\n" "  lorem_ipsum=dolom " >> "${prefs_file}"
        printf "%s\n" "est=lorem ipsum dolom" >> "${prefs_file}"

        printf "\n%s\n" "--- Prefs file before changes: ----------------"
        cat "${prefs_file}"
        printf "\n%s\n" "---END-----------------------------------------"

        apply_preferences prefs

        printf "\n%s\n" "--- Prefs file after changes: -----------------"
        cat "${prefs_file}"
        printf "\n%s\n" "---END-----------------------------------------"

        unset prefs
    }

    test_get_snapshot_dirs() {
        import "bashduino/snapshots/get_snapshot_dirs" as "get_snapshot_dirs"
        get_snapshot_dirs
        local snapshot_dirs=( "${RETURN_VALUE[@]}" )
        printf "%s : \n\t%s\n" "test_get_snapshot_dirs" "$(declare -p snapshot_dirs)"
    }

    test_get_hardware_dir() {
        import "bashduino/snapshots/get_hardware_dir" as "get_hardware_dir"
        get_hardware_dir
        local hardware_dir="${RETURN_VALUE}"
        printf "Hardware dir: '%s'\n" "${hardware_dir}"
    }

    run_tests
}