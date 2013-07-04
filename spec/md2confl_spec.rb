# -*- encoding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "./lib/md2confl"

# fixture reader
def fixture(filename)
  fixture_dir = File.expand_path(File.expand_path(File.dirname(__FILE__) + "/fixture"))
  File.open("#{fixture_dir}/#{filename}").read
end

describe "Md2confl" do

  it "<code>がatlassianのcode block用の書式に変換される" do
    source = fixture("code.md")
    confl = Md2confl::Converter.convert(source)
    expect(confl).to eq fixture("code_confl.xml")
  end

  it "リストがtableの場合、tableタグに変換される" do
    confl = Md2confl::Converter.convert(fixture("table.md"))
    expect(confl).to eq fixture("table_confl.xml")
  end

end
