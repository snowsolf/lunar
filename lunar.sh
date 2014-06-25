#########################################################################
# File Name: lunar.sh
# Author: snowsolf
# E-mail: snowsolf@hotmail.com
# Created Time: 2013年07月***********
#########################################################################
#!/bin/sh

Version=1.0
Editor=snowsolf
Email=snowsolf@hotmail.com

# print help
function Usage()
{
   cat << EOF
==============================================================
Valid date: 19010101 ~ 20991231
But 'date' program support: 19011215 ~ 20380119

  -h, --help              display this help and exit
  -V, --version           output version information and exit

Usage: $0 [-h|--help|-V|--version] | [date(yyyymmdd)]

Examples:
Usage input time:    $0 20130101
Usage system time:    $0

Editor: $Editor
E-mail: $Email
EOF
   exit 0
}

#################################################################
#get year,month,day and day of year
#system 'date' program support:19011215 ~ 20380119
#################################################################
function Date_data()
{
   date_year=$(echo $DATE |sed 's/^\(.\{4\}\).*/\1/')
   date_month=$(echo $DATE |sed 's/.*\(..\)..$/\1/')
   date_day=$(echo $DATE |sed 's/.*\(..\)$/\1/')
   date_days=$(date -d $DATE +%j)
}

DATE=$@
# handle difference input
case "$#" in
   0)
      echo "No parameters!"
      echo -e "Usage system time: $(date +%Y-%m-%d)\n"
      DATE=$(date +%Y%m%d)
      Date_data
   ;;
   1)
       date -d $DATE +%j > /dev/null || ((Usage && exit 0))
      case "$1" in
         -h|--help)
            Usage
         ;;
         -V|--version)
            echo "$0: Version $Version"
            echo "Editor: $Editor"
            echo "E-mail: $Email"
            exit 0
         ;;
         [1][9][0-9][0-9][0-9][0-9][0-9][0-9]|[2][0][0-9][0-9][0-9][0-9][0-9][0-9])
            [ "$1" -ge "19010101" ] && [ "$1" -lt "19011215" ] || [ "$1" -gt "20380119" ] && [ "$1" -le "20991231" ] \
            && echo -e "'date' program no support: $1\n" && Usage
            [ "$1" -ge "19000000" ] && [ "$1" -lt "19010101" ] || [ "$1" -gt "20991231" ] && [ "$1" -le "20999999" ] \
            && echo -e "Invalid parameter: $1\n" && Usage
            Date_data
         ;;
         *)
            echo -e "Invalid parameter: $1\n"
            Usage
         ;;
      esac
   ;;
   *)
      echo -e "The number of parameter greater than one !\n"
      Usage
   ;;
esac

# lunar databases
databases_path=databases

# get lunar year
lunar_year=$(sed /$date_year/!d $databases_path |sed 's/^\(....\).*/\1/')

# get all for lunar year, and form hexadecimal to binary
# include lunar year, month, day, and leap month
lunar_year_data=$(sed /$date_year/!d $databases_path |sed 's/.*\ \(.*\)/\1/')
lunar_year_data_bin=$(echo "ibase=16;obase=2;$lunar_year_data"|bc |sed -e :a -e 's/^.\{1,23\}$/0&/;ta')

new_year_month_bin=$(echo $lunar_year_data_bin |sed -e 's/^.\{17\}\(.\{2\}\).*/\1/')
new_year_month=$(echo "ibase=2;$new_year_month_bin"|bc |sed -e :a -e 's/^.\{1,1\}$/0&/;ta')

new_year_day_bin=$(echo $lunar_year_data_bin |sed -e 's/.*\(.\{5\}\)$/\1/')
new_year_day=$(echo "ibase=2;$new_year_day_bin"|bc |sed -e :a -e 's/^.\{1,1\}$/0&/;ta')

new_year_days=$(date -d $date_year$new_year_month$new_year_day +%j)
lunar_days=$(expr $date_days - $new_year_days + 1)
# flag
befor_or_after=0

if [ "$lunar_days" -le "0" ]; then
   befor_or_after=1
   date_year=$(($date_year - 1))

   lunar_year=$(sed /$date_year/!d $databases_path |sed 's/^\(....\).*/\1/')

   lunar_year_data=$(sed /$date_year/!d $databases_path |sed 's/.*\ \(.*\)/\1/')
   lunar_year_data_bin=$(echo "ibase=16;obase=2;$lunar_year_data"|bc |sed -e :a -e 's/^.\{1,23\}$/0&/;ta')
fi

lunar_leap_month_bin=$(echo $lunar_year_data_bin |sed -e 's/^\(.\{4\}\).*/\1/')
lunar_leap_month=$(echo "ibase=2;$lunar_leap_month_bin"|bc)

lunar_month_all_bin=$(echo $lunar_year_data_bin |sed -e 's/^.\{4\}\(.\{13\}\).*/\1/')
[ "$lunar_leap_month" = "0" ] && lunar_month_all_bin=$(echo $lunar_year_data_bin |sed -e 's/^.\{4\}\(.\{12\}\).*/\1/')
lunar_month_all=$(echo $lunar_month_all_bin |sed -e 's/0/29\ /g' |sed -e 's/1/30\ /g')

if [ "$befor_or_after" = "0" ];then
   lunar_month=1
   lunar_day=$lunar_days
   for i in $lunar_month_all
   do
      [ "$lunar_day" -eq "$i" ] && break
      [ "$lunar_day" -gt "$i" ] && lunar_day=$(($lunar_day - $i)) && lunar_month=$(($lunar_month + 1))
   done
else
   lunar_month=12
   lunar_day=$((-$lunar_days))
   lunar_month_all_bin=$(echo $lunar_month_all_bin |rev)
   lunar_month_all=$(echo $lunar_month_all_bin |sed -e 's/0/29\ /g' |sed -e 's/1/30\ /g')
   for i in $lunar_month_all
   do
      [ "$lunar_day" -eq "$i" ] && break
      if [ "$lunar_day" -gt "$i" ]; then
         lunar_day=$(($lunar_day - $i))
         lunar_month=$(($lunar_month - 1))
      else
         lunar_day=$(($i - $lunar_day))
         break
      fi
   done
fi

# output
if [ "$lunar_leap_month" = "0" ]; then
    echo $lunar_year-$lunar_month-$lunar_day
else
   if [ "$lunar_leap_month" -ge "$lunar_month" ]; then
      echo $lunar_year-$lunar_month-$lunar_day
   elif [ "$befor_or_after" = "0" ]; then
      if [ "$(($lunar_leap_month + 1))" = "$lunar_month" ];then
         lunar_month=$(($lunar_month - 1))
         echo $lunar_year-*$lunar_month-$lunar_day
      else
         lunar_month=$(($lunar_month - 1))
         echo $lunar_year-$lunar_month-$lunar_day
      fi
   else
      echo $lunar_year-$lunar_month-$lunar_day
   fi
fi

sed -n $(($(($lunar_year - 4598 + 2)) % 12))p shengxiao
