# odroid-xu-backup

The purpose of this was to make backups of the SD card on my Odroid XU4 development board but the script is general enough to be used whenever one wants to make weekly/monthly rotating backups of a file/folder.


## backup

The [backup.sh](https://github.com/kstrnisa/odroid-xu-backup/blob/master/backup.sh) shell script makes rotating weekly and monthly backups of a source (file or folder).

It makes weekly and monthly backups as gzipped files with the following format:

 * weekly backups: <base_folder>/<base_filename>_yyyy_mm_dd.gz
 * monthly backups: <base_folder>/<base_filename>_yyyy_mm.gz

Each time the script is run it checks whether a new weekly backup should be made. It does so by looking into the <base_folder> and checking whether a file with the appropriate filename exists.

If the last weekly backup found this way is older than one week or if no weekly backups exist it proceeds to create a new one with

```
dd if=<source> | gzip > <base_folder>/<base_filename>_yyy_mm_dd.gz
```

Then it looks for all existing weekly backups that are older than the retention age for weekly backups and makes those weekly backups the monthly backup for the month they belong to. This means just changing the filename to the appropriate monthly backup filename. Thus that monthly backup for a particular month ends up being the last weekly backup made in that month.

This behaviour makes the script "safe" to run at practically any period since new backups will only be created when the last weekly backup is more than a week old even if the script is run daily for example.

On each run the script also looks for all existing monthly backups that are older than the retention age for monthly backups and removes them.

It is up to you to make sure that the user under which the script runs has read permissions on the file/folder that is being backedup.


usage 

```
backup.sh [-s source] [-f base folder] [-n base filename] [-w weekly max] [-m monthly max]

        -s Source file or folder that will be gzipped as a backup.
        -f Base folder where the backups will be saved to.
        -n Base filename that will be prepended to all backups.
        -w Retention age (in weeks) after which weekly backups will be rotated.
        -m Retention age (in weeks) after which monthly backups will be deleted.
```

Default values of parameters

 * -s /dev/mmcblk0
 * -f . (current folder)
 * -n backup
 * -w 4 (weekly backups older than 4 weeks will be rotated to monthly backup)
 * -m 26 (monthly backups older than 26 weeks will be deleted)


