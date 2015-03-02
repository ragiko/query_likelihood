# クエリ尤度+ldaを試したい
# 元ソース queryyuudo.rb

# 第一引数	：拡張クエリフォルダ(指定フォルダ/クエリ毎のフォルダ/web記事)
#		：＊フォルダ内に質問文(原文まま)のテキストquerylist.txtが必須
# 第二引数	：拡張クエリのlda結果
# 第三引数	：μ値
# 第四引数	：λ値
# 第五引数	：出力ファイル名
# 参照ファイル	：dir変数で指定
# 出力ファイル	：result_クエリファイル名.txt
#		：クエリに対する、各文書のコサイン尺度
#		出力例：<CANDIDATE document="result_A01M0149_kak.txt" /> : 0.374955070025794

#プログラムの流れ
#文書とクエリの、ディレクトリの指定
#MeCab
# 検索対象文書の出現回数を計算
# 質問クエリ、拡張クエリの出現回数を計算
# クエリ尤度モデルの適用
#結果ファイルを出力

# $KCODE: 使用する文字コード 
$KCODE="UTF-8"
require 'MeCab'
require 'csv'
require 'nkf'
require 'kconv' #文字変換

## 設定項目
# mcb	:MeCabオブジェクト生成　形式：”形態素,品詞”
# dir	:読み込むテキストの格納されているディレクトリ(絶対パス推奨)
# in_f	:入力１：読み込むクエリの格納されているディレクトリ(絶対パス推奨)スラッシュも入れる
mcb = MeCab::Tagger.new("--node-format=%m,%f[0]\\n --eos-format=")
#dir = "/home2/copass/NTCIR-9/kakiokoshi/toNTCIR/"
#dir = "result_recognition_unmatched/"
# デバッグ用(正式使用時は下のdir代入を消す)
#dir = "/home2/query-expansion/result_expand/kakunin/0/"
# トピックモデル情報topic_model

# 検索の対象
dir = "ntcir11_spoken_koen_jout/"
# 検索の対象のLDA
topic_dir ="lda/model/ntcir11_spoken_koen_jout/"

if ARGV.size != 5
	puts "Syntax Error!!"
	exit(-1)
else
	in_f = ARGV[0]
	in_f_two = ARGV[1]
	out_f = ARGV[4]
	Dir::mkdir(out_f)
	# 拡張クエリの比率を決めるalpha（大きいほど拡張クエリへの依存が高い
	paramator_u = ARGV[2].to_f
	paramator_ramda = ARGV[3].to_f
       n_best = 1
end
## ここまで設定項目

puts "begininng queryyuudo.rb"

#####df定義####
# df_hash	: DFのハッシュ
df_hash = Hash.new


####################################
######   検索対象文書 　　　　  ######
# 変数宣言
# tf_result	: TFの結果の配列
tf_result = Array.new
mor_num_line = Array.new
# topic_doc 
topic_doc = Array.new

# 文書リストを取得する
filelist = Dir::entries(topic_dir).sort

# 不要な要素を消しておく
filelist.delete(".")
filelist.delete("..")

puts "＊文書の読み込み＊"
puts "using; file : " + dir + ", " + n_best.to_s + "best"
## それぞれの文書について実行
for file_num in 0..filelist.size-1
### mor_num: 文書中の形態素数チェック
 mor_num = 0
### tf_hash: TFのハッシュ
### tf_hash_temp: TFのハッシュに入れるためのとりあえず配列
 tf_hash= Hash.new
 under = Hash.new
## nbestファイルを読み込む
 for i in 1 .. n_best 
### res: ファイルを読み込みMeCabで形態素解析した結果
### 文字コード：UTF-8
### 改行コード：Linux(LF)
  #res = mcb.parse(NKF.nkf("-w -m0 -Lu", File.read(dir + filelist[file_num] +".rcg/"+ i.to_s + "best.txt")))
  #### MYMY
  # delete("\n ")
  res = mcb.parse(NKF.nkf("-w -m0 -Lu", File.read(dir + filelist[file_num] +".match_word.jout.txt/#{filelist[file_num]}.match_word.jout.txt")).delete(" "))




