#!/bin/bash
# $1 -- ch_num
# $2 -- rec_min
# $3 -- title
# $4 -- iepg seed
#stgfile="/home/`/usr/bin/whoami`/rectv/stgdir/"
stgfile="`/usr/bin/dirname ${0}`/recstg/"
# hdd-id
d1="hdd-id01"
d2="hdd-id02"
g="grep"
dt=`date +%y%m%d%H%M%S`
mt=$(( 60 * ${2} ))
case "${1}" in
  "103" | "910" ) sid=${1} ;;
  * ) sid=hd ;;
esac
flag=`cat "${stgfile}drive.list"`
case ${flag} in
  ${d1} ) ;;
  ${d2} ) d2=${d1}
  d1=${flag} ;;
  * ) flag=${d1} ;;
esac
if [ ! -d /media/${d1} ]
then
  d1=${d2}
  d2=${flag}
fi
u="9[6-9]%\|100%"
dck=`df -h | $g ${d1} | $g ${u} | wc -l`
case ${dck} in
	1 ) df -h | $g ${d2} | $g ${u} && exit
	dr=${d2} ;;
	* ) dr=${d1} ;;
esac
cd /media/${dr}/recdir/ || exit
/usr/local/bin/recpt1 --b25 --strip --sid ${sid} ${1} ${mt} ${1}_${3}_${dt}.ts
echo "${dr}" > "${stgfile}drive.list"
if [ -n "${4}" ]
then
  sleep $(($RANDOM%50)) && iepgnum=`cat ${stgfile}iepg.list | sed -e "s/${4}/$(( ${4} + 1 ))/"`
  echo ${iepgnum} | sed -e "s/\r\|\n//g" -e "s/ /\n/g" > ${stgfile}iepg.list
fi
