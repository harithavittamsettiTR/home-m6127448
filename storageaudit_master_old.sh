#!/bin/bash
########
##
#   storageaudit.sh
#
#   script to report on NFS/CIFS volumes in STORAGE-SUPPORT's preferred format.
#   should be as multiplatform as possible, or at least include hooks for it.
#   But keeping it simple.
#
#   Source vfiler, path, mount point, server name, mounted yes/no and configured yes/no
##
#   2016-10-26  init    eric.larmouth@thomsonreuters.com
##  2019-04-10  { Added autofs files handling logic} Bhargav bhargavkumar.nadipalli@thomsonreuters.com
########

##  Three needed components:
##      1) mounted nfs/cifs (easy)
##      2) /etc/fstab nfs/cifs entries (easy)
##      3) autofs nfs/cifs entries (hard)

##  fstab filesystem handling

grep -v '^#' /etc/fstab 2>/dev/null | awk -v MYHN=$(hostname) '(($3=="cifs")||($3=="nfs")){print $1","$2","$3","MYHN",configured-fstab"}' 2>/dev/null | sort | uniq

##  mounted filesystem handling
OS=$(uname -s)
if [[ "$OS" == "Linux" ]]; then
        mount 2>/dev/null | awk -v MYHN=$(hostname) '(($5=="cifs")||($5=="nfs")){print $1","$3","$5","MYHN",mounted"}' 2>/dev/null | sort | uniq
elif [[ "$OS" == "AIX" ]]; then
    	mount | grep 'nfs' | awk -v MYHN=$(hostname) '{print $1":"$2","$3","$4","MYHN",mounted"}' | sort | uniq
fi

##  autofs handling

while read AMDIR AMFIL T; do
    grep -v '^#' "${AMFIL}" 2>/dev/null | awk -v MYHN=$(hostname) -v AMDIR=${AMDIR} '{print $NF","AMDIR"/"$1",nfs,"MYHN",configured-autofs"}' 2>/dev/null | sort | uniq
done <<<"`grep ^/ /etc/auto.master`"

## AIX  autofs handling

if [ -f "/etc/auto_master" ];
then
while read AMDIR AMFIL T; do
    grep -v '^#' "${AMFIL}" 2>/dev/null | awk -v MYHN=$(hostname) -v AMDIR=${AMDIR} '{print $NF","AMDIR"/"$1",nfs,"MYHN",configured-autofs"}' 2>/dev/null | sort | uniq
done <<<"`grep ^/ /etc/auto_master`"
fi

## ##  additional autofs files handling

FILE="/etc/autox.tools"
if [ -f "$FILE" ];
then
   a=$(cat $FILE | grep -i MYAUTOFSFILES | awk -F\" '{print $2}')
   cat $a | awk -v myhn=$(hostname) -v butools="$a" '{print $3",/tools/"$1",nfs,"myhn","butools",configured-BUautofs"}'
fi
