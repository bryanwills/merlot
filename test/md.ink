` Markdown library tests `

std := load('../vendor/std')

cat := std.cat

md := load('../lib/md')
compile := md.compile

Newline := char(10)

run := (m, t) => (
	` NOTE: Because we don't want the tests to depend on any internal
	implementation detail, we only test two high level components of the
	Markdown module: md.parse: text -> AST and md.compile: AST -> text. `

	m('md.parse/inline nodes')
	(
		parse := md.parse

		t('plain text', parse('hello'), [{
			tag: 'p'
			children: ['hello']
		}])
		t('characters are escaped properly by \\', parse('\\- x86\\_64'), [{
			tag: 'p'
			children: ['- x86_64']
		}])
		t('text with delimiters parses as one text node', parse('[([ hi) ]'), [{
			tag: 'p'
			children: ['[([ hi) ]']
		}])
		t('plain header h1', parse('# hello'), [{
			tag: 'h1'
			children: ['hello']
		}])
		t('plain header h4', parse('#### hello world'), [{
			tag: 'h4'
			children: ['hello world']
		}])

		t('italic with underscore', parse('_italicized_'), [{
			tag: 'p'
			children: [{
				tag: 'em'
				children: ['italicized']
			}]
		}])
		t('italic with asterisk', parse('*italicized*'), [{
			tag: 'p'
			children: [{
				tag: 'em'
				children: ['italicized']
			}]
		}])
		t('bold with underscore', parse('__bolded__'), [{
			tag: 'p'
			children: [{
				tag: 'strong'
				children: ['bolded']
			}]
		}])
		t('bold with asterisk', parse('**bolded**'), [{
			tag: 'p'
			children: [{
				tag: 'strong'
				children: ['bolded']
			}]
		}])
		t('inline code block', parse('`code block`'), [{
			tag: 'p'
			children: [{
				tag: 'code'
				children: ['code block']
			}]
		}])
		t('strikethrough inline', parse('~struck out~'), [{
			tag: 'p'
			children: [{
				tag: 'strike'
				children: ['struck out']
			}]
		}])
		t('strikethrough within text', parse('hi ~hello~ world'), [{
			tag: 'p'
			children: [
				'hi '
				{
					tag: 'strike'
					children: ['hello']
				}
				' world'
			]
		}])
		t('unclosed italic automatically closes at end of line', parse('_ital'), [{
			tag: 'p'
			children: [{
				tag: 'em'
				children: ['ital']
			}]
		}])
		t('unclosed bold automatically closes at end of line', parse('**bold'), [{
			tag: 'p'
			children: [{
				tag: 'strong'
				children: ['bold']
			}]
		}])
		t('unclosed tags all automatically close at end of line', parse('**_mixed case'), [{
			tag: 'p'
			children: [{
				tag: 'strong'
				children: [{
					tag: 'em'
					children: ['mixed case']
				}]
			}]
		}])
		t('italic, bold, code block in header', parse('## my _big_ **scary** `code`'), [{
			tag: 'h2'
			children: [
				'my '
				{
					tag: 'em'
					children: ['big']
				}
				' '
				{
					tag: 'strong'
					children: ['scary']
				}
				' '
				{
					tag: 'code'
					children: ['code']
				}
			]
		}])

		t('mixed italic and bold separately', parse('_ital_ **bold**'), [{
			tag: 'p'
			children: [
				{
					tag: 'em'
					children: ['ital']
				}
				' '
				{
					tag: 'strong'
					children: ['bold']
				}
			]
		}])
		t('mixed italic and bold together', parse('this **whole _text_ is bolded**'), [{
			tag: 'p'
			children: [
				'this '
				{
					tag: 'strong'
					children: [
						'whole '
						{
							tag: 'em'
							children: ['text']
						}
						' is bolded'
					]
				}
			]
		}])
		t('coincident italic and bold', parse('**_really emphasized_**'), [{
			tag: 'p'
			children: [{
				tag: 'strong'
				children: [{
					tag: 'em'
					children: ['really emphasized']
				}]
			}]
		}])

		t('plain text link', parse('[text](dst)'), [{
			tag: 'p'
			children: [{
				tag: 'a'
				href: 'dst'
				children: ['text']
			}]
		}])
		t('rich text link inside', parse('[rich **text**](#dst-link)'), [{
			tag: 'p'
			children: [{
				tag: 'a'
				href: '#dst-link'
				children: [
					'rich '
					{
						tag: 'strong'
						children: ['text']
					}
				]
			}]
		}])
		t('rich text link outside', parse('_[rich text](link)_'), [{
			tag: 'p'
			children: [{
				tag: 'em'
				children: [{
					tag: 'a'
					href: 'link'
					children: ['rich text']
				}]
			}]
		}])
		t('link href does not get Markdown-formatted', parse('[link](_dst_)'), [{
			tag: 'p'
			children: [{
				tag: 'a'
				href: '_dst_'
				children: ['link']
			}]
		}])

		t('link with preceding []', parse('[link like this] [another link](dst)'), [{
			tag: 'p'
			children: [
				'[link like this] '
				{
					tag: 'a'
					href: 'dst'
					children: ['another link']
				}
			]
		}])
		t('link with internal []', parse('[link like this [[another] ](this)'), [{
			tag: 'p'
			children: [
				'[link like this '
				{
					tag: 'a'
					href: 'this'
					children: ['[another] ']
				}
			]
		}])
		t('link with two following ()s', parse('[link [some*thing*](first)(second)'), [{
			tag: 'p'
			children: [
				'[link '
				{
					tag: 'a'
					href: 'first'
					children: [
						'some'
						{
							tag: 'em'
							children: ['thing']
						}
					]
				}
				'(second)'
			]
		}])
		t('incomplete link', parse('[this is an incomplete](link'), [{
			tag: 'p'
			children: ['[this is an incomplete](link']
		}])
		t('link in surrounding text', parse('ab [cd](ef) ghi'), [{
			tag: 'p'
			children: [
				'ab '
				{
					tag: 'a'
					href: 'ef'
					children: ['cd']
				}
				' ghi'
			]
		}])

		t('! without following link syntax is not an image', parse('hello !image'), [{
			tag: 'p'
			children: ['hello !image']
		}])
		t('! followed by link syntax is an image', parse('![alt text](dst text)'), [{
			tag: 'p'
			children: [{
				tag: 'img'
				alt: 'alt text'
				src: 'dst text'
			}]
		}])
		t('text in alt region of image is not formatted', parse('![alt **text**](dst)'), [{
			tag: 'p'
			children: [{
				tag: 'img'
				alt: 'alt **text**'
				src: 'dst'
			}]
		}])
		t('image in link', parse('[an ![image](linked) thing](https://google.com/)'), [{
			tag: 'p'
			children: [{
				tag: 'a'
				href: 'https://google.com/'
				children: [
					'an '
					{
						tag: 'img'
						alt: 'image'
						src: 'linked'
					}
					' thing'
				]
			}]
		}])
		t('image in surrounding text', parse('ab ![cd](ef) ghi'), [{
			tag: 'p'
			children: [
				'ab '
				{
					tag: 'img'
					alt: 'cd'
					src: 'ef'
				}
				' ghi'
			]
		}])
	)

	m('md.parse/block nodes')
	(
		parse := md.parse

		parseLines := lines => parse(cat(lines, Newline))

		t('consecutive lines parse as one paragraph', parseLines(['hello', 'world']), [{
			tag: 'p'
			children: ['hello world']
		}])
		t('nonconsecutive lines parse as two paragraphs', parseLines(['a', 'b', '', 'd']), [
			{
				tag: 'p'
				children: ['a b']
			}
			{
				tag: 'p'
				children: ['d']
			}
		])

		t('one line block quote', parse('>hello world'), [{
			tag: 'q'
			children: [{
				tag: 'p'
				children: ['hello world']
			}]
		}])
		t('multiline block quote', parseLines(['>hello world', '>goodbye!']), [{
			tag: 'q'
			children: [
				{
					tag: 'p'
					children: ['hello world goodbye!']
				}
			]
		}])
		t('block quote in text', parseLines(['first', '>blockquote!', 'second']), [
			{
				tag: 'p'
				children: ['first']
			}
			{
				tag: 'q'
				children: [{
					tag: 'p'
					children: ['blockquote!']
				}]
			}
			{
				tag: 'p'
				children: ['second']
			}
		])
		t('multiline block quote in text', parseLines(['>blockquote!', '>continued *here*', 'second']), [
			{
				tag: 'q'
				children: [
					{
						tag: 'p'
						children: [
							'blockquote! continued '
							{
								tag: 'em'
								children: ['here']
							}
						]
					}
				]
			}
			{
				tag: 'p'
				children: ['second']
			}
		])
		t('quoted block inside quoted block', parseLines(['>layer 1', '>>layer 2', '>>layer 2', '>layer 1']), [{
			tag: 'q'
			children: [
				{
					tag: 'p'
					children: ['layer 1']
				}
				{
					tag: 'q'
					children: [{
						tag: 'p'
						children: ['layer 2 layer 2']
					}]
				}
				{
					tag: 'p'
					children: ['layer 1']
				}
			]
		}])
		lines := [
			'>1'
			'>- A'
			'>  - B'
			'>- C'
			'>2'
		]
		t('nested list inside a quoted block', parseLines(lines), [{
			tag: 'q'
			children: [
				{
					tag: 'p'
					children: ['1']
				}
				{
					tag: 'ul'
					children: [
						{
							tag: 'li'
							children: [
								'A'
								{
									tag: 'ul'
									children: [{
										tag: 'li'
										children: ['B']
									}]
								}
							]
						}
						{
							tag: 'li'
							children: ['C']
						}
					]
				}
				{
					tag: 'p'
					children: ['2']
				}
			]
		}])

		t('unordered list with one item', parse('- hello world'), [{
			tag: 'ul'
			children: [{
				tag: 'li'
				children: ['hello world']
			}]
		}])
		t('small unordered list', parseLines(['- a', '- b']), [{
			tag: 'ul'
			children: [
				{
					tag: 'li'
					children: ['a']
				}
				{
					tag: 'li'
					children: ['b']
				}
			]
		}])

		lines := [
			'- baa baa **black sheep**'
			'- old ![mcdonalds](had) a farm!'
			'- done.'
		]
		t('unordered list with formatted text', parseLines(lines), [{
			tag: 'ul'
			children: [
				{
					tag: 'li'
					children: [
						'baa baa '
						{
							tag: 'strong'
							children: ['black sheep']
						}
					]
				}
				{
					tag: 'li'
					children: [
						'old '
						{
							tag: 'img'
							alt: 'mcdonalds'
							src: 'had'
						}
						' a farm!'
					]
				}
				{
					tag: 'li'
					children: ['done.']
				}
			]
		}])

		lines := [
			'- first level'
			'  - second level'
			'- first level again'
		]
		t('unordered list with nesting', parseLines(lines), [{
			tag: 'ul'
			children: [
				{
					tag: 'li'
					children: [
						'first level'
						{
							tag: 'ul'
							children: [{
								tag: 'li'
								children: ['second level']
							}]
						}
					]
				}
				{
					tag: 'li'
					children: ['first level again']
				}
			]
		}])

		lines := [
			'first paragraph'
			'- a'
			'  - b'
			'- c'
			'  - d'
			'    - d2'
			'    - d3'
			'  - e'
			'- f'
			'last paragraph'
		]
		t('unordered list with multiple nesting', parseLines(lines), [
			{
				tag: 'p'
				children: ['first paragraph']
			}
			{
				tag: 'ul'
				children: [
					{
						tag: 'li'
						children: [
							'a'
							{
								tag: 'ul'
								children: [{
									tag: 'li'
									children: ['b']
								}]
							}
						]
					}
					{
						tag: 'li'
						children: [
							'c'
							{
								tag: 'ul'
								children: [
									{
										tag: 'li'
										children: [
											'd'
											{
												tag: 'ul'
												children: [
													{
														tag: 'li'
														children: ['d2']
													}
													{
														tag: 'li'
														children: ['d3']
													}
												]
											}
										]
									}
									{
										tag: 'li'
										children: ['e']
									}
								]
							}
						]
					}
					{
						tag: 'li'
						children: ['f']
					}
				]
			}
			{
				tag: 'p'
				children: ['last paragraph']
			}
		])

		lines := [
			'first random line'
			'- first list item'
			'- second list item'
			'last random line'
		]
		t('unordered list in text', parseLines(lines), [
			{
				tag: 'p'
				children: ['first random line']
			}
			{
				tag: 'ul'
				children: [
					{
						tag: 'li'
						children: ['first list item']
					}
					{
						tag: 'li'
						children: ['second list item']
					}
				]
			}
			{
				tag: 'p'
				children: ['last random line']
			}
		])

		t('one line code block', parseLines(['```', 'hello **not bold**', '```']), [{
			tag: 'pre'
			children: [{
				tag: 'code'
				lang: ''
				children: ['hello **not bold**']
			}]
		}])
		lines := [
			'```'
			'hello world()'
			'    -ing'
			'*foo := bar/baz'
			'```'
		]
		t('multiline code block', parseLines(lines), [{
			tag: 'pre'
			children: [{
				tag: 'code'
				lang: ''
				children: ['hello world()
    -ing
*foo := bar/baz']
			}]
		}])
		t('code block with language tag', parseLines(['```ink', 'log := std.log', '```']), [{
			tag: 'pre'
			children: [{
				tag: 'code'
				lang: 'ink'
				children: ['log := std.log']
			}]
		}])

		t('!html in one line', parse('!html <img src="dst" alt="me!">'), [{
			tag: '-raw-html'
			children: ['<img src="dst" alt="me!">']
		}])
		t('multiline !html', parseLines(['!html <div class="hi"', 'hidden', '></div>']), [{
			tag: '-raw-html'
			children: ['<div class="hi"
hidden
></div>']
		}])
		lines := [
			'hello'
			''
			'!html <', 'hr', '/>'
			''
		'bye']
		t('multiline !html in other text', parseLines(lines), [
			{
				tag: 'p'
				children: ['hello']
			}
			{
				tag: '-raw-html'
				children: ['<
hr
/>']
			}
			{
				tag: 'p'
				children: ['bye']
			}
		])

		t('neverending code block does not break parser', parseLines(['```', 'ahh!']), [{
			tag: 'pre'
			children: [{
				tag: 'code'
				lang: ''
				children: ['ahh!']
			}]
		}])

		t('horizontal dividers between paragraphs', parseLines(['a', '---', 'b', 'b', '***', 'c']), [
			{tag: 'p', children: ['a']}
			{tag: 'hr'}
			{tag: 'p', children: ['b b']}
			{tag: 'hr'}
			{tag: 'p', children: ['c']}
		])

		t('hr mark followed by excess characters', parseLines(['a', '--- whatever', 'b']), [
			{tag: 'p', children: ['a']}
			{tag: 'hr'}
			{tag: 'p', children: ['b']}
		])
	)

	m('md.compile')
	(
		compile := md.compile
		t(
			'plain text'
			compile(['hello world'])
			'hello world'
		)
		t(
			'single paragraph'
			compile([{
				tag: 'p'
				children: ['goodbye world']
			}])
			'<p>goodbye world</p>'
		)
		t(
			'inline marks'
			compile([{
				tag: 'p'
				children: [
					'abc '
					{
						tag: 'strong'
						children: ['def']
					}
					' ghi '
					{
						tag: 'em'
						children: ['jkl']
					}
				]
			}]
			)
		'<p>abc <strong>def</strong> ghi <em>jkl</em></p>')
		t(
			'nested marks'
			compile([{
				tag: 'p'
				children: [{
					tag: 'code'
					children: [{
						tag: 'strong'
						children: ['internals check']
					}]
				}]
			}]
			), '<p><code><strong>internals check</strong></code></p>'
		)
		t(
			'links'
			compile([{
				tag: 'p'
				children: [{
					tag: 'a'
					href: 'some url'
					children: [{
						tag: 'em'
						children: ['click here']
					}]
				}]
			}])
			'<p><a href="some url"><em>click here</em></a></p>'
		)
		t(
			'image'
			compile([{
				tag: 'p'
				children: [{
					tag: 'img'
					alt: 'alternative text'
					src: 'https://linus.zone/pic'
				}]
			}])
			'<p><img alt="alternative text" src="https://linus.zone/pic"/></p>'
		)
		t(
			'headers'
			compile([
				{
					tag: 'h1'
					children: ['first header']
				}
				{
					tag: 'h3'
					children: [
						{
							tag: 'em'
							children: ['second']
						}
						' header'
					]
				}
			])
			'<h1>first header</h1><h3><em>second</em> header</h3>'
		)
		t(
			'pre tag preserves whitespace'
			compile([
				{
					tag: 'pre'
					children: ['first line
	second line, indented
third line']
				}
			])
			'<pre>first line
	second line, indented
third line</pre>'
		)
		t(
			'pre tag with code inside'
			compile([{
				tag: 'pre'
				children: [{
					tag: 'code'
					children: ['first line
second line
	third']
				}]
			}])
			'<pre><code>first line
second line
	third</code></pre>'
		)
		t(
			'code with language attribute'
			compile([{
				tag: 'code'
				lang: 'ink'
				children: ['log := std(\'log\')']
			}])
			'<code data-lang="ink">log := std(\'log\')</code>'
		)

		t(
			'nested list with one item'
			compile([{
				tag: 'ul'
				children: [
					{
						tag: 'li'
						children: ['my list item']
					}
				]
			}])
			'<ul><li>my list item</li></ul>'
		)
		t(
			'nested list with many items'
			compile([{
				tag: 'ul'
				children: [
					{
						tag: 'li'
						children: [
							'first'
							{
								tag: 'ul'
								children: [
									{
										tag: 'li'
										children: ['sub-first']
									}
									{
										tag: 'li'
										children: ['sub-first']
									}
								]
							}
						]
					}
					{
						tag: 'li'
						children: ['second']
					}
				]
			}])
			'<ul><li>first<ul><li>sub-first</li><li>sub-first</li></ul></li><li>second</li></ul>'
		)

		t(
			'raw html'
			compile([
				{
					tag: 'p'
					children: ['before html']
				}
				{
					tag: '-raw-html'
					children: ['<img src="dst" loading="lazy" />']
				}
				{
					tag: 'p'
					children: ['after html']
				}
			])
			'<p>before html</p><img src="dst" loading="lazy" /><p>after html</p>'
		)

		t(
			'unknown tags'
			compile([{
				tag: 'broken'
			}])
			'<span style="color:red">Unknown Markdown node {tag: \'broken\'}</span>'
		)
	)

	m('md.transform integration sanity tests')
	(
		transform := md.transform

		t(
			'plain text'
			transform('hello world')
			'<p>hello world</p>'
		)
		t(
			'inline marks'
			transform('**bold** _italic_ `code line`')
			'<p><strong>bold</strong> <em>italic</em> <code>code line</code></p>'
		)
		t(
			'header'
			transform('## totally [AWESOME](link)')
			'<h2>totally <a href="link">AWESOME</a></h2>'
		)
	)
)