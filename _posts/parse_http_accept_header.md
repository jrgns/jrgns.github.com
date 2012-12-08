---
layout: post
title: Parse Http Accept Header
categories:
- blog
---

I want to generate CSS on the fly for a personal project. I'm doing this by redirect all requests for files that does not exist to index.php, and then, if the request is for a stylesheet, index.php generates it.<!--break-->

To identify a request for a stylesheet, we need to parse the Accept header in the HTTP Request. I've grouped all the functions together in a Parser class.

This function retrieves the header, and then determines the mime type, precedence, and tokens for each type given. It's then sorted according to [RFC 2616][1] specifications.

    <?php
    public static function accept_header($header = false) {
        $toret = null;
        $header = $header ? $header : (array_key_exists('HTTP_ACCEPT', $_SERVER) ? $_SERVER['HTTP_ACCEPT']: false);
        if ($header) {
            $types = explode(',', $header);
            $types = array_map('trim', $types);
            foreach ($types as $one_type) {
                $one_type = explode(';', $one_type);
                $type = array_shift($one_type);
                if ($type) {
                    list($precedence, $tokens) = self::accept_header_options($one_type);
                    list($main_type, $sub_type) = array_map('trim', explode('/', $type));
                    $toret[] = array('main_type' => $main_type, 'sub_type' => $sub_type, 'precedence' => (float)$precedence, 'tokens' => $tokens);
                }
            }
            usort($toret, array('Parser', 'compare_media_ranges'));
        }
        return $toret;
    }
    ?>

This helper function parses the options for each mime type, determining the precedence and tokens. It returns the precidence as a float, and an array of tokens.

    <?php
    public static function accept_header_options($type_options) {
        $precedence = 1;
        $tokens = array();
        if (is_string($type_options)) {
            $type_options = explode(';', $type_options);
        }
        $type_options = array_map('trim', $type_options);
        foreach ($type_options as $option) {
            $option = explode('=', $option);
            $option = array_map('trim', $option);
            if ($option[0] == 'q') {
                $precedence = $option[1];
            } else {
                $tokens[$option[0]] = $option[1];
            }
        }
        $tokens = count ($tokens) ? $tokens : false;
        return array($precedence, $tokens);
    }
    ?>

This function is used to sort the array of mime types we parsed from the header. At the moment it doesn't check any tokens, but this code can easily be added on line 6.
<?php
private static function compare_media_ranges($one, $two) {
    if ($one['main_type'] != '*' && $two['main_type'] != '*') {
        if ($one['sub_type'] != '*' && $two['sub_type'] != '*') {
            if ($one['precedence'] == $two['precedence']) {
                if (count ($one['tokens']) == count ($two['tokens'])) {
                    return 0;
                } else if (count ($one['tokens']) < count ($two['tokens'])) {
                    return 1;
                } else {
                    return -1;
                }
            } else if ($one['precedence'] < $two['precedence']) {
                return 1;
            } else {
                return -1;
            }
        } else if ($one['sub_type'] == '*') {
            return 1;
        } else {
            return -1;
        }
    } else if ($one['main_type'] == '*') {
        return 1;
    } else {
        return -1;
    }
}
?>


  [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
