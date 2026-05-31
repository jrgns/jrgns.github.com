---
title: "A JavaScript trim function"
date: 2011-07-18

---

A simple enough `trim` function for JavaScript:

    function trim(string) {
        return string.replace(/^\s*|\s*$/g, '')
    }

The regular expression translates as

* `^` - At the beginning of the line
* `\s*` - Take all the white space you can find, if there is any
* `|` - OR
* `\s*` - Take all the white space you can find, if there is any
* `$` - At the end of the line

The `g` parameter at the end ensures that all instances are replaced.

The replace function uses the regular expressions to replace the white space it found at the beginning or the end of the string with an empty string.

Easy enough!
