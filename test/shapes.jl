#Test whether the cubefromshape for a shapefile with a different CRS works when we set wrap to nothing
@testset "Load shapefile with wrap=nothing" begin
cube = Cube("data/s1_jurua_singlelake_large.nc")
shape = cubefromshape("data/s1_jurua_singlelake_select.shp", cube, wrap=nothing)
inds = findall(isequal.(shape.data, 1))
#This test makes sure, that the indices are inside the lake values
#We don't compare the values directly, because the rasterization can still be shifted by half a pixel
@test all([cube[ind.I...] for ind in inds] .<0.015)
end