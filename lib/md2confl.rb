#require 'github-markdown/markdown'
#require 'rubygems'
require 'github/markdown'
require 'nokogiri'
require 'redcarpet'
require 'md2confl/version'
require 'pp'

module Md2confl

  class Converter
    
    # md to html doc
    def self.get_doc(md)
      html = GitHub::Markdown.render_gfm(md)
      Nokogiri::HTML::DocumentFragment.parse html
    end


    # main converter
    def self.convert(file_path, md)
      
      doc = Converter.get_doc(md)
      modified_doc = MdDoc.new(file_path, doc)
      modified_doc.convert()
      modified_doc.to_html
    end

  end

  class MdDoc
    #file_pathはinludeリンク解決に利用。分離したい。
    def initialize(file_path, doc)
      @file_path = file_path
      @doc = doc
    end

    def convert()
      self.convert_codes()
      self.convert_table_lists()
      self.include_links()
    end

    def to_html()
      @doc.to_xml(:indent => 2)
    end

    def new_node(name)
      Nokogiri::XML::Node.new name, @doc
    end

    def new_cdata(text)
      tmp_doc = Nokogiri::XML::Document.new
      tmp_doc.create_cdata text
    end

    def get_parent_text(node)
      node.at_xpath(".//text()").text.strip
    end


    # code部分を置き換える
    def convert_codes()
      codes = @doc.css "pre"
      codes.each do |code_pre|
        # change parent
        self.convert_code(code_pre)
      end
    end

    def convert_code(parent)
      # modify parent
      parent.name = "ac:macro"
      parent["ac:name"] = "code"
      
      # add parameter
      lang_param = self.new_node "ac:parameter"
      lang_param["lang"] = parent["lang"]
      parent.add_child(lang_param)

      # replace <code> => <ac:plain-text-body>
      code_body = self.new_node "ac:plain-text-body"
      code_body.add_child(self.new_cdata(parent.text))
      parent.add_child(code_body)

      # remove <code>
      parent.search("code").remove

      return parent
    end

    # table list置換
    def convert_table_lists()
      tables = @doc.css('ul').select{ |ul|
        li = ul.at_css("li") # TODO ２つの表が結合されるバグあり
        self.get_parent_text(li) == "table"
      }

      tables.each{ |table|
        self.convert_table(table)
      }
    end

    def convert_table(table_li)
      table_array = self.ul_to_array(table_li)
      table = self.array_to_table(table_array)
      
      table_li.replace(table)
    end

    def ul_to_array(parent)
      table = []
      # col = {} # TODO: colに名前付けれるようにする。
      row_cnt = 0
      col_cnt = 0
      name_mode = ["th","tr"].include?(self.get_parent_text(parent.css("ul")))

      parent.css("ul ul").each{ |ul|
        col_cnt = 0
        table[row_cnt] = []
        if not name_mode
          table[row_cnt][col_cnt] = self.get_parent_text(ul.parent)
          col_cnt = col_cnt + 1
        end
        ul.css("li").each{ |li|
          table[row_cnt][col_cnt] = self.get_parent_text(li)
          col_cnt = col_cnt + 1
        }
        row_cnt = row_cnt + 1
      }
      table
    end

    def array_to_table(array, head_row=0)
      table = self.new_node "table"

      array.each_with_index{ |row, ri|
        node_name = ri == head_row ? "th" : "tr"
        row_node = self.new_node node_name
        row.each{ |col|
          col_node = self.new_node "td"
          col_node.content = col
          row_node.add_child(col_node)
        }
        table.add_child(row_node)
      }
      table
    end

    # include file 分離したい
    def include_links()
      links = @doc.css "a"
      links.each { |link|
        puts link
        title = link.attribute("title")
        if /^include/.match(title)
          self.include_link(link)
        end
      }

    end

    def include_link(link)
      # path
      include_path = File.absolute_path(link.attribute("href"), File.dirname(@file_path))
      
      # read file
      f = open include_path
      include_source = f.read
      f.close
      
      # create snippet
      snippet = Converter.convert(include_path,include_source )  #再帰的になりそうこえー
   
      #replace
      link.replace(snippet)
    end
  end
end