#!/usr/bin/ruby -w
#
# Test case for BlueCloth Markdown transforms.
# $Id: TEMPLATE.rb.tpl,v 1.2 2003/09/11 04:59:51 deveiant Exp $
#
# Copyright (c) 2004 The FaerieMUD Consortium.
# 

if File::exists?( "lib/bluecloth.rb" )
	require 'tests/bctestcase'
else
	require 'bctestcase'
end


### This test case tests ...
class SubfunctionsTestCase < BlueCloth::TestCase

	TestSets = {}
	begin
		seenEnd = false
		inMetaSection = true
		inInputSection = true
		section, description, input, output = '', '', '', ''
		linenum = 0

		# Read this file, skipping lines until the __END__ token. Then start
		# reading the tests.
		File::foreach( __FILE__ ) {|line|
			linenum += 1
			if /^__END__/ =~ line then seenEnd = true; next end
			debugMsg "#{linenum}: #{line.chomp}"
			next unless seenEnd

			# Start off in the meta section, which has sections and
			# descriptions.
			if inMetaSection
				
				case line

				# Left angles switch into data section for the current section
				# and description.
				when /^<<</
					inMetaSection = false
					next

				# Section headings look like:
				# ### [Code blocks]
				when /^### \[([^\]]+)\]/
					section = $1.chomp
					TestSets[ section ] ||= {}

				# Descriptions look like:
				# # Para plus code block
				when /^# (.*)/
					description = $1.chomp
					TestSets[ section ][ description ] ||= {
						:line => linenum,
						:sets => [],
					}

				end

			# Data section has input and expected output parts
			else

				case line

				# Right angles terminate a data section, at which point we
				# should have enough data to add a test.
				when /^>>>/
					TestSets[ section ][ description ][:sets] << [ input.chomp, output.chomp ]

					inMetaSection = true
					inInputSection = true
					input = ''; output = ''

				# 3-Dashed divider with text divides input from output
				when /^--- (.+)/
					inInputSection = false

				# Anything else adds to either input or output
				else
					if inInputSection
						input += line
					else
						output += line
					end
				end
			end
		}			
	end

	debugMsg "Test sets: %p" % TestSets

	TestSets.each {|sname, section|

		section.each do |desc, test|
			methname = "test_%03d_%s" %
				[ test[:line], desc.gsub(/\W+/, '_').downcase ]

			code = %{
				def #{methname}
					printTestHeader "BlueCloth: #{desc}"
					rval = nil
			}

			test[:sets].each {|input, output|
				code << %{
					assert_nothing_raised {
						obj = BlueCloth::new(%p)
						rval = obj.to_html
					}
					assert_equal %p, rval

				} % [ input, output ]
			}

			code << %{
				end
			}


			debugMsg "--- %s [%s]:\n%s\n---\n" % [sname, desc, code]
			eval code
		end

	}

end


__END__

### [Paragraphs and Line Breaks]

# Paragraphs
<<<
This is some stuff that should all be 
put in one paragraph
even though 
it occurs over several lines.

And this is a another
one.
--- Should become:
<p>This is some stuff that should all be 
put in one paragraph
even though 
it occurs over several lines.</p>

<p>And this is a another
one.</p>
>>>

# Line breaks
<<<
Mostly the same kind of thing  
with two spaces at the end  
of each line  
should result in  
line breaks, though.

And this is a another  
one.
--- Should become:
<p>Mostly the same kind of thing<br/>
with two spaces at the end<br/>
of each line<br/>
should result in<br/>
line breaks, though.</p>

<p>And this is a another<br/>
one.</p>
>>>

# Escaping special characters
<<<
The left shift operator, which is written as <<, is often used & greatly admired.
--- Should become:
<p>The left shift operator, which is written as &lt;&lt;, is often used &amp; greatly admired.</p>
>>>

