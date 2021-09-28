#! /usr/bin/bash

## Date Count
# Counts time until target date

targetDate=( "$@" )

# checks if targetDate is a valid date param
date "-d" "${targetDate[@]}" &> /dev/null
if [[ $? -ne 0 ]]; then
        exit 1
fi
# echo "${targetDate[@]}"
currentDateParams(){
        # grabs day (0..366)
        # and hour (0..23)
        # and minutes (..59)
        # of current date
        day=$(date +%j)
        hour=$(date +%H)
        minutes=$(date +%M)
       echo "$day" "$hour" "$minutes"
}

targetDateParams(){
        # grabs day (0..366)
        # and hour (0..23)
        # and minutes (..59)
        # of target date
        day=$(date -d "${targetDate[@]}" +%j)
        hour=$(date -d "${targetDate[@]}" +%H)
        minutes=$(date -d "${targetDate[@]}" +%M)
       echo "$day" "$hour" "$minutes"
}

diffInMinutes(){
        # calculates the
        # difference in
        # minutes

        # indexes of following arrays
        # [0]=days,[1]=hours,[2]=mins
        currentDayHour=( $(currentDateParams) )
        targetDayHour=( $(targetDateParams) )

        # total mins = ((days diff)*60 mins
        # - minutes past in current day
        # + minutes left in target day)
        dayDiff="$(( ${targetDayHour[0]} - ${currentDayHour[0]} ))"
        minutesInCurrentDay="$(( 10#${currentDayHour[1]}*60+10#${currentDayHour[2]} ))"
        # hashtag 10 forces base-10 interpretation
        # otherwise it might interpret numbers
        # like '09' wrong
        minutesInTargetDay="$(( 10#${targetDayHour[1]}*60+10#${targetDayHour[2]} ))"
        diff="$(( ($dayDiff*24*60) - ($minutesInCurrentDay) + ($minutesInTargetDay) ))"
        echo "$diff"
}

minutesDiff=$(diffInMinutes)

daysLeft="$(( ($minutesDiff/60)/24 ))"
hoursLeft="$(( ($minutesDiff/60)%24 ))"
minutesLeft="$(( ($minutesDiff%60) - 1 ))"

# tests if results are negative
isDaysLeftNegative=$(if (($daysLeft < 0)); then printf 0; else printf 1; fi)
isHoursLeftNegative=$(if (($hoursLeft < 0)); then printf 0; else printf 1; fi)
isMinutesLeftNegative=$(if (($minutesLeft < 0)); then printf 0; else printf 1; fi)

if [[ $isDaysLeftNegative -eq 0 || \
        $isHoursLeftNegative -eq 0  || \
        $isMinutesLeftNegative -eq 0  ]]; then
        printf "negative numbers\n"
        exit 1
fi

printf "%s %s %s" "$daysLeft" "$hoursLeft" "$minutesLeft"
