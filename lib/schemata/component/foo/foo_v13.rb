require 'membrane'
require File.expand_path('../../../helpers/hash_copy', __FILE__)

module Schemata
  module Component
    module Foo
    end
  end
end

module Schemata::Component::Foo
  class V13
    SCHEMA = Membrane::SchemaParser.parse do
      {
        "foo1" => String,
        "foo3" => [Integer],
        "foo4" => String
      }
    end

    MOCK_VALUES = {
      "foo1" => "foo",
      "foo3" => lambda { [Random.rand(11)] },
      "foo4" => Proc.new do
        time = Time.now
        time.to_s
      end
    }

    MIN_VERSION_ALLOWED = 13

    FOO4_DEFAULT = "foo"

    def self.upvert(old_data)
      begin
        Schemata::Component::Foo::V12::SCHEMA.validate(old_data)
      rescue Membrane::SchemaValidationError => e
        raise Schemata::DecodeError.new(e.message)
      end

      new_data = Schemata::HashCopyHelpers.deep_copy(old_data)
      new_data.delete("foo2")
      new_data["foo4"] = FOO4_DEFAULT
      new_data
    end

    def generate_old_fields(aux_data = nil)
      return Schemata::Component::V12.new(contents), {}
    end

    #################################################

    SCHEMA.schemas.keys.each do |k|
      define_method(k.to_sym) do
        Schemata::HashCopyHelpers.deep_copy(@contents[k])
      end

      define_method("#{k}=".to_sym) do |v|
        field_value = Schemata::HashCopyHelpers.deep_copy(v)
        instance_variable_set("@#{k}", field_value)
        @contents[k] = field_value
        begin
          SCHEMA.schemas[k].validate(@contents[k])
        rescue Membrane::SchemaValidationError => e
          raise Schemata::UpdateAttributeError.new(e.message)
        end
        v
      end
    end

    def self.mock
      mock = {}
      MOCK_VALUES.keys.each do |k|
        value = MOCK_VALUES[k]
        mock[k] = value.respond_to?("call") ? value.call : value
      end
      self.new(mock)
    end

    def initialize(msg_data)
      begin
        SCHEMA.validate(msg_data)
      rescue Membrane::SchemaValidationError => e
        raise Schemata::DecodeError.new(e.message)
      end

      @contents = {}
      SCHEMA.schemas.keys.each do |k|
        field_value = Schemata::HashCopyHelpers.deep_copy(msg_data[k])
        instance_variable_set("@#{k}", field_value)
        @contents[k] = field_value
      end
    end

    def contents
      Schemata::HashCopyHelpers.deep_copy(@contents)
    end

    def message_type
      Schemata::Component::Foo
    end

  end
end
