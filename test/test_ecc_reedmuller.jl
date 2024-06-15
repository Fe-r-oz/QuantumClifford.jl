using Test
using Nemo
using LinearAlgebra
using RowEchelon: rref
using QuantumClifford
using QuantumClifford.ECC
using QuantumClifford.ECC: AbstractECC, ReedMuller, generator, RecursiveReedMuller 

function designed_distance(matrix, m, r)
    for row in eachrow(matrix)
        count = sum(row)
        if count >= 2 ^ (m - r)
            return true
        end
    end
    return false
end

@testset "Test RM(r, m) properties" begin
    for m in 3:10
        for r in 0:m
            H = generator(ReedMuller(r, m))
            mat = Nemo.matrix(Nemo.GF(2), H)
            computed_rank = LinearAlgebra.rank(mat)
            expected_rank = sum(binomial.(m, 0:r))
            @test computed_rank == expected_rank
            @test designed_distance(H, m, r) == true
            @test rate(ReedMuller(r, m)) == sum(binomial.(m, 0:r)) / 2 ^ m
            @test code_n(ReedMuller(r, m)) == 2 ^ m
            @test code_k(ReedMuller(r, m)) == sum(binomial.(m, 0:r))
            @test distance(ReedMuller(r, m)) == 2 ^ (m - r) 
            @test rref(generator(ReedMuller(r, m))) == rref(generator(RecursiveReedMuller(r, m))) 
        end
    end
   
    # Testing common examples of RM(r,m) codes [raaphorst2003reed](@cite), [djordjevic2021quantum](@cite), [abbe2020reed](@cite).
    # RM(0,3)  
    @test generator(ReedMuller(0,3)) == [1 1 1 1 1 1 1 1]
    
    #RM(1,3) 
    @test generator(ReedMuller(1,3)) == [1 1 1 1 1 1 1 1;
                                         1 1 1 1 0 0 0 0;
                                         1 1 0 0 1 1 0 0;
                                         1 0 1 0 1 0 1 0]
    #RM(2,3)
    @test generator(ReedMuller(2,3)) == [1 1 1 1 1 1 1 1;
                                         1 1 1 1 0 0 0 0;
                                         1 1 0 0 1 1 0 0;
                                         1 0 1 0 1 0 1 0;
                                         1 1 0 0 0 0 0 0;
                                         1 0 1 0 0 0 0 0;
                                         1 0 0 0 1 0 0 0]
    #RM(3,3)
    @test generator(ReedMuller(3,3)) == [1 1 1 1 1 1 1 1;
                                         1 1 1 1 0 0 0 0;
                                         1 1 0 0 1 1 0 0;
                                         1 0 1 0 1 0 1 0;
                                         1 1 0 0 0 0 0 0;
                                         1 0 1 0 0 0 0 0;
                                         1 0 0 0 1 0 0 0;
                                         1 0 0 0 0 0 0 0]
    #RM(2,4)
    @test generator(ReedMuller(2,4)) == [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
                                         1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0;
                                         1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0;
                                         1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0;
                                         1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
                                         1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0;
                                         1 1 0 0 1 1 0 0 0 0 0 0 0 0 0 0;
                                         1 0 1 0 1 0 1 0 0 0 0 0 0 0 0 0;
                                         1 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0;
                                         1 0 1 0 0 0 0 0 1 0 1 0 0 0 0 0;
                                         1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0]
end
