@testset "parse single session" begin
    ses_path = joinpath(
        @__DIR__,
        "data",
        "bids_root",
        "sub-subtest",
        "ses-1"
    )

    my_ses = Session(ses_path)

    @test my_ses.path == ses_path
    @test my_ses.identifier == "1"
    @test my_ses.scans_detail == DataFrame()
    @test total_files(my_ses) == 1
    @test sprint(show, my_ses) == """
        Session:
            identifier = 1
            total files = 1"""
end
