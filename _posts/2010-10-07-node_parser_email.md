---
layout: post
title: Email Parser for node.js
permalink: /node_parser_email/index.html
date: 2010-10-07 09:53:55
categories:
- blog
---

I need to parse Emails in node.js and after looking around on the web, I didn't find much. Oh, no, I'll have to write it myself... :)

The source is hosted on [GitHub][1] .<!--break-->

Here's an example:

    var   fs        = require('fs')
        , sys       = require('sys')
        , em_parse  = require('./parser_email')

    stream = fs.ReadStream(file);
    stream.setEncoding('ascii');
    stream.on('data', function(data) {
    	mail += data;
    });
    stream.on('close', function () {
    	parser = em_parse.parser_email();
    	parser.setContent(mail);
    	parser.parseMail();
    });


  [1]: http://github.com/jrgns/parser_email
