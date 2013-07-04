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
    end

    def to_html()
      @doc.to_xml
    end


    def new_node(name)
      Nokogiri::XML::Node.new name, @doc
    end

    def new_cdata(text)
      tmp_doc = Nokogiri::XML::Document.new
      tmp_doc.create_cdata text
    end


    # code部分を置き換える
    def convert_codes()
      codes = @doc.css "pre"
      codes.each do |code_pre|
        # change parent
        self.convert_code(code_pre)
      end
    end

    def convert_code(code_pre)
      # modify parent
      code_pre.name = "ac:macro"
      code_pre["ac:name"] = "code"
      
      # add parameter
      lang_param = self.new_node "ac:parameter"
      lang_param["lang"] = code_pre["lang"]
      code_pre.add_child(lang_param)

      # replace <code> => <ac:plain-text-body>
      code_body = self.new_node "ac:plain-text-body"
      code_body.add_child(self.new_cdata(code_pre.text))
      code_pre.add_child(code_body)

      # remove <code>
      code_pre.search("code").remove
      return code_pre
    end

  end
end