### resから1行ずつ取り出し配列に変換してstrに格納
	for line in res
	  str = line.chomp.split(",")
	     # 名詞のみを取り出す
	    if str[1] == "名詞"
	     mor_num = mor_num + 1.0/i.to_f
	      # tf_hashに既に格納されているか
	      #  格納されていなければ 1 (else部分)
	      #  格納されている時は +1
	      if tf_hash.key?(str[0])
		tf_hash[str[0]] += 1.0/i.to_f
	      else
		tf_hash[str[0]] = 1.0/i.to_f
	      end
	    end
	end
 end

## DFハッシュに既に格納されているか
##  格納されていなければ 1 (else部分)
##  格納されている時は +1
## 同時にTF値の対数を取る
 for word in tf_hash.to_a
    if df_hash.key?(word[0])
      df_hash[word[0]] += 1
    else
      df_hash[word[0]] = 1
    end
 end

## 一つの文書の処理が終わったらtf_resultに結果をプッシュ 
 tf_result << tf_hash.to_a
 mor_num_line << mor_num

## トピック情報のγモデル格納
 res = File.read(topic_dir + filelist[file_num] +"/#{filelist[file_num]}/#{filelist[file_num]}.gamma")
 topic_doc << res.split(/\s+/)

end
tf_hash = Hash.new

##########################
##### IDF ############
## 求めたDFからIDFを求める(おそらく使わないが一応)
idf_hash = Hash.new
for str in df_hash.to_a
    idf_hash[str[0]] = Math::log10(filelist.size.to_f/str[1].to_f) +1.0
end
#仕事終了。お疲れ様
df_hash = Hash.new


###文書のTFIDF##############
# doc_vector: TF-IDFの結果を格納
# col_result: 文書全体のベクトルの記憶
doc_vector = Array.new
doc_collection = Hash.new

doc_tfidf = Array.new
# それぞれの文章について実行
for doc_num in 0..tf_result.size-1
## tfidf_hash: TF-IDFのハッシュ
  tfidf_hash = Hash.new
## tfidf_nor: 文書の長さ統一のためのノルム
  tfidf_nor = 0.0
## 文書内の単語毎にtfidfを求める。
  for word in tf_result[doc_num]
    tfidf_hash[word[0]] = word[1].to_f / mor_num_line[doc_num].to_f   
  if doc_collection.key?(word[0])
   doc_collection[word[0]] += word[1].to_f
  else
   doc_collection[word[0]]= word[1].to_f
  end
  end
## 一つの文書の処理が終わったらdoc_vectorに結果をプッシュ
  doc_vector << tfidf_hash
end

mor_num_all = 0.0
for mor_num in mor_num_line
 mor_num_all += mor_num
end

for key_vallue in doc_collection.keys
 doc_collection[key_vallue] /= mor_num_all.to_f
end

puts "＊書き起こし文のTFIDF計算完了＊"
#tf_result = Hash.new




########################################
#####質問クエリ文###############3
####クエリ原文
######
# 関数query_tfにクエリ毎の形態素数を代入
origin_query_vector = Array.new
#####
# クエリ毎に検索されたwebページのリストの作成
originalquery = Array.new
queryfile = File.read(in_f +"querylist.txt")
originalquery = queryfile.split("\n")
#
## クエリ毎のループ
for txt in originalquery
# print txt + "\n"
## tf計算のためのtempループ
 tf_temp = Hash.new
## 形態素解析結果ループ
 #### MYMY
 # txt.delete(" \n")
 res = mcb.parse(txt.delete("\n "))
 res = (res).split(/\s*\n\s*/)
 for row in res
	# 名詞のみを代入
	if /(\D+),名詞/ =~ row
	 meishi = $1
	 if idf_hash.key?(meishi)
	  if tf_temp.key?(meishi)
	   tf_temp[meishi] += 1
	  else
	   tf_temp[meishi]= 1 
	  end
	 end
	end
  end

## tfidf計算のためのtemp関数
 tfidf_temp = Hash.new
## tfidfを求める
 for word in tf_temp
   tfidf_temp[word[0]] = word[1].to_f / (tf_temp.size)
 end
##クエリ毎の名詞ベクトルに代入
 origin_query_vector << tfidf_temp
##
end


