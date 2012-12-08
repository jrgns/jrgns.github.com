---
layout: post
title: The Low Hanging Fruit Of Testing
permalink: the-low-hanging-fruit-of-testing/index.html
date: 2012-03-16 15:14:03
categories:
- blog
---

I've been getting more into Testing (specifically Unit Testing) the past few weeks, and although I'm still struggling to firstly get it right, and secondly see the long term benefits, I know that the quality of my code is already better. Let's call it the low hanging fruit of Testing.

I find that I'm reordering and sometimes rewriting functions, and sometimes whole classes, because just the need to test it already shows some design flaws. A class with too many private methods, a function with no clear input / output, all of that shows up when you start to write tests.

The fact that I have to think of my code and classes in terms of an API requires that I make sure of what the purpose of a function is, and what it's signature and return should look like. Because it's difficult to test large, complex functions, I'm refactoring those into smaller, more modular functions.

So I'm spending more time with the code, making improvements as I read and think about the code. So yeah, I'm not utilizing the full power of testing yet (not to speak of Test Driven Development), but I'm already enjoying the fruits.
