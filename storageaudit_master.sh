#!/bin/bash
########
##
#   storageaudit_master.sh
#
#   should be as multiplatform as possible, or at least include hooks for it.
#   But keeping it simple.
#
#   Source vfiler, path, mount point, server name, mounted yes/no and configured yes/no
##
#   2016-10-26  init    eric.larmouth@thomsonreuters.com
#   2019-04-10  { Added autofs files handling logic} Bhargav bhargavkumar.nadipalli@thomsonreuters.com
#   2025-03-02  {Added logic to make compatible for solaris servers} haritha.vittamsetti@thomsonreuters.com
#   2025-07-25  {Added logic for Solaris servers} haritha.vittamsetti@thomsonreuters.com
########

OS=$(uname -s)

## fstab filesystem handling
if [[ "$OS" == "Linux" ]]; then
    grep -v '^#' /etc/fstab 2>/dev/null | awk -v MYHN=$(hostname) '(($3=="cifs")||($3=="nfs")){print $1","$2","$3","MYHN",configured-fstab"}' | sort | uniq
elif [[ "$OS" == "SunOS" ]]; then
    if [[ -x "/infra_unixsvcs/unix-support/bin/solaris_nfs_audit.sh" ]]; then
        /infra_unixsvcs/unix-support/bin/solaris_nfs_audit.sh
    else
        echo "Warning: /infra_unixsvcs/unix-support/bin/solaris_nfs_audit.sh not found or not executable." >&2
    fi
    # Also process vfstab for SunOS
    grep -v '^#' /etc/vfstab 2>/dev/null | nawk -v MYHN=$(hostname) '(($3=="cifs")||($3=="nfs")){print $1","$2","$3","MYHN",configured-fstab"}' | sort | uniq
elif [[ "$OS" == "AIX" ]]; then
    grep -v '^#' /etc/fstab 2>/dev/null | awk -v MYHN=$(hostname) '(($3=="cifs")||($3=="nfs")){print $1","$2","$3","MYHN",configured-fstab"}' | sort | uniq
fi

## mounted filesystem handling
if [[ "$OS" == "Linux" ]]; then
    mount 2>/dev/null | awk -v MYHN=$(hostname) '(($5=="cifs")||($5=="nfs")){print $1","$3","$5","MYHN",mounted"}' | sort | uniq
elif [[ "$OS" == "SunOS" ]]; then
    cat /etc/mnttab | grep -i nfs | nawk -v MYHN=$(hostname) '{print $1":"$2","$3","$4","MYHN",mounted"}' | sort | uniq
elif [[ "$OS" == "AIX" ]]; then
    mount | grep 'nfs' | awk -v MYHN=$(hostname) '{print $1":"$2","$3","$4","MYHN",mounted"}' | sort | uniq
fi

## autofs handling for Linux
if [[ "$OS" == "Linux" ]]; then
    if [[ -f "/etc/auto.master" ]]; then
        while read AMDIR AMFIL T; do
            grep -v '^#' "${AMFIL}" 2>/dev/null | awk -v MYHN=$(hostname) -v AMDIR=${AMDIR} '{print $NF","AMDIR"/"$1",nfs,"MYHN",configured-autofs"}' 2>/dev/null | sort | uniq
        done < <(grep ^/ /etc/auto.master)
    fi
fi

## autofs handling for Solaris
if [[ "$OS" == "SunOS" ]]; then
    if [[ -f "/etc/auto_master" ]]; then
        grep ^/ /etc/auto_master | while read AMDIR AMFIL T; do
            if [[ -n "$AMFIL" && -f "$AMFIL" ]]; then
                grep -v '^#' "$AMFIL" 2>/dev/null | nawk -v MYHN=$(hostname) -v AMDIR="$AMDIR" '{print $NF","AMDIR"/"$1",nfs,"MYHN",configured-autofs"}' | sort | uniq
            fi
        done
    else
        echo "/etc/auto_master does not exist." >&2
    fi
fi

## AIX autofs handling
if [[ "$OS" == "AIX" ]]; then
    if [[ -f "/etc/auto_master" ]]; then
        grep ^/ /etc/auto_master | while read AMDIR AMFIL T; do
            if [[ -n "$AMFIL" && -f "$AMFIL" ]]; then
                grep -v '^#' "${AMFIL}" 2>/dev/null | awk -v MYHN=$(hostname) -v AMDIR=${AMDIR} '{print $NF","AMDIR"/"$1",nfs,"MYHN",configured-autofs"}' | sort | uniq
            fi
        done
    fi
fi

## BU autofs handling for Linux
FILE="/etc/autox.tools"
if [[ "$OS" == "Linux" ]]; then
    if [[ -f "$FILE" ]]; then
        a=$(grep -i MYAUTOFSFILES "$FILE" | awk -F\" '{print $2}')
        if [[ -n "$a" && -f "$a" ]]; then
            cat "$a" | awk -v myhn=$(hostname) -v butools="$a" '{print $3",/tools/"$1",nfs,"myhn","butools",configured-BUautofs"}'
        fi
    fi
fi

