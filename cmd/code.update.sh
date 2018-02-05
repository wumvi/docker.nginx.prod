#!/bin/bash

while getopts p:r:f: opts; do
   case ${opts} in
      f) ZIP_FILE=${OPTARG} ;;
      p) PROJECT_NAME=${OPTARG} ;;
      r) REF=${OPTARG} ;;
   esac
done

if [ -z $PROJECT_NAME ]
then
	echo Error: Option -p not found
	exit 1
fi

if [ -z $ZIP_FILE ]
then
	echo Error: Option -f not found
	exit 9
fi

if [ -z $REF ]
then
	echo Error: Option -r not found
	exit 10
fi

if [ ! -r $ZIP_FILE ]
then
	echo Error: File $ZIP_FILE not found
	exit 2
fi

PROJECT_FOLDER=/www/$PROJECT_NAME/$REF/
mkdir -p $PROJECT_FOLDER
if [ ! $? -eq 0 ]
then
	echo Error: Can not create folder $PROJECT_FOLDER
	exit 3
fi

unzip -o -q $ZIP_FILE -d $PROJECT_FOLDER
if [ ! $? -eq 0 ]
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

export PROJECT_PREFIX=$PROJECT_NAME/$REF
envsubst < $TPL_NAME > $CONFIG_NAME

nginx -t
if [ ! $? -eq 0 ]
then
	rm $CONFIG_NAME
	[ -r $BACKUP_CONFIG_NAME ] && mv $BACKUP_CONFIG_NAME $CONFIG_NAME
	echo Bad template $TPL_NAME
	exit 6
fi

nginx -s reload
if [ ! $? -eq 0 ]
then
	rm $CONFIG_NAME
	[ -r $BACKUP_CONFIG_NAME ] && mv $BACKUP_CONFIG_NAME $CONFIG_NAME
	echo Error during restarting nginx
	exit 7
fi

[ -r $BACKUP_CONFIG_NAME ] && rm $BACKUP_CONFIG_NAME
a
LAST_REF_FOLDER=/www/run/$PROJECT_NAME/
LAST_REF_FILE=$LAST_REF_FOLDER/current.txt
if [ -r $LAST_REF_FILE ]
then
	OLD_REF=`cat $LAST_REF_FILE`
	if [ ! -z $OLD_REF ] && [ $OLD_REF != $REF ]
	then
		rm -rf /www/$PROJECT_NAME/$OLD_REF/
	fi
	
fi

mkdir -p $LAST_REF_FOLDER
echo $REF > $LAST_REF_FILE

exit $?