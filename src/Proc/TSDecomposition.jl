module TSDecomposition
export filterTSFFT
importall ..Cubes
importall ..DAT
importall ..CubeAPI
importall ..Proc

function detrendTS!{T}(outar::Matrix,xin::Vector{T})
    x=T[i for i in 1:length(xin)]
    a,b=linreg(x,xin)
    for i in eachindex(xin)
        outar[i,1]=a+b*x[i]
    end
end

function tscale2ind(b::Float64,l::Int)
    i=round(Int,l/b+1)
    return i
end
mirror(i,l)=l-i+2

function filterTSFFT{T<:Real}(outar::Matrix{T},y::Vector{T}, annfreq::Number;nharm::Int=3)

    size(outar) == (length(y),4) || error("Wrong size of output array")

    detrendTS!(outar,y)
    l        = length(y)

    fy       = Complex{eltype(y)}[y[i]-outar[i,1] for i=1:l]
    fft!(fy)
    fyout    = similar(fy)
    czero    = zero(eltype(fy))

    #Remove annual cycle
    fill!(fyout,zero(eltype(fyout)))

    for jharm = 1:nharm
        iup=tscale2ind(annfreq*1.1/jharm,l)

        idown=tscale2ind(annfreq*0.9/jharm,l)

        for i=iup:idown
            fyout[i]  = fy[i]
            i2        = mirror(i,l)
            fyout[i2] = fy[i2]
            fy[i]     = czero
            fy[i2]    = czero
        end
    end

    ifft!(fyout)
    for i=1:l
        outar[i,3]=real(fyout[i])
    end

    iup   = tscale2ind(annfreq*1.1,l)
    idown = tscale2ind(annfreq*0.9,l)
    #Now split the remaining parts
    fill!(fyout,czero)
    for i=2:iup-1
        i2        = mirror(i,l)
        fyout[i]  = fy[i]
        fyout[i2] = fy[i2]
        fy[i]     = czero
        fy[i2]    = czero
    end
    ifft!(fyout)
    ifft!(fy)

    for i=1:l
        outar[i,2]=real(fyout[i])
        outar[i,4]=real(fy[i])
    end
    outar
end
registerDATFunction(filterTSFFT,(TimeAxis,),(TimeAxis,(c,p)->TimeScaleAxis()),(c,p)->getNpY(c[1]),inmissing=(:nan,),outmissing=:nan,no_ocean=1)

end