"""
`File` has following public fields:

* `path` - path to the file
* `metadata` - dictionary parsed from JSON-sidecar
* `entities` - dictionary parsed from key-value filename

The `File` can be initialized by specifying only `path`. Other behavior can also be
tweaked accordingly with the optional parameters:

* `load_metadata::Bool` - defaults to `true`. If `true`, this expects a JSON-sidecar to
  be present alongside with every BIDS files.
* `require_modality::Bool` - defaults to `true`. If `true` this expects a modality
  presents in every file name, e.g. sub-subtest_ses-1_run-001_**T1w**.nii.gz
* `strict::Bool` - defaults to `true`. If `true`, `BIDSTools` will throw an error on
  invalid BIDS filename, this can be turned to `false` to not parse those file names
  and display a warning instead. This will result in empty dictionary in `entities`.

# Example

```julia-repl
julia> file = File("/path/to/bids/root/sub-Subtest/ses-1/anat/sub-Subtest-1_run-001_T1w.nii.gz")
File:
    path = /path/to/bids/root/sub-Subtest/ses-1/anat/sub-Amelll_ses-1_run-001_T1w.nii.gz
    metadata_exist = true
```
"""
struct File
    path::String
    # This is the metadata from JSON-sidecar (doesn't exists in BIDS-like directory)
    metadata::OrderedDict{String, Any}
    # Entities are the key-value from filename
    entities::OrderedDict{String, String}
end

function File(
    path::AbstractString;
    load_metadata::Bool=true,
    require_modality::Bool=true,
    strict::Bool=true
)
    entities = parse_path(path, require_modality=require_modality, strict=strict)
    metadata = !load_metadata ? OrderedDict{String,Any}() :
               JSON.parsefile(
                   get_metadata_path(path), dicttype=OrderedDict{String,Any}
               )
    File(path, metadata, entities)
end

#-------------------------------------------------------------------------------

function Base.show(io::IO, file::File)
    if length(file.metadata) == 0
        print(io, "File($(repr(file.path)), no_metadata=true)")
    else
        print(io, "File($(repr(file.path)))")
    end
end

"""
    function get_metadata_path(path)

Get file path of metadata file (json sidecar) for a BIDS `path` which can be a string or
`File`.
"""
function get_metadata_path(file::File)
    get_metadata_path(file.path)
end

function get_metadata_path(path::AbstractString)
    fname_without_ext = split(basename(path), ".")[1]
    this_dirname = dirname(path)

    metadata_path = isfile(joinpath(this_dirname, fname_without_ext*".json")) ?
                    joinpath(this_dirname, fname_without_ext*".json") : nothing
    return metadata_path
end

"""
    function parse_path(path; require_modality::Bool=true, strict::Bool=true)

Function to parse path of a File to Dictionary. The argument `path` can be
a `File` or path (any `String` object implementing `AbstractString`). This function
implements `parse_fname`.

The following keyword arguments can be passed:

* `require_modality::Bool` - defaults to `true`. If `true` this expects a modality
  presents in every file name, e.g. sub-subtest_ses-1_run-001_**T1w**.nii.gz
* `strict::Bool` - defaults to `true`. If `true`, `BIDSTools` will throw an error on
  invalid BIDS filename, this can be turned to `false` to not parse those file names
  and display a warning instead. This will result in empty dictionary in `entities`.
"""
parse_path(file::File; kws...) = parse_path(file.path; kws...)

function parse_path(
    path::AbstractString; require_modality::Bool=true, strict::Bool=true
)
    fname = basename(path)
    parse_fname(fname, require_modality=require_modality, strict=strict)
end


"""
    function parse_fname(
        fname::AbstractString; require_modality::Bool=true, strict::Bool=true
    )

Function to parse filename keys and values with this following structure
`<k1>-<v1>_<k2>-<v2>_..._<kn>-<vn>`

The following keyword arguments can be passed:

* `require_modality::Bool` - defaults to `true`. If `true` this expects a modality
  presents in every file name, e.g. sub-subtest_ses-1_run-001_**T1w**.nii.gz
* `strict::Bool` - defaults to `true`. If `true`, `BIDSTools` will throw an error on
  invalid BIDS filename, this can be turned to `false` to not parse those file names
  and display a warning instead. This will result in empty dictionary in `entities`.

This function returns a dictionary containing those keys and values.
"""
function parse_fname(
    fname::AbstractString; require_modality::Bool=true, strict::Bool=true
)
    fname_without_ext = split(fname, ".")[1]
    parts = [split(part, '-') for part in split(fname_without_ext, '_')]
    if require_modality
        # Add modality entitiy
        modality = pop!(parts)
        @assert length(modality) == 1 "Got unexpected modality $(modality)"
        push!(parts, ["modality", modality[1]])
    end
    d = OrderedDict{String,String}()
    for (idx, part) in enumerate(parts)
        if length(part) != 2
            msg = """Invalid BIDS file name $fname
                     (part $(join(part, '-')) should have exactly one '-')"""
            if strict
                error(msg)
            else
                @warn msg
                return OrderedDict{String, String}()
            end
        end
        k,v = part
        if haskey(d, k)
            msg = "Invalid BIDS file name (key $k occurs twice)"
            if strict
                error(msg)
            else
                @warn msg
                return OrderedDict{String, String}()
            end
        elseif isempty(k)
            msg = "Empty key in pair $k-$v"
            if strict
                error(msg)
            else
                @warn msg
                return OrderedDict{String, String}()
            end
        end
        d[k] = v
    end
    d
end

"""
    function check_entities_meta(file::File; kws...)

Private function to check whether keywords argument in metadata or in entities. Return
false if the key could not be found anywhere or the value of given key is not the same.
"""
function check_entities_meta(file::File; kws...)
    for (k,v) in kws
        keystr = string(k)
        meta_val = get(file.entities, keystr) do
            get(file.metadata, keystr, nothing)
        end
        if isnothing(meta_val) || meta_val != v
            return false
        end
    end
    return true
end

"""
    function get_files(
        files::Vector{File}; path::Union{String, Regex, Nothing}=nothing, kws...
    )

Function to query files based on their `path`, `entities`, and `metadata`. `path` is
optional and can be passed as either `String` or `Regex`, while entities and metadata
can be passed as keyword args, i.e. `key="value"`.

In addition to querying vector of File, this can also be used to obtain desired files
in a `Layout`, `Subject`, or `Session` by simply replacing Vector{File} into desired
object.

# Example

```julia
filtered_files = get_files(files, path="anat", run="002", modality="T1w")

# Filter from layout only from entities and metadata
filtered_files = get_files(layout, run="002", modality="T1w")
```
"""
function get_files(
    files::Vector{File}; path::Union{String, Regex, Nothing}=nothing, kws...
)
    if !isnothing(path)
        filter!(x->occursin(path, x.path), files)
    end
    result = filter(files) do f
        check_entities_meta(f; kws...)
    end
    return result
end
