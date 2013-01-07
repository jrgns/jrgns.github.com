---
layout: post
title: Why Object Orientation is Great
permalink: /why_oo_is_great/index.html
date: 2011-02-08 07:00:21
categories:
- blog
---

I'm working on some statistics surrounding [BI's][1] API Documentation coverage: Just how much user documentation have we written?

When I started out, the number was abysmally low: 11% of the 1300 functions. Not good. But I didn't feel too bad when I realized that because it's written as an Object Orientated system, I can very quickly improve the coverage.<!--break-->

As I went through the undocumented functions, it became clear that a lot of them are defined in some of our base classes. So, by documenting them in the base classes, I will immediately improve the documentation coverage for a whole bunch of classes. I tried it with one function, and lo and behold, the percentage jumped with 6 points!

So, what do we learn from this? Object orientation is powerful when you implement changes deep down in the object stack, as it propagates through the whole stack. It also reduces the work load (most of the time) as there's no need to repeat yourself.

The downside to consider is that the documentation written is very general (as it should be in a base class), and will probably be overwritten in some of the sub classes.

But that's Object Orientation: Solve 80% of the problem with 20% of the code, and the other 20% of the problem with the other 80% of the code!

  [1]: http://www.brandedinternet.co.za
