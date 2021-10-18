#! /usr/bin/bash

# dcount.sh must be in this same folder!

#################################################################
### Functions                                                 ###
#################################################################

help(){
        echo "AGENDA"
        echo "shows time until appointment"
        echo ""
        echo "SYNTAX"
        echo "agenda [-a|d|b|r|u|h]"
        echo ""
        echo "USAGE"
        echo "agenda [no args]          shows agenda"
        echo "a                         adds appointment"
        echo "d                         date to add to appointment"
        echo "b                         creates a backup file at $HOME"
        echo "r                         if backup file exists, loads it into current agenda"
        echo "u                         removes appointment by index"
        echo "h                         show help"
}

writeCsv(){
        # delimits an array with commas and
        # a newline after the last element
        local input=("$@")
        local length="${#input[@]}"
        local csv=()

        for ((i=0; i<$length-1; i++)); do
                csv+=$(printf "${input[$i]},")
        done

        # adds a newline after the last element
        csv+=$(printf "${input[-1]}")  # [-1] gets last element
        printf "%s\n" "${csv[@]}" >> "$agendaPath/agenda.txt"
}

printAgenda(){
        local line="_____________________________________________________________________"
        local agendaEntries=("$@")
        local length="${#agendaEntries[@]}"
        local entry=()
        for ((i=0; i<$length; i++)); do
                readarray -d ',' -t entry <<< "${agendaEntries[$i]}"
                local timeLeft=(${entry[0]})
                local appointment="${entry[1]}"
                local index=$(($i+1))
                local padding=$(printf "[$index] %s days %s hours and %s minutes left"\
                "${timeLeft[0]}" "${timeLeft[1]}" "${timeLeft[2]}")
                
                printf "[$index] %s days %s hours and %s minutes left %s %s\n"\
                "${timeLeft[0]}" "${timeLeft[1]}" "${timeLeft[2]}" "${line:${#padding}}" "$appointment"
        done
}

updateAgenda(){
        # runs dcount on each entry
        # to update countdowns
        local agendaEntries=("$@")
        local currentEntry=()
        local length="${#agendaEntries[@]}"
        : > "$agendaPath/agenda.txt"
        for ((j=0; j<"$length"; j++)); do
                readarray -d ',' -t currentEntry <<< "${agendaEntries[$j]}"
                local newDate=$("$dirPath/dcount.sh" "${currentEntry[2]}") status=$?

                # checks if exit status is 1
                # i.e. if countdown values is
                # negative
                if [[ $status -ne 0 ]]; then
                        continue
                fi

                local updatedEntry=("$newDate" "${currentEntry[1]}" "${currentEntry[2]}")
                writeCsv "${updatedEntry[@]}"
        done
}

convertToMinutes(){
        # receives days hours and mins
        # and returns the equivalent in
        # minutes
        minutes=$(($1*24*60 + $2*60 + $3))
        printf $minutes
}

sortAgenda(){
        # sorts entries based on the
        # total minutes left to target
        # date
        local agendaEntries=("$@")
        local sortedEntries=()
        local length=${#agendaEntries[@]} 
        local count=1
        local previousIndex=-1

        # assigns each entry with the time left
        # in minutes as index to sort values
        for ((i=0; i<$length; i++)); do
                readarray -d ',' -t entry <<< "${agendaEntries[$i]}"
                local index=$(convertToMinutes ${entry[@]})
                # minimizes the chance of duplicate values
                # causing indexes to be overwritten
                index=$(($index + $count)) 
                sortedEntries[$index]="${agendaEntries[$i]}"
                ((count++))
        done

        printf "%s" "${sortedEntries[@]}"
}

#################################################################
### Main Program                                              ###
#################################################################

agendaPath="$HOME" # agenda.txt will be saved here
dirPath=$(dirname $(realpath "$0")) # dcount.sh must be here

# creates file to store agenda
# if it does not exist
if [[ ! -f "$agendaPath/agenda.txt" ]]; then
        touch "$agendaPath/agenda.txt"
fi

# sorts agenda.txt
agendaEntries=()
readarray agendaEntries < "$agendaPath/agenda.txt"
# if entries is not 0, sort array
if ((${#agendaEntries[@]})); then
        # updates and sorts agenda
        readarray agendaEntries < <(sortAgenda "${agendaEntries[@]}")
        updateAgenda "${agendaEntries[@]}"
        # and refreshes the array
        readarray agendaEntries < "$agendaPath/agenda.txt"
fi

aOption=false
dOption=false
declare -A userInput
while getopts ":a:d:bru:h" option; do
        case "$option" in

        # add and delete =====================================================================
                a) # adds appointment name

                        aOption=true
                        userInput["appointment"]="$OPTARG"
                ;;

                d)      # adds date and saves to agenda.txt
                        dOption=true
                        if ! $aOption; then break; fi
                        userInput["date"]="$OPTARG"
                        userInput["timeLeft"]=$("$dirPath/dcount.sh" "${userInput["date"]}")

                        # tests if dcount received valid date
                        if [[ $? -ne 0 ]]; then
                                printf "invalid date\n"
                                exit 1
                        fi
                
                        newEntry=("${userInput[timeLeft]}" \
                                "${userInput[appointment]}" \
                                "${userInput[date]}")
                        writeCsv "${newEntry[@]}"
                        printf "Entry added\n"
                ;;

                u)      # unsets entry
                        index=$(($OPTARG-1))
                        echo "$index"
                        unset agendaEntries[$index]
                
                        # tests if unset received a valid value
                        if [[ $? -ne 0 ]]; then
                                echo "invalid index"
                                exit 1
                        fi

                        printf "%s" "${agendaEntries[@]}" > "$agendaPath/agenda.txt"
                        echo "the index [$index] was unset"
                        exit 0
                ;;

        # backup and restore =================================================================
                b)
                        cp "$agendaPath/agenda.txt" "$agendaPath/agenda.bkp"
                ;;

                r)
                    if [ -f  "$agendaPath/agenda.bkp" ]; then
                        cp "$agendaPath/agenda.bkp" "$agendaPath/agenda.txt"
                    else
                        printf "No backup file\n"
                    fi
                ;;

        # help ===============================================================================
                h)      # shows help
                        help
                        exit 0
                ;;

        # invalid ============================================================================
                \?)
                        echo "invalid options"
                        echo "see options with -h"
                        exit 1
                ;;
        esac
done

# if no options were passed
# prints agenda
if [[ $OPTIND -eq 1 ]]; then
        # print entries
        printAgenda "${agendaEntries[@]}"
fi

# warns user
# if a is passed but not b, or
# if b is passed but not a
if $aOption && ! $dOption; then
        echo "to add an entry insert both -a 'appointment' and -d 'date'"
fi
if ! $aOption && $dOption; then
        echo "to add an entry insert both -a 'appointment' and -d 'date'"
fi
