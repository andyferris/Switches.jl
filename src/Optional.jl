
"""
    x = Unknown(T)

Constructs the Julia singleton `Unknown{T}()` which semantically represents that
`x` is equal to some instance of `T`, but which one is unknown. It represents
missing data rather than non-existance.

`Unknown` is used by the `Optional` type, which itself is a typealias for
a `Switch`.
"""
immutable Unknown{T}
end

(::Type{Unknown}){T}(::Type{T}) = Unknown{T}()

Base.show{T}(io::IO, ::Unknown{T}) = print(io, "Unknown(", T, ")")

"""
    Optional{T}(value)
    Optional{T}()

Construct an `Optional` container that contains either `value::T` or
`Unknown{T}()`.

This differs semantically from `Base.Nullable{T}` in that an `Unknown` state
means that some value `T` exists but is not known to the program, while a
null-valued `Nullable` represents the absence of a value. This subtle difference
allows us to implement 3-valued logic on `Optional{Bool}`, for example.
"""
typealias Optional{T} Switch{T,Unknown{T}}

(::Type{Optional})(x) = Optional{typeof(x)}(x)
(::Type{Optional{T}}){T}() = Optional{T}(Unknown{T}())

hasvalue{T}(x::Optional{T}) = x.which
get{T}(x::Optional{T}) = x.a.value

Base.show{T}(io::IO, x::Optional{T}) = hasvalue(x) ? print(io, "Optional(", get(x), ")") : print(io, "Optional{", T ,"}()")


# Three-valued logic
@inline Base.:!(::Unknown{Bool}) = Unknown{Bool}()

@inline Base.:&(::Unknown{Bool}, ::Unknown{Bool}) = Unknown{Bool}()
@inline Base.:&(x::Bool, ::Unknown{Bool}) = x ? Optional{Bool}() : Optional{Bool}(false)
@inline Base.:&(::Unknown{Bool}, y::Bool) = y ? Optional{Bool}() : Optional{Bool}(false)

@inline Base.:|(::Unknown{Bool}, ::Unknown{Bool}) = Unknown{Bool}()
@inline Base.:|(x::Bool, ::Unknown{Bool}) = x ? Optional{Bool}(true) : Optional{Bool}()
@inline Base.:|(::Unknown{Bool}, y::Bool) = y ? Optional{Bool}(true) : Optional{Bool}()

@inline Base.:$(::Unknown{Bool}, ::Unknown{Bool}) = Unknown{Bool}()
@inline Base.:$(x::Bool, ::Unknown{Bool}) = Unknown{Bool}()
@inline Base.:$(::Unknown{Bool}, y::Bool) = Unknown{Bool}()


# Basic arrithmetic operators
@inline Base.:-{T<:Number}(::Unknown{T}) = Unknown{promote_op(-,T)}()

@inline Base.:+{T1<:Number, T2<:Number}(::Unknown{T1}, ::Unknown{T2}) = Unknown{promote_op(+,T1,T2)}()
@inline Base.:+{T1<:Number, T2<:Number}(::T1, ::Unknown{T2}) = Unknown{promote_op(+,T1,T2)}()
@inline Base.:+{T1<:Number, T2<:Number}(::Unknown{T1}, ::T2) = Unknown{promote_op(+,T1,T2)}()

@inline Base.:-{T1<:Number, T2<:Number}(::Unknown{T1}, ::Unknown{T2}) = Unknown{promote_op(-,T1,T2)}()
@inline Base.:-{T1<:Number, T2<:Number}(::T1, ::Unknown{T2}) = Unknown{promote_op(-,T1,T2)}()
@inline Base.:-{T1<:Number, T2<:Number}(::Unknown{T1}, ::T2) = Unknown{promote_op(-,T1,T2)}()

@inline Base.:*{T1<:Number, T2<:Number}(::Unknown{T1}, ::Unknown{T2}) = Unknown{promote_op(*,T1,T2)}()
@inline Base.:*{T1<:Number, T2<:Number}(::T1, ::Unknown{T2}) = Unknown{promote_op(*,T1,T2)}()
@inline Base.:*{T1<:Number, T2<:Number}(::Unknown{T1}, ::T2) = Unknown{promote_op(*,T1,T2)}()

@inline Base.:/{T1<:Number, T2<:Number}(::Unknown{T1}, ::Unknown{T2}) = Unknown{promote_op(/,T1,T2)}()
@inline Base.:/{T1<:Number, T2<:Number}(::T1, ::Unknown{T2}) = Unknown{promote_op(/,T1,T2)}()
@inline Base.:/{T1<:Number, T2<:Number}(::Unknown{T1}, ::T2) = Unknown{promote_op(/,T1,T2)}()

@inline Base.://{T1<:Number, T2<:Number}(::Unknown{T1}, ::Unknown{T2}) = Unknown{promote_op(//,T1,T2)}()
@inline Base.://{T1<:Number, T2<:Number}(::T1, ::Unknown{T2}) = Unknown{promote_op(//,T1,T2)}()
@inline Base.://{T1<:Number, T2<:Number}(::Unknown{T1}, ::T2) = Unknown{promote_op(//,T1,T2)}()

@inline Base.:\{T1<:Number, T2<:Number}(::Unknown{T1}, ::Unknown{T2}) = Unknown{promote_op(\,T1,T2)}()
@inline Base.:\{T1<:Number, T2<:Number}(::T1, ::Unknown{T2}) = Unknown{promote_op(\,T1,T2)}()
@inline Base.:\{T1<:Number, T2<:Number}(::Unknown{T1}, ::T2) = Unknown{promote_op(\,T1,T2)}()

@inline Base.:%{T1<:Number, T2<:Number}(::Unknown{T1}, ::Unknown{T2}) = Unknown{promote_op(%,T1,T2)}()
@inline Base.:%{T1<:Number, T2<:Number}(::T1, ::Unknown{T2}) = Unknown{promote_op(%,T1,T2)}()
@inline Base.:%{T1<:Number, T2<:Number}(::Unknown{T1}, ::T2) = Unknown{promote_op(%,T1,T2)}()
