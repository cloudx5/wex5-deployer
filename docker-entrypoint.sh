#!/bin/bash

source `dirname $0`/init-product.sh

if [ -z "$POOL_TYPE" ]; then
  source `dirname $0`/init.sh $RESOUCE_ID
  echo "****FINISHED****"
  echo "始化完毕，结束进程"
else
  echo "****FINISHED****"
  echo "启动池类型为$POOL_TYPE的监听"
  java -jar /usr/local/agent/agent-1.0.1.jar $POOL_TYPE
fi
