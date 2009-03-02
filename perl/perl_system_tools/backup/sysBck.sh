#! /bin/bash

ADMIN_BASE=/usr/local/sysAdmin
HOST_IP=172.16.0.201
backup_script=${ADMIN_BASE}/${HOST_IP}/sysBackup/sysBck.pl
LOG_DIR=${ADMIN_BASE}/${HOST_IP}/log
LOG_FILE=${LOG_DIR}/sysBackup_`date +"%Y-%m-%d"`.log

exec ${backup_script} all >> $LOG_FILE 2>&1
