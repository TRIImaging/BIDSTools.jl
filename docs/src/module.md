# Module

`BIDSTools` parsed a directory into Julia objects `Layout`, `Subject`, `Session`, and `File`. 
Basically, the idea is `Layout` consists of `Subject`, `Subject` consists of `Session` (there
will always be 1 session in non-longitudinal study), and `Session` contains `File`. 

```@meta
CurrentModule = BIDSTools
DocTestSetup = quote
	using .BIDSTools
end
```

```@autodocs
Modules = [BIDSTools]
Order   = [:type, :function]
Private = false
```