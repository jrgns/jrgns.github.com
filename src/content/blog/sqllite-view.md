---
title: "SQLite Viewer"
date: 2010-03-18
description: "I'm playing around with [Google Gears](https://developers."
---

I'm playing around with [Google Gears](https://developers.google.com/gears/), doing data imports, and generally playing around. I'm quite visiually oriented, so I need to SEE that the data has been added to a table. For my conventional PHP / MySQL apps, I usually use phpMyAdmin or the MySQL query browser, but for Gears developmen, which uses SQLite, I needed to use something else.

I wrote a small JavaScript / Gears app which enables you to view the contents of a SQLite database. All you need to use it, is to download the file, and unzip it into the folder where your web app sits. And no, you won't be able to use it for a remote DB. You need at least FTP access to the website you want to look at, and it will only show you your local data.

You will also need to know the name of the database. At the moment I can see no simple way to supply the user with a listing of DB's, so the app prompts the user for the DB name.

The app currently links to the scripts and styles on my host, which is fine for light use. If you plan to use this app extensively, please start hosting the files on your own host and update the HTML!

[1]: http://developers.google.com/gears/
