require "reform"

module Trailblazer
  module Macro
    # This Circuit-task calls the {task} Option, then allows
    # to run an arbitary block to process the option's result.
    # @private
    class CircuitTaskWithResultProcessing < Activity::TaskBuilder::Task # DISCUSS: extract to public?
      def initialize(task, user_proc, block)
        @block = block
        super(task, user_proc)
      end

      def call_option(task_with_option_interface, (ctx, flow_options), **circuit_options)
        result = super

        @block.call(result, ctx)
      end
    end

    module Contract
      def self.Build(name: "default", constant: nil, builder: nil)
        contract_path     = :"contract.#{name}"

        injections = {
          Activity::Railway.Inject() => {
            "#{contract_path}.class": ->(*) { constant } # default to {constant} if not injected.
          }
        }

        input = {
          Activity::Railway.In() => ->(ctx, **) do
            ctx.to_hash.merge(
              constant: constant,
              name:     contract_path
            )
          end
        }

        output = {
          Activity::Railway.Out() => [contract_path]
        }

        default_contract_builder = ->(ctx, model: nil, **) { ctx[:"#{contract_path}.class"].new(model) }

        # proc is called via {Option()}.
        task_option_proc = builder ? builder : default_contract_builder

        # after the builder proc is run, assign its result to {:"contract.default"}.
        ctx_assign_block = ->(result, ctx) { ctx[contract_path] = result }

        task = CircuitTaskWithResultProcessing.new(Trailblazer::Option(task_option_proc), task_option_proc, ctx_assign_block)

        {
          task:   task, id: "contract.build",
        }.
          merge(injections).
          merge(input).
          merge(output)
      end

      module DSL
        def self.extended(extender)
          extender.extend(ClassDependencies)
          warn "[Trailblazer] Using `contract do...end` is deprecated. Please use a form class and the Builder( constant: <Form> ) option."
        end

        # This is the class level DSL method.
        #   Op.contract #=> returns contract class
        #   Op.contract do .. end # defines contract
        #   Op.contract CommentForm # copies (and subclasses) external contract.
        #   Op.contract CommentForm do .. end # copies and extends contract.
        def contract(name = :default, constant = nil, base: Reform::Form, &block)
          heritage.record(:contract, name, constant, &block)

          path, form_class = Trailblazer::DSL::Build.new.(
            {prefix: :contract, class: base, container: self},
            name, constant, block
          )

          self[path] = form_class
        end
      end
    end
  end
end
