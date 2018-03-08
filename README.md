# Trailblazer Macro Contract
The Contract Macros helps you defining contracts and assists with instantiating and validating data with those contracts at runtime.

## Table of Contents
* [Installation](#installation)
* [Contract](#contract)
  + [Build](#build)
  + [Validation](#validation)
    - [Key](#key)
  + [Persist](#persist)
    - [Name](#name)
  + [Result Object](#result-object)

## Installation
The obvious needs to be in your `Gemfile`.
```ruby
gem "trailblazer-operation"
gem "reform"
gem "trailblazer-macro-contract"
```
Note: you don't need to install anything if you're using the trailblazer gem itself.

## Contract
The Contract Macro, covers the contracts for Trailblazer, they are basically Reform objects that you can define and validate inside an operation. Reform is a fantastic tool for deserializing and validating deeply nested hashes, and then, when valid, writing those to the database using your persistence layer such as ActiveRecord.

```ruby
# app/concepts/song/contract/create.rb
module Song::Contract
  class Create < Reform::Form
    property :title
    property :length

    validates :title,  length: 2..33
    validates :length, numericality: true
  end
end
```

The Contract then gets hooked into the operation. using this Macro.
```ruby
# app/concepts/song/operation/create.rb
class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate()
  step Contract::Persist()
end
```
As you can see, using contracts consists of five steps.

Define the contract class (or multiple of them) for the operation.
Plug the contract creation into the operation’s pipe using Contract::Build.
Run the contract’s validation for the params using Contract::Validate.
If successful, write the sane data to the model(s). This will usually happen in the Contract::Persist macro.
After the operation has been run, interpret the result. For instance, a controller calling an operation will render a erroring form for invalid input.

Here’s what the result would look like after running the Create operation with invalid data.
```ruby
result = Song::Create.( title: "A" )
result.success? #=> false
result["contract.default"].errors.messages
  #=> {:title=>["is too short (minimum is 2 characters)"], :length=>["is not a number"]}
```

### Build
The Contract::Build macro helps you to instantiate the contract. It is both helpful for a complete workflow, or to create the contract, only, without validating it, e.g. when presenting the form.
```ruby
class Song::New < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
end
```

This macro will grab the model from options["model"] and pass it into the contract’s constructor. The contract is then saved in options["contract.default"].
```ruby
result = Song::New.()
result["model"] #=> #<struct Song title=nil, length=nil>
result["contract.default"]
  #=> #<Song::Contract::Create model=#<struct Song title=nil, length=nil>>
```
The Build macro accepts the :name option to change the name from default.

### Validation
The Contract::Validate macro is responsible for validating the incoming params against its contract. That means you have to use Contract::Build beforehand, or create the contract yourself. The macro will then grab the params and throw then into the contract’s validate (or call) method.

```ruby
class Song::ValidateOnly < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate()
end
```
Depending on the outcome of the validation, it either stays on the right track, or deviates to left, skipping the remaining steps.
```ruby
result = Song::ValidateOnly.({}) # empty params
result.success? #=> false
```

Note that Validate really only validates the contract, nothing is written to the model, yet. You need to push data to the model manually, e.g. with Contract::Persist.
```ruby
result = Song::ValidateOnly.({ title: "Rising Force", length: 13 })

result.success? #=> true
result["model"] #=> #<struct Song title=nil, length=nil>
result["contract.default"].title #=> "Rising Force"
```

Validate will use options["params"] as the input. You can change the nesting with the :key option.

Internally, this macro will simply call Form#validate on the Reform object.

Note: Reform comes with sophisticated deserialization semantics for nested forms, it might be worth reading a bit about Reform to fully understand what you can do in the Validate step.

#### Key
Per default, Contract::Validate will use options["params"] as the data to be validated. Use the key: option if you want to validate a nested hash from the original params structure.
```ruby
class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate( key: "song" )
  step Contract::Persist( )
end
```

This automatically extracts the nested "song" hash.
```ruby
result = Song::Create.({ "song" => { title: "Rising Force", length: 13 } })
result.success? #=> true
```

If that key isn’t present in the params hash, the operation fails before the actual validation.
```ruby
result = Song::Create.({ title: "Rising Force", length: 13 })
result.success? #=> false
```

Note: String vs. symbol do matter here since the operation will simply do a hash lookup using the key you provided.

### Persist
To push validated data from the contract to the model(s), use Persist. Like Validate, this requires a contract to be set up beforehand.
```ruby
class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate()
  step Contract::Persist()
end
```

After the step, the contract’s attribute values are written to the model, and the contract will call save on the model.
```ruby
result = Song::Create.( title: "Rising Force", length: 13 )
result.success? #=> true
result["model"] #=> #<Song title="Rising Force", length=13>
```

You can also configure the Persist step to call sync instead of Reform’s save.
```ruby
step Persist( method: :sync )
```
This will only write the contract’s data to the model without calling save on it.

#### Name
Explicit naming for the contract is possible, too.
```ruby

class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build(    name: "form", constant: Song::Contract::Create )
  step Contract::Validate( name: "form" )
  step Contract::Persist(  name: "form" )
end
```

You have to use the name: option to tell each step what contract to use. The contract and its result will now use your name instead of default.
```ruby
result = Song::Create.({ title: "A" })
result["contract.form"].errors.messages #=> {:title=>["is too short (minimum is 2 ch...
```

Use this if your operation has multiple contracts.

### Result Object
The operation will store the validation result for every contract in its own result object.

The path is result.contract.#{name}.
```ruby
result = Create.({ length: "A" })

result["result.contract.default"].success?        #=> false
result["result.contract.default"].errors          #=> Errors object
result["result.contract.default"].errors.messages #=> {:length=>["is not a number"]}
```

Each result object responds to success?, failure?, and errors, which is an Errors object. TODO: design/document Errors. WE ARE CURRENTLY WORKING ON A UNIFIED API FOR ERRORS (FOR DRY AND REFORM).
