"""
The functions provided by ESDL are supposed to work on different types of cubes. This module defines the interface for all
Data types that
"""
module Cubes
export Axes, AbstractCubeData, getSubRange, readcubedata, AbstractCubeMem, axesCubeMem,CubeAxis, TimeAxis, TimeHAxis, QuantileAxis, VariableAxis, LonAxis, LatAxis, CountryAxis, SpatialPointAxis, caxes,
       AbstractSubCube, CubeMem, EmptyCube, YearStepRange, _read, saveCube, loadCube, RangeAxis, CategoricalAxis, axVal2Index, MSCAxis,
       getSingVal, ScaleAxis, axname, @caxis_str, rmCube, cubeproperties, findAxis, AxisDescriptor, get_descriptor, ByName, ByType, ByValue, ByFunction, getAxis,
       getOutAxis, Cube, (..), getCubeData, subsetcube, CubeMask, renameaxis!, Dataset, S3Cube, cubeinfo

"""
    AbstractCubeData{T,N}

Supertype of all cubes. `T` is the data type of the cube and `N` the number of
dimensions. Beware that an `AbstractCubeData` does not implement the `AbstractArray`
interface. However, the `ESDL` functions [`mapCube`](@ref), [`reduceCube`](@ref),
[`readcubedata`](@ref), [`plotMAP`](@ref) and [`plotXY`](@ref) will work on any subtype
of `AbstractCubeData`
"""
abstract type AbstractCubeData{T,N} end

"""
getSingVal reads a single point from the cube's data
"""
getSingVal(c::AbstractCubeData,a...)=error("getSingVal called in the wrong way with argument types $(typeof(c)), $(map(typeof,a))")

Base.eltype(::AbstractCubeData{T}) where T = T
Base.ndims(::AbstractCubeData{<:Any,N}) where N = N

"""
    readCubeData(cube::AbstractCubeData)

Given any type of `AbstractCubeData` returns a [`CubeMem`](@ref) from it.
"""
function readcubedata(x::AbstractCubeData{T,N}) where {T,N}
  s=size(x)
  aout = zeros(Union{T,Missing},s...)
  r=CartesianIndices(s)
  _read(x,aout,r)
  CubeMem(collect(CubeAxis,caxes(x)),aout,cubeproperties(x))
end

"""
This function calculates a subset of a cube's data
"""
function subsetcube end

function _read end

getsubset(x::AbstractCubeData) = x.subset === nothing ? ntuple(i->Colon(),ndims(x)) : x.subset
#"""
#Internal function to read a range from a datacube
#"""
#_read(c::AbstractCubeData,d,r::CartesianRange)=error("_read not implemented for $(typeof(c))")

"Returns the axes of a Cube"
caxes(c::AbstractCubeData)=error("Axes function not implemented for $(typeof(c))")

cubeproperties(::AbstractCubeData)=Dict{String,Any}()

"Chunks, if given"
cubechunks(c::AbstractCubeData) = (size(c,1),map(i->1,2:ndims(c))...)

"Offset of the first chunk"
chunkoffset(c::AbstractCubeData) = ntuple(i->0,ndims(c))

function iscompressed end

"Supertype of all subtypes of the original data cube"
abstract type AbstractSubCube{T,N} <: AbstractCubeData{T,N} end


"Supertype of all in-memory representations of a data cube"
abstract type AbstractCubeMem{T,N} <: AbstractCubeData{T,N} end

include("Axes.jl")
using .Axes
import .Axes: getOutAxis, getAxis
struct EmptyCube{T}<:AbstractCubeData{T,0} end
caxes(c::EmptyCube)=CubeAxis[]

"""
    CubeMem{T,N} <: AbstractCubeMem{T,N}

An in-memory data cube. It is returned by applying `mapCube` when
the output cube is small enough to fit in memory or by explicitly calling
[`readCubeData`](@ref) on any type of cube.

### Fields

* `axes` a `Vector{CubeAxis}` containing the Axes of the Cube
* `data` N-D array containing the data

"""
mutable struct CubeMem{T,N} <: AbstractCubeMem{T,N}
  axes::Vector{CubeAxis}
  data::Array{T,N}
  properties::Dict{String}
end

CubeMem(axes::Vector{CubeAxis},data) = CubeMem(axes,data,Dict{String,Any}())
Base.permutedims(c::CubeMem,p)=CubeMem(c.axes[collect(p)],permutedims(c.data,p))
caxes(c::CubeMem)=c.axes
cubeproperties(c::CubeMem)=c.properties
iscompressed(c::AbstractCubeMem)=false

Base.IndexStyle(::CubeMem)=Base.LinearFast()
function Base.setindex!(c::CubeMem,i::Integer,v)
  c.data[i] = v
end
Base.size(c::CubeMem)=size(c.data)
Base.size(c::CubeMem,i)=size(c.data,i)
Base.similar(c::CubeMem)=CubeMem(c.axes,similar(c.data))
Base.ndims(c::CubeMem{T,N}) where {T,N}=N

readcubedata(c::CubeMem)=c

function getSubRange(c::AbstractArray,i...;write::Bool=true)
  length(i)==ndims(c) || error("Wrong number of view arguments to getSubRange. Cube is: $c \n indices are $i")
  return view(c,i...)
end
getSubRange(c::Tuple{AbstractArray{T,0},AbstractArray{UInt8,0}};write::Bool=true) where {T}=c

function _subsetcube end

function subsetcube(z::CubeMem{T};kwargs...) where T
  newaxes, substuple = _subsetcube(z,collect(Any,map(Base.OneTo,size(z)));kwargs...)
  newdata = z.data[substuple...]
  !isa(newdata,AbstractArray) && (newdata = fill(newdata))
  if haskey(z.properties,"labels")
    alll = filter!(!ismissing,unique(newdata))
    z.properties["labels"] = filter(i->in(i[1],alll),z.properties["labels"])
  end
  CubeMem{T,length(newaxes)}(newaxes,newdata,z.properties)
