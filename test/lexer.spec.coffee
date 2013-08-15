chai = require 'chai'

do chai.should

Grammar = require '../src/grammar.coffee'
Lexer   = require '../src/lexer.coffee'

describe 'Lexer', ->

	describe 'constructor', ->
		it 'creates a new lexer based on a Grammar instance', ->
			grammar = new Grammar
					'@digit': [
						regex: '\\d{1}'
					]
			lexer = new Lexer grammar
			lexer.grammar.should.equal grammar

	describe 'tokenize', ->
		it 'returns a syntax tree as an object literal when passed root token name and a string', ->
			grammar = new Grammar
				'@digit': [
					regex: '\\d{1}'
				]
			lexer = new Lexer grammar
			tree = lexer.tokenize '@digit', '1'
			tree.should.be.json

		it 'creates a single element AST when matching a string using a grammar comprising only one terminal token', ->
			grammar = new Grammar
				'@digit': [
					regex: '\\d{1}'
				]

			lexer = new Lexer grammar
			tree = lexer.tokenize '@digit', '1'
			tree.should.deep.equal '@digit': '1'

		it 'matches a sequence of regex terminals inside a token', ->
			grammar = new Grammar
				'@two_letters': [
					{ regex: '\\[A-Z]{1}' }
					{ regex: '\\[a-z]{1}' }
				]

			lexer = new Lexer grammar
			tree = lexer.tokenize '@two_letters', 'Hi'
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

			tree = lexer.tokenize '@mark', 'A'
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

			tree = lexer.tokenize '@state_abbr', 'OH'
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

			tree = lexer.tokenize '@tree', 'branch branch  branch branch   	branch'
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

			tree = lexer.tokenize '@yummy', 'omnomnom'
			tree.should.deep.equal
				'@yummy': [
					{ '@om': [ { '@o': 'o' }, { '@m': 'm' } ]	}
					{ '@nom': [ { '@n': 'n' }, { '@o': 'o' }, { '@m': 'm' } ] }
					{ '@nom': [ { '@n': 'n' }, { '@o': 'o' }, { '@m': 'm' } ] }
				]

		# it 'returns a null value for the root token if the string couldn\'t be matched', ->
		# 	grammar = new Grammar
		# 		'@state_abbr': [
		# 			{ token: '@letter', quantifier: 2 }
		# 		]
		# 		'@letter': [
		# 			regex: '[A-Z]'
		# 		]

		# 	tree = lexer.tokenize '@state_abbr', 'AAA'
		# 	tree.should.deep.equal {}

