---
layout: post
title: A Summary of Symfony 2 Authorization
categories:
- blog
---

Symfony 2 comes with a great [security component][1] that provides both [Authentication][2]
(identifying the user) and [Authorization][3] (determining the permissions for the user)
functionality. It has sane defaults, works out of the box, and is extendable enough
to cater for any scenario. This post describe the default authorization functionality
available to the developer.

Out of the box, Symfony 2 offers two method with which to authorize a user:

* Role based authorization
* Access control lists (ACL's)

Role Based Authorization
------------------------

With role based authorization, you specify a number of roles (which can be hierarchical)
and specify the access of these roles, all within your application config:

    #project/app/config/security.yml
    security:
        role_hierarchy:
            ROLE_ANONYMOUS:
            ROLE_USER:        ROLE_ANONYMOUS
            ROLE_ADMIN:       ROLE_USER
            ROLE_SUPER_ADMIN: [ROLE_ADMIN, ROLE_ALLOWED_TO_SWITCH]

        access_control:
            - { path: ^/login, roles: IS_AUTHENTICATED_ANONYMOUSLY }
            - { path: ^/public, roles: IS_AUTHENTICATED_ANONYMOUSLY }
            - { path: ^/, roles: ROLE_USER }
            - { path: ^/admin/, role: ROLE_ADMIN }

In the config above, there's roles (or types of users). Anonymous, normal users, admin
users and super admin users. Anonymous users can only access the public part of the site.
Logged in users can access the whole site, except for the admin area. Admin users can access
the admin area of the site. Relatively simple and easy to set up, but not very customizable
on a fine grained level.

Access Control Lists
--------------------

Say for instance that users generate content, and that users can only access the content
they generated. The role based rules are too general for this, so we'll turn to Access Control
Lists for a solution.

The concept of ACL's boils down to a list of many to many relations between users
and resources defining who has access to what. Even though Symfony provides built
in [ACL functionality][4], this can become hairy quite quickly, as you need to manage
Access Control Entries (ACE) in your controller code.

Although Symfony provides an [ACL Provider][5] with which the coder can create and
check ACL's, it can become hairy quite quickly, as it needs to be managed in each and
every Controller Action.

This boilerplate code wil appear in controller actions that deal with creating Entities
and their ACL's:

    <?php
    use Symfony\Component\Security\Acl\Domain\ObjectIdentity;
    use Symfony\Component\Security\Acl\Domain\UserSecurityIdentity;
    use Symfony\Component\Security\Acl\Permission\MaskBuilder;

    // Inside a controller action

    // creating the ACL
    $aclProvider = $this->get('security.acl.provider');
    $objectIdentity = ObjectIdentity::fromDomainObject($entity);
    $acl = $aclProvider->createAcl($objectIdentity);

    // retrieving the security identity of the currently logged-in user
    $securityContext = $this->get('security.context');
    $user = $securityContext->getToken()->getUser();
    $securityIdentity = UserSecurityIdentity::fromAccount($user);

    // grant owner access
    $acl->insertObjectAce($securityIdentity, MaskBuilder::MASK_OWNER);
    $aclProvider->updateAcl($acl);

The "creating the ACL" block retrieves the Security Provider, generates an identity
for the object using the `ObjectIdentity` class, and then creates the ACL using the
security provider.

The second block retrieves the Security Context and the current user. From there it
generates the an identifier for the user using the `UserSecurityIdentity` class.

The third block then inserts an Access Control Entry and updates the ACL.

That's a lot of code. If there's a generic way to handle this, please let me know
in the comments.

Behind the Scenes
-----------------

The key component in how Symfony manages authentication is the [AccessDecisionManager][6].
Each time a request is made, the `AccessDecisionManager` lets registered Voters vote on
if the user may access the resource. The voters will determine their vote by inspecting
the current security token, a set of attributes, and an optional object. Access will
then be granted (or denied) depending on the votes and the `AccessDecisionManager's`
decision strategy. Both the role based auth and ACL's use this mechanism.

I'll go into how to use the `AccessDecisionManager` and Voters in a later post.

[1]: http://symfony.com/doc/current/book/security.html
[2]: http://symfony.com/doc/current/components/security/authentication.html
[3]: http://symfony.com/doc/current/components/security/authorization.html
[4]: http://symfony.com/doc/current/cookbook/security/acl.html
[5]: http://api.symfony.com/2.0/Symfony/Component/Security/Acl/Dbal/AclProvider.html
[6]: http://api.symfony.com/2.2/Symfony/Component/Security/Core/Authorization/AccessDecisionManager.html
