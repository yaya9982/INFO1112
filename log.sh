#!/bin/bash
# checks for inputs : yes dir, no dir, too many
if [ -z "$1" ]
then
    dir=`pwd`
else
    if [ "$2" ]
    then
        echo -e "usage: more than 1 arg is not allowed.\n"
        exit 2
    fi
    if [ -d "$1" ]
    then
        dir=$1
    else
        echo -e "usage: arg needs to be a directory.\n"
    exit 1
    fi
fi
# finds logfiles from assigned dir
largest_count=0
largest_error_file=""
sum_error=0
findfile=`find $dir -maxdepth 1 -name "*.log" -mtime -7`
if [ -z  "$findfile" ]
then
    echo -e "No. of modified log files: 0\n"
    exit 0
fi
for logfile in `find $dir -maxdepth 1 -name "*.log" -mtime -7`
do
    count=`grep -c "ERROR" $logfile`
    echo "FILE : $logfile | ERRORS : $count"
    echo "FILE : $logfile | ERRORS : $count" >> ~/analysisData.log
    sum_error=$((sum_error + count))
    if [ $count -gt $largest_count ]
    then
        largest_count=$count
        largest_error_file=$logfile
    fi
done
# stdouts error files and stats to terminal and files
echo "Total errors in $dir : $sum_error"
echo "Most error file : $largest_error_file with $largest_count errors"  
echo "Total errors in $dir : $sum_error" >> ~/summary.log
echo "Most error file : $largest_error_file with $largest_count errors" >> ~/summary.log

    




