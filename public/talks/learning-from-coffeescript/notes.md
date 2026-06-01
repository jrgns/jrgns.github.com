# How CoffeeScript Improved My JavaScript Skills

## Intro

* I write JavaScript for fun. I've played around with Node and JQuery and MooTools and just plain ol' vanilla JavaScript, but I can't call myself a professional JavaScript Coder.
* While working with [Dashing](https://github.com/shopify/dashing) I realised that I haven't worked with CoffeeScript yet. Challenge Accepted!
* I took an existing module I wrote in JavaScript, and rewrote it in CoffeeScript
* It might be comparing apples to oranges, as I didn't set out from the beginning to make this a JS vs CS project. Either way I'll try to be fair. Feel free to call me out if you think I'm missing something or if I'm being prejudiced.
* CoffeeScript Coders? Because you want to or have to?

## What I Learnt

Or, a quick lesson in how *NOT* to code in JS

## I Suck at JavaScript Prototypes

* When you're not doing a lot of JavaScript coding it's easy to forget that JavaScript isn't a "normal" OO language - It's approach to OO is prototypical
* When you have a flat object hierarchy, it's very easy to write code like this, and not realise that it's not actually "correct":
* You can use that as an object, and even create it with `new`:
* But any inheritance will be borked as the properties and methods aren't added to the prototype.

## CoffeeScript generated JS

* The prototype is used properly, and you can then easily extend this object into something more specific.

## Build Processes are Awesome

* Plain JS doesn't need a build process...
* Flat file with all my classes, utilities - It's a mess
* But why deny yourself an awesome tool?
* CoffeeScript requires at least one build step
* So once the work of setting it up is done, get some more goodies

* I had one flat file with all my classes, utilities and methods in it. It's a mess. Instead of making the time to understand utilities such as Grunt and Gulp I just mucked on.
* CoffeeScript requires at least one build step: compilation. Since I had to do compilation, I started looking into other build tasks allowing me to use multiple files, and voila, my project was better organized.

## Source maps? Source maps!

### Without Source Maps

* The code is unrecognizable
* Is it your fault or the compilers?
* Are the changes I'm making fixing or breaking things?

### With Sourcemaps!

* Recognizable code
* Direct link between what's happening in the browser and your CoffeeScript
* Supported in Chrome and Firefox, FireBUG support is coming

## A few meta-functions go a long way

## Simpler is Better? The Tradeoff

### CoffeeScript...

* Hides a lot of boilerplate
* Less code (read information) to take in
* Easier to look past the code and at the abstraction

### But?

* Do you want the extra complexity?
* and the extra boilerplate?
* what about it being only a subset of JS?
