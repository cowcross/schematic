require "spec_helper"

describe Schematic::Serializers::Xsd do
  before do
    class EmptyModel < ActiveRecord::Base

      def self.columns
        []
      end
    end
  end

  describe ".to_xsd" do

    context "XSD validation" do
      context "when the model is not namespaced" do
        subject { SomeModel.to_xsd }

        with_model :some_model do
          table do |t|
            t.string "some_string"
            t.float "some_float"
            t.integer "some_integer"
            t.datetime "some_datetime"
            t.date "some_date"
            t.boolean "some_boolean"
          end

          model do
            validates :some_string, :presence => true
            validates :some_date, :presence => true, :allow_blank => true
            validates :some_datetime, :presence => true, :allow_blank => false

            class << self
              def xsd_methods
                {:foo => { :bar => { :baz => nil }, :quz => [:qaz] } }
              end
            end
          end

        end

        it "should generate a valid XSD" do
          validate_xsd(subject)
        end

        it "should validate against it's own XSD" do
          instance = SomeModel.new(:some_string => "ExampleString",
                                   :some_date => Date.today,
                                   :some_datetime => DateTime.new,
                                   :some_boolean => true,
                                   :some_float => 1.5,
                                   :some_integer => 2)
          xml = [instance].to_xml

          validate_xml_against_xsd(xml, subject)
        end
      end

      context "when the model is namespaced" do
        before do
          module Namespace; end
        end

        subject { Namespace::SomeModel.to_xsd }

        with_model :some_model do
          table do |t|
            t.string "some_string"
          end

          model do
            validates :some_string, :presence => true
          end

        end

        before do
          class Namespace::SomeModel < SomeModel
          end
        end

        it "should generate a valid XSD" do
          validate_xsd(subject)
        end
      end

      context "when the model has a nested attribute on a subclass with a reference to the superclass" do
        with_model :parent do
          table {}
          model do
            has_many :children
            accepts_nested_attributes_for :children
          end
        end

        with_model :child do
          table do |t|
            t.integer :parent_id
          end

          model do
            belongs_to :parent
          end
        end

        before do
          module Namespace; end
          class Namespace::Child < Child
            accepts_nested_attributes_for :parent
          end
        end

        subject { Namespace::Child.to_xsd }

        it "should generate a valid XSD" do
          validate_xsd(subject)
        end
      end

      context "when the model has a circular nested attribute reference" do
        with_model :blog do
          table {}
          model do
            has_many :posts
            accepts_nested_attributes_for :posts
          end
        end

        with_model :post do
          table do |t|
            t.integer :blog_id
          end

          model do
            belongs_to :blog
            accepts_nested_attributes_for :blog
          end
        end

        subject { Post.to_xsd }

        it "should generate a valid XSD" do
          validate_xsd(subject)
        end

      end
    end

    context "for an empty model with no attributes or validations" do
      subject { sanitize_xml(EmptyModel.to_xsd) }

      it "should return an xsd for an array of the model" do
        xsd = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
            <xs:element name="empty-models" type="EmptyModels"/>
            <xs:complexType name="EmptyModels">
              <xs:sequence>
                <xs:element name="empty-model" type="EmptyModel" minOccurs="0" maxOccurs="unbounded"/>
              </xs:sequence>
              <xs:attribute name="type" type="xs:string" fixed="array"/>
            </xs:complexType>
            <xs:complexType name="EmptyModel">
              <xs:all>
              </xs:all>
            </xs:complexType>
          </xs:schema>
        XML
        subject.should == sanitize_xml(xsd)
      end

    end

    context "for a model with attributes" do

      subject { sanitize_xml(SomeModel.to_xsd) }

      context "for a any attribute" do
        with_model :some_model do
          table :id => false do |t|
            t.float 'some_float'
          end
        end

        it "should define the correct xsd element" do
          xsd = generate_xsd_for_model(SomeModel) do
            <<-XML
              <xs:element name="some-float" minOccurs="0" maxOccurs="1">
                <xs:complexType>
                  <xs:simpleContent>
                    <xs:extension base="xs:float">
                      <xs:attribute name="type" type="xs:string" use="optional"/>
                    </xs:extension>
                  </xs:simpleContent>
                </xs:complexType>
              </xs:element>
            XML
          end

          subject.should == xsd
        end

      end

      describe "additional methods" do
        with_model :some_model do
          table {}
        end

        it "should include the additional method" do
          xsd = generate_xsd_for_model(SomeModel) do
            <<-XML
              <xs:element name="id" minOccurs="0" maxOccurs="1">
                <xs:complexType>
                  <xs:simpleContent>
                    <xs:extension base="xs:integer">
                      <xs:attribute name="type" type="xs:string" use="optional"/>
                    </xs:extension>
                  </xs:simpleContent>
                </xs:complexType>
              </xs:element>
              <xs:element name="foo-bar" minOccurs="0" maxOccurs="1"/>
            XML
          end

          sanitize_xml(SomeModel.to_xsd(:methods => {:foo_bar => nil})).should == xsd
        end
      end

    end

  end

end
