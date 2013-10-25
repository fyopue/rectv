#!/bin/bash
# ディレクトリ設定
#usrdir="/home/`/usr/bin/whoami`/"
usrdir="`/usr/bin/dirname ${0}`/"
stgfile=${usrdir}recstg/
reclist=/tmp/
# エラー処理
pusherrmsg () {
  errtime=`date "+%Y/%m/%d %H:%M:%S"`
  case ${1} in
    1 ) echo "${errtime} : ディレクトリの設定が間違っているようです。末尾にスラッシュがあるか確認してください。" >> /tmp/recdgen_err.log && exit 1 ;;
    2 ) echo "${errtime} : ファイルの取得に失敗しました。iepg.list または ネットワークを確認してください。" ;;
    3 ) echo "${errtime} : 取得データに異常があります。iepg.listを確認してください。" ;;
    4 ) echo "${errtime} : 予約情報の生成に失敗したようです。設定ファイル、ディレクトリ設定、ネットワークの状態を確認してください。" ;;
    5 ) echo "${errtime} : 番組情報が存在しないため ${3} をリストから削除しました。放送が終了したか、存在しない番組です。" ;;
  esac >> /tmp/recdgen_err.log
  if [ -z "${3}" ]
  then
    rm -f ${2}iepg/*.* ${2}rec/*.*
    exit 1
  else
# 偽データ
    echo "ＭＸテレビ" 1970 01 01 09:00 09:30 "無効タイトル"
  fi
}
iepgex () {
  cat "${1}iepg/iepg.php?PID=${2}"  | iconv -f cp932 -t utf-8 | grep -e "year" -e "month" -e "date" -e "start" -e "end" -e "program-title" -e "station" | sed -e "s/[a-z]*-\|[a-z]*: \|\r\|\n\|<\|>//g"
}
getiepg () {
  sleep 2 && /usr/bin/wget -P "${1}iepg/" http://cal.syoboi.jp/iepg.php?PID=${2} || pusherrmsg 2 ${1}
}
lsupdate () {
  local lsd=${1}iepg.list
  case ${3} in
    del ) local iepgnum=`cat ${lsd} | sed -e "s/${2}//" -e "s/^$//"` ;;
    upd ) local iepgnum=`cat ${lsd} | sed -e "s/${2}/$((${2}+1))/"` ;;
  esac
  echo ${iepgnum} | sed -e "s/\r\|\n//g" -e "s/ /\n/g" > ${stgfile}iepg.list
}
# ディレクトリ設定チェック
ckstg=( "${usrdir}" "${stgfile}" "${reclist}" )
for (( i = 0; i < ${#ckstg[@]}; i++ ))
{
  echo ${ckstg[i]} | grep /$ || pusherrmsg 1
}
# 作業ディレクトリ
if [ ! -d "${reclist}rec" ]
then
  mkdir "${reclist}rec"
fi
if [ ! -d "${reclist}iepg" ]
then
  mkdir "${reclist}iepg"
fi
# ファイル取得
for (( i = 0; i < `cat "${stgfile}iepg.list" | wc -w`; i++ ))
{
  pgid+=( `cat "${stgfile}iepg.list" | head -$(( ${i} +1 )) | tail -1 | sed -e "s/\r\|\n//g"` )
  getiepg ${reclist} ${pgid[i]}
# ファイル処理
  unset data dt tm len nxtm sp
  data=(`iepgex "${reclist}" "${pgid[i]}"`)
  while :
  do
    if [ "${data[1]}" -lt "1971" ]
    then
# 番組存在しない
      unset data
      data=( `pusherrmsg 5 ${reclist} ${pgid[i]}` )
      ngid+=( ${pgid[i]} )
      sp="nodata"
      break
    elif [ "${data[1]}${data[2]}${data[3]}" -lt `date +%Y%m%d` ]
    then
# データ古い時
      unset data
      lsupdate ${stgfile} ${pgid[i]} upd
      rm "${reclist}iepg/iepg.php?PID=${pgid[i]}"
      pgid[i]=$(( ${pgid[i]} + 1 ))
      getiepg ${reclist} ${pgid[i]}
      data=(`iepgex "${reclist}" "${pgid[i]}"`)
    else
      break
    fi
  done
# 休止確認
  nxtm=( `date -d "\`date +%Y%m%d\`" +%s` - `date -d "${data[1]}${data[2]}${data[3]}" +%s` )
  nxtm=`echo $(( $(( ${nxtm[@]} )) / 86400 )) | grep ^- | sed -e "s/^-//"`
  if [ -n "${nxtm}" ]
  then
    if [ "8" -le "${nxtm}" ]
    then
      sp="# "
    fi
  fi
  for (( j = 0; j < ${#data[@]}; j++ ))
  {
    if [ -z "${data[j]}" ]
    then
      pusherrmsg 3 ${reclist}
    fi
    case ${j} in
      0 ) ch=( `cat "${stgfile}ch.list" | grep ${data[j]}` ) ;;
      [4,5] ) tm+=( `date -d ${data[j]} "+%-H %-M"` ) ;;
      6 ) ttl=${data[j]} ;;
      * ) dt+=${data[j]} ;;
    esac
  }
  wk=`date -d ${dt} "+%w"`
# 開始終了時刻確認
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
# 録画時間確認
  len=$(( ${ed} - ${st} - 1 ))
  if [ ${len} -lt 9 ]
  then
    len=$(( ${ed} - ${st} + 2 ))
    if [ ${st} -eq 0 ]
    then
      tm[0]=23
      tm[1]=$(( 6${tm[1]} - 1 ))
    else
      tm[1]=$(( ${tm[1]} - 1 ))
    fi
  fi
# 個別job生成
  case ${sp} in
    nodata ) : > ${reclist}rec/rec${pgid[i]}.list ;;
    * ) echo  ${sp}${tm[1]} ${tm[0]} '*' '*' ${wk} "${usrdir}rectv.sh" ${ch[1]} ${len} "\"${ttl}\"" ${pgid[i]} > ${reclist}rec/rec${pgid[i]}.list ;;
  esac
}
for (( i = 0; i < ${#ngid[@]}; i++ ))
{
  lsupdate ${stgfile} ${ngid[i]} del
}
# 個別job生成確認
ckjobdata=`cat ${reclist}rec/*.*`
if [ -z "${ckjobdata}" ]
then
  pusherrmsg 4 ${reclist}
else
# job生成
  cat ${reclist}rec/*.* "${stgfile}routine.list" | /usr/bin/sort -k 5 > "${reclist}rec.list"
fi
# crontab登録
/usr/bin/crontab "${reclist}rec.list"
# 作業ファイル削除
rm ${reclist}iepg/*.* ${reclist}rec/*.*
