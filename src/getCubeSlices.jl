
"""
getCubeSlices(cube,timeRange,lonRange,latRange; variable = "air_temperature_2m")

Extracts slice arrays from a cube given a range in longitude,latitude and time.
- Outputs cFront, cBack, cRight, cLeft, cTop, cBottom to plot a cube.
"""
function getCubeSlices(dataCube::YAXArray, timeRange, lonRange, latRange;
    variable = "air_temperature_2m")
    #front face
    cubef = dataCube[
        var  = variable,
        time = timeRange[1],
        lon  = lonRange,
        lat  = latRange].data[:,:]
    #back face
    cubeb = dataCube[
        var  = variable,
        time = timeRange[2],
        lon  = lonRange,
        lat  = latRange].data[:,:];
    #rigth face
    cuber = dataCube[
        var  = variable,
        time = timeRange,
        lon  = lonRange[2],
        lat  = latRange].data[:,:];
    #left face
    cubel = dataCube[
        var   = variable,
        time  = timeRange,
        lon   = lonRange[1],
        lat   = latRange].data[:,:];
    #top face
    cubet = dataCube[
        var  = variable,
        time = timeRange,
        lon  = lonRange,
        lat  = latRange[2]].data[:,:];
    #bottom face
    cubebt = dataCube[
        var  = variable,
        time = timeRange,
        lon  = lonRange,
        lat  = latRange[1]].data[:,:]
    # replace missing values and sort to properly plot values with Makie
    cubef  = replace(cubef[:,end:-1:1], missing => NaN)
    cubeb  = replace(cubeb[:,end:-1:1], missing => NaN)
    cubet  = replace(cubet', missing => NaN)
    cubebt = replace(cubebt', missing => NaN)
    cubel  = replace(cubel'[:,end:-1:1], missing => NaN)
    cuber = replace(cuber'[:,end:-1:1], missing => NaN) #
    return cubef, cubeb, cuber, cubel, cubet, cubebt
end

export getCubeSlices
