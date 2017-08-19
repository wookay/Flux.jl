module Tracker

export track, back!

data(x) = x

struct Call{F,As<:Tuple}
  func::F
  args::As
end

Call(f, args...) = Call{typeof(f),typeof(args)}(f, args)

(c::Call)() = c.func(data.(c.args)...)

back!(c::Call, Δ) = back!(c.func, Δ, c.args...)

back!(f, Δ) = nothing

struct TrackedArray{T,N,A} <: AbstractArray{T,N}
  f::Call
  x::A
  Δ::A
end

TrackedScalar{T,A} = TrackedArray{T,0,A}
TrackedVector{T,A} = TrackedArray{T,1,A}
TrackedMatrix{T,A} = TrackedArray{T,2,A}

TrackedArray(c::Call, x::A, Δ::A) where A <: AbstractArray =
  TrackedArray{eltype(A),ndims(A),A}(c, x, Δ)

TrackedArray(c::Call, x::AbstractArray) = TrackedArray(c, x, zeros(x))

TrackedArray(c::Call) = TrackedArray(c, c())

TrackedArray(x::AbstractArray) = TrackedArray(Call(nothing), x)

track(xs) = TrackedArray(xs)
data(x::TrackedArray) = x.x
grad(x::TrackedArray) = x.Δ

function back!(x::TrackedArray, Δ)
  x.Δ .+= Δ
  back!(x.f, Δ)
end

# Fallthrough methods

for f in :[Base.size, Base.ndims].args
  @eval @inline $f(x::TrackedArray, a...) = $f(data(x), a...)
end

Base.similar(x::TrackedArray, dims::Union{AbstractUnitRange,Integer}...) =
  similar(data(x), dims...)

Base.similar(x::TrackedArray, T::Type) = similar(data(x), T)

function Base.showarray(io::IO, X::TrackedArray, repr::Bool = true; header = true)
  if repr
    print(io, "track(")
    Base.showarray(io, data(X), true)
    print(io, ")")
  else
    header && print(io, "Tracked ")
    Base.showarray(io, data(X), false, header = header)
  end
end

include("lib.jl")

end
