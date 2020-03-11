# KernelOps.jl

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/francescoalemanno/KernelOps.jl.svg?branch=master)](https://travis-ci.com/francescoalemanno/KernelOps.jl)
[![codecov.io](http://codecov.io/github/francescoalemanno/KernelOps.jl/coverage.svg?branch=master)](http://codecov.io/github/francescoalemanno/KernelOps.jl?branch=master)
<!--
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://francescoalemanno.github.io/KernelOps.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://francescoalemanno.github.io/KernelOps.jl/dev)
-->

A Julia package to apply lazy kernel operations on AbstractArrays, they are composable and non copying.
Have Fun!

# Example
Let's say we have a noisy image stored in an array 'M' and we want to locate local maximas, one very simple way to do that is
to take a local average of the image, take the local maximum function of the smoothed image and compare the two for equality,
the points where they coincide are the local maxima
```julia
M=[exp(-(x-3)^2-(y-3)^2) for x in 1:5, y in 1:5].+rand(5,5)*0.3 #fake image with a maximum in the middle affected by random noise

f1=KernelOp(M, (1,1)) do A,Is,I   # (1,1) is the size of the kernelop
    avg=zero(eltype(A))
    @inbounds for i in Is
        avg+=A[i]
    end
    avg/length(Is)
end

f2=KernelOp(f1, (1,1)) do A,Is,I   # (1,1) is the size of the kernelop
    m=A[I]
    @inbounds for i in Is
        m=max(m,A[i])
    end
    m
end

show(stdout,"text/plain",f1.==f2)
```
### result:
```julia
5×5 BitArray{2}:
 0  0  0  0  0
 0  0  0  0  0
 0  0  1  0  0
 0  0  0  0  0
 0  0  0  0  0
```

# Example: Conway's Game of life

```julia
using KernelOps
b=Int8.([
    0 0 0 1 1 0 0 0;
    0 0 1 0 0 1 0 0;
    0 1 0 0 0 0 1 0;
    1 0 0 0 0 0 0 1;
    1 0 0 0 0 0 0 1;
    0 1 0 0 0 0 1 0;
    0 0 1 0 0 1 0 0;
    0 0 0 1 1 0 0 0;
])
cb=copy(b);
```

```julia
function evolve(cells::AbstractMatrix)
    game_of_life=KernelOp(cells,(1,1)) do M,Is,I
        s=sum(M[Is])-M[I]
        if M[I]==1
            s<2 && return Int8(0)
            s<=3 && return Int8(1)
            return Int8(0)
        else
            s==3 && return Int8(1)
        end
        return M[I]
    end
    return game_of_life|>collect #add this collect, unless you want julia to suffer
end
```

### Now let's test this fun bit of code

```julia
show(stdout,"text/plain",b)
println("\n")
for i in 1:100
    b=evolve(b)
    show(stdout,"text/plain",b)
    println("\n")
    if b==cb
        print("Pattern repeats itself after $i iterations")
        break;
    end
end
```

    8×8 Array{Int8,2}:
     0  0  0  1  1  0  0  0
     0  0  1  0  0  1  0  0
     0  1  0  0  0  0  1  0
     1  0  0  0  0  0  0  1
     1  0  0  0  0  0  0  1
     0  1  0  0  0  0  1  0
     0  0  1  0  0  1  0  0
     0  0  0  1  1  0  0  0

    8×8 Array{Int8,2}:
     0  0  0  1  1  0  0  0
     0  0  1  1  1  1  0  0
     0  1  0  0  0  0  1  0
     1  1  0  0  0  0  1  1
     1  1  0  0  0  0  1  1
     0  1  0  0  0  0  1  0
     0  0  1  1  1  1  0  0
     0  0  0  1  1  0  0  0

    8×8 Array{Int8,2}:
     0  0  1  0  0  1  0  0
     0  0  1  0  0  1  0  0
     1  1  0  1  1  0  1  1
     0  0  1  0  0  1  0  0
     0  0  1  0  0  1  0  0
     1  1  0  1  1  0  1  1
     0  0  1  0  0  1  0  0
     0  0  1  0  0  1  0  0

    8×8 Array{Int8,2}:
     0  0  0  0  0  0  0  0
     0  0  1  0  0  1  0  0
     0  1  0  1  1  0  1  0
     0  0  1  0  0  1  0  0
     0  0  1  0  0  1  0  0
     0  1  0  1  1  0  1  0
     0  0  1  0  0  1  0  0
     0  0  0  0  0  0  0  0

    8×8 Array{Int8,2}:
     0  0  0  0  0  0  0  0
     0  0  1  1  1  1  0  0
     0  1  0  1  1  0  1  0
     0  1  1  0  0  1  1  0
     0  1  1  0  0  1  1  0
     0  1  0  1  1  0  1  0
     0  0  1  1  1  1  0  0
     0  0  0  0  0  0  0  0

    8×8 Array{Int8,2}:
     0  0  0  1  1  0  0  0
     0  0  1  0  0  1  0  0
     0  1  0  0  0  0  1  0
     1  0  0  0  0  0  0  1
     1  0  0  0  0  0  0  1
     0  1  0  0  0  0  1  0
     0  0  1  0  0  1  0  0
     0  0  0  1  1  0  0  0

    Pattern repeats itself after 5 iterations
