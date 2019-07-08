---
title: "A Programmer’s Regret: Neglecting Math at University"
date: 2019-07-07
tags: ["mathematics", "category theory", "abstract algebra", "proofs", "dependent types"]
---

## Does Math Matter?

Math matters both more and less than you think...

Yes, you can ignore math and be a highly paid professional programmer. Programming is a wide enough field that you can choose which areas you want to focus on -- some of which do not require math -- and still be successful.  On the other hand:

   1. Mathematics is **the** tool used to solve specialized problems, and
   2. **Programming is doing mathematics**.  

I would like to give you some examples for both, with the hope that this will motivate you to give math a chance to grow on you. For this I have chosen some short (average 10 minutes in length) videos that should excite you and explain the concepts better than I can.

But first, a story. About me not caring about math...

## If you don’t want to learn, you won’t learn

When I was at university, I didn’t really see the point of math. It was such a big change from the math we did in high school, and all I really wanted to do was program.  Math just seemed like a necessary evil for getting my degree, so that I could move onto more programming. The proofs were the least motivating of all, since it felt like they needed to be crammed solely for the exam and offered no value for my programming career. My stubborn self felt so “principled” about it that I refused to study the proofs. This resulted in me being put into a special group for underperforming students in my first year. Too proud (read stupid), I refused to study the proofs and ended up narrowly passing even though 40% of the exam was proofs. Still not getting the message, I had to rewrite a test and an exam in my second year. The exam rewrite is where I finally compromised my principles and had to give up most of my summer vacation to study proofs. I couldn’t hack the math, so I lost a vacation and still didn’t understand why it was important.  You would think that from this great failure I would learn something, but I was still blinkered by stubbornness. Suffice to say, when math became an elective, I didn’t choose it! In hindsight this is one of my biggest regrets: five years later I would find out that the problems that I found most interesting were **all** intimately based in math.

I finally picked up a Computer Science book to read past the prescribed material in the week that I was handing in my master’s thesis.  This is when I finally realized that Mathematics and Computer Science were linked in a way that I found really interesting.  Since then I have been playing catch-up with all the students who were actually paying attention in class, during … my valuable after-work free time.  This has been an ongoing process for over ten years now, when I could have rather just paid attention for the four years that it was shoved in my face.  This is ten years I could have spent learning new things, like my peers who paid attention, but instead my math is still not at graduate level. Sometimes I really feel like I wasted my life, but rather than dwell on this any further, let’s look at some examples of Math that is important for programming.

## Examples of Math as a tool for Programmers

Obviously graphics programming in games and movies requires physics knowledge, but since exact physics can be too expensive to properly simulate, we typically use Numerical Methods from Mathematics, for example using Verlet Integration to approximate ragdoll physics:

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/2TIEfgC3tAo" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

Less obvious might be Google’s web search algorithm.  You might think this is simply counting words on web pages and showing the page with the highest count of the relevant word at the top, but this ranking is too easy to manipulate, for example a web page that just repeats the word math, does not actually contain any math.  Ranking the pages to have the most relevant results at the top is a much harder problem.  The PageRank algorithm takes into account the number of links to and from a web page and places them in a matrix, then it uses an approximation of an eigenvector from Linear Algebra to calculate a more relevant ranking:

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/F5fcEtqysGs" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

Artificial Intelligence or rather the subfield of Machine Learning, is something that I found very intriguing while studying. Tracking gestures on a dance game, finding movies that you might like on Netflix, recognizing the song that is currently playing, etc.  If you want to help to build any of these systems, you will need at least a good understanding of Calculus, Probability Theory and Linear Algebra.

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/8onB7rPG4Pk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

I think those are enough examples, which use math as the tool for solving specialized problems.  I now want to talk about the less obvious and show that math is programming, which I now find even more intriguing.

## Programming is eating Math

### Abstraction as an Appetizer

