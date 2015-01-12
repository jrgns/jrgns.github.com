---
layout: post
excerpt_separator: ---more---
title: "The Logstash Config Guide"
categories:
- blog
---

The ELK stack has been becoming more and more popular, specifically [Elasticsearch][1]. The [search volume][2] for it has been growing constantly since 2010. It's faithful sidekick, [Logstash][3], has been growing along with it, and ever since I've started looking at it, I'm just loving it more and more.

The fact that you can string together totally disparate systems, from XMPP to Redmine and files on S3 to Nagios, with a simple config makes it a wonderful plaything and very useful utility. The rub, though, is in the config: Even though a great effort is made to write proper docs, I've found the documentation to be unclear, incomplete and sometimes confusing. So I've decided to do something about it:

[The Logstash Config Guide][4]

---more---

The plan is to write focused guides on some of the more popular Logstash plugins in the hopes of making it easier for people to set up and configure them. Each chapter will point out the bare minimum required to get you up and running and also highlight some of the more interesting, but not necessarily necessary settings for a plugin. You'll also find a complete reference of all the available settings, with working examples for each of them.

It's still early days, but I'll be publishing a number of preliminary posts on [EagerELK][5] to get things going. Subscribe there, or just buy the book on [Leanpub][4], to stay up to date.

The book will be focusing on version 1.4.2 of Logstash (since 1.5 is still in beta), but I'll update it once 1.5 is stable and being adopted. If you sign up for the 1.4.2 version, you'll receive a free upgrade to the 1.5 version. Two books for the price of one!

Any questions or comments are welcome, let me know below!

[1]: http://www.elasticsearch.org/
[2]: http://www.google.com/trends/explore#q=elasticsearch
[3]: http://logstash.net/
[4]: https://leanpub.com/logstashconfigguide
