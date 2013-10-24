#!/bin/bash
# prefix
usrdir=/home/usrdir/
settingfile=${usrdir}stgdir/
reclist=/filedir/
# エラー処理
pusherrmsg () {
  errtime=`date "+%Y/%m/%d %H:%M:%S"`
  case ${1} in
    1 ) echo "${errtime} : ディレクトリの設定が間違っているようです。末尾にスラッシュがあるか確認してください。" >> /tmp/recdgen_err.log && exit 1 ;;
    2 ) echo "${errtime} : ファイルの取得に失敗しました。iepg.list または ネットワークを確認してください。" ;;
    3 ) echo "${errtime} : 取得データに異常があります。iepg.listを確認してください。" ;;
    4 ) echo "${errtime} : 予約情報の生成に失敗したようです。設定ファイル、ディレクトリ設定、ネットワークの状態を確認してください。" ;;
  esac >> /tmp/recdgen_err.log
  rm -f ${2}iepg/*.* ${2}rec/*.*
  exit 1
}
# prefix内容チェック
ckstg=( "${settingfile}" "${reclist}" "${reclist}" )
for (( i = 0; i < ${#ckstg[@]}; i++ ))
{
  echo ${ckstg[i]} | grep /$ || pusherrmsg 1
}
# 作業ディレクトリ
if [ ! -d ${reclist}rec ]
then
  mkdir ${reclist}rec
  if [ ! -d ${reclist}iepg ]
  then
    mkdir ${reclist}iepg
  fi
fi
# ファイル取得
str=( "start" "end" "year" "month" "date" "program-title" "station" )
for (( i = 0; i < `cat ${settingfile}iepg.list | wc -w`; i++ ))
{
  pgid+=( `cat ${settingfile}iepg.list | head -$(( ${i} +1 )) | tail -1 | sed -e "s/\r\|\n//g"` )
  sleep 2 && /usr/bin/wget -P ${reclist}iepg/ http://cal.syoboi.jp/iepg.php?PID=${pgid[i]} || pusherrmsg 2 ${reclist}
# ファイル処理
  unset data tm dt len
  for (( j = 0; j < ${#str[@]}; j++ ))
  {
    data+=( `cat ${reclist}iepg/iepg.php?PID=${pgid[i]} | iconv -f cp932 -t utf-8 | grep ${str[j]} | sed -e "s/${str[j]}: \|<\|>\|\r\|\n//g" -e "s/ \|　/_/g"` )
    if [ -z "${data[j]}" ]
    then
      pusherrmsg 3 ${reclist}
    fi
    case ${j} in
      [0,1] ) tm+=( `date -d ${data[j]} "+%-H %-M"` ) ;;
      4 ) wk=`date -d ${dt}${data[j]} "+%w"` ;;
      5 ) ttl=${data[j]} ;;
      6 ) ch=( `cat ${settingfile}ch.list | grep ${data[j]}` ) ;;
      * ) dt+=${data[j]} ;;
    esac
  }
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
  echo ${tm[1]} ${tm[0]} '*' '*' ${wk} "${usrdir}rectv.sh" ${ch[1]} ${len} "\"${ttl}\"" ${pgid[i]} > ${reclist}rec/${pgid[i]}.list
}
# 個別job生成確認
ckjobdata=`cat ${reclist}rec/*.*`
if [ -z "${ckjobdata}" ]
then
  pusherrmsg 4 ${reclist}
else
# job生成
  cat ${reclist}rec/*.* ${settingfile}routine.list | /usr/bin/sort -k 5 > ${reclist}rec.list
fi
# crontab登録
/usr/bin/crontab "${reclist}rec.list"
# 作業ファイル削除
rm -f ${reclist}iepg/*.* ${reclist}rec/*.*
