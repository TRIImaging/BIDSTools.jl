@testset "parse single file" begin
    file_path = joinpath(
        @__DIR__,
        "data/bids_root/sub-subtest/ses-1/test/sub-test_ses-1_run-001_modlbl.nii.gz"
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
    @test my_file.path == file_path
    @test my_file.metadata == metadata
    @test my_file.entities == entities

    metadata_path = joinpath(
        @__DIR__,
        "data/bids_root/sub-subtest/ses-1/test/sub-test_ses-1_run-001_modlbl.json"
    )

    @test get_metadata_path(my_file) == metadata_path
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
end
