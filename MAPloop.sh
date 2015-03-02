#!/bin/sh
# 複数結果に対するMAPまでひとつながり！
# 第一引数	:map.rb参照 result_rankのファイルのパス

files=${1}*

for filepath1 in ${files}
do
 files2=${filepath1}/*
 for filepath2 in ${files2}
 do
  echo ${filepath2}/
  ruby map.rb ${filepath2}/
 done
done
