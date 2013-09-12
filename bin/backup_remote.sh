#!/bin/bash

# TODO: put vars into config file
# USER-SPECIFIC VARS: USER MUST MODIFY DESTINATION INFORMATION
TEST=1 # activates -n switch on rsync; 0 if full run
DUNAME="dstadminuname"
DADD="10.1.0.0" # destintion IP or host name
DDIR="/ABS/PATH/TO/BACKUP/DEST/"  # REMOTEPATH
LOGGER="/usr/bin/logger"

##########################################################
# Disk backup script
# Backs up local OSX system to remote system via rsync+ssh
# 
# THANKS TO (sources)
#   - http://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync/ (great example script)
#   - http://www.mtmckenna.com/posts/2011/11/26/incremental-backup-rsync-ssh/ (fuller implementation)
#   - http://bit.ly/1eF1pTP (info from bombich on exclusions for OSX systems)
#   - http://linuxproblem.org/art_9.html (ssh auto login details)
#   - http://repoforge.org/use/ (setting up repoforge in order to install keychain on Linux)
#   - http://www.cyberciti.biz/faq/ssh-passwordless-login-with-keychain-for-scripts/ (more keychain)
#   - http://crunchtools.com/ssh-keychain/ (helpful for linux keychain setup)
##########################################################

##########################################################
# Preconditions
#      - rsync 3 and ssh on source and destination systems
#      - RSA key aleady accepted 
#      - ssh authentication keys set up SRC to DST
#      - sshkeychain installed on SRC (OSX src) or keychain (Linux src)
#      - IMPORTANT: keychain installed to /opt/local/bin not /usr/local/bin
#      - for OSX, xcode installed (done with macport)
#      - local (sender) installation/operation
#      - SRC is local file system being backed up to DST
#      - $HOME/bin directory containing backup_excludes.txt
#      - rsync options string currently assumes SRC is OSX
##########################################################
# Postconditions
#      - system backs up to path specified by user at destination system
#      - backup is not quite bootable (needs 'bless')
#      - logs backup in two places: to sys logs and to logfiles in $HOME/backuplogs
##########################################################

## LOCAL AUTHENTICATION
# TODO: replace auth proc
# TODO: configure for cron
# TODO: replace the sudo pw prompt
# TODO: option for initial or incremental, dry run true or false (-n)

##  SELECTED SIMPLE RSYNC OPTIONS FOR OSX SRC
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

# STANDARD VARS #
DST="$DUNAME@$DADD:$DDIR"
EXCLUDE="$BUPHOME/backup_excludes.txt"
BUPHOME="$HOME/bin"
LOGHOME="$HOME/backuplogs"
TS=`date +'%Y%m%d%H%M'` # time stamp
LOG="$LOGHOME/$TS.log"
SRC="/" # LOCALPATH; should not be changed
PROG=$0
# TODO: determine if OPTS string works on Linux as well as OSX; if not make second OPTS var
OPTS="-AaEHixPvX -del --delete-excluded --fake-super -exclude-from=$EXCLUDE -e ssh"

printf "starting backup process\n"
printf "logging to: \n$LOG\n\n"

# create log directory if it does not exist
mkdir -p $LOGHOME

## http://stackoverflow.com/questions/185451/quick-and-dirty-way-to-ensure-only-one-instance-of-a-shell-script-is-running-at-a
## http://blog.interlinked.org/tutorials/rsync_time_machine.html
# LOCKFILE=${HOME}/temp/lock.txt
# if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
#     echo "already running"
#     exit
# fi

## make sure the lockfile is removed when we exit and then claim it
# trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
# echo $$ > ${LOCKFILE}

# check if can read SRC
if [ ! -r "$SRC" ]; then
    $LOGGER -t $PROG "Source $SRC not readable - Cannot start the sync process"
    exit;
fi

## TODO: fix to work on remote; probably does not work
# if [ ! -w "$DST" ]; then
#     $LOGGER -t $PROG "Destination $DST not writeable - Cannot start the sync process"
#     exit;
# fi

$LOGGER -t $PROG "Start rsync"
printf "starting Backup\n"
source ${HOME}/.keychain/${HOSTNAME}-sh
if (($TEST == 1))
then 
    echo "TESTING ONLY"
    rsync $OPTS -n $SRC $DST >> $LOG 2>&1
else
    echo "FULL RUN"
    rsync $OPTS $SRC $DST >> $LOG 2>&1
fi
# TODO: Make the backup bootable on remote system; this works for local system
# sudo bless -folder "$DST"/System/Library/CoreServices
printf "completing Backup\n"
$LOGGER -t $PROG "End rsync"
printf "completed backup process\n"
printf "please inspect logfiles at: \n$LOG\n\n"
printf "exiting\n"

#rm -f ${LOCKFILE}

exit 0
