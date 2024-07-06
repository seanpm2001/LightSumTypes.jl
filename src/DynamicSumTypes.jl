
module DynamicSumTypes

export @sumtype

unwrap(sumt) = getfield(sumt, :variants)

"""
    @sumtype SumTypeName(Types) [<: AbstractType]

The macro creates a sumtypes composed by the given types.
It optionally accept also an abstract supertype.

## Example
```julia
julia> using DynamicSumTypes

julia> struct A x::Int end;

julia> struct B end;

julia> @sumtype AB(A, B)
```
"""
macro sumtype(typedef)

    if typedef.head === :call
        abstract_type = :Any
        type_with_variants = typedef
    elseif typedef.head === :(<:)
        abstract_type = typedef.args[2]
        type_with_variants = typedef.args[1]
    else
        error("Invalid syntax")
    end

    type = type_with_variants.args[1]
    variants = type_with_variants.args[2:end]

    esc(quote
            struct $type <: $(abstract_type)
                variants::Union{$(variants...)}
                $type(v) = $(branchs(variants, :(return new(v)))...)
            end
            function variant(sumt::$type)
                v = DynamicSumTypes.unwrap(sumt)
                $(branchs(variants, :(return v))...)
            end
            function Base.getproperty(sumt::$type, s::Symbol)
                v = DynamicSumTypes.unwrap(sumt)
                $(branchs(variants, :(return getproperty(v, s)))...)
            end
            function Base.setproperty!(sumt::$type, s::Symbol, value)
                v = DynamicSumTypes.unwrap(sumt)
                $(branchs(variants, :(return setproperty!(v, s, value)))...)
            end
            function Base.propertynames(sumt::$type)
                v = DynamicSumTypes.unwrap(sumt)
                $(branchs(variants, :(return propertynames(v)))...)
            end
            function Base.show(io::IO, ::MIME"text/plain", sumt::$type)
                v = DynamicSumTypes.unwrap(sumt)
                print(string($type), "'.", string(v))                
            end
            allvariants(sumt::Type{$type}) = tuple($(variants...))
    end)
end 

function branchs(variants, outputs)
    if !(outputs isa Vector)
        outputs = repeat([outputs], length(variants))
    end
    branchs = [Expr(:if, :(v isa $(variants[1])), outputs[1])]
    for i in 2:length(variants)
        push!(branchs, Expr(:elseif, :(v isa $(variants[i])), outputs[i]))
    end
    push!(branchs, :(error("THIS_SHOULD_BE_UNREACHABLE")))
    return branchs
end

"""
    variant(inst)

Returns the variant enclosed in the sum type.

## Example
```julia
julia> using DynamicSumTypes

julia> struct A x::Int end;

julia> struct B end;

julia> @sumtype AB(A, B)

julia> a = AB(A(0))
AB'.A(0)

julia> variant(a)
A(0)
```
"""
function variant end

"""
    allvariants(SumType)

Returns all the enclosed variants types in the sum type
in a tuple.
  
## Example
```julia
julia> using DynamicSumTypes

julia> struct A x::Int end;

julia> struct B end;

julia> @sumtype AB(A, B)

julia> allvariants(AB)
(A, B)
```
"""
function allvariants end

end
