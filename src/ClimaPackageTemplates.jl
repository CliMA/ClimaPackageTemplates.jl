module ClimaPackageTemplates

using Pkg
using REPL.TerminalMenus
if VERSION >= v"1.6.0"
    radio_menu(options; kwargs...) =
        TerminalMenus.RadioMenu(options; charset = :ascii, kwargs...)
else
    radio_menu(options; kwargs...) = TerminalMenus.RadioMenu(options; kwargs...)
end


include("utils.jl")
include("common_package_uuids.jl")

"""
    make_package(;
        pkg_dir,
        pkgname
    )
"""
function make_package(;
    pkg_dir,
    pkgname,
    deps::Vector{String} = String[],
    extras::Vector{String} = String["Test", "Aqua"],
)
    pkgname_with_jl = endswith(pkgname, ".jl") ? pkgname : string(pkgname, ".jl")
    pkgname_no_jl = replace(pkgname_with_jl, ".jl" => "")
    cd(pkg_dir) do

        path_to_delete = joinpath(pkg_dir, pkgname_with_jl)
        options = ["No, stop!", "Continue."]
        menu = radio_menu(options)
        msg = "\n\nClimaPackageTemplates.jl is about delete files in the following path.\n\n\t$(pwd())\n\n"
        msg *= "Please select one of the following options:"
        choice = TerminalMenus.request(msg, menu)
        if choice == 2
            @info "Continuing with generating CliMA package."
        else
            @warn "Leaving without generating package."
            return nothing
        end

        # Cleanup
        for f in readdir()
            occursin(".git", f) && continue
            occursin("LICENSE", f) && continue
            occursin("README.md", f) && continue
            rm(f; recursive = true, force = true)
        end
        rm(path_to_delete; recursive = true, force = true)

        # New package, move
        Pkg.generate(pkgname)
        new_pkg_contents = readdir(pkgname_with_jl)
        for x in new_pkg_contents
            mv(joinpath(pkgname_with_jl, x), joinpath(".", x))
        end
        rm(pkgname_with_jl; force = true)

        # Make directory tree
        ispath("docs") || mkdir("docs")
        ispath(".github") || mkdir(".github")
        ispath(".github/workflows") || mkdir(".github/workflows")
        ispath("test") || mkdir("test")
        ispath("docs/src") || mkdir("docs/src")

        # Update Project.toml
        project_lines = map(readlines("Project.toml")) do line
            if occursin("authors = [", line)
                "authors = [\"CliMA Contributors <clima-software@caltech.edu>\"]"
            else
                line
            end
        end
        project_contents = join(project_lines, "\n")
        open(io -> println(io, project_contents), "Project.toml", "w")
        project_contents = join(readlines("Project.toml"), "\n")
        project_extras_contents = make_project_extras_contents(extras)
        project_contents = string(project_contents, "\n\n", project_extras_contents)
        open(io -> println(io, project_contents), "Project.toml", "w")

        # Dependencies
        with_precompile_set() do
            with_precompile_set() do
                for dep in deps
                    Pkg.add(dep)
                end
            end
        end

        # NEWS
        write_template("news.md", pkgname_no_jl)

        # Github Actions
        write_template("CompatHelper.yml", pkgname_no_jl)
        write_template("TagBot.yml", pkgname_no_jl)
        write_template("invalidations.yml", pkgname_no_jl)
        write_template("DocCleanup.yml", pkgname_no_jl)
        write_template("ci.yml", pkgname_no_jl)
        write_template("JuliaFormatter.yml", pkgname_no_jl)
        write_template("docs.yml", pkgname_no_jl)

        # Docs
        write_template("docs_make.jl", pkgname_no_jl)
        write_template("docs_index.md", pkgname_no_jl)
        write_template("docs_api.md", pkgname_no_jl)
        write_template("refs.bib", pkgname_no_jl)
        write_template("refs.bib", pkgname_no_jl)
        contents = template_contents("docs_project.toml", pkgname_no_jl)
        project_uuid = last(split(readlines("Project.toml")[2], "uuid = \""))[1:end-1]
        @show project_uuid
        contents = replace(
            contents,
            "$pkgname_no_jl = \"\"" => "$pkgname_no_jl = \"$project_uuid\"",
        )
        open(io -> println(io, contents), target_file("docs_project.toml"), "w")
        cd("docs/") do
            Pkg.activate()
            with_precompile_set() do
                Pkg.add("Documenter")
                Pkg.add("DocumenterCitations")
            end
        end

        # Test
        write_template("test_runtests.jl", pkgname_no_jl)

        # Apply formatter
        run(`$(Base.julia_cmd()) -e 'using JuliaFormatter; format(".")'`)
    end
end

#! format: off
templates() = Dict{String,String}(
    "docs_make.jl"        => joinpath(@__DIR__, "..", "templates", "docs", "make.jl"),
    "docs_index.md"       => joinpath(@__DIR__, "..", "templates", "docs", "src", "index.md"),
    "docs_api.md"         => joinpath(@__DIR__, "..", "templates", "docs", "src", "api.md"),
    "docs_project.toml"   => joinpath(@__DIR__, "..", "templates", "docs", "Project.toml"),
    "refs.bib"            => joinpath(@__DIR__, "..", "templates", "docs", "refs.bib"),
    "references.md"       => joinpath(@__DIR__, "..", "templates", "docs", "src", "references.md"),
    "test_runtests.jl"    => joinpath(@__DIR__, "..", "templates", "test", "runtests.jl"),
    "project_extras.toml" => joinpath(@__DIR__, "..", "templates", "Project_extras.toml"),
    "news.md"             => joinpath(@__DIR__, "..", "templates", "NEWS.md"),
    "pr_template.md"      => joinpath(@__DIR__, "..", "templates", ".github", "pull_request_template.md"),
    "CompatHelper.yml"    => joinpath(@__DIR__, "..", "templates", ".github", "workflows", "CompatHelper.yml"),
    "TagBot.yml"          => joinpath(@__DIR__, "..", "templates", ".github", "workflows", "TagBot.yml"),
    "invalidations.yml"   => joinpath(@__DIR__, "..", "templates", ".github", "workflows", "invalidations.yml"),
    "DocCleanup.yml"      => joinpath(@__DIR__, "..", "templates", ".github", "workflows", "DocCleanup.yml"),
    "ci.yml"              => joinpath(@__DIR__, "..", "templates", ".github", "workflows", "ci.yml"),
    "JuliaFormatter.yml"  => joinpath(@__DIR__, "..", "templates", ".github", "workflows", "JuliaFormatter.yml"),
    "docs.yml"            => joinpath(@__DIR__, "..", "templates", ".github", "workflows", "docs.yml"),
)
#! format: on

function template_contents(name, pkgname; replace_pkgname::Bool = true)
    contents = join(readlines(templates()[name]), "\n")
    if replace_pkgname
        return replace(contents, "ClimaPackageTemplateName" => pkgname)
    else
        return contents
    end
end

function target_file(name)
    file = joinpath(split(templates()[name], joinpath(@__DIR__, "..", "templates")))
    return startswith(file, "/") ? file[2:end] : file
end

function write_template(name, pkgname; replace_pkgname::Bool = true)
    file = target_file(name)
    open(io -> println(io, template_contents(name, pkgname; replace_pkgname)), file, "w")
end

function make_project_extras_contents(extras)
    s = "[extras]\n"
    uuids = common_package_uuids()
    for e in extras
        s *= "$e = \"$(uuids[e])\"\n"
    end
    s *= "\n"
    s *= "[targets]\n"
    s *= "test = $(string(extras))"
    return s
end

end # module ClimaPackageTemplates
