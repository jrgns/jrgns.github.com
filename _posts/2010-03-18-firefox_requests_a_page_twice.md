---
layout: post
title: Firefox requests a page twice?
permalink: /firefox_requests_a_page_twice/index.html
date: 2010-03-18 16:13:43
categories:
- blog
---

I'm busy creating a site for a client who wants to know when certain internal links get clicked. Not a problem, I just insert a record into a table every time the links they want to know about get accesesd. Only problem is, when I check the table, I notice that every page impression gets logged twice.<!--break-->

Now, this happened before, where I also needed to implement some page tracking, and it ended up being an image or something with src="", and Firefox interpreting it as the same location as the current page (as with form with action=""). Don't know if that is according to standards, either way, it messes up my page tracking.

The simple solution is to find any images or HTML elements with source attributes that are empty. Only problem is I couldn't find any this time. So, by taking out chunks of code, I eventually tracked it to srcover attributes in some of the images. Just as a side note, I don't use srcover, the designers use them, and unfortunately I must make do with what the designers give me.

So why does Firefox (I didn't test on other browser) do this on srcover? Firebug shows that the images specified in srcover are downloaded, and the mouseovers work, so it's not that the images are missing or anything.

I'll investigate when I have some time, and report back...

**Update:**

I found this page at [Experts Exchange][1], but hey, they want me to pay to see it. No chance of that happening. If anyone is a member, and you don't want money to share some wisdom, please do!

**Update number two:**

I fount [this page][2] which only talks about the empty src tag, but it also quotes the HTML spec that says that empty src tags refer to the same page their in. So why does srcover still re-request my page?

**Update number final:**

Ok, so it wasn't Firefox's fault, but the javascript that did the rollover images. When it preloades, it doesn't check for empty src attributes, it just loads them. As it checks for both srcover and srcdown, which aren't necessarily specified, it gets quite a lot of empty tags. I guess that Firefox uses a cached page for the rest of the requests.

The javascript library is called imagerollover.js by Adam Smith. I couldn't find a working website, so I don't know if I have the latest version, but I'll upload my modified version...


  [1]: http://www.experts-exchange.com/Web_Development/Web_Languages-Standards/PHP/PHP_Databases/Q_23101341.html
  [2]: http://forums.mozillazine.org/viewtopic.php?p=3022038
