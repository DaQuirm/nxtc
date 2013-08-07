chai = require 'chai'

do chai.should

Grammar = require '../src/grammar.coffee'

describe 'Grammar', ->

	describe 'is_terminal', ->
		it 'returns true if token doesn\'t contain other tokens', ->
			grammar = new Grammar
				'@terminal': [ regex:'a', regex:'b' ]
				'@non_terminal': [ '@terminal' ]
			grammar.is_terminal('@terminal').should.be.true
			grammar.is_terminal('@non_terminal').should.be.false

	describe 'constructor', ->
		it 'accepts an object literal as a parameter which is stored in the `tokens` field', ->
			grammar = new Grammar
				'@digit': [
					regex: '\\d{1}'
				]
			grammar.tokens.should.deep.equal
				'@digit': [
					regex: '\\d{1}'
				]

	describe 'tokenize', ->
		it 'returns a syntax tree as an object literal when passed root token name and a string', ->
			grammar = new Grammar
				'@digit': [
					regex: '\\d{1}'
				]

			tree = grammar.tokenize '@digit', '1'
			tree.should.be.json

		it 'creates a single element AST when matching a string using a grammar comprising only one terminal token', ->
			grammar = new Grammar
				'@digit': [
					regex: '\\d{1}'
				]

			tree = grammar.tokenize '@digit', '1'
			tree.should.deep.equal '@digit': '1'

		it 'matches a sequence of regex terminals inside a token', ->
			grammar = new Grammar
				'@two_letters': [
					{ regex: '\\[A-Z]{1}' }
					{ regex: '\\[a-z]{1}' }
				]

			tree = grammar.tokenize '@two_letters', 'Hi'
			tree.should.deep.equal '@two_letters': 'Hi'

		it 'matches a nonterminal token that contains a terminal', ->
			grammar = new Grammar
				'@mark': [
					token: '@letter'
					quantifier: 1
				]
				'@letter': [
					regex: '[A-Z]'
				]

			tree = grammar.tokenize '@mark', 'A'
			tree.should.deep.equal
				'@mark': [
					'@letter': 'A'
				]

		it 'matches tokens using specified integer quantifiers', ->
			grammar = new Grammar
				'@state_abbr': [
					{ token: '@letter', quantifier: 2 }
				]
				'@letter': [
					regex: '[A-Z]'
				]

			tree = grammar.tokenize '@state_abbr', 'OH'
			tree.should.deep.equal
				'@state_abbr': [
					{ '@letter': 'O' }
					{ '@letter': 'H' }
				]

		it 'matches mutiple tokens using `zero or more` quantifiers as arrays of matches', ->
			grammar = new Grammar
				'@tree': [
					{ token: '@branch', quantifier: '*' }
				]
				'@branch': [
					regex: 'branch\s+'
				]

			tree = grammar.tokenize '@tree', 'branch branch  branch branch   	branch'
			tree.should.deep.equal
				'@tree': [
					{ '@branch': ['branch'] }
					{ '@branch': ['branch'] }
					{ '@branch': ['branch'] }
					{ '@branch': ['branch'] }
					{ '@branch': ['branch'] }
				]

		it 'can use nested token grammars of arbitrary complexity', ->
			grammar = new Grammar
				'@yummy': [
					{ token: '@om', quantifier: 1 }
					{ token: '@nom', quantifier: 2 }
				]
				'@om': [
					{ token: '@o', quantifier: 1 }
					{ token: '@m', quantifier: 1 }
				]
				'@nom': [
					{ token: '@n', quantifier: 1 }
					{ token: '@o', quantifier: 1 }
					{ token: '@m', quantifier: 1 }
				]
				'@m':
					regex: 'm'
				'@n':
					regex: 'n'
				'@o':
					regex: 'o'

			tree = grammar.tokenize '@yummy', 'omnomnom'
			tree.should.deep.equal
				'@yummy': [
					{ '@om': [ { '@o': 'o' }, { '@m': 'm' } ]	}
					{ '@nom': [ { '@n': 'n' }, { '@o': 'o' }, { '@m': 'm' } ] }
					{ '@nom': [ { '@n': 'n' }, { '@o': 'o' }, { '@m': 'm' } ] }
				]

		it 'returns a null value for the root token if the string couldn\'t be matched', ->
			grammar = new Grammar
				'@state_abbr': [
					{ token: '@letter', quantifier: 2 }
				]
				'@letter': [
					regex: '[A-Z]'
				]

			tree = grammar.tokenize '@state_abbr', 'AAA'
			tree.should.deep.equal {}

