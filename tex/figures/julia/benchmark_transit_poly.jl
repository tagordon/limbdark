# Benchmarks the version of transit_poly which uses a Type
# for holding all of the variables related to the transit
# computation.

using Statistics
using PyPlot

# Defines the function that computes the transit:
include("../../../src/transit_poly_struct.jl")

#function benchmark_transit_poly()

nu = [1,2,3,5,8,13,21,34,55,89,144]; #233,377,610];
nnu = length(nu)
nb = [100,316,1000,3160,10000,31600,100000];
nnb = length(nb)
timing_ratio = zeros(nnb,nnu)

# Define a function that loops over impact parameter
# and defines arrays to hold the results:

function profile_transit_poly(trans,nb)
fgrad = zeros(2+trans.n)
timing = zeros(length(nb))
tmean = zeros(5)
for j=1:length(nb)
  nb0 = nb[j]
  b = zeros(nb0)
  flux = zeros(nb0)
  for k=1:5
    elapsed = time_ns()
    for i=1:nb0
      b[i] = sqrt(((i-float(nb0)/2)*2/float(nb0)*(1.0+2.0*trans.r))^2)
      trans.b = b[i]
      flux[i] = transit_poly!(trans)
    end
    tmean[k] = (time_ns()-elapsed)*1e-9
  end
  timing[j] = median(tmean)
#  println("nb = ",nb0," min(b): ",minimum(b)," max(b): ",maximum(b)," min(flux): ",minimum(flux)," max(flux): ",maximum(flux))
end
return timing
end

# Instantiate a transit with r=0.1, b=0.5, u_n=[0.2,0.3]:
r = 0.1; b = 0.5
# Load in PyPlot (Julia matplotlib wrapper):
clf()
cmap = get_cmap("plasma")
for iu = 1:nnu
  u_n .= ones(nu[iu])/nu[iu]
  trans = transit_init(r,b[1],u_n,true)
# Transform from u_n to c_n coefficients:
#compute_c_n_grad!(trans)  # Now included in transit_init function
  timing = zeros(nnb)
# Call the function:
  @time timing =profile_transit_poly(trans,nb)
  if iu == 1
    timing_ratio[:,1] = timing
  else
    timing_ratio[:,iu] = timing./timing_ratio[:,1]
  end
  loglog(nb,timing,color=cmap(float(iu)/nnu))
  loglog(nb,timing,"o",color=cmap(float(iu)/nnu),label=string("n: ",nu[iu]))
end
xlabel("Number of points")
ylabel("Timing [sec]")
legend(loc="upper left",fontsize=8,ncol=3)
timing_ratio[:,1]=1.0
#clf()
#plot(b,flux-1,label="flux-1")
#plot(b,trans.r*flux_grad[:,1],label="r*dfdr")
#plot(b,trans.r*flux_grad[:,2],label="r*dfdb")
#plot(b,flux_grad[:,3],label="dfdu1")
#plot(b,flux_grad[:,4],label="dfdu2")
#legend(loc="lower right")
#println("b: ",minimum(b)," ",maximum(b))
#println("f: ",minimum(flux)," ",maximum(flux))
savefig("benchmark_transit_poly.pdf", bbox_inches="tight")

clf()
tmed = vec(median(timing_ratio;dims=1))
loglog(nu,tmed,"o")
plot(nu,tmed,label="Measured",linewidth=2)
alp = log(tmed[nnu])/log(nu[nnu])
plot(nu,nu.^0.2,linestyle="--",label=L"$n^{0.2}$")
plot(nu,tmed[nnu]*(nu/nu[nnu]).^2,linestyle="--",label=L"$n^1$")
#plot(nu,(nu).^(1./3.),linestyle="--",label=L"$n^{1/3}$",linewidth=2)
#plot(nu,(nu).^(3./8.),linestyle="--",label=L"$n^{3/8}$",linewidth=2)
#plot(nu,(nu).^(3./8.),linestyle="--",label=L"$n^{3/8}$",linewidth=2)
xlabel("Number of limb-darkening coefficients")
ylabel("Relative timing")
legend(loc="upper left")
axis([1,144,0.7,2e2])
savefig("benchmark_limbdark_timing.pdf", bbox_inches="tight")

#return
#end
