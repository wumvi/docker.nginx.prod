#!/bin/bash

while getopts p:r:f: opts; do
   case ${opts} in
      f) ZIP_FILE=${OPTARG} ;;
      p) export PROJECT_NAME=${OPTARG} ;;
      r) REF=${OPTARG} ;;
   esac
done

if [ -z $PROJECT_NAME ]
then
	echo Error: Option -p not found
	exit 1
fi

if [ ! -r $ZIP_FILE ]
then
	echo Error: File $ZIP_FILE not found
	exit 2
fi

PROJECT_FOLDER=/www/$PROJECT_NAME/
mkdir -p $PROJECT_FOLDER
if [ $? -eq 0 ]
then
	echo Error: Can not create folder $PROJECT_FOLDER
	exit 3
fi

unzip $ZIP_FILE -d $PROJECT_FOLDER
if [ $? -eq 0 ]
then
	echo Error: Can not unzip file $ZIP_FILE
	exit 4
fi

TPL_NAME=$PROJECT_FOLDER/prod/nginx.conf
if [ ! -r $TPL_NAME ]
then
	echo Error: template $TPL_NAME not found
	exit 5
fi

CONFIG_NAME=/www/conf/$PROJECT_NAME.conf
BACKUP_CONFIG_NAME=/tmp/$PROJECT_NAME.conf.bck
if [ -r $CONFIG_NAME ]
then
	mv $CONFIG_NAME $BACKUP_CONFIG_NAME
fi

envsubst < $TPL_NAME > $CONFIG_NAME

nginx -t
if [ $? -eq 0 ]
then
	rm $CONFIG_NAME
	[ -r $BACKUP_CONFIG_NAME ] && mv $BACKUP_CONFIG_NAME $CONFIG_NAME
	echo Bad template $TPL_NAME
	exit 6
fi

nginx -s reload

if [ $? -eq 0 ]
then
	rm $CONFIG_NAME
	[ -r $BACKUP_CONFIG_NAME ] && mv $BACKUP_CONFIG_NAME $CONFIG_NAME
	echo Error during restarting nginx
	exit 7
fi

[ -r $BACKUP_CONFIG_NAME ] && rm $BACKUP_CONFIG_NAME
exit $?
