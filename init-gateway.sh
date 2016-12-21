#!/bin/bash
#
#Author wyt
#
#在不重建容器的情况下重新初始化网关(kong)。 满足幂等性
#source common.sh

if [ -z "$API_KEY" ]; then
  #error '请设置API_KEY环境变量' 1
  API_KEY="app"
  echo "  API_KEY环境变量未设置， 使用默认值: $API_KEY"
fi

if [ -z "$API_SECRET" ]; then
  #error '请设置API_SECRET环境变量' 1
  API_SECRET="appclientsecret"
  echo "  API_SECRET环境变量未设置， 使用默认值: $API_S"
fi

if [ -z "$BASE_DOMAIN" ]; then
  #error '请设置BASE_DOMAIN环境变量' 1
  BASE_DOMAIN="xpaas.net"
  echo "  BASE_DOMAIN环境变量未设置， 使用默认值: $BASE_DOMAIN"
fi

if [ -z "$APP_SRV_NAME" ]; then
  APP_SRV_NAME="wex5"
  echo "  APP_SRV_NAME环境变量未设置， 使用默认值: $APP_SRV_NAME"
fi

if [ -z "$APP_SRV_PORT" ]; then
  APP_SRV_PORT="8080"
  echo "  APP_SRV_PORT环境变量未设置， 使用默认值: $APP_SRV_PORT"
fi

if [ -z "$CMN_STACK_NAME" ]; then
  CMN_STACK_NAME="common-service"
  echo "  CMN_STACK_NAME环境变量未设置， 使用默认值: $CMN_STACK_NAME"
fi

#curl -s -f $PRODUCT_URL/psql/9.5.3/psql -o psql
#chmod a+x psql

#psql -U $POSTGRES_USER -h $KONG_PG_HOST -d $POSTGRES_DB -c "DELETE FROM apis;"

# 检测Gateway的管理服务是否可访问
gstart=`expr \`date +%s%N\` / 1000000`

for i in {10..0}; do
  ret_code=`curl -I -s --connect-timeout 3 --url http://gateway:8001 -w %{http_code} | tail -n1`
  if [ "x$ret_code" = "x405" ]; then
    break
  fi
  echo '  连接Gateway失败，3秒后重试...'
  sleep 3
done
wgstart=`expr \`date +%s%N\` / 1000000`
echo "  等待Gateway耗时$[ wgstart - gstart ]毫秒. "

outputf='  %{http_code}, 耗时: %{time_total}s. '
#uaa
echo -n "  /uaa 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf"  -X DELETE --url http://gateway:8001/apis/uaa
curl -sf -o /dev/null -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=uaa" --data "upstream_url=http://uaa.$CMN_STACK_NAME:8771" --data "request_path=/uaa" --data "preserve_host=true"
#curl -sf -o /dev/null  -w "%{http_code}

#login
echo
echo -n "  /login 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/login
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=login" --data "upstream_url=http://uaa.$CMN_STACK_NAME:8771/uaa/login" --data "request_path=/login" --data "preserve_host=true"
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/login/plugins/ --data "name=authentication" --data "config.app_key=$API_KEY" --data "config.app_secret=$API_SECRET"

#logout
echo
echo -n "  /logout 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/logout
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=logout" --data "upstream_url=http://uaa.$CMN_STACK_NAME:8771/uaa/logout" --data "request_path=/logout" --data "preserve_host=true"
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/logout/plugins/ --data "name=authentication" --data "config.app_key=$API_KEY" --data "config.app_secret=$API_SECRET"

#db-admin
echo
echo -n "  /db-admin 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/db-admin
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=db-admin" --data "upstream_url=http://$APP_SRV_NAME" --data "request_path=/db-admin" --data "preserve_host=true"

#storage
echo
echo -n "  /storage 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/storage
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=storage" --data "upstream_url=http://storage.$CMN_STACK_NAME:8770" --data "request_path=/storage" --data "preserve_host=true"

#appkey
echo
echo -n "  /appkey 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/appkey
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=appkey" --data "upstream_url=http://appkey.$CMN_STACK_NAME:8781" --data "request_path=/appkey" --data "preserve_host=true"

#sms
echo
echo "  sms 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/sms
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=sms" --data "upstream_url=http://sms.$CMN_STACK_NAME:8782" --data "request_path=/sms" --data "preserve_host=true"

#postgrest
echo
echo -n "  /postgrest 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/postgrest
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=postgrest" --data "upstream_url=http://$APP_SRV_NAME:3000" --data "request_path=/postgrest" --data "preserve_host=true" --data "strip_request_path=true"

#x5
echo
echo -n "  /x5 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/x5
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=x5" --data "upstream_url=http://$APP_SRV_NAME:$APP_SRV_PORT" --data "request_path=/x5" --data "preserve_host=true"

#ide
echo
echo -n "  /ide 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/ide
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=ide" --data "upstream_url=http://$APP_SRV_NAME:$APP_SRV_PORT" --data "request_path=/ide" --data "preserve_host=true"

#baas
echo
echo "  baas 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/baas
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=baas" --data "upstream_url=http://$APP_SRV_NAME:$APP_SRV_PORT" --data "request_path=/baas" --data "preserve_host=true"

#/ static resource
echo
echo "  静态资源 清理并接入 ... "
curl -sf -o /dev/null  -w "$outputf" -X DELETE --url http://gateway:8001/apis/static
curl -sf -o /dev/null  -w "$outputf" -X POST --url http://gateway:8001/apis/ --data "name=static" --data "upstream_url=http://$APP_SRV_NAME:$APP_SRV_PORT" --data "request_path=/" --data "preserve_host=true"

execute=`expr \`date +%s%N\` / 1000000`
echo
echo "  网关初始化调用完成. 耗时$[ execute - wgstart ]毫秒."
