using KernelOps
using Test
using BenchmarkTools
@inline function op_mean(A,r,c)
    m=zero(eltype(A))
    @simd for i in r
        @inbounds m+=A[i]
    end
    m/length(r)
end
@inline function op_max(A,r,c)
    m=A[r[1]]
    @simd for i in r
        @inbounds m=max(m,A[i])
    end
    m
end

@inline function kop(M)
    f1=KernelOp(op_mean,M,(1,1))
    f2=KernelOp(op_max,f1,(1,1))
    return KernelOp(M,(0,0)) do A,Is,I
        @inbounds f1[I]==f2[I]
    end
end
@noinline function compare_kop(M,R)
    kop(M)==R
end
@testset "Basic Test" begin
    M=[exp(-(x-3)^2-(y-3)^2) for x in 1:5, y in 1:5]
    result=Bool[0 0 0 0 0; 0 0 0 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 0 0 0]
    @btime compare_kop($M,$result)
    @test compare_kop(M,result)
end
