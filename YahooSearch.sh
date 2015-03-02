
#!/bin/sh
# 文章をそのままyahoo!APIで検索して出力する
# 第一引数：質問文が１行事に記してあるテキスト
# 第二引数：出力ファイル名
# 第三引数：上限検索数

# 変数宣言
querylist="${1}"
foldername="${2}"
searchnum="${3}"
query_num=0

 #出力先フォルダを自動生成
 mkdir expand_query/${foldername}

 #プログラム稼働用にディレクトリ移動(最後に戻る)
 cd program_yahoosearch
#querylistテキストの生成
 ruby querypass.rb ../${querylist} ../expand_query/${foldername}/querylist.txt
 #querylistテキストにある質問の数だけループが回る
 while read line
 do
 #質問クエリ毎に番号を割り振る
 query_num=`expr ${query_num} + 1`

 paded_num=`printf "%03d" ${query_num}`

 #フォルダの指定(resultフォルダ内のクエリ番号フォルダ指定)
 filename="../expand_query/${foldername}/${paded_num}"
 #フォルダ名の確認
 echo "${filename}:${line}"
  mkdir ${filename}
  ruby searchquery.rb ${line} ${filename} ${searchnum}
 echo ""
 done < ../expand_query/${foldername}/querylist.txt

 rm *.pdf
 cd ../

