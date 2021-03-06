chai = require 'chai'

should = do chai.should

Grammar = require '../src/grammar.coffee'
TokenTree = require '../src/token-tree.coffee'

describe 'TokenTree', ->

	grammar = new Grammar
		# Terminals
		'@text'       :  regex:'\\w+'
		'@ang_start'  :  regex:'<'
		'@ang_end'    :  regex:'>'
		'@slash'      :  regex:'/'
		'@space'      :  regex:'\\s+'
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
		tree = new TokenTree grammar, element_string, '@element'
		simple_tree = new TokenTree simple_grammar, abc_string, '@root'

	describe 'constructor', ->
		it 'creates a tree based on a grammar instance, a string and a root token', ->
			tree.grammar.should.deep.equal grammar

		it 'sets current_token to the root_token', ->
			tree.current_token.should.deep.equal
				name: '@element'
				children: []
				next: null
				match: null
			tree.current_token.should.deep.equal tree.root_token

		it 'sets position to zero', ->
			tree.position.should.equal 0

	describe 'create_node', ->
		it 'creates an empty tree node based on a token name', ->
			node = TokenTree.create_node '@root'
			node.should.deep.equal
				name: '@root'
				children: []
				next: null
				match: null

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
			(grammar.is_terminal tree.current_token.name).should.be.true
			tree.current_token.name.should.equal '@ang_start'
			tree.root_token.children.should.be.an.instanceof Array
			tree.root_token.children.should.have.property 'length', 3
			tree.root_token.children[0].children.should.have.property 'length', 5
			should.not.exist tree.root_token.match

		it 'threads token connecting them via the `next` field', ->
			do tree.expand
			tag_open_token = tree.root_token.children[0]
			tag_open_token.next.name.should.equal '@ang_start'
			ang_end_token = tag_open_token.children[3].next
			tag_close_token = ang_end_token.next.next
			should.not.exist tag_close_token.next

			lonely_child_grammar = new Grammar
				'@abc'   : regex: 'ab'
				'@next'  : regex: 'c'
				'@child' : ['@abc']
				'@parent': ['@child', '@next']

			lonely_child_tree = new TokenTree lonely_child_grammar, abc_string, '@parent'
			do lonely_child_tree.expand
			child_token = lonely_child_tree.root_token.children[0].children[0];
			child_token.next.name.should.equal '@next'

		it 'supports extended token notation with a literal instead of name', ->
			abbr_grammar = new Grammar
				'@state_abbr': [
					{ token: '@letter' }
					{ token: '@letter' }
				]
				'@letter': regex:'[A-Z]'
			tree = new TokenTree abbr_grammar, 'CA', '@state_abbr'
			do tree.expand
			#TREE
			# @state_abbr
			#   @letter <--
			#   @letter
			tree.current_token.name.should.equal '@letter'
			tree.root_token.children.should.have.property 'length', 2
			tree.root_token.children[1].name.should.equal '@letter'

		it 'expands tokens with integer quantifiers as multiple nodes', ->
			abbr_grammar = new Grammar
				'@state_abbr': [
					{ token: '@letter', quantifier: 2 }
				]
				'@letter': regex:'[A-Z]'
			tree = new TokenTree abbr_grammar, 'CA', '@state_abbr'
			do tree.expand
			tree.current_token.name.should.equal '@letter'
			tree.root_token.children.should.have.property 'length', 2
			tree.root_token.children[1].name.should.equal '@letter'

	describe 'match', ->
		it 'matches contiguous terminal tokens starting from current_token', ->
			do tree.expand
			do tree.match
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
			(grammar.is_terminal tree.current_token.name).should.be.false
			should.not.exist tree.current_token.match
			ang_start_token = tree.root_token.children[0].children[0]
			ang_start_token.name.should.equal '@ang_start'
			ang_start_token.next.name.should.equal '@tagname'
			ang_start_token.match.should.deep.equal { position: 0, length: 1 }

			do simple_tree.expand
			do simple_tree.match
			abc_token = simple_tree.root_token.children[0]
			abc_token.children.should.have.property 'length', 3
			abc_token.children[0].match.should.deep.equal { position: 0, length: 1 }
			abc_token.children[1].match.should.deep.equal { position: 1, length: 1 }
			abc_token.children[2].match.should.deep.equal { position: 2, length: 1 }

		it 'updates lookup position', ->
			do tree.expand
			do tree.match
			tree.position.should.equal 1
			do tree.expand
			#TREE
			# @element 0 6
			#   @tag_open 0 6
			#     @ang_start 0 1
			#     @tagname 1 4
			#       @text 1 4
			#     @space 5 1
			#     @attribute <--
			#     @ang_end
			#   @text
			#   @tag_close
			#
			# <span class="item">text</span>
			#       ^
			do tree.match
			tree.position.should.equal 6

		it 'uses terminal matches to calculate match properties for all non-terminals', ->
			do simple_tree.expand
			do simple_tree.match
			abc_token = simple_tree.root_token.children[0]
			abc_token.match.should.deep.equal { position: 0, length: 3 }
			simple_tree.root_token.match.should.deep.equal { position: 0, length: 3 }
