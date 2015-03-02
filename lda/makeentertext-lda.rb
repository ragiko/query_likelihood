
# makeentertext.lda.rb
# テキストをldaの入力用のデータにするプログラム
# 第一引数：学習用lex
# 第二引数：キーワードを抜きたいテキスト
# 第三引数：出力


## $KCODE: 使用する文字コード 
$KCODE="UTF-8"
require 'MeCab'
require 'csv'
require 'kconv' #文字変換

print "beginning maketext_lda.rb\n"
puts


## mcb: MeCabの出力形式
mcb = MeCab::Tagger.new("--node-format=%m\,%f[0]\\n --eos-format=")


# 引数の数をチェック
if ARGV.size != 3
	puts "Syntax Error!!"
	exit(-1)
else
  in_f=File.read(ARGV[1])	
  in_f = in_f.toutf8
  out_f=File.open(ARGV[2],"w")	##出力形態
  out_lex=File.open(ARGV[2]+".lex","w")
  out_t=File.open(ARGV[2]+".topic","w")
end

#　キーとなる形態素を入れる関数lex
lex = Array.new

######
# lex取り出し
  o_lex=File.read(ARGV[0]+".lex")	
  o_lex = o_lex.toutf8
######

# 関数lexに形態素を代入する
lex = o_lex.split(/\n/)


######
# 形態素毎に番号を割り振る
# キー値：形態素　値：番号
lex_hash = Hash.new

count = 0
for mor in lex
	count = count + 1
	lex_hash.store(mor, count) 
	out_lex << mor + "\n"
end



######
# 各文章毎の形態素数を番号を元に出力

# 文章一時保存用変数txt
txt = ""

in_f << "\n[eos]"
# 行数番人count
count = 0
# フレーム毎にトピック境界が存在するかを記憶する関数topicboundary
# １フレーム計算毎にカウントする番人topicboundary_count
topicboundary = Array.new
topicboundary_count=0
topicboundary[0]=0

for line in in_f
	# 最終ループは問答無用で外れ
	if /\[eos\]/ =~ line
	else
	## 改行のみの行で文章を区切る
		if line == "\n"
			topicboundary[topicboundary_count]=1
			next
	## 3文集まるまで1フレームとしない
		elsif count < 2
			txt += line
			count=count+1
			next
		end 
	end
#	txt = line
	# 文章毎の形態素数をカウントするtxt_hashの宣言／リセット
	# キー値：形態素　値：数
	txt_hash = Hash.new
	#　形態素解析
	txt = NKF.nkf("-w -Lu -m0",txt)
	res = mcb.parse(txt)
	  # 形態素解析
	res = (res).split(/\s*\n\s*/)
	for row in res
	  row = row.split(",")
	   if row[1] == "名詞"

	    # lex内に存在する場合にカウント
	    if lex_hash.key?(row[0])
		# 二回目以降は既存値+1
		# 初回のみtxtハッシュに追加
		if txt_hash.key?(row[0])
		  txt_hash[row[0]] = txt_hash[row[0]] + 1
		else
		  txt_hash.store(row[0], 1)
		end
	   end

	  end
	end
	# 結果を出力
	# 出力用変数txt_out
	txt_out = ""
	# 出力フォーマット
	# (形態素番号):(形態素個数) (形態素番号):(形態素個数) ・・・
	for mor in txt_hash
	   txt_out = txt_out + lex_hash[mor[0]].to_s + ":" + txt_hash[mor[0]].to_s + " "
	end
	out_f << txt_out + "\n"		

	# txtのクリア
	txt = ""
	count = 0
	topicboundary_count=topicboundary_count+1
	topicboundary[topicboundary_count]=0
end
	

topicboundary[topicboundary_count]=2

for line in topicboundary
	out_t << line
	out_t << "\n"
end

print "end maketext_lda.rb\n"
