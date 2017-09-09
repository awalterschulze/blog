---
title: "Monads for Go Programmers"
date: 2017-08-26T12:19:12+02:00
tags: ["monads", "golang", "generator"]
---

## Why?

Monads are all about function composition and hiding the tedious part of it.

After 7 years of being a Go programmer, typing `if err != nil` can become quite tedious.
Everytime I type `if err != nil` I thank the Gophers for a readable language with great tooling, but at the same time I curse them for making me feel like I'm Bart Simpson in detention.

![Missing image of Bart Simpson writing if err != nil on the detention chalkboard](http://awalterschulze.github.io/blog/monads-for-goprogrammers/bartiferr.png "if err != nil")

[I suspect I am not the only one](https://anvaka.github.io/common-words/#?lang=go), but 
```go
if err != nil {
    log.Printf("This should still be interesting to a Go programmer " +
        "considering using a functional language, despite %v.", err)
}
```

Monads are not just used to hide some error handling, but can also be used for list comprehensions and concurrency, to name but a few examples.

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

We can think of a `functor` as a container, which contains one type of item.

Examples include:

  - A slice with items of type T: `[]T` is a container where the items are ordered into a list.
  - A tree: `type Node<T> struct { Value T; Children: []Node<T> }` is a container whose items are structured into a tree;
  - A channel: `<-chan T` is a container, like a pipe which contains water;
  - A pointer: `*T` is a container that may be empty or contain one item;
  - A function: `func(A) T` is a container, like a lock box, that first needs a key, before you can see the item;
  - Multiple return values: `func() (T, error)` is a container that possibly contains one item, while we can see the error as part of the container.  From here on we will refer to `(T, error)` as a tuple.

> Non Go programmers: Go does not have algebraic data types or union types.  This means that instead of a function returning a value `or` an error, we Go programmers return a value `and` an error, where one of them is typically nil.  Sometimes we break the convention and return a value and an error, where both are not nil, just to try and confuse one another. Oh we have fun.

> The most popular way to have union types in Go would be to have an interface (abstract class) and then have a type switch (a very naive form of pattern matching) on the interface type.

The other requirement for a container to be a `functor` is that we need an implementation of the `fmap` function for that container type.
The `fmap` function applies a function to each item in the container without modifying the container or structure in any way.

```go
func fmap(f func(A) B, aContainerOfA Container<A>) Container<B>
```

The classic example, which you might recognize from Hadoop's mapreduce, Python, Ruby or almost any other language you can think of, is the `map` function for a slice:

```go
func fmap(f func(A) B, as []A) []B {
    bs := make([]b, len(as))
    for i, a := range as {
        bs[i] = f(a)
    }
    return bs
}
```

We can also implement `fmap` for a tree:

```go
func fmap(f func(A) B, atree Node<A>) Node<B> {
    btree := Node<B>{
        Value: f(atree.Value),
        Children: make([]Node<B>, len(atree.Children)),
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
func fmap(f func(A) B, a *A) *B {
    if a == nil {
        return nil
    }
    b := f(*a)
    return &b
}
```

Or a function:

```go
func fmap(f func(A) B, g func(C) A) func(C) B {
    return func(c C) B {
        a := g(c)
        return f(a)
    }
}
```

Or a function that returns an error:

```go
func fmap(f func(A) B, g func() (*A, error)) func() (*B, error) {
    return func() (*B, error) {
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
Hmmm ... ok that does not help to explain it, it is too abstract.
And that is typically the problem with trying to explain what a `monad` is.
Its like trying to explain what "side effects" are, it is just too broad.
So lets rather explain the reason for the abstraction of a `monad`.
The reason is to compose functions that return these embellished types.

Lets start with plain function composition, without embellished types.
In this example, we want to compose two functions `f` and `g` and return a function that takes the input that is expected by `f` and returns the output from `g`:

```go
func compose(f func(A) B, g func(B) C) func(A) C {
    return func(a A) c {
        b := f(a)
        c := g(b)
        return c
    }
}
```

Obviously, this will only work if the output type of `f` matches the input type of `g`.

Another version of this would be composing functions that return errors.

```go
func compose(f func(*A) (*B, error), g func(*B) (*C, error)) 
    func(*A) (*C, error) {
    return func(a *A) (*C, error) {
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

```go
func compose(f func(A) M<B>, g func(B) M<C>) func(A) M<C> {
    return func(a A) M<C> {
        mb := f(a)
        // ...
        return mc
    }
}
```

We have to return a function that takes an `a` as an input parameter, so we start by declaring the return function.
Now that we have an `a`, we can call `f` and get and a value `mb` of type `M<b>`, but now what?

We fall short, because it is too abstract.
I mean now that we have `mb`, what do we do?

When we knew it was an error we could check it, but now that it is abstracted away, we can't.

But ... if we know that our embellishment `M` is also a `functor`, then we can `fmap` over `M`:

```go
type fmap = func(func(A) B, M<A>) M<B>
```

The function `g` that we want to `fmap` with does not return a simple type like `C` it returns `M<C>`.
Luckily this is not a problem for `fmap`, but it changes the type signature a bit:

```go
type fmap = func(func(B) M<C>, M<B>) M<M<C>>
```

So now we have a value `mmc` of type `M<M<C>>`:

```go
func compose(f func(A) M<B>, g func(B) M<C>) func(A) M<C> {
    return func(a A) M<C> {
        mb := f(a)
        mmc := fmap(g, mb)
        // ...
        return mc
    }
}
```

We need a way to go from `M<M<C>>` to `M<C>`.

We need our embellishment `M` to not just be a `functor`, but to also have another property.
This extra property is a function called `join` and is defined for each `monad`, just like `fmap` was defined for each `functor`.

```go
type join = func(M<M<C>>) M<C>
```

Given join, we can now write:

```go
func compose(f func(A) M<B>, g func(B) M<C>) func(A) M<C> {
    return func(a A) M<C> {
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

```go
type join = func(M<M<C>>) M<C>
```

We will now define `join` for:

  - lists, which will result in list comprehensions,
  - errors, which will result in monadic error handling and
  - channels, which will result in a concurrency pipeline.

### List Comprehensions

Join on a slice is the simplest and probably the easiest to start with.
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

Lets look at why we need `join` again, but focusing specifically on slices.
Here is our compose function again, but this time defined specifically for slices.

```go
func compose(f func(A) []B, g func(B) []C) func(A) []C {
    return func(a A) []C {
        bs := f(a)
        css := fmap(g, bs)
        cs := join(css)
        return cs
    }
}
```

If we pass `a` to `f` we get `bs` which is of type `[]B`.

We can now `fmap` over `[]B` with `g`, which will give us a value of type `[][]C` and not `[]C`:

```go
func fmap(g func(B) []C, bs []B) [][]C {
    css := make([][]C, len(bs))
    for i, b := range bs {
        css[i] = g(b)
    }
    return css
}
```

And that is why we need `join`.
We need to go from `css` to `cs` or from `[][]C` to `[]C`.

Lets take a look at a more concrete example:

If we substitute our types:

  - `A` for type `int`,
  - `B` for type `int64` and 
  - `C` for type `string`.

Then our functions become:

```go
func compose(f func(int) []int64, g func(int64) []string) 
    func(int) []string
```
```go
func fmap(g func(int64) []string, bs []int64) [][]string
```
```go
func join(css [][]string) []string
```

And then we can use them in our example:

```go
func upto(n int) []int64 { 
    nums := make([]int64, n)
    for i := range nums {
        nums[i] = int64(i+1)
    }
    return nums
}

func pair(x int64) []string {
    return []int{strconv.FormatInt(x, 10), strconv.FormatInt(-1*x, 10)}
}

c := compose(upto, pair)
c(3)
// "1","-1","2","-2","3","-3"
```

This makes a slice our first `monad`.

Interestingly this is exactly how list comprehensions work in Haskell:

```haskell
[ y | x <- [1..3], y <- [show x, show (-1 * x)] ]
```

But might know them from Python:

```python
def pair (x):
  return [str(x), str(-1*x)]

[y for x in range(1,4) for y in pair(x) ]
```

### Monadic Error Handling

We can also define `join` on functions which return a value and an error.
For this we first need to take a step back to the `fmap` function again, because of some idiosyncrasies in Go.

```go
type fmap = func(f func(B) C, g func(A) (B, error)) func(A) (C, error)
```

We know our compose function is going to call `fmap` with a function `f` that also returns an error.
This will result in our `fmap` signature looking something like this:

```go
type fmap = func(f func(A) (C, error), g func(A) (B, error)) 
    func(A) ((C, error), error)
```

Unfortunately tuples are not first class citizens in Go, so we can't write:

```go
((C, error), error)
```

There are a few ways to work around this problem.
I prefer using a function, since a function that returns a tuple is still a first class citizen:

```go
(func() (C, error), error)
```

Now we can define our `fmap` for functions which returns a value and an error, using our work around:

```go
func fmap(f func(B) (C, error), g func(A) (B, error)) 
    func(A) (func() (C, error), error) {
    return func(a A) (func() (C, error), error) {
        b, err := g(a)
        if err != nil {
            return nil, err
        }
        return func() (C, error) {
            return f(b)
        }
    }
}
```

Which brings us back to our main point, our `join` function on `(func() (c, error), error)`.
Its pretty simple and simply does one of the error checks for us.

```go
func join(f func() (C, error), err error) (C, error) {
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

Here is another [example](https://speakerdeck.com/rebeccaskinner/monadic-error-handling-in-go?slide=77), where I feel like Bart Simpson:

```go
func upgradeUser(endpoint, username string) error {
    getEndpoint := fmt.Sprintf("%s/oldusers/%s", endpoint, username)
    postEndpoint := fmt.Sprintf("%s/newusers/%s", endpoint, username)

    req, err := http.Get(genEndpoint)
    if err != nil {
        return err
    }
    data, err := ioutil.ReadAll(req.Body)
    if err != nil {
        return err
    }
    olduser, err := user.NewFromJson(data)
    if err != nil {
        return err
    }
    newuser, err := user.NewUserFromUser(olduser),
    if err != nil {
        return err
    }
    buf, err := json.Marshal(newuser)
    if err != nil {
        return err
    }
    _, err = http.Post(
        postEndpoint, 
        "application/json", 
        bytes.NewBuffer(buf,
    )
    return err
}
```

Technically `compose` could take more than two functions as parameters.
That means that we could chain all the above functions together in one call and rewrite the above example:

```go
func upgradeUser(endpoint, username string) error {
    getEndpoint := fmt.Sprintf("%s/oldusers/%s", endpoint, username)
    postEndpoint := fmt.Sprintf("%s/newusers/%s", endpoint, username)

    _, err := compose(
		http.Get,
		func(req *http.Response) ([]byte, error) {
			return ioutil.ReadAll(req.Body)
		},
		newUserFromJson,
		newUserFromUser,
		json.Marshal,
		func(buf []byte) (*http.Response, error) {
			return http.Post(
				postEndpoint,
				"application/json",
				bytes.NewBuffer(buf),
			)
		},
	)(getEndpoint)
    return err
}
```

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
			go func(inner <-chan T) {
				for t := range inner {
					out <- t
				}
				wait.Done()
			}(c)
		}
		wait.Wait()
		close(out)
	}()
	return out
}
```

Here we have a channel `in` that will feed us more channels of type `T`.
We first create our `out` channel and start up a go routine which we are going to use to feed the channel with and then return the `out` channel.
Inside the go routine we start up a new go routine for each incoming channel that we are reading from `in`.
This inner go routines will be used to listen to incoming events on a single channel and send all of these events to the `out` channel.
Then we wait for all the channels to be closed and close the `out` channel.

In short we are reading all `T`s from `in` and pushing them all to the `out` channel.

> Non Go programmers: I have to pass `c` as a parameter to the inner go routine, because `c` is a single variable that takes on the value of each element in the channel.  That means that if we just used it, inside the closure instead of creating a copy of the value by passing it as a parameter, we would probably only be reading from the newest channel.  [This is a common mistake made by go programmers](https://golang.org/doc/faq#closures_and_goroutines).

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

This was a very hand wavy explanation of `monads` and there are many things I intentionally left out, to keep things simpler, but there is one more thing that I would like to cover.

Technically our compose function defined in the previous section, is called the `Kleisli Arrow`.

```go
type kleisliArrow = func(func(A) M<B>, func(B) M<C>) func(A) M<C>
```

When people talk about `monads` they rarely mention the `Kleisli Arrow`, which was the key for me to understanding `monads`.
If you are lucky they explain it using `fmap` and `join`, but if you are unlucky, like me, they explain it using the bind function.

```go
type bind = func(M<B>, func(B) M<C>) M<C>
```

Why?

Because `bind` is the function in Haskell that you need to implement for your type if you want it to be considered a `Monad`.

Lets repeat our implementation of the compose function here:

```go
func compose(f func(A) M<B>, g func(B) M<C>) func(A) M<C> {
    return func(a A) M<C> {
        mb := f(a)
        mmc := fmap(g, mb)
        mc := join(mmc)
        return mc
    }
}
```

If the `bind` function was implemented then we could simply call it, instead of `fmap` and `join`.

```go
func compose(f func(A) M<B>, g func(B) M<C>) func(A) M<C> {
    return func(a A) M<C> {
        mb := f(a)
        mc := bind(mb, g)
        return mc
    }
}
```

Which means that `bind(mb, g)` = `join(fmap(g, mb))`.

The `bind` function for lists would be `concatMap` or `flatMap` depending on the language.

```go
func concatMap([]A, func(A) []B) []B
```

## Squinting

I found that Go started to blur the lines for me between `bind` and the `Kleisli Arrow`.
Go returns an error in a tuple, but a tuple is not a first class citizen.
For example this code will not compile, because you cannot pass `f`'s results to `g`, in an in-line way:

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

```go
type bind = func(M<B>, func(B) M<C>) M<C>
```

as defined for errors:

```go
type bind = func(b B, err error, g func(B) (C, error)) (C, error)
```

will not be fun to use, unless we squash that tuple into a function:

```go
type bind = func(f func() (B, error), g func(B) (C, error)) (C, error)
```

If we squint we can see our returning tuple as a function as well:

```go
type bind = func(f func() (B, error), g func(B) (C, error)) func() (C, error)
```

And if we squint again, then we can see that this is our compose function, where `f` just takes zero parameters:

```go
type compose = func(f func(A) (B, error), g func(B) (C, error)) func(A) (C, error)
```

Ta da, we have our `Kleisli Arrow`, by just squinting a few times.

```go
type compose = func(f func(A) M<B>, g func(B) M<C>) func(A) M<C>
```

## Conclusion

Monads hide some of the repeated logic of composing functions with embellished types, so that you don't have to feel like Bart Simpson in detention, but rather like Bart Simpson on his skateboard.

![Missing image of Bart Simpson on his skateboard](http://awalterschulze.github.io/blog/monads-for-goprogrammers/bartskate.jpg "separation of church and skate")

If you want to try `monads` and other functional programming concepts in Go, then you can do it using my code generator, [GoDerive](https://github.com/awalterschulze/goderive).

> Warning:  One of the key concepts of functional programming is immutability.  This not only makes programs easier to reason about, but also allows for compiler optimizations.  To simulate this immutability, in Go, you will tend to copy lots of structures that will lead to non optimal performance.  The reason functional programming languages gets away with this is exactly because they can rely on the immutability and always point to the old values, instead of copying them again.

> If you really want to transition to functional programming, I would recommend [Elm](http://elm-lang.org/).  Its a statically typed functional programming language for the front-end.  It is as easy to learn as is Go to learn for an imperative language.  I did this [guide](https://guide.elm-lang.org/) in a day and I was able to start being productive that evening.  The creator went out of his way to make it an easy to learn language by even removing the need to understand monads.  I have personally found `Elm` a joy to use in the front-end in conjunction with Go in back-end.  If you start feeling bored in Go and Elm, don't worry there is much more to learn, Haskell is waiting for you.

Thank you:

  - [Johan Brandhorst](https://jbrandhorst.com/) for proof reading and pushing me to write a blog.
  - [Ryan Lemmer](https://github.com/uroboros) for proof reading and the line on "side effects".
  - [Anton Hendriks](https://www.linkedin.com/in/anton-hendriks-1b549514/) for proof reading.