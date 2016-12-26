#!/bin/bash
start=`expr \`date +%s%N\` / 1000000`

source `dirname $0`/common.sh
echo "用户资源ID: $1"
export DIST_URL=$DIST_URL/$1

PROJECT_CONF_PATH=$JUSTEP_HOME/project.conf

rtcode=`curl -w "%{http_code}" -s -f $DIST_URL/home/project.conf -o $PROJECT_CONF_PATH`
if [[ "x$rtcode" = "x200"  ]]; then
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
        API_KEY=${line#*=}
        echo "$API_KEY"
        ;;
      "api_secret")
        API_SECRET=${line#*=}
        #echo "$API_SECRET"
        ;;
      "index_url")
        INDEX_URL=${line#*=}
        #echo "$API_SECRET"
        ;;
      "db_username")
        DB_USERNAME=${line#*=}
        #echo "$API_SECRET"
        ;;
      "db_password")
        DB_PASSWORD=${line#*=}
        #echo "$API_SECRET"
        ;;
      "db_driver_class")
        DB_DRIVER_CLASS_NAME=${line#*=}
        #echo "$API_SECRET"
        ;;
      "db_url")
        DB_URL=${line#*=}
        #echo "$API_SECRET"
        ;;
      "db_schema")
        DB_SCHEMA=${line#*=}
        #echo "$API_SECRET"
        ;;
      "db_type")
        DB_TYPE=${line#*=}
        #echo "$API_SECRET"
        ;;
      "postgrest_schemaid")
        POSTGREST_SCHEMAID=${line#*=}
        #echo "$API_SECRET"
        ;;  
      "no_cmnsrv")
        NO_CMNSRV=${line#*=}
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
else 
  echo "下载project.conf失败: $rtcode . 设置no_cmnsrv为true."
  NO_CMNSRV="true"
fi


if [ -z "$DIST_URL" ]; then
  error '请设置$DIST_URL环境变量 ' 1
fi

prepare=`expr \`date +%s%N\` / 1000000`
echo "环境参数获取耗时$[ prepare - start ]毫秒"

# 数据库初始化，由于数据库容器启动慢，放到最后执行
echo "正在初始化数据库..."
if [ "$INIT_DB"x = "false"x ]; then
  echo '$INIT_DB=false，忽略数据库初始化'
else
  source `dirname $0`/init-db.sh  
fi
dbinit=`expr \`date +%s%N\` / 1000000`
echo "数据库初始化完毕. 耗时$[ dbinit - prepare ]毫秒."

echo "正在初始化网关..."
source `dirname $0`/init-gateway.sh
gateway=`expr \`date +%s%N\` / 1000000`
echo "初始化网关完毕. 总耗时$[ gateway - dbinit ]毫秒"

if [[ -z "$NO_CMNSRV" || "$NO_CMNSRV" = "false" ]]; then
  echo "正在初始化公共服务..."
  source `dirname $0`/init-service.sh
  cmnsrv=`expr \`date +%s%N\` / 1000000`
  echo "初始化公共服务完毕. 总耗时$[ cmnsrv - gateway ]毫秒."
else
  echo "no_cmnsrv存在, 跳过公共服务初始化."
  cmnsrv=`expr \`date +%s%N\` / 1000000`
fi

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
usrsrc=`expr \`date +%s%N\` / 1000000`
echo "更新用户资源完毕. 耗时$[ usrsrc - cmnsrv ]毫秒."

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
webapps=`expr \`date +%s%N\` / 1000000`
echo "自定义webapps更新完毕. 耗时$[ webapps - usrsrc ]毫秒."

end=`expr \`date +%s%N\` / 1000000`
echo "初始化总耗时: $[ end - start ]毫秒."
