#! /usr/bin/bash

# dcount.sh must be in this same folder!

#################################################################
### Help                                                      ###
#################################################################

help(){
        echo "AGENDA"
        echo "shows time until appointment"
        echo ""
        echo "SYNTAX"
        echo "agenda [-a|d|u]"
        echo ""
        echo "USAGE"
        echo "agenda [no args]          shows agenda"
        echo "a                         adds appointment"
        echo "d                         date to add to appointment"
        echo "u                         removes appointment by index"
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
        local line="___________________________________________"
        local agendaEntries=("$@")
        local length="${#agendaEntries[@]}"
        local entry=()
        for ((i=0; i<$length; i++)); do
                readarray -d ',' -t entry <<< "${agendaEntries[$i]}"
                local timeLeft=(${entry[0]})
                local appointment="${entry[1]}"
                local index=$(($i+1))
                printf "[$index] %s days %s hours and %s minutes left %20s\n"\
                "${timeLeft[0]}" "${timeLeft[1]}" "${timeLeft[2]}" "$appointment"
        done
}

updateAgenda(){
        local agendaEntries=("$@")
        local currentEntry=()
        local length="${#agendaEntries[@]}"
        : > "$agendaPath/agenda.txt"
        for ((j=0; j<"$length"; j++)); do
                readarray -d ',' -t currentEntry <<< "${agendaEntries[$j]}"
                local newDate=$(./dcount.sh "${currentEntry[2]}")
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

                # changes the index if it is equal to
                # that of another entry to prevent
                # overwriting
                if (($index==$previousIndex)); then
                        local newIndex=$(($index + $count))
                        sortedEntries[$newIndex]="${agendaEntries[$i]}"
                        ((count+=10))
                        continue
                fi

                sortedEntries[$index]="${agendaEntries[$i]}"
                previousIndex=$index
        done

        # updates file with sorted values
       # local count2=1
       # : > "$agendaPath/agenda.txt"
       # for i in "${sortedEntries[@]}"; do
       #         printf "%s" "$i" >> "$agendaPath/agenda.txt"
       #         ((count2++))
       # done
        printf "%s" "${sortedEntries[@]}"
}

#################################################################
### Main Program                                              ###
#################################################################

agendaPath="$HOME"

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
while getopts ":a:d:u:h" option; do
        case "$option" in

                a) # adds appointment name
                aOption=true
                userInput["appointment"]="$OPTARG"
                ;;

                d) # adds date and saves to agenda.txt
                dOption=true
                if ! $aOption; then break; fi
                userInput["date"]="$OPTARG"
                userInput["timeLeft"]=$(./dcount.sh "${userInput["date"]}")

                # tests if dcount received valid date
                if [[ $? -ne 0 ]]; then
                        echo "invalid date"
                        exit 1
                fi
                
                newEntry=("${userInput[timeLeft]}" \
                        "${userInput[appointment]}" \
                        "${userInput[date]}")
                writeCsv "${newEntry[@]}"
                printf "Entry added\n"
                ;;

                u) # unsets entry
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

                h) # shows help
                help
                exit 0
                ;;

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