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
require "pp"

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
dir = "ntcir11_spoken_target_document/"
# dir = "/home/hara/Develop/NTCIR11/Data/jout_for_lda/"
# 検索の対象のLDA
topic_dir ="/home.old/hara/ldaResult/lda-slide/"
# topic_dir ="/home.old/hara/ldaResult/lda-lecture2/"

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
        res = mcb.parse(NKF.nkf("-w -m0 -Lu", File.read(dir + filelist[file_num] +".txt/#{filelist[file_num]}.txt")).delete(" "))




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
# PMI_WORD_FILTERS = [
# ["キーワード", "方法", "そん", "問題", "点", "論文"],
# ["定式", "化", "手法", "構造"],
# ["ー", "検索", "文字", "列", "修正", "固定", "長", "さ", "分割", "の", "ん", "母音", "挿入", "推定", "システム", "今回", "よう", "こと", "可能", "性"],
# ["ー", "今回", "未知", "語", "の", "ん", "よう", "漠然", "考慮"],
# ["ー", "データー", "単語", "研究", "キーワード", "音声", "ん", "件数", "検討", "検出", "特性", "日本語", "場合", "モーラ", "等", "近似", "直前", "よう", "認識", "誤り", "音節", "影響", "脱落", "挿入", "の", "件", "これ", "仕組み", "問題", "説明", "発表"],
# ]
PMI_WORD_FILTERS = [
    ["ネットワーク", "音声", "検索", "未知", "語", "結果"],
    ["分割", "文", "統計", "的", "手法"],
    ["ツール", "スピーカー", "うそ", "がま", "の", "かって"],
    ["尤", "度", "ー", "フィラー", "の", "かま", "程"],
    ["本人", "よう", "ん", "こと", "原因", "の"],
    ["モデル", "言語", "パープレキシティー", "性能", "評価", "ギャル", "直感", "的", "ユーザー", "単語", "予測", "能力", "こと", "値", "知識", "研究", "文", "分野", "かま", "応用", "ーパープレキシティー"],
    ["ーサブレッド", "ー", "僕", "毎日", "生活", "何", "みたい", "話", "ライブ", "くだ", "頃", "課程", "小", "ん", "なん", "日", "駄目"],
    ["ーアラインメント", "機械", "一", "目", "アラインメント", "種", "ースライド"],
    ["ＩＢＭ", "言語", "説明", "回路", "単語"],
    ["話し方", "研究", "もの", "声", "明瞭"],
    ["コーパス", "話し言葉", "フィラー", "導入", "こと", "言語", "モデル", "音声", "システム", "性能", "よう", "結果"],
    ["ドキュメント", "構成", "検索", "音声", "情報", "騒音", "データー", "際", "手法", "フレーム", "フル", "テキスト", "選択", "フレームインデックスエ", "よう", "ウェブテキスト", "インデックス", "作成", "方法", "スライド"],
    ["強調", "発話", "検出", "よう"],
    ["位置", "情報", "発話", "ケース", "リコール", "値"],
    ["ドキュメント", "音声", "検索", "未知", "語", "一つ", "認識", "用", "辞書", "登録", "問題", "論文"],
    ["認識", "音声", "テキスト", "話し言葉", "書き言葉", "文", "論文", "付け", "方法", "説明", "特徴", "手法"],
    ["自動", "要約", "研究", "音声", "認識", "話し言葉", "内容", "書き", "重要", "むものかとかそういう", "部分", "抽出", "文", "判定", "特徴", "付け", "ニュース", "手法", "具体", "的"],
    ["中継", "野球", "構成", "要素"],
    ["五", "十", "一", "二"],
    ["三", "十", "四", "二月", "五", "一", "歳"],
    ["衰退", "叩き", "認識", "誤り", "解決", "システム", "化"],
    ["人", "英語", "翻訳", "日本語", "普通"],
    ["ドキュメント", "検索", "ワード", "システム", "ー", "幸福", "フォワード", "列", "分割", "音素", "固定", "テール", "点火", "方法", "選択"],
    ["音声", "メント", "文字", "列", "検索", "システム", "高速", "化", "論文", "講義", "データーベース", "実験", "考察", "未知", "語", "よう", "今回", "手法", "後悔", "今後", "変更"],
    ["動画", "島", "の", "場所", "どこ", "気"],
    ["検索", "父", "よう", "話し言葉", "システム"],
    ["論文", "紹介", "真っ赤", "呼吸", "ープラス"],
    ["一", "方法", "説明", "数値", "分"],
    ["一", "三", "四", "五", "認識", "誤り", "対処", "精度", "連続", "ＤＰ", "時間", "立川"],
    ["広場", "ドキュメント", "検索", "公園", "メール", "長音", "従来", "ＰＲ"],
    ["データー", "収録", "音声", "認識", "どれ", "発話", "データーセット", "全体"],
    ["信頼", "度", "スコア", "確信", "元", "モデル"],
    ["簡単", "ＳＴＤ", "音声", "認識", "器", "ネットワーク", "構成", "マッチング", "研究", "ＤＰ", "コンピューター", "ノード", "複数", "お力", "提案", "スコア", "説明"],
    ["簡単", "セクション", "ＣＤ", "研究", "幾つ", "操作", "以下", "例", "検索", "対象", "木", "構造", "変換", "探索", "京都", "クエリー", "決定", "場合", "分割", "手法", "検出", "誤り", "原子", "部分", "説明"],
    ["ビデオ", "録音", "録画", "分割", "音声", "認識", "用", "誤り", "置換", "挿入", "脱落", "マット", "実験"],
    ["音声", "ベクトル", "スペクトル", "帯域", "ごと", "パワー", "方法", "バイク", "混合", "音"],
    ["的", "統計", "機械", "翻訳", "対", "訳文", "二つ", "対訳", "ー", "計算", "機", "枠組み", "理論", "原理", "説明", "スライド", "お願い"],
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
        # puts "reading::#{in_f}#{querylist[query_num]}#{weblist[page_num]}"    # 10/21 原 追加
        txt = File.read(in_f + querylist[query_num] +"/"+ weblist[page_num])
        txt = txt.toutf8
        txt = NKF.nkf("-w -Lu -m0",txt)


        #### 形態素解析結果ループ
        # 10/21 原 try-catchブロック追加

        begin
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
        rescue
            puts "Error occured in #{in_f}#{querylist[query_num]}#{weblist[page_num]}"
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
        # doc = File.open("./#{dir}#{cos_result[i][0].to_s}.txt/#{cos_result[i][0].to_s}.txt").read 
        doc = File.open("#{dir}#{cos_result[i][0].to_s}.txt/#{cos_result[i][0].to_s}.txt").read 
        if doc.size < 100
            #puts "WITHOUT #{cos_result[i][0].to_s} : SIZE #{doc.size.to_s}"
            next
        end

        # ファイルに出力
        out_text = out_text + "<CANDIDATE rank=\"" + (rank_count.to_s) +"\" document=\"" + cos_result[i][0].to_s + ".txt"  + "\" /> : " + cos_result[i][1].to_s + "\n"
        rank_count += 1
        ###

    end
    foo = File.open(out_f + "/"+querylist[query_num]+".txt","w")
    #puts out_text
    foo.puts out_text
    foo.close
end