Abstraction is an extremely important part of programming. It is one way we can break up a complex problem into smaller pieces.  We see some pattern or want to hide some complexity and we create an abstraction, using for example abstract classes or interfaces. We even create patterns for how we abstract and abstract over those patterns.  It is very important how we abstract, since abstractions can be very confusing or very useful.  How can we discover the most useful abstractions?

Even though computers, as we know them, have only been around for a few decades, questions of computation and the design of computing engines have existed for hundreds of years.  This is quite a surprising fact, but still it is considered a very young field when compared to mathematics, which has been around for thousands of years.  This means that mathematics has had quite a bit more time to come up with solutions to certain problems. We might as well take a look to see if there are ideas that we can steal - in fact, it might be arrogant not to!

No surprise ... Mathematics has an appropriate sounding sub field called Abstract Algebra.
Here is a little taste of Abstract Algebra, with an explanation of a Group:

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/QudbrUcVPxk" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

A Group was a good abstraction over addition and multiplication, but it is also a superclass of a Monoid.  If you take a Group and remove the property that the elements need inverses, you are left with a Monoid.  A Monoid is a set of elements, which includes an identity element and an associative operation.  Now we have an abstraction that not only works for addition, but also:

<center>
<table>
    <tr>
        <td><b>Monoid</b></td>
        <td><b>Identity</b></td>
        <td><b>Operation</b></td>
    </tr>
    <tr>
        <td>Addition over Integers</td>
        <td>0</td>
        <td>+</td>
    </tr>
    <tr>
        <td>Multiplication over Integers</td>
        <td>1</td>
        <td>x</td>
    </tr>
    <tr>
        <td>Concatenation over Strings</td>
        <td>empty string</td>
        <td>concat</td>
    </tr>
    <tr>
        <td>Extending over Lists</td>
        <td>empty list</td>
        <td>extend</td>
    </tr>
    <tr>
        <td>Union over Sets</td>
        <td>empty set</td>
        <td>union</td>
    </tr>
    <tr>
        <td>Any over Booleans</td>
        <td>false</td>
        <td>or</td>
    </tr>
    <tr>
        <td>All over Booleans</td>
        <td>true</td>
        <td>and</td>
    </tr>
    <tr>
        <td>Overlay for Images</td>
        <td>Transparent Image</td>
        <td>Overlay</td>
    </tr>    
</table>
</center>

This abstraction is useful, because now we can write single implementations of functions that work for any monoid.  For example:

  - A simple function `mconcat`, which takes a list of monoid elements and combines them into a single element.  Summing a list of integers is now the same as overlaying a list of images.
  - A more complex function `foldMap` can recursively walk over a tree and either:
    * return whether any element is true,
    * find if there is any element is larger than 5, or 
    * transform the foldable structure into a set, 
    all depending on the type of monoid we use.

We can abstract even further and not only make this function work for trees, but for any foldable container, in other words, any container that can be transformed to a list.

Knowing about monoids can be useful when designing a library.  Whenever you have a binary function, like multiply, which takes two parameters of the same type and returns a result of the same type, it is a good idea to think about what the identity element would be.  If you find one, you have found a very intuitive way of using your binary function over lists.  Your function will even work on the empty list, since you have a sensible default with mathematical properties, and it will remove a case for error handling, which will simplify your user’s code.

Here we used the abstraction to create shared implementations, but an abstraction can be and should be more useful than that.  The abstraction is at the service of explaining or discovering the connections.

### The Composition of the Main Course

One quite popular way that humans solve a complex problem is to divide and conquer.  Break down the problem into smaller parts, solve those smaller problems and then compose those solutions into a solution for the bigger problem.  Can you think of another (general) way? ...

In programming we break up a problem into several smaller functions that solve smaller problems and then compose them together into bigger and bigger functions that eventually solve the bigger problem.  What would be the best way to compose functions together? I wonder if math has any ideas that we can steal?

