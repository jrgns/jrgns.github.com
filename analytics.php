<?php
$fp = fopen('php://input', 'r');
$input = stream_get_contents($fp);

$message = json_decode($input);

$message->ip = array_key_exists('REMOTE_ADDR', $_SERVER) ? $_SERVER['REMOTE_ADDR'] : 'Unkown';
$message->browser = array_key_exists('HTTP_USER_AGENT', $_SERVER) ? $_SERVER['HTTP_USER_AGENT'] : 'Unkown';

$message = json_encode($message);

$socket = fsockopen('search.stelsels.net', '8080');
if ($socket) {
	$bytes = fwrite($socket, $message . PHP_EOL);
	fflush($socket);
	die('Logged ' . $message . ' (' . $bytes . ')');
} else {
	header(400, 'Could not log');
	die('Could not log ' . $message);
}
