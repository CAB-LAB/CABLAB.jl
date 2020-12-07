using ESDL
using Test
using Dates
#Open a remote cube
@testset "Cube Access" begin

c=Cube()

@testset "Access single variable" begin
d = subsetcube(c,variable="air_temperature_2m",lon=(10,11),lat=(51,50),
                time=(Date("2002-01-01"),Date("2008-12-31")))


@test d.data.v.indices==(18:21, 17:20, 93:414)
@test d.axes[1].values==10.125:0.25:10.875
@test d.axes[2].values==50.875:-0.25:50.125
@test isa(d.axes[1],LonAxis)
@test isa(d.axes[2],LatAxis)
end

@testset "Access multiple variables" begin
d2 = subsetcube(c,variable=["air_temperature_2m","gross_primary_productivity"],lon=(10,11),lat=(50,51),
                time=(Date("2002-01-01"),Date("2008-12-31")))

  @test d2.axes[4].values == ["air_temperature_2m", "gross_primary_productivity"]
  @test d2.data.arrays[1].v.indices ==(18:21, 17:20, 93:414)
  @test d2.axes[1].values==10.125:0.25:10.875
  @test d2.axes[2].values==50.875:-0.25:50.125
  @test first(d2.axes[3].values) == Dates.Date(2002,1,5)
  @test last(d2.axes[3].values) == Dates.Date(2008, 12, 30)
end

@testset "Test values in MemCube" begin
d = subsetcube(c,variable="air_temperature_2m",lon=(10,11),lat=(51,50),
                time=(Date("2002-01-01"),Date("2008-12-31")))
d2 = subsetcube(c,variable=["air_temperature_2m","gross_primary_productivity"],lon=(10,11),lat=(50,51),
                time=(Date("2002-01-01"),Date("2008-12-31")))
data1=readcubedata(d)
data2=readcubedata(d2)

@test size(data1.data)==(4,4,322)
@test size(data2.data)==(4,4,322,2)


@test isapprox(data1.data[1,1,1:10],Float32[267.9917, 269.9631, 276.71036, 280.88998,
  280.90665, 277.02243, 274.5466, 276.919, 279.96243, 279.42276])

@test isapprox(data2.data[1,1,1:10,1],Float32[267.9917, 269.9631, 276.71036, 280.88998,
  280.90665, 277.02243, 274.5466, 276.919, 279.96243, 279.42276])

@test caxes(data1)[1:2]==CubeAxis[LonAxis(10.125:0.25:10.875),LatAxis(50.875:-0.25:50.125)]

tax = caxes(data1)[3]
@test isa(tax, TimeAxis)
@test tax.values[1] == Date(2002,01,05)
@test tax.values[end] == Date(2008,12,30)
@test length(tax.values) == 7*46

@test caxes(data2)[[1,2,4]]==CubeAxis[LonAxis(10.125:0.25:10.875),LatAxis(50.875:-0.25:50.125),VariableAxis(["air_temperature_2m","gross_primary_productivity"])]

tax = caxes(data2)[3]
@test isa(tax, TimeAxis)
@test tax.values[1] == Date(2002,01,05)
@test tax.values[end] == Date(2008,12,30)
@test length(tax.values) == 7*46

end

@testset "Coordinate extraction" begin
d = subsetcube(c,variable="air_temperature_2m",lon=(10,11),lat=(51,50),
                time=(Date("2002-01-01"),Date("2008-12-31")))
data1=readcubedata(d)
# Test reading of coordinate list
ll=[10.1 50.2;10.5 51.1;10.8 51.1]
llcube = readcubedata(extractLonLats(data1,ll))
@test llcube.data[1,:]==data1.data[1,4,:]
@test llcube.data[2,:]==data1.data[3,1,:]
@test llcube.data[3,:]==data1.data[4,1,:]
end

@testset "Accessing regions" begin
#Test access datacube by region
d3 = subsetcube(c,variable="gross_primary_productivity",region="Austria",time=Date("2005-01-01"))
@test d3.axes==[LonAxis(9.625:0.25:14.875),LatAxis(48.875:-0.25:47.375)]
end

@testset "Saving and loading cubes" begin
  d = subsetcube(c,variable="air_temperature_2m",lon=(10,31),lat=(51,50),
                  time=(Date("2002-01-01"),Date("2008-12-31")))
  data1=readcubedata(d)
  #Test saving cubes
  dire=tempname()
  ESDLdir(dire)
  saveCube(data1,"mySavedCube")


  data3=readcubedata(loadCube("mySavedCube"))
  @test data1.axes==data3.axes
  @test data1.data==data3.data

  # Test loadOrGenerate macro
  d=subsetcube(c,time=Date(2001)..Date(2005),lon=(10,11),lat=(50,51),variable=["gross_primary_productivity","net_ecosystem_exchange"])

  rmCube("Anomalies")
  @loadOrGenerate danom=>"Anomalies" begin
      danom = removeMSC(d)
  end

  @test danom.data isa Array

  @loadOrGenerate danom=>"Anomalies" begin
      error("This should never execute")
  end;
  @test danom isa ESDL.Cubes.ConcatCube

  saveCube(danom, "mySavedZArrayCube")

  @test danom isa ESDL.Cubes.ConcatCube

  danom=readcubedata(danom)
  danom2=readcubedata(loadCube("mySavedZArrayCube"))

  @test danom.axes==danom2.axes
  @test all(map(isequal,danom.data,danom2.data))

  ncf = tempname()
  exportcube(danom,ncf)

  using NetCDF, Dates
  #Test exportcube
  @test ncread(ncf,"Lon") == 10.125:0.25:10.875
  @test ncread(ncf,"Lat") == 50.875:-0.25:50.125
  @test ncgetatt(ncf,"Time","units") == "days since 2001-01-01"
  @test getAxis("Time",danom).values .- DateTime(2001) == Millisecond.(Day.(ncread(ncf,"Time")))

  anc = replace(ncread(ncf,"gross_primary_productivity")[:,:,:],-9999.0=>missing)
  @test all(isequal.(anc, permutedims(danom[:,:,:,1],(2,3,1))))
  neear = replace(danom[:,:,:,2],missing=>-9999.0)
  @test all(isequal.(ncread(ncf,"net_ecosystem_exchange")[:,:,:],permutedims(neear,(2,3,1))))
end
end
