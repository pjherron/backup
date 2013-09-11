#!/bin/bash

##########################################################
# Disk backup script
# Backs up local OSX system to remote system via rsync+ssh
##########################################################

# Preconditions
# Assumes rsync 3 and ssh on source and destination systems
# Assumes local (sender) installation/operation
# Assumes RSA key aleady accepted
# Assumes sshkeychain & xcode installed (done with macport)

# THANKS TO (sources)
# http://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync/
# http://www.mtmckenna.com/posts/2011/11/26/incremental-backup-rsync-ssh/
# http://bit.ly/1eF1pTP

## LOCAL AUTHENTICATION
# TODO: replace auth proc
# TODO: configure for cron
# TODO: replace the sudo pw prompt

# IMPORTANT: Make sure you update the `DST` variable to match the name of the
# destination backup drive

# TODO: put vars into config file
# TODO: option for initial or incremental, dry run true or false (-n)
# VARS #

BUPHOME="$HOME/bin"
LOGHOME="$HOME/backuplogs"
TS=`date +'%Y%m%d%H%M'` # time stamp
LOG="$LOGHOME/$TS.log"
SRC="/" # LOCALPATH
# DST="/Volumes/Macintosh HD/"
DUNAME="adminuser"
DADD="10.1.0.0" # destintion IP or host name
DDIR="/ABS/PATH/TO/BACKUP/DEST/"  # REMOTEPATH
DST="$DUNAME@$DADD:$DDIR"
EXCLUDE="$BUPHOME/backup_excludes.txt"

PROG=$0
OPTS="-AaEHixPvX -del --delete-excluded --fake-super -exclude-from=$EXCLUDE -e ssh"

##  SELECTED SIMPLE RSYNC OPTIONS WITH SHORTHAND
# -A,   --acls                  update the destination ACLs to be the same as the source ACLs
# -a,   --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
# -E,   --executability         preserve executability
# -del, --delete-during         receiver deletes during the transfer
# -H,   --hard-links            preserve hard-links
# -i,   --itemize-changes       output a change-summary for all updates
# -x,   --one-file-system       don't cross device boundaries (ignore mounted volumes)
#       --partial               keep partially transferred files
#       --progress              show progress during transfer
# -P    (same as --partial --progress)
# -v    --verbose               increase verbosity
# -X,   --xattrs                preserve extended attributes
##  SELECTED SIMPLE RSYNC OPTIONS W/O SHORTHAND
#       --delete-excluded       delete any files (on DST) that are part of the list of excluded files
#       --fake-super            store/recover privileged attrs using xattrs
## AND OPTIONS THAT NEED ADDED ARGS
#       --exclude-from=FILE     reference a list of files to exclude
# -e,                           ssh

printf "starting backup process\n"

if [ ! -r "$SRC" ]; then
    logger -t $PROG "Source $SRC not readable - Cannot start the sync process"
    exit;
fi

## probably does not work
# if [ ! -w "$DST" ]; then
#     logger -t $PROG "Destination $DST not writeable - Cannot start the sync process"
#     exit;
# fi

$LOGGER -t $PROG "Start rsync"
printf "starting Backup\n"

sudo rsync $OPTS  $SRC $DST >> $LOG

printf "completing Backup\n"
logger -t $PROG "End rsync"
printf "completed backup process\n"

## Make the backup bootable
# TODO: Make operable on remote system
# sudo bless -folder "$DST"/System/Library/CoreServices

exit 0
