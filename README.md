# Parlour

Parlour is an RBI generator and merger for Sorbet. Once done, it'll consist of
two parts:

  - The generator, which outputs beautifully formatted RBI files, created using
    an intuitive DSL.

  - The plugin/build system, which allows multiple Parlour plugins to generate
    RBIs for the same codebase. These are combined automatically as much as 
    possible, but any other conflicts can be resolved manually through prompts.

## Usage

Here's a quick example of how you might generate an RBI currently, though this
API is very likely to change:

```ruby
require 'parlour'

generator = Parlour::RbiGenerator.new
generator.root.create_module('A') do |a|
  a.create_class('Foo') do |foo|
    foo.create_method('add_two_integers', [
      Parlour::RbiGenerator::Parameter.new('a', type: 'Integer'),
      Parlour::RbiGenerator::Parameter.new('b', type: 'Integer')
    ], 'Integer')
  end

  a.create_class('Bar', superclass: 'Foo')
end

generator.rbi # => Our RBI as a string
```

This will generate the following RBI:

```ruby
module A
  class Foo
    sig { params(a: Integer, b: Integer).returns(Integer) }
    def add_two_integers(a, b); end
  end

  class Bar < Foo
  end
end
```

There aren't really any docs currently, so have a look around the code to find
any extra options you may need.

## Code Structure

### Overall Flow
```
                        STEP 1
                 All plugins mutate the
                 instance of RbiGenerator
                 They generate a tree
                 structure of RbiObjects

                 +--------+  +--------+
                 |Plugin 1|  |Plugin 2|
                 +----+---+  +----+---+         STEP 2
                      ^           ^        ConflictResolver
                      |           |        mutates the structure
+-------------------+ |           |        to fix conflicts
|                   | |           |
| One instance of   +-------------+        +----------------+
| RbiGenerator      +--------------------->+ConflictResolver|
|                   |                      +----------------+
+---------+---------+
          |
          |
          |          +-------+          STEP 3
          +--------->+ File  |    The final RBI is written
                     +-------+    to a file
```

### Generation
Everything that can generate lines of the RBI implements the 
`RbiGenerator::RbiObject` interface. This defines one function, `generate_rbi`,
which accepts the current indentation level and a set of formatting options.
(Each object is responsible for generating its own indentation; that is, the
lines generated by a child object should not then be indented by its parent.)

I think generation is quite close to done, but it still needs features like 
constants and type parameters.

### Conflict Resolution
This will be a key part of the plugin/build system. The `ConflictResolver` takes
a namespace from the `RbiGenerator` and merges duplicate items in it together. 
This means that many plugins can generate their own signatures which are all 
bundled into one, conflict-free output RBI.

It will be able to do the following merges automatically (checkmark means
implemented):

  - [X] If many methods are identical, delete all but one.
  - [ ] If many classes are defined with the same name, merge their methods,
        includes and extends. (But only if they are all abstract or all not,
        and only if they don't define more than one superclass together.)
  - [ ] If many modules are defined with the same name, merge their methods,
        includes and extends. (But only if they are all interfaces or all not.)

If a merge can't be performed automatically, then the `#resolve_conflicts`
method takes a block. This block is passed all the conflicting objects, and one
should be selected and returned - all others will be deleted. (Alternatively,
the block can return nil, and all will be deleted.) This will allow a CLI to 
prompt the user asking them what they'd like to do, in the case of conflicts
between each plugin's signatures which can't automatically be resolved.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AaronC81/parlour. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Parlour project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/AaronC81/parlour/blob/master/CODE_OF_CONDUCT.md).
