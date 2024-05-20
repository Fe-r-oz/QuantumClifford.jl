"""The family of Reed-Solomon codes, as discovered by Reed and Solomon in their 1960 paper [reed1960polynomial](@cite). 

Reed Solomon codes are maximum distance separable (MDS) codes and have the highest possible minimum Hamming distance. The codes have symbols from finite Galois fields `GF(pᵐ)` of degree `m`, where `p` is a prime number, with parameters `[[x - 1, k, x - k]]`.

They are not binary codes but frequently are used with `x = 2ᵐ`, and so there is a mapping of residue classes of a primitive polynomial with binary coefficients and each element of `GF(2ᵐ)` is represented as a binary `m`-tuple. Denoting the `x` field elements as `0, α⁰, α¹, α²,... αˣ ⁻ ¹`, the shortened field parity-check matrix (`HF`) is given as follows:

```
(α⁰)ʲ			(α¹)ʲ			(α²)ʲ				...		(αˣ ⁻ ¹)ʲ
(α⁰)ʲ ⁺ ¹		(α¹)ʲ ⁺ ¹		(α²)ʲ ⁺ ¹			...		(αˣ ⁻ ¹)ʲ ⁺ ¹
(α⁰)ʲ ⁺ ²		(α¹)ʲ ⁺ ²		(α²)ʲ ⁺ ²			...		(αˣ ⁻ ¹)ʲ ⁺ ²
(α⁰)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹	(α¹)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹	(α²)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹		...		(αˣ ⁻ ¹)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹
	.			.			.			...			.
	.			.			.			...			.
	.			.			.			...			.
(α⁰)ʲ ⁺ ˣ ⁻ ᵏ		(α¹)ʲ ⁺ ˣ ⁻ ᵏ	(α²)ʲ ⁺ ˣ ⁻ ᵏ		...		(αˣ ⁻ ¹)ʲ ⁺ ˣ ⁻ ᵏ
```

You might be interested in consulting [geisel1990tutorial](@cite), [wicker1999reed](@cite), [sklar2001reed](@cite), [berlekamp1978readable](@cite), [tomlinson2017error](@cite), [macwilliams1977theory](@cite), and [peterson1972error](@cite) as well.

The ECC Zoo has an [entry for this family](https://errorcorrectionzoo.org/c/reed_solomon).
"""

abstract type AbstractPolynomialCode <: ClassicalCode end

struct ReedSolomon <: AbstractPolynomialCode
    m::Int
    t::Int

    function ReedSolomon(m, t)
        if m < 3 || t < 0 || t >= 2 ^ (m - 1) 
            throw(ArgumentError("Invalid parameters: m and t must be non-negative. Also, m > 3 and t < 2 ^ (m - 1) in order to obtain a valid code."))
        end
        new(m, t)
    end
end

"""
`generator_polynomial(ReedSolomon(m, t))`

- `m`: The positive integer defining the degree of the finite (Galois) field, `GF(2ᵐ)`.
- `t`: The positive integer specifying the number of correctable errors.

The generator polynomial for an RS code takes the following form:

```
g(X) = g₀ + g₁X¹ + g₂X² + ... + g₂ₜ₋₁X²ᵗ⁻¹ + X²ᵗ
```

where `X` is the indeterminate variable, `gᵢ` are the coefficients of the polynomial and `t` is the number of correctable symbol errors.

We describe the generator polynomial in terms of its `2 * t  = n - k` roots, as follows:

``` 
g(X) = (X - α¹)(X - α²)(X - α³) ... (X - α²ᵗ)
```

Degree and Parity Symbols: The degree of the generator polynomial is equal to `2 * t`, which is also the number of parity symbols added to the original data (`k` symbols) to create a codeword of length `n` `(n = k + 2 * t)`.

Roots of the Generator Polynomial: The generator polynomial has `2 * t` distinct roots, designated as `α¹, α², ... , α²ᵗ`. These roots are chosen from a Finite Galois Field. Any power of α can be used as the starting root, not necessarily `α¹` itself.

Fixed generator polynomial scheme vs variable generator polynomial scheme: Only in this construction scheme using fixed generator polynomial `g(x)`, RS codes are a subset of the Bose, Chaudhuri, and Hocquenghem (BCH) codes; hence, this relationship between the degree of the generator polynomial and the number of parity symbols holds, just as for BCH codes where degree of BCH generator polynomial, `degree(g(x)) == n - k`. Prior to 1963, RS codes employed a variable generator polynomial for encoding. This approach [peterson1972error](@cite) differed from the prevalent BCH scheme (used here), which utilizes a fixed generator polynomial. Consequently, these original RS codes weren't strictly categorized as BCH codes. Furthermore, depending on the chosen evaluation points, they might not even qualify as cyclic codes.

"""
# RS(7, 3), RS(15, 9), RS(255, 223), RS(160, 128), RS(255, 251), (255, 239) and (255, 249) codes. Examples taken from https://en.wikipedia.org/wiki/Reed%E2%80%93Solomon_error_correction, https://www.cs.cmu.edu/~guyb/realworld/reedsolomon/reed_solomon_codes.html, http://www.chencode.cn/lecture/Information_Theory_and_Coding/Information%20Theory%20and%20Coding-CH7.pdf, https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=91e1d6d27311780b0a8c34a41793fa85f3947af1.

