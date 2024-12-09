module BIDSTools

using JSON
using DataStructures
using CSV
using DataFrames
using PrettyTables

include("File.jl")
include("Session.jl")
include("Subject.jl")
include("Layout.jl")
# Class
export
    Layout,
    Subject,
    Session,
    File
# Utility functions
export
    total_subjects,
    total_sessions,
    total_files,
    get_metadata_path,
    get_events_path,
    parse_path,
    parse_fname,
    print_dataset_description,
    list_subject_detail,
    list_scans_detail,
    get_files,
    get_sub,
    get_ses,
    construct_fname,
    subjects,
    sessions,
    files

end # module
