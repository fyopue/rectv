#!/bin/bash

cd "/filedir/daily/"
dt=`date +%Y%m%d%H`
/usr/bin/crontab -l > "tablog${dt}.txt"
fl=`ls | wc -l`
fn="${1}"
if [ -z "${fn}" ]
then
  fn="10"
fi
if [ ${fl} -gt ${fn} ]
then
  rmf=$(( ${fl} - ${fn} ))
  rm `ls | head -${rmf}`
fi