Category Theory, another subfield of Mathematics, is what I like to call abstract Abstract Algebra, but really it is the mathematics of composition, where we study the context of objects rather than their content.  Here we can find many useful ideas, like:

  - Functors, which allow us to apply a function to every element in a container using a map function, like Lists in Python, the Stream API and Optional in Java or even functions in Haskell.
  - Monads, which are the basis of list comprehensions in Python, LINQ in C#, parser combinators in Scala, IO and most concurrency in Haskell, etc. 
    Find me a programming language and I’ll find you a useful monad in that language.
  - F-Algebras, which allow us to abstract over recursion - but to be honest, now we are at the edge of my knowledge.

These extremely abstract concepts can take a while to mature in your brain, so the earlier you start the better.  See below a short video that tries to explain monads:

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/Nq-q2USYetQ?start=55" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

### The Proof is in the Pudding

This is the sweetest and final part of your meal of math.

Now, you might remember that I said that I found proofs to be the least motivating part of doing Mathematics at University.  Well what if I told you that types can be viewed as propositions and programs as proofs:

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/SknxggwRPzU" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

Here are some provable properties:

  - x + y = y + x
  - P & (Q | R) = (P & Q) | (P & R)
  - length(filter(predicate, list)) <= length(list)
  - The executable code the C compiler produces is exactly as specified by the semantics of the source C program, see [CompCert](http://compcert.inria.fr/compcert-C.html)

Now that I know that I can use programming to prove things mathematically, I find proofs to be the most interesting thing about programming.  Proofs allow us to write safer programs with fewer errors, because we can prove properties instead of just testing them.

But wait, if you can prove things using programming, can’t you also contribute to Mathematics by simply doing the thing we love, writing programs? Yes and mathematics seriously needs you.  Proofs are not just hard for you, but also hard for mathematicians.  [Mathematicians create bugs in proofs all the time - and these bugs go undiscovered for decades](https://www.youtube.com/watch?v=E9RiR9AcXeE).  Homotopy Type Theory, which studies different types of equality, is disrupting the foundations of Mathematics with its univalent point of view, because it thinks that the so called foundations of Mathematics are buggy.  Yes, not even math is perfect and there is lots of room to contribute.

I am still new to the concept of proving using programming, but I find this very exciting and can’t wait to learn more.  I can recommend reading [The Little Typer](https://mitpress.mit.edu/books/little-typer), which provides a great introduction to proving using dependent types to any programmer that has some experience with recursion.

## Find Inspiration and Build Foundations

It seems the thing that I have been trying to avoid at all costs, turned out to be the thing that I loved doing most of all. Don’t make the same mistake I made: Make the best of your mandatory Mathematics subjects or you will regret it later.

If your educators or education material is not inspiring you to explore this vast area of knowledge, then please turn to the plethora of alternative online resource, like [YouTube](https://www.youtube.com/), [Coursera](https://www.coursera.org/) or [Edx](https://www.edx.org) or try to find a better book.  There is someone who can explain a difficult concept and inspire you - you just need to take the time to find them. You also need to practice using exercises, just like you practice programming.

Other times I have struggled because I didn’t understand a previous fundamental concept that was required to understand the new material.  Don’t be ashamed to go back and fix your understanding.  In math, many things build on top of one another and without solid foundations it is very hard to make any progress.  It is almost always worth taking the time to go back and find an alternative resource on the subject and try to properly grasp that key concept, instead of moving forward and banging your head against a wall.

I have a [todo list](https://github.com/awalterschulze/learning/blob/master/Mathematics.md) that I am using to try to catch up to all the math that I missed.  As you will see, this is only the start of a very long and delightful journey.  Mathematics is a huge and exciting subject, where almost everything is connected.  It might be useful to take a look at the bigger picture:

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/OmJ-4B-mS-Y" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

## Thank you

  - [Steve Kroon](http://www.cs.sun.ac.za/~kroon/) for incredibly scrupulous proofreading.
  - [Brandon Ashley](https://github.com/ShadowBrandon199) for inspiring this post.
  - [Paul Cadman](https://github.com/paulcadman) for providing a mathematical perspective.
  - [Liyuan Bi](https://www.linkedin.com/in/liyuan-bi-668761121/) for helping me add more examples.

## Referenced


