module KernelOps
import Base.size, Base.getindex, Base.IndexStyle
export KernelOp

struct KernelOp{T,N,S,F<:Function} <: AbstractArray{T,N}
    parent::S
    op::F
    opdims::CartesianIndex{N}
    lowbound::CartesianIndex{N}
    upbound::CartesianIndex{N}
    @inline function KernelOp{T,N,S,F}(operation::F,A::S,dims::CartesianIndex{N}) where {T,N,S<:AbstractArray,F<:Function}
        l=minimum(CartesianIndices(A))
        h=maximum(CartesianIndices(A))
        new{T,N,S,F}(A,operation,dims,l,h)
    end
end

@inline function KernelOp(op::F,A::AbstractArray{T,N},dims::NTuple{N,Int}) where {T,N,F<:Function}
    v=CartesianIndices(ntuple(i->1,N))
    ### Just in case compiler policy changes
    ## testout=op(A,v,first(v))
    ## KernelOp{eltype(testout),ndims(A),typeof(A),F}(op,A,CartesianIndex(dims))
    type_A=typeof(A)
    type_v=typeof(v)
    type_elv=typeof(first(v))
    rtypes=Base.return_types(op,(type_A,type_v,type_elv))
    KernelOp{Union{rtypes...},ndims(A),typeof(A),F}(op,A,CartesianIndex(dims))
end

@inline IndexStyle(::KernelOp) = IndexCartesian()

@inline function size_parent(A::KernelOp)
    size(A.parent)
end

@inline function size(A::KernelOp)
    return size_parent(A)
end

@inline function getindex(A::KernelOp{T,N,S},Index::Vararg{Int,N}) where {T,N,S}
    I=CartesianIndex(Index)
    @boundscheck checkbounds(A,I)
    @inbounds begin
        lowI=max(I-A.opdims,A.lowbound)
        upI=min(I+A.opdims,A.upbound)
        return A.op(A.parent,lowI:upI,I)
    end
end

end # module
