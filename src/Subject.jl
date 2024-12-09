"""
`Subject` has following public fields:

* `path` - path to the subject directory
* `identifier` - identifier of subject, extracted from directory name `sub-<subject_id>`
* `sessions` - a vector of `Session`

The `Subject` can be initialized by specifying only `path`. Other behavior can also be
tweaked accordingly with the optional parameters:

* `search::Bool` - defaults to `true`. If `true` this will search over `root` to find
  `Subject`, `Session` and `Files`.
* `load_metadata::Bool` - defaults to `true`. If `true`, this expects a JSON-sidecar to
  be present alongside with every BIDS files.
* `require_modality::Bool` - defaults to `true`. If `true` this expects a modality
  presents in every file name, e.g. sub-subtest_ses-1_run-001_**T1w**.nii.gz
* `longitudinal::Bool` - defaults to `true`. If `true` this expects a session directory
  `ses-` exists under subject directory.
* `strict::Bool` - defaults to `true`. If `true`, `BIDSTools` will throw errors on
  invalid BIDS filenames, this can be turned to `false` to not parse those file names
  and display a warning instead.
* `extract_from_full_path::Bool` - defaults to `true`. If `true`, will try to extract
  `sub` and `ses` from full path and append to `entities` if they can't be found in the
  parsed filename.

# Example

```julia-repl
julia> sub = Subject("/path/to/bids/root/sub-Subtest/")
Subject:
    identifier = Subtest
    total session = 1
    total files = 8
```
"""
struct Subject
    path::String
    identifier::String
    sessions::Vector{Session}
end

sessions(subject::Subject) = subject.sessions

function Subject(
    path::AbstractString;
    search::Bool=true,
    load_metadata::Bool=true,
    require_modality::Bool=true,
    longitudinal::Bool=true,
    strict::Bool=true,
    extract_from_full_path::Bool=true
)
    sessions = Vector{Session}()
    sep = Vector{Char}(Base.Filesystem.path_separator)
    @assert startswith(basename(rstrip(path, sep)), "sub-")
    identifier = replace(basename(rstrip(path, sep)), "sub-" => "")
    if search
        for d in readdir(path)
            if isdir(joinpath(path, d)) && startswith(d, "ses-")
                push!(
                    sessions,
                    Session(
                        joinpath(path, d),
                        search=search,
                        load_metadata=load_metadata,
                        require_modality=require_modality,
                        longitudinal=longitudinal,
                        strict=strict,
                        extract_from_full_path=extract_from_full_path
                    )
                )

            end
        end
    end
    Subject(path, identifier, sessions)
end

#-------------------------------------------------------------------------------

"""
    function total_sessions(subject::Subject)

Get number of session of a subject. The argument `Subject` can be changed into `Layout`.
"""
function total_sessions(subject::Subject)
    length(subject.sessions)
end

# Docstring in Session.jl
function total_files(subject::Subject)
    sum(total_files, subject.sessions)
end

function Base.show(io::IO, subject::Subject)
    print(
        io,
        """
  Subject:
      identifier = $(subject.identifier)
      total session = $(total_sessions(subject))
      total files = $(total_files(subject))"""
    )
end

# Docstring of get_files is in File.jl
function get_files(
    subject::Subject; path::Union{String,Regex,Nothing}=nothing, kws...
)
    result = Vector{File}()
    for ses in subject.sessions
        files = get_files(ses; path=path, kws...)
        push!(result, files...)
    end
    return result
end
