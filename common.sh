#!/bin/bash

source `dirname $0`/env.sh

error(){
  echo >&2 "$1"
  echo >&2 "****ERROR****: $2"
  exit $2
}

download_tar(){
  # 保留此函数以支持不需要分离系统目录的tar包
  # $1: url $2: filename $3: 是否忽略不存在的资源 $4: 是否解压 $5: 不删除解压目录，默认删除
  rm -rf $2.tar.gz
  if [ "$5"x != "true"x ]; then
    rm -rf $2
  fi
  echo "  正在更新 $2..."
  curl -s -f $1/$2.tar.gz -o $2.tar.gz
  ERROR=$?
  if [ "$ERROR" -eq "0" ]; then
    if [ "$4"x = "true"x ]; then
      mkdir -p $2
      tar -xf $2.tar.gz -C ./$2
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

# 用于分离系统目录和用户目录的情况
# $1: url $2: filename $3: 是否忽略不存在的资源 $4: 是否解压 
# $5: 不删除解压目录，默认删除 
down_ln_user_tar(){
  rm -rf $2.tar.gz
  if [ "$5"x != "true"x ]; then
    if [ -d ${2}_sys ]; then #存在sys目录,说明不是第一次更新，可安全删除$2目录
      rm -rf $2
    fi
  fi
  echo "  正在更新用户 $2..."
  curl -s -f $1/$2.tar.gz -o $2.tar.gz
  ERROR=$?
  if [ "$ERROR" -eq "0" ]; then
    if [ "$4"x = "true"x ]; then
      if [ ! -d ${2}_sys ]; then #不存在sys目录,说明是第一次更新
        mv $2{,_sys}              
      fi
      mkdir -p $2
      tar -xf $2.tar.gz -C ./$2
      merge_sys $2              
    fi
    echo "  用户$2 更新完毕"
  else
    if [ "$3"x = "true"x ]; then
      echo "  $2 不存在，忽略更新"
    else
      error "  [$ERROR]更新 $2 失败" 1
    fi
  fi
}

#  合并$1系统目录内容到$1目录下
merge_sys(){
  echo "  合并系统目录到用户目录... "
  src_dir=$JUSTEP_HOME/$1
  sys_dir=$JUSTEP_HOME/${1}_sys
  enable_git=`tar -tvf $1.tar.gz | grep ".git/config"`
  if [ ! -z "$enable_git" ]; then
    echo "# ignore system files and directories." > $src_dir/.git/info/exclude 
    echo "  检测到$1为git化的资源."
  fi
  # 第一层目录遍历
  for sub_name in `find $sys_dir -maxdepth 1 -mindepth 1 -type d -printf "%f\n"` ; do
    mkdir -p $src_dir/$sub_name
    retc=`find $sys_dir/$sub_name -mindepth 1 -maxdepth 1`
    if [ ! -z "$retc" ]; then
      # 第二层目录
      find $sys_dir/$sub_name -mindepth 1 -maxdepth 1 | xargs ln -t $src_dir/$sub_name -s
    fi
    if [ ! -z "$enable_git" ]; then
      # 第二层目录
      for sub_sub_name in `find $sys_dir/$sub_name -mindepth 1 -maxdepth 1 -printf "%f\n"` ; do
        echo "/$sub_name/$sub_sub_name" >> $src_dir/.git/info/exclude 
      done
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
