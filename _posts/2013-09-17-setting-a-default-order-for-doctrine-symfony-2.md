---
layout: post
title: Setting a default order for Doctrine 2 / Symfony 2
categories:
- blog
---

Usually when you're working with data you expect some kind of default ordering.
It might be the primary key, or, more commonly, the data set will be ordered by
a timestamp field or the data's most important property. In Doctrine you can create
[custom repository classes][2] to tweak queries to your liking:

{% highlight php linenos inline %}
<?php
// src/Acme/StoreBundle/Entity/ProductRepository.php
namespace Acme\StoreBundle\Entity;

use Doctrine\ORM\EntityRepository;

class ProductRepository extends EntityRepository
{
    public function findAllOrderedByName()
    {
        return $this->getEntityManager()
            ->createQuery(
                'SELECT p FROM AcmeStoreBundle:Product p ORDER BY p.name ASC'
            )
            ->getResult();
    }
}
?>
{% endhighlight %}

This is all fine and dandy, but do you really want to repeat yourself everytime
you write a query for a model that will almost **always** be ordered
by the same field? Or get caught out by calls to default repository methods that
*don't* use the ordering you like? No, you don't. Enter this piece of code:

{% highlight php linenos inline %}
<?php
// src/Acme/StoreBundle/Entity/ProductRepository.php
namespace Acme\StoreBundle\Entity;

use Doctrine\ORM\EntityRepository;

class ProductRepository extends EntityRepository
{
    public function findBy(array $criteria, array $orderBy = null, $limit = null, $offset = null)
    {
        // Default Ordering
        $orderBy = $orderBy === null ? array('added' => 'desc') : $orderBy;

        // Default Filtering
        if (array_key_exists('active', $criteria) === false) {
            $criteria['active'] = 1;
        }
        return parent::findBy($criteria, $orderBy, $limit, $offset);
    }
}
?>
{% endhighlight %}

The [findBy][3] method of the EntityRepository class is the method used by most
(if not all) of the the repository methods that fetch data. This includes `findBy`
methods where you can specify an arbitrary column and value:

{% highlight php linenos inline %}
<?php
// find a group of products based on an arbitrary column value
$products = $repository->findByPrice(19.99);
?>
{% endhighlight %}

So to ensure a default ordering, we override this method and check if an orderBy
clause has been set. If not, set it to our default ordering &mdash; in this case by the
`added` field, descending. For good measure we also add default filtering &mdash;
the `active` field needs to equal 1. Once that's done, call the parent method
with the default values set.

Easy as &#960;


[1]: http://www.teach-a-rific.com
[2]: http://symfony.com/doc/current/book/doctrine.html#custom-repository-classes
[3]: http://www.doctrine-project.org/api/orm/2.3/class-Doctrine.ORM.EntityRepository.html#_findBy
