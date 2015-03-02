# query_likelihood

## 長谷川さんのサーバの場所
* IPアドレス; **.**.**.73
* 作業ディレクトリ; /home/hasegawa/query-yuudo/lda

## 1. LDAを作成する
* 作業ディレクトリ; /home/hasegawa/query-yuudo/lda

## コマンド例; クエリをWEB拡張した文書に対するLDA

```
# (comand) (入力ファイル) (出力ファイル[出力先は/home/hasegawa/query-yuudo/lda以下])
./Enter2.sh ../expand_query/ntcir11_spoken_tf10/ ntcir11_spoken_tf10
```

## コマンド例; 検索対象原文文書に対するLDA

```
# (comand) (入力ファイル) (出力ファイル)
./Enter2.sh ../ntcir11_spoken_target_document/ ntcir11_spoken_target_document
```

## 2. query_yuudo.rbの編集
* 作業ディレクトリ; /home/hasegawa/query-yuudo

```
# query_yuudo.rbの部分を修正
# 検索対象文書の原文
dir = "ntcir11_spoken_target_document/"
# 検索対象文書のLDAの結果のディレクトリ
topic_dir ="lda/ntcir11_spoken_target_document/"
```

```
# query_yuudo.rbの編集
vi query_yuudo.rb
# ちなみにquery_yuudo.rbは結構いじってあって、長谷川さんの元のファイルはquery_yuudo.rb_cpです
# sumPMIが正の単語は250行目くらいの，PMI_WORD_FILTERSの中に二重配列にして直書きしないとダメです
```

## 3. クエリ尤度の計算 (最終結果!)
* 作業ディレクトリ; /home/hasegawa/query-yuudo

```
# クエリ尤度の計算 
# (comand) (入力ファイル: WEB拡張クエリのPATH, WEB拡張クエリのLDAのパス) (出力ファイル: [出力先は/home/hasegawa/query-yuudo/result_rank以下])
./Queryyuudo.sh expand_query/ntcir11_spoken_tf10/ lda/model/ntcir11_spoken_tf10/ ntcir11_spoken_tf10
```

