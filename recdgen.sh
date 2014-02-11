#!/bin/bash
# ディレクトリ設定
ub=/usr/bin/
usrdir="`${ub}dirname ${0}`/"
stgfile=${usrdir}recstg/
reclist=/tmp/
# エラー処理
pusherrmsg () {
  local errtime=`date "+%Y/%m/%d %H:%M:%S"`
  case ${1} in
    1 ) echo "${errtime} : ディレクトリの設定が間違っているようです。末尾にスラッシュがあるか確認してください。" ;;
    2 ) echo "${errtime} : ファイルの取得に失敗しました。iepg.list または ネットワークを確認してください。" ;;
    3 ) echo "${errtime} : 取得データに異常があります。iepg.listを確認してください。" ;;
    4 ) echo "${errtime} : 予約情報の生成に失敗したようです。設定ファイル、ディレクトリ設定、ネットワークの状態を確認してください。" ;;
    5 ) echo "${errtime} : 番組情報が存在しないため ${3} ${4} をリストから削除しました。放送が終了したか、存在しない番組です。" ;;
    6 ) echo "${errtime} : 受信できない番組です。 ${3} ${4} をリストから削除しました。" ;;
    7 ) echo "${errtime} : 意図しない番組予約を行おうとしています。 ${3} ${4} をリストから削除しました。番号の間違い、または、連番の開始位置の変更があった可能性があります。iepg.listを確認・修正してください。" ;;
    8 ) echo "${errtime} : 意図しない番組予約を行った可能性があります。該当する番号は ${3} ${4} です。iepg.listを確認してください。" ;;
    9 ) echo "${errtime} : ${3} ${4} をリストから削除しました。" ;;
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
# データ抽出
iepgex () {
  cat "${1}iepg/iepg.php?PID=${2}" | iconv -f cp932 -t utf-8 | grep -e "year" -e "month" -e "date" -e "start" -e "end" -e "program-title" -e "station" | sed -e "s/^[a-z].*: \|\r\|\n\|<\|>\|-//g" -e "s/ \|　\|\//_/g"
}
# 誰かの善意に頼り切った自動展開
# 日付を跨ぐと正常に動作しない 要検討
mltpgex () {
  local ckmlt=`cat "${1}iepg/iepg.php?PID=${2}" | iconv -f cp932 -t utf-8 | tail -1 | grep -e "連続放送" -e "一挙放送" | wc -l`
  if [ "1" -eq "${ckmlt}" ]
  then
    while :
    do
      local seed=$(( ${2} + ${ckmlt} ))
      getiepg "${1}" "${seed}"
      local mltdata=(`iepgex "${1}" "${seed}"`)
      if [ "${3}" -ne "${mltdata[3]}" ]
      then
        echo ${ckmlt}
        break
      fi
      local ckmlt=$(( ${ckmlt} + 1 ))
      unset mltdata
    done
  fi
}
# データ取得
getiepg () {
  sleep 2 && ${ub}wget -P "${1}iepg/" http://cal.syoboi.jp/iepg.php?PID=${2} || pusherrmsg 2 ${1}
}
# リスト更新
lsupdate () {
  local lsd=${2}iepg.list
  case ${1} in
    del ) local iepgnum=`cat ${lsd} | ${ub}sort | ${ub}uniq | sed -e "s/${3}//" -e "s/^$//"` ;;
    upd ) local iepgnum=`cat ${lsd} | sed -e "s/${3}${4}/$((${3}+1))${4}/"` ;;
  esac
  echo ${iepgnum} | sed -e "s/\r\|\n//g" -e "s/ /\n/g" > ${stgfile}iepg.list
}
# ディレクトリ設定チェック
ckstg=( "${usrdir}" "${stgfile}" "${reclist}" )
for (( i = 0; i < ${#ckstg[@]}; i++ ))
{
  echo ${ckstg[i]} | grep /$ || pusherrmsg 1 ${reclist}
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
  unset mlt sd automlt
  sd=( `echo ${pgid[i]} | sed "s/s/ s/"` )
  mlt=( `echo ${sd[0]} | sed "s/m/ m/"` )
  multi=`echo ${mlt[1]} |sed "s/m//"`
  getiepg ${reclist} ${mlt[0]}
# ファイル処理
  unset data dt tm len nxtm sp atpt
  data=(`iepgex "${reclist}" "${mlt[0]}"`)
  automlt=`mltpgex "${reclist}" "${mlt[0]}" "${data[3]}"`
  atpt=1
  while :
  do
    if [ -z "${data}" ]
    then
# 番組存在しない
      unset data
      data=( `pusherrmsg 5 ${reclist} ${mlt[0]}${mlt[1]}${sd[1]} ${data[6]}` )
      ngid+=( ${mlt[0]}${mlt[1]}${sd[1]} )
      sp="nodata"
      break
    elif [ "${data[1]}${data[2]}${data[3]}" -lt `date +%Y%m%d` ]
    then
# データ古い時
      unset data
      if [ "${atpt}" -eq "4" ]
      then
# 4回目で終了
        data=( `pusherrmsg 7 ${reclist} ${mlt[0]}${mlt[1]}${sd[1]} ${data[6]}` )
        ngid+=( ${mlt[0]}${mlt[1]}${sd[1]} )
        sp="nodata"
        break
      elif [ "${atpt}" -eq "3" ]
      then
        pusherrmsg 8 ${reclist} ${mlt[0]}${mlt[1]}${sd[1]} ${data[6]}
        atpt=$(( ${atpt} + 1 ))
      else
        atpt=$(( ${atpt} + 1 ))
      fi
      lsupdate upd ${stgfile} ${mlt[0]} ${mlt[1]}${sd[1]}
      rm "${reclist}iepg/iepg.php?PID=${mlt[0]}"
      mlt[0]=$(( ${mlt[0]} + 1 ))
      getiepg ${reclist} ${mlt[0]}
      data=(`iepgex "${reclist}" "${mlt[0]}"`)
      automlt=`mltpgex "${reclist}" "${mlt[0]}" "${data[3]}"`
    else
      break
    fi
  done
# 休止確認
  nxtm=( `date -d "${data[1]}${data[2]}${data[3]}" +%s` - `date -d "\`date +%Y%m%d\`" +%s` )
  nxtm=$(( $(( ${nxtm[@]} )) / 86400 ))
  if [ -n "${nxtm}" ]
  then
    if [ "7" -le "${nxtm}" ]
    then
      sp="# "
    fi
  fi
# 抽出データ流し込み
  for (( j = 0; j < ${#data[@]}; j++ ))
  {
    if [ -z "${data[j]}" ]
    then
      pusherrmsg 3 ${reclist}
    fi
    case ${j} in
      0 ) ch=( `cat "${stgfile}ch.list" | grep ${data[j]}` ) ;;
      [4,5] ) tm+=( `date -d ${data[j]} "+%H %M"` ) ;;
      6 ) ttl=${data[j]} ;;
      * ) dt+=${data[j]} ;;
    esac
  }
  if [ -z "${ch[1]}" ]
  then
# 放送局遠い
    ngid+=( ${mlt[0]}${mlt[1]}${sd[1]} )
    sp="nodata"
    pusherrmsg 6 ${reclist} ${mlt[0]}${mlt[1]}${sd[1]} ${data[6]}
  fi
  wk=`date -d ${dt} "+%w"`
# 開始終了時刻確認
  st=`date -d "${dt} ${tm[0]}${tm[1]}" +%s`
  if [ ${tm[0]}${tm[1]} -gt ${tm[2]}${tm[3]} ]
  then
    ed=`date -d "${dt} ${tm[2]}${tm[3]} 1 days" +%s`
  else
    ed=`date -d "${dt} ${tm[2]}${tm[3]}" +%s`
  fi
# 録画時間確認
  len=$(( $(( ${ed} - ${st} )) / 60 ))
  mtlen=${len}
  if [ -n "${automlt}" ]
  then
    len=$(( ${len} * ${automlt} ))
  fi
  if [ ${len} -le 10 ]
  then
    len=$(( ${len} + 1 ))
    stprg=( `date -d "${tm[0]}:${tm[1]} 1 minutes ago" "+%H %M"` )
    tm[0]=${stprg[0]}
    tm[1]=${stprg[1]}
    unset stprg
  else
    len=$(( ${len} - 1 ))
  fi
# 削除判定
  ckdel=`${ub}crontab -l | grep -i "ng$" | grep "${ch[1]}${sd[1]} ${len} \"${ttl}\""`
  if [ -n "${ckdel}" ]
  then
    ngid+=( ${mlt[0]}${mlt[1]}${sd[1]} )
    sp="nodata"
    pusherrmsg 9 ${reclist} ${mlt[0]}${mlt[1]}${sd[1]} ${data[6]}
  fi
# 個別job生成
  case ${sp} in
    nodata ) : > ${reclist}rec/rec${mlt[0]}.list ;;
    * )
      while :
      do
        echo ${sp}${tm[1]} ${tm[0]} '*' '*' ${wk} "${usrdir}rectv.sh" ${ch[1]}${sd[1]} ${len} "\"${ttl}\"" >> ${reclist}rec/rec${mlt[0]}.list
        if [ -n "${multi}" ]
        then
          mltprg=( `date -d "${tm[0]}:${tm[1]} ${mtlen} minutes" "+%H %M"` )
          tm[0]=${mltprg[0]}
          tm[1]=${mltprg[1]}
          unset mltprg
          multi=$(( ${multi} -1 ))
          if [ ${multi} -eq 0 ]
          then
            break
          fi
        else
          break
        fi
      done
    ;;
  esac
}
for (( i = 0; i < ${#ngid[@]}; i++ ))
{
  lsupdate del ${stgfile} ${ngid[i]}
}
# 個別job生成確認
ckjobdata=`cat ${reclist}rec/*.*`
if [ -z "${ckjobdata}" ]
then
  pusherrmsg 4 ${reclist}
else
# job生成
#  cat ${reclist}rec/*.* "${stgfile}routine.list" | ${ub}sort -k 5 > "${reclist}rec.list"
  cat ${reclist}rec/*.* "${stgfile}routine.list" | grep "\* \* \*" | sort -k 2 > "${reclist}rec.list"
  cat ${reclist}rec/*.* "${stgfile}routine.list" | grep "^#" | sort -k 6 >> "${reclist}rec.list"
  for (( i = 0; i < 7; i++ ))
  {
    cat ${reclist}rec/*.* "${stgfile}routine.list" | grep "\* \* ${i}" | sort -k 2 | grep -v "#" >> "${reclist}rec.list"
  }
fi
# crontab登録
${ub}crontab "${reclist}rec.list"
# 作業ファイル削除
rm ${reclist}iepg/*.* ${reclist}rec/*.*
