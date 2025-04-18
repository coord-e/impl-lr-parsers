require_relative 'lib/symbol'
require_relative 'lib/rule'
require_relative 'lib/parsing_table'
require_relative 'lib/parsing_table/builder'
require_relative 'lib/parser'

raise "main.rb [LR0|LR1|LALR1] [GRAMMAR_FILE]" unless ARGV[0] && ARGV[1]

load ARGV[1]

puts
puts "=== RULES"
RULES.each_with_index do |rule, index|
  puts "#{index}:\t#{rule.to_s}"
end
builder = ParsingTable::Builder.const_get(ARGV[0]).new(rules: RULES)
table = builder.build

puts
puts "=== TABLE"
STDOUT.puts "\t#{builder.all_terminals.join("\t")}\tgoto"
table.states.each_with_index do |state, index|
  next if state.nil?
  STDOUT.print "#{index}:\t"
  builder.all_terminals.each do |t|
    STDOUT.print "#{state.actions[t].to_s || 'nil'}\t"
  end
  STDOUT.puts state.goto.transform_keys(&:name)
end

puts "#states #{table.states.compact.size}"

parser = Parser.new(table: table, rules: RULES)

puts
puts "=== PARSING"
puts "(tokenized by ' ')"
loop do
  print '> '
  line = STDIN.gets
  break unless line
  parser.parse(line.split(' ') + ['$'])
end
