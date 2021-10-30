require "reform"

module Trailblazer
  module Macro
    module Contract
      # DISCUSS: could we make the manual builder a step and save a lot of circuit-interface code?
      def self.Build(name: "default", constant: nil, builder: nil)
        build_injections  = {"contract.#{name}.class": ->(*) { constant }} # default to {constant} if not injected.


        task = lambda do |(options, flow_options), **circuit_options|
          result = Build.(options, circuit_options, name: name, constant: constant, builder: builder)

          return Activity::TaskBuilder.binary_signal_for(result, Activity::Right, Activity::Left),
              [options, flow_options]
        end

        {task: task, id: "contract.build", inject: [build_injections]}
      end

      module Build
        # Build contract at runtime.
        def self.call(ctx, circuit_options, name: "default", constant: nil, builder: nil)
          contract_class = ctx[:"contract.#{name}.class"] # the injection makes sure this is set.

          # TODO: we could probably clean this up a bit at some point.
          model          = ctx[:model]

          name           = :"contract.#{name}"
          ctx[name] = if builder
                            call_builder(ctx, circuit_options, builder: builder, constant: contract_class, name: name)
                          else
                            contract_class.new(model)
                          end
        end

        def self.call_builder(ctx, circuit_options, builder: raise, constant: raise, name: raise)
          tmp_options = ctx.to_hash.merge(
            constant: constant,
            name:     name
          )

          Trailblazer::Option(builder).(ctx, keyword_arguments: tmp_options, **circuit_options) # TODO: why can't we build the {builder} at compile time?
        end
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
