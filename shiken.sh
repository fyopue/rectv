#!/bin/bash
# prefix
#usrdir="/home/`/usr/bin/whoami`/"
usrdir="`dirname ${0}`/"
stgfile="${usrdir}recstg/"
echo ${usrdir} ${stgfile} | sed "s/ /\n/g" > /tmp/shiken.log
