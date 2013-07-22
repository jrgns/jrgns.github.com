---
layout: post
title: Pre-populating an Entity in a Symfony 2 Form
categories:
- blog
---

I've been working on [teach-a-rific.com][1] in my spare time, and I'm learning a lot
about how [Symfony 2 Forms][2] work. One thing I need to do a lot, is to show a
form with a [entity field][3] pre-populated. In this situation you also don't want
the user to be able to edit the field. This is how I did it.

First, you need to retrieve the mapped entity, in this case a `Student`, and set it
in the entity which you're creating a form for. In this case a `ContactDetail`.
This all happens in the `newAction` method of the `ContactDetailController`.
Notice how I save the student ID in a session variable. More on this later.

{% highlight php linenos inline %}
<?php
//ContactDetailController::newAction
$detail = new ContactDetail();

if ($studentId = $request->query->get('student_id')) {
    $student = $this
        ->getDoctrine()
        ->getManager()
        ->getRepository('NotesNoteBundle:Student')
        ->find($studentId);
    if ($student) {
        $this->get('session')->set('contact_detail:create:student', $studentId);
        $detail->setStudent($student);
    }
}

$form = $this->createForm(new ContactDetailType(), $detail);
{% endhighlight %}

On to the form. Quite simply, if the entity already has a student, don't add the
field for the student.

{% highlight php linenos inline %}
<?php
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolverInterface;

class ContactDetailType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options)
    {
        if ($builder->getData()->getStudent() === null) {
            $builder->add('student');
        }
        $builder
            ->add('type', 'choice', array('choices' => array('Email' => 'Email', 'Cellphone' => 'Cellphone')))
            ->add('content')
        ;
    }
}
{% endhighlight %}

On to the actual form. If the student field is defined in the form, display the
form widget. Otherwise display the student in an uneditable text input. Displaying
the student can be skipped if it's not necessary.

{% highlight php linenos inline %}
{% raw %}
{% if form.student is defined %}
    {{ form_row(form.student, { form_type: 'horizontal' }) }}
{% elseif form.vars.data.student.id is defined %}
    <div class="control-group">
        <label class="control-label">Student</label>
        <div class="controls">
            <span class="input uneditable-input">{{ form.vars.data.student }}</span>
        </div>
    </div>
{% endif %}
{% endraw %}
{% endhighlight %}

And on to the `updateAction`. Just get the Student whose ID we stored in the session,
and set it on the ContactDetail before populating the form:

{% highlight php linenos inline %}
<?php
//ContactDetailController::updateAction
$entity  = new ContactDetail();

if ($studentId = $this->get('session')->get('contact_detail:create:student')) {
    $student = $this
        ->getDoctrine()
        ->getManager()
        ->getRepository('NotesNoteBundle:Student')
        ->find($studentId);
    if ($student) {
        $entity->setStudent($student);
    }
}
{% endhighlight %}

Simple enough. Any suggestions on how to improve it, or comments on how to do it
differently?

[1]: http://www.teach-a-rific.com
[2]: http://symfony.com/doc/current/book/forms.html
[3]: http://symfony.com/doc/current/reference/forms/types/entity.html
