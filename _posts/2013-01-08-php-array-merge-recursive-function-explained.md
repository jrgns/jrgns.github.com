---
layout: post
title: PHP's array_merge_recursive function explained
categories:
- blog
---

Reading the PHP docs, it's not immediately clear how the `[array_merge_recursive][1]` function behaves.
I've setup a couple of test cases and compared them with the plain `[array_merge][2]` function to explain it further:

The following snippet set's up a couple of arrays, and outputs them for completeness sake.

{% highlight php linenos inline %}
<?php
$cats = array(
    'white' => array('Kitty'),
    'brown' => 'Bach',
    'mixed' => array('Tomcat')
);
$dogs = array(
    'white' => 'Bowser',
    'brown' => 'Rex',
    'mixed' => ('Mutt')
);

var_dump('Cats', $cats, 'Dogs', $dogs);
{% endhighlight %}

<pre><small>string</small> <font color='#cc0000'>'Cats'</font> <i>(length=4)</i>
<b>array</b>
  'white' <font color='#888a85'>=&gt;</font> 
    <b>array</b>
      0 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Kitty'</font> <i>(length=5)</i>
  'brown' <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Bach'</font> <i>(length=4)</i>
  'mixed' <font color='#888a85'>=&gt;</font> 
    <b>array</b>
      0 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Tomcat'</font> <i>(length=6)</i>
<small>string</small> <font color='#cc0000'>'Dogs'</font> <i>(length=4)</i>
<b>array</b>
  'white' <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Bowser'</font> <i>(length=6)</i>
  'brown' <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Rex'</font> <i>(length=3)</i>
  'mixed' <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Mutt'</font> <i>(length=4)</i>
</pre>

This snippet highlights what happens when the arrays being merged have matching keys.

{% highlight php linenos inline %}
<?php
var_dump('Cats and Dogs - plain', array_merge($cats, $dogs));
var_dump('Cats and Dogs - recursive', array_merge_recursive($cats, $dogs));
{% endhighlight %}

All values that's not already in an array will be placed in an array,
and merged with other values with the same keys. Arrays are left as they are and then merged.

<pre>
<b>array</b>
  'white' <font color='#888a85'>=&gt;</font> 
    <b>array</b>
      0 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Kitty'</font> <i>(length=5)</i>
      1 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Bowser'</font> <i>(length=6)</i>
  'brown' <font color='#888a85'>=&gt;</font> 
    <b>array</b>
      0 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Bach'</font> <i>(length=4)</i>
      1 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Rex'</font> <i>(length=3)</i>
  'mixed' <font color='#888a85'>=&gt;</font> 
    <b>array</b>
      0 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Tomcat'</font> <i>(length=6)</i>
      1 <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Mutt'</font> <i>(length=4)</i>
</pre>

Compare this with the normal `array_merge` function, where the values of the latter arrays replace
all the values with the same key.

<pre>
<b>array</b>
  'white' <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Bowser'</font> <i>(length=6)</i>
  'brown' <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Rex'</font> <i>(length=3)</i>
  'mixed' <font color='#888a85'>=&gt;</font> <small>string</small> <font color='#cc0000'>'Mutt'</font> <i>(length=4)</i>
</pre>

Values with numerical keys get added to the original array with a renumbering of keys. This
is the same behaviour as that of `array_merge`.

 [1]: http://php.net/manual/en/function.array-merge-recursive.php
 [2]: http://php.net/manual/en/function.array-merge.php
