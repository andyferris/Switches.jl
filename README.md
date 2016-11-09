# Switches

*Faster dynamical dispatch and efficient "optionals" for Julia*

[![Build Status](https://travis-ci.org/andyferris/Switches.jl.svg?branch=master)](https://travis-ci.org/andyferris/Switches.jl)
[![Coverage Status](https://coveralls.io/repos/andyferris/Switches.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/andyferris/Switches.jl?branch=master)
[![codecov.io](http://codecov.io/github/andyferris/Switches.jl/coverage.svg?branch=master)](http://codecov.io/github/andyferris/Switches.jl?branch=master)

## `Switch`: organizing dispatch

A `Switch` is a one-element container that may contain one of two possible types.
For instance, a `Switch{Int, Float64}` is a wrapper container around a number
which is either an `Int` or a `Float64`.

This type differs from `Union{Int, Float64}` in two important respects:

 * It is a container, so its value needs to be fetched, mapped or broadcasted
   over (possibly with dot-call syntax).
 * The `broadcast` method is extended to use type-stable routines. Dynamic
   dispatch is determined by a simple binary branch, rather than the Julia's
   slower dynamic multiple dispatch algorithm.

Under `broadcast` and Julia's powerful dot-call syntax, it allows for some
powerful manipulations. The type automatically simplifies wherever possible, for
example:

```julia
x = Switch{Int, Float64}(1)
x .+ 1     # = Switch{Int, Float64}(2)
x .+ 1.0   # = 2.0 (it is a Float64 in either case)
```

While the value inside a `Switch` `x` can be accessed via `x[]` this is not
type-stable and should be avoided in performance-sensitive situations.

## `Optional` and `Unknown`: a data-friendly alternative to `Nullable`

Julia's in-built `Nullable` type is often semantically compared to a container
with either zero or one value. This is particularly useful when an object *might
not exist*, for instance a system resource may or may not be initialized or
available.

On the other hand, data scientists and others might like to deal with
data which *exists in principle* but is *unknown*. The `Optional{T}` container
is a single-element container that contains a single `value::T`, or else `Unknown(T)`.
`Unknown(T)` represents an element of `T` which is unknown to the computer
program. `Optional{T}` is a simple typealias of `Switch{T, Unknown{T}}` and
therefore uses the same algorithms for speed and the same dot-call syntax for
convenience (like both `Nullable` and `Switch`, unwrapping the container to
access the value is mandatory).

One example of where the distinction between `Nullable` and `Optional` is in
performing three-valued logic, where for instance logic dictates that
`true | Unknown(Bool)` is always `true`. However, as the result of
`false | Unknown(Bool)` is unknown, we wrap *both* results in an
`Optional{Bool}` to provide type stability and speed.

On the other hand, broadcasting over a `Nullable{Bool}` is unable to result in
three-valued logic. If an empty (i.e. null) container is passed to `broadcast`, the
output must always be an empty (i.e. null) container. It follows that
`broadcast(|, Nullable(true), Nullable{Bool}())` must equal `Nullable{Bool}()`.

In many senses `Optional` is a compromise between `Base.Nullable` and the
`DataArrays` pacakge and its `NA` object. Like `NA`, users can extend function
methods for the `Unknown` type to facilitate correct propagation of `Optional`
broadcasts through your code. The fact that `Unknown{T}` is parameterized by a
type helps one to reason about the output of such specializations (for instance,
`Unknown{Bool}` must represent either `true` or `false`).

### Acknowledgement

I thank Tim Holy for inspiration on performant dynamic dispatch.