```jldoctest
julia> test_cases = [(7, 3), (15, 9), (225, 223), (160, 128), (255, 251), (255, 239), (255, 249)]
7-element Vector{Tuple{Int64, Int64}}:
 (7, 3)
 (15, 9)
 (225, 223)
 (160, 128)
 (255, 251)
 (255, 239)
 (255, 249)

julia> for (n, k) in test_cases
           m = ilog2(n + 1)
           t = div(n - k, 2)
           # Using fixed generator polynomial construction scheme for defining generator polynomial, `g(x)`, of RS codes, `degree(g(x))` == 2 * t == n - k. 
           degree(generator_polynomial(ReedSolomon(m, t))) == 2 * t == n - k
       end
```

function generator_polynomial(rs::ReedSolomon)
    GF2ʳ, a = finite_field(2, rs.m, "a")
    P, x = GF2ʳ[:x]
    gx = x - a ^ 1
    for i in 2:2 * rs.t
        gx *= (x - a ^ i)
    end
    return gx
end

"""
`parity_checks(ReedSolomon(m, t))`
- `m`: The positive integer defining the degree of the finite (Galois) field, `GF(2ᵐ)`.
- `t`: The positive integer specifying the number of correctable errors.

This function applies Reed-Solomon codes for binary transmission using soft decisions (see section 7.3)[tomlinson2017error](@cite). For significant coding gain, code length is typically restricted to less than 200 bits. Modified Dorsch decoder [dorsch1974decoding](@cite) is recommended for near maximum likelihood decoding.

Challenges of Standard RS Codes: While efficient as MDS codes, standard RS codes are not ideal for binary channels. As demonstrated in the results (see section 7.2)[tomlinson2017error](@cite), their performance suffers due to a mismatch between the code structure (symbol-based) and the channel (binary). A single bit error can lead to a symbol error, negating the code's benefits.

Improved Binary Codes through Concatenation: This method enhances RS codes for binary channels through code concatenation. It adds a single overall binary parity check to each `m`-tuple representing a symbol. This approach transforms the original RS code `[[n, k, n - k - 1]]` into a new binary code with parameters `[[n[m + 1], k * m, 2[n - k -1]]]`. The resulting binary code boasts a minimum symbol weight of 2, effectively doubling the minimum Hamming distance compared to the original RS code.

Augmented Extended RS Codes: Constructed from Galois Field `GF(2ᵐ)`. Length: `2ᵐ + 1` (Maximum Distance Separable (MDS) codes). Parameters: `[[2ᵐ + 1, k, 2ᵐ ⁺ ¹ - k]]`. Generalization: Applicable to any Galois Field `GF(x)` with parameters `[[x + 1, k, x + 2 - k]]`.

Field Parity-Check Matrix Properties:

```
(α₀)ʲ				(α₁)ʲ				(α₂)ʲ			...		(αₓ₋₂)ʲ				1	0
(α₀)ʲ ⁺ ¹			(α₁)ʲ ⁺ ¹			(α₂)ʲ ⁺ ¹		...		(αₓ₋₂)ʲ ⁺ ¹			0	0
(α₀)ʲ ⁺ ²			(α₁)ʲ ⁺ ²			(α₂)ʲ ⁺ ²		...		(αₓ₋₂)ʲ ⁺ ²			0	0
(α₀)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹		(α₁)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹		(α₂)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹	...		(αₓ₋₂)ʲ ⁺ ˣ ⁻ ᵏ ⁻ ¹		0	0
	.				.				.		...			.			.	.
	.				.				.		...			.			.	.
	.				.				.		...			.			.	.
(α₀)ʲ ⁺ ˣ ⁻ ᵏ			(α₁)ʲ ⁺ ˣ ⁻ ᵏ			(α₂)ʲ ⁺ ˣ ⁻ ᵏ		...		(αₓ₋₂)ʲ ⁺ ˣ ⁻ ᵏ		0	1
```

The matrix has `x - k + 1` rows corresponding to the code's parity symbols. Any `x - k + 1` columns form a Vandermonde matrix (non-singular). This ensures correction of up to `x - k + 1` symbol erasures in a codeword. We can re-arrange the columns of this matrix in any desired order. Any set of `s` symbols within a codeword can be designated as parity symbols and permanently removed. This important property leads to construction of Shortened MDS codes.

Shortened MDS Codes: Corresponding columns of the field parity-check matrix can be deleted to form a shortened `[[2ᵐ + 1 - s, k, 2ᵐ ⁺ ¹ - s - k]]` MDS code. This is an important property of MDS codes, particularly for their practical realisation in the form of augmented, extended RS codes because it enables efficient implementation in applications such as incremental redundancy systems, and network coding. The 3-level quantization of the received channel bits is utilized meaning 3 symbols are deleted. The Fig. 7.2 [tomlinson2017error](@cite) shows that with 3-level quantization, there is an improvement over the binary-transmission with hard decisions for Reed-Solomon coding. The designed distance for binary expanded parity check matrix remains same as symbol based parity check matrix. According to [macwilliams1977theory](@cite), changing the basis `j` can increase the designed distance `(dmin)` of the resulting binary code.

Cyclic Code Construction: Using the first `x - 1` columns of the field parity-check matrix, using `j = 0`, and setting `α₀, α₁, α₂, ..., αₓ ₋ ₁` to  `α⁰, α¹, α², ..., αˣ ⁻ ¹` in the parity-check matrix are set equal to the powers of a primitive element α of the Galois Field `GF(x)`, a cyclic code can be constructed for efficient encoding and decoding.

Shortened MDS (`HF`) Matrix element expansion: 
    1. Row expansion: Each row of in the field parity-check matrix is replaced with an `m`-by-`m` field matrix defined over the base field `GF(2ᵐ)`.
    2. Column expansion: Consequently, the elements in each column of expanded field parity-check matrix are converted to binary representations by substituting powers of a primitive element (`α`) in the Galois Field `GF(2ᵐ)` with their corresponding `m`-tuples over the Boolean Field `GF(2)`.
"""
function parity_checks(rs::ReedSolomon)
    GF2ʳ, a = finite_field(2, rs.m, "a")
    s_symbols = 3 # 3-level quantization. 
    x = 2 ^ rs.m + 1 - s_symbols
    k = 2 ^ rs.m - 1 - 2 * rs.t
    HField = Matrix{FqFieldElem}(undef, x - k + 1, x)
    for j in 1:x
        HField[1, j] = a ^ 0
    end
    for i in 1: x - k + 1
        HField[i, 1] = a ^ 0
    end
    for i in 2:x - k + 1
        for j in 2:x
            HField[i, j] = (a ^ (j - 1)) ^ (i - 2)
        end
    end
    HSeed = vcat(HField[1:1, :], HField[3:end, :])
    HTemp2 = Matrix{FqFieldElem}(undef, rs.m, x)
    HFieldExpanded = Matrix{FqFieldElem}(undef, rs.m * k, x)
    g = 1
    while g <= rs.m * k
        for i in 1:x - k
            for p in 1:rs.m
                HTemp2[p:p, :] = reshape(HSeed[i, :].*a ^ (p - 1) , 1, :)
            end
        if g > rs.m * k
           break
        end
        HFieldExpanded[g:g + rs.m - 1, :] .=  HTemp2
        g = g + rs.m
        end
    end
    H = Matrix{Bool}(undef, rs.m * k, rs.m * x)
    for i in 1:rs.m * k
        for j in 1:x
            col_start = (j - 1) * rs.m + 1
            col_end = col_start + rs.m - 1
            t_tuple = Bool[]
            for k in 0:rs.m - 1
                push!(t_tuple, !is_zero(coeff(HFieldExpanded[i, j], k)))
            end 
            H[i, col_start:col_end] .=  vec(t_tuple)
        end
    end
    return H
end

code_n(rs::ReedSolomon) = (2 ^ rs.m + 1 - 3) * rs.m
code_k(rs::ReedSolomon) = (2 ^ rs.m - 1 - 2 * rs.t) * rs.m
