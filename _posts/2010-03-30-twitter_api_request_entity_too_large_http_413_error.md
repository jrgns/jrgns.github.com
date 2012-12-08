---
layout: post
title: Twitter API Request Entity too large / HTTP 413 error
permalink: twitter_api_request_entity_too_large_http_413_error/index.html
date: 2010-03-30 07:12:09
categories:
- blog
---

I've setup [zacoders.net][1] that it will automatically tweet new RFC's. A while back this functionality stopped working. Today I investigated a bit further, and here's what I found.<!--break-->

When posting an update, the Twitter API responded with a 413 HTTP error code, and the following text:

    Request Entity Too Large
    
    The requested resource
    
    /1/statuses/update.json
    
    does not allow request data with POST requests,
    or the amount of data provided in the request
    exceeds the capacity limit.

I realized that the [backend][2]'s OAuth utility sent through POST requests with the parameters included in the URI, just like a GET request:

   POST HTTP/1.1 http://api.twitter.com/1/statuses/update.json?parameters=here

What baffled me is that I only got this error when running it on my live server, not on my testing local server. I suspect it might be a difference in the Curl libraries, but I'm not sure.

To fix it, I just updated the code to only add the parameters to the URI when it was a GET, and to POST the data when it was a POST, and voila, it's working again.


  [1]: http://zacoders.net
  [2]: http://backend-php.net
