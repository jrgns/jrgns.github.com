---
layout: post
title: My take on single or multiple returns
permalink: /my_take_on_single_or_multiple_returns/index.html
date: 2010-03-18 16:17:11
categories:
- blog
---

Originally posted on [StackOverflow][1]

I force myself to use only one return statement, as it will in a sense generate code smell. Let me explain:<!--break-->

    <?php
    function isCorrect($param1, $param2, $param3) {
        $toret = false;
        if ($param1 != $param2) {
            if ($param1 == ($param3 * 2)) {
                if ($param2 == ($param3 / 3)) {
                    $toret = true;
                } else {
                    $error = 'Error 3';
                }
            } else {
                $error = 'Error 2';
            }
        } else {
            $error = 'Error 1';
        }
        return $toret;
    }
    ?>

*(The conditions are arbritary...)*

The more conditions, the larger the function gets, the more difficult it is to read. So if you're attuned to the code smell, you'll realise it, and want to refactor the code. Two possible solutions are:

* Multiple returns
* Refactoring into separate functions

**Multiple Returns**

    <?php
    function isCorrect($param1, $param2, $param3) {
        if ($param1 == $param2)       { $error = 'Error 1'; return false; }
        if ($param1 != ($param3 * 2)) { $error = 'Error 2'; return false; }
        if ($param2 != ($param3 / 3)) { $error = 'Error 3'; return false; }
        return true;
    }
    ?>

**Separate Functions**

    <?php
    function isEqual($param1, $param2) {
        return $param1 == $param2;
    }

    function isDouble($param1, $param2) {
        return $param1 == ($param2 * 2);
    }

    function isThird($param1, $param2) {
        return $param1 == ($param2 / 3);
    }

    function isCorrect($param1, $param2, $param3) {
        $toret = false;
        if (!isEqual($param1, $param2)
            && isDouble($param1, $param3)
            && isThird($param2, $param3)
        ) {
            $toret = true;
        }
        return $toret;
    }
    ?>

Granted, it is longer and a bit messy, but in the process of refactoring the function this way, we've

* created a number of reusable functions,
* made the function more human readable, and
* the focus of the functions is on why the values are correct.


  [1]: http://stackoverflow.com/questions/36707/should-a-function-have-only-one-return-statement/1276951#1276951



