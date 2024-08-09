"""
$TYPEDSIGNATURES

Fix the clipped gauge of a stabilizer (in place).

Assumes the input is a valid full-rank stabilizer (all operators
commute and have real phases).

```jldoctest
julia> s = S"- X_ZX_X
             + XXYZ__
             - YZ_Z_X
             - XZX__Y
             + _Z_Y_Y
             - ____Z_";


julia> canonicalize_clip!(s)
- X_XY__
+ YZY___
+ _XZX__
- _ZYX_Z
- __YZ_X
- ____Z_
```

If `phases=false` is set, the canonicalization does not track the phases
in the tableau, leading to a significant speedup.

Introduced in [nahum2017quantum](@cite), with a more detailed explanation of the algorithm in Appendix A of [li2019measurement](@cite)

See also: [`canonicalize!`](@ref), [`canonicalize_rref!`](@ref), [`canonicalize_gott!`](@ref).
"""
function canonicalize_clip!(state::AbstractStabilizer; phases::Bool=true)
    @valbooldispatch _canonicalize_clip!(state; phases=Val(phases)) phases
end
function _canonicalize_clip!(state::AbstractStabilizer; phases::Val{B}=Val(true)) where B
    tab = stabilizerview(state)
    rows, columns = size(stabilizerview(state))
    # step 1: pregauge
    i = 1 # index to place used stab
    for j in 1:columns
        # find first row that is not I in col j
        k1 = findfirst(let j=j; k->|(tab[k,j]...) end, i:rows)
        # find second row that is not I and not same as k1
        if !isnothing(k1)
            k1 += i-1
            k2 = findfirst(let j=j, k1=k1; k->
                           (|(tab[k,j]...) & # not identity
                           (tab[k,j]!=tab[k1,j])) end, # not same as k1
                           k1+1:rows)
            if !isnothing(k2)
                k2 += k1
                # move k1 and k2 up to i and i+1
                rowswap!(state, k1, i; phases=phases)
                rowswap!(state, k2, i+1; phases=phases)
                # use them to eliminate others
                for m in i+2:rows
                    if !(tab[m,j][1]⊻tab[i,j][1]) && !(tab[m,j][2]⊻tab[i,j][2])
                        mul_left!(state, m, i; phases=phases)
                    elseif !(tab[m,j][1]⊻tab[i+1,j][1]) && !(tab[m,j][2]⊻tab[i+1,j][2])
                        mul_left!(state, m, i+1; phases=phases)
                    elseif !(tab[m,j][1]⊻tab[i,j][1]⊻tab[i+1,j][1]) && !(tab[m,j][2]⊻tab[i,j][2]⊻tab[i+1,j][2])
                        mul_left!(state, m, i; phases=phases)
                        mul_left!(state, m, i+1; phases=phases)
                    end
                end
                i += 2
            else # can only find k1
                # move k1 up to i
                rowswap!(state, k1, i; phases=phases)
                # use it to eliminate others
                for m in i+1:rows
                    if !(tab[m,j][1]⊻tab[i,j][1]) && !(tab[m,j][2]⊻tab[i,j][2])
                        mul_left!(state, m, i; phases=phases)
                    end
                end
                i += 1
            end
        end
    end
    # step 2: gauge
    unfrozen_rows = Array(rows:-1:1)
    for j in columns:-1:1 # in reversed order to keep left ends
        # find first row that is not I in col j
        k1 = findfirst(let j=j; k->|(tab[k,j]...) end, unfrozen_rows)
        # find second row that is not I and not same as k1
        if k1!==nothing
            k1_row = unfrozen_rows[k1]
            k2 = findfirst(let j=j, k1_row=k1_row; k->
                           (|(tab[k,j]...) & # not identity
                           (tab[k,j]!=tab[k1_row,j])) end, # not same as k1
                           @view unfrozen_rows[k1+1:end])

            if k2!==nothing
                k2 += k1
                k2_row = unfrozen_rows[k2]
                # use them to eliminate others
                # for rows between k1 and k2, use k1
                for m in @view unfrozen_rows[k1+1:k2-1]
                    if !(tab[m,j][1]⊻tab[k1_row,j][1]) && !(tab[m,j][2]⊻tab[k1_row,j][2])
                        mul_left!(state, m, k1_row; phases=phases)
                    end
                end
                # for other rows, use both
                for m in @view unfrozen_rows[k2+1:end]
                    if !(tab[m,j][1]⊻tab[k1_row,j][1]) && !(tab[m,j][2]⊻tab[k1_row,j][2])
                        mul_left!(state, m, k1_row; phases=phases)
                    elseif !(tab[m,j][1]⊻tab[k2_row,j][1]) && !(tab[m,j][2]⊻tab[k2_row,j][2])
                        mul_left!(state, m, k2_row; phases=phases)
                    elseif !(tab[m,j][1]⊻tab[k1_row,j][1]⊻tab[k2_row,j][1]) && !(tab[m,j][2]⊻tab[k1_row,j][2]⊻tab[k2_row,j][2])
                        mul_left!(state, m, k1_row; phases=phases)
                        mul_left!(state, m, k2_row; phases=phases)
                    end
                end
                deleteat!(unfrozen_rows, (k1, k2))
            else # can only find k1
                # use it to eliminate others
                for m in @view unfrozen_rows[k1+1:end]
                    if !(tab[m,j][1]⊻tab[k1_row,j][1]) && !(tab[m,j][2]⊻tab[k1_row,j][2])
                        mul_left!(state, m, k1_row; phases=phases)
                    end
                end
                deleteat!(unfrozen_rows, k1)
            end
        end
    end
    state
