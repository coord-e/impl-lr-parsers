require_relative 'lib/symbol'
require_relative 'lib/rule'
require_relative 'lib/parsing_table'
require_relative 'lib/parsing_table/builder'
require_relative 'lib/parser'

S = NonTerminal.new(name: 'S')
E = NonTerminal.new(name: 'E')
B = NonTerminal.new(name: 'B')
RULES = [
  Rule.new(lhs: S, rhs: [E]),
  Rule.new(lhs: E, rhs: [E, '*', B]),
  Rule.new(lhs: E, rhs: [E, '+', B]),
  Rule.new(lhs: E, rhs: ['-', B]),
  Rule.new(lhs: E, rhs: [B]),
  Rule.new(lhs: B, rhs: ['0']),
  Rule.new(lhs: B, rhs: ['1']),
  Rule.new(lhs: B, rhs: ['?']),
]

puts
puts "=== RULES"
RULES.each_with_index do |rule, index|
  puts "#{index}:\t#{rule.to_s}"
end
TABLE = ParsingTable::Builder.new(rules: RULES).build

puts
puts "=== TABLE"
STDOUT.puts "\t*\t+\t0\t1\tgoto"
TABLE.states.each_with_index do |state, index|
  STDOUT.print "#{index}:\t"
  ['*', '+', '0', '1', '$'].each do |t|
    STDOUT.print "#{state.actions[t].to_s || 'nil'}\t"
  end
  STDOUT.puts state.goto.transform_keys(&:name)
end

parser = Parser.new(table: TABLE, rules: RULES)

puts
puts "=== PARSING"
parser.parse(['0', '*', '1', '+', '?', '$'])
