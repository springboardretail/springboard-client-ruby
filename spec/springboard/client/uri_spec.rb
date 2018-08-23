require 'spec_helper'

describe Springboard::Client::URI do
  let(:uri) { described_class.parse('/relative/path') }

  describe "subpath" do
    it "should return a new URI with the path relative to the receiver" do
      expect(uri.subpath('other')).to eq(described_class.parse('/relative/path/other'))
      expect(uri.subpath('/other')).to eq(described_class.parse('/relative/path/other'))
      uri.subpath(described_class.parse('/other')) == described_class.parse('/relative/path/other')
    end
  end

  describe "parse" do
    describe "when called with a URI object" do
      it "should return a cloned URI object" do
        parsed_uri = described_class.parse(uri)
        expect(uri.class).to eq(parsed_uri.class)
        expect(uri.object_id).not_to eq(parsed_uri.object_id)
        expect(parsed_uri.to_s).to eq(uri.to_s)
      end
    end

    describe "when called with a URI string" do
      it "should return a URI based on the given string" do
        uri = described_class.parse('/some_path')
        expect(uri).to be_a(described_class)
        expect(uri.to_s).to eq('/some_path')
      end
    end
  end

  describe "dup" do
    it "should return a duplicate URI object" do
      dup_uri = uri.dup
      expect(uri.class).to eq(dup_uri.class)
      expect(uri.to_s).to eq(dup_uri.to_s)
      expect(uri.object_id).not_to eq(dup_uri.object_id)
    end

    describe "when mutating the copy" do
      it "should not affect the original" do
        dup_uri = uri.dup
        dup_uri.query_values = {per_page: 1}
        expect(uri.to_s).to eq('/relative/path')
        expect(dup_uri.to_s).to eq('/relative/path?per_page=1')
      end
    end
  end

  describe "==" do
    it "should consider two URIs parsed from the same string equal" do
      expect(
        described_class.parse('http://example.com/some_path?a=1&b=2') ==
        described_class.parse('http://example.com/some_path?a=1&b=2')
      ).to be(true)
    end

    it "should consider two URIs parsed from different strings not equal" do
      expect(
        described_class.parse('http://example.com/some_path?a=1&b=2') ==
        described_class.parse('http://example.com/some_path?a=1&c=3')
      ).to be(false)

      expect(
        described_class.parse('http://foo.example.com') ==
        described_class.parse('http://bar.example.com')
      ).to be(false)
    end
  end

  describe "merge_query_values!" do
    it "should merge the given values with the existing query_values" do
      uri.query_values = {'a' => '1', 'b' => '2'}
      uri.merge_query_values! 'c' => '3'
      expect(uri.query_values).to eq(
        {'a' => '1', 'b' => '2', 'c' => '3'}
      )
    end

    it "should overwrite the previous values when a new value is given" do
      uri.query_values = {'a' => '1', 'b' => '2'}
      uri.merge_query_values! 'a' => '3', 'b' => '4'
      expect(uri.query_values).to eq(
        {'a' => '3', 'b' => '4'}
      )
    end

    it "should overwrite the previous values if a new array is given" do
      uri.query_values = {'a' => '1', 'b' => ['2', '3']}
      uri.merge_query_values! 'b' => ['4', '5']
      expect(uri.query_values).to eq(
        {'a' => '1', 'b' => ['4', '5']}
      )
    end

    it "should set the given values if there are no existing query_values" do
      expect(uri.query_values).to be_nil
      uri.merge_query_values! 'a' => ['10'], 'b' => '20', 'c' => '30'
      expect(uri.query_values).to eq({'a' => ['10'], 'b' => '20', 'c' => '30'})
    end
  end

  describe "query_values=" do
    it "should set the string value for the specified key" do
      uri.query_values = {'p1' => '1'}
      expect(uri.query_values).to eq({'p1' => '1'})
    end

    it "should preserve empty bracket notation for array params" do
      uri.query = 'sort[]=f1&sort[]=f2'
      uri.query_values = uri.query_values
      expect(uri.to_s).to eq('/relative/path?sort%5B%5D=f1&sort%5B%5D=f2')
    end

    it "should stringify symbol keys" do
      uri.query_values = {:a => '1'}
      expect(uri.query_values).to eq({'a' => '1'})
    end

    it "should stringify boolean param values" do
      uri.query_values = {:p1 => true, :p2 => false}
      expect(uri.to_s).to eq('/relative/path?p1=true&p2=false')
    end

    it "should support hash param values" do
      uri.query_values = {:a => {:b => {:c => 123}}}
      expect(uri.to_s).to eq(
        '/relative/path?a=%7B%22b%22%3D%3E%7B%22c%22%3D%3E123%7D%7D'
      )
    end

    it "should add [] to the key for array values" do
      uri.query_values = {:a => ['1', '2', '3']}
      expect(uri.query).to eq('a%5B%5D=1&a%5B%5D=2&a%5B%5D=3')
    end

    it "should remove duplicate values for the same key" do
      uri.query_values = {:a => ['1', '1', '2']}
      expect(uri.query_values).to eq({'a' => ['1', '2']})
    end
  end

  describe "query_values" do
    it "should return the current query values" do
      uri.query = 'sort[]=f1&sort[]=f2&per_page=all'
      uri.query_values = uri.query_values
      expect(uri.query_values).to eq({'sort' => ['f1', 'f2'], 'per_page' => 'all'})
    end

    it "should remove [] from array keys" do
      uri.query = 'sort[]=f1&sort[]=f2'
      uri.query_values = uri.query_values
      expect(uri.query_values).to eq({'sort' => ['f1', 'f2']})
    end
  end
end