# Preservation of named entities
<<<
The left shift operator, which is written as &lt;&lt;, is often used &amp; greatly admired.
--- Should become:
<p>The left shift operator, which is written as &lt;&lt;, is often used &amp; greatly admired.</p>
>>>

# Preservation of decimal-encoded entities
<<<
The left shift operator, which is written as &#060;&#060;, is often used &#038; greatly admired.
--- Should become:
<p>The left shift operator, which is written as &#060;&#060;, is often used &#038; greatly admired.</p>
>>>

# Preservation of hex-encoded entities
<<<
The left shift operator, which is written as &#x3c;&#x3c;, is often used &#x26; greatly admired.
--- Should become:
<p>The left shift operator, which is written as &#x3c;&#x3c;, is often used &#x26; greatly admired.</p>
>>>

# Inline HTML
<<<
This is a regular paragraph.

<table>
    <tr>
        <td>Foo</td>
    </tr>
</table>

This is another regular paragraph.
--- Should become:
<p>This is a regular paragraph.</p>

<table>
    <tr>
        <td>Foo</td>
    </tr>
</table>

<p>This is another regular paragraph.</p>
>>>

# Span-level HTML
<<<
This is some stuff with a <span class="foo">spanned bit of text</span> in
it. And <del>this *should* be a bit of deleted text</del> which should be
preserved, and part of it emphasized.
--- Should become:
<p>This is some stuff with a <span class="foo">spanned bit of text</span> in
it. And <del>this <em>should</em> be a bit of deleted text</del> which should be
preserved, and part of it emphasized.</p>
>>>



### [Code spans]

# Single backtick
<<<
Making `code` work for you
--- Should become:
<p>Making <code>code</code> work for you</p>
>>>

# Literal backtick with doubling
<<<
Making `` `code` `` work for you
--- Should become:
<p>Making <code>`code`</code> work for you</p>
>>>

# Many repetitions
<<<
Making `````code````` work for you
--- Should become:
<p>Making <code>code</code> work for you</p>
>>>

