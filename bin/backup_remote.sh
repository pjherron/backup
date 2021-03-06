#!/bin/bash
##########################################################
# Disk backup script
# Backs up local OSX system to remote system via rsync+ssh
# Performs snapshots
#
# THANKS TO (sources)
#   - http://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync/ (great example script)
#   - http://www.mtmckenna.com/posts/2011/11/26/incremental-backup-rsync-ssh/ (fuller implementation)
#   - http://bit.ly/1eF1pTP (info from bombich on exclusions for OSX systems)
#   - http://linuxproblem.org/art_9.html (ssh auto login details)
#   - http://repoforge.org/use/ (setting up repoforge in order to install keychain on Linux)
#   - http://www.cyberciti.biz/faq/ssh-passwordless-login-with-keychain-for-scripts/ (more keychain)
#   - http://crunchtools.com/ssh-keychain/ (helpful for linux keychain setup)
#   - http://blog.interlinked.org/tutorials/rsync_time_machine.html (performing snapshots)
##########################################################

# USER-SPECIFIC VARS: USER MUST MODIFY DESTINATION INFORMATION
# HOME=path to user home # may be necessary if running as root
DUNAME="dstadminuname" # remote system user name
DADD="10.1.0.0" # destintion IP or host name
DDIR="/ABS/PATH/TO/BACKUP/DEST"  # REMOTEPATH
LOGGER="/usr/bin/logger"  #always check your system for where the logger app is
SRC="/" # LOCALPATH; do not end with '/' unless starting from root directory
BUPHOME="$HOME/bin" # probably does not need changing
LOGHOME="$HOME/backuplogs"  #customize name of dir if system needs >1 backups
EXCLUDEFILE="1"  # only if using an exclude file
EXCLUDEF="$BUPHOME/backup_excludes.txt"  #default; can use yr own name

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
# TODO: configure for cron

##  SELECTED SIMPLE RSYNC OPTIONS FOR OSX SRC
# -A,   --acls                  update the destination ACLs to be the same as the source ACLs
# -a,   --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
# -E,   --executability         preserve executability
# -H,   --hard-links            preserve hard-links
# -i,   --itemize-changes       output a change-summary for all updates
# -v    --verbose               increase verbosity
# -x,   --one-file-system       don't cross device boundaries (ignore mounted volumes)
# -X,   --xattrs                preserve extended attributes
##  SELECTED SIMPLE RSYNC OPTIONS W/O SHORTHAND
#       --delete-excluded       delete any files (on DST) that are part of the list of excluded files
#       --fake-super            store/recover privileged attrs using xattrs
#       --partial               keep partially transferred files
## AND OPTIONS THAT NEED ADDED ARGS
#       --exclude=PATTERN       exclude files matching PATTERN
#       --exclude-from=FILE     reference a list of files to exclude
# -e,                           ssh

# STANDARD VARS #
TS=`date +'%Y%m%d%H%M%S'` # time stamp
DST="$DUNAME@$DADD:$DDIR/incomplete_back-${TS}"
LOG="$LOGHOME/$TS.log"
PROG=$0
# if user indicates an exclude file
if (($EXCLUDEFILE==1))
then 
    OPTS="-AaEHixX --delete --delete-excluded --fake-super --force --partial --link-dest=$DDIR/current --exclude-from=$EXCLUDEF -e ssh"
else 
    OPTS="-AaEHixX --delete --delete-excluded --fake-super --force --partial --link-dest=$DDIR/current -e ssh"
fi  
# begin
printf "starting backup process\n"
printf "logging to: \n$LOG\n\n"
mkdir -p $LOGHOME # create log directory if it does not exist
# check if can read SRC
if [ ! -r "$SRC" ]; then
    $LOGGER -t $PROG "Source $SRC not readable - Cannot start the sync process"
    exit;
fi
$LOGGER -t $PROG "Start rsync"
printf "starting Backup\n"
source ${HOME}/.keychain/${HOSTNAME}-sh
echo "FULL RUN"
rsync $OPTS $SRC $DST >> $LOG 2>&1 
ssh $DUNAME@$DADD "mv ${DDIR}/incomplete_back-${TS} ${DDIR}/back-${TS} && rm -f ${DDIR}/current && ln -s back-${TS} ${DDIR}/current"  
# ending
printf "completing Backup\n"
$LOGGER -t $PROG "End rsync"
printf "completed backup process\n"
printf "please inspect logfiles at: \n$LOG\n\n"
printf "exiting\n"

exit 0
