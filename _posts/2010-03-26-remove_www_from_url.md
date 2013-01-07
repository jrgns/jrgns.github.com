---
layout: post
title: How to remove the www from your URL
permalink: /remove_www_from_url/index.html
date: 2010-03-26 08:03:29
categories:
- blog
---

If you like simplicity, you might like to simplify your website's URL. You can do this by adding the following in your `.htaccess` file, or in the `VirtualHost` declaration on your Apache setup.

    RewriteEngine on
    RewriteCond %{HTTP_HOST} ^www.mysite.co.za$ [NC]
    RewriteRule ^(.*)$ http://mysite.co.za/$1 [L,R=301]

The rewrite module for apache needs to be installed for this to work.

Remember that you can tell Google to list all links to your site with / without the www by setting that in the [Webmaster Tools][1].


  [1]: http://www.google.com/webmasters/tools/