### MYMY
QUERY_NUM = 37
PMI_WORD_FILTERS = [
["ネットワーク", "検索", "未知", "語", "結果"],
["分割", "文", "統計", "的", "手法"],
["スピーカー", "うそ", "がま", "こと", "の", "よう", "かって"],
["尤", "度", "もの", "こと", "影響", "の", "かま"],
["本人", "認識", "これ", "よう", "こと", "空間", "それ", "指定", "原因", "の"],
["モデル", "パープレキシティー", "性能", "の", "直感", "的", "ユーザー", "単語", "予測", "能力", "こと", "知識", "研究", "文", "分野", "かま", "応用", "場面", "ーパープレキシティー", "それ"],
["雰囲気", "五", "の", "毎日", "生活", "管理", "何", "みたい", "話", "ライブ", "よう", "くだ", "二", "一", "小", "なん", "それ"],
["ーアラインメント", "的", "機械", "翻訳", "一", "アラインメント", "説明", "一つ", "結果", "の"],
["研究", "モデル", "言語", "それ", "年齢", "説明", "回路", "単語", "スコア", "結果", "的"],
["性", "研究", "もの", "声", "明瞭"],
["話し言葉", "コーパス", "フィラー", "こと", "言語", "モデル", "システム", "性能", "よう", "の", "結果"],
["構成", "ドキュメント", "検索", "音声", "情報", "それ", "データー", "際", "資料", "手法", "フレーム", "テキスト", "選択", "よう", "インデックス", "作成", "方法", "スライド"],
["影響", "強調", "検出", "数", "よう"],
["位置", "情報", "ケース", "リコール", "値"],
["ドキュメント", "検索", "未知", "語", "一つ", "認識", "用", "登録", "の", "問題", "それ"],
["認識", "テキスト", "話し言葉", "それ", "書き言葉", "文", "もの", "付け", "こと", "分類", "方法", "説明", "特徴", "量", "手法"],
["自動", "要約", "研究", "よう", "認識", "場合", "話し言葉", "内容", "書き", "重要", "部分", "抽出", "こと", "文", "もの", "判定", "の", "特徴", "量", "付け", "ニュース", "手法", "具体", "的"],
["中継", "構成", "要素"],
["の", "五", "一", "二"],
["三", "十", "四", "二月", "状態", "の", "五", "一"],
["認識", "解決", "複数", "システム", "化"],
["英語", "翻訳", "日本語", "発話", "一"],
["ドキュメント", "検索", "システム", "下", "論文", "の", "幸福", "こと", "フォワード", "列", "それ", "分割", "固定", "長", "場合", "テール", "提供", "方法", "考え方"],
["文字", "列", "検索", "システム", "化", "講義", "データーベース", "実験", "考察", "未知", "の", "フォーク", "音", "もの", "こと", "よう", "今回", "手法", "後悔", "若干", "今後", "変更"],
["の", "場所", "どこ"],
["言葉", "よう", "システム"],
["最初", "の", "紹介", "複数", "認識", "検索", "オーケー", "ネットワーク"],
["一", "単語", "方法", "法", "数値", "分", "理解"],
["一", "三", "五", "認識", "誤り", "対処", "精度", "新婦", "の", "それ", "問題", "手法"],
["性", "ドキュメント", "検索", "公園", "メール", "長音", "従来", "よう", "問題", "の"],
["収録", "データー", "認識", "こと", "よう", "為", "の", "四", "どれ", "時間", "発話", "データーセット"],
["信頼", "度", "スコア", "の", "こと", "元", "モデル", "それ"],
["簡単", "認識", "器", "ネットワーク", "構成", "マッチング", "研究", "コンピューター", "ノード", "複数", "際", "提案", "スコア", "説明"],
["簡単", "セクション", "研究", "幾つ", "操作", "以下", "例", "検索", "対象", "木", "構造", "変換", "探索", "京都", "クエリー", "指数", "的", "決定", "場合", "分割", "手法", "検出", "認識", "誤り", "の"],
["ビデオ", "録音", "録画", "分割", "研究", "認識", "用", "結果", "誤り", "こと", "よう", "もの", "新聞", "分析", "置換", "挿入", "脱落", "マット", "影響", "の", "これ", "発表", "実験"],
["解析", "の", "スペクトル", "帯域", "ごと", "パワー", "方法", "バイク", "三", "それ", "説明", "よう", "音"],
["統計", "的", "機械", "翻訳", "対", "日本語", "二つ", "対訳", "用意", "計算", "機", "枠組み", "それ", "理論", "原理", "の", "スライド", "お願い"]
]

for query_id in 0..(QUERY_NUM-1) 
  origin_query_vector[query_id].delete_if { |word, v| PMI_WORD_FILTERS[query_id].include?(word) == false }
end

