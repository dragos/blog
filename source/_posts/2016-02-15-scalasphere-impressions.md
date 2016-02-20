---
layout: post
title: "ScalaSphere impressions"
description: "One of the best Scala conferences of past year just happened. Here are my impressions."
date: 2016-02-15
comments: true
keywords: "Scala, conference, dev tools"
tags:
- scala, conference, dev tools
---

One of the best Scala conferences of past year just happened. Here are my impressions.

[ScalaSphere](http://scalasphere.org) was, hands-down, the Scala conference where I watched the most talks in the past few years. The energy and excitement were real and I'll summarize my main impressions in this blog (fully aware that I can't do justice to the whole atmosphere, vibe and Polish hospitality). If you want my advice, book early for next year's session!

Back in September 2015 [I deplored](https://www.youtube.com/watch?v=c1tIbHATjB0) the state of Scala tooling and the little attention they gather in most Scala conferences.  Probably trying to prove me wrong, the good people of [VirtusLab](http://virtuslab.com) decided to organize a full conference dedicated to Scala development tools. Meet ScalaSphere: 2 days, single track, finishing off with a Hackathon for your favorite tool! There were 180 registrations, and I think the first morning saw the full bunch, with a few standing-room talks. 

## IDE and No IDE

It's only fair to start with the elephant in the room: IDEs.  Whatever your favorite IDE is, you'd agree that they have evolved greatly in the past few years (caveat: [I'm biased](http://scala-ide.org/team.html)). All major IDEs were present: [Pavel Fatin](https://pavelfatin.com/) represented the IntelliJ platform, [Sam Halliday](https://twitter.com/fommil) and [Rory Graves](https://twitter.com/a_dev_musing) for [Ensime](http://ensime.github.io/), and [Wiesław Popielarski](https://github.com/wpopielarski) for Scala IDE.

- The IntelliJ Scala demo was impressive as usual, highlighting the platform language model (called PSI) and the ease with which new *inspections* can be written. A good inspiration for tool writers, the Psi model is pretty close to a concrete syntax (including parenthesis or whitespace and comments).
- The Scala IDE talk focused on two new tools in the debugging department: expression evaluator (in a debugged running instance), and the [async debugger](http://scala-ide.org/docs/current-user-doc/features/async-debugger/index.html), both being quite awesome. You should check them out.
- The Ensime talk was a breath of fresh air, and proved that a capable IDE can be built on top of "simple" editors like Emacs, Sublime Text or Atom. The Ensime architecture makes it easy to port a powerful set of services to other editors: the presentation compiler, the powerful engine behind the Scala IDE, is exposed as an HTTP service, such that semantic highlighting or code completion can be invoked via a REST API. Ensime is more than just the presentation compiler, though, so make sure to check it out next time you want to add Scala support to your editor of choice (such as my current favorite, [Visual Studio Code](https://code.visualstudio.com/)).

### NO-IDE 

No Scala IDE showdown is complete without the *no-IDE* camp, and we had a great lightning talk by [Dave Gurnell](http://davegurnell.com/) showing how to get by without an actual IDE: a capable editor, bookmarks for documentation (downloaded locally for your low-latency pleasure), application launcher, Dash and grep is all you need!

Web-based (hosted) IDEs made an appearence via Rory's lightning talk: [Scalanator](https://www.scalanator.io/) is a training platform based on Code Mirror and Ensime meant at bringing a hands-on approach to Scala schooling: code directly in the browser and get quick feedback on your progress. My personal take on Web-based IDEs: they couldn't produce a killer feature yet, but could be useful in certain segments, such as training or code review. Training is particularly appealing, as zero-hassle setup is paramount and projects are small and self-contained.

### Scala Refactoring

[scala-refactoring](https://github.com/scala-ide/scala-refactoring) is one of the oldest Scala libraries in tools-space and powers both the Eclipse plugin and Ensime. It is based on the presentation compiler, so in principle it should have access to the most precise type information possible under the sun. Unfortunately, it is plagued by many bugs that trace to a common source: Scala type-checker desugarings. Mathias Langer has done an amazing job in the past year by squashing bug after bug, marking the best refactorings we've ever had in Scala IDE for a while.

In his talk [Matthias](https://twitter.com/mlangc) highlighted the difficulties and challenges in working with the presentation compiler. His verdict: we need a common model for Scala source that is close enough to surface syntax (concrete syntax) and put an end to error-prone and incomplete heuristics when printing trees and un-desugaring them. 

> Scala.Meta will save us all!

---

## Scala.Meta

The first day was definitely under the sign of [scala.meta](http://scalameta.org/), so [Eugene](http://xeno.by) gets a full section. Scala tooling is sufferring greatly from the lack of reusable tools. The Scala compiler itself (via the presentation compiler) has severe shortcomings that appeared in all talks except Pavel's (IntelliJ decided to write their own type-checker):

- no reliable way to un-de-sugar trees (sugar trees?): All tools need an attributed tree, but close enough to reconstruct the original code. Most notably, the Scala AST lacks comments, parenthesis, whitespace, in addition to non-trivial desugarings such as `for-yield` and *default-arguments*.
- batch-oriented: no easy way to resolve names in a source fragment. A clever work-around (called *targeted type-checking*) uses the batch type-checker, but due to important source transformations done during type-checking may lead (and it does!) to spurious errors (notably for code involving default-arguments and implicit resolution). More about this in another post.
- API incompatibilities: this really means that there is no well-defined API. Each Scala version may change the AST,or the way it is attributed. Even if it was binary compatible a new version may subtly change the way symbols are attached to trees (though, it isn't binary compatible). This leads to important burdens on tool writers, who essentially need to fork the tool for each Scala release they support.

Eugene's work is the holy grail of Scala development tools: a single model for Scala code, based on concrete syntax trees suitable for source transformations, with semnatic information (notably, types). The project is still under heavy development, but it can already handle purely syntactic tasks (such as automatic formatting). Next step: *converters* from existing type-checkers (think: different versions of the Scala compiler, Dotty, IntelliJ) to the new *lingua-franca* of the Scala world!

This last step proved to be problematic, and Eugene's talk, and the later brainstorming session -- more about that later -- have toned down our expectations. We can summarize this as "*there is no magic*": the first point makes a come-back: the converter needs to solve exactly the same problem as all tool writers, and there seem to be fundamental limitations in what can be achieved. A couple of ideas:

- desugaring is a one-way function. The AST can be matched to many input sources (think: is a `xs.map(x => x + 1)` coming from the same source, or maybe the user wrote `for (x <- xs) yield x + 1`? Or maybe he wrote `for (x <- xs) yield (x+1)`?
- starting with a concrete syntax tree (knowing what the user wrote) and mapping back from ASTs may provide enough context. But there's still the question of how to type certain constructs. Maybe the **only** truth there is **is** in the desguared AST. For example, an application with default arguments is simply not type-correct without the defaults inserted in the call (at least, in the usual Scala type-system).

{% highlight scala %}
// type: (File, String) => String
def readFile(f: File, encoding = "UTF-8"): String = //...

// a sane invariant is that
// Apply.args.size == Apply.fun.type.params.size
// but typing the sugared application has only one argument
readFile(new File("README.md"))
{% endhighlight %} 

*En bref*, hope is still there, but Eugene has some tough work ahead. The whole community counts on it and needs it.

---

## An ad-hoc brainstorming session 

As the first day drew to a close and my tired brain was dreaming of a beer to wash it all out, there was "one more thing" to be done: since all Eclipse plugin developers were under the same roof, we'd have a planning session.

What happened instead became **the highlight** of this conference: we had an all-hands meeting with practically all tool authors in the same room! IntelliJ, Ensime, Scala.Meta, Eclipse, Scala Refactoring and even Dotty were up to some serious brainstorming for the greater Scala good!

It all stated with the stringent problem of Scala refactorings: how can we improve their reliabilty, in the short-term and the long-term?

- remove all but three: *Rename*, *Organize Imports* and *Move Declaration*
- make these three bullet-proof
- base them on Scala.Meta?

This should be the subject of a whole post in itself (hopefully a joint one), suffice to say: there's some cool stuff coming out, and the Free Monad might be part of it (this is Karma)!

---

## Other tools

What else? Sbt had a couple of appearances, but unfortunately I missed Nepomuk's talk so I can't speak conclusively about auto-plugins.

[Coursier](https://github.com/alexarchambault/coursier) is a library for dependency fetching entirely written in Scala that aims to *fix Sbt*. It's easy to use programmatically, it's really fast, and has an Sbt plugin. Keep an eye on it, it may solve one of the main complaints against Sbt: slow resolution.

[Simon Ochsenreither](https://github.com/soc) talked about challenges in cleaning up the Scala specification and its corresponding implementation, focusing on two corner cases: automatic import of `java.lang._` and numeric promotions. A good primer on language design and the challenges of maintaing compatibility but evolving the language. At this point in Scala's evolution my personal take is that compatibility is, in the vast majority of cases, a more worthy goal than purity.

[Simon Schäffer](https://twitter.com/sschaef_)'s talk on an uber-platform to supersede them all was an ambitious overview of our field and the futile cycle of innovation and reinvention of the wheel. Thought provoking, and the kind of ambitious talk that gets one dreaming of a better future. Personally I'm not sure if I like the perspective of a single tooling platform for everyone (.NET tried and got the closest to that goal). Watch it for yourself once talks are online!

[Lukas Wegmann](https://github.com/Luegg) showed a pretty awesome [search tool](http://scala-search.org/): a Hoogle for Scala. Search Scala libraries for a specific type! Say, you need to get from a sequence to a set? type in `Seq[A] => Set[A]` and let Scala Search answer that for you. If we can have it index most popular Scala libraries this will become indispensable. Even better, this should integrate with IDEs and suggest completions based on the type context (something we actually had but fell into oblivion once the author graduated).

#### Honorable mention

[Rapture](http://rapture.io/) is a library for everyday Scala programming. It has nothing to do with Scala tools, as noted by Haoyi Li, but [Jon](https://twitter.com/propensive) did a great job at showing clear use-cases, elegant APIs and sense of humor! Watch it when its out, especially if you deal with i18n. I'd definitely give it a go in my next project.

#### Not watched

I missed a few talks during the second day, so appologies for not covering "Play-Swagger: Swagger support for the Play Framework" and "Custom deployments with Sbt plugins and sbt-native-packager".

---

## Panel: In the wind of change

Unfortunately, the panel had only nice people so no controversial, outrageous claims that lead to a heated discussion! Something to be fixed next year! Sbt came up several times, with everyone trying to be nice and look at the "good parts". Definitely, Sbt should have been represented at this conference.

---

## Conclusion

The conference was fantastic, and I will definitely return. The whole conference was organized in a very short time, and understandbly missed important pieces of the ecosystem (such as Sbt) whose main authors live across the ocean. All in all, a great success, and kudos to VirtusLab for a great job!
