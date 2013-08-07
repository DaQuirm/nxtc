chai = require 'chai'

should = do chai.should

Grammar = require '../src/grammar.coffee'
TokenTree = require '../src/token-tree.coffee'

describe 'TokenTree', ->

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
		'@tag_close'  :  ['@ang_start', '@slash', '@tagname', '@ang_end']
		'@element'    :  ['@tag_open', '@text', '@tag_close']

	element_string = '<span class="item">text</span>'

	simple_grammar = new Grammar
		# Terminals
		'@a': regex:'a'
		'@b': regex:'b'
		'@c': regex:'c'
		# Non-terminals
		'@abc': ['@a', '@b', '@c']
		'@root': ['@abc']

	abc_string = 'abc'

	tree = null
	simple_tree = null

	beforeEach ->
		tree = new TokenTree grammar, '@element'
		simple_tree = new TokenTree simple_grammar, '@root'

	describe 'constructor', ->

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
			do tree.expand
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

			do simple_tree.expand
			do simple_tree.match abc_string, 0
			abc_token = simple_tree.root_token.children[0]
			abc_token.children.should.have.property 'length', 3
			abc_token.children[0].match.should.deep.equal { position: 0, length: 1 }
			abc_token.children[1].match.should.deep.equal { position: 1, length: 1 }
			abc_token.children[2].match.should.deep.equal { position: 2, length: 1 }

	describe 'bloom', ->
		it 'uses terminal matches to calculate match proeprties for all non-terminals', ->
			do simple_tree.expand
			do simple_tree.match abc_string, 0
			do simple_tree.bloom
			abc_token = simple_tree.root_token.children[0]
			abc_token.match.should.deep.equal { position: 0, length: 3 }
			simple_tree.root_token.match.should.deep.equal { position: 0, length: 3 }



