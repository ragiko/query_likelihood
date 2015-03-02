#!/bin/sh
# NTCIR用のLDA動かしたい！(なぜかHDD上でシェルが動かない)
# 第一引数：学習モデル名(拡張子なし)
# 　./model/学習用モデル名/学習用モデル名(.alpha,.beta,.arpa)
# 第二引数：出力名

# 入力ファイルのアドレス
echo "$3"/* > temp.txt
/usr/bin/ruby toriaezu.rb temp.txt temping
# 出力先のアドレス
mkdir "$2"
enteradress="$2/"
# モデルの位置の記憶
modelline="$1/$1"

if [ $# != 3 ]
then
  echo "check input file!"
else

  # トピック数Nの読み取り
  while read line
  do
    n=${line}
  done < ${modelline}.n


 ######
# ファイルの数だけリピート
while read filepath
do
echo ${filepath}
  # ファイルの名前を抽出
  file_p=${filepath##*/}
  file_p=${file_p%%.*}

  # 出力先の位置の記憶
  enterline="${enteradress}${file_p}"
  mkdir ${enterline}
  echo "****************"
  echo ${enterline}
 echo "テキストデータをlda用に変換するよ！"
  /usr/bin/ruby makeentertext-lda.rb ${modelline} ${filepath} ${enterline}/${file_p}

 ######
 echo "ガンマだすよ！"
  # 行毎のlda計算
  # あまり綺麗なプログラムの書き方じゃないけど・・・
   ./lda-gamma/lda -N $n ${enterline}/${file_p} ${modelline} 
  
   cat ${modelline}.gamma > ${enterline}/${file_p}.gamma

done < temping

 echo "***end Enter.sh - erace temp file***"

fi


