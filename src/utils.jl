"""
    with_precompile_set(fn; precompile=false)

Call `fn()` while temporarily setting
`ENV["JULIA_PKG_PRECOMPILE_AUTO"] = 0`.
"""
function with_precompile_set(fn; precompile = false)
    # ENV does not always have JULIA_PKG_PRECOMPILE_AUTO
    # precompile_value = ENV["JULIA_PKG_PRECOMPILE_AUTO"]
    x = "JULIA_PKG_PRECOMPILE_AUTO"
    precompile₀ = haskey(ENV, x) ? ENV[x] : nothing
    if !precompile
        @info "Temporarily setting ENV[$x] = 0"
        ENV[x] = 0
    end
    fn()
    if !precompile
        if isnothing(precompile₀)
            pop!(ENV, x)
        else
            ENV[x] = precompile₀
        end
    end
    return precompile₀
end
