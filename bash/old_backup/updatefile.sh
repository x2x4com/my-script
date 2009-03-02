#!/bin/bash

##
## Auto update file to tomcat or crontab
##
## Useage: scriptname zipfile [backup] [restart] [Tomcat_Home=xxx]
##
## Jacky.Xu
##
## 1 is yes; 0 is no

useage (){
echo "  Help from `basename $0`"
echo "  Error, No parameter or bad file name"
echo "  ========================================================================"
echo "  Useage: `basename $0` YYYYMMDD_target_updatenumber [backup|no_bakup] [restart] [Tomcat_Home=Directory]"
echo 
echo "  target: must setup to ${WEBSITE_LIST[*]}"
# for x in ${WEBSITE_LIST}
# do
# echo -n "[${x}] "
# done
# unset x
# echo 
echo 
echo "  Optional parameters:"
echo "  backup | no_backup -- Auto | Not backup file which in zipfile [Default is yes]"
echo "  restart -- Auto restart tomcat [Default is no]"
echo "  Tomcat_Home -- Give Tomcat Home to script [Default is /usr/local]"
echo "  ========================================================================"
echo
}

testupdatetarget(){
if [ ${TARGET_OK} -ne 1 ]
then
echo "  --------------------------------------------------------"
echo "  Error: unknow or wrong update target"
echo "  Make sure your file name is YYYYMMDD_target_updatenumber"
echo "  --------------------------------------------------------"
echo 
useage
exit ${EXT_NO_PART}
fi
}

notdir(){
echo "  --------------------------------------------------------"
echo "  Error: ${NOT_DIR[@]} not a dirctory!"
echo "  Wrong dirctory format"
echo "  --------------------------------------------------------"
exit ${EXT_NO_PART}
}


unzipfile (){
cd $FILE_PWD
if [ ! -r ${ZIPFILE} ]
then
echo "  Error ${ZIPFILE} not find"
exit ${EXT_NO_PART}
fi
if [ -d ${UPDATE_HOME}/update/${UPDATE_TARGET}/${UPDATE_DIR} ]
then
echo "  --------------------------------------------------------"
echo "  Error: ${UPDATE_HOME}/update/${UPDATE_TARGET}/${UPDATE_DIR} exist!"
echo "  --------------------------------------------------------"
exit ${EXT_NO_PART}
fi
echo "  Unzip ${ZIPFILE} now ..."
echo 
/usr/bin/unzip ${ZIPFILE} -d /tmp
if [ ${?} -ne 0 ]
then
echo 
echo "  --------------------------------------------------------"
echo "  Error: can't unzip ${ZIPFILE}..."
echo "  `/usr/bin/file ${ZIPFILE}`"
echo "  Please make sure ${ZIPFILE} is a vaild ZIP file"
echo "  --------------------------------------------------------"
exit ${EXT_NO_PART}
fi
echo 
echo "  Move /tmp/${DIR_IN_TEMP} to ${UPDATE_HOME}/update/${UPDATE_TARGET}  and rename it to${UPDATE_DIR}"
echo
mv -f /tmp/${DIR_IN_TEMP} ${UPDATE_HOME}/update/${UPDATE_TARGET}/${UPDATE_DIR}
if [ ${?} -ne 0 ]
then
echo 
echo "  --------------------------------------------------------"
echo "  Error: can't move /tmp/${DIR_IN_TEMP} to ${UPDATE_HOME}/update/${UPDATE_TARGET}/${UPDATE_DIR}"
echo "  --------------------------------------------------------"
exit ${EXT_NO_PART}
fi
if [ -d ${UPDATE_HOME}/update/${UPDATE_TARGET}/${UPDATE_DIR} ]
then
return 5
fi
}

