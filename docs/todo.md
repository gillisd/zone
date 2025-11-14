## Rules
1. VERY IMPORTANT .Before using ANY Ruby class, method, builtin, expression, you are to read the latest docs on it. This can be found by executing `ri --no-pager <subject>`.  For example:

```
ri --no-pager 'Array#zip'
```

Additionally, more comprehensive documentation can be found by accessing these documents, using the syntax:

```
ri --no-pager 'syntax/pattern_matching:'
```
which renders the document syntax/pattern_matching.rdoc. All other advanced documentation can be found below:


bsearch.rdoc
bug_triaging.rdoc
case_mapping.rdoc
character_selectors.rdoc
command_injection.rdoc
contributing.md
contributing/building_ruby.md
contributing/documentation_guide.md
contributing/glossary.md
contributing/making_changes_to_ruby.md
contributing/making_changes_to_stdlibs.md
contributing/reporting_issues.md
contributing/testing_ruby.md
date/calendars.rdoc
dig_methods.rdoc
distribution.md
dtrace_probes.rdoc
encodings.rdoc
exceptions.md
extension.ja.rdoc
extension.rdoc
fiber.md
format_specifications.rdoc
globals.rdoc
implicit_conversion.rdoc
index.md
maintainers.md
marshal.rdoc
memory_view.md
optparse/argument_converters.rdoc
optparse/creates_option.rdoc
optparse/option_params.rdoc
optparse/tutorial.rdoc
packed_data.rdoc
ractor.md
regexp/methods.rdoc
regexp/unicode_properties.rdoc
rjit/rjit.md
ruby/option_dump.md
ruby/options.md
security.rdoc
signals.rdoc
standard_library.md
strftime_formatting.rdoc
syntax.rdoc
syntax/assignment.rdoc
syntax/calling_methods.rdoc
syntax/comments.rdoc
syntax/control_expressions.rdoc
syntax/exceptions.rdoc
syntax/keywords.rdoc
syntax/literals.rdoc
syntax/methods.rdoc
syntax/miscellaneous.rdoc
syntax/modules_and_classes.rdoc
syntax/operators.rdoc
syntax/pattern_matching.rdoc
syntax/precedence.rdoc
syntax/refinements.rdoc
windows.md
yjit/yjit.md


You must do this for EVERY method, class, etc when you use it in this session for the first time

2. Prefer "in" to "when". See `ri --no-pager syntax/pattern_matching:`

3. When using OptionParser, prefer the implict, blockless declarations that utilize `OptionParser#parse!(into: options)`

4. Prefer a functional chaining style when doing consecutive operations on enumerables 


## Tasks

* Calling `zone` with no arguments or with one field is splitting the timestamp into words. It should not lose its formatting
* Memoize fuzzy search - seems to be searching every time for zone input like tokyo last time I checked
* Plan a refactor into separate classes, using idiomatic ruby and good Object Oriented Design

