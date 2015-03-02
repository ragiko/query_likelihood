# -*- coding: utf-8 -*-

# HOW TO USE
# 
require 'pp'

SLIDES_PATH = './ntcir11_spoken_target_document'
RESULT_PATH = './result_rank/ntcir11_formalrun_part'
ALPHA = 4000
BETA = 50
QUERY_NUM = 37 # 欲しいクエリまで取得
QUERY_LIST_FILE_PATH = "./expand_query/ntcir11_formalrun_part/querylist.txt"

for query_id in 1..QUERY_NUM
    
    ## 
    # get query contents 
    #
    query = ""
    
    File.open(QUERY_LIST_FILE_PATH) do |f|
        query = f.read.split("\n")[query_id-1]
    end

    
    ##
    # get rank & document & values form result
    #
    rank_doc_vals = []
    
    File.open("#{RESULT_PATH}/#{ALPHA}/#{BETA}/#{format("%02d", query_id)}.txt") do |f|
    
        result_lines = f.read.split("\n")
       
        # get result (rank, name of doc, contents of doc, value ) 
        result_lines.each do |result_line|
            /^.*rank=\"(.*)\".*document=\"(.*)\".* (.*?)$/ =~ result_line
    
            rank = $1 # 順位
            doc_name = $2 # 文書の名前
            doc_contents = ""
            val = $3 # 評価値
            
            # get doc contents   
            File.open("#{SLIDES_PATH}/#{doc_name}.txt/#{doc_name}.txt") do |f|
                doc_contents = f.read
            end

    
            rank_doc_vals << {
		:query => query,
                :rank => rank,
                :doc_name => doc_name,
                :doc => doc_contents,
                :val => val
            }
        end
    end
    
    # show rusult visiblity
    rank_doc_vals.each_with_index do |t, i|
        puts "#############################"
        puts "# query = #{t[:query]}"
        puts "# rank = #{t[:rank]}"
        puts "# slide = #{t[:doc_name]}"
        puts "# value = #{t[:val]}"
        puts "#############################"
        puts t[:doc]
        puts "#############################"
        puts ""
        puts ""
        
        if i >= 5
    	break
        end
    end
    
    
end
