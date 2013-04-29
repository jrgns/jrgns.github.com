---
layout: post
title: A PHP Virtual Host
permalink: /php-virtualhost/index.html
date: 2011-09-13 03:18:03
categories:
- blog
---

I hate repetitive work. I love solving a puzzle. So it often happens that I'd spend 2 hours writing a script to solve a repetitive problem, than just taking the 2 minutes to do it manually. Creating apache config files are tedious and boring, so I wrote a PHP script that emulates Virtual Hosting.<!--break-->

You can get the code on [GitHub][1]. A **Warning**: The code is **not** production ready. Use it at your own risk. Here's what it does:

An `.htaccess` file [redirects all requests][2] to the `index.php` file, which sits in `/var/www`. We get the host from the `$_SERVER` variable, and check if a folder for that host exists.

{% highlight php linenos inline %}
<?php
$host   = $_SERVER['HTTP_HOST'];
$folder = getcwd() . '/' . $host . '/';
if (!file_exists($folder)) {
	no_host();
	die;
}
{% endhighlight %}

So if we wanted to server jrgns.net from it, the folder `/var/www/jrgns.net` should exist on the server. If it doesn't, a generic message is displayed.

Courtesy of the `.htaccess` file, the whole URL, except the host name, gets passed to the script in the `f` query variable. As we might be requesting a stylesheet such as jrgns.net/styles/basic.css, the virtual host should pick that up. If no file is requested, check for and serve an index file.

{% highlight php linenos inline %}
<?php
if (empty($_REQUEST['f'])) {
	$indexes = array(
		'index.php', 'index.html', 'index.htm', 'main.php'
	);
	foreach($indexes as $index) {
		if (file_exists($folder . $index)) {
			chdir($folder);
			include($folder . $index);
			die;
		}
	}
} else {
	$file = $_REQUEST['f'];
	if (file_exists($folder . $file)) {
		$info = explode('.', $file);
		switch(end($info)) {
		case 'js':
			header('Content-Type: text/javascript');
			break;
		case 'css':
			header('Content-Type: text/css');
			break;
		}
		readfile($folder . $file);
		die;
	}
}
{% endhighlight %}

I use a very rudimentary way to get the file extension, and then send the content header. There are probably better ways to do this, but it works. The rest is just the generic message that gets displayed if we don't know what you're looking for.

{% highlight php linenos inline %}
<?php
function no_host() {
	global $host;
?><!DOCTYPE html>
<html>
	<head>
		<title>Unknown Domain: <?php echo $host ?></title>
	</head>
	<body>
		<div>
			<h1>Unknown Domain: <?php echo $host ?></h1>
		</div>
	</body>
</html>

<?php
}
no_host();
{% endhighlight %}

Like I said. Simple!


  [1]: https://github.com/jrgns/php-virtualhost
  [2]: ?q=content/redirect_request_to_index
