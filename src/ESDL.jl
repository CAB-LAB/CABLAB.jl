"""
## The Earth System Data Cube
![](http://earthsystemdatacube.net/wp-content/uploads/2015/07/EarthDataCube3.png "The DataCube")

Some info on the project...
"""
module ESDL

include("Proc.jl")
include("countrydict.jl")
include("esdc.jl")

using YAXArrays: @reexport

@reexport using Dates: Date, DateTime
@reexport using YAXArrays: (..)
@reexport using YAXArrays: concatenatecubes, caxes,
  subsetcube, readcubedata,renameaxis!, YAXArray
@reexport using YAXArrays: CubeAxis, RangeAxis, CategoricalAxis,
  getAxis

@reexport using YAXArrays: mapCube, getAxis, InDims, OutDims, Dataset,
      CubeTable, cubefittable, fittable, savecube, Cube, open_dataset #From DAT module
@reexport using .Proc: removeMSC, gapFillMSC,normalizeTS,
  getMSC, filterTSFFT, getNpY,
  getMedSC, extractLonLats, cubefromshape,
  gapfillpoly, spatialinterp #From Proc module
@reexport using YAXArrays: @loadOrGenerate # from ESDL Tools

@reexport using .ESDC: esdc, esdd

using NetCDF: NetCDF
using Zarr: Zarr

include("cubeinfo.jl")
include("getCubeSlices.jl")

using YAXArrays: YAXDefaults
function __init__()
    push!(YAXDefaults.subsetextensions, replaceregion)
end

end # module
