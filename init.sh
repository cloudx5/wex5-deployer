#!/bin/bash
start=`expr \`date +%s%N\` / 1000000`

source `dirname $0`/common.sh
echo "用户资源ID: $1"
export DIST_URL=$DIST_URL/$1

PROJECT_CONF_PATH=`dirname $0`/project.conf

curl -s -f $DIST_URL/home/project.conf -o $PROJECT_CONF_PATH

while read line
do
  #echo $line
  if [ -z "$line" ]; then
   continue
  fi
  kv=(${line//=/ })
  #echo $kv
  case ${kv[0]} in
    "api_key")
      API_KEY=${kv[1]}
      echo "$API_KEY"
      ;;
    "api_secret")
      API_SECRET=${kv[1]}
      #echo "$API_SECRET"
      ;;
    "index_url")
      INDEX_URL=${kv[1]}
      #echo "$API_SECRET"
      ;;
    [a-z]*_srvinit)
      #SRV_INIT_ARR=(${SRV_INIT_ARR[@]} $kv)
      #echo $kv
      SRV_INIT_ARR="$SRV_INIT_ARR,$line"
      ;;
    *)
      #echo "ignore: ${kv}"
      ;;
  esac
done < $PROJECT_CONF_PATH



if [ -z "$DIST_URL" ]; then
  error '请设置$DIST_URL环境变量 ' 1
fi

prepare=`expr \`date +%s%N\` / 1000000`
echo "耗时$[ prepare - start ]毫秒"

echo "正在初始化网关..."
source `dirname $0`/init-gateway.sh
echo "初始化网关完毕."

gateway=`expr \`date +%s%N\` / 1000000`
echo "耗时$[ gateway - prepare ]毫秒"

echo "正在初始化公共服务..."
source `dirname $0`/init-service.sh
echo "初始化公共服务完毕."

cmnsrv=`expr \`date +%s%N\` / 1000000`
echo "耗时$[ cmnsrv - gateway ]毫秒"


cd $JUSTEP_HOME

echo "正在更新用户资源..."
curl -s -f $X5_URL/$UPDATE_HOME_USER_SH -o $UPDATE_HOME_USER_SH
ERROR=$?
if [ "$ERROR" -eq "0" ]; then
  chmod a+x $UPDATE_HOME_USER_SH
  source $UPDATE_HOME_USER_SH
else
  echo "  无更新规则，跳过更新"
fi
echo "更新用户资源完毕"

usrsrc=`expr \`date +%s%N\` / 1000000`
echo "耗时$[ usrsrc - cmnsrv ]毫秒"

# webapps资源更新后再更新，避免相关资源未准备而访问错误

cd $WEBAPPS_DIR

echo "正在更新$X5_NAME运行时..."
curl -s -f $X5_URL/$UPDATE_WEBAPPS_USER_SH -o $UPDATE_WEBAPPS_USER_SH
ERROR=$?
if [ "$ERROR" -eq "0" ]; then
  chmod a+x $UPDATE_WEBAPPS_USER_SH
  source $UPDATE_WEBAPPS_USER_SH
else
  if [ -n "$INDEX_URL" ]; then
    echo "  设置入口地址INDEX_URL为：$INDEX_URL"
    INDEX_FILE="$WEBAPPS_DIR/ROOT/index.jsp"
    mkdir -p $WEBAPPS_DIR/ROOT
    echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">" > $INDEX_FILE
    echo "<html><head><script type="text/javascript">window.location=\"$INDEX_URL\";</script></head></html>" >> $INDEX_FILE
  fi
  echo "  无更新规则，跳过更新"
fi
echo "更新$X5_NAME运行时完毕"

echo "正在更新自定义webapps..."
download_webapps $DIST_URL/webapps
echo "自定义webapps更新完毕"

webapps=`expr \`date +%s%N\` / 1000000`
echo "耗时$[ webapps - usrsrc ]毫秒"

# 数据库初始化，由于数据库容器启动慢，放到最后执行
if [ "$INIT_DB"x = "false"x ]; then
  echo '$INIT_DB=false，忽略数据库初始化'
else
  SQL_PATH="$JUSTEP_HOME/sql"
  mkdir -p $SQL_PATH
  LOG_PATH="$SQL_PATH/sql_`date +%Y%m%d%H%M%S`.log"
  load_script(){
    TMP="tmp_script"
    echo "DROP DATABASE IF EXISTS x5;" >>$TMP
    echo "CREATE DATABASE x5;" >>$TMP
    echo "USE x5;" >>$TMP
    echo "SET FOREIGN_KEY_CHECKS=0;" >>$TMP
    echo "SET SQL_MODE='NO_AUTO_VALUE_ON_ZERO';" >>$TMP
    SQL_FILES=`ls -A $1/*.sql 2> /dev/null`
    for FILE_NAME in $SQL_FILES;do
      echo "source $FILE_NAME;" >>$TMP
    done
    echo "SET FOREIGN_KEY_CHECKS=1;" >>$TMP
    echo "SET SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';" >>$TMP
    echo "commit;" >>$TMP
    echo "quit" >>$TMP
    echo "" >>$TMP

    testsql=( ./mysql -hdatabase -uroot -px5 )
    for i in {9..0}; do
      if echo 'SELECT 1' | ${testsql[@]} &> /dev/null; then
        break
      fi
      echo '  连接数据库失败，5秒后重试...'
      sleep 5 
    done

    if [ "$i" = 0 ]; then
      error '  数据库连接失败，请检查部署环境' 1
    fi

    START_TIME=$(date "+%s")
    ./mysql --default-character-set=utf8 -hdatabase -uroot -px5 -ve "source $TMP" >$LOG_PATH 2>&1
    ERROR=$?
    if [ "$ERROR" -eq "0" ]; then
      echo "  数据库初始化成功！共计用时: " `expr $(date "+%s") - ${START_TIME}` " 秒"
    else
      head $LOG_PATH
      error "  [$ERROR]数据库初始化失败" 1
    fi
  }

  echo "开始数据库初始化..."
  mkdir -p $SQL_PATH
  cd $SQL_PATH
  echo "  获取mysql客户端..."
  curl -s -f $PRODUCT_URL/mysql/5.6/mysql -o mysql
  chmod a+x mysql
  load_script $SQL_PATH
  echo "数据库初始化完毕"
fi

dbinit=`expr \`date +%s%N\` / 1000000`
echo "耗时$[ dbinit - webapps ]毫秒"
