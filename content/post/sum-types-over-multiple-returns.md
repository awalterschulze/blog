---
title: "For Sum Types: Golang's multiple return parameters are overrated"
date: 2017-09-25T13:32:51+02:00
tags: ["algebraic data types", "golang", "sum types", "tuples"]
---

# For Sum Types: Golang's multiple return parameters are overrated

In this Go Experience Report I am going to make a case for sum types over multiple return parameters.

## Analysis of multiple return parameters

I wrote a little tool which does some analysis of Go source code:

https://github.com/awalterschulze/goanalysis

Thank you to the `go/types` library.

The tool simply counts the number of times multiple return parameters are used.
I ran this tool over the standard library and these are the results:

```
$ goanalysis std

functions with N return arguments:
-----------------------------
returns | number of functions
      0 | 8693
      1 | 7743
      2 | 1975
      3 | 205
      4 | 25
      5 | 4
      6 | 1
      7 | 1
-----------------------------

total number of functions: 18647
total number of functions with multiple return parameters: 2211
number of functions with 2 return arguments, where the second argument is an error: 1562

percentage of functions where multiple return parameters are really what we want: 3.480453
```

These results show us two things:

  - most functions return zero or one argument.
  - most functions with multiple return parameters return a value `and` an error.

Only 3.5% of functions actually use multiple return parameters.

The tool does not count functions that return a value `and` an error as a proper use of multiple return parameters.

This is because I think we should rather have sum, union or algebriac data types for this use case.

I believe that most of the time we return:

  - a value `and` a nil error, or
  - a nil or zero value `and` a non nil error

, which means that we would rather return a value `or` an error, than a value `and` an error.

## Tuples are not first class citizens

In the `go/types` library I found that multiple return parameters are actually called [Tuples](https://golang.org/pkg/go/types/#Tuple), 
but these Tuples are not first class citizens.

For example nested tuples are currently not supported:

```go
func() ((string, error), error)
```

I ran into this while building monadic error handling in [goderive](https://github.com/awalterschulze/goderive).
I worked around this by using a function:

```go
func() (func() (string, error), error)
```

, which is not ideal, since a function implies some computation.

We currently also cannot directly pass multiple return parameters to a function:

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

I also ran into this usecase while building [monadic error handling](https://awalterschulze.github.io/blog/post/monads-for-goprogrammers/) for Go.

## We need sum types

Firstly, we need sum types to return a value `or` an error, instead of a value `and` an error from functions, but we need sum types for other reasons as well.

In, my validation language, [Relapse's Abstract Syntax Tree](https://github.com/katydid/katydid/blob/1eaef3ef662fd6431dea1ae4937bbae500b3be53/relapse/ast/relapse.pb.go#L143-L157), each Pattern can be one of several Patterns:

```go
type Pattern struct {
	Empty      *Empty
	TreeNode   *TreeNode
	LeafNode   *LeafNode
	Concat     *Concat
	Or         *Or
	And        *And
...
```

Here I simulate a sum type with a struct which has several fields (a product type) where only one field should be non nil.  This is not ideal in terms of type safety.  For instance when writing a function that processes a pattern, I have to do a nil check for each field:

```go
func Nullable(refs ast.RefLookup, p *ast.Pattern) bool {
    if p.Empty != nil {
        return true
    } else if p.TreeNode != nil {
        return false
    } else if p.LeafNode != nil {
        return false
    } else if p.Concat != nil {
        return Nullable(refs, p.Concat.GetLeftPattern()) && Nullable(refs, p.Concat.GetRightPattern())
    } else if p.Or != nil {
        return Nullable(refs, p.Or.GetLeftPattern()) || Nullable(refs, p.Or.GetRightPattern())
    } else if p.And != nil {
        return Nullable(refs, p.And.GetLeftPattern()) && Nullable(refs, p.And.GetRightPattern())
    ...
```

This is fine, but when I add a new pattern the compiler is not going to tell me that I forgot to update one of these functions.

I opted for [another implementation, using a type switch](https://github.com/katydid/katydid/blob/1eaef3ef662fd6431dea1ae4937bbae500b3be53/relapse/interp/nullable.go#L24), but it only works because each field is of a unique type and I still have the runtime time type check problem.

This pushes Go to be a strong dynamically typed language, rather a strong statically typed language, which I would prefer to use.

The use of an interface as a way to simulate a sum type can also be found in a [Protocol buffers library for Go](https://github.com/golang/protobuf/blob/157d9c53be5810dd5a0fac4a467f7d5f400042ea/proto/testdata/test.pb.go#L2142) where they have to implement `oneof`.  

From this proto message:
```proto
message MyMessage {
  oneof BoolOrInt {
    bool BoolValue = 1;
    int32 Int32Value = 2;
  }
}
```

The following go code is generated:
```go
type MyMessage struct {
	BoolOrInt isMyMessage_BoolOrInt
}

type isMyMessage_BoolOrInt interface {
	isMyMessage_BoolOrInt()
}

type MyMessage_BoolValue struct {
	BoolValue bool
}
type MyMessage_Int32Value struct {
	Int32Value int32
}

func (*MyMessage_BoolValue) isMyMessage_BoolOrInt()        {}
func (*MyMessage_Int32Value) isMyMessage_BoolOrInt()       {}
```

This implementation is far from ideal, in my and others' opinion.
In an alternative Protocol buffer library for Go, [developers cannot even agree](https://github.com/gogo/protobuf/issues/168) on what they would really like to have as a `oneof` implementation in Go, because Go does not lend itself to sum types.

A need for sum types can also be found in the [go/ast](https://golang.org/pkg/go/ast/#Spec) library, where Spec is documented to be one of the following types:
  - `*ImportSpec`,
  - `*ValueSpec` or
  - `*TypeSpec`
which is something that could have been enforced by the compiler, instead of mere documentation.

Another such an instance is the [Walk function](https://golang.org/src/go/ast/walk.go?s=1311:1342#L41), which ends with classic runtime error, where a compile error would have been more appropriate:

```go
default:
  panic(fmt.Sprintf("ast.Walk: unexpected node type %T", n))
}
```

## Conclusion

In Conclusion, I have shown that multiple return parameters are overrated, since:

  - it is rarely used for the right reason and
  - it is not even a first class citizen.

I have also demonstrated several use cases for sum types:

  - proper error handling
  - in the implementation of languages, and
  - protocol buffers
  
, but I know there are `MANY` more.

I think a Go without multiple return parameters and with first class sum types would make for a better language.