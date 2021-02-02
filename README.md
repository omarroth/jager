# jager

I would recommend re-implementing this if you plan on using it for anything yourself. The approach in this library is a poorly-informed implementation based on parser actions.

If anyone is curious on how something like this would be implemented **correctly** I would recommend reading Russ Cox's series of posts, and convert a regular expression into a proper DFA as described [here](https://swtch.com/~rsc/regexp/regexp1.html). Then this library reduces to traversing the DFA randomly until reaching an accept state.

[![GitHub release](https://img.shields.io/github/release/omarroth/jager.svg)](https://github.com/omarroth/jager/releases)

> This is a project built with [marpa](https://github.com/omarroth/marpa).

Given a regular expression, generate a string that matches that expression

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  jager:
    github: omarroth/jager
```

## Usage

```crystal
require "jager"

regex = /\d{3}-\d{3}-\d{4}/
engine = Jager::Engine.new

input = engine.generate(regex)

input # => "754-327-6740"
```

## Examples

| Name        | Regex                                                          | Output                                 |
| ----------- | -------------------------------------------------------------- | -------------------------------------- |
| US Phone    | /\d{3}-\d{3}-\d{4}/                                            | "019-586-1821"                         |
| UUID        | /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/ | "0d007d29-f50b-4763-f40e-102fcaa77a1b" |
| JSON Number | /-?[1-9]\d+(.\d+)?([eE][+-]?\d+)?/                             | "85.2292e+6745508109"                  |
| US Dollar   | /\\$([1-9]{1}[0-9]{0,2})(,\d{3}){0,4}(.\d{2})?/                | "$7,239,557,686.39"                    |

## Notes

- Jager does **not** support:
  - anchors (`$`, `^`),
  - extended character classes (`[[:digit:]]`, `[[:alpha:]]`)

## Contributing

1.  Fork it ( https://github.com/omarroth/jager/fork )
2.  Create your feature branch (git checkout -b my-new-feature)
3.  Commit your changes (git commit -am 'Add some feature')
4.  Push to the branch (git push origin my-new-feature)
5.  Create a new Pull Request

## Contributors

- [omarroth](https://github.com/omarroth) Omar Roth - creator, maintainer
