---
layout: post
title: Redirect All Requests To Index.php Using .htaccess
permalink: redirect_request_to_index
date: 2010-03-18 08:42:15
categories:
- blog
---

In one of my pet projects, I redirect all requests to index.php, which then decides what to do with it:<!--break-->

###Simple Example

This snippet in your .htaccess will ensure that all requests for files and folders that does not exists will be redirected to index.php:

    RewriteEngine on
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule . index.php [L]

This enables the rewrite engine:

    RewriteEngine on

This checks for existing folders (-d) and files (-f):

    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f

And this does the actual redirecting:

    RewriteRule . index.php [L]

###Extended Example

You can extend this to pass the requested path to the index.php file by modifying the `RewriteRule` to the following:

    RewriteRule ^(.*)$ index.php?q=$1 [L,QSA]

* The `^(.*)$` part tells the rewrite module that we want to pass down the whole requested path as one parameter.
* The `QSA` part tells the module to append any query strings to the request.
* The `?q=$1` tells the module how to pass down the parameter. In this case, it's passed down as the `q` parameter.

You can extend this even further by using regular expressions. For example:

    RewriteRule ^([^/]*)(.*)$ index.php?first=$1&second=$2

This will pass down the first part of the path as the `first` parameter, and the rest as the `second`. So the following request

    http://yourhost.com/some/path/somewhere

will result in

    http://yourhost.com/index.php?first=some&second=path/somewhere

This allows for some creative ways to do clean URLs.

###Trouble Shooting

If it's not working, make sure that mod_rewrite is installed on Apache. On a unix system you can just do

    sudo a2enmod rewrite

to achieve that.