# TEST
# puts "SIZE: #{origin_query_vector.size} "
# puts "query1: #{origin_query_vector[1]}"
# puts "delete #{origin_query_vector[1]}"
p origin_query_vector[0]
### YMYMY

  doc_nor_vector = Array.new
# LDAノルム
for doc_num in 0 .. topic_doc.size-1
 doc_nor = 0
   for nor in topic_doc[doc_num]
    doc_nor += nor.to_f*nor.to_f
   end
  doc_nor_vector << doc_nor
end
###TF-IDFノルム
#  doc_nor_vector = Array.new
#  for doc_num in 0 .. topic_doc.size-1
#   doc_nor = 0
#   for nor in doc_vector[doc_num]
#    temp = nor[1].to_f * idf_hash[nor[0]]
#   doc_nor += temp*temp
#  end
#  doc_nor_vector << doc_nor
# end
####

##################
####拡張クエリ####
######
querylist = Array.new
## 各クエリのフォルダ取り出し
querylist = Dir::entries(in_f)
querylist.sort!
querylist.delete_if{|x| /\D+/ =~ x}
p querylist
######
# 関数query_tfにクエリ毎の形態素数を代入
belonged_query_vector = Array.new
# トピック情報
topic_web = Array.new

ramda_topic = Array.new

######
 puts "＊拡張クエリ読み込み＊" 
 puts "using; belonged query : " + in_f
## クエリ毎のループ
for query_num in 0..querylist.size-1
puts querylist[query_num]
# 各ページ毎の形態素数を代入するlex_temp配列
# lex_temp[0]に1ページ目の形態素数を入れる
 lex_temp = Array.new### クエリ毎に検索されたwebページのリストの作成
 weblist = Dir::entries(in_f  + querylist[query_num])
 weblist.sort!
 weblist.delete(".")
 weblist.delete("..")
  mor_num = 0
### トピック情報
topic_web_arr = Array.new
###
#### 各クエリのwebページ毎のループ
 for page_num in 0 .. weblist.size-1
#### tf計算のためのtemp配列
  lex_temp[page_num] = Hash.new
#### テキスト読み込み
  txt = File.read(in_f + querylist[query_num] +"/"+ weblist[page_num])
  txt = txt.toutf8
  txt = NKF.nkf("-w -Lu -m0",txt)
  

#### 形態素解析結果ループ
  res = mcb.parse(txt)
  res = (res).split(/\s*\n\s*/)
  for row in res
	# 検索対象文書に存在する名詞のみを代入
	if /(\D+),名詞/ =~ row
	 meishi = $1
	 if idf_hash.key?(meishi)
 	  if lex_temp[page_num].key?(meishi)
	   lex_temp[page_num][meishi] += 1.0
	  else
	   lex_temp[page_num][meishi]= 1.0
	  end
	 end
	end
  end

#### トピック推定
## トピック情報のγモデル格納

### MYMY
  #if /(\d+).txt/ =~ weblist[page_num]
  #  webname = $1
  #end

  if /(.*).txt/ =~ weblist[page_num]
    webname = $1
  end
### YMYM

  res = File.read(in_f_two + querylist[query_num] +"/"+ webname + "/" + webname + ".gamma")
  ress = res.split(/\s+/)

#####
# LDAノルム
  res_nor = 0
  for nor in ress
   res_nor += nor.to_f*nor.to_f
  end
####

#### 1文書毎に
##### トピック同士のコサイン類似度計算
  topic_temp_arr = Array.new
  for doc_num in 0 .. topic_doc.size-1
### LDAノルム
   top = 0
   for i in 0 .. ress.size-1
    top += ress[i].to_f*topic_doc[doc_num][i].to_f
   end
#####
   topic_web_arr << top/Math::sqrt(doc_nor_vector[doc_num])/Math::sqrt(res_nor) 
  end
 end
####
###コサイン類似度の平均を求め、正規化
 mean = 0
 for i in topic_web_arr
  mean += i
 end
 mean /= topic_web_arr.size
 undermean =1/mean 
### クエリ毎のtf計算のためのtf_temp
 tf_temp = Hash.new
### tf_tempに代入していく
 for page_num in 0 .. lex_temp.size-1
  for lex in lex_temp[page_num]
	lex_temp[page_num][lex[0]] = lex[1]*topic_web_arr[page_num]#*undermean
	 mor_num += lex[1]*topic_web_arr[page_num]#*undermean
  end
 end 
 for page_num in 0 .. lex_temp.size-1
  for lex in lex_temp[page_num]
   if tf_temp.key?(lex[0])
	tf_temp[lex[0]] += lex[1]/mor_num.to_f
   else
	tf_temp[lex[0]] = lex[1]/mor_num.to_f
   end
  end
 end   
