#!/bin/bash


#
# Script that does rotating weekly and monthly backups of a source (file or folder).
#
# Usage: backup.sh [-s source] [-f base folder] [-n base filename]
#                  [-w weekly max] [-m monthly max]
#
#        -s Source file or folder that will be gzipped as a backup.
#        -f Base folder where the backups will be saved to.
#        -n Base filename that will be prepended to all backups.
#        -w Retention age (in weeks) after which weekly backups will be rotated.
#        -m Retention age (in weeks) after which monthly backups will be deleted.
#
# The script makes weekly and monthly backups as gzipped files with the
# following format:
#
#  * weekly backups: <base_folder>/<base_filename>_yyyy_mm_dd.gz
#  * monthly backups: <base_folder>/<base_filename>_yyyy_mm.gz
#
# Each time the script is run it checks whether a new weekly backup should be
# made. It does so by looking into the <base_folder> and checking whether
# a file with the appropriate filename exists.
#
# If the last weekly backup found this way is older than one week
# or if no weekly backups exist it proceeds to create a new one with
#
# dd if=<source> | gzip > <base_folder>/<base_filename>_yyy_mm_dd.gz
#
# Then it looks for all existing weekly backups that are older than
# the retention age for weekly backups and makes those weekly backups
# the monthly backup for the month they belong to. This means just changing
# the filename to the appropriate monthly backup filename. Thus that monthly 
# backup for a particular month ends up being the last weekly backup 
# made in that month.
#
# This behaviour makes the script "safe" to run at practically any period
# since new backups will only be created when the last weekly backup is more
# than a week old even if the script is run daily for example.
#
# On each run the script also looks for all existing monthly backups
# that are older than the retention age for monthly backups and removes them.
#
# Default values of parameters
#
#  * -s /dev/mmcblk0
#  * -f . (current folder)
#  * -n backup
#  * -w 4 (weekly backups older than 4 weeks will be rotated to monthly backup)
#  * -m 26 (monthly backups older than 26 weeks will be deleted)
#
# It is up to you to make sure that the user under which the script runs
# has read permissions on the file/folder that is being backedup.
#


SOURCE=/dev/mmcblk0
BASEFOLDER=.
BASENAME=backup
WEEKLY_MAX=4
MONTHLY_MAX=26

DAYSEC=86400
WEEKSEC=$(( $DAYSEC * 7 ))


while getopts ":f:s:n:w:m:" opt
do
    case $opt in
        s)
            SOURCE=$OPTARG
            ;;
        f)
            BASEFOLDER=$OPTARG
            ;;
        n)
            BASENAME=$OPTARG
            ;;
        w)
            WEEKLY_MAX=$OPTARG
            ;;
        m)
            MONTHLY_MAX=$OPTARG
            ;;
        \?)
            printf "invalid option: -%c \n" $OPTARG >&2
            exit 1
            ;;
        :)
            printf "option -%c requires an argument \n" $OPTARG >&2
            exit 1
            ;;
    esac
done


# weekly backups: $BASEFOLDER/$BASENAME_yyyy-mm-dd

# find latest weekly backup
WEEKLY=$(ls $BASEFOLDER | egrep "^$BASENAME\_[0-9]{4}-[0-9]{2}-[0-9]{2}\.gz$" \
        | sed "s:$BASENAME\_::" | sed "s:\.gz$::")

LATEST_WEEKLY=$(echo $WEEKLY | rev | cut -f 1 -d " " | rev)
if [[ $LATEST_WEEKLY ]]
then
    printf "latest weekly backup on %s \n" $LATEST_WEEKLY
fi

# create new weekly backup if necessary
LATEST_WEEKLY_AGE=$(( $(date --date="" +%s) - $(date --date=$LATEST_WEEKLY +%s) ))

# create new if latest weekly is to old or if none exist
if [[ $LATEST_WEEKLY_AGE -ge $WEEKSEC || ! $LATEST_WEEKLY ]]
then
    WEEKLY_NAME=$BASENAME\_$(date --date="" +%F).gz
    printf "creating new weekly backup: %s \n" $WEEKLY_NAME
    dd if=$SOURCE | gzip > $BASEFOLDER/$WEEKLY_NAME
else
    printf "not creating a new backup, latest weekly backup is recent enough \n"
fi


# if there are more weekly backups older than retention maximum promote them to monthly
WEEKLY_AGE_MAX=$(( $WEEKSEC * $WEEKLY_MAX ))

for BACKUP in $WEEKLY
do
    BACKUP_AGE=$(( $(date --date="" +%s) - $(date --date="$BACKUP" +%s) ))
    if [[ $BACKUP_AGE -gt $WEEKLY_AGE_MAX ]]
    then
        WEEKLY_NAME=$BASENAME\_$BACKUP.gz
        MONTHLY_NAME=$BASENAME\_$(echo $BACKUP | sed -r "s:-[0-9]{2}$::").gz
        printf "promoting weekly backup: %s to monthly backup: %s \n" $WEEKLY_NAME $MONTHLY_NAME
        mv $BASEFOLDER/$WEEKLY_NAME $BASEFOLDER/$MONTHLY_NAME
    fi
done


# monthly backups: $BASEFOLDER/$BASENAME_yyyy-mm
MONTHLY=$(ls $BASEFOLDER | egrep "^$BASENAME\_[0-9]{4}-[0-9]{2}\.gz$" \
        | sed "s:$BASENAME\_::" | sed "s:\.gz$::")

# if there are more than $MONTHLY_MAX remove them
MONTHLY_AGE_MAX=$(( $WEEKSEC * $MONTHLY_MAX ))

for BACKUP in $MONTHLY
do
    BACKUP_AGE=$(( $(date --date="" +%s) - $(date --date="$BACKUP-28" +%s) ))
    if [[ $BACKUP_AGE -gt $MONTHLY_AGE_MAX ]]
    then
        MONTHLY_NAME=$BASENAME\_$BACKUP.gz
        printf "removing monthy: %s \n" $MONTHLY_NAME
        rm $BASEFOLDER/$MONTHLY_NAME
    fi
done

