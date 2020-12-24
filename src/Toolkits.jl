__precompile__()


module Toolkits

export @pip, @pipas, changesub, @activate

import Pkg

const sub = :(_)

function __init__()
    println("Substitution = $sub")
end  # function __init__

"""
    @activate(env, shared::Bool=true)
    @activate()

Access `Pkg.activate`, without quoting environment name. Default value of `shared` is true.
If no arguments are given, it will call `Pkg.activate()` and activate default environment, `@x.x`.
If / is given, it will activate environment at current path. If current path is a project, it will activate the project environment. 
If a unquoted argument is given, it will activate an environment in [./.julia/environments](./.julia/environments). If the environment has already existed, it will activate it.
"""
macro activate(env, shared::Bool = true)
    env = String(env)
    return quote
        $env == "/" ? Pkg.activate($(esc(pwd()))) : Pkg.activate($env, shared = true)
    end
end

macro activate()
    return Pkg.activate()
end

"""
    @pip(fs...)

Enable writing function call in sequenced-manner, avoiding tedious amounts of parethesis.

# Examples
```julia-repl

julia> using Tool
Substitution = _

julia> @pip -2.0 abs sqrt # Single variable, similar to |>
1.4142135623730951

julia> sqrt(abs(-2.0))
1.4142135623730951

julia> -2.0 |> abs |> sqrt
1.4142135623730951

julia> f(x::Real;z)=x,z
f (generic function with 1 method)

julia> f(x::Float64;z)=x+z
f (generic function with 2 methods)

julia> x = 5;y = 5.0
5.0

julia> @pip x f(_,z=1) # Multiple variables, both args and kwargs are available
(5, 1)

julia> f(x,z=1) == @pip x f(_,z=1) == @pip x f(z=1) # if _ is the first variable, it can be omiited (only a tiny performance difference)
true

julia> @pip x f(1,z=_)
(1, 5)

julia> @pip y f(_,z=1)
6.0

julia> @pip -5 abs Float64[1.0,_] _.^2 _[2] # Broadcast is available
25.0

julia> (Float64[1,abs(-5)].^2)[2]
25.0

julia> using DataFrames

julia> df = DataFrame(:x=>[1,2,3],:y=>[2,3,4],:z=>[1.1,2.3,2.9])
3×3 DataFrame
│ Row │ x     │ y     │ z       │
│     │ Int64 │ Int64 │ Float64 │
├─────┼───────┼───────┼─────────┤
│ 1   │ 1     │ 2     │ 1.1     │
│ 2   │ 2     │ 3     │ 2.3     │
│ 3   │ 3     │ 4     │ 2.9     │

julia> @pip df Matrix cor # If the function call is also a type name, parathesis and sub is neccessary.
ERROR: LoadError: MethodError: Cannot `convert` an object of type Expr to an object of type Symbol
Closest candidates are:
  convert(::Type{S}, ::T) where {S, T<:(Union{CategoricalString{R}, CategoricalValue{T,R} where T} where R)} at C:/Users/sciph/.julia/packages/CategoricalArrays/dmrjI/src/value.jl:103     
  convert(::Type{T}, ::T) where T at essentials.jl:171
  Symbol(::Any...) at strings/basic.jl:207

julia> @pip df Matrix(_) cor
3×3 Array{Float64,2}:
 1.0       1.0       0.981981
 1.0       1.0       0.981981
 0.981981  0.981981  1.0
 
```
"""

macro pip(fs...)
    fs = [fs...]
    ans = similar(fs)
    ans[1] = popfirst!(fs)
    for (i, foo) in enumerate(fs)
        if typeof(foo) == Symbol    # Handle pure function symbol, e.g. abs
            ans[i+1] = Expr(:call, fs[i], ans[i])
        elseif foo.head == :(->)    # Handle anonymous function symbol, e.g. x->x^2
            var = foo.args[1]
            call = foo.args[2].args[2]
            for (j, arg) in enumerate(call.args)
                arg == var && begin call.args[j] = ans[i]; ans[i+1] = call; break; end 
            end
        else                    
            notsearched = true
            for (j, arg) in enumerate(fs[i].args)
                if arg == sub   # Handle variable in function, e.g. f(sub, 2)
                    fs[i].args[j] = ans[i]
                    notsearched = false
                    break
                elseif typeof(arg) == Expr  # Handle variable in an addtion layer of Expr, e.g. [sub, 2]
                    for (k, kwarg) in enumerate(arg.args)
                        kwarg == sub && begin fs[i].args[j].args[k] = ans[i]; notsearched = false; break; end
                    end
                    !notsearched && break
                end
            end
            notsearched && insert!(fs[i].args, 2, ans[i]) # Handle ommited variable
            ans[i+1] = fs[i]
        end
    end
    return esc(ans[end])
