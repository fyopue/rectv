#!/bin/bash
# ファイル取得
settingfile=/filedir/
reclist=/filedir/
reciepg=/filedir/
pusherrmsg () {
  errtime=`date "+%Y/%m/%d %k:%M:%S"`
  case ${1} in
    1 ) echo "${errtime} : ディレクトリの設定が間違っているようです。末尾にスラッシュがあるか確認してください。" ;;
    2 ) echo "${errtime} : ファイルの取得に失敗しました。iepg または ネットワークを確認してください。" ;;
    3 ) echo "${errtime} : 取得データに異常があります。iepg.listを確認してください。" ;;
    4 ) echo "${errtime} : 予約情報の生成に失敗したようです。設定ファイル、ディレクトリ設定、ネットワークの状態を確認してください。" ;;
  esac >> /tmp/recdgen_err.log
  rm -f ${2}iepg/*.* ${2}rec/*.*
  exit 1
}
ckstg=( "${settingfile}" "${reclist}" "${reciepg}" )
for (( i = 0; i < ${#ckstg[@]}; i++ ))
{
  echo ${ckstg[i]} | grep /$ || pusherrmsg 1
}
if [ ! -d ${reciepg}rec ]
then
  mkdir ${reciepg}rec
  if [ ! -d ${reciepg}iepg ]
  then
    mkdir ${reciepg}iepg
  fi
fi
str=( "start" "end" "year" "month" "date" "program-title" "station" )
for (( i = 0; i < `cat ${settingfile}iepg.list | wc -l`; i++ ))
{
  pgid+=( `cat ${settingfile}iepg.list | head -$(( ${i} +1 )) | tail -1 | sed -e "s/\r\|\n//g"` )
  sleep 2 && /usr/bin/wget -P ${reciepg}iepg/ http://cal.syoboi.jp/iepg.php?PID=${pgid[i]} || pusherrmsg 2 ${reciepg}
# ファイル処理
  unset data tm dt len
  for (( j = 0; j < ${#str[@]}; j++ ))
  {
    data+=( `cat ${reciepg}iepg/iepg.php?PID=${pgid[i]} | iconv -f cp932 -t utf-8 | grep ${str[j]} | sed -e "s/${str[j]}: \|<\|>\|\r\|\n//g" -e "s/ \|　/_/g"` )
    if [ -z "${data[j]}" ]
    then
      pusherrmsg 3 ${reciepg}
    fi
    case ${j} in
      [0,1] ) tm+=( `date -d ${data[j]} "+%-k:%-M" | sed -e "s/:/ /"` ) ;;
      4 ) wk=`date -d ${dt}${data[j]} "+%w"` ;;
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
ckjobdata=`cat ${reciepg}rec/*.*`
if [ -z "${ckjobdata}" ]
then
  pusherrmsg 4 ${reciepg}
else
  cat ${reciepg}rec/*.* ${settingfile}routine.list | /usr/bin/sort -k 5 > ${reclist}rec.list
fi
/usr/bin/crontab "${reclist}rec.list"
rm -f ${reciepg}iepg/*.*
rm -f ${reciepg}rec/*.*
