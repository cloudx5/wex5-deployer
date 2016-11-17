#!/bin/bash

source `dirname $0`/init-product.sh
source `dirname $0`/init.sh
echo "****FINISHED****"

if [ -z "$POOL_TYPE" ]; then
  echo "始化完毕，结束进程"
else
  echo "启动池类型为$POOL_TYPE的监听"
  java -jar /usr/local/agent/agent-1.0.1.jar $POOL_TYPE
fi
