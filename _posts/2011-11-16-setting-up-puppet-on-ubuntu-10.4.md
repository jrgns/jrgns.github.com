---
layout: post
title: Setting up Puppet on Ubuntu 10.4
permalink: setting-up-puppet-on-ubuntu-10.4/index.html
date: 2011-11-16 04:24:06
categories:
- blog
---

I'm trying to use puppet to setup standard dev and (eventually) production environments. As Ubuntu 10.4 is the current LTS release (at least until 12.4), I need to get puppet running on 10.4. The problem is that although the latest stable release for puppet is 2.7.6, puppet in the ubuntu repo is version 0.25.4. Here's how to firstly set it up, and then upgrade it to the latest version.

Setup
-----

First install packages required by Puppet via aptitude

    sudo apt-get update
    sudo apt-get install irb libopenssl-ruby libreadline-ruby rdoc ri ruby ruby-dev

And then install puppet and puppet master, also through aptitude

    sudo apt-get install puppet puppetmaster

You can skip install puppet if your working on the master machine, or skip puppetmaster if your working on a client. *I'll be installing the client and the master on the same machine*.

You can then follow the following steps from [the documentation][1] to get the default setup going. *Run all commands as root*:

    #Generate a default config file
    puppetd --genconfig > etc/puppet/puppet.conf
    #Generate a default site manifest
    puppetd --genmanifest > etc/puppet/manifests/site.pp
    #Add the puppet user and group
    puppetd --mkusers

We also need to tell the client which server it should use as it's master. Add the following line to `/etc/hosts`:

127.0.0.1 puppet

Puppet uses the host name `puppet` as the default master. You can change this by setting the server config value in `/etc/puppet/puppet.conf`

You can then test your client setup by running

    puppetd --test

Cert Issues
-----------

At this point I ran into a stupid config issue, where the client complained bombed out with the following error:

could not retrieve catalog from remote server: hostname was not match with the server certificate

Despite the [bad english and uninformative message][2], I eventually figured out that even though a puppet client by default uses the puppet hostname as its master, the name on the cert that was generated for the hostname isn't puppet, but the current machine's name. This mismatch causes the confusion, so either change the server config value, or regen the cert with hostname puppet. I just changed the config value to my machine's name. This actually negates the need for the added line in `/etc/hosts`.


  [1]: http://docs.puppetlabs.com/references/0.25.4/configuration.html
  [2]: http://projects.puppetlabs.com/issues/7224