# Entity escaping
<<<
The left angle-bracket (`&lt;`) can also be written as a decimal-encoded
(`&#060;`) or hex-encoded (`&#x3c;`) entity.
--- Should become:
<p>The left angle-bracket (<code>&amp;lt;</code>) can also be written as a decimal-encoded
(<code>&amp;#060;</code>) or hex-encoded (<code>&amp;#x3c;</code>) entity.</p>
>>>



### [Code blocks]

# Para plus code block (literal tab)
<<<
This is a chunk of code:

	some.code > some.other_code

--- Should become:
<p>This is a chunk of code:</p>

<pre><code>some.code &gt; some.other_code
</code></pre>
>>>

# Para plus code block (tab-width spaces)
<<<
This is a chunk of code:

    some.code > some.other_code

--- Should become:
<p>This is a chunk of code:</p>

<pre><code>some.code &gt; some.other_code
</code></pre>
>>>

# Colon with preceeding space
<<<
A regular paragraph, without a colon. :

    This is a code block.
--- Should become:
<p>A regular paragraph, without a colon.</p>

<pre><code>This is a code block.
</code></pre>
>>>

# Single colon
<<<
:
	
	some.code > some.other_code

--- Should become:
<pre><code>some.code &gt; some.other_code
</code></pre>
>>>


### [Horizontal Rules]

# Hrule 1
<<<
* * *
--- Should become:
<hr/>
>>>

# Hrule 2
<<<
***
--- Should become:
<hr/>
>>>

# Hrule 3
<<<
*****
--- Should become:
<hr/>
>>>

# Hrule 4
<<<
- - -
--- Should become:
<hr/>
>>>

# Hrule 5
<<<
---------------------------------------
--- Should become:
<hr/>
>>>


### [Titles]

# setext-style h1
<<<
Title Text
=
--- Should become:
<h1>Title Text</h1>
>>>

<<<
Title Text
===
--- Should become:
<h1>Title Text</h1>
>>>

<<<
Title Text
==========
--- Should become:
<h1>Title Text</h1>
>>>

# setext-style h2
<<<
Title Text
-
--- Should become:
<h2>Title Text</h2>
>>>

<<<
Title Text
---
--- Should become:
<h2>Title Text</h2>
>>>

<<<
Title Text
----------
--- Should become:
<h2>Title Text</h2>
>>>

# ATX-style h1
<<<
# Title Text
--- Should become:
<h1>Title Text</h1>
>>>

<<<
# Title Text #
--- Should become:
<h1>Title Text</h1>
>>>

<<<
# Title Text ###
--- Should become:
<h1>Title Text</h1>
>>>

<<<
# Title Text #####
--- Should become:
<h1>Title Text</h1>
>>>

# ATX-style h2
<<<
## Title Text
--- Should become:
<h2>Title Text</h2>
>>>

<<<
## Title Text #
--- Should become:
<h2>Title Text</h2>
>>>

<<<
## Title Text ###
--- Should become:
<h2>Title Text</h2>
>>>

<<<
## Title Text #####
--- Should become:
<h2>Title Text</h2>
>>>

# ATX-style h3
<<<
### Title Text
--- Should become:
<h3>Title Text</h3>
>>>

<<<
### Title Text #
--- Should become:
<h3>Title Text</h3>
>>>

<<<
### Title Text ###
--- Should become:
<h3>Title Text</h3>
>>>

<<<
### Title Text #####
--- Should become:
<h3>Title Text</h3>
>>>

# ATX-style h4
<<<
#### Title Text
--- Should become:
<h4>Title Text</h4>
>>>

<<<
#### Title Text #
--- Should become:
<h4>Title Text</h4>
>>>

<<<
#### Title Text ###
--- Should become:
<h4>Title Text</h4>
>>>

<<<
#### Title Text #####
--- Should become:
<h4>Title Text</h4>
>>>

# ATX-style h5
<<<
##### Title Text
--- Should become:
<h5>Title Text</h5>
>>>

<<<
##### Title Text #
--- Should become:
<h5>Title Text</h5>
>>>

<<<
##### Title Text ###
--- Should become:
<h5>Title Text</h5>
>>>

<<<
##### Title Text #####
--- Should become:
<h5>Title Text</h5>
>>>

# ATX-style h6
<<<
###### Title Text
--- Should become:
<h6>Title Text</h6>
>>>

<<<
###### Title Text #
--- Should become:
<h6>Title Text</h6>
>>>

<<<
###### Title Text ###
--- Should become:
<h6>Title Text</h6>
>>>

<<<
###### Title Text #####
--- Should become:
<h6>Title Text</h6>
>>>


### [Blockquotes]

# Regular 1-level blockquotes
<<<
> Email-style angle brackets
> are used for blockquotes.
--- Should become:
<blockquote>
    <p>Email-style angle brackets
    are used for blockquotes.</p>
</blockquote>
>>>

# Doubled blockquotes
<<<
> > And, they can be nested.
--- Should become:
<blockquote>
    <blockquote>
        <p>And, they can be nested.</p>
    </blockquote>
</blockquote>
>>>

# Nested blockquotes
<<<
> Email-style angle brackets
> are used for blockquotes.

> > And, they can be nested.
--- Should become:
<blockquote>
    <p>Email-style angle brackets
    are used for blockquotes.</p>
    
    <blockquote>
        <p>And, they can be nested.</p>
    </blockquote>
</blockquote>
>>>

# Lazy blockquotes
<<<
> This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,
consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.
Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.

> Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse
id sem consectetuer libero luctus adipiscing.
--- Should become:
<blockquote>
    <p>This is a blockquote with two paragraphs. Lorem ipsum dolor sit amet,
    consectetuer adipiscing elit. Aliquam hendrerit mi posuere lectus.
    Vestibulum enim wisi, viverra nec, fringilla in, laoreet vitae, risus.</p>
    
    <p>Donec sit amet nisl. Aliquam semper ipsum sit amet velit. Suspendisse
    id sem consectetuer libero luctus adipiscing.</p>
</blockquote>
>>>


# Blockquotes containing other markdown elements
<<<
> ## This is a header.
> 
> 1.   This is the first list item.
> 2.   This is the second list item.
> 
> Here's some example code:
> 
>     return shell_exec("echo $input | $markdown_script");
--- Should become:
<blockquote>
    <h2>This is a header.</h2>
    
    <ol>
    <li>This is the first list item.</li>
    <li>This is the second list item.</li>
    </ol>
    
    <p>Here's some example code:</p>
    
    <pre><code>return shell_exec("echo $input | $markdown_script");
    </code></pre>
</blockquote>
>>>


### [Images]

# Inline image with title
<<<
![alt text](/path/img.jpg "Title")
--- Should become:
<p><img src="/path/img.jpg" alt="alt text" title="Title"/></p>
>>>

# Reference image
<<<
![alt text][id]

[id]: /url/to/img.jpg "Title"
--- Should become:
<p><img src="/url/to/img.jpg" alt="alt text" title="Title"/></p>
>>>


### [Emphasis]

# Emphasis (<em>) with asterisks
<<<
Use *single splats* for emphasis.
--- Should become:
<p>Use <em>single splats</em> for emphasis.</p>
>>>

# Emphasis (<em>) with underscores
<<<
Use *underscores* for emphasis.
--- Should become:
<p>Use <em>underscores</em> for emphasis.</p>
>>>

# Strong emphasis (<strong>) with asterisks
<<<
Use **double splats** for more emphasis.
--- Should become:
<p>Use <strong>double splats</strong> for more emphasis.</p>
>>>

# Strong emphasis (<strong>) with underscores
<<<
Use __doubled underscores__ for more emphasis.
--- Should become:
<p>Use <strong>doubled underscores</strong> for more emphasis.</p>
>>>

# Combined emphasis types 1
<<<
Use *single splats* or _single unders_ for normal emphasis.
--- Should become:
<p>Use <em>single splats</em> or <em>single unders</em> for normal emphasis.</p>
>>>

# Combined emphasis types 2
<<<
Use _single unders_ for normal emphasis
or __double them__ for strong emphasis.
--- Should become:
<p>Use <em>single unders</em> for normal emphasis
or <strong>double them</strong> for strong emphasis.</p>
>>>

# Emphasis containing escaped metachars
<<<
You can include literal *\*splats\** by escaping them.
--- Should become:
<p>You can include literal <em>*splats*</em> by escaping them.</p>
>>>


### [Links]

# Inline link, no title
<<<
An [example](http://url.com/).
--- Should become:
<p>An <a href="http://url.com/">example</a>.</p>
>>>

# Inline link with title
<<<
An [example](http://url.com/ "Check out url.com!").
--- Should become:
<p>An <a href="http://url.com/" title="Check out url.com!">example</a>.</p>
>>>

# Reference-style link, no title
<<<
An [example][ex] reference-style link.

[ex]: http://www.bluefi.com/
--- Should become:
<p>An <a href="http://www.bluefi.com/">example</a> reference-style link.</p>
>>>

# Reference-style link with quoted title
<<<
An [example][ex] reference-style link.

[ex]: http://www.bluefi.com/ "Check out our air."
--- Should become:
<p>An <a href="http://www.bluefi.com/" title="Check out our air.">example</a> reference-style link.</p>
>>>

# Reference-style link with paren title
<<<
An [example][ex] reference-style link.

[ex]: http://www.bluefi.com/ (Check out our air.)
--- Should become:
<p>An <a href="http://www.bluefi.com/" title="Check out our air.">example</a> reference-style link.</p>
>>>

# Reference-style link with one of each (hehe)
<<<
An [example][ex] reference-style link.

[ex]: http://www.bluefi.com/ "Check out our air.)
--- Should become:
<p>An <a href="http://www.bluefi.com/" title="Check out our air.">example</a> reference-style link.</p>
>>>

" <- For syntax highlighting

# Reference-style link with intervening space
<<<
You can split the [linked part] [ex] from
the reference part with a single space.

[ex]: http://www.treefrog.com/ "for some reason"
--- Should become:
<p>You can split the <a href="http://www.treefrog.com/" title="for some reason">linked part</a> from
the reference part with a single space.</p>
>>>

# Reference-style link with intervening space
<<<
You can split the [linked part]
 [ex] from the reference part
with a newline in case your editor wraps it there, I guess.

[ex]: http://www.treefrog.com/
--- Should become:
<p>You can split the <a href="http://www.treefrog.com/">linked part</a> from the reference part
with a newline in case your editor wraps it there, I guess.</p>
>>>

# Reference-style anchors
<<<
I get 10 times more traffic from [Google] [1] than from
[Yahoo] [2] or [MSN] [3].

  [1]: http://google.com/        "Google"
  [2]: http://search.yahoo.com/  "Yahoo Search"
  [3]: http://search.msn.com/    "MSN Search"
--- Should become:
<p>I get 10 times more traffic from <a href="http://google.com/" title="Google">Google</a> than from
<a href="http://search.yahoo.com/" title="Yahoo Search">Yahoo</a> or <a href="http://search.msn.com/" title="MSN Search">MSN</a>.</p>
>>>

# Implicit name-link shortcut anchors
<<<
I get 10 times more traffic from [Google][] than from
[Yahoo][] or [MSN][].

  [google]: http://google.com/        "Google"
  [yahoo]:  http://search.yahoo.com/  "Yahoo Search"
  [msn]:    http://search.msn.com/    "MSN Search"
--- Should become:
<p>I get 10 times more traffic from <a href="http://google.com/" title="Google">Google</a> than from
<a href="http://search.yahoo.com/" title="Yahoo Search">Yahoo</a> or <a href="http://search.msn.com/" title="MSN Search">MSN</a>.</p>
>>>

# Inline anchors
<<<
I get 10 times more traffic from [Google](http://google.com/ "Google")
than from [Yahoo](http://search.yahoo.com/ "Yahoo Search") or
[MSN](http://search.msn.com/ "MSN Search").
--- Should become:
<p>I get 10 times more traffic from <a href="http://google.com/" title="Google">Google</a>
than from <a href="http://search.yahoo.com/" title="Yahoo Search">Yahoo</a> or
<a href="http://search.msn.com/" title="MSN Search">MSN</a>.</p>
>>>


### [Auto-links]

# Plain HTTP link
<<<
This is a reference to <http://www.FaerieMUD.org/>. You should follow it.
--- Should become:
<p>This is a reference to <a href="http://www.FaerieMUD.org/">http://www.FaerieMUD.org/</a>. You should follow it.</p>
>>>

# FTP link
<<<
Why not download your very own chandelier from <ftp://ftp.usuc.edu/pub/foof/mir/>?
--- Should become:
<p>Why not download your very own chandelier from <a href="ftp://ftp.usuc.edu/pub/foof/mir/">ftp://ftp.usuc.edu/pub/foof/mir/</a>?</p>
>>>


### [Lists]

# Unordered list
<<<
*   Red
*   Green
*   Blue
--- Should become:
<ul>
<li>Red</li>
<li>Green</li>
<li>Blue</li>
</ul>
>>>

# Ordered list
<<<
1.  Bird
2.  McHale
3.  Parish
--- Should become:
<ol>
<li>Bird</li>
<li>McHale</li>
<li>Parish</li>
</ol>
>>>

# Ordered list, any numbers
<<<
1.  Bird
1.  McHale
1.  Parish
--- Should become:
<ol>
<li>Bird</li>
<li>McHale</li>
<li>Parish</li>
</ol>
>>>

# Ordered list, any numbers 2
<<<
3.  Bird
1.  McHale
8.  Parish
--- Should become:
<ol>
<li>Bird</li>
<li>McHale</li>
<li>Parish</li>
</ol>
>>>

# Hanging indents
<<<
*   Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
    Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,
    viverra nec, fringilla in, laoreet vitae, risus.
*   Donec sit amet nisl. Aliquam semper ipsum sit amet velit.
    Suspendisse id sem consectetuer libero luctus adipiscing.
--- Should become:
<ul>
<li>Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,
viverra nec, fringilla in, laoreet vitae, risus.</li>
<li>Donec sit amet nisl. Aliquam semper ipsum sit amet velit.
Suspendisse id sem consectetuer libero luctus adipiscing.</li>
</ul>
>>>

# Lazy indents
<<<
*   Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,
viverra nec, fringilla in, laoreet vitae, risus.
*   Donec sit amet nisl. Aliquam semper ipsum sit amet velit.
Suspendisse id sem consectetuer libero luctus adipiscing.
--- Should become:
<ul>
<li>Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,
viverra nec, fringilla in, laoreet vitae, risus.</li>
<li>Donec sit amet nisl. Aliquam semper ipsum sit amet velit.
Suspendisse id sem consectetuer libero luctus adipiscing.</li>
</ul>
>>>

# Paragraph wrapped list items
<<<
*   Bird

*   Magic
--- Should become:
<ul>
<li><p>Bird</p></li>
<li><p>Magic</p></li>
</ul>
>>>

# Multi-paragraph list items
<<<
1.  This is a list item with two paragraphs. Lorem ipsum dolor
    sit amet, consectetuer adipiscing elit. Aliquam hendrerit
    mi posuere lectus.

    Vestibulum enim wisi, viverra nec, fringilla in, laoreet
    vitae, risus. Donec sit amet nisl. Aliquam semper ipsum
    sit amet velit.

2.  Suspendisse id sem consectetuer libero luctus adipiscing.
--- Should become:
<ol>
<li><p>This is a list item with two paragraphs. Lorem ipsum dolor
sit amet, consectetuer adipiscing elit. Aliquam hendrerit
mi posuere lectus.</p>

<p>Vestibulum enim wisi, viverra nec, fringilla in, laoreet
vitae, risus. Donec sit amet nisl. Aliquam semper ipsum
sit amet velit.</p></li>
<li><p>Suspendisse id sem consectetuer libero luctus adipiscing.</p></li>
</ol>
>>>

# Lazy multi-paragraphs
<<<
*   This is a list item with two paragraphs.

    This is the second paragraph in the list item. You're
only required to indent the first line. Lorem ipsum dolor
sit amet, consectetuer adipiscing elit.

*   Another item in the same list.
--- Should become:
<ul>
<li><p>This is a list item with two paragraphs.</p>

<p>This is the second paragraph in the list item. You're
only required to indent the first line. Lorem ipsum dolor
sit amet, consectetuer adipiscing elit.</p></li>
<li><p>Another item in the same list.</p></li>
</ul>
>>>

# Blockquote in list item
<<<
*   A list item with a blockquote:

    > This is a blockquote
    > inside a list item.
--- Should become:
<ul>
<li><p>A list item with a blockquote:</p>

<blockquote>
    <p>This is a blockquote
    inside a list item.</p>
</blockquote></li>
</ul>
>>>

# Code block in list item
<<<
*   A list item with a code block:

        <code goes here>
--- Should become:
<ul>
<li><p>A list item with a code block:</p>

<pre><code>&lt;code goes here&gt;
</code></pre></li>
</ul>
>>>

# Backslash-escaped number-period-space
<<<
1986\. What a great season.
--- Should become:
<p>1986. What a great season.</p>
>>>

