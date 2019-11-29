@testset "parse single subject" begin
    sub_path = joinpath(
        @__DIR__,
        "data/bids_root/sub-subtest/"
    )

    my_sub = Subject(sub_path)

    @test my_sub.path == sub_path
    @test my_sub.identifier == "subtest"
    @test total_sessions(my_sub) == 1
    @test total_files(my_sub) == 1
    @test sprint(show, my_sub) == """
        Subject:
            identifier = subtest
            total session = 1
            total files = 1"""
end
