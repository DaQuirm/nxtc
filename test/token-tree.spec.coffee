chai = require 'chai'

should = do chai.should

Grammar = require '../src/grammar.coffee'

describe 'TokenTree', ->

	describe 'constructor', ->

		grammar = null
		element_string = '<span class="item">text</span>'

		beforeEach ->
			grammar = new Grammar
				# Terminals
				'@text'       :  regex:'\w+'
				'@ang_start'  :  regex:'<'
				'@ang_end'    :  regex:'>'
				'@slash'      :  regex:'/'
				'@space'      :  regex:'\s+'
				'@quot_mark'  :  regex:'"'
				'@equals_sign':  regex:'='
				# Non-terminals
				'@attr_name'  :  ['@text']
				'@attr_value' :  ['@quot_mark', '@text', '@quot_mark']
				'@attribute'  :  ['@attr_name', '@equals_sign', '@attr_value']
				'@tagname'    :  ['@text']
				'@tag_open'   :  ['@ang_start', '@tagname', '@space', '@attribute', '@ang_end']
				'@tag_close'  :  ['@ang_start', '@slash', '@tagname' '@ang_end']
				'@element'    :  ['@tag_open', '@text', '@tag_close']

			tree = new TokenTree grammar, '@element'

		it 'creates a tree based on a grammar instance and a root token', ->
			tree.grammar.should.deep.equal grammar
			tree.current_token.should.deep.equal
				name: '@element'
				children: []
				next: null
				match: null
			tree.current_token.should.deep.equal tree.root_token

	describe 'expand', ->
		it 'expands current_token until it\'s a terminal', ->
			do tree.expand
			#TREE
			# @element
			#   @tag_open
			#     @ang_start <--
			#     @tagname
			#     @space
			#     @attribute
			#     @ang_end
			#   @text
			#   @tag_close
			(Grammar.is_termial tree.current_token).should.be.true
			tree.current_token.name.should.equal '@ang_start'
			tree.root_token.children.to.be.an.instanceof 'Array'
			tree.root_token.children.to.have.property 'length', 3
			tree.root_token.children[0].children.to.have.property 'length', 5
			should.not.exist tree.root_token.match

		it 'threads token connecting them via the `next` field', ->
			do.tree.expand
			tag_open_token = tree.root_token.children[0]
			tag_open_token.next.name.should.equal 'text'
			tag_close_token = tag_open_token.next.next
			tag_close_token.next.should.be.null


	describe 'match', ->
		it 'matches contiguous terminal tokens starting from current_token in a string starting from specified position', ->
			do tree.expand
			do tree.match element_string, 0
			#TREE
			# @element 0 1
			#   @tag_open 0 1
			#     @ang_start 0 1
			#     @tagname <--
			#     @space
			#     @attribute
			#     @ang_end
			#   @text
			#   @tag_close
			(Grammar.is_termial tree.current_token).should.be.false
			should.not.exist tree.current_token.match
			ang_start_token = tree.root_token.children[0].children[0]
			ang_start_token.name.should.equal '@ang_start'
			ang_start_token.next.name.should.equal '@tagname'
			ang_start_token.match.should.deep.equal { position: 0, length: 1 }
