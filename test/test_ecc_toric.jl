@testitem "ECC Toric code" begin
    using Hecke
    using QuantumClifford.ECC
    using QuantumClifford.ECC: toric_codes, Toric, code_n, code_k

    # TODO: compare distance as well using the MIP solver for minimum distance
    @testset "[[n, k, d]] equivalence between toric_codes and Toric " begin
        for l in 2:10
            c = toric_codes(l)
            @test code_n(parity_checks(c)) == 2*l^2 == code_n(parity_checks(Toric(l,l)))
            @test code_k(parity_checks(c)) == 2 == code_k(parity_checks(Toric(l,l)))
        end
    end
end
