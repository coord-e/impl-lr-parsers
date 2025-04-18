S = NonTerminal.new(name: 'S')
E = NonTerminal.new(name: 'E')

RULES = [
  Rule.new(lhs: S, rhs: [E]),
  Rule.new(lhs: E, rhs: ['1', E]),
  Rule.new(lhs: E, rhs: ['1']),
]
