---
layout: post
title: "Abstracting exception handlers in Scala"
description: "Scala offers many ways to abstract and reuse code, but one area where this is not entirely obvious is _exception_ handling."
date: 2012-12-10 16:39:18
comments: true
keywords: "Scala, error handling, exceptions, dsl"
tags:
- scala
---

Scala offers many ways to abstract and reuse code, but one area where this is not entirely obvious is _exception_ handling. Sure, when it comes to *error handling*, there are good ways to write elegant code: use `Option` or `Either` and soon `Try`. But when it comes to _exceptions_, for instance when interfacing with Java code, one has to write tedious `try-catch` blocks. In this post I will briefly describe a few utility methods in the standard library that are undeservedly obscure. I got the idea of this blog post when answering [this stack overflow question](http://stackoverflow.com/questions/12618072/testing-if-a-given-instance-is-a-subclass-of-a-given-class-in-scala/12621215#12621215) (though my answer is not the most voted, I still think it's the better solution ;-)).

### scala.util.control.Exception

This little utility class and allows the programmer to abstract over common patterns of handling exceptions. Let's start with some code that catches an exception and converts it to <code>Option</code>.

{% highlight scala %}
import scala.util.control._

object exceptions {
  import Exception._
  
  catching(classOf[NoSuchElementException]).opt {
    List().head
  }                                               //> res1: Option[Nothing] = None
}
{% endhighlight %}

`catching` loosely follows the [builder pattern](http://en.wikipedia.org/wiki/Builder_pattern) and constructs a `Catcher` object, with user-configurable logic for _what_ to catch and _how_ to handle the exceptions. In our example, we pass an exception type and configure the catcher to convert the result to an option. Obviously, if an exception is thrown the result is `None`

In exactly the same way we could convert it to `Either`:

{% highlight scala %}
import scala.util.control.Exception._

object exceptions {
  val xs = List(1)

  catching(classOf[NoSuchElementException]).opt {
    xs.head
  }                                               //> res0: Option[Int] = Some(1)

  catching(classOf[NoSuchElementException]).either {
    xs.head
  }                                               //> res1: scala.util.Either[Throwable,Int] = Right(1)
}
{% endhighlight %}

### Canned logic

`catching` takes any number of exceptions and it is the most flexible way to use this library, but a few patterns come up often enough to warrant their addition to the standard library:

- `nonFatalCatch` is, unsurprisingly, a catcher that re-throws fatal errors. Given that the Scala compiler sometimes relies on exceptions for control flow (like non-local returns), it's a *very bad idea* to catch any of those
- `ignoring(e1, e2, ..)` evaluates a block and catches given exceptions (it returns `Unit`, so this can be used only for side-effecting code
- `failing(e1, e2, ..)` evaluates a block and catches given exceptions, returning `None` if the block throws an exception, wrapping the resulting value in an `Option`
- `failAsValue(e1, e2, ..)(default)` catches any of the given exceptions and returns a given default value if the block throws. For instance,
{% highlight scala %}
  failAsValue(classOf[Exception])(-1) {
    xs(2)
  }                                               //> res3: Int = -1
{% endhighlight %}

Catchers can be customised even more, and that's what I used in the SO answer. `withApply` can be used to pass a function that handles the exceptional case. For instance:

{% highlight scala %}
  def logError(t: Throwable): Int = {
    println("Error: " + t)
    -1
  }
  
  catching(classOf[Exception]).withApply(logError _) {
    xs(2)
  }                                               //> Error: java.lang.IndexOutOfBoundsException: 2
                                                  //| res3: Int = -1
{% endhighlight %}

This example shows how the exception handling logic can be abstracted in a function. We can take this one step further and reuse entire catchers (since they are plain Scala values, there's not much to be done):

{% highlight scala %}
  val loggingExceptions = catching(classOf[Exception]).withApply(logError _)
  
  loggingExceptions {
    xs(2)
  }                                               //> Error: java.lang.IndexOutOfBoundsException: 2
                                                  //| res3: Int = -1
{% endhighlight %}

I've found this utility class very useful when integrating [Scala code](http://www.scala-ide.org) with an existing [Java codebase](http://www.eclipse.org), and a good example of DSL design.