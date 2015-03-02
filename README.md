# query_likelihood

## workspace
* IPアドレス; **.**.**.73
* 作業ディレクトリ: /home/taguchi/query_likelihood_150202/query_likelihood

## 環境導入について
* プロジェクト以下に/home/hasegawa/query_yuudoのシンボリックリンクをプロジェクト以下にhasegawa/で作成

## 1. query_yuudo.rbの編集
```
# query_yuudo.rbの部分を修正
# 検索対象文書の原文
dir = "hasegawa/ntcir11_spoken_target_document/"  # 検索の対象
topic_dir ="hasegawa/lda/ntcir11_spoken_target_document/" # 検索の対象のLDA
expand_query_dir = "hasegawa/expand_query/ntcir11_spoken_tf10/"
expand_query_lda_dir = "hasegawa/lda/model/ntcir11_spoken_tf10/"
```

## 2. クエリ尤度の計算 (最終結果!)
```
# クエリ尤度の計算 
# (comand) (出力ファイル名: [出力先は/home/hasegawa/query-yuudo/result_rank以下])
./Queryyuudo.sh ntcir11_spoken_tf10
```

