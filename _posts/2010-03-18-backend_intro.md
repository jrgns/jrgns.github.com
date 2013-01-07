---
layout: post
title: backend: PHP Framework
permalink: /backend_intro/index.html
date: 2010-03-18 08:46:32
categories:
- blog
---

<div class="notice">
<h3>Update: 21/11/2011</h3>
Backend has undergone a major rewrite. Get the latest info <a href="/content/backend-core-a-restful-mvc-php-framework">here</a>, and get the code on <a href="https://github.com/jrgns/backend-core">GitHub</a>
</div>
In the past few years I've been working on a PHP framework / backend. Sometimes out of frustration with copying and pasting code, but usually because I'm to lazy to write a lot of code, so decide to write a little bit of code to do a lot... And then I write some more code, to do a little bit more, and before you know it, it's yet another PHP framework. I tried to get some public input on the <a href="http://launchpad.net/yaphpfter">project</a> once before, but that went nowhere, and I left it there - until of course I had to do some work that required the same type of thing, and now I'm at it again.<!--break-->

What makes backend different from my previous [failed][1] experiment? Well, the fact that this is now the 7th or 8th time that I've rehashed the concept, and that this time, I've actually put some thought and effort into it. No, it's not perfect, and it won't solve the world's problems, but it better and simpler, and hopefully more useful.

One concept that I definitely want to run with in backend, is the concept of backend as a web service, as opposed to a framework or a content / data management system. Backend provides a client, as in a browser or an application, with the requested data, in a format that the client can understand. Be it a human readable web page, JSON, XML or even PHP variables. This struck me as important after reading [this][2] by Ryan Tomayko:

> Wife: A web page is a resource?
>
> Ryan: Kind of. A web page is a
> "representation" of a resource.
> Resources are just concepts.
> URLs—those things that you type into
> the browser…
>
> Wife: I know what a URL is..
>
> Ryan: Oh, right. Those tell the
> browser that there’s a concept
> somewhere. A browser can then go ask
> for a specific representation of the
> concept. Specifically, the browser
> asks for the web page representation
> of the concept.
>
> Wife: What other kinds of
> representations are there?
>
> Ryan: Actually, representations is one
> of these things that doesn’t get used
> a lot. In most cases, a resource has
> only a single representation. But
> we’re hoping that representations will
> be used more in the future because
> there’s a bunch of new formats popping
> up all over the place.
>
> Wife: Like what?
>
> Ryan: Hmm. Well, there’s this concept
> that people are calling "Web
> Services". It means a lot of different
> things to a lot of different people
> but the basic concept is that machines
> could use the web just like people do.

So it's important for me to make it easy for web developers to easily provide data in different formats. Backend can already provide any client with data in 4, yes 4, different formats:

* HTML, or a human readable webpage
* [JSON][3], the new darling of AJAX fans
* [(PHP) Serialized byte stream representations][4]
* [PHP variables][5], as created by var_export

This will hopefully increase backend's usefulness as a web service. And yes, I know, XML is missing, but of those 4, HTML was necessary, although not necessarily easy, and the other three were extremely easy to implement, as they are all products of simple PHP functions. One day when someone uses backend and actually **needs** XML, we can implement it. (Notice that I said *we*, not *I* - I rarely use XML, so I won't know the requirements, so if I do it alone, it will probably be useless).

At the moment backend is on version 0.1.2.1 in my personal repo. All that means is that I've decided I've reached a point where I can actually release the code to the public, and made some improvements, fixes and changes. When will it be marked as version 1.0?

When we have the following:

1. A fully fledged and integrated admin space
2, Easy and intuitive setup / install system
3. Easy and intuitive update system
4. An intuitive plugin system
5. Intuitive and function DB Objects<
6. The ability to easily implement different data formats
7. The ability to use multiple and different data sources (MySQL, SQLite, flat files, etc.)
8. Working and secure user access control
9. Either a REST-full implementation, or a roadmap towards it
10. Something that makes coding easier

That's ten requirements for me to release backend v1.0...

What's already done?

* Semi working DB Objects
* Output of different data formats using views
* Simple templating / caching system
* Simple user access control
* CRUD, actually, just CRU actions. I haven't gotten round to the Deletes yet.


I'm using [jQuery][6] as a JavaScript backend, and [blueprint][7] for my CSS needs. For now it's under the [EPL][8], but I may switch to the MIT license at some point. I'm using MySQL exclusively at this point, but am hoping to add support for other DB's / sources eventually.

I'll be putting the code on [Launchpad][9] soon, so if you want to contribute, or comment, please do!


  [1]: http://www.codinghorror.com/blog/archives/000576.html
  [2]: http://tomayko.com/writings/rest-to-my-wife
  [3]: http://json.org/
  [4]: http://www.php.net/serialize
  [5]: http://www.php.net/var-export
  [6]: http://jquery.com/
  [7]: http://www.blueprintcss.org/
  [8]: http://www.opensource.org/licenses/eclipse-1.0.php
  [9]: http://launchpad.net/backend