end
"""
    @pipas(fs...)

Enable writing function call in sequenced-manner, avoiding tedious amounts of parethesis
@pipas reassign final value to the first arguments, and the first argument should be a global variable.

# Examples
```julia-repl

julia> using Tool
Substitution = _

julia> f(x::Real;z)=x,z
f (generic function with 1 method)

julia> f(x::Float64;z)=x+z
f (generic function with 2 methods)

julia> x = 5
5

julia> y = 5.0
5.0

julia> @pipas x f(_,z=1)
(5, 1)

julia> x
(5, 1)

julia> @pipas y f(_,z=1)
6.0

julia> y
6.0
```
"""
macro pipas(fs...)
    fs = [fs...]
    ans = similar(fs)
    ans[1] = popfirst!(fs)
    for (i, foo) in enumerate(fs)
        if typeof(foo) == Symbol    # Handle pure function symbol, e.g. abs
            ans[i+1] = Expr(:call, fs[i], ans[i])
        elseif foo.head == :(->)    # Handle anonymous function symbol, e.g. x->x^2
            var = foo.args[1]
            call = foo.args[2].args[2]
            for (j, arg) in enumerate(call.args)
                arg == var && begin call.args[j] = ans[i]; ans[i+1] = call; break; end 
            end
        else                    
            notsearched = true
            for (j, arg) in enumerate(fs[i].args)
                if arg == sub   # Handle variable in function, e.g. f(sub, 2)
                    fs[i].args[j] = ans[i]
                    notsearched = false
                    break
                elseif typeof(arg) == Expr  # Handle variable in an addtion layer of Expr, e.g. [sub, 2]
                    for (k, kwarg) in enumerate(arg.args)
                        kwarg == sub && begin fs[i].args[j].args[k] = ans[i]; notsearched = false; break; end
                    end
                    !notsearched && break
                end
            end
            notsearched && insert!(fs[i].args, 2, ans[i]) # Handle ommited variable
            ans[i+1] = fs[i]
        end
    end
    return :(global $(ans[1]) = $(esc(ans[end])))
end

"""
    changesub(x::Symbol)

Change the substitution for _ in @pip or @pipas.
Any symbols are available.

# Examples
```julia-repl
julia> using Tool
Substitution = _

julia> x = -5
-5

julia> @pip x _+5
0

julia> changesub(:α)
Substitution = α

julia> @pip x α+5
0

```
"""
changesub(x::Symbol) = begin eval(:(sub = :(x))); println("Substitution = $sub") end



"""
    prime(x::Int)

Return true if x is a prime number, false if x is a composite number.

# Examples
```julia-repl

julia> prime(10)
false

julia> prime(97)
true

```
"""
function prime(x,y::Int,bound)
    if y <= bound
        if x%y == 0
            return false
        else
            return prime(x,y+2,bound)
        end
    else
        return true
    end
end

function prime(x::Int)
    if x == 1
        return nothing
    elseif x == 2
        return true
    elseif x%2==0
        return false
    else
        bound = round(sqrt(x))
        return prime(x, 3, bound)
    end
end
"""
    median(A::Array{T,1}) where {T <: Number}
    median(A::AbstractArray{T,N}) where {T <: Number, N}

Calculate median
"""
function median(A::Array{<: Number, 1})
    B = sort(A)
    n = length(B)
    m = cld(n, 2)
    iseven(n) ? (return sum(B[m:m + 1])/2) : return B[m]
end
median(A::AbstractArray{<: Number, N}) where N = median(reshape(A, length(A)))



minus_pos(x::Number, y::Number) = max(x - y, 0)
relu(x::AbstractArray{<: Number, N}) where N = max.(x, 0)


end
