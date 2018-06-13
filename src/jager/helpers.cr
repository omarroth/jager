module Jager
  class Engine
    def regex_bnf
      bnf = <<-'END_BNF'
        :start ::= regex
        regex ::= union
        | elements

        union ::= elements+ separator => <union op>
        action => union
        proper => 1

        <union op> ~ '|'

        elements ::= element+
        element ::= '(' regex ')' action => capture_group
        | '(?=' elements ')' action => not_implemented
        | '(?!' elements ')' action => not_implemented
        | '(?:' elements ')' action => not_implemented
        | '[' <character set elements> ']' action => character_set
        | '[^' <character set elements> ']' action => negated_set
        | element '+' action => plus
        | element '*' action => star
        | element '?' action => optional
        | element quantifier action => quantifier
        | character action => character
        | group action => group

        quantifier ::= '{' min '}'
        | '{' min ',' '}'
        | '{' min ',' max '}'

        min ~ number
        max ~ number

        number ~ [\d]+

        <character set elements> ::= <character set element>*
        <character set element> ::= range action => range
        | group action => group
        | character
        | <set character>

        range ::= character '-' character
        group ~ /\\[wWdDsS]|\./

        character ::= ascii
        | <reserved character> action => reserved_character
        | <escaped character> action => escaped_character
        | <octal escape> action => octal_escape
        | <hexadecimal escape> action => hexadecimal_escape
        | <unicode escape> action => unicode_escape
        | <extended unicode escape> action => extended_unicode_escape
        | <control character escape> action => control_character_escape

        ascii ~ [ !"#%&',0-9:;<=>@A-Z_`a-z{}~-]
        <reserved character> ~ /\\[+*?^$\\\.\[\]\{\}\(\)\|\/]/
        <escaped character> ~ '\' ascii
        <set character> ~ [+*?^$.[{}()|/]

        <octal escape> ~ /\\[\d]{3}/
        <hexadecimal escape> ~ /\\x[a-fA-F0-9]{2}/
        <unicode escape> ~ /\\u[a-fA-F0-9]{4}/
        <extended unicode escape> ~ /(\\u|\\x){[a-zA-Z0-9]+}/
        <control character escape> ~ /\\c[a-zA-Z]/
      END_BNF
      return bnf
    end
  end
end
