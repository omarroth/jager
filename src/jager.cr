require "./jager/*"
require "marpa"

module Jager
  alias Node = {value: String, edges: Array(Int32)}

  class Actions < Marpa::Actions
    ACCEPTABLE_CHARS = (' '..'~').to_a
    DIGIT            = ('0'..'9').to_a
    NOT_DIGIT        = ACCEPTABLE_CHARS - DIGIT

    WORD     = ('A'..'Z').to_a + ('a'..'z').to_a + DIGIT + ['_']
    NOT_WORD = ACCEPTABLE_CHARS - WORD

    WHITESPACE     = ['\t', '\n', ' ']
    NOT_WHITESPACE = ACCEPTABLE_CHARS - WHITESPACE

    property graph

    def initialize
      @graph = [] of Node
    end

    def capture_group(context)
      context = context[1].as(Array)
      context
    end

    def group(context)
      group = context[0].as(String)

      case group
      when "\\w"
        body = WORD
      when "\\W"
        body = NOT_WORD
      when "\\d"
        body = DIGIT
      when "\\D"
        body = NOT_DIGIT
      when "\\s"
        body = WHITESPACE
      when "\\S"
        body = NOT_WHITESPACE
      when "."
        body = ACCEPTABLE_CHARS
      else
        raise "Invalid group #{group}"
      end

      context.clear

      @graph << {value: "", edges: (1..body.size).to_a}
      context << ""

      body.each_with_index do |element, i|
        @graph << {value: element.to_s, edges: [body.size - i]}
        context << ""
      end

      context
    end

    def character(context)
      character = context.as(Array)
      character = context.flatten
      character = character[0]

      @graph << {value: character, edges: [1]}
      context
    end

    def union(context)
      elements = context.as(Array)
      elements.delete("|")

      body = @graph.pop(elements.flatten.size)

      edge = 1
      edges = [] of Int32
      elements = elements.map do |element|
        element = element.as(Array)
        element = element.flatten
        element << ""

        edges << edge
        edge += element.size

        element
      end

      edges.each_with_index do |edge, i|
        body.insert(edge + elements[i].size - 2, {value: "", edges: [elements[i..-1].flatten.size - elements[i].size + 1]})
      end

      body.insert(0, {value: "", edges: edges})
      @graph += body

      context.clear
      body.size.times do
        context << ""
      end
      context
    end

    def character_set(context)
      body = context[1].as(Array)
      body = body.flatten

      @graph << {value: "", edges: (1..body.size).to_a}
      body.each_with_index do |element, i|
        @graph << {value: element, edges: [body.size - i]}
      end

      context.clear

      body.size.times do
        context << ""
      end
      context << ""
      context
    end

    def negated_set(context)
      body = context[1].as(Array)
      body = body.flatten

      body = ACCEPTABLE_CHARS - body

      @graph << {value: "", edges: (1..body.size).to_a}
      body.each_with_index do |element, i|
        @graph << {value: element.to_s, edges: [body.size - i]}
      end

      context.clear

      body.size.times do
        context << ""
      end
      context << ""
      context
    end

    def range(context)
      range = context[0].as(Array)

      first = range[0].as(Array)
      first = first[0].as(String)
      first = first.chars[0]

      last = range[2].as(Array)
      last = last[0].as(String)
      last = last.chars[0]

      if first > last
        raise "Range values reversed, #{first} and #{last}."
      end

      range = (first..last).to_a

      context.clear
      range.each do |char|
        context << char.to_s
      end

      context
    end

    def escaped_character(context)
      character = context[0].as(String)

      case character
      when "\\t"
        context = "\t"
      when "\\n"
        context = "\n"
      when "\\v"
        context = "\v"
      when "\\f"
        context = "\f"
      when "\\r"
        context = "\r"
      when "\\0"
        context = "\0"
      else
        context = character.lchop("\\")
      end

      context
    end

    def reserved_character(context)
      character = context[0].as(String)
      character = character.lchop("\\")

      context[0] = character
      context
    end

    def octal_escape(context)
      character = context[0].as(String)
      character = character.lchop("\\").to_u8(base = 8).unsafe_chr.to_s

      context[0] = character
      context
    end

    def hexadecimal_escape(context)
      character = context[0].as(String)
      character = character.lchop("\\x").to_u8(base = 16).unsafe_chr.to_s

      context[0] = character
      context
    end

    def unicode_escape(context)
      character = context[0].as(String)
      character = character.lchop("\\u").to_u16(base = 16).unsafe_chr.to_s

      context[0] = character
      context
    end

    def extended_unicode_escape(context)
      character = context[0].as(String)
      character = character.lchop("\\u").lchop("\\x")
      character = character.lchop("{")
      character = character.rchop("}")
      character = character.to_u32(base = 16).unsafe_chr.to_s

      context[0] = character
      context
    end

    def control_character_escape(context)
      character = context[0].as(String)

      codes = ('A'..'Z').to_a

      character = character.lchop("\\c")
      codes.each_with_index do |match, i|
        if character == match.to_s
          character = i.unsafe_chr.to_s
          break
        end
      end

      context[0] = character
      context
    end

    def plus(context)
      body = context[0].as(Array)
      body = body.flatten

      @graph << {value: "", edges: [1, -body.size]}

      context.clear
      body.size.times do
        context << ""
      end
      context << ""
      context
    end

    def star(context)
      body = context[0].as(Array)
      body = body.flatten

      @graph.insert(-1 - body.size, {value: "", edges: [1, body.size + 2]})
      @graph << {value: "", edges: [-1 - body.size]}

      context.clear
      body.size.times do
        context << ""
      end
      context << ""
      context << ""
      context
    end

    def quantifier(context)
      body = context[0].as(Array)
      body = body.flatten

      quantifier = context[1].as(Array)
      quantifier = quantifier.flatten

      min = quantifier[1].to_i
      comma = quantifier[2]?.try &.== ","
      max = quantifier[3]?.try &.to_i?

      context.clear
      body = @graph.pop(body.size)

      min.times do
        @graph += body
        body.size.times do
          context << ""
        end
      end

      if max
        (max - min).times do
          @graph << {value: "", edges: [1, body.size + 1]}
          @graph += body

          body.size.times do
            context << ""
          end
          context << ""
        end
      elsif comma
        @graph << {value: "", edges: [1, body.size + 2]}
        @graph += body
        @graph << {value: "", edges: [-1 - body.size]}

        body.size.times do
          context << ""
        end
        context << ""
        context << ""
      end

      context
    end

    def optional(context)
      body = context[0].as(Array)
      body = body.flatten

      @graph.insert(-1 - body.size, {value: "", edges: [1, body.size + 1]})

      context.clear
      body.size.times do
        context << ""
      end
      context << ""
      context
    end

    def not_implemented(context)
      raise "Not implemented"
    end
  end

  class Engine
    # Generate a string that matches the given regex
    def generate(regex : Regex)
      regex = regex.to_s
      regex = regex.partition(":")[2]
      regex = regex.rchop
      return generate(regex)
    end

    # Generate a string that matches the given regular expression (as string)
    def generate(regex : String)
      graph = compile(regex)
      output = generate(graph)

      return output
    end

    # Given graph, create output until an endpoint is found
    def generate(graph : Array(Node))
      output = ""
      offset = 0

      until graph[offset][:edges].empty?
        output += graph[offset][:value]
        offset += graph[offset][:edges].sample(1)[0]
      end

      return output
    end

    # Compile given regular expression
    def compile(regex : Regex)
      regex = regex.to_s
      regex = regex.partition(":")[2]
      regex = regex.rchop
      return compile(regex)
    end

    # Compile given regular expression (as string)
    def compile(regex : String)
      grammar = regex_bnf

      parser = Marpa::Parser.new
      actions = Jager::Actions.new
      string = parser.parse(regex, grammar, actions)

      graph = actions.graph
      graph << {value: "", edges: [] of Int32}

      return graph
    end
  end
end
