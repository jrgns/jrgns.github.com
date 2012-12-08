---
layout: post
title: Getting Started with node.js
permalink: getting_started_with_node_js/index.html
date: 2010-10-11 06:31:40
categories:
- blog
---

Looking for a new challenge, I started a small project in node.js. Here's a few simple tips on how to get going quickly.<!--break-->

It's JavaScipt
--------------

Yeah, that's obvious, but sometimes stating the obvious is necessary. Node.js is essentially server side JavaScript. This means that all your JS knowledge and tutorials and manuals will be usefull once you get stuck.

It's Event Driven
-----------------

Node.js is an event driven framework, which can take some getting used to, but it is very powerful in the long run. You can write straight forward bottom to top code, but then you'll be missing out on the real power of node.js. An example:

    //Get the events module
    var   events = require('events')
        , fs     = require('fs');

    //Create a new event object
    var file_emitter = new events.EventEmitter();

    //Create a listener for our event object
    var newFileListener = file_emitter.on('found', function(file) {
        //Do something to the found file
    }

    //Check for files in a folder
    var files = fs.readdirSync('/some/folder');
    files.forEach(function(file) {
    	//Emit (Trigger) the "found" event on our event object
    	file_emitter.emit('found', dest);
    });

Multiple Files
--------------

Any good coder knows that putting your code in multiple files is a quick win for organized coded. Here's how to do it in node.js:

    //In utils.js
    exports.trim = trim;
    function trim(string) {
    	return string.replace(/^\s*|\s*$/g, '')
    }

    //In the file you want to use the trim function
    var utils = require('./utils')

The `.js` part of the file is automatically added/detected. This is to include a file in the same folder as the calling file, but you can easily just add the correct path traversals to get to other files. The important part in the file being included is setting the function name in the `exports` Object.

File I/O
--------

Files are all treated as streams in node.js. This means that you can start acting on the data in a file before node has even finished reading the file.

    //Open a file as a Readable stream
    stream = fs.ReadStream(file);
    stream.setEncoding('ascii');
    stream.on('data', function(data) {
        //Do something to the file's data mid stream
    });
    stream.on('close', function () {
        //Do something to the file once it's finished reading
    }

Writing to a file is just as simple

    stream = fs.createWriteStream(filename, { 'encoding': 'base64' });
    stream.write(data);
    stream.end();

Want More?
----------

See [parser_email on github][1] for the full source of the examples given.

Some useful sites:

* [Official Site][2] | [Documentation][3] | [Source][4]
* [Understanding node.js][5]
* [How to Node][6]


  [1]: http://github.com/jrgns/parser_email
  [2]: http://nodejs.org/
  [3]: http://nodejs.org/api.html
  [4]: http://github.com/ry/node
  [5]: http://debuggable.com/posts/understanding-node-js:4bd98440-45e4-4a9a-8ef7-0f7ecbdd56cb
  [6]: http://howtonode.org/
