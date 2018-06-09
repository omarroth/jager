require "./jager/*"
require "marpa"

module Jager
  class Engine
    LENGTH         = 10
    ACCEPTABLE_SET = %( !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~\t\n).split("")

    # Generate a string that matches the given regex
    def generate(regex : Regex)
      regex = regex.to_s
      regex = regex.partition(":")[2]
      regex = regex.rchop
      return generate(regex)
    end

    # Generate a string that matches the given regex (as string)
    def generate(regex : String)
      grammar = File.read("src/jager/regex.bnf")

      parser = Marpa::Parser.new
      stack = parser.parse(grammar, regex)

      stack = stack.as(Array)
      string = stack_to_string(stack)

      return string
    end

    # Method for turning stack produced from succesful parse into output that matches
    # the given regular expression
    def stack_to_string(stack)
      output = ""
      case stack
      when Array
        case stack[0]
        when "("
          body = stack[1].as(Array)
          output += stack_to_string(body)
        when "(?:"
          body = stack[1].as(Array)
          output += stack_to_string(body)
        when "(?="
          body = stack[1].as(Array)
          output += stack_to_string(body)
        when "(?!"
          body = stack[1].as(Array)
          output += stack_to_string(body)
        when "["
          body = stack[1].as(Array)
          body = body.map { |item| decode_element(item) }
          body = body.flatten.as(Array(String))

          output += body.sample(1)[0]
        when "[^"
          body = stack[1].as(Array)
          body = body.map { |item| decode_element(item) }
          body = body.flatten.as(Array(String))

          set = ACCEPTABLE_SET - body
          output += set.sample(1)[0]
        else
          if stack[1]? == "|"
            stack.delete("|")
            output += stack_to_string(stack.sample(1)[0])
          else
            case stack[-1]
            when "+"
              (rand(LENGTH) + 1).times do
                output += stack_to_string(stack[0])
              end
            when "*"
              rand(LENGTH + 1).times do
                output += stack_to_string(stack[0])
              end
            when "?"
              rand(2).times do
                output += stack_to_string(stack[0])
              end
            else
              if stack[-1][0] == "{"
                quantifier = stack[-1][1..-2].as(Array)
                quantifier = quantifier.flatten.as(Array(String))
                min = quantifier[0].to_i
                comma = quantifier[1]?
                max = quantifier[2]?

                min.times do
                  output += stack_to_string(stack[0])
                end
                if max
                  max = quantifier[2].to_i
                  rand(max).times do
                    output += stack_to_string(stack[0])
                  end
                elsif comma
                  rand(LENGTH).times do
                    output += stack_to_string(stack[0])
                  end
                end
              else
                stack.each do |item|
                  if ["\\w", "\\W", "\\d", "\\D", "\\s", "\\S"].includes? item[0]
                    item = decode_element([item]).as(Array(String))
                    output += item.sample(1)[0]
                  else
                    item = stack_to_string(item)

                    case item
                    when "\\t"
                      item = "\t"
                    when "\\n"
                      item = "\n"
                    when "\\v"
                      item = "v"
                    when "\\f"
                      item = "\f"
                    when "\\r"
                      item = "\r"
                    when "\\0"
                      item = "\0"
                    else
                      if item.starts_with?("\\") && item.size == 2
                        item = item.lchop
                      end
                    end

                    output += item
                end
              end
            end
          end
        end
        end
      else
        output = stack
      end

      return output
    end

    # Private method for decoding parts of character classes
    private def decode_element(element)
      element = element[0]
      case element
      when Array
        if element[1]?
          start = element[0].as(Array)[0]
          stop = element[2].as(Array)[0]

          start_pos = -1
          stop_pos = -1

          ACCEPTABLE_SET.map_with_index do |value, pos|
            if start == value
              start_pos = pos
            elsif stop == value
              stop_pos = pos
            end
          end

          if start_pos < 0 || stop_pos < 0
            raise "Could not find character #{start} or #{stop} in acceptable characters."
          end

          if start_pos > stop_pos
            raise "Range values reversed: #{start} and #{stop}"
          end

          return ACCEPTABLE_SET[start_pos..stop_pos]
        else
          character_class = element[0].as(String)
          if character_class.starts_with? "\\"
            case character_class
            when "\\w"
              chars = ACCEPTABLE_SET[16..25] + ACCEPTABLE_SET[33..58] + ACCEPTABLE_SET[65..90] + ["_"]
            when "\\W"
              chars = ACCEPTABLE_SET[16..25] + ACCEPTABLE_SET[33..58] + ACCEPTABLE_SET[65..90] + ["_"]
              chars = ACCEPTABLE_SET - chars
            when "\\d"
              chars = ACCEPTABLE_SET[16..25]
            when "\\D"
              chars = ACCEPTABLE_SET - ACCEPTABLE_SET[16..25]
            when "\\s"
              chars = [" ", "\n", "\t"]
            when "\\S"
              chars = ACCEPTABLE_SET - [" ", "\n", "\t"]
            else
              raise "Couldn't find character class #{character_class}"
            end

            return chars
          else
            return element
          end
        end
      else
        return element.as(String)
      end
    end
  end
end
