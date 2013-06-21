---
layout: post
title: Backend 100 Revisions
permalink: /backend_100_revisions/index.html
date: 2010-03-18 16:20:29
categories:
- blog
---

I've been working on [backend][1], a PHP framework the last couple of months, and it's really starting to take shape. I've learned a lot about what one can do by coding smarter and the advantages open source code gives on.<!--break-->

After getting somewhat disheartened a few weeks back, I decided to take a look at how [CodeIgnitir][2] does things, and wow, it blew my mind. After spending some time with their code base, I had so many ideas I wanted to implement in backend and my thoughts around it was instantly rejuvinated. Problems that stopped me from progressing had new solutions, and the momentum I gathered from that helped to solve some problems that didn't have any solutions directly at hand.

So, backend just hit it's 100th revision, somewhat arbitrarily, as I reset the branch at some point, and don't always follow the exact same commit methodology, but hey, it looks like a milestone, I'll treat it as one.

**What has changed?**

URL mapping has improved a lot (thanks to CodeIgnitir). `?q=controller/action/param1/param2` now maps to `Controller::action(param1, param2)` without much effort. This has also helped to work towards being a RESTful API.

The installation process is now very smooth and stable. The setting up of data sources need some work, but once that is done, getting the application up and running and fine tuning it is a breeze.

The beginning of a Links structure with named link lists can be managed. The primary use will be for primary and secondary links for a website.

I've managed to implement tags for content, as well as RSS feeds for content as a whole, or content in a tag. The ease with which I could do it really gives me hope that backend will make my coding life easier!

All around polish and stability. Especially around the HTML templating  and rendering engine.

**Where to from here?**

The permissions / security infrastructure still needs some work. I've managed to automatically install most of the default permissions, but there's no useful management interface yet.

I want to start using backend on my personal site (this one) and on another site I've got in the works, called [zacoders.net][3]. More on that later.


[1]: http://backend-php.net
[2]: http://codeigniter.com/
[3]: http://zacoders.net
