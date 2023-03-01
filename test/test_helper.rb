$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "trailblazer-macro-contract"

require "pp"
require 'delegate'
require "trailblazer/operation"
require "trailblazer/macro"
require "trailblazer/developer"
# require "trailblazer/activity/testing"
require "minitest/autorun"

# TODO: convert tests to non-rails.
require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end

Memo = Struct.new(:id, :body) do
  def self.find(id)
    return new(id, "Yo!") if id
    nil
  end
end

# Minitest::Spec.class_eval do
#   include Trailblazer::Activity::Testing::Assertions
# end