end


"""
$TYPEDSIGNATURES

The Bigram `B` of stabilizer endpoints represents the "span" of each stabilizer within a set of Pauli operators `𝒢 = {g₁,…,gₙ}`.

For each stabilizer `g`, the left endpoint `𝓁(g)` is defined as the minimum site `x` where `g` acts non-trivially, while the
right endpoint `𝓇(g)` is the maximum site where `g` acts non-trivially. 

The site `x` represent the position within the system, taking values from `{1,2,…,n}` where `n` is the number of qubits.

The bigram set `B(𝒢)` encodes these endpoints as pairs:

`B(𝒢) ≡ {(𝓁(g₁),𝓇(g₁)),…,(𝓁(gₙ),𝓇(gₙ))}`

The clipped gauge `𝒢` is a specific choice of stabilizer state where exactly two stabilizer endpoints exist at each site,
ensuring `ρ𝓁(x) + ρ𝓇(x) = 2` for all sites `x`.

In the clipped gauge, entanglement entropy is determined only by the stabilizers' endpoints, regardless of their internal structure.

If `clip=true` (the default) the tableau is converted to the clipped gauge in-place before calculating the bigram.
Otherwise, the clip gauge conversion is skipped (for cases where the input is already known to be in the correct gauge).

Introduced in [nahum2017quantum](@cite), with a more detailed explanation of the algorithm in [li2019measurement](@cite) and [gullans2021quantum](@cite).

```jldoctest
julia> s = ghz(3)
+ XXX
+ ZZ_
+ _ZZ

julia> bigram(s)
3×2 Matrix{Int64}:
 1  3
 1  2
 2  3
```

See also: [`canonicalize_clip!`](@ref)
"""
function bigram(state::AbstractStabilizer; clip::Bool=true)::Matrix{Int} # JET-XXX The ::Matrix{Int} should not be necessary, but they help with inference
    clip && canonicalize_clip!(state)
    tab = stabilizerview(state)
    rows, columns = size(tab)
    bg = zeros(Int, rows, 2)
    for i in 1:rows
        l = findfirst(j->|(tab[i,j]...), 1:columns)
        r = findlast(j->|(tab[i,j]...), 1:columns)
        (isnothing(l) || isnothing(r)) && throw(DomainError("the tableau is inconsistent (check if it is clip-canonicalized and Hermitian)"))
        bg[i, 1] = l
        bg[i, 2] = r
    end
    bg
