$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer-macro-contract"

require "pp"
require "delegate"
require "trailblazer/operation"
require "trailblazer/developer"
require "trailblazer/macro"
require "minitest/autorun"

# TODO: convert tests to non-rails.
require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end

module Mock
  class Result
    def initialize(bool); @bool = bool end
    def success?; @bool end
    def errors; ["hihi"] end
  end
end

module Test
  module ReturnCall
    def self.included(includer)
      includer._insert :_insert, ReturnResult, {replace: Trailblazer::Operation::Result::Build}, ReturnResult, ""
    end
  end
  ReturnResult = ->(_last, input, _options) { input }
end

Memo = Struct.new(:id, :body) do
  def self.find(id)
    return new(id, "Yo!") if id

    nil
  end
end
