#!/bin/bash
#init service for tenant
#source common.sh
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
      echo "初始化公共服务： ${sn[0]}..."
      curl -sS -w "%{http_code}\n" -X POST --url http://gateway/${sn[0]}$value -H "apiKey: $API_KEY" -H "apiSecret: $API_SECRET"
      echo "初始化公共服务： ${sn[0]}结束."
      ;;
    *)
      echo "ignore: ${kv[0]}"
      ;;
  esac
done 

