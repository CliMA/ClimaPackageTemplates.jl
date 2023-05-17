import Documenter, DocumenterCitations
import ClimaPackageTemplateName

bib = DocumenterCitations.CitationBibliography(joinpath(@__DIR__, "refs.bib"))

mathengine = Documenter.MathJax(
    Dict(
        :TeX => Dict(
            :equationNumbers => Dict(:autoNumber => "AMS"),
            :Macros => Dict(),
        ),
    ),
)

format = Documenter.HTML(
    prettyurls = !isempty(get(ENV, "CI", "")),
    mathengine = mathengine,
    collapselevel = 1,
)

Documenter.makedocs(;
    plugins = [bib],
    sitename = "ClimaPackageTemplateName.jl",
    format = format,
    checkdocs = :exports,
    clean = true,
    doctest = true,
    modules = [ClimaPackageTemplateName],
    pages = Any[
        "Home" => "index.md",
        "API" => "api.md",
        "References" => "references.md",
    ],
)

Documenter.deploydocs(
    repo = "github.com/CliMA/ClimaPackageTemplateName.jl.git",
    target = "build",
    push_preview = true,
    devbranch = "main",
    forcepush = true,
)
