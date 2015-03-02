# map.rb
# mapすいてい！
# 第一引数：各講演の結果が昇順でならんでいるフォルダ
#		やっぱりスラッシュ込みで指定

## $KCODE: 使用する文字コード 
$KCODE="UTF-8"
require 'MeCab'
require 'csv'
require 'kconv' #文字変換

#print "beginning map.rb\n"

# 上位何件参照か定義
line_lim = 1000

# 正解の置いてあるフォルダ
queryline = "querylist/SDR_QueryAndReferenceSet.txt"

query_txt = File.read(queryline)
# 各クエリ毎の正解講演を格納する配列query_list
query_list = Array.new
# 最所だけの暫定処理
listtemp = nil
for line in query_txt
# 区切り部分でこれまでの結果を格納する→宣言
 if /----------/ =~ line 
  if listtemp != nil
   query_list << listtemp.uniq
  end
  listtemp = Array.new
# 講演名抜きだし
 elsif /^([A-Z][0-9]{2}[A-Z][0-9]{4})\s*[0123456789-]*\s([IRP])/ =~ line
  if "R" == $2
   listtemp << $1
  end
 end
end
   query_list << listtemp.uniq
#p query_list

######
## 結果を読み込む
#	番号か何かふって、ソートしたときに上から１つめのクエリのファイルになるようにしてね
passagelist = Dir::entries(ARGV[0])
passagelist.sort!
passagelist.delete(".")
passagelist.delete("..")

#各講演のap値を入れるap_arr
ap_arr = Array.new
# 結果ファイルごとに
for list_num in 0..passagelist.size-1
 ranklist = File.read(ARGV[0] + passagelist[list_num])
 i = 1
 # 各文書と順位を算出→ans_list
 ans_list = Hash.new
 	for line in ranklist
 	 #その行にある文書番号を抽出
	 if /([A-Z][0-9]{2}[A-Z][0-9]{4})/ =~ line
	  ans_num = $1
	 end
 	 # 文書番号と順位を格納
 	 ans_list.store(ans_num,i)
 	 i= i+1
 	 #　上限越えたら強制ループ抜け
 	 if i == line_lim
 	  break
	 end
	end
 # 正解文書を算出
 rank_list = Array.new
 for cor in query_list[list_num]
  if ans_list.key?(cor)
   rank_list << ans_list[cor]
  end
 end
 rank_list.sort!
 rank_list.uniq!


 # ap計算部分
 ap = 0
 for j in 1..rank_list.size
  ap = ap + j/rank_list[j-1].to_f
 end
# 確認表示
#  passagelist[list_num]
#  query_list[list_num]
#  rank_list

 ap_arr << ap/query_list[list_num].size
end


for ap in ap_arr
# print ap.to_s + "\t"
end

# map計算
map = 0
for ap in ap_arr
 map = map + ap
end
map = map/ap_arr.size

print "MAP : "
print map.to_s + "\n"
#print "ending map.rb\n" 
  
 
