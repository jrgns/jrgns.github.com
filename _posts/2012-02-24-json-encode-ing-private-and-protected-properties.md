---
layout: post
title: json-encode'ing Private and Protected Properties
permalink: /json-encode-ing-private-and-protected-properties/index.html
date: 2012-02-24 06:51:15
categories:
- blog
---


When you `json_encode` an object, it will ignore all protected and private properties if the `json_encode` isn't called from within the object. Sometimes you want to output the protected and private properties of an object when you're JSON encoding it. Here's how to do it in an easy and elegant way:<!--break-->

##The Problem

The properties of an object `json_encode` includes in it's eventual output depends on the scope of the function call: If it's from inside the object, it will include **all** the properties, private and protected. If it's from outside of the object, it will only include the public properties.

{% highlight php linenos inline %}
<?php
class Tester
{
    public $public       = 'Public';
    protected $protected = 'Protected';
    private $private     = 'Private';
    function foo()
    {
        echo json_encode($this);
    }
}
$test = new Tester();
$test->foo(); //Outputs {"public":"Public","protected":"Protected","private":"Private"}
echo json_encode($test); //Outputs {"public":"Public"}
{% endhighlight %}

This isn't necessarily the desired outcome. Sometimes you want more control over what is being included in the encoding function.

##The Solution

The easiest way to solve this is to add a `_toJson` function to your object, and call that instead of `json_encode`:

{% highlight php linenos inline %}
<?php
public function _toJson()
{
    $properties = $this->getProperties();
    $object     = new StdClass();
    $object->_class      = get_class($this);
    foreach ($properties as $name => $value) {
        $object->$name = $value;
    }
    return json_encode($object);
}
{% endhighlight %}

The `getProperties` function should return the properties you want to include in the encoding. At it's simplest it can be

{% highlight php linenos inline %}
<?php
    public function getProperties()
    {
        return get_object_vars($this);
    }
{% endhighlight %}

Then, to call it, just check if the function exists, otherwise just call json_encode:

{% highlight php linenos inline %}
<?php
    echo method_exists($object, '_toJson') ? $object->_toJson() : json_encode($object);
{% endhighlight %}

It's relatively simple to do it as a Decorator as well, which will enable you to give this functionality to multiple classes without the need to duplicate the code. See how I did it in the [Backend-PHP][1] framework.

Do you have a better way to do it? Say so in the comments.

[1]: https://github.com/backend/Backend-PHP
