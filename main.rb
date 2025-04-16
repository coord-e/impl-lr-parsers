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
  Rule.new(lhs: E, rhs: [B, E]),
  Rule.new(lhs: E, rhs: []),
  Rule.new(lhs: B, rhs: ['1', B]),
  Rule.new(lhs: B, rhs: ['0']),
]

puts
puts "=== RULES"
RULES.each_with_index do |rule, index|
  puts "#{index}:\t#{rule.to_s}"
end
TABLE = ParsingTable::Builder::LR1.new(rules: RULES).build

puts
puts "=== TABLE"
STDOUT.puts "\t*\t+\t0\t1\t$\tgoto"
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
parser.parse(['1', '0', '1', '0', '0', '$'])
