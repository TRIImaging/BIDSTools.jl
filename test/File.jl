@testset "parse single file" begin
    file_path = joinpath(
        @__DIR__,
        "data",
        "bids_root",
        "sub-subtest",
        "ses-1",
        "test",
        "sub-test_ses-1_run-001_modlbl.nii.gz"
    )

    my_file = File(file_path)

    metadata = OrderedDict(
        "key1" => "value1",
        "key2" => "value2"
    )
    entities = OrderedDict(
        "sub" => "test",
        "ses" => "1",
        "run" => "001",
        "modality" => "modlbl"
    )
    events = DataFrame(
        onset=[1143.0],
        duration=[70.0],
        eventType=["dummy"],
        confidence=["n/a"],
        channels=["T4,T6"],
        dateTime=["2016-01-01 19:39:33"],
        recordingDuration=[2625.0]
    )

    @test my_file.path == file_path
    @test my_file.metadata == metadata
    @test my_file.entities == entities
    @test my_file.events == events

    metadata_path = joinpath(
        @__DIR__,
        "data",
        "bids_root",
        "sub-subtest",
        "ses-1",
        "test",
        "sub-test_ses-1_run-001_modlbl.json"
    )
    events_path = joinpath(
        @__DIR__,
        "data",
        "bids_root",
        "sub-subtest",
        "ses-1",
        "test",
        "sub-test_ses-1_run-001_events.tsv"
    )

    @test get_metadata_path(my_file) == metadata_path
    @test get_events_path(my_file) == events_path
    @test get_sub(my_file) == "test"
    @test get_ses(my_file) == "1"
    @test get_sub(
        dirname(my_file.path) * Base.Filesystem.path_separator, from_fname=false
    ) == "subtest"
    @test get_ses(
        dirname(my_file.path) * Base.Filesystem.path_separator, from_fname=false
    ) == "1"

    new_path = joinpath(dirname(file_path), "run-001_modlbl.nii.gz")
    mv(file_path, new_path)
    my_file = File(new_path, load_metadata=false, load_events=false)
    @test my_file.path == new_path
    @test my_file.metadata == OrderedDict{String,Any}()
    entities["sub"] = "subtest"
    @test my_file.entities == entities
    mv(new_path, file_path)
end

@testset "parse filename" begin
    fname = "sub-test_ses-1_run-001_modlbl.json"
    entities = OrderedDict(
        "sub" => "test",
        "ses" => "1",
        "run" => "001",
        "modality" => "modlbl"
    )
    @test parse_fname(fname) == entities

    # Fail tests
    fname_err = [
        (
            "sub-subtest_ses-1_run-001_key-nomoderror.nii.gz",
            AssertionError(
                """Got unexpected modality SubString{String}["key", "nomoderror"]"""
            )
        ),
        (
            "sub-subtest_ses-1-more-than-one-dash_run-001_mod.nii.gz",
            ErrorException(
                """Invalid BIDS file name sub-subtest_ses-1-more-than-one-dash_run-001_mod.nii.gz
                     (part ses-1-more-than-one-dash should have exactly one '-')"""
            )
        ),
        (
            "sub-subtest_key_without_val_mod.nii.gz",
            ErrorException(
                """Invalid BIDS file name sub-subtest_key_without_val_mod.nii.gz
                     (part key should have exactly one '-')"""
            )
        ),
        (
            "sub-subtest_key1-val1_key1-val2_mod.nii.gz",
            ErrorException("Invalid BIDS file name (key key1 occurs twice)")
        ),
        (
            "sub-subtest_-val1_mod.nii.gz",
            ErrorException("Empty key in pair -val1")
        )
    ]
    for (fname_test, e) in fname_err
        @test_throws e parse_fname(fname_test)
    end

    @test construct_fname(entities, ext="json") == fname
end
