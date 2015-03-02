## $KCODE: 使用する文字コード 
$KCODE="UTF-8"
require 'MeCab'
require 'csv'
require 'kconv' #文字変換

  in_temp=File.read(ARGV[0])	
  in_temp = in_temp.toutf8
  voi_array = Array.new
  voi_array = in_temp.split("\s")

 out_temp=File.open(ARGV[1],"w")
for temp in voi_array
 out_temp << temp + "\n"
end
