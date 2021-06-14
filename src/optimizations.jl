"""
    eaCVPrimal(
        ρ :: Matrix{<:Number},
        dimA :: Int,
        dimB :: Int
    ) :: Tuple{Float64, Matrix{ComplexF64}}

This function solves the SDP
```math
\\max \\{ \\langle \\rho, X \\rangle :  \\text{Tr}_{A}(X) = I_{B} , X \\succeq 0 \\}
```
and returns the optimal value and the optimizer, X.
This is the primal problem of the SDP corresponding to the entanglement-assisted commmunication value.
It is related to the channel min-entropy ``H_{\\min}(A|B)_{\\mathcal{J}(\\mathcal{N})}`` by
``cv_{\\text{ea}}(\\mathcal{N}) = 2^{-H_{\\min}(A|B)_{\\mathcal{J}(\\mathcal{N})}}``.
(See [Section 6.1 of this reference](https://arxiv.org/abs/1504.00233) for further details about
the min-entropy.)
Note: we label the primal as the maximization problem.
"""
function eaCVPrimal(ρ :: AbstractArray, dimA :: Int, dimB :: Int) :: Tuple{Float64,  Matrix{ComplexF64}}
    X = HermitianSemidefinite(dimA*dimB)
    objective = real(tr(ρ' * X))
    constraint = partialtrace(X, 1, [dimA,dimB]) == Matrix{Float64}(I,dimB,dimB)
    problem = maximize(objective,constraint)
    qsolve!(problem)
    return problem.optval, X.value
end

"""
    eaCVDual(
        ρ :: Matrix{<:Number},
        dimA :: Int,
        dimB :: Int
    ) :: Tuple{Float64, Matrix{ComplexF64}}

This function solves the SDP
```math
\\min \\{ \\text{Tr}(Y) :  I_{A} \\otimes Y \\succeq \\rho, Y \\in \\text{Herm}(B) \\}
```
and returns the optimal value and the optimizer, Y. This is the dual problem for the SDP
corresponding to the entanglement-assisted commmunication value.
It is related to the channel min-entropy ``H_{\\min}(A|B)_{\\mathcal{J}(\\mathcal{N})}`` by
``cv_{\\text{ea}}(\\mathcal{N}) = 2^{-H_{\\min}(A|B)_{\\mathcal{J}(\\mathcal{N})}}``.
(See [Section 6.1 of this reference](https://arxiv.org/abs/1504.00233) for further details about
the min-entropy.)
Note: we label the primal as the maximization problem.
"""
function eaCVDual(ρ :: AbstractArray, dimA :: Int, dimB :: Int) :: Tuple{Float64,  Matrix{ComplexF64}}
    identMat = Matrix{Float64}(I, dimA, dimA)
    Y = HermitianSemidefinite(dimB)
    objective = real(tr(Y))
    constraint = [kron(identMat , Y) ⪰ ρ]
    problem = minimize(objective,constraint)
    qsolve!(problem)
    return problem.optval, Y.value
end

"""
    pptCVPrimal(
        ρ :: Matrix{<:Number},
        dimA :: Int,
        dimB :: Int
    ) :: Tuple{Float64,  Matrix{ComplexF64}}

This function solves the SDP
```math
\\max \\{ \\langle \\rho, X \\rangle :  \\text{Tr}_{A}(X) = I_{B} , \\Gamma(X) \\succeq 0, X \\succeq 0 \\}
```
where ``\\Gamma( \\cdot)`` is the partial transpose with respect to the second system,
and returns the optimal value and the optimizer, X.
This is the primal problem for the SDP relaxation of the channel value. The relaxation is to the PPT cone.
This has various interpretations. Note: we label the primal as the maximization problem.
"""
function pptCVPrimal(ρ :: AbstractArray, dimA :: Int, dimB :: Int) :: Tuple{Float64,  Matrix{ComplexF64}}
    X = HermitianSemidefinite(dimA*dimB)
    objective = real(tr(ρ' * X))
    constraints = [partialtrace(X, 1, [dimA,dimB]) == Matrix{Float64}(I,dimB,dimB),
                   partialtranspose(X,2,[dimA,dimB]) ⪰ 0]
    problem = maximize(objective,constraints)
    qsolve!(problem)
    return problem.optval, X.value
end

"""
    pptCVDual(
        ρ :: Matrix{<:Number},
        dimA :: Int,
        dimB :: Int
    ) :: Tuple{Float64,  Matrix{ComplexF64}, Matrix{ComplexF64}}

This function solves the SDP
```math
\\min \\{ \\text{Tr}(Y_{1}) : I_{A} \\otimes Y_{1} - \\Gamma(Y_{2}) \\succeq \\rho, Y_{2} \\succeq 0, Y_{1} \\in \\text{Herm}(B) \\}
```
where `` \\Gamma( \\cdot)`` is the partial transpose with respect to the second system,
and returns the optimal value and optimizer, ``(Y_1 , Y_2 )``.
This is the dual problem for the SDP relaxation of the channel value. The relaxation is to the PPT cone.
This has various interpretations. Note: we label the primal as the maximization problem.
"""
function pptCVDual(ρ :: AbstractArray, dimA :: Int, dimB :: Int, dual=true :: Bool) :: Tuple{Float64,  Matrix{ComplexF64}, Matrix{ComplexF64}}
    identMat = Matrix{Float64}(I, dimA, dimA)
    Y1 = ComplexVariable(dimB,dimB)
    Y2 = HermitianSemidefinite(dimA*dimB)
    objective = real(tr(Y1))
    constraints = [kron(identMat,Y1) - partialtranspose(Y2, 2 , [dimA,dimB]) ⪰ ρ,
                   Y1' - Y1 == zeros(dimB,dimB)] #Forces Hermiticity
    problem = minimize(objective,constraints)
    qsolve!(problem)
    return problem.optval, Y1.value, Y2.value
end

"""
    twoSymCVPrimal(
        ρ :: Matrix{<:Number},
        dimA :: Int,
        dimB :: Int
    ) :: Tuple{Float64,  Matrix{ComplexF64}}

This function solves the SDP
```math
\\max \\{ \\langle \\rho, X \\rangle :  \\text{Tr}_{A}(X) = I_{B} ,
                                        \\Gamma^{B_{1}}(X) \\succeq 0,
                                        X = (I_{A} \\otimes \\mathbb{F}_{B})X(I_{A} \\otimes \\mathbb{F}_{B}),
                                        X \\succeq 0 \\}
```
where ``\\Gamma^{B_{1}}( \\cdot)`` is the partial transpose with respect to the second system,
and returns the optimal value and the optimizer, X. The conditions on X demand it is two-symmetric, i.e.
an element of the lowest level of the [DPS hierarchy.](https://arxiv.org/abs/quant-ph/0308032)
Note: we label the primal as the maximization problem.
"""
function twoSymCVPrimal(ρ :: AbstractArray, dimA :: Int, dimB :: Int) :: Tuple{Float64,  Matrix{ComplexF64}}
    X = HermitianSemidefinite(dimA*dimB*dimB)
    idA = Matrix(1I, dimA, dimA); idB = Matrix(1I, dimB, dimB)
    F = swapOperator(dimB)
    objective = real(tr(kron(ρ,idB)' * X))
    constraints = [partialtrace(partialtrace(X, 1, [dimA,dimB,dimB]),2,[dimB,dimB]) == Matrix{Float64}(I,dimB,dimB),
                   X - (kron(idA,F)*X*kron(idA,F)') == 0,
                   partialtranspose(X,2,[dimA,dimB,dimB]) ⪰ 0]
    problem = maximize(objective,constraints)
    qsolve!(problem)
    return problem.optval, X.value
end
#I don't write the dual program because it's too big to be useful anyways
