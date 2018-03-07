require "test_helper"

class DocsContractOverviewTest < Minitest::Spec
  Song = Struct.new(:length, :title)

  #:overv-reform
  # app/concepts/song/create.rb
  class Create < Trailblazer::Operation
    #~contractonly
    class MyContract < Reform::Form
      property :title
      property :length

      validates :title,  presence: true
      validates :length, numericality: true
    end
    #~contractonly end

    step Model( Song, :new )
    step Contract::Build(constant: MyContract)
    step Contract::Validate()
    step Contract::Persist( method: :sync )
    #~contractonly end
  end
  #:overv-reform end

  puts Trailblazer::Operation::Inspect.(Create, style: :rows)

=begin
  #:overv-reform-pipe
   0 ==========================&model.build
   1 =======================>contract.build
   2 ==============&validate.params.extract
   3 ====================&contract.validate
   4 =========================&persist.save
  #:overv-reform-pipe end
=end

  it do
    assert Create.(params: {})["contract.default"].must_be_instance_of DocsContractOverviewTest::Create::MyContract
  end

  #- result
  it do
    #:result
    result = Create.(params: { length: "A" })

    result["result.contract.default"].success?        #=> false
    result["result.contract.default"].errors          #=> Errors object
    result["result.contract.default"].errors.messages #=> {:length=>["is not a number"]}

    #:result end
    result["result.contract.default"].success?.must_equal false
    result["result.contract.default"].errors.messages.must_equal ({:title=>["can't be blank"], :length=>["is not a number"]})
  end

  it "shows 2-level tracing" do
    result = Create.trace( params: { length: "A" } )
    result.wtf.gsub(/0x\w+/, "").must_equal %{|-- #<Trailblazer::Activity::Start semantic=:default>
|-- model.build
|-- contract.build
|-- contract.default.validate
|   |-- #<Trailblazer::Activity::Start semantic=:default>
|   |-- contract.default.params_extract
|   |-- contract.default.call
|   `-- #<Trailblazer::Activity::End semantic=:failure>
`-- #<Trailblazer::Operation::Railway::End::Failure semantic=:failure>}
  end
end
#---
# contract MyContract
class DocsContractExplicitTest < Minitest::Spec
  Song = Struct.new(:length, :title)

  #:reform-inline
  class MyContract < Reform::Form
    property :title
    property :length

    validates :title,  presence: true
    validates :length, numericality: true
  end
  #:reform-inline end

  #:reform-inline-op
  # app/concepts/comment/create.rb
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build(constant: MyContract)
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end
  #:reform-inline-op end
end

#- Validate with manual key extraction
class DocsContractSeparateKeyTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #:key-extr
  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    def type
      "evergreen" # this is how you could do polymorphic lookups.
    end

    step Model( Song, :new )
    step Contract::Build(constant: MyContract)
    step :extract_params!
    step Contract::Validate( skip_extract: true )
    step Contract::Persist( method: :sync )

    def extract_params!(options, **)
      options["contract.default.params"] = options[:params][type]
    end
  end
  #:key-extr end

  it { Create.(params: { }).inspect(:model).must_equal %{<Result:false [#<struct DocsContractSeparateKeyTest::Song id=nil, title=nil>] >} }
  it { Create.(params: {"evergreen" => { title: "SVG" }}).inspect(:model).must_equal %{<Result:true [#<struct DocsContractSeparateKeyTest::Song id=nil, title="SVG">] >} }
end

#---
#- Contract::Build( constant: XXX )
class ContractConstantTest < Minitest::Spec
  Song = Struct.new(:title, :length) do
    def save
      true
    end
  end

  #:constant-contract
  # app/concepts/song/contract/create.rb
  module Song::Contract
    class Create < Reform::Form
      property :title
      property :length

      validates :title,  length: 2..33
      validates :length, numericality: true
    end
  end
  #:constant-contract end

  #:constant
  class Song::Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
    step Contract::Validate()
    step Contract::Persist()
  end
  #:constant end

  it { Song::Create.(params: { title: "A" }).inspect(:model).must_equal %{<Result:false [#<struct ContractConstantTest::Song title=nil, length=nil>] >} }
  it { Song::Create.(params: { title: "Anthony's Song", length: 12 }).inspect(:model).must_equal %{<Result:true [#<struct ContractConstantTest::Song title="Anthony's Song", length=12>] >} }
  it do
    #:constant-result
    result = Song::Create.(params: { title: "A" })
    result.success? #=> false
    result["contract.default"].errors.messages
    #=> {:title=>["is too short (minimum is 2 characters)"], :length=>["is not a number"]}
    #:constant-result end

    #:constant-result-true
    result = Song::Create.(params: { title: "Rising Force", length: 13 })
    result.success? #=> true
    result["model"] #=> #<Song title="Rising Force", length=13>
    #:constant-result-true end
  end

  #---
  # Song::New
  #:constant-new
  class Song::New < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
  end
  #:constant-new end

  it { Song::New.(params: {}).inspect(:model).must_equal %{<Result:true [#<struct ContractConstantTest::Song title=nil, length=nil>] >} }
  it { Song::New.(params: {})["contract.default"].model.inspect.must_equal %{#<struct ContractConstantTest::Song title=nil, length=nil>} }
  it do
    #:constant-new-result
    result = Song::New.(params: {})
    result["model"] #=> #<struct Song title=nil, length=nil>
    result["contract.default"]
    #=> #<Song::Contract::Create model=#<struct Song title=nil, length=nil>>
    #:constant-new-result end
  end

  #---
  #:validate-only
  class Song::ValidateOnly < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
    step Contract::Validate()
  end
  #:validate-only end

  it { Song::ValidateOnly.(params: {}).inspect(:model).must_equal %{<Result:false [#<struct ContractConstantTest::Song title=nil, length=nil>] >} }
  it do
    result = Song::ValidateOnly.(params: { title: "Rising Forse", length: 13 })
    result.inspect(:model).must_equal %{<Result:true [#<struct ContractConstantTest::Song title=nil, length=nil>] >}
  end

  it do
    #:validate-only-result-false
    result = Song::ValidateOnly.(params: {}) # empty params
    result.success? #=> false
    #:validate-only-result-false end
  end

  it do
    #:validate-only-result
    result = Song::ValidateOnly.(params: { title: "Rising Force", length: 13 })

    result.success? #=> true
    result["model"] #=> #<struct Song title=nil, length=nil>
    result["contract.default"].title #=> "Rising Force"
    #:validate-only-result end
  end
end

#---
#- Validate( key: :song )
class DocsContractKeyTest < Minitest::Spec
  Song = Class.new(ContractConstantTest::Song)

  module Song::Contract
    Create = ContractConstantTest::Song::Contract::Create
  end

  #:key
  class Song::Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build( constant: Song::Contract::Create )
    step Contract::Validate( key: "song" )
    step Contract::Persist( )
  end
  #:key end

  it { Song::Create.(params: {}).inspect(:model, "result.contract.default.extract").must_equal %{<Result:false [#<struct DocsContractKeyTest::Song title=nil, length=nil>, nil] >} }
  it { Song::Create.(params: {"song" => { title: "SVG", length: 13 }}).inspect(:model).must_equal %{<Result:true [#<struct DocsContractKeyTest::Song title=\"SVG\", length=13>] >} }
  it do
    #:key-res
    result = Song::Create.(params: { "song" => { title: "Rising Force", length: 13 } })
    result.success? #=> true
    #:key-res end

    #:key-res-false
    result = Song::Create.(params: { title: "Rising Force", length: 13 })
    result.success? #=> false
    #:key-res-false end
  end
end

#- Contract::Build[ constant: XXX, name: AAA ]
class ContractNamedConstantTest < Minitest::Spec
  Song = Class.new(ContractConstantTest::Song)

  module Song::Contract
    Create = ContractConstantTest::Song::Contract::Create
  end

  #:constant-name
  class Song::Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build(    name: "form", constant: Song::Contract::Create )
    step Contract::Validate( name: "form" )
    step Contract::Persist(  name: "form" )
  end
  #:constant-name end

  it { Song::Create.(params: { title: "A" }).inspect(:model).must_equal %{<Result:false [#<struct ContractNamedConstantTest::Song title=nil, length=nil>] >} }
  it { Song::Create.(params: { title: "Anthony's Song", length: 13 }).inspect(:model).must_equal %{<Result:true [#<struct ContractNamedConstantTest::Song title="Anthony's Song", length=13>] >} }

  it do
    #:name-res
    result = Song::Create.(params: { title: "A" })
    result["contract.form"].errors.messages #=> {:title=>["is too short (minimum is 2 ch...
    #:name-res end
  end
end

#---
#- dependency injection
#- contract class
class ContractInjectConstantTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #:di-constant-contract
  class MyContract < Reform::Form
    property :title
    validates :title, length: 2..33
  end
  #:di-constant-contract end
  #:di-constant
  class Create < Trailblazer::Operation
    step Model( Song, :new )
    step Contract::Build()
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end
  #:di-constant end

  it do
    #:di-contract-call
    Create.(
      params: { title: "Anthony's Song" },
      "contract.default.class" => MyContract
    )
    #:di-contract-call end
  end
  it { Create.(params: { title: "A" }, "contract.default.class" => MyContract).inspect(:model).must_equal %{<Result:false [#<struct ContractInjectConstantTest::Song id=nil, title=nil>] >} }
  it { Create.(params: { title: "Anthony's Song" }, "contract.default.class" => MyContract).inspect(:model).must_equal %{<Result:true [#<struct ContractInjectConstantTest::Song id=nil, title="Anthony's Song">] >} }
end

class DryValidationContractTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #---
  # DRY-validation with multiple validation sets,
  #- result.path
  #:dry-schema
  require "reform/form/dry"
  class Create < Trailblazer::Operation
    # contract to verify params formally.
    class MyContract < Reform::Form
      feature Reform::Form::Dry
      property :id
      property :title

      validation name: :default do
        required(:id).filled
      end

      validation name: :extra, if: :default do
        required(:title).filled(min_size?: 2)
      end
    end
    #~form end

    step Model( Song, :new )                      # create the op's main model.
    step Contract::Build( constant: MyContract )  # create the Reform contract.
    step Contract::Validate()                     # validate the Reform contract.
    step Contract::Persist( method: :sync)        # persist the contract's data via the model.
    #~form end
  end
  #:dry-schema end

  puts "@@@@@ #{Trailblazer::Operation::Inspect.(Create, style: :rows)}"

  it { Create.(params: {}).inspect("result.contract.default").must_include "Result:false"}
  it { Create.(params: {}).inspect("result.contract.default").must_include "@errors={:id=>[\"must be filled\""}

  it { Create.(params: { id: 1 }).inspect(:model, "result.contract.default").must_include "Result:false"}
  it { Create.(params: { id: 1 }).inspect(:model, "result.contract.default").must_include "@errors={:title=>[\"must be filled\", \"size cannot be less than 2\"]}"}
  it { Create.(params: { id: 1 }).inspect(:model, "result.contract.default").wont_include ":id=>[\"must be filled\""}

  it { Create.(params: { id: 1, title: "" }).inspect(:model).must_equal %{<Result:false [#<struct DryValidationContractTest::Song id=nil, title=nil>] >} }
  it { Create.(params: { id: 1, title: "Y" }).inspect(:model).must_equal %{<Result:false [#<struct DryValidationContractTest::Song id=nil, title=nil>] >} }
  it { Create.(params: { id: 1, title: "Yo" }).inspect(:model).must_equal %{<Result:true [#<struct DryValidationContractTest::Song id=1, title="Yo">] >} }
end

class DocContractBuilderTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #---
  #- builder:
  #:builder-option
  class Create < Trailblazer::Operation

    class MyContract < Reform::Form
      property :title
      property :current_user, virtual: true

      validate :current_user?
      validates :title, presence: true

      def current_user?
        return true if defined?(current_user)
        false
      end
    end

    step Model( Song, :new )
    step Contract::Build( constant: MyContract, builder: :default_contract! )
    step Contract::Validate()
    step Contract::Persist( method: :sync )

    def default_contract!(options, constant:, model:, **)
      constant.new(model, current_user: options [:current_user])
    end
  end
  #:builder-option end

  it { Create.(params: {}).inspect(:model).must_equal %{<Result:false [#<struct DocContractBuilderTest::Song id=nil, title=nil>] >} }
  it { Create.(params: { title: "title"}, current_user: Module).inspect(:model).must_equal %{<Result:true [#<struct DocContractBuilderTest::Song id=nil, title="title">] >} }
end

class DocContractTest < Minitest::Spec
  Song = Struct.new(:id, :title)
  #---
  # with contract block, and inheritance, the old way.
  class Block < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Model( Song, :new )
    step Contract::Build(constant: MyContract)            # resolves to "contract.class.default" and is resolved at runtime.
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end

  it { Block.(params: {}).inspect(:model).must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title=nil>] >} }
  it { Block.(params: { id:1, title: "Fame" }).inspect(:model).must_equal %{<Result:true [#<struct DocContractTest::Song id=nil, title="Fame">] >} }

  class Breach < Block
    class MyContract < MyContract
      property :id
    end

    step Contract::Build(constant: MyContract), replace: "contract.build"
  end

  it { Breach.(params: { id:1, title: "Fame" }).inspect(:model).must_equal %{<Result:true [#<struct DocContractTest::Song id=1, title="Fame">] >} }

  #-
  # with constant.
  class Break < Block
    class MyContract < Reform::Form
      property :id
    end
    # override the original block as if it's never been there.
    step Contract::Build(constant: MyContract), replace: "contract.build"
  end

  it { Break.(params: { id:1, title: "Fame" }).inspect(:model).must_equal %{<Result:true [#<struct DocContractTest::Song id=1, title=nil>] >} }
end
