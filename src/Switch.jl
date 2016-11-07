"""
    Wrap(value)
    Wrap{T}()

A wrapper which makes it convenient to instantiate without unitializing memory.
Used internally by `Switch`.
"""
immutable Wrap{T}
    value::T

    Wrap(v::T) = new(v)
    Wrap(v) = new(convert(T,v))
    Wrap() = new()
end

(::Type{Wrap}){T}(v::T) = Wrap{T}(v)

Base.show{T}(io::IO, x::Wrap{T}) = print(io, "Wrap(", x.value, ")")


"""
    Switch{A,B}(value::Union{A,B})

Create an single-element storage container which can contain one of two possible
input types. Semantically this type has similarities with `Union{A,B}`, but is
optimized for faster dispatch.

Using the `Switch` instance under `broadcast` is efficient and type-stable, and
is convenient to use with "dot-call" syntax. For example

    x = Switch{Int, Float64}(1)
    x .+ 1    # = Switch{Int, Float64}(2)
    x .+ 1.0  # = 2.0 (automatically fall back to simple type where possible)
"""
immutable Switch{A,B}
    which::Bool
    a::Wrap{A}
    b::Wrap{B}

    Switch(a::A) = new(true,  Wrap{A}(a), Wrap{B}())
    Switch(b::B) = new(false, Wrap{A}(),  Wrap{B}(b))
end

Base.show{A,B}(io::IO, x::Switch{A,B}) = x.which ? print(io, "Switch{A,B}(", x.a.value, ")") : print(io, "Switch{A,B}(", x.b.value, ")")

# broadcast methods
size(::Switch) = ()

getindex(x::Switch) = x.which ? x.a.value : x.b.value # not type-stable

@pure switchtype{A}(::Type{A}, ::Type{A}) = A
@pure switchtype{A,B}(::Type{A}, ::Type{B}) = Switch{A,B}
@pure switchtype{A,B}(::Type{Switch{A,B}}, ::Type{A}) = Switch{A,B}
@pure switchtype{A,B}(::Type{Switch{A,B}}, ::Type{B}) = Switch{A,B}
@pure switchtype{A,B}(::Type{A}, ::Type{Switch{A,B}}) = Switch{A,B}
@pure switchtype{A,B}(::Type{B}, ::Type{Switch{A,B}}) = Switch{A,B}
@pure switchtype{A,B}(::Type{Switch{A,B}}, ::Type{Switch{A,B}}) = Switch{A,B}
@pure switchtype{A,B}(::Type{Switch{A,B}}, ::Type{Switch{B,A}}) = Switch{A,B}

switchtype{A,B,C}(::Type{Switch{A,B}}, ::Type{C}) = error("Switches with more than two types is not supported")
switchtype{A,B,C}(::Type{C}, ::Type{Switch{A,B}}) = error("Switches with more than two types is not supported")
@pure switchtype{A,B,C,D}(::Type{Switch{A,B}}, ::Type{Switch{C,D}}) = error("Switches with more than two types is not supported")

@inline function broadcast{A,B}(f, x::Switch{A,B})
    A2 = promote_op(f, A)
    B2 = promote_op(f, B)
    out_type = switchtype(A2,B2)

    if out_type <: Switch
        return x.which ? out_type(f(x.a.value)) : out_type(f(x.b.value))
    else
        return x.which ? f(x.a.value) : f(x.b.value)
    end
end

@inline function broadcast{A,B,C,D}(f, x::Switch{A,B}, y::Switch{C,D})
    T1 = promote_op(f, A, C)
    T2 = promote_op(f, A, D)
    T3 = promote_op(f, B, C)
    T4 = promote_op(f, B, D)
    out_type = switchtype(switchtype(switchtype(T1,T2),T3),T4)

    if out_type <: Switch
        return x.which ? (y.which ? out_type(f(x.a.value, y.a.value)) :
                                    out_type(f(x.a.value, y.b.value))) :
                         (y.which ? out_type(f(x.b.value, y.a.value)) :
                                    out_type(f(x.b.value, y.b.value)))
    else
        return x.which ? (y.which ? f(x.a.value, y.a.value) :
                                    f(x.a.value, y.b.value)) :
                         (y.which ? f(x.b.value, y.a.value) :
                                    f(x.b.value, y.b.value))
    end
end

@inline function broadcast{A,B}(f, x::Switch{A,B}, y)
    T1 = promote_op(f, A, typeof(y))
    T2 = promote_op(f, B, typeof(y))
    out_type = switchtype(T1,T2)

    if out_type <: Switch
        return x.which ? out_type(broadcast(yi -> f(x.a.value, yi), y)) : out_type(broadcast(f(x.b.value, yi), y)))
    else
        return x.which ? broadcast(yi -> f(x.a.value, yi), y) : yi -> broadcast(f(x.b.value, yi), y))
    end
end

@inline function broadcast{A,B}(f, x, y::Switch{A,B})
    T1 = promote_op(f, typeof(x), A)
    T2 = promote_op(f, typeof(x), B)
    out_type = switchtype(T1,T2)

    if out_type <: Switch
        return y.which ? out_type(broadcast(xi -> f(xi, y.a.value), x)) : out_type(broadcast(xi -> f(xi, y.b.value), x))
    else
        return y.which ? broadcast(xi -> f(xi, y.a.value), x) : broadcast(xi -> f(xi, y.b.value), x)
    end
end


@inline Base.:(.+){A,B,C,D}(x::Switch{A,B}, y::Switch{C,D}) = broadcast(+, x, y)
@inline Base.:(.+){A,B}(x::Switch{A,B}, y) = broadcast(+, x, y)
@inline Base.:(.+){C,D}(x, y::Switch{C,D}) = broadcast(+, x, y)

@inline Base.:(.*){A,B,C,D}(x::Switch{A,B}, y::Switch{C,D}) = broadcast(*, x, y)
@inline Base.:(.*){A,B}(x::Switch{A,B}, y) = broadcast(*, x, y)
@inline Base.:(.*){C,D}(x, y::Switch{C,D}) = broadcast(*, x, y)

@inline Base.:(.-){A,B,C,D}(x::Switch{A,B}, y::Switch{C,D}) = broadcast(-, x, y)
@inline Base.:(.-){A,B}(x::Switch{A,B}, y) = broadcast(-, x, y)
@inline Base.:(.-){C,D}(x, y::Switch{C,D}) = broadcast(-, x, y)

@inline Base.:(./){A,B,C,D}(x::Switch{A,B}, y::Switch{C,D}) = broadcast(/, x, y)
@inline Base.:(./){A,B}(x::Switch{A,B}, y) = broadcast(/, x, y)
@inline Base.:(./){C,D}(x, y::Switch{C,D}) = broadcast(/, x, y)

@inline Base.:(.//){A,B,C,D}(x::Switch{A,B}, y::Switch{C,D}) = broadcast(//, x, y)
@inline Base.:(.//){A,B}(x::Switch{A,B}, y) = broadcast(//, x, y)
@inline Base.:(.//){C,D}(x, y::Switch{C,D}) = broadcast(//, x, y)

@inline Base.:(.%){A,B,C,D}(x::Switch{A,B}, y::Switch{C,D}) = broadcast(%, x, y)
@inline Base.:(.%){A,B}(x::Switch{A,B}, y) = broadcast(%, x, y)
@inline Base.:(.%){C,D}(x, y::Switch{C,D}) = broadcast(%, x, y)
