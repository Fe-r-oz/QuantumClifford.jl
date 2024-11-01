"""
# Direct Product of Groups

The direct product of groups is instrumental in constructing group algebra of two-block
group algebra code. Lin and Pryadko illustrate this method in Appendix C, Table 2 of
[lin2024quantum](@cite), where they utilize the direct product of two cyclic groups,
expressed as `C₂ₘ = Cₘ × C₂`, with an order of `2m`.

# Example

The [[56, 28, 2]] abelian 2BGA code from Appendix C, Table II in [lin2024quantum](@cite)
can be constructed using the direct product of two cyclic groups. Specifically, the group
`C₂₈` of order `l = 28` can be represented as `C₁₄ × C₂`, where the first group has order
`m = 14` and the second group has order `n = 2`.

```jldoctest directprod
julia> import Oscar: cyclic_group, small_group_identification, describe, order; # hide

julia> import Hecke: gens, quo, group_algebra, GF, one, direct_product, sub; # hide

julia> m = 14; n = 2;

julia> C₁₄ = cyclic_group(m);

julia> C₂ = cyclic_group(n);

julia> G = direct_product(C₁₄, C₂);

julia> GA = group_algebra(GF(2), G);

julia> x, s = gens(GA)[1], gens(GA)[3];

julia> a = [one(GA), x^7];

julia> b = [one(GA), x^7, s, x^8, s * x^7, x];

julia> c = twobga_from_direct_product(a, b, GA);

julia> order(G)
28

julia> code_n(c), code_k(c)
(56, 28)

julia> describe(G), small_group_identification(G)
("C14 x C2", (28, 4))
```

!!! note When using the direct product of two cyclic groups, it is essential to verify
the group presentation `Cₘ = ⟨x, s | xᵐ = s² = xsx⁻¹s⁻¹ = 1⟩` is satisfied, where the
order is `2m`. Ensure that the selected generators have the correct orders of `m = 14`
and `n = 2`, respectively. If the group presentation is not satisfied, the resulting
group algebra over `GF(2)` will not represent the intended group, `C₂₈ = C₁₄ × C₂`. In
addition, `Oscar.sub` can be used to determine if `H` is a subgroup of `G` and to
confirm that both `C₁₄` and `C₂` are subgroups of `C₂₈`.

```jldoctest directprod
julia> order(gens(G)[1])
14

julia> order(gens(G)[3])
2

julia> x^14 == s^2 == x * s * x^-1 * s^-1
true

julia> H, _  = sub(G, [gens(G)[1], gens(G)[3]]);

julia> H == G
true
```
"""
function twobga_from_direct_product(a_elts::VectorDirectProductGroupElem, b_elts::VectorDirectProductGroupElem, F2G::DirectProductGroupAlgebra)
    a = sum(F2G(x) for x in a_elts)
    b = sum(F2G(x) for x in b_elts)
    c = two_block_group_algebra_codes(a,b)
    return c
end
