# < 長谷川先輩のプログラム >
#
# プログラムの流れ
# 文書とクエリの、ディレクトリの指定
# MeCab
# 検索対象文書の出現回数を計算
# 質問クエリ、拡張クエリの出現回数を計算
# クエリ尤度モデルの適用
# 結果ファイルを出力
#
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
dir = "hasegawa/ntcir11_spoken_target_document/" # 検索の対象
topic_dir ="hasegawa/lda/ntcir11_spoken_target_document/" # 検索の対象のLDA

if ARGV.size != 5
  puts "Syntax Error!!"
  exit(-1)
else
  in_f = ARGV[0]
  in_f_two = "hasegawa/" + ARGV[1]
  out_f = ARGV[4]
  Dir::mkdir(out_f)
  # 拡張クエリの比率を決めるalpha（大きいほど拡張クエリへの依存が高い
  paramator_u = ARGV[2].to_f
  paramator_ramda = ARGV[3].to_f
  n_best = 1
end

puts "begininng queryyuudo.rb"

# ///////////////////////////////
# df定義
# ///////////////////////////////
df_hash = Hash.new

# ///////////////////////////////
# 検索対象文書
# ///////////////////////////////
tf_result = Array.new # TFの結果の配列
mor_num_line = Array.new
topic_doc = Array.new

# 文書リストを取得する
filelist = Dir::entries(topic_dir).sort

# 不要な要素を消しておく
filelist.delete(".")
filelist.delete("..")

puts "＊文書の読み込み＊"
puts "using; file : " + dir + ", " + n_best.to_s + "best"

# ///////////////////////////////
# TF
# ///////////////////////////////
for file_num in 0..filelist.size-1 # それぞれの文書について実行
  mor_num = 0 # 文書中の形態素数チェック
  tf_hash= Hash.new # TFのハッシュ
  under = Hash.new
  for i in 1 .. n_best
    res = mcb.parse(NKF.nkf("-w -m0 -Lu", File.read(dir + filelist[file_num] +".txt/#{filelist[file_num]}.txt")))
    for line in res
      str = line.chomp.split(",")
      if str[1] == "名詞"
        mor_num = mor_num + 1.0/i.to_f
        if tf_hash.key?(str[0])
          tf_hash[str[0]] += 1.0/i.to_f
        else
          tf_hash[str[0]] = 1.0/i.to_f
        end
      end
    end
  end
  # ///////////////////////////////
  # DF
  # ///////////////////////////////
  for word in tf_hash.to_a
    if df_hash.key?(word[0])
      df_hash[word[0]] += 1
    else
      df_hash[word[0]] = 1
    end
  end

  tf_result << tf_hash.to_a
  mor_num_line << mor_num

  ## トピック情報のγモデル格納
  res = File.read(topic_dir + filelist[file_num] +"/#{filelist[file_num]}/#{filelist[file_num]}.gamma")
  topic_doc << res.split(/\s+/)
end

# ///////////////////////////////
# IDF
# ///////////////////////////////
idf_hash = Hash.new
for str in df_hash.to_a
  idf_hash[str[0]] = Math::log10(filelist.size.to_f/str[1].to_f) +1.0
end

# ///////////////////////////////
# TF-IDF
# ///////////////////////////////
doc_vector = Array.new # TF-IDFの結果を格納
doc_collection = Hash.new # 文書全体のベクトルの記憶

for doc_num in 0..tf_result.size-1
  tfidf_hash = Hash.new # tfidf_hash: TF-IDFのハッシュ
  # 文書内の単語毎にtfidfを求める
  for word in tf_result[doc_num]
    tfidf_hash[word[0]] = word[1].to_f / mor_num_line[doc_num].to_f
    if doc_collection.key?(word[0])
      doc_collection[word[0]] += word[1].to_f
    else
      doc_collection[word[0]]= word[1].to_f
    end
  end
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

# ///////////////////////////////
# 質問クエリ文
# -------------------------------
# * queryのTFの計算
# * LDAのノルムの計算
# ///////////////////////////////
origin_query_vector = Array.new # 関数query_tfにクエリ毎の形態素数を代入
queryfile = File.read(in_f +"querylist.txt")
originalquery = queryfile.split("\n") # クエリ毎に検索されたwebページのリストの作成
for txt in originalquery
  tf_temp = Hash.new
  # 形態素解析結果ループ
  res = mcb.parse(txt)
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

  tfidf_temp = Hash.new # tfidf計算のためのtemp
  for word in tf_temp # tfidfを求める
    tfidf_temp[word[0]] = word[1].to_f / (tf_temp.size)
  end
  ## クエリ毎の名詞ベクトルに代入
  origin_query_vector << tfidf_temp
end

# LDAノルム
doc_nor_vector = Array.new
for doc_num in 0 .. topic_doc.size-1
  doc_nor = 0
  for nor in topic_doc[doc_num]
    doc_nor += nor.to_f*nor.to_f
  end
  doc_nor_vector << doc_nor
end

# ///////////////////////////////
# web拡張クエリ
# -------------------------------
# * queryのTFの計算
# * LDAのノルムの計算
# ///////////////////////////////
querylist = Dir::entries(in_f) # 各クエリのフォルダ取り出し
querylist.sort!
querylist.delete_if { |x| /\D+/ =~ x }
# 関数query_tfにクエリ毎の形態素数を代入
belonged_query_vector = Array.new

