#!/bin/bash

if [ -z "$WEBAPPS_URL" ]; then
	echo >&2 '请设置$WEBAPPS_URL环境变量 '
	exit 1
fi

if [ -z "$DIST_URL" ]; then
        echo >&2 '请设置$DIST_URL环境变量 '
        exit 1
fi

WEBAPPS_DIR=/usr/local/tomcat/webapps
JUSTEP_HOME=/usr/local/x5

cd $WEBAPPS_DIR
rm -rf baas*.*
rm -rf x5*.*
curl $WEBAPPS_URL/x5.war -o $WEBAPPS_DIR/x5.war
curl $WEBAPPS_URL/baas.war -o $WEBAPPS_DIR/baas.war

cd $JUSTEP_HOME
rm -rf model*.*
rm -rf sql*.*
curl $DIST_URL/model.tar.gz -o $JUSTEP_HOME/model.tar.gz
curl $DIST_URL/sql.tar.gz -o $JUSTEP_HOME/sql.tar.gz
mkdir model
tar -xvf model.tar.gz -C model/
mkdir sql
tar -xvf sql.tar.gz -C/ sql/

# todo: init database

