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
