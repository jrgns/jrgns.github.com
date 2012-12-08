---
layout: post
title: 22seven.com - Folly, or Genius?
permalink: 22seven-com-folly-or-genius/index.html
date: 2012-01-28 08:37:06
categories:
- blog
---

##Promising Product

Last week Christo Davel, founder of the now defunct [twenty20][1] bank, released an online personal accounting service called **[22seven.com][2]**. It [looked][3] like a great product. Something I was looking for for quite a while: A simple online interface that automatically imports my transaction details, and reports on how much I'm spending on what.

I will never use it, though. Why? The app asks for your online banking login details.<!--break-->

##But...

In case you don't know. This is "not a good thing"(tm). As [tweeted][4] by Micheal Jordaan, CEO of FNB, you're taking a big risk by doing so. Once you've given it to them, it's out there, somewhere. Yes, they [secure][5] the information, but to use it, it needs to become readable at some point. If it can become readable, someone can steal it. From a dishonest employee, to a hacker that found his way on to their servers.

The question is, why did they decide to go the route of asking for a user's banking login details? The banks have been struggling to educate users so that they don't enter the online banking sites from any other place than the bank's site, and that they *don't* give their login credentials to any third party. As far as I know, the South African banks will refund any money you lost because of online fraud, **except** if they can prove that you gave your credentials to someone else. And this service is asking for it, wholesale.

##The Problem

The problem is that this isn't the only company that went this route. Sidpayment, a product from Setcom, gives merchants the ability to do online EFTs. The problem is that it's a Java app that looks over the customer's shoulder while he's doing a once off payment through his internet banking. The opportunity for hacks and attacks abound. I'm sure both these knew the risks and were aware of the potential [backlash][6], but why did they knowingly proceed with it?

There's a simple answer: **They had no choice**. The banks in South Africa are walled gardens, with all of **your** information locked up in it. There's no way to access it, except through their portals: the branch and online banking. Even FNB, who seems to be embracing newer technologies, doesn't have anything that even looks like an API. All they have is an accounting app that looks like it was written by (no offence) accountants. So how are third party applications supposed to access a client's transaction details?

Is there even a need for third parties to access people's transaction information? Of course there is! In a number of other countries you see [innovation][7] in [personal finance][8] because they have access to information. There's a number of services that track your credit card and spending patterns. These services depend on (sometimes read-only) data they get from banks and financial institutions.

##Come on, Banks!

If we are to see innovation and progress in personal accounting in South Africa, the banks need to lead the way by not walling everything off, but by giving accredited and approved third party developers and companies access to API's. Perhaps 22seven.com's play was to force the hand of the big banks, and not as stupid as it seems.


  [1]: http://mg.co.za/article/2005-11-02-online-bank-20twenty-up-for-sale
  [2]: http://22seven.com
  [3]: http://www.itweb.co.za/index.php?option=com_content&view=article&id=50971:22seven-goes-live
  [4]: https://twitter.com/?tw_e=details&tw_i=162563523292041216&tw_p=tweetembed#!/MichaelJordaan/statuses/162563523292041216
  [5]: https://www.22seven.com/security.html
  [6]: http://memeburn.com/2012/01/new-startup-22seven-under-fire-from-banks/
  [7]: http://www.wesabe.com
  [8]: http://mint.com
