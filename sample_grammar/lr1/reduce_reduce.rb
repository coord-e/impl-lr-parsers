S = NonTerminal.new(name: 'S')
E = NonTerminal.new(name: 'E')
A = NonTerminal.new(name: 'A')
B = NonTerminal.new(name: 'B')

RULES = [
  Rule.new(lhs: S, rhs: [E]),
  Rule.new(lhs: E, rhs: [A, '1']),
  Rule.new(lhs: E, rhs: [B, '2']),
  Rule.new(lhs: A, rhs: ['1']),
  Rule.new(lhs: B, rhs: ['1']),
]
