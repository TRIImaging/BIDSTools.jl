@testset "parse single subject" begin
    bids_root = joinpath(
        @__DIR__,
        "data",
        "bids_root"
    )

    my_layout = Layout(bids_root)

    @test my_layout.root == bids_root
    @test my_layout.longitudinal == true
    @test my_layout.description == OrderedDict{String,Any}()
    @test my_layout.subjects_detail == DataFrame()
    @test total_subjects(my_layout) == 1
    @test total_sessions(my_layout) == 1
    @test total_files(my_layout) == 1
    @test sprint(show, my_layout) == """
        Layout:
            root = $bids_root
            total subject = 1
            total session = 1
            total files = 1"""
end

@testset "query files" begin
    # get_files in layout implements all of the get_files (from file subject, and
    # session), so testing the others are not necessary
    bids_root = joinpath(
        @__DIR__,
        "data",
        "bids_root"
    )

    my_layout = Layout(bids_root)

    f = get_files(my_layout, key1="value1", run="001")
    @test length(f) == 1
    @test f[1].path == joinpath(
        @__DIR__,
        "data",
        "bids_root",
        "sub-subtest",
        "ses-1",
        "test",
        "sub-test_ses-1_run-001_modlbl.nii.gz"
    )

    f = get_files(my_layout, key1="value1", run="002")
    @test length(f) == 0

    f = get_files(my_layout, key1="value2", run="001")
    @test length(f) == 0

    f = get_files(my_layout, random_key="value1")
    @test length(f) == 0

    # Test with path argument
    f = get_files(my_layout, path=".nii.gz", key1="value1", run="001")
    @test length(f) == 1

    f = get_files(my_layout, path=".json", key1="value1", run="001")
    @test length(f) == 0
end
