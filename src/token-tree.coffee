class TokenTree

	@create_node: (token_name) ->
		name: token_name
		children: []
		next: null
		match: null

	constructor: (@grammar, @string, root_token_name)->
		@current_token = @root_token = TokenTree.create_node root_token_name
		@position = 0

	expand: ->
		while not @grammar.is_terminal @current_token.name

			@grammar.tokens[@current_token.name].forEach (token, index) =>
				{token, quantifier} = token if typeof token is 'object'
				node = TokenTree.create_node token
				quantifier ?= 1
				nodes = Array::map.call (Array ++quantifier).join('|'), -> TokenTree.create_node token
				@current_token.children = @current_token.children.concat nodes

			@current_token.children.reduce (previous, current) ->
				previous.next = current
				current

			[first_child, _..., last_child] = @current_token.children
			last_child ?= first_child
			last_child.next = @current_token.next
			last_child.parent = @current_token
			@current_token = @current_token.next = first_child

	match: ->
		while @current_token? and @grammar.is_terminal @current_token.name
			match = @string.substr(@position).match @grammar.tokens[@current_token.name].regex
			@current_token.match =
				position: match.index + @position
				length: match[0].length
			@position += match[0].length
			parent = @current_token.parent
			while parent
				parent.match =
					position: parent.children[0].match.position
					length: parent.children.reduce ((sum, item) -> sum + item.match.length), 0
				parent = parent.parent
			@current_token = @current_token.next

module.exports = TokenTree