puts "＊拡張クエリ読み込み＊"
puts "using; belonged query : " + in_f

for query_num in 0..querylist.size-1
  puts querylist[query_num]
  # 各ページ毎の形態素数を代入するlex_temp配列
  # lex_temp[0]に1ページ目の形態素数を入れる
  lex_temp = Array.new ### クエリ毎に検索されたwebページのリストの作成
  weblist = Dir::entries(in_f + querylist[query_num])
  weblist.sort!
  weblist.delete(".")
  weblist.delete("..")
  mor_num = 0
  topic_web_arr = Array.new # トピック情報
  for page_num in 0 .. weblist.size-1 # 各クエリのwebページ毎のループ
    lex_temp[page_num] = Hash.new # tf計算のためのtemp配列
    txt = File.read(in_f + querylist[query_num] +"/"+ weblist[page_num])
    txt = txt.toutf8
    txt = NKF.nkf("-w -Lu -m0", txt)
    # 形態素解析結果ループ
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
    
    # トピック推定
    # トピック情報のγモデル格納
    if /(\d+).txt/ =~ weblist[page_num]
      webname = $1
    end
    res = File.read(in_f_two + querylist[query_num] +"/"+ webname + "/" + webname + ".gamma")
    ress = res.split(/\s+/)

    # LDAノルム
    res_nor = 0
    for nor in ress
      res_nor += nor.to_f*nor.to_f
    end
    # 1文書毎にトピック同士のコサイン類似度計算
    for doc_num in 0 .. topic_doc.size-1
      # LDAノルム
      top = 0
      for i in 0 .. ress.size-1
        top += ress[i].to_f*topic_doc[doc_num][i].to_f
      end
      topic_web_arr << top/Math::sqrt(doc_nor_vector[doc_num])/Math::sqrt(res_nor)
    end
  end
  #コサイン類似度の平均を求め、正規化
  mean = 0
  for i in topic_web_arr
    mean += i
  end
  mean /= topic_web_arr.size
  
  # クエリ毎のtf計算のためのtf_temp,tf_tempに代入していく
  tf_temp = Hash.new
  for page_num in 0 .. lex_temp.size-1
    for lex in lex_temp[page_num]
      lex_temp[page_num][lex[0]] = lex[1]*topic_web_arr[page_num] #*undermean
      mor_num += lex[1]*topic_web_arr[page_num] #*undermean
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
  #クエリ毎の名詞ベクトルに代入
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

puts "＊拡張クエリベクトル計算完了＊"


# ///////////////////////////////
# query尤度モデル
# -------------------------------
# * queryのTFの計算
# * LDAのノルムの計算
# ///////////////////////////////
simirality_point = Hash.new # 類似度計算ハッシュ

puts "＊クエリ尤度の計算＊"
puts "using; μ : " + paramator_u.to_s + ", λ : "+paramator_ramda.to_s
# クエリ毎に尤度を計算
# ファイルリストの何番目のファイルか？
for query_num in 0..querylist.size-1
  print querylist[query_num]
  print " : "
  print originalquery[query_num]
  print "\n"
  # 各文書のdoc_vector毎に計算
  for doc_num in 0..doc_vector.size-1
    temp = 0
    # 各質問クエリの名詞毎に計算
    for word in origin_query_vector[query_num]
      # 重みを付与するための分母
      smooth = mor_num_line[doc_num] + paramator_u + paramator_ramda
      # 検索対象文書の名詞情報
      if doc_vector[doc_num].key?(word[0])
        pwd = mor_num_line[doc_num].to_f * doc_vector[doc_num][word[0]].to_f / smooth
      else
        pwd = 0
      end
      # 文書コレクションを用いた重み
      if doc_collection.key?(word[0])
        pwcol = paramator_u * doc_collection[word[0]].to_f / smooth
      else
        pwcol = 0
      end
      # 拡張クエリを用いた重み
      if query_vector.key?(word[0])
        pwweb = paramator_ramda * query_vector[word[0]] / smooth
      else
        pwweb = 0
      end
      temp += word[1] * Math::log(pwd+pwcol+pwweb)
    end
    # 尤度を類似度として記憶
    simirality_point[filelist[doc_num]] = temp
  end

  # コサイン尺度の計算結果を格納
  cos_result = simirality_point.to_a.sort { |a, b| (a[1] <=> b[1]) }
  cos_result.reverse!
  # 類似度の高い順に結果を出力
  out_text = ""
  rank_count = 1
  for i in 0..filelist.size-1
    #out_text = out_text + format("%s\t %10.8f",cos_result[i][0],cos_result[i][1]) + "\n"
    ii = (i+1).to_s

    #  スライドの長さが短いやつを削除
    doc = File.open("./#{dir}#{cos_result[i][0].to_s}.txt/#{cos_result[i][0].to_s}.txt").read
    if doc.size < 100
      #puts "WITHOUT #{cos_result[i][0].to_s} : SIZE #{doc.size.to_s}"
      next
    end

    # ファイルに出力
    out_text = out_text + "<CANDIDATE rank=\"" + (rank_count.to_s) +"\" document=\"" + cos_result[i][0].to_s + "\" /> : " + cos_result[i][1].to_s + "\n"
    rank_count += 1
  end
  foo = File.open(out_f + "/"+querylist[query_num]+".txt", "w")
  foo.puts out_text
  foo.close
end
