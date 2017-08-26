---
title: "Monads for Go Programmers"
date: 2017-07-16T12:05:59+02:00
draft: true
tags: ["monads", "golang"]
---

## Why?

Monads are all about function composition and hiding the tedious part of it.

After 7 years of being a Go programmer, the amount of times I have had to type `if err != nil` can become quite tedious.
Everytime I type `if err != nil` I thank the Gophers for a readable language with great tooling,but at the same time I curse them for making me feel like I'm Bart Simpson in detention.

![Missing image of Bart Simpson writing if err != nil on the detention chalkboard](http://awalterschulze.github.io/blog/monads-for-goprogrammers/bartiferr.png "if err != nil")

[I suspect I am not the only one](https://anvaka.github.io/common-words/#?lang=go), but 
```go
if err != nil {
    log.Printf("This should still be interesting for a go programmer " +
        "considering to use a functional language, despite %v.", err)
}
```

Monads are not just used to hide some error handling, but can also be used for list comprehension and concurrency, to name but a few.

## Don't read this

In Erik Meijer's [Introduction to Functional Programming Course on Edx](https://www.edx.org/course/introduction-functional-programming-delftx-fp101x-0)
he asks us to please not write another post on `monads`, since there are already so many.

I recommend you watch [Bartosz Milewski's videos on Category Theory](https://www.youtube.com/playlist?list=PLbgaMIhjbmEnaH_LTkxLI7FMa2HsnawM_)
, which culminates in a video that is [the best explanation of Monads](https://www.youtube.com/watch?v=gHiyzctYqZ0&t=4s&index=19&list=PLbgaMIhjbmEnaH_LTkxLI7FMa2HsnawM_) that I have ever seen, 
rather than reading this post.

Stop reading now!

## Functors

Okay fine ... sigh ... just remember I warned you.

Before I can explain `monads`, I first need to explain `functors`.
A `functor` is a superclass of a `monad`, which means that all `monads` are `functors` as well.
I will use `functors` in my explanation of `monads`, so please don't gloss over this section.

We can think of a `functor` as a container, which contains one parametric type.

Examples include:

  - A slice with parametric type T: `[]T` is a container where the items are ordered into a list.
  - A tree: `type Node<T> struct { Value T; Children: []Node<T> }` is a container whose items are structured into a tree;
  - A channel with parametric type T: `<-chan T` is a container, like a pipe which contains water;
  - A pointer: `*T` is a container that may be empty or contain one item;
  - A function: `func(a) T` is a container, like a lock box, that first needs a key, before you can see the item;
  - A tuple: `(T, error)` is a container that possibly contains one item with a possible error in the container as well.

> Non go programmers: Go does not have algebriac data types or union types.  This means that instead of a function returning a value `or` an error, we go programmers return a value `and` an error, where one of them is typically nil.  Sometimes we break the convention and return a value and an error, where both are not nil, just to try and confuse one another. Oh we have fun.

> The most popular way to have union types in go would be have an interface (abstract class) and then have a type switch (a very naive form of pattern matching) on the interface type.

The other requirement for a container to be a `functor` is that we need an implementation of the `fmap` function for that container type.
The `fmap` function applies a function to each item in the container without modifying the container or structure in any way.

```text
func fmap(f func(a) b, aContainerOfa Container<a>) Container<b>
```

The classic example, which you might recognize from Hadoop's mapreduce, Python, Ruby or almost any other language you can think of, is the `map` function for a slice:

```go
func fmap(f func(a) b, as []a) []b {
    bs := make([]b, len(as))
    for i, a := range as {
        bs[i] = f(a)
    }
    return bs
}
```

We can also implement `fmap` for a tree:

```text
func fmap(f func(a) b, atree Node<a>) Node<b> {
    btree := Node<b>{
        Value: f(atree.Value),
        Children: make([]Node<b>, len(atree.Children)),
    }
    for i, c := range atree.Children {
        btree.Children[i] = fmap(f, c)
    }
    return btree
}
```

Or a channel:

```go
func fmap(f func(A) B, in <-chan A) <-chan B {
	out := make(chan B, cap(in))
	go func() {
		for a := range in {
			b := f(a)
			out <- b
		}
		close(out)
	}()
	return out
}
```

Or a pointer:

```go
func fmap(f func(a) b, a *a) *b {
    if a == nil {
        return nil
    }
    b := f(*a)
    return &b
}
```

Or a function:

```go
func fmap(f func(a) b, g func(c) a) func(c) b {
    return func(c c) b {
        a := g(c)
        return f(a)
    }
}
```

Or a function that returns an error:

```go
func fmap(f func(a) b, g func() (*a, error)) func() (*b, error) {
    return func() (*b, error) {
        a, err := g()
        if err != nil {
            return nil, err
        }
        b := f(*a)
        return &b, nil
    }
}
```

All of these containers with their respective `fmap` implementations are examples of `functors`.

## Function Composition

Now that we understand that a `functor` is just:
  - an abstract name for a container and
  - that we can apply a function to the items inside the container
, we can get to the whole point: the abstract concept of a `monad`.

A `monad` is simply an embellished type.
Hmmm ... ok that does not help to explain it, its too abstract.
And that is typically the problem with trying to explain what a `monad` is.
Its like trying to explain what "side effects" are, its just too broad.
So lets rather explain the reason for the abstraction of a `monad`.
The reason is to compose functions that return these embellished types.

Lets start with plain function composition, without embellished types.
In this example, we want to compose two functions `f` and `g` and return a function that takes the input that is expected by `f` and return the output from `g`:

```go
func compose(f func(a) b, g func(b) c) func(a) c {
    return func(a a) c {
        b := f(a)
        c := g(b)
        return c
    }
}
```

Obviously, this will only work if the output type of `f` matches the input type of `g`.

Another version of this would be composing functions that return errors.

```go
func compose(f func(*a) (*b, error), g func(*b) (*c, error)) func(*a) (*c, error) {
    return func(a *a) (*c, error) {
        b, err := f(a)
        if err != nil {
            return nil, err
        }
        c, err := g(b)
        return c, err
    }
}
```

Now we can try to abstract this error as an embellishment `M` and see what we are left with:

```text
func compose(f func(a) M<b>, g func(b) M<c>) func(a) M<c> {
    return func(a a) M<c> {
        mb := f(a)
        // ...
        return mc
    }
}
```

We have to return a function that takes an `a` as an input parameter, so we start by declaring the return function.
Now that we have an `a`, we can call `f` and get and a value `mb` of type `M<b>`, but now what?

We fall short, because its too abstract.
I mean now that we have `mb`, what do we do?

When we knew it was an error we could check it, but now that its abstracted away, we can't.

But ... if we know that our embellishment `M` is also a `functor`, then we can `fmap` over `M`:

```text
type fmap = func(func(a) b, M<a>) M<b>
```

The function `g` that we want to `fmap` with does not return a simple type like `c` it returns `M<c>`.
Luckily this is not a problem for `fmap`, but it changes the type signature a bit:

```text
type fmap = func(func(b) M<c>, M<b>) M<M<c>>
```

So now we have a value `mmc` of type `M<M<c>>`:

```text
func compose(f func(a) M<b>, g func(b) M<c>) func(a) M<c> {
    return func(a a) M<c> {
        mb := f(a)
        mmc := fmap(g, mb)
        // ...
        return mc
    }
}
```

We need a way to go from `M<M<c>>` to `M<c>`.

We need our embellishment `M` to not just be a `functor`, but to also have another property.
This extra property is a function called `join` and is defined for each `monad`, just like `fmap` was defined for each `functor`.

```text
type join = func(M<M<c>>) M<c>
```

Given join, we can now write:

```text
func compose(f func(a) M<b>, g func(b) M<c>) func(a) M<c> {
    return func(a a) M<c> {
        mb := f(a)
        mmc := fmap(g, mb)
        mc := join(mmc)
        return mc
    }
}
```

This means we can compose two functions that return embellished types, if the embellishment defines `fmap` and `join`.
These two functions are required to be defined for a type, for that type to be a `monad`.

## Join

Monads are `functors`, so we don't need to define `fmap` for them again.
We just need to define `join`.

```text
type join = func(M<M<c>>) M<c>
```

We will now define `join` for:
  - lists, which will result in list comprehensions,
  - errors, which will result in monadic error handling and
  - channels, which will result in a concurrency pipeline.

### List Comprehension

Join on a slice is the simplest probably the easiest to start with.
The `join` function simply concatenates all the slices.

```go
func join(ss [][]T) []T {
    s := []T{}
    for i := range ss {
        s = append(s, ss[i]...)
    }
    return s
}
```

This means we can define compose on functions that return slices.

```go
type compose = func(func(a) []b, func(b) []c) func(a) []c
```

And that makes a slice our first `monad`.
Here is an example:

```go
func upto(n int) []int { 
    nums := make([]int, n)
    for i := range nums {
        nums[i] = i+1
    }
    return nums
}

func pair(x int) []int {
    return []int{x, -1*x}
}

c := compose(upto, pair)
c(3)
// 1,-1,2,-2,3,-3
```

This is exactly how list comprehensions work in Haskell:

```haskell
[ y | x <- [1..4], y <- pair x ]
```

And in Python:

```python
def pair (x):
  return [x, -1*x]

[y for x in range(1,4) for y in pair(x) ]
```

### Monadic Error Handling

We can also define `join` on functions which return a value and an error.
For this we first need to take a step back to the `fmap` function again, because of some idiosyncrasies in go.

```go
type fmap = func(f func(b) c, g func(a) (b, error)) func(a) (c, error)
```

We know our compose function is going to call `fmap` with a function `f` that also returns an error.
This will result in our `fmap` signature looking something like this:

```go
type fmap = func(f func(b) (c, error), g func(a) (b, error)) func(a) ((c, error), error)
```

Unfortunately tuples are not first class citizens in go, so we can't write:

```go
((c, error), error)
```

There are a few ways to work around this problem.
I prefer using a function, since a function that returns a tuple is still a first class citizen:

```go
(func() (c, error), error)
```

Now we can define our `fmap` for functions which returns a value and an error, using our work around:

```go
func fmap(f func(b) (c, error), g func(a) (b, error)) func(a) (func() (c, error), error) {
    return func(a a) (func() (c, error), error) {
        b, err := g(a)
        if err != nil {
            return nil, err
        }
        return func() (c, error) {
            return f(b)
        }
    }
}
```

Which brings us back to our main point, our `join` function on `(func() (c, error), error)`.
Its pretty simple and simply does one of the error checks for us.

```go
func join(f func() (c, error), err error) (c, error) {
    if err != nil {
        return nil, err
    }
    return f()
}
```

We can now use our compose function, since we have defined `join` and `fmap`:

```go
func unmarshal(data []byte) (s string, err error) {
    err = json.Unmarshal(data, &s)
    return
}

getnum := compose(
    unmarshal, 
    strconv.Atoi,
)
getnum(`"1"`)
// 1, nil
```

This results in us having to do less error checking, since the `monad` does it for us in the background using the `join` function.

There are many other `monads` out there.
Think of any two functions that you want to compose that return the same type of embellishment.
Lets do one more example.

### Concurrent Pipelines

We can also define `join` on channels.

```go
func join(in <-chan <-chan T) <-chan T {
	out := make(chan T)
	go func() {
		wait := sync.WaitGroup{}
		for c := range in {
			wait.Add(1)
			res := c
			go func() {
				for r := range res {
					out <- r
				}
				wait.Done()
			}()
		}
		wait.Wait()
		close(out)
	}()
	return out
}
```

Here have a channel `in` that will feed us more channels of type `T`.
We first create our `out` channel and start up a go routine which we are going to use to feed the channel with and then return the `out` channel.
Inside the go routine we start up a new go routine for each incoming channel that we are reading from `in`.
This inner go routines will be used to listen to incoming events on a single channel and send all of these events to the `out` channel.
Then we wait for all the channels to be closed and close the `out` channel.

In short we are reading all `T`s from `in` and pushing them all to the `out` channel.

This means we can define a compose function on functions that return channels.

```go
func compose(f func(A) <-chan B, g func(B) <-chan C) func(A) <-chan C {
	return func(a A) <-chan C {
		b := f(a)
		return join(fmap(g, b))
	}
}
```

And because of the way that `join` is implemented, we get concurrency almost for free.

```go
func toChan(lines []string) <-chan string {
	c := make(chan string)
	go func() {
		for _, line := range lines {
			c <- line
		}
		close(c)
	}()
	return c
}

func wordsize(line string) <-chan int {
	c := make(chan int)
	go func() {
		words := strings.Split(line, " ")
		for _, word := range words {
			c <- len(word)
		}
		close(c)
	}()
	return c
}

sizes := compose(
    toChan([]string{
        "my name is judge",
        "welcome judy welcome judy",
        "welcome hello welcome judy",
        "welcome goodbye welcome judy",
    }), 
    wordsize,
)
total := 0
for _, size := range sizes {
    total += size
}
// total == 83
```

## Less Hand waving

This was a very hand wavy explanation of `monads` and there are many things I intentionally left out, to keep things simpler, but there is one thing that I would like to cover.

Technically our compose function defined in the previous section, is called the `Kleisli` arrow.

```text
type kleisliArrow = func(func(a) M<b>, func(b) M<c>) func(a) M<c> {
```

When people talk about `monads` they rarely mention the `Kleisli` arrow, which was the key for me to understanding `monads`.
If you are lucky they explain it using `fmap` and `join`, but if you are unlucky, like me, they explain it using the bind function.

```text
type bind = func(M<b>, func(b) M<c>) M<c>
```

Why?

Because this is the `mappend` or `>>=` function in Haskell that you need to implement for your type to be consider of the `Monad` type class.

Lets repeat our implementation of the compose function here:

```text
func compose(f func(a) M<b>, g func(b) M<c>) func(a) M<c> {
    return func(a a) M<c> {
        mb := f(a)
        mmc := fmap(g, mb)
        mc := join(mmc)
        return mc
    }
}
```

If the bind function was implemented then we could simply call it instead of `fmap` and `join`.

```text
func compose(f func(a) M<b>, g func(b) M<c>) func(a) M<c> {
    return func(a a) M<c> {
        mb := f(a)
        mc := bind(mb, g)
        return mc
    }
}
```

Which means that `bind(mb, g)` = `join(fmap(g, mb))`.

The `bind` function for lists would be `concatMap` or `flatMap` depending on the language.

```go
func concatMap(as []a, func(a) []b) []b
```

## Squinting

I found that go started to blur the lines for me between `bind` and `Kleisli`.
Go returns an error in a tuple, but a tuple is not a first class citizen.
For example this code will not compile:

```go
func f() (int, error) {
    return 1, nil
}

func g(i int, err error, j int) int {
    if err != nil {
        return 0
    }
    return i + j
}

func main() {
    i := g(f(), 1)
    println(i)
}
```

, because you cannot pass `f`'s results to `g`, in an in-line way.
You have to write it out:

```go
func main() {
    i, err := f()
    j := g(i, err, 1)
    println(j)
}
```

Or you have to make `g` take a function as input, since functions are first class citizens.

```go
func f() (int, error) {
    return 1, nil
}

func g(ff func() (int, error), j int) int {
    i, err := ff()
    if err != nil {
        return 0
    }
    return i + j
}

func main() {
    i := g(f, 1)
    println(i)
}
```

But that means that our bind function:

```text
type bind = func(M<b>, func(b) M<c>) M<c>
```

as defined for errors:

```go
type bind = func(b, error, func(b) (c, error)) (c, error)
```

will not be fun to use, unless we squash that tuple into a function:

```go
type bind = func(func() (b, error), func(b) (c, error)) (c, error)
```

It we squint we can see our returning tuple as a function as well:

```go
type bind = func(f func() (b, error), g func(b) (c, error)) func() (c, error)
```

And if we squint again, then we can see that this is our compose function, where `f` just takes zero parameters:

```go
type compose = func(f func(a) (b, error), g func(b) (c, error)) func(a) (c, error)
```

Ta da, we have our `Kleisli` arrow, by just squinting a few times.

## Conclusion

Monads hide some of the repeated logic of composing functions with embellished types, so that you don't have to feel like Bart Simpson in detention, but rather like Bart Simpson on his skateboard.

![Missing image of Bart Simpson on his skateboard](http://awalterschulze.github.io/blog/monads-for-goprogrammers/bartskate.jpg "separation of church and skate")

If you want to try `monads` and other functional programming concepts in go, then you can do it using my code generator, [GoDerive](https://github.com/awalterschulze/goderive).

> Warning:  One of the key concepts of functional programming is immutability.  This not only makes programs easier to reason about, but also allows for compiler optimizations.  To simulate this immutability, in Go, you will tend to copy lots of structures that will lead to non optimal performance.  The reason functional programming languages gets away with this is exactly because they can rely on the immutability and always point to the old values, instead of copying them again.

> If you really want to transition to functional programming, I would recommend [Elm](http://elm-lang.org/).  Its a statically typed functional programming language for the front-end.  It is as easy to learn as is Go to learn for an imperative language.  I did this [guide](https://guide.elm-lang.org/) in a day and I was able to start being productive that evening.  The creator went out of his way to make it an easy to learn language by even removing the need to understand monads.  I have personally found `Elm` a joy to use in the front-end in conjunction with Go in back-end.  If you start feeling bored in Go and Elm, don't worry there is much more to learn, Haskell is waiting for you.