end

"""
    gethandle(c::AbstractCubeData, [block_size])

Returns an indexable handle to the data.
"""
gethandle(c::AbstractCubeMem) = c.data
gethandle(c::CubeAxis) = collect(c.values)
gethandle(c,block_size)=gethandle(c)


import ..ESDLTools.toRange
#Generic fallback method for _read
function _read(c::CubeMem,thedata::AbstractArray,r::CartesianIndices)
  thedata .= view(c.data,r.indices...)
end

function _write(c::CubeMem,thedata::AbstractArray,r::CartesianIndices)
  cubeview = getSubRange(c.data,r.indices...)
  copyto!(cubeview,thedata)
end


#Implement getindex on AbstractCubeData objects
const IndR = Union{Integer,Colon,UnitRange}
getfirst(i::Integer,a::CubeAxis)=i
getlast(i::Integer,a::CubeAxis)=i
getfirst(i::UnitRange,a::CubeAxis)=first(i)
getlast(i::UnitRange,a::CubeAxis)=last(i)
getfirst(i::Colon,a::CubeAxis)=1
getlast(i::Colon,a::CubeAxis)=length(a)

function Base.getindex(c::AbstractCubeData,i::Integer...)
  length(i)==ndims(c) || error("You must provide $(ndims(c)) indices")
  r = CartesianIndices((first(i):first(i),Base.tail(i)...))
  aout = zeros(eltype(c),size(r))
  _read(c,aout,r)
  return aout[1]
end

function Base.getindex(c::AbstractCubeData,i::IndR...)
  length(i)==ndims(c) || error("You must provide $(ndims(c)) indices")
  ax = (caxes(c)...,)
  r = CartesianIndices(map((ii,iax)->getfirst(ii,iax):getlast(ii,iax),i,ax))
  lall = map((rr,ii)->(length(rr),!isa(ii,Integer)),r.indices,i)
  lshort = filter(ii->ii[2],collect(lall))
  newshape = map(ii->ii[1],lshort)
  aout = Array{eltype(c)}(undef,newshape...)
  if newshape == size(r)
    _read(c,aout,r)
  else
    _read(c,reshape(aout,size(r)),r)
  end
  aout
end
Base.read(d::AbstractCubeData) = getindex(d,fill(Colon(),ndims(d))...)

function formatbytes(x)
  exts=["bytes","KB","MB","GB","TB"]
  i=1
  while x>=1024
    i=i+1
    x=x/1024
  end
  return string(round(x, digits=2)," ",exts[i])
end
cubesize(c::AbstractCubeData{T}) where {T}=(sizeof(T)+1)*prod(map(length,caxes(c)))
cubesize(c::AbstractCubeData{T,0}) where {T}=sizeof(T)+1

getCubeDes(c::AbstractSubCube)="Data Cube view"
getCubeDes(::CubeAxis)="Cube axis"
getCubeDes(c::CubeMem)="In-Memory data cube"
getCubeDes(c::EmptyCube)="Empty Data Cube (placeholder)"
function Base.show(io::IO,c::AbstractCubeData)
    println(io,getCubeDes(c), " with the following dimensions")
    for a in caxes(c)
        println(io,a)
    end

    foreach(cubeproperties(c)) do p
      if p[1] in ("labels","name","units")
        println(io,p[1],": ",p[2])
      end
    end
    println(io,"Total size: ",formatbytes(cubesize(c)))
end

import ..ESDL.workdir
using NetCDF

function check_overwrite(newfolder, overwrite)
  if isdir(newfolder)
    if overwrite
      rm(newfolder, recursive=true)
    else
      error("$(newfolder) already exists, please pick another name or use `overwrite=true`")
    end
  end
end
function getsavefolder(name)
  if isempty(name)
    name = tempname()[2:end]
  end
  isabspath(name) ? name : joinpath(workdir[1],name)
end

"""
    saveCube(cube,name::String)

Save a [`ZarrCube`](@ref) or [`CubeMem`](@ref) to the folder `name` in the ESDL working directory.

See also [`loadCube`](@ref)
"""
function saveCube end


# function saveCube(c::CubeMem{T},name::AbstractString; overwrite=true) where T
#   newfolder=getsavefolder(name)
#   check_overwrite(newfolder, overwrite)
#   tc=Cubes.ESDLZarr.ZArrayCube(c.axes,folder=newfolder,T=T)
#   _write(tc,c.data,CartesianIndices(c.data))
# end

import Base.Iterators: take, drop
Base.show(io::IO,a::RangeAxis)=print(io,rpad(Axes.axname(a),20," "),"Axis with ",length(a)," Elements from ",first(a.values)," to ",last(a.values))
function Base.show(io::IO,a::CategoricalAxis)
  print(io,rpad(Axes.axname(a),20," "), "Axis with ", length(a), " elements: ")
  if length(a.values)<10
    for v in a.values
      print(io,v," ")
    end
  else
    for v in take(a.values,2)
      print(io,v," ")
    end
    print(io,".. ")
    for v in drop(a.values,length(a.values)-2)
      print(io,v," ")
    end
  end
end
Base.show(io::IO,a::SpatialPointAxis)=print(io,"Spatial points axis with ",length(a.values)," points")


include("TransformedCubes.jl")
function S3Cube end
include("ZarrCubes.jl")
import .ESDLZarr: (..), Cube, getCubeData, loadCube, rmCube, CubeMask, cubeinfo, getsubinds
include("NetCDFCubes.jl")
include("Datasets.jl")
import .Datasets: Dataset, ESDLDataset
include("OBS.jl")
end
