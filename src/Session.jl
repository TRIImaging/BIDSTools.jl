"""
`Session` has following public fields:

* `path` - path to the session directory
* `identifier` - identifier of session, extracted from directory name
  `ses-<session_id>`. In non-longitudinal study, this will always be "1".
* `files` - a vector of `File`
* `scans_details` - `DataFrame` parsed from `*_scans.tsv`. If the tsv is not exist, this
  will be an empty `DataFrame`

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
julia> ses = Session("/path/to/bids/root/sub-Subtest/ses-1/")
Session:
    identifier = 1
    total files = 8
```
"""
struct Session
    path::String
    identifier::String
    files::Vector{File}
    scans_detail::DataFrame
end

function Session(
    path::AbstractString;
    search::Bool=true,
    load_metadata::Bool=true,
    require_modality::Bool=true,
    longitudinal::Bool=true,
    strict::Bool=true,
    extract_from_full_path::Bool=true
)
    files = Vector{File}()
    scans_detail = nothing
    identifier = nothing
    # If not longitudinal, the subject dir == ses dir and session id will
    # always be 1 (only consists of 1 session/subject)
    if longitudinal
        sep = Vector{Char}(Base.Filesystem.path_separator)
        @assert startswith(basename(rstrip(path, sep)), "ses-")
        identifier = replace(basename(rstrip(path, sep)), "ses-" => "")
    else
        identifier = "1"
    end
    # Look for _scans.tsv
    for d in readdir(path)
        if isnothing(scans_detail)
            scans_detail = isfile(joinpath(path, d)) && endswith(d, "_scans.tsv") ?
                           CSV.File(joinpath(path, d)) |> DataFrame! : nothing
        end
    end
    if search
        # Search for files
        for d in readdir(path)
            !isdir(joinpath(path, d)) && continue
            for f in readdir(joinpath(path, d))
                # Ignore json-sidecar since it'll go to the metadata
                if isfile(joinpath(path, d, f)) && !endswith(f, ".json") && !endswith(f, "_events.tsv")
                    push!(
                        files,
                        File(
                            joinpath(path, d, f),
                            load_metadata=load_metadata,
                            require_modality=require_modality,
                            strict=strict,
                            extract_from_full_path=extract_from_full_path
                        )
                    )
                end
            end
        end
    end
    if isnothing(scans_detail)
        scans_detail = DataFrame()
    end
    Session(path, identifier, files, scans_detail)
end

files(session::Session) = session.files
#-------------------------------------------------------------------------------

"""
    function total_files(session::Session)

Get number of files in a session. The argument `Session` can be changed into `Subject`
or `Layout`.
"""
function total_files(session::Session)
    length(session.files)
end

function Base.show(io::IO, session::Session)
    print(
        io,
        """
  Session:
      identifier = $(session.identifier)
      total files = $(total_files(session))"""
    )
end

"""
    function list_scans_detail(session::Session)

Function to pretty print scans detail spreadsheet (_scans.tsv) using PrettyTables
"""
function list_scans_detail(session::Session)
    pretty_table(session.scans_detail, crop=:none)
end

# Docstring of get_files is in File.jl
function get_files(
    session::Session; path::Union{String,Regex,Nothing}=nothing, kws...
)
    result = get_files(session.files; path=path, kws...)
    return result
end
