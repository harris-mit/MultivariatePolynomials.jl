using LinearAlgebra, Test
using ChainRulesCore

function test_chain_rule(dot, op, args, Δin, Δout)
    output = op(args...)
    foutput, fΔout = ChainRulesCore.frule((NoTangent(), Δin...), op, args...)
    @test output == foutput
    routput, pullback = ChainRulesCore.rrule(op, args...)
    @test output == routput
    rΔin = pullback(Δout)
    @test rΔin[1] == NoTangent()
    @test dot(Δin, rΔin[2:end]) ≈ dot(fΔout, Δout)
end

@testset "ChainRulesCore" begin
    Mod.@polyvar x y
    p = 1.1x + y
    q = -0.1x - y
    output, pullback = ChainRulesCore.rrule(+, p, q)
    @test output == 1.0x
    @test pullback(2) == (NoTangent(), 2, 2)
    @test pullback(x + 3) == (NoTangent(), x + 3, x + 3)
    output, pullback = ChainRulesCore.rrule(differentiate, p, x)
    @test output == 1.1
    @test pullback(q) == (NoTangent(), -0.2x^2 - x*y, NoTangent())
    test_chain_rule(dot, +, (p, q), (q, p), p)
    test_chain_rule(dot, +, (p, q), (p, q), q)
    function _dot(p, q)
        monos = monomials(p + q)
        return dot(coefficient.(p, monos), coefficient.(q, monos))
    end
    function _dot(px::Tuple{<:AbstractPolynomial,NoTangent}, qx::Tuple{<:AbstractPolynomial,NoTangent})
        return _dot(px[1], qx[1])
    end
    test_chain_rule(_dot, differentiate, (p, x), (q, NoTangent()), p)
    test_chain_rule(_dot, differentiate, (p, x), (q, NoTangent()), differentiate(p, x))
    test_chain_rule(_dot, differentiate, (p, x), (q, NoTangent()), differentiate(q, x))
    test_chain_rule(_dot, differentiate, (p, x), (p * q, NoTangent()), p)
end
