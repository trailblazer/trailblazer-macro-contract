require "test_helper"
require "dry/validation"

class ContractTest < Minitest::Spec
  Song = Struct.new(:title)
  #---
  #- validate
  class ValidateTest < Minitest::Spec
    #---
    # Contract::Validate[]
    class Update < Trailblazer::Operation
      class Form < Reform::Form
        property :title
        validates :title, presence: true
      end

      step Model( Song, :new )
      step Contract::Build( constant: Form )
      step Contract::Validate() # generic validate call for you.

      # include Procedural::Validate
      ->(*) { validate(options["params"][:song]) } # <-- TODO
    end

    # success
    it do
      result = Update.(params: {title: "SVG"})
      result.success?.must_equal true
      result[:"result.contract.default"].success?.must_equal true
      result[:"result.contract.default"].errors.messages.must_equal({})
    end

    # failure
    it do
      result = Update.(params: {title: nil})
      result.success?.must_equal false
      result[:"result.contract.default"].success?.must_equal false
      result[:"result.contract.default"].errors.messages.must_equal({:title=>["can't be blank"]})
    end

    #---
    # Contract::Validate[key: :song]
    class Upsert < Trailblazer::Operation
      class Form < Reform::Form
        property :title
        validates :title, presence: true
      end

      step Model( Song, :new ) # FIXME.
      step Contract::Build( constant: Form )
      step Contract::Validate( key: :song) # generic validate call for you.
      # ->(*) { validate(options["params"][:song]) } # <-- TODO
      step Contract::Persist( method: :sync )
    end

    # success
    it { Upsert.(params: {song: { title: "SVG" }}).success?.must_equal true }
    # failure
    it { Upsert.(params: {song: { title: nil }}).success?.must_equal false }
    # key not found
    it { Upsert.(params: {}).success?.must_equal false }
    # no params passed
    it { Upsert.().success?.must_equal false } 

    #---
    # contract.default.params gets set (TODO: change in 2.1)
    it { Upsert.( params: {song: { title: "SVG" }})[:params].must_equal({:song=>{:title=>"SVG"}} ) }
    it { Upsert.( params: {song: { title: "SVG" }})[:"contract.default.params"].must_equal({:title=>"SVG"} ) }

    #---
    #- inheritance
    class New < Upsert
    end

    it { Trailblazer::Developer.railway(New).must_equal %{[>model.build,>contract.build,>contract.default.validate,>persist.save]} }

    #- overwriting Validate
    class NewHit < Upsert
      step Contract::Validate( key: :hit ), override: true
    end

    it { Trailblazer::Developer.railway(NewHit).must_equal %{[>model.build,>contract.build,>contract.default.validate,>persist.save]} }
    it { NewHit.(params: {:hit => { title: "Hooray For Me" }}).inspect(:model).must_equal %{<Result:true [#<struct ContractTest::Song title=\"Hooray For Me\">] >} }
  end
end

# TODO: full stack test with validate, process, save, etc.
