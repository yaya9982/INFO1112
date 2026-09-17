#!/bin/bash
# FUNCTIONS : tohex & tobin
tohex(){
    bin_f=${1:0:4}
    bin_b=${1:4:4}
    sum_f=0
    sum_b=0
    for((i=0;i<4;i++))
    do
        if [ ${bin_f:$i:1} -eq 1 ]
        then
            sum_f=$(($sum_f + 2**$((3-$i))))
        fi
    done
    for((i=0;i<4;i++))
    do
        if [ ${bin_b:$i:1} -eq 1 ]
        then
            sum_b=$(($sum_b + 2**$((3-$i))))
        fi
    done
    if [ $sum_f -lt 10 ]
    then
        hex=$sum_f
    else
        case $sum_f in
            10)
                hex=a
                ;;
            11)
                hex=b
                ;;
            12)
                hex=c
                ;;
            13)
                hex=d
                ;;
            14)
                hex=e
                ;;
            15)
                hex=f
                ;;
            *)
                echo "(ERROR) NOT A VALID NUMBER"
                ;;
        esac
    fi
    if [ $sum_b -lt 10 ]
    then
        hex="$hex$sum_b"
    else
        case $sum_b in
            10)
                hex="$hex"a
                ;;
            11)
                hex="$hex"b
                ;;
            12)
                hex="$hex"c
                ;;
            13)
                hex="$hex"d
                ;;
            14)
                hex="$hex"e
                ;;
            15)
                hex="$hex"f
                ;;
            *)
                echo "(ERROR) NOT A VALID NUMBER"
                ;;
        esac

    fi
    echo $hex
}
tobin(){
    val=$1
    bin_made=1
    if [ "$val" -eq 0 ]
    then
        bin_val=00000000
    fi
    while [ "$val" -ne 0 ] 
    do
        if [ "$bin_made" -eq 1 ]
        then
            bin_made=0
            bin_val=$(($val % 2))
            val=$(($val/2))
        else
            bin_val="$(($val % 2))$bin_val"
            val=$(($val/2))
        fi
    done
    echo $bin_val
}

# START OF PROGRAM
# check for file input : no input, invalid file, too many
if [ -z "$1" ]
then
    echo "usage: no argument is provided"
    exit 1
fi
if [[ "$2" || "$3" || "$4" ]]
then
    echo "usage: more than one arguments are provided"
    exit 1
fi
if [[ "$1" == *.* ]]
then
    if ! [[ "$1" == *.vsc ]]
    then
        echo "usage: input does not have the extension .vsc"
        exit 1
    fi
fi
if [ -f "$1" ]
then
    if [[ "$1" == *.vsc ]]
    then
        vscfile=$1
    else
        echo "usage: input does not have the extension .vsc"
        exit 1
    fi
else
    echo "usage: input is not a file or it does not exist"
    exit 1
