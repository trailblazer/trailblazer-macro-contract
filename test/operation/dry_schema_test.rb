require 'test_helper'
require 'dry-validation'

class DrySchemaTest < Minitest::Spec
  Song = Struct.new(:title)

  class Create < Trailblazer::Operation
    SongSchema = Dry::Validation.Schema do
      required(:title).filled
    end

    step Model(Song, :new)
    step Contract::Validate(schema: SongSchema)
  end

  # success
  it do
    result = Create.(params: { title: "SVG" })
    result.success?.must_equal true
    result["result.contract.default"].success?.must_equal true
    result["result.contract.default"].errors.messages.must_equal({})
  end

  # failure
  it do
    result = Create.(params: { title: nil })
    result.success?.must_equal false
    result["result.contract.default"].success?.must_equal false
    result["result.contract.default"].errors.messages.must_equal(title: ["must be filled"])
  end

  class Update < Trailblazer::Operation
    SongSchema = Dry::Validation.Schema do
      required(:title).filled
    end

    step Model(Song, :new)
    step Contract::Validate(schema: SongSchema, key: :song)
  end

  # success
  it do
    result = Update.(params: { song: { title: "SVG" } })
    result.success?.must_equal true
    result["result.contract.default"].success?.must_equal true
    result["result.contract.default"].errors.messages.must_equal({})
  end

  # failure
  it do
    result = Update.(params: { song: { title: nil } })
    result.success?.must_equal false
    result["result.contract.default"].success?.must_equal false
    result["result.contract.default"].errors.messages.must_equal(title: ["must be filled"])
  end
end
