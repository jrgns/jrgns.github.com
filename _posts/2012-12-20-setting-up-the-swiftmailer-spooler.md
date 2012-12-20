---
layout: post
title: Setting up the Swiftmailer Spooler
categories:
- blog
---

The [Swiftmailer][1] library comes with a nifty feature where mails can be spooled to disk
and sent later asynchronously instead of mailing them immediately. This results in quicker
response times from your scripts, and by extension happier users. This post will explain
how to set it up *outside* of the Symfony 2 framework.

Spooling the Mail
-----------------

Swiftmailer defines a number of Transports with which mails can be sent. A common one
is the `Swift_SmtpTransport`. To spool mails, we'll use the `Swift_SpoolTransport` for
the initial sending, and then still use `Swift_SmtpTransport` for the background sending.
The following comes (with some changes) from a post in the [Swiftmailer Google Group][2]:

{% highlight php linenos inline %}

    // Setup the spooler, passing it the name of the folder to spool to
    $spool = new Swift_FileSpool(__DIR__ . "/spool");
    // Setup the transport and mailer
    $transport = Swift_SpoolTransport::newInstance($spool);
    $mailer = Swift_Mailer::newInstance($transport);

    // Create a message
    $message = Swift_Message::newInstance('Excellent Subject')
        ->setFrom(array('sende...@domain.com' => 'John Doe'))
        ->setTo(array('your_emailAddress@domain.com'))
        ->setBody('spool messages !!!');

     // Send the message
    $result = $mailer->send($message);

    echo "SPOOLED $result emails";

{% endhighlight %}

This will spool the email to specified folder instead of sending it. At this stage,
the actual sending of the mail hasn't happened yet. You will need to flush the spooled
messages using a cron or background script that calls the flashQueue method to do that.

Sending the Mail
----------------

The background script will use the `Swift_SmtpTransport` to send the spooled mails:

{% highlight php linenos inline %}

    <?php
    //create an instance of the spool object pointing to the right position in the filesystem
    $spool = new Swift_FileSpool(__DIR__."/spool");

    //create a new instance of Swift_SpoolTransport that accept an argument as Swift_FileSpool
    $transport = Swift_SpoolTransport::newInstance($spool);

    //now create an instance of the transport you usually use with swiftmailer
    //to send real-time email
    $realTransport = Swift_SmtpTransport::newInstance(
        "smtp.gmail.com",
        "465",
        "ssl"
    )
        ->setUsername("username")
        ->setPassword("password");

    $spool = $transport->getSpool();
    $spool->setMessageLimit(10);
    $spool->setTimeLimit(100);
    $sent = $spool->flushQueue($transport2);

    echo "SENT $result emails";

{% endhighlight %}

And that's it. All that's left now is to call the background script periodically using
something like cron.

  [1]: http://swiftmailer.org/
  [2]: https://groups.google.com/forum/?fromgroups=#!searchin/swiftmailer/spool/swiftmailer/xQPP5qtNnMA/k3QXcRebG-wJ