end


"""
$TYPEDSIGNATURES

Get bipartite entanglement entropy of a subsystem `𝒶`. 

In a system of `n`-qubits divided into regions `𝒶` and `𝒷`, the Rényi (or von Neumann)
entropy `S(ρ𝒶)` where `ρ𝒶` is reduced density matrix, quantifies the quantum information
in region `𝒶` after tracing out region `𝒷`.

The entropy is given by: `S(ρ𝒶) = |𝒶| - log₂ |𝒢𝒶|`, where `𝒢𝒶` is a subgroup of stabilizers
acting non-trivially on `𝒶`. This entropy measures the number of independent stabilizers 
on `𝒶`,  reflecting the quantum  correlations between regions. 

The stabilizer group `𝒢`, viewed as a binary vector space `V`, can be decomposed such that:
`S𝒶 = |𝒷| - dim V𝒷 = dim (Π𝒶 V) - |𝒶|` where `Π𝒶` and `Π𝒷` are truncation maps for regions
`𝒶` and `𝒷`, respectively. 

Initially, each site has one stabilizer and zero entanglement, but as stabilizers enter 
region `𝒶` over time, entanglement `S𝒶` increases by one bit for each new independent
operator in `𝒶`.

It can be calculated with multiple different algorithms, the most performant one depending
on the particular case.

Currently implemented are the `:clip` (clipped gauge), `:graph` (graph state), and `:rref` (Gaussian elimination) algorithms.
Benchmark your particular case to choose the best one.

See Appendix C of [nahum2017quantum](@cite).
"""
function entanglement_entropy end


"""
$TYPEDSIGNATURES

Get bipartite entanglement entropy of a contiguous subsystem by passing through the clipped gauge.

If `clip=false` is set the canonicalization step is skipped, useful if the input state is already in the clipped gauge.

```jldoctest
julia> s = ghz(3)
+ XXX
+ ZZ_
+ _ZZ

julia> entanglement_entropy(s, 1:3, Val(:clip))
0
```

See also: [`bigram`](@ref), [`canonicalize_clip!`](@ref)
"""
function entanglement_entropy(state::AbstractStabilizer, subsystem_range::UnitRange, algorithm::Val{:clip}; clip::Bool=true)
    # JET-XXX The ::Matrix{Int} should not be necessary, but they help with inference
    bg = bigram(state; clip=clip)::Matrix{Int}
    # If the state is mixed, this formula is valid only for contiguous regions that don't wrap around.
    # See Eq. E7 of gullans2021quantum.
    # As subsystem_range is UnitRange, we know the formula will be valid.
    length(subsystem_range) - count(r->(r[1] in subsystem_range && r[2] in subsystem_range), eachrow(bg))
end


"""
$TYPEDSIGNATURES

Get bipartite entanglement entropy by first converting the state to a graph and computing the rank of the adjacency matrix.

```jldoctest
julia> using Graphs # hide

julia> s = Stabilizer(Graph(ghz(4)))
+ XZZZ
+ ZX__
+ Z_X_
+ Z__X

julia> entanglement_entropy(s, [1,4], Val(:graph))
1
```

Based on "Entanglement in graph states and its applications".
""" # TODO you should use [hein2006entanglement](@cite) instead of "Entanglement in graph states and its applications", but Documenter is giving the weirdest error if you do so...
function entanglement_entropy(state::AbstractStabilizer, subsystem::AbstractVector, algorithm::Val{:graph})
    graph = Graphs.Graph(state)
    adjmat = Graphs.adjacency_matrix(graph)
    other_subsystem = filter(i->!(i in collect(subsystem)), 1:Graphs.nv(graph))
    subadjmat = Nemo.matrix(Nemo.GF(2), collect(adjmat[subsystem,other_subsystem]))
    LinearAlgebra.rank(subadjmat)
end


