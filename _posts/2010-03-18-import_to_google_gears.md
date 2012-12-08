---
layout: post
title: Importing a file into a Google Gears DB using PHP
permalink: import_to_google_gears/index.html
date: 2010-03-18 08:45:19
categories:
- blog
---

I'm playing around with [Google Gears][1], particularly the database part, just to see what it's usefull for, and if I can use it in an app I'm working on. At some point I realised that I will need to import data at some point. Here's how I did it:<!--break-->

By using an HTML uploading form, and PHP to process the upload, you can create a JSON object which can be used to import data into whatever Gears DB you have. Use whatever you use to put all of the data into one array. The source can be a DB or a file upload, come to think of it. Convert the data to JSON using json_encode, and assign it to a JavaScript variable:

<code>var data = <?php echo json_encode($data) ?>;</code>

After that, check that the table exists, loop through the data, and insert!

The complete code below:

The test data to import:

<pre>
"one two",2,1
"three four",3.4,2
</pre>

And the test page, HTML and PHP together:

    <?php
    $data = false;
    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    	$data = array();
    	if (!empty($_FILES['to_import']['tmp_name']) && is_readable($_FILES['to_import']['tmp_name'])) {
    		$fp = fopen($_FILES['to_import']['tmp_name'], 'r');
    		while (($row = fgetcsv($fp)) !== false) {
    			$data[] = $row;
    		}
    		fclose($fp);
    	}
    	$data;
    }
    ?>
    <html>
    	<head>
    		<title>JSON / Gears import Test</title>
    	</head>
    	<body onload="do_import()">
    		<form method="post" action="" enctype="multipart/form-data">
    			<input type="file" name="to_import">
    			<input type="submit">
    		</form>
    		<script src='gears_init.js'></script>
    		<script>
    var data = <?php echo json_encode() ?>;
    
    function do_import() {
    	var db = google.gears.factory.create('beta.database');
    	db.open('database-test');
    	db.execute('CREATE TABLE IF NOT EXISTS Import' +
    				' (Phrase text, Amount float, Something int)');
    	if (data) {
    		for (var i = 0; i < data.length; i++) {
    			db.execute('INSERT INTO Import Values(?, ?, ?)', data[i]);
    		}
    		
    		rs = db.execute('SELECT * FROM Import');
    		while(rs.isValidRow()) {
    			alert(rs.field(0) + ' - ' + rs.field(1) + ' - ' + rs.field(2));
    			rs.next();
    		}
    		rs.close();
    	}
    }
    		</script>
    	</body>
    </html>


  [1]: http://code.google.com/apis/gears/

