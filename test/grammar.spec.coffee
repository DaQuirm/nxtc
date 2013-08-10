chai = require 'chai'

do chai.should

Grammar = require '../src/grammar.coffee'

describe 'Grammar', ->

	describe 'is_terminal', ->
		it 'returns true if token doesn\'t contain other tokens', ->
			grammar = new Grammar
				'@terminal': [ regex:'a', regex:'b' ]
				'@non_terminal': [ '@terminal' ]
				'@single_regex': regex:'\d'
			grammar.is_terminal('@terminal').should.be.true
			grammar.is_terminal('@non_terminal').should.be.false
			grammar.is_terminal('@single_regex').should.be.true

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