fi
num_of_vars=0
IFS=. read -r filename vsc <<< "$vscfile"
# starts reading every line in .vsc and append to dataArray
line_count=0
dataArray=()
no_vars=1
quitted=1
while read -r line 
do
    line="${line%$'\r'}"
    # errors if over 100 instructions, which is 200 lines (2 lines per instruction)
    if (($line_count > $(( $num_of_vars + 200 ))))
    then
        echo "(ERROR) Too many instructions!"
        exit 1
    fi
    if [ $no_vars -eq 0 ]
    then
        # errors if 0 values provided and next line is not QUIT,0,0
        if [ "$line" != "QUIT,0,0" ]
        then
            echo "(ERROR) must QUIT if 0 values"
            exit 1
        fi
    fi
    # only checks if 'instruction' lines (starts with letter)
    if [[ "$line" == [A-Z]* ]]
    then
        IFS=, read -r op reg mem <<< "$line"
        # errors if memory or register values aren't integer and within valid ranges
        if [[ "$reg" != [0-3] ]]
        then
            echo "(ERROR) Register value invalid!"
            exit 1
        elif [[ ! "$mem" =~ ^[0-9]+$ ]]
        then
            echo "(ERROR) Memory value invalid!"
            exit 1
        elif [[ "$mem" -gt 255 || "$mem" -lt 0 ]]
        then
            echo "(ERROR) Memory value invalid!"
            exit 1
        fi
        # converts register value to binary
        bin_reg=$(tobin $reg)
        bin_reg=$(printf "%02d" "$bin_reg")
        # convert memory value to binary
        bin_mem=$(tobin $mem)
        bin_mem=$(printf "%08d" "$bin_mem")
        # selects appropriate binary code for instruction
        case "$op" in
            "LOAD")
                bin_op=000001 
                ;; 
            "STORE")
                bin_op=000010
                ;;
            "ADD")
                bin_op=000011
                ;;
            "SUB")
                bin_op=000100
                ;;
            # QUIT and PRINT must have distinct memory and/or register values
            "QUIT")
                bin_op=001000
                quitted=0
                if [[ "$mem" -ne 0 || "$reg" -ne 0 ]]
                then
                    echo "(ERROR) QUIT must have addresses 0,0"
                    exit 1
                fi
                ;;
            "PRINT")
                bin_op=001001
                if [[ "$mem" -ne 0 ]]
                then
                    echo "(ERROR) PRINT must have memory address 0"
                    exit 1
                fi
                ;;
            # catches any invalid operation code : LOADDD, INVALID, load, l0ad, etc
            *)
                echo "(ERROR)INVALID OPERATION PROVIDED : $op"
                exit 1
        esac
        # appends the bytes to dataArray
        dataArray[$line_count-1]="$bin_op$bin_reg" 
        (( line_count++ ))
        dataArray[$line_count-1]="$bin_mem"
    # only activates if its the first line (num of values declaration)
    elif [ "$line_count" -eq 0 ]
    then
        num_of_vars="$line"
        # errors if number of values not an integer 
        if ! [[ "$num_of_vars" =~ ^[0-9]+$ ]]
        then
            echo "(ERROR) Number of variables not a positive integer!"
            exit 1
        fi
        if [ "$num_of_vars" -eq 0 ]
        then
            # edge case : if number of values is 0, no_vars condition triggers (must have QUIT as next line)
            no_vars=0
            filetype="QUIT"
        elif [ "$num_of_vars" -eq 2 ]
        then
            filetype="ADD/SUB"
        else
            filetype=""
        fi
    # if inside value declaration zone
    elif [[ "$line_count" -lt $(($num_of_vars + 1)) ]]
    then 
        bin_val_made=1
        val=$line
        # assigns 0 if val is 0, errors and exits if val is not in [0,128) or not integer
        if ! [[ "$val" =~ ^[0-9]+$ ]]
        then
            echo "(ERROR) Value not a positive integer!"
            exit 1
        fi
        if [ "$val" -lt 0 ]
        then
            echo "(ERROR) value must be positive!"
            exit 1
        elif [ "$val" -gt 127 ]
        then
            echo "(ERROR) value cannot exceed 127!"
            exit 1
        fi
        # converts value to binary and stores in dataArray
        bin_val=$(tobin $val)
        bin_val=$(printf "%08d" "$bin_val")
        dataArray[$line_count-1]="$bin_val"
    fi
    # line_count variable increments to keep track
    (( line_count++ ))
done < $vscfile
# errors if program never has QUIT
if [ $line_count -eq 0 ]
then
    echo "usage: the file is empty - no .bin file is produced"
    exit 1
elif [ $quitted -ne 0 ]
then
    echo "(ERROR) Program never quitted"
    exit 1
fi
# iterates through dataArray to convert binary to hexadecimal and add to file
printf "It is a %s program\n" "$filetype"
echo "********************"
echo "The content of the .bin file is"
for ((i=0;i<$line_count-1;i++))
do
    hex_data=$(tohex "${dataArray[i]}")
    echo "$hex_data"
    printf "\x$hex_data" >> "$(pwd)/$filename".bin
done    
exit 0



