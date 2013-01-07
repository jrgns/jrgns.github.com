---
layout: post
title: Why Johnny Died (or, How I Finally Realised Why Singletons And Global Variables Are Bad)
permalink: /why-johnny-died-or-how-i-finally-realised-why-singletons-and-global-variables-are-bad/index.html
date: 2011-09-28 04:06:19
categories:
- blog
---

Johnny (an asthma sufferer and fictitious character) died yesterday. He got an asthma attack, but he could not find his inhaler, and sadly passed away. Usually his mother kept it for him and made sure he used it, but on the first day he ventured out alone, he got an asthma attack, realised that he didn't have his inhaler with him, and died. What does this have to do with Singletons or Global variables? Read on...<!--break-->

I've been struggling to get my head around why singletons and global variables are bad. Particularly in the context of unit testing. I'm [quite a fan](http://stackoverflow.com/questions/228590/what-is-the-best-method-for-getting-a-database-connection-object-into-a-function/228715#228715)
of a global static class that can manage certain resources for you. But if you just look around a bit, you'll find a [few][1] [resources][2] around the fact that they are a bad idea.

I read up quite a bit on why exactly globals and singletons are bad, but couldn't find any convincing explanations. Until yesterday, when I read this [question](http://stackoverflow.com/questions/1020312/are-singletons-really-that-bad) and [answer](http://stackoverflow.com/questions/1020312/are-singletons-really-that-bad/1020384#1020384) on stackoverflow. Particularly

> every class can potentially depend on
> a singleton, which means the class can
> not be reused in other projects unless
> we also reuse all our singletons

In other words, if you want your classes / objects to be modular and easily transportable and reusable in other code bases, you **cannot** use global variables or singletons. To properly unit test, you need to use your class in a clean environment, with only it's stated dependencies injected into it on creation. Otherwise there's no guarantee that your tests will fail or succeed consistently. Doing this also promotes code reuse, as you know that the global state won't be affected in some averse way.

What does this have to do with Johnny? Look at him as an object of the class Human, who has a dependency on an Inhaler object. His mother is a global variable or class that supplies him with the Inhaler when he needs it. All fine and dandy if Johnny operates within the context of his mother's home. Take him out of that context, and he dies when he needs the inhaler. Rather give him the inhaler, and let him keep it in his pocket. Dependency injected!


  [1]: http://www.webapper.com/blog/index.php/2008/01/23/evils-of-global-variables-when-unit-testing/
  [2]: http://sebastian-bergmann.de/archives/882-Testing-Code-That-Uses-Singletons.html
