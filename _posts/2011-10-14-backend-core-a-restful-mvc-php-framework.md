---
layout: post
title: Backend-Core: A RESTful MVC PHP Framework
permalink: backend-core-a-restful-mvc-php-framework/index.html
date: 2011-10-14 06:59:32
categories:
- blog
---

I like frameworks. I like working with them, I like writing them. I wrote [Backend-PHP][1], which I'm using personally and at [Branded Internet][2]. Unfortunately it has a number of major flaws: It's not easily unit testable, not really a REST web service, and it doesn't conform to any popular coding standards. So I wrote [Backend-Core][3] as the first step towards addressing these issues.<!--break-->

Minimal
-------

Backend-Core is only intended as a minimal, core system. It doesn't implement any application logic or data source abstraction. I decided to focus on the core functionality and design of a RESTful MVC system, and make sure that it works as it should. Eventually I'll extend it with a seperate code base that will include application and data source logic.

MVC
---

The system is structured into Model, View and Controller components:

* Model - The model contains all the **business** logic for an application. As this is a core system, the models are empty.
* View - The view determines how the results of a query will be displayed.
* Controller - The controller contains the **application** logic. Once again, this is only the core, not an application, so the controller just calls the model.

I found that a number of MVC systems confuse what should go into the Model and what should go into the Controller. I'm aiming for thin Controllers containing application logic, and thick Models containing the business logic.

Unit Testing
------------

Backend-PHP used static global classes quite liberally, without even a thought around dependency injection. This makes unit testing unreliable and a real headache to add to the framework.

Backend-Core, on the other hand, was designed to use [constructor injection][4] across the board, and includes a number of unit tests, supported by PHPUnit. This should increase the overall stability of the system.

RESTful Service
---------------

Something I didn't understand about REST when I initial wrote Backend-PHP, was that every REST URL should refer to a noun, with [the only verbs being GET, POST, PUT and DELETE][5], as specified by the HTTP request. This resulted in it *not* complying with REST standards, as a lot of the URLs contained extra verbs, or didn't refer to nouns directly.

Backend-Core supports the REST / HTTP verbs directly, and uses the same methods as CakePHP to identify which verb to use:

* A `_method` POST variable
* A `X_HTTP_METHOD_OVERRIDE` header sent with the request
* The HTTP request's method

This enables it to be used from a Web browser as well as from a REST compliant client.

Documentation and Coding Standards
----------------------------------

The code complies with the [ZEND coding standard][6], as enforced by [PHP Code Sniffer][7]. It's documented using the [PHPdoc standard][8]. Hopefully this will make it easier for people to contribute to and extend the system.

Feel free to fork, comment and use this.


  [1]: http://backend-php.net
  [2]: http://www.brandedinternet.co.za
  [3]: https://github.com/jrgns/backend-core
  [4]: http://martinfowler.com/articles/injection.html#ConstructorVersusSetterInjection
  [5]: http://stackoverflow.com/questions/2001773/understanding-rest-verbs-error-codes-and-authentication/2022938#2022938
  [6]: http://framework.zend.com/manual/en/coding-standard.html
  [7]: http://pear.php.net/package/PHP_CodeSniffer/redirected
  [8]: http://www.phpdoc.org/
