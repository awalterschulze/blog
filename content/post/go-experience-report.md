---
title: "Go Experience Report: from a code generator developer [DRAFT]"
date: 2017-01-01T12:19:12+02:00
tags: ["generator", "golang", "go2"]
---

## Introduction

I have written many code generators for go, these include:

  - [gogoprotobuf](https://github.com/gogo/protobuf) - Protocol Buffers for Go with Gadgets
  - [goderive](https://github.com/awalterschulze/goderive) - Derives functions from their input parameters
  - [gocc](https://github.com/goccmack/gocc) - Parser / Scanner Generator ( only a maintainer, not a creator )
  - [a](https://github.com/katydid/katydid/blob/master/gen/gen.go) [few](https://github.com/katydid/katydid/blob/master/parser/parser-gen/main.go) [project](https://github.com/katydid/katydid/blob/master/parser/debug/debug-gen/main.go) [specific](https://github.com/katydid/katydid/blob/master/relapse/compose/compose-gen/main.go) [ones](https://github.com/katydid/katydid/blob/master/relapse/funcs/funcs-gen/main.go) and
  - some proprietary ones

Code generation is my hammer and Go is my nail.

I would like to talk about my experience developing `goderive` and explain what I would like in Go 2 as a developer of code generators.

## GoDerive inspiration

`goderive` derives mundane Go functions that you do not want to maintain and keeps them up to date.  It does this by parsing your go code for functions which are not implemented and then generates these functions for you by deriving their implementations from the parameter types.

`goderive` was inspired by Haskell's deriving and some other things that I missed from Haskell, when I was developing a [validation language in Go](https://github.com/katydid/katydid) and [Haskell](https://github.com/katydid/katydid-haskell).

This code generator would not have been possible without the [go/types](https://golang.org/pkg/go/types/) library.  Actually, I have been waiting for the `go/types` library to become official for about six years.  The fact that it did not exist, when we needed fast serialization, was one of the mayor reasons for the existence of `gogoprotobuf`.  I prefered generating code from the FileDescriptorSet provided by `protoc` over using the `go/ast` library.  I have to give a compliment to the developers of `go/types`, it was totally worth the wait.

The final piece of the puzzle clicked when Robert Griesemer gave his talk on [Prototype your design!](https://www.youtube.com/watch?v=vLxX3yZmw5Q).  This showed that you could parse go code and infer types, even though the there were errors in the code, simply using some config.

```go
func load(paths ...string) (*loader.Program, error) {
    conf := loader.Config{
        ...
        AllowErrors: true,
    }
    conf.TypeChecker.Error = func(err error) {}
    ... := conf.FromArgs(paths, true)
    ...
    return conf.Load()
}
```

## Why Functions and not Methods

Finally, some design discussions with [Pascal S. de Kloe](https://github.com/pascaldekloe) pushed me to generate functions, instead of methods.
It all started with the `Equal` method and what the generated type signature should be:

Option 1: probably the most likely

```go
func (this *MyStruct) Equal(that *MyStruct) bool
```

Option 2: meant that it could be part of some interface
```go
type Eq interface {
    Equal(interface{}) bool
}

func (this *MyStruct) Equal(that interface{}) bool
```

Option 3: a union type
```go
func (this *MyStruct) Equal(that OneOfStructs) bool
```

All these options become even harder when you look at the `compare` function.
If I only generate a function, then I don't have to make this decision.  All of these options are then supported with minimal code from the user.

```go
func (this *MyStruct) Equal(that interface{}) bool {
    s, ok := that.(*MyStruct)
    if !ok {
        return false
    }
    return deriveEqual(this, s)
}
```

This choice resulted in some unforeseen upsides:

  1. The first being that I did not need to ask the user to provide any hints (comments or tags) to ask the generator to generate some code.
  2. I got parametric polymorphism and did not have to worry about subtypes.  I could leave this to the user in his method specification.  To be fair, in the recursive functions the `goderive` generator does not support interfaces, exactly because then it becomes really difficult and you have to start worrying about subtyping vs parametric polymorphism.

# BuiltIn Function Values

One of the first things I noticed when developing GoDerive is something almost at the bottom of the Go spec.

> The built-in functions do not have standard Go types, so they can only appear in call expressions; they cannot be used as function values. - https://golang.org/ref/spec#Built-in_functions

I wanted to write:

```go
deriveCurry(deriveEqual)(this)
```

The `deriveEqual` function did not have any input types, so the Go language could not infer its type, which meant that `deriveCurry` could not infer its input type.
I went into the `go/types` library to try and find out how this is done for `append` and other generic/builtin functions and thats when I came upon the spec, [which meant that I couldn't solve this.](https://github.com/awalterschulze/goderive/issues/10)

This reminded me of [APL](https://en.wikipedia.org/wiki/APL_(programming_language)), which has higher order functions that are represented by graphical symbols, for example:

  - ceiling ⌈
  - log ⍟

which means that you can order special keyboards with which to program in `APL`.

![Missing image of an APL keyboard](http://awalterschulze.github.io/blog/go-experience-report/us_rc.jpg "Have languages come a long way?")

I remember how I laughed at [APL](https://en.wikipedia.org/wiki/APL_(programming_language)), because higher order functions can only be defined by the language maintainers.

Now I have to laugh at the language I love and how, even with a code generator, we can't really have generics, because of this limitation.
Only the language maintainers can define generic functions.

To be fair, even the Go maintainers can't define a truly generic function.

```go
func apply(f func(c, d []int) int, a, b []int) {
    f(a, b)
}

func main() {
    a, b := []int{1,2}, []int{3, 4}	
    apply(copy, a, b)
}
```

```text
use of builtin copy not in function call
```

So at least we are all in the same boat, which is much fairer than `APL`.

# Why and do we have Tuples?

The next thing I noticed was while trying to implement monadic error handling.
Go has multiple return parameters, which almost always just gets used for error handling.
Multiple return values allows us to return a value `and` an error

```go
func() (value, error)
```

, but what we really want is to return is a value `or` an error.  

```go
func() (value | error)
```

So actually, I don't think we need multiple return values.  I think this is a feature we can *remove* and replace with algebraic data types.  

I am not saying it will be easy, but it could make type switches safer.
There are quite a few use cases for misusing interfaces, because we actually wanted pattern matching.  If you have ever done this, then you actually wanted algebraic data types:

```go
type MyMessage interface {
    IsMessage()
}
```

This could be a thing of the past:
```go
func action(mymsg MyMessage) {
    switch mymsg.(type) {
    case *msgX:
        ...
    case *msgY:
        ...
    default:
        panic("unreachable")
    }
```

What you actually wanted was this:
```go
func action(mymsg MyMessage) {
    switch mymsg.(MyMessage) {
    case *msgX:
        ...
    case *msgY:
        ...
    }
```

And the compiler to tell you that you forgot about `*msgZ`.

Also interestingly enough, even though we have multiple return parameters, they are referred to in the `go/types` library as [tuples](https://golang.org/pkg/go/types/#Tuple).  They are also used for function parameters and multiple assignments.

But why aren't they first class citizens.

When developing monadic error handling, I wanted to write:

```go
((value, error), error)
```

But this is not supported, so I chose to settle for:

```go
(func() (value, error), error)
```

Since functions that return tuples are first class citizens.

# Interfaces are {}

Ok so I am a bit biased here, because interfaces make it hard to generate code, since you can't infer their type at compile time.

But when I am programming normally and not generating code, then they still bother me and not only as I mentioned that they are a hack to support union types.

But also, it would be more intuitive for the programmer if an interface was represented by their definition and not by their name:

  - https://github.com/golang/go/issues/8082
  - https://github.com/golang/go/issues/8691

But if you read these issues, this request is not as simple as it seems.

My fourth reason I don't like interfaces, is that they are probably the hardest thing to design orthogonally with generics.

# Conclusion

  - The `go/types` library is awesome
  - I would like to have built-in function values, so that the type system can support a smarter code generator.
  - Replace multiple return values and non first class tuples with algebraic data types.
  - Consider removing interfaces
