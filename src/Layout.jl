"""
`Layout` has following public fields:

* `root` - the root folder of the data
* `subjects` - a vector of `Subject`
* `longitudinal` - `true` if a longitudinal study, i.e. multi-session/multi-visit per
  subject.
* `description` - dictionary parsed from `dataset_description.json`.
* `subjects_details` - `DataFrame` from `subjects.tsv`

The BIDS directory must follow the specification, i.e.
`root/sub-<subject_id>/[ses-<session_id>]`

The `Layout` can be initialized by specifying only `root`. Other behavior can also be
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
julia> layout = Layout("/path/to/bids/root/")
Layout:
    root = "/path/to/bids/root/"
    total subject = 49
    total session = 74
    total files = 1161
```
"""
struct Layout
    root::String
    subjects::Vector{Subject}
    # With this turned off, not going to look for ses- in path
    longitudinal::Bool
    description::OrderedDict{String,Any}
    subjects_detail::DataFrame
end

subjects(layout::Layout) = layout.subjects

function Layout(
    root::AbstractString;
    search::Bool=true,
    load_metadata::Bool=true,
    require_modality::Bool=true,
    longitudinal::Bool=true,
    strict::Bool=true,
    extract_from_full_path::Bool=true
)
    subjects = Vector{Subject}()
    if search
        # Search for subject, session, and files
        for d in readdir(root)
            if isdir(joinpath(root, d)) && startswith(d, "sub-")
                push!(
                    subjects,
                    Subject(
                        joinpath(root, d),
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
    description = !isfile(joinpath(root, "dataset_description.json")) ?
                  OrderedDict{String,Any}() :
                  JSON.parsefile(
        joinpath(root, "dataset_description.json"),
        dicttype=OrderedDict{String,Any}
    )
    subjects_detail = !isfile(joinpath(root, "subjects.tsv")) ?
                      DataFrame() :
                      CSV.File(joinpath(root, "subjects.tsv"), delim="\t") |>
                      DataFrame!
    Layout(root, subjects, longitudinal, description, subjects_detail)
end

function Layout(root::AbstractString, longitudinal::Bool)
    Layout(root, [], true)
end

#-------------------------------------------------------------------------------

"""
    function total_subjects(layout::Layout)

Get number of subject in the layout
"""
function total_subjects(layout::Layout)
    length(layout.subjects)
end

# Docstring in Subject.jl
function total_sessions(layout::Layout)
    sum(total_sessions, layout.subjects)
end

# Docstring in Session.jl
function total_files(layout::Layout)
    sum(total_files, layout.subjects)
end


function Base.show(io::IO, layout::Layout)
    print(
        io,
        """
  Layout:
      root = $(layout.root)
      total subject = $(total_subjects(layout))
      total session = $(total_sessions(layout))
      total files = $(total_files(layout))"""
    )
end

"""
    function print_dataset_description(layout::Layout)

Function to pretty-print dataset description
"""
function print_dataset_description(layout::Layout)
    print(json(layout.description, 2))
end

"""
    function list_subject_detail(layout::Layout)

Function to pretty print subject spreadsheet (subjects.tsv) using PrettyTables
"""
function list_subject_detail(layout::Layout)
    pretty_table(layout.subjects_detail, crop=:none)
end

# Docstring of get_files is in File.jl
function get_files(
    layout::Layout; path::Union{String,Regex,Nothing}=nothing, kws...
)
    result = Vector{File}()
    for sub in layout.subjects
        files = get_files(sub; path=path, kws...)
        push!(result, files...)
    end
    return result
end
