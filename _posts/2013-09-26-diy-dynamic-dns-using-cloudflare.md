---
layout: post
title: A DIY Dynamic DNS service using Cloudflare
categories:
- blog
---

DynDNS was always the dynamic IP service of choice, but I could never get it
to work properly, and I was always stuck with their lame domain names as I'm
too cheap to pay for their serivces.

Luckily services of all kinds, including DNS Providers, have caught on to the
fact that people want API's. If there's an API to do DNS updates, I can script
a solution.

Some of my domains run off of [Cloudflare][1] which needs to overwrite your DNS.
And, hey presto, they have an [API][2]. So here it is:

{% highlight bash linenos inline %}
#!/bin/bash
curl https://www.cloudflare.com/api_json.html \
    -d 'a=rec_edit' \
    -d 'tkn=1234512345qweqwe1234512345' \
    -d 'id=12345' \
    -d 'email=jrgns@jrgns.net' \
    -d 'z=jrgns.net' \
    -d 'type=A' \
    -d 'name=home' \
    -d "content=$1" \
    -d 'service_mode=0' \
    -d 'ttl=3600'

{% endhighlight %}

Quick and dirty. This updates a domain (home.jrgns.net) with id 12345 with the
IP address that's passed as the first argument to the script. There's a bunch of
ways to get your external IP, my favourite is `curl http://api.externalip.net/ip`,
but I just run this script as the `postscript` of my ddclient (which updates another
service)

{% highlight text linenos inline %}
# /etc/ddclient.conf

protocol=dyndns2
use=web, web=myip.dnsomatic.com
ssl=yes
server=updates.someservice.com
login=mylogin@gmail.com
password='123456'
daemon=3600
postscript=/home/jrgns/bin/cloudflare_dynamic_dns.sh

{% endhighlight %}

I'm sure the same can be done with outer services such as Route 53? Has anyone
tried something like this?

[1]: https://www.cloudflare.com/
[2]: http://www.cloudflare.com/docs/client-api.html
