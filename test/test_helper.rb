require "minitest/autorun"
require "trailblazer/macro/contract"
require "trailblazer/operation"
require "trailblazer/developer"
require "trailblazer/core"

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

# FIXME: who loads the macros where?
# [Trailblazer::Operation].each do |topology|
[Trailblazer::Activity::FastTrack,  # DISCUSS: remove?
  Trailblazer::Operation # we need to add this because we're using :adds, so both normalizers get updated.
].each do |topology|
  _, _, builder, helpers_module = Trailblazer::Activity::DSL::Topology.build(
    builder: topology.config.builder,
    default_options: {},
    **Trailblazer::Macro::Contract::TOPOLOGY_BUILD_OPTIONS # :helpers and :adds
  )

  topology.config.builder = builder
  topology.include helpers_module
end

[Trailblazer::Activity::FastTrack,  # DISCUSS: remove?
  Trailblazer::Operation # we need to add this because we're using :adds, so both normalizers get updated.
].each do |topology|
  _, _, builder, helpers_module = Trailblazer::Activity::DSL::Topology.build(
    builder: topology.config.builder,
    default_options: {},
    **Trailblazer::Macro::TOPOLOGY_BUILD_OPTIONS # :helpers and :adds
  )

  topology.config.builder = builder
  topology.include helpers_module
end

T = Trailblazer::Core

Minitest::Spec.class_eval do
  include Trailblazer::Core::Utils::AssertRun
  include Trailblazer::Core::Utils::AssertEqual
end