"""
$TYPEDSIGNATURES

Get bipartite entanglement entropy by converting to RREF form (i.e., partial trace form).

The state will be partially canonicalized in an RREF form.

```jldoctest
julia> s = MixedDestabilizer(T"-IX -YX -ZZ -ZI",2)
𝒟ℯ𝓈𝓉𝒶𝒷
- _X
- YX
𝒮𝓉𝒶𝒷
- ZZ
- Z_

julia> entanglement_entropy(s, [1,2], Val(:rref))
0
```

See also: [`canonicalize_rref!`](@ref), [`traceout!`](@ref).
"""
function entanglement_entropy(state::AbstractStabilizer, subsystem::AbstractVector, algorithm::Val{:rref}; pure::Bool=false)
    nb_of_qubits = nqubits(state)
    # if state is pure, then S(A) = S(A_complement), so trace out whichever is shorter
    if pure && length(subsystem) < nb_of_qubits/2
        state, rank_after_deletion = canonicalize_rref!(state, subsystem)
        nb_of_deletions = length(subsystem)
    else
	# trace out the complement to get S(A)
        state, rank_after_deletion = canonicalize_rref!(state, setdiff(1:nb_of_qubits, subsystem))
        nb_of_deletions = nb_of_qubits - length(subsystem)
    end
    return nb_of_qubits - rank_after_deletion - nb_of_deletions
end

"""
$TYPEDSIGNATURES
"""
entanglement_entropy(state::MixedDestabilizer, subsystem::AbstractVector, a::Val{:rref}) = entanglement_entropy(state, subsystem, a; pure=nqubits(state)==rank(state))

_to_unitrange(x) = isa(x, UnitRange) ? x : isa(x, AbstractVector) && !isempty(x) && all(diff(x) .== 1) ? UnitRange(first(x), last(x)) : error("Cannot convert to UnitRange: $x")

"""
$TYPEDSIGNATURES

The mutual information between subsystems `𝒶` and `𝒷` in a stabilizer state is
given by `Iⁿ(𝒶, 𝒷) = Sⁿ𝒶 + Sⁿ𝒷 - Sⁿ𝒶𝒷`, where the Rényi index `n` is dropped because, for
Clifford circuits, all Renyi entropies are equal due to the flat entanglement spectrum.

```jldoctest
julia> mutual_information(ghz(3), 1:2, 3:4, Val(:clip))
2
```

See Eq. E6 of [li2019measurement](@cite).
"""
function mutual_information(state::AbstractStabilizer, A::UnitRange, B::UnitRange, algorithm::Val{:clip}; clip::Bool=true)
    S𝒶 = entanglement_entropy(state, A, algorithm; clip=clip)
    S𝒷 = entanglement_entropy(state, B, algorithm; clip=clip) 
    S𝒶𝒷 = entanglement_entropy(state, _to_unitrange(union(A, B)), algorithm; clip=clip)
    return S𝒶 + S𝒷 - S𝒶𝒷
end

"""
$TYPEDSIGNATURES

```jldoctest
julia> using Graphs # hide

julia> s = Stabilizer(Graph(ghz(4)))
+ XZZZ
+ ZX__
+ Z_X_
+ Z__X

julia> mutual_information(s, [1,2], [3, 4], Val(:graph))
2
```

"""
function mutual_information(state::AbstractStabilizer, A::AbstractVector, B::AbstractVector, algorithm::Union{Val{:rref}, Val{:graph}}; pure::Bool=false)
    if algorithm == Val(:graph)
        S𝒶 = entanglement_entropy(state, A, algorithm)
        S𝒷 = entanglement_entropy(state, B, algorithm)
        S𝒶𝒷 = entanglement_entropy(state, union(A, B), algorithm)
        return S𝒶 + S𝒷 - S𝒶𝒷
    else
        S𝒶 = entanglement_entropy(state, A, algorithm; pure=pure)
        S𝒷 = entanglement_entropy(state, B, algorithm; pure=pure)
        S𝒶𝒷 = entanglement_entropy(state, union(A, B), algorithm; pure=pure)
        return S𝒶 + S𝒷 - S𝒶𝒷
    end
end
