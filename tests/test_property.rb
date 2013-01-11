# -*- coding: utf-8 -*-
require_relative "helpers"

class PropertyTest < Test::Unit::TestCase

  include TiledTmx

  class TestSet
    include TiledTmx::PropertySet
  end

  def test_creation
    set = TestSet.new

    assert_empty(set.properties)
  end

  def test_duplicate
    set = TestSet.new
    set.properties["key"]="value"
    dupped = set.dup
    
    #check if propertyset is equal to an Hash
    assert_equal(set.properties,{"key" => "value"})
    assert_equal({"key" => "value"},set.properties)
    #check if an property set and its copy are equal 
    assert_equal(set.properties,dupped.properties)
    #check if the elements are equal but its copy is not the same object
    assert_equal(set.properties["key"],dupped.properties["key"])
    assert_not_equal(set.properties["key"].object_id,dupped.properties["key"].object_id)
  end

  def test_to_and_from_xml
    set = TestSet.new
    set.properties["key"]="value"
    
    xml = Nokogiri::XML::Builder.new do |xml|
      set.to_xml_properties(xml)
    end.to_xml
    
    noko=Nokogiri::XML(xml)
    
    set2 = TestSet.new
    set2.load_xml_properties(noko)
    assert_equal(set.properties,set2.properties)

    set = TestSet.new
    set.properties[:key]=:value

    xml = Nokogiri::XML::Builder.new do |xml|
      set.to_xml_properties(xml)
    end.to_xml
    
    noko=Nokogiri::XML(xml)
    
    set2 = TestSet.new
    set2.load_xml_properties(noko)
    assert_not_equal(set.properties,set2.properties)

  end


end
