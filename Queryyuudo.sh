#!/bin/sh
# 第一引数	：拡張クエリ
# 第二引数	：拡張クエリのトピックモデル
# 第三引数	：結果

# delete
rm -rf hasegawa/result_rank/${1}
mkdir hasegawa/result_rank/${1}

TIME_A=`date +%s`   #A

# alpha u = 4000, bata v = 50
for alpha in 4000
do
  mkdir hasegawa/result_rank/${1}/${alpha}
  for beta in  50
  do
   /usr/bin/ruby query_yuudo.rb ${alpha} ${beta} hasegawa/result_rank/${1}/${alpha}/${beta}
  done
done

TIME_B=`date +%s`   #B
PT=`expr ${TIME_B} - ${TIME_A}`
H=`expr ${PT} / 3600`
PT=`expr ${PT} % 3600`
M=`expr ${PT} / 60`
S=`expr ${PT} % 60`
echo "document retrieval using query likelihood model:"
echo "${H}:${M}:${S}"
