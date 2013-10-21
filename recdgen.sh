#!/bin/bash
# ファイル取得
settingfile=/filedir/
reclist=/filedir/
reciepg=/filedir/
if [ ! -d ${reciepg}rec ]
then
    if [ ! -d ${reciepg}iepg ]
    then
      mkdir ${reciepg}rec
      mkdir ${reciepg}iepg
    fi
fi
str=( "start" "end" "year" "month" "date" "program-title" "station" )
for (( i = 0; i < `cat ${settingfile}iepg.list | wc -l`; i++ ))
{
  pgid+=( `cat ${settingfile}iepg.list | head -$(( ${i} +1 )) | tail -1 | sed -e "s/\r\|\n//g"` )
  sleep 2 && /usr/bin/wget -P ${reciepg}iepg/ http://cal.syoboi.jp/iepg.php?PID=${pgid[i]}
# ファイル処理
  unset data tm dt len
  for (( j = 0; j < ${#str[@]}; j++ ))
  {
    data+=( `cat ${reciepg}iepg/iepg.php?PID=${pgid[i]} | iconv -f cp932 -t utf-8 | grep ${str[j]} | sed -e "s/${str[j]}: \|<\|>\|\r\|\n//g" -e "s/ \|　/_/g"` )
    case ${j} in
      [0,1] ) tm+=( `date -d ${data[j]} +%k:%M | sed -e "s/:0\|:/ /"` ) ;;
      4 ) wk=`date -d ${dt}${data[j]} +%w` ;;
      5 ) ttl=${data[j]} ;;
      6 ) ch=( `cat ${settingfile}ch.list | grep ${data[j]}` ) ;;
      * ) dt+=${data[j]} ;;
    esac
  }
  st=$(( $(( ${tm[0]} * 60 )) + ${tm[1]} ))
  if [ ${st} -eq 0 ]
	  then
	  ed=$(( $(( ${tm[2]} * 60 )) + ${tm[3]} ))
	else
    case ${tm[2]} in
      0 ) ed=$(( $(( 24 * 60 )) + ${tm[3]} )) ;;
      * ) ed=$(( $(( ${tm[2]} * 60 )) + ${tm[3]} )) ;;
    esac
  fi
  len=$(( ${ed} - ${st} - 1 ))
  if [ ${len} -lt 9 ]
	  then
	  len=$(( ${ed} - ${st} + 2 ))
	  case ${tm[1]} in
	    0 ) tm[1]=$(( 6${tm[1]} - 1 )) ;;
		  * ) tm[1]=$(( ${tm[1]} - 1 )) ;;
    esac
  fi
  echo ${tm[1]} ${tm[0]} '*' '*' ${wk} "/home/usrdir/rectv.sh" ${ch[1]} ${len} "\"${ttl}\"" ${pgid[i]} > ${reciepg}rec/${pgid[i]}.list
}
rm -f ${reciepg}iepg/*.*
cat ${reciepg}rec/*.* ${settingfile}routine.list | /usr/bin/sort -k 5 > ${reclist}rec.list
rm -f ${reciepg}rec/*.*
/usr/bin/crontab "${reclist}rec.list" 
