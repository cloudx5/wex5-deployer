#!/bin/bash

source `dirname $0`/init-product.sh

if [ -z "$POOL_TYPE" ]; then
  source `dirname $0`/init.sh $RESOURCE_ID
  echo "****FINISHED****"
  echo "始化完毕，结束进程"
else
  echo "****FINISHED****"
  echo "启动池类型为$POOL_TYPE的监听"
  java -Xmx64m -Xms16m -Xmn8m -Xss1m -XX:ReservedCodeCacheSize=5m -XX:NewRatio=3 -jar /usr/local/agent/agent-1.0.1.jar $POOL_TYPE
fi
