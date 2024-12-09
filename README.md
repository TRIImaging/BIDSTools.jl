# BIDSTools

[![Build Status](https://travis-ci.com/TRIImaging/BIDSTools.jl.svg?branch=master)](https://travis-ci.com/TRIImaging/BIDSTools.jl)
[![CodeCoverage](https://codecov.io/gh/TRIImaging/BIDSTools.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/TRIImaging/BIDSTools.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://triimaging.github.io/BIDSTools.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://triimaging.github.io/BIDSTools.jl/dev)

Tools for working with Brain Imaging Data Structure (BIDS) from Julia.

For more info on BIDS, read [the documentation](https://bids-specification.readthedocs.io/en/stable/)

## Features

* Working with BIDS Directory easily
* Flexible usage - initialize single object as you wish
* Query to get the desired files
* Other utility functions such as `total_sessions`, `parse_fname`, `parse_path`, etc.

## Quick start

```julia-repl
julia> using BIDSTools

julia> layout = Layout("/path/to/bids/root/")
Layout:
    root = /path/to/bids/root/
    total subject = 125
    total session = 137
    total files = 2945

julia> for sub in layout.subjects
           for ses in sub.sessions
               for file in ses.files
                   # do something
               end
           end
       end

julia> files = get_files(layout, path="Subtest", run="002")
1-element Array{File,1}:
File("/path/to/bids/root/sub-Subtest/ses-2/mrs/sub-Subtest_ses-2_acq-96inc_loc-pcg_spec-uns_run-002_mod-cosy_fid.tsv")
```
