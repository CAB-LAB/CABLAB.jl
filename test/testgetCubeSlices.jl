# hopefully everything just works :D

## Just tell me your variable(default air_temperature_2m), time range, lon range and lat range.
timeRange = (Date("2003-01-01"), Date("2003-01-31"))
lonRange = (-5, 5)
latRange = (-5, 5)
allFaces = getCubeSlices(c, timeRange, lonRange, latRange)
@test length(allFaces) == 6
