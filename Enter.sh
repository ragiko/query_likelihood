
#!/bin/sh
# 文章をそのままyahoo!APIで検索して出力する
# 第一引数：質問文が１行事に記してあるテキスト
# 第二引数：拡張クエリの出力名(expand_query内に生成。)
#          :ほぼ同名のLDAトピックモデルはlda/model内に生成
# 第三引数：上限検索数
# 第四引数：最終結果(result_rankフォルダに生成)

# 変数宣言
query="${1}"
searchnum="${3}"
query_num=0

#. ./YahooSearch.sh ${1} ${2} ${3}

cd lda
# . ./Enter2.sh ../expand_query/${2}
# mv output model/topicmodel_${2}
cd ../

. ./Queryyuudo.sh /expand_query/${2} lda/model/topicmodel_${2} ${4}