###クエリ毎の名詞ベクトルに代入
 belonged_query_vector << tf_temp
end

# query_vector: TF-IDFの結果を格納
query_vector = Hash.new


## クエリ毎のweb文書生起確率を合体
# それぞれの文章について実行
for query_num in 0..belonged_query_vector.size-1
  for word in belonged_query_vector[query_num]
    if /(\d+)/ =~ word[1].to_s
     if query_vector.key?(word[0])
	query_vector[word[0]] += word[1].to_f / belonged_query_vector.size
      else
	query_vector[word[0]] = word[1].to_f / belonged_query_vector.size
     end
   end
  end
end

 temp = 0
 for i in query_vector
  temp += i[1]
 end

p temp

puts "＊拡張クエリベクトル計算完了＊"


#############################
######   query尤度モデル  ######
# simirality_point	: 類似度計算ハッシュ
simirality_point = Hash.new


puts "＊クエリ尤度の計算＊"
puts "using; μ : " + paramator_u.to_s + ", λ : "+paramator_ramda.to_s
#### クエリ毎に尤度を計算
#ファイルリストの何番目のファイルか？
for query_num in 0..querylist.size-1
print querylist[query_num]
print " : "
print originalquery[query_num]
print "\n"
## 各文書のdoc_vector毎に計算
 for doc_num in 0..doc_vector.size-1
  temp = 0
### 各質問クエリの名詞毎に計算
   for word in origin_query_vector[query_num]
### 重みを付与するための分母
   smooth = mor_num_line[doc_num] + paramator_u + paramator_ramda
#### 検索対象文書の名詞情報
     if doc_vector[doc_num].key?(word[0])
	pwd = mor_num_line[doc_num].to_f * doc_vector[doc_num][word[0]].to_f / smooth
     else
	pwd = 0
     end
#### 文書コレクションを用いた重み
     if doc_collection.key?(word[0])
	pwcol = paramator_u * doc_collection[word[0]].to_f / smooth
     else
	pwcol = 0
     end
### 拡張クエリを用いた重み
     if query_vector.key?(word[0])
       pwweb = paramator_ramda * query_vector[word[0]] / smooth 
     else
       pwweb = 0
     end
### それらをクエリとして計算
   temp +=  word[1] * Math::log(pwd+pwcol+pwweb)
   end
###
# 尤度を類似度として記憶
   simirality_point[filelist[doc_num]] = temp
###################
###prioritized and-operator retrieval
#   flag = 0
#   for meishi in origin_query_vector[query_num]
#    if doc_vector[doc_num].key?(meishi[0])
#    else
#	flag += 1
#    end
#   end
#   if flag == 0
#    simirality_point[filelist[doc_num]] += 10
#   end
####
 end
##

# ハッシュをソート
# cos_result	: コサイン尺度の計算結果を格納
 cos_result = Array.new
 cos_result = simirality_point.to_a.sort{|a, b|
     (a[1] <=> b[1])
 }
 cos_result.reverse!
## 類似度の高い順に結果を出力
 out_text = ""
 rank_count = 1
 for i in 0..filelist.size-1
  #out_text = out_text + format("%s\t %10.8f",cos_result[i][0],cos_result[i][1]) + "\n"
  ii = (i+1).to_s

  ##
  #  MY CODE
  #  長さが短いやつを削除
  #
  doc = File.open("./#{dir}#{cos_result[i][0].to_s}.match_word.jout.txt/#{cos_result[i][0].to_s}.match_word.jout.txt").read 
  if doc.size < 100
      #puts "WITHOUT #{cos_result[i][0].to_s} : SIZE #{doc.size.to_s}"
      next
  end

  # ファイルに出力
  out_text = out_text + "<CANDIDATE rank=\"" + (rank_count.to_s) +"\" document=\"" + cos_result[i][0].to_s + ".match_word.jout.txt"  + "\" /> : " + cos_result[i][1].to_s + "\n"
  rank_count += 1
  ###

 end
  foo = File.open(out_f + "/"+querylist[query_num]+".txt","w")
  #puts out_text
  foo.puts out_text
  foo.close
end
