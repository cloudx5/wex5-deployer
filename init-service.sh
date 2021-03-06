#!/bin/bash
#init service for tenant
#source common.sh

if [ -z "$BASE_DOMAIN" ]; then
  BASE_DOMAIN="xpaas.net"
  echo "  BASE_DOMAIN环境变量未设置， 使用默认值: $BASE_DOMAIN"
fi
echo "  主域名：$BASE_DOMAIN"

srvinit=${SRV_INIT_ARR//,/ }
#echo $srvinit
for srv in $srvinit;do
  #echo $srv
  if [ -z "$srv" ]; then
   continue 
  fi
  kv=(${srv//=/ })
  case ${kv[0]} in
    [a-z]*_srvinit)
      key=${kv[0]}
      value=${kv[1]}
      sn=(${key//_/ }) 
      #echo "http://gateway/${sn[0]}$value"
      echo -n "  初始化公共服务： ${sn[0]}..."
      #echo "$BASE_DOMAIN"
      sstart=`expr \`date +%s%N\` / 1000000`
      curl -sf -o /dev/null -w "  status: %{http_code}\n" -H "Host: $BASE_DOMAIN" -X POST --url http://gateway/${sn[0]}$value -H "apiKey: $API_KEY" -H "apiSecret: $API_SECRET"
      send=`expr \`date +%s%N\` / 1000000`
      echo "  初始化公共服务： ${sn[0]}结束. 耗时$[ send - sstart ]毫秒."
      ;;
    *)
      echo "  忽略: ${kv[0]}"
      ;;
  esac
done 

