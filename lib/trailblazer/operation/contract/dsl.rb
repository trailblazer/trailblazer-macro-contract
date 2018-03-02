module Trailblazer
  class Operation
    module Contract
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
        def contract(name=:default, constant=nil, base: Reform::Form, &block)
          heritage.record(:contract, name, constant, &block)

          path, form_class = Trailblazer::DSL::Build.new.({ prefix: :contract, class: base, container: self }, name, constant, block)

          self[path] = form_class
        end
      end # Contract
    end
  end
end
