#!/bin/sh
# NTCIR用のLDA動かしたい！(なぜかHDD上でシェルが動かない)
# 第一引数：学習モデル名(拡張子なし)
# 　./model/学習用モデル名/学習用モデル名(.alpha,.beta,.arpa)
# 第二引数：出力名 ./output/${2}
#rm -rf output/*

TIME_A=`date +%s`   #A

files=${1}*
output_folder="${2}"

for filepath1 in ${files}
do
  # ファイルの名前を抽出
  file_p=${filepath1##*/}
  file_p=${file_p%%.*}
mkdir -p ${output_folder}/${file_p}/
echo ${output_folder}/${file_p}
echo ${filepath1}
  . ./Enter.sh mainichi0113 ${output_folder}/${file_p} ${filepath1}
done

TIME_B=`date +%s`   #B
PT=`expr ${TIME_B} - ${TIME_A}`
H=`expr ${PT} / 3600`
PT=`expr ${PT} % 3600`
M=`expr ${PT} / 60`
S=`expr ${PT} % 60`
echo "making lda:"
echo "${H}:${M}:${S}"
