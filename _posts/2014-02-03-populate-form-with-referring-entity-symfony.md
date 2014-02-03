---
layout: post
title: "Populate a Symfony 2 Form with the referring entity"
categories:
- blog
---

In any web project it often happens that you have an entity, say a Group, to which you want to add a linked entity, say a Student. So you'll have a "Add a Student" link on the page displaying the Group. When your users click through, there's probably a dropdown with the different groups, and your users expect the Group they're coming from to be prepopulated.

There's various ways to do this, but I'd like to show you a simple, non intrusive one for Symfony 2. You don't have to add any parameters to the link, it just works. In your `Student` Controller, the `newAction` method:

{% highlight php linenos inline %}
<?php
// src/My/Bundle/Controller/StudentController.php
    public function newAction()
    {
        $entity = new Student();
        $form   = $this->createForm(new StudentType(), $entity);

        // Get the refering URL Path
        $ref = str_replace("app_dev.php/", "", parse_url($request->headers->get('referer'),PHP_URL_PATH ));
        // Get the matching route
        $route = $this->container->get('router')->match($ref);
        if (empty($route['_route']) === false && $route['_route'] === 'group_show') {
            // Find the referring group
            if ($group = $this->get('doctrine')->getRepository('MyBundle:Group')->findOneById($route['id'])) {
                $form->get('group')->setData($group);
            }
        }

        return $this->render('MyBundle:Student:new.html.twig', array(
            'entity' => $entity,
            'form'   => $form->createView(),
        ));
    }
?>
{% endhighlight %}

We basically try and match the referring URL to a route, and if found, retrieve that entity, and set it in the form. Simple!
