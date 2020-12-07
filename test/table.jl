using ESDL
using OnlineStats
using WeightedOnlineStats
using Test
using DataFrames
using CSV
using StatsBase
using RDatasets
using Statistics

iris = dataset("datasets", "iris")

@testset "TableAggregator functions" begin
    fitMean = fittable(DataFrames.eachrow(iris), Mean, :SepalWidth)
    @test value(fitMean) ≈ mean(iris[!,:SepalWidth])

    minSepalLength, maxSepalLength = extrema(iris[!,:SepalLength])
    weightVector = map(x -> (x - minSepalLength) /
                    (maxSepalLength - minSepalLength), iris[!,:SepalLength]
                    )
    fitMeanWeight = fittable(DataFrames.eachrow(iris), WeightedMean, :SepalWidth,
                    weight=(x -> (x.SepalLength - minSepalLength) /
                        (maxSepalLength - minSepalLength)
                        )
                    )
    @test value(fitMeanWeight) ≈ mean(iris[!,:SepalWidth], weights(weightVector))

    # meanBy = combine(groupby(iris, :Species), SepalWidth => mean)
    # cn = names(meanBy)[2]
    # fitMeanBy = fittable(DataFrames.eachrow(iris), Mean, :SepalWidth, by=(:Species,))
    # for (key, value) in value(fitMeanBy)
    #     @test value ≈ meanBy[meanBy[:Species] .== key, cn][1]
    # end

    # meanByWeight = by(iris, :Species,
    #                     SepalWidth_mean = [:SepalWidth, :SepalLength] =>
    #                         (x -> mean(x.SepalWidth,
    #                             weights(map(x -> (x - minSepalLength) /
    #                                         (maxSepalLength - minSepalLength),
    #                                         x.SepalLength)
    #                                     )
    #                             )
    #                         )
    #                 )
    # fitMeanByWeight = fittable(DataFrames.eachrow(iris), WeightedMean,
    #                             :SepalWidth, by=(:Species,),
    #                             weight=(x -> (x.SepalLength - minSepalLength) /
    #                                         (maxSepalLength - minSepalLength)
    #                                     )
    #                             )
    # for (key, value) in value(fitMeanByWeight)
    #     @test value ≈ meanByWeight[meanByWeight[!,:Species] .== key, :SepalWidth_mean][1]
    # end
end
