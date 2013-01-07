---
layout: post
title: Decorator Pattern Implemented Properly In PHP
permalink: /decorator-pattern-implemented-properly-in-php/index.html
date: 2012-03-17 11:14:56
categories:
- blog
---

While working on [Backend-PHP][1] I needed to do a proper implementation of the [Decorator Pattern][2] in PHP. Just googling PHP decorator pattern will come up with a number of simple solutions, but none of them are usable in a general, robust way that a framework requires. So I extended and tweaked the implementations a bit.<!--break-->

##TL;DR

Most decorator pattern implementations for PHP found on the web is broken. They need some extra functionality to work properly, especially for nested decorators. See the complete solution in the [Backend-PHP code][3]

##The Basics

I'm assuming you know how decorators work. If not, read up on it first! I've implemented a base `Decorator` class to handle the base functionality for Decorators. The simple implementations out there serve as a good base for an initial implementation:

    class Decorator
    {
        protected $object; //The object to decorate

        function __construct( $object)
        {
            $this->object = $object;
        }
    }

This is enough to get you started, but you will need to wrap the original object's properties and methods manually. Let's define a couple of magic functions to do that automatically:

    public function __call($method, $args)
        {
            if (is_callable($this->object, $method) {
                return call_user_func_array(array($this->object, $method), $args);
            }
            throw new Exception(
                'Undefined method - ' . get_class($this->object) . '::' . $method
            );
        }

        public function __get($property)
        {
            if (property_exists($this->object, $property)) {
                return $this->object->$property;
            }
            return null;
        }

        public function __set($property, $value)
        {
            $this->object->$property = $value;
            return $this;
        }

That should give you a working basic implementation.

##More Advanced

That will work as long as you don't nest decorators, ie, decorate an already decorated object:

    $object = new DecoratorOne(new DecoratorTwo(new SomeClass()));

Why? The magic functions will check the decorated object for the properties and methods, but in the case of `DecoratorOne` above, the decorated object will be another decorator, and you won't get the expected behaviour. This happens because `property_exists` doesn't trigger the `__get` (or `__set`) methods. `is_callable` does check for the `__call` function, but that doesn't necessarily produce the expected results, especially if you stack decorators that modify method execution.

We solve this by adding two more functions:

###getOriginalObject

    public function getOriginalObject()
    {
        $object = $this->object;
        while ($object instanceof Decorator) {
            $object = $object->getOriginalObject();
        }
        return $object;
    }

`getOriginalObject` will return the original, undecorated object. This is handy to get the correct class name or access to undecorated methods and properties:

    echo get_class($decoratedClass) //Will give the name of the Decorator

    echo get_class($decoratedClass->getOriginalObject()) //Will give the name of the original object

###isCallable

    public function isCallable($method, $checkSelf = false)
    {
        //Check the original object
        $object = $this->getOriginalObject();
        if (is_callable(array($object, $method))) {
            return $object;
        }
        //Check Decorators
        $object = $checkSelf ? $this : $this->object;
        while ($object instanceof Decorator) {
            if (is_callable(array($object, $method))) {
                return $object;
            }
            $object = $this->object;
        }
        return false;
    }

`isCallable` will check the original object for the specified method, and if not found, it will check the other decorators for the method. The option exists to check itself as well.

##The Result

Now we can modify the magic functions like so:

    public function __call($method, $args)
    {
        if ($object = $this->isCallable($method)) {
            return call_user_func_array(array($object, $method), $args);
        }
        throw new Exception(
            'Undefined method - ' . get_class($this->getOriginalObject()) . '::' . $method
        );
    }

    public function __get($property)
    {
        $object = $this->getOriginalObject();
        if (property_exists($object, $property)) {
            return $object->$property;
        }
        return null;
    }

    public function __set($property, $value)
    {
        $object = $this->getOriginalObject();
        $object->$property = $value;
        return $this;
    }

This will give you a robust Decorator Pattern implementation from which you can then create more Decorators. See the complete implementation in the [Backend-PHP code][3]

  [1]: http://backend-php.net
  [2]: http://en.wikipedia.org/wiki/Decorator_pattern
  [3]: https://github.com/backend/Backend-PHP-Core/blob/master/Decorators/Decorator.php
