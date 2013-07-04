#require 'github-markdown/markdown'
#require 'rubygems'
require 'github/markdown'
require 'nokogiri'
require 'redcarpet'
require 'pp'

module Md2confl
  class Converter
    
    # md to html doc
    def self.get_doc(md)
      html = GitHub::Markdown.render_gfm(md)
      Nokogiri::HTML::DocumentFragment.parse html
    end

    # main converter
    def self.convert(md)
      doc = Converter.get_doc(md)
      modified_doc = MdDoc.new(doc)
      modified_doc.convert()
      modified_doc.to_html
    end

  end

  class MdDoc

    def initialize(doc)
      @doc = doc
    end

    def convert()
      self.convert_codes()
      self.convert_table_lists()
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
        self.get_parent_text(ul.at_css("li")) == "table"
      }

      tables.each{ |table|
        self.convert_table(table)
      }
    end

    def convert_table(parent)
      table_array = self.ul_to_array(parent)
      table = self.array_to_table(table_array)
      parent.replace(table)
    end

    def ul_to_array(parent)
      table = []
      # col = {} # TODO: colに名前付けれるようにする。
      row_cnt = 0
      col_cnt = 0
      parent.css("ul ul").each{ |ul|
        col_cnt = 0
        table[row_cnt] = []
        ul.css("li").each{ |li|
          table[row_cnt][col_cnt] = self.get_parent_text(li)
          col_cnt = col_cnt + 1
        }
        row_cnt = row_cnt + 1
      }
      table
    end

    def array_to_table(array)
      table = self.new_node "table"

      array.each{ |row|

        row_node = self.new_node "tr"
        row.each{ |col|
          col_node = self.new_node "td"
          col_node.content = col
          row_node.add_child(col_node)
        }
        table.add_child(row_node)
      }
      table
    end

  end
end