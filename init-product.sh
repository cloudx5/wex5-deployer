#!/bin/bash

source `dirname $0`/common.sh

if [ -z "$X5_VERSION" ]; then
  error '请设置$X5_VERSION 环境变量，该变量标识使用的X5版本，例如3.5 ' 1
fi

# 清空weapps下应用，需部署的应用最后在放置
cd $WEBAPPS_DIR
rm -rf *
mkdir ROOT

# 检测product下载的服务是否可访问
for i in {3..0}; do
  ret_code=`curl -I -s --connect-timeout 5 $PRODUCT_URL/status -w %{http_code} | tail -n1`
  if [ "x$ret_code" = "x200" ]; then
    break
  fi
  echo '连接产品服务器失败，10秒后重试...'
  sleep 10 
done

if [ "$i" = 0 ]; then
  error '连接产品服务器失败，请联系管理员' 1
fi

# model, sql 等JUSTEP_HOME下资源

cd $JUSTEP_HOME

echo "当前使用的$X5_NAME版本：$X5_VERSION"

echo "正在更新资源..."
curl -s -f $X5_URL/$UPDATE_HOME_SH -o $UPDATE_HOME_SH
ERROR=$?
if [ "$ERROR" -eq "0" ]; then
  chmod a+x $UPDATE_HOME_SH
  source $UPDATE_HOME_SH
else
  echo "  无更新规则，跳过更新"
fi
echo "更新资源完毕"

# webapps资源更新后再更新，避免相关资源未准备而访问错误

cd $WEBAPPS_DIR

echo "正在更新$X5_NAME运行时..."
curl -s -f $X5_URL/$UPDATE_WEBAPPS_SH -o $UPDATE_WEBAPPS_SH
ERROR=$?
if [ "$ERROR" -eq "0" ]; then
  chmod a+x $UPDATE_WEBAPPS_SH
  source $UPDATE_WEBAPPS_SH
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
download_webapps $X5_URL/webapps
echo "更新$X5_NAME运行时完毕"
