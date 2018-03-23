# 2.1.0.beta3

* New activity API update.

# 2.1.0.beta2

* Remove `trailblazer` dependency.

# 2.1.0.beta1

Split all Trailblazer Operation based Contract Macros into separate gem

# 2.0.2

* In `Contract::Build( builder: )` you now also have access to the `name:` keyword. Note that you need to double-splat in builders.

        ```ruby
        Contract::Build( builder: ->(options, constant:, **) )
        ```
  Same for `:method` and `Callable`.

# 2.0.0

All old semantics will be available via [trailblazer-compat](https://github.com/trailblazer/trailblazer-compat).

* Removed `Operation::contract` (without args). Please use `Operation::["contract.default.class"]`.
* Removed `Operation::contract_class`. Please use `Operation::["contract.default.class"]`.
* Removed `Operation::contract_class=`. Please use `Operation::["contract.default.class"]=`. Doesn't inherit.

## Contract

* You can't call `Create.().contract` anymore. The contract instance(s) are available through the `Result` object via `["contract.default"]`.
* Removed the deprecation for `validate`, signature is `(params[, model, options, contract_class])`.
* Removed the deprecation for `contract`, signature is `([model, options, contract_class])`.

# 2.0.0.rc2

* It's now Contract::Persist( name: "params" ) instead of ( name: "contract.params" ).

# 2.0.0.beta2

* Renamed `Persist` to `Contract::Persist`.
* `Contract` paths are now consistent.
