#!/bin/bash
# $1 -- ch_num
# $2 -- rec_min
# $3 -- title
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
echo "${dr}" > "${stgfile}drive.list"
# 二重録画防止
if [ ! -d "/tmp/running" ]
then
  mkdir "/tmp/running"
fi
# プロセスが存在するかチェック
spid=$$
pdo=(`pidof recpt1`)
if [ ${#pdo[@]} -eq 0 ]
then
  rm /tmp/running/*
elif [ ${#pdo[@]} -gt 0 ]
then
# 同一番組かチェック
  kproc=(`cat /tmp/running/* | $g "${1} ${3}" | $g -v ${spid}`)
  if [ -n "${kproc[2]}" ]
  then
    kill ${kproc[2]} && rm /tmp/running/${kproc[2]}
    sleep 1
  fi
fi
/usr/local/bin/recpt1 --b25 --strip --sid ${sid} ${1} ${mt} ${1}_${3}_${dt}.ts &
# 実行情報の保存
rpid=$!
echo ${1} ${3} ${rpid} ${spid} > /tmp/running/${rpid}
