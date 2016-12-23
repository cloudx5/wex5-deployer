#!/bin/bash

source `dirname $0`/env.sh

error(){
  echo >&2 "$1"
  echo >&2 "****ERROR****: $2"
  exit $2
}

download_tar(){
  # $1: url $2: filename $3: 是否忽略不存在的资源 $4: 是否解压 $5: 不删除解压目录，默认删除
  rm -rf $2.tar.gz
  if [ "$5"x != "true"x ]; then
    rm -rf $2
  fi
  echo "  正在更新 $2..."
  curl -s -f $1/$2.tar.gz -o $2.tar.gz
  ERROR=$?
  enable_git=`tar -tvf $2.tar.gz | grep ".git/config"`
  if [ "$ERROR" -eq "0" ]; then
    if [ "$4"x = "true"x ]; then
      if [ -z $enable_git ]; then
        mkdir -p $2
        tar -xf $2.tar.gz -C ./$2
      else
        echo " git化的资源，创建符号链接... "
        ln_tar
      fi
    fi
    echo "  $2 更新完毕"
  else
    if [ "$3"x = "true"x ]; then
      echo "  $2 不存在，忽略更新"
    else
      error "  [$ERROR]更新 $2 失败" 1
    fi
  fi
}

# link source的子目录到model目录下
ln_tar(){
  src_dir=$JUSTEP_HOME/source
  run_dir=$JUSTEP_HOME/model
  for sub_name in `find $src_dir -maxdepth 1 -mindepth 1 -type d -printf "%f\n"` ; do
    mkdir -p $run_dir/$sub_name
    retc=`find $src_dir/$sub_name -mindepth 1 -maxdepth 1`
    if [ ! -z "$retc" ]; then
      find $src_dir/$sub_name -mindepth 1 -maxdepth 1 | xargs ln -t $run_dir/$sub_name -fs
    fi
  done
}

download_webapps(){
  rm -rf $WEBAPPS_DIR/webapps.txt
  curl -s -f $1/webapps.txt -o $WEBAPPS_DIR/webapps.txt
  ERROR=$?
  # curl 空文件不会生成，这里判断一下文件是否存在
  if [ "$ERROR" -eq "0" ] && [ -s $WEBAPPS_DIR/webapps.txt ]; then
    while read webapp
    do
      echo "  正在更新 $webapp..."
      curl -s -f $1/$webapp -o $WEBAPPS_DIR/$webapp
      ERROR=$?
      if [ "$ERROR" -eq "0" ]; then
        echo "  $webapp 更新完毕"
      else
        error "  [$ERROR]更新 $webapp 失败" 1
      fi
    done < $WEBAPPS_DIR/webapps.txt
  fi
}
