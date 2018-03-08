require "test_helper"

# contract Constant # new
# contract Constant, inherit: true # extend existing
# contract do end # extend existing || new
# contract Constant do .. end # new, extend new

class DslContractTest < MiniTest::Spec
  module Call
    class MyContract

    end

    def call(params)
      validate(params, model: model=OpenStruct.new) { contract.sync }
      model
    end

    def self.included(includer)
      includer.step Trailblazer::Operation::Model( OpenStruct, :new )
      includer.step Trailblazer::Operation::Contract::Build(constant: MyContract)
      includer.step Trailblazer::Operation::Contract::Validate()
      includer.step Trailblazer::Operation::Contract::Persist( method: :sync )
      # includer.> ->(op, *) { op["x"] = [] }
    end
  end

  # ---
  # Operation::["contract.default.class"]
  # Operation::["contract.default.class"]=
  class Create < Trailblazer::Operation
    self["contract.default.class"] = String
  end

  # reader method.
  # no subclassing.
  it { Create["contract.default.class"].must_equal String }

  class CreateOrFind < Create
  end

  # no inheritance with setter.
  it { CreateOrFind["contract.default.class"].must_be_nil }

  # ---
  # Op::contract Constant
  class Update < Trailblazer::Operation
    include Call

    class IdContract < Reform::Form
      property :id
    end

    step Trailblazer::Operation::Contract::Build(constant: IdContract), replace: "contract.build"
  end

  # UT: subclasses contract.
  it { Update.(params: {})["contract.default"].class.must_equal Update::IdContract }
  # IT: only knows `id`.
  it { Update.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct id=1>} }

  # Op::contract with inheritance
  # no ::contract call.
  class Upgrade < Update
    class UpgradeContract < Reform::Form
    end
    step Trailblazer::Operation::Contract::Build(constant: UpgradeContract), replace: "contract.build"
  end

  # UT: replaces contract and doesn't share with parent.
  it { Upgrade.(params: {})["contract.default"].class.must_equal Upgrade::UpgradeContract }
  # IT: Doesn't know `id`.
  it { Upgrade.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct>} }

  # ::contract B overrides old A contract.
  # this makes sure when calling contract(Constant), the old class gets wiped and is replaced with the new constant.
  class Upsert < Update
    class TitleContract < Reform::Form
      property :title
    end

    step Trailblazer::Operation::Contract::Build(constant: TitleContract), replace: "contract.build"
  end

  # UT: subclasses contract.
  it { Upsert.(params: {})["contract.default"].class.must_equal Upsert::TitleContract }
  # IT: only knows `title`.
  it { Upsert.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title="Coaster">} }

  # ::contract B do ..end overrides and extends new.
  # using a constant will wipe out the existing class.
  class Upside < Update
    class Upsert::TitleContract
      property :id
    end

    step Trailblazer::Operation::Contract::Build(constant: Upsert::TitleContract), replace: "contract.build"
  end

  # UT: subclasses contract.
  it { Upside.(params: {})["contract.default"].class.must_equal Upsert::TitleContract }
  # IT: only knows `title`.
  it { Upside.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title="Coaster", id=1>} }

  #---
  # contract do .. end
  # (with block)
  class Delete < Trailblazer::Operation
    include Call

    class TitleContract < Reform::Form
      property :title
    end

    step Trailblazer::Operation::Contract::Build(constant: TitleContract), replace: "contract.build"
  end

  # IT: knows `title`.
  it { Delete.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title=\"Coaster\">} }

  # subsequent calls merge.
  class Remove < Trailblazer::Operation
    include Call

    class TitleContract < Reform::Form
      property :title
    end

    class IdContract < TitleContract
      property :id
    end

    step Trailblazer::Operation::Contract::Build(constant: IdContract), replace: "contract.build"
  end

  # IT: knows `title` and `id`, since contracts get merged.
  it { Remove.(params: {id: 1, title: "Coaster"})[:model].inspect.must_equal %{#<OpenStruct title=\"Coaster\", id=1>} }

  # Operation::["contract.default.class"]
  # Operation::["contract.default.class"]=
  describe %{Operation::["contract.default.class"]} do

    class Update2 < Trailblazer::Operation
      self["contract.default.class"] = String
    end

    it { Update2["contract.default.class"].must_equal String }
  end

  describe "inheritance across operations" do
    # inheritance
    class Operation < Trailblazer::Operation
      class MyContract < Reform::Form
        property :title
        property :band
      end

      step Model( OpenStruct, :new )
      step Contract::Build(constant: MyContract)

      class JSON < self
        class JsonContract < MyContract
          property :genre, validates: {presence: true}
          property :band, virtual: true
        end
        step Contract::Build(constant: JsonContract), replace: "contract.build"
      end

      class XML < self
      end
    end

    # inherits subclassed Contract.
    it { Operation.(params: {})["contract.default"].must_be_instance_of Operation::MyContract }
    it { Operation::JSON.(params: {})["contract.default"].must_be_instance_of Operation::JSON::JsonContract }
    it { Operation::XML.(params: {})["contract.default"].must_be_instance_of Operation::MyContract }

    it do
      form = Operation.(params: {})["contract.default"]
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{}"

      form = Operation::JSON.(params: {})["contract.default"]
      form.validate({})#.must_equal true
      form.errors.to_s.must_equal "{:genre=>[\"can't be blank\"]}"
    end

    # allows overriding options
    it do
      form = Operation::JSON.(params: {})["contract.default"]
      form.validate({genre: "Punkrock", band: "Osker"}).must_equal true
      song = form.sync

      song.genre.must_equal "Punkrock"
      song.band.must_be_nil
    end
  end

  describe "Op.contract CommentForm" do
    class SongForm < Reform::Form
      property :songTitle, validates: {presence: true}
    end

    class OpWithExternalContract < Trailblazer::Operation
      include Call
      step Trailblazer::Operation::Contract::Build(constant: SongForm), replace: "contract.build"
    end

    it { OpWithExternalContract.(params: {"songTitle"=> "Monsterparty"})["contract.default"].songTitle.must_equal "Monsterparty" }
  end

  describe "Op.contract CommentForm do .. end" do
    class DifferentSongForm < Reform::Form
      property :songTitle, validates: {presence: true}
    end

    class OpNotExtendingContract < Trailblazer::Operation
      include Call

      class MyContract < DifferentSongForm
      end

      step Trailblazer::Operation::Contract::Build(constant: MyContract), replace: "contract.build"
    end

    class OpExtendingContract < Trailblazer::Operation
      include Call

      class SongContract < DifferentSongForm
        property :genre
      end

      step Trailblazer::Operation::Contract::Build(constant: SongContract), replace: "contract.build"
    end

    # this operation copies DifferentSongForm and shouldn't have `genre`.
    it do
      contract = OpNotExtendingContract.(params: {"songTitle"=>"Monsterparty", "genre"=>"Punk"})["contract.default"]

      song = contract.sync
      song.songTitle.must_equal "Monsterparty"
      song.songGenre.must_be_nil
    end

    # this operation copies DifferentSongForm and extends it with the property `genre`.
    it do
      contract = OpExtendingContract.(params: {"songTitle"=>"Monsterparty", "genre"=>"Punk"})["contract.default"]

      song = contract.sync
      song.songTitle.must_equal "Monsterparty"
      song.genre.must_equal "Punk"
    end

    # of course, the original contract wasn't modified, either.
    it do
      assert_raises(NoMethodError) { DifferentSongForm.new(OpenStruct.new).genre }
    end
  end

  describe "Op.contract :name, Form" do
    class Follow < Trailblazer::Operation
      class ParamsForm < Reform::Form
      end

      step Trailblazer::Operation::Contract::Build(constant: ParamsForm)
    end

    it { Follow.(params: {})["contract.default"].must_be_instance_of Follow::ParamsForm }
  end

  describe "Op.contract :name do..end" do
    class Unfollow < Trailblazer::Operation
      class MyContract < Reform::Form
        property :title
      end

      step Model( OpenStruct, :new )
      step Trailblazer::Operation::Contract::Build(constant: MyContract, name: "params")
    end

    it { Unfollow.(params: {})["contract.params"].must_be_instance_of Unfollow::MyContract }
  end

  # multiple ::contract calls.
  describe "multiple ::contract calls" do
    class Star < Trailblazer::Operation
      class MyContract < Reform::Form
        property :title
      end

      class MySecondContract < Reform::Form
        property :id
      end

      step Model( OpenStruct, :new )
      step Contract::Build(constant: MyContract)
      step Contract::Build(constant: MySecondContract, name: "second")
    end

    it { Star.(params: {})["contract.default"].must_be_instance_of Star::MyContract }
    it { Star.(params: {})["contract.second"].must_be_instance_of Star::MySecondContract }
  end
end
