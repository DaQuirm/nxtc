jsdom = require 'jsdom'

walk = (node) ->
	node = node.firstChild
	while node
		walk node
		node = node.nextSibling

jsdom.env 'letter-view.nxt', (errors, window) ->
	walk window.document