getupdatelist() {
cd ${UPDATE_HOME}/update/${UPDATE_TARGET}/${UPDATE_DIR}
DIR_LIST=(`ls`)
##  echo ${#DIR_LIST[*]}
array_start=0
##  ${#DIR_LIST[*]} number of array here is 3
while [ ${array_start} -lt ${#DIR_LIST[*]} ]
do
##  echo ${DIR_LIST[${array_start}]}
if [ ! -d ${DIR_LIST[${array_start}]} ]
then
NOT_DIR[${array_start}]=${DIR_LIST[${array_start}]}
fi
let array_start=${array_start}+1
done
if [ ${#NOT_DIR[@]} -ne 0 ]
then
notdir
fi
}

confrim() {
echo 
}


EXT_NO_PART=65
WEBSITE_LIST=(livebytouch paybyfinger crontab)
TARGET_HOME_ARRAY=(/usr/local/tomcat/tomcat /usr/local/paybyfinger/tomcat /usr/local/lbt)
UPDATE_HOME=/home/jacky/share
PWD_NOW=`pwd`

if [ ${#} -lt 1 ]
then
useage
exit ${EXT_NO_PART}
fi

#{
##  Get Args ###
ZIPFILE=${1}
echo "ZIPFILE=${ZIPFILE}"
DIR_IN_TEMP=`echo ${1} | cut -d . -f 1 `
echo DIR_IN_TEMP=${DIR_IN_TEMP}
UPDATE_DIR=`echo ${DIR_IN_TEMP} | cut -d _ -f 1`_`echo ${DIR_IN_TEMP} | cut -d . -f 1 | cut -d _ -f 3`
echo UPDATE_DIR=${UPDATE_DIR}
UPDATE_TARGET=`echo ${DIR_IN_TEMP} | cut -d _ -f 2`
echo UPDATE_TARGET=${UPDATE_TARGET}
TARGET_OK=0

## Get ZIPFILE Dir ###
PWD_NOW=`pwd`
FILE_PWD=(`echo $ZIPFILE | sed -e "s/\//\ /g"`) 
echo FILE_PWD=${FILE_PWD}
FILE_DIR_NUM=${#FILE_PWD[@]}
echo FILE_DIR_NUM=${#FILE_PWD[@]}
if [ ${FILE_DIR_NUM} -le 0 ]
then
ZIPFILE=${ZIPFILE}
echo FILE_DIR_NUM is ${FILE_DIR_NUM}
fi
let FILE_DIR_NUM=${FILE_DIR_NUM}-1
file_dir_start=0
echo file_dir_start=${file_dir_start}
if [ "${FILE_PWD[0]}" != '..' ]
then
cd /
echo pwd is /
fi

while [ ${file_dir_start} -lt ${FILE_DIR_NUM} ]
do
cd ${FILE_PWD[${file_dir_start}]}
if [ ${?} -ne 0 ]
then
notdir
fi
echo `pwd`
let file_dir_start=${file_dir_start}+1
echo file_dir_start=${file_dir_start}
done
FILE_PWD=`pwd`
echo `pwd`
cd ${PWD_NOW}
echo `pwd`

## make sure website is vaild
WEBSITE_LIST_NUMBER=${#WEBSITE_LIST[@]}
echo WEBSITE_LIST_NUMBER=${#WEBSITE_LIST[@]}
website_array_start=0
while [ ${website_array_start} -lt ${#WEBSITE_LIST[@]} ]
do
if [ "${UPDATE_TARGET}" = ${WEBSITE_LIST[${website_array_start}]} ]
then
TARGET_HOME=${TARGET_HOME_ARRAY[${website_array_start}]}
echo TARGET_HOME=${TARGET_HOME_ARRAY[${website_array_start}]}
TARGET_OK=1
break
fi
let website_array_start=${website_array_start}+1
done

echo TARGET_OK=${TARGET_OK}
#} >> /dev/null

testupdatetarget

DEFAULT_BAK="1"
DEFAULT_RESTART="0"
{
shift 1
if [ "${1}" = "no_backup" ]
then
BACKUP_SOURCE=0
else
BACKUP_SOURCE=1
fi
echo BACKUP_SOURCE=${BACKUP_SOURCE}
shift 1
if [ "${1}" = "restart" ]
then
RESTART_TOMCAT=1
else
RESTART_TOMCAT=0
fi
echo RESTART_TOMCAT=${RESTART_TOMCAT}
shift 1
TC_HOME=`echo ${1} | cut -d = -f 1`
echo TC_HOME=${TC_HOME}
TC_HOME=${TC_HOME:-$TARGET_HOME}
echo TC_HOME=${TC_HOME}
} >> /dev/null
if [ ! -d ${TC_HOME} ]
then
TC_HOME=${TARGET_HOME}
echo "  Warning - Bad TC_HOME, Auto setup to ${TC_HOME}"
fi

#unzipfile
#getupdatelist
