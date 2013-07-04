require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


def fixture(filename)
  fixture_dir = File.expand_path(File.expand_path(File.dirname(__FILE__) + "/fixture"))
  File.open("#{fixture_dir}/#{filename}").read
end

require "./lib/md2confl"
describe "Md2confl" do
  it "convert" do
    converter = Md2confl::Converter.new
    source = fixture("code.md")
    confl = converter.convert(source)

    expect(confl).to eq fixture("code_confl.xml")
  end
end
