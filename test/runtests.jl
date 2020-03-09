using KernelOps
using Test

@inline function op_mean(A,r,c)
    m=zero(eltype(A))
    @inbounds begin
        @simd for i in r
            m+=A[i]
        end
    end
    m/length(r)
end
@inline function op_max(A,r,c)
    m=A[r[1]]
    @inbounds begin
        @simd for i in r
            m=max(m,A[i])
        end
    end
    m
end

@testset "Basic Test" begin
    M=[exp(-(x-3)^2-(y-3)^2) for x in 1:5, y in 1:5]
    f1=KernelOp(op_mean,M,(1,1))
    f2=KernelOp(op_max,f1,(1,1))

    @test (f1.==f2) == Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 0 0 0]
end

using KernelOps

M=[exp(-(x-3)^2-(y-3)^2) for x in 1:5, y in 1:5]

f1=KernelOp(M,(1,1)) do A,Is,I
    length(Is) != 9 && return zero(eltype(A)) 
    A[I]
end
f2=KernelOp(op_max,f1,(1,1))

@test (f1.==f2) == Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 0 0 0]
