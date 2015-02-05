---
layout: post
title: "Everything's Connected: Hacking the interwebs with Logstash"
categories:
- blog
---

These are just notes for a RubyFuza2015 ligthening talk. I'll expand it later.

## What is Logstash

* Event processing
* Ruby running on the JRuby engine
* PubSub on Steroids
* Inputs
* Filters
* Outputs

## What is it used for

* Log processing
* From files
* Parse it for relevant data, make it structured
* To Elasticsearch
* Key component in making measurable data available through the ELK stack

## What can it be used for

* IFTTT
* Zapier
* Stamplay
* Logstash

## Why is this significant

* Make anything searchable / storable
    - Email in ELS / Redis
* Connect Anything
    - SNS with XMPP / RabbitMQ
    - IMAP with S3
    - Websocket -> Process / Filter -> Websocket
