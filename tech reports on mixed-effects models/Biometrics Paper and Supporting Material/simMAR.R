##########################################################################
### Simulated data on the CD4 cell count decline under MAR missingness ###
##########################################################################

beta.true = c(23.60,-1.30)

# 5 years maximum study duration
# 1 Visit every 3 months
time = rep(seq(0,60,by=3)/12,G)

# Design matrix of the fixed effects
x = cbind(1,time)

# Number of obs by patient
ni = length(seq(0,60,by=3))
n = nrow(x)

# Patient id and order of visits
id = rep(1:G,each = ni)
ord = rep(1:ni,G)

# Random intercept and slope model
# D.true covariance matrix of random effects
D.true = matrix(c(22.6,-2.07,-2.07,1.85),nr = 2, nc = 2)


#####################################
### Simulation of it MAR datasets ###
#####################################

set.seed(1536)

for (j in 1:it)
{
  # Simulation of random effects
  b = rmvnorm(n = G,mean = c(0,0),sigma = D.true)
  zb = rowSums(b[id,]*x)
  
  # Within patient errors
  sd.e = sqrt(5.3)
  epsilon = rnorm(n,0,sd = sd.e)
  
  # Simulate the full data
  # sq.cd4 is the current observed CD4 measured with error 
  sq.cd4 = c(x%*%beta.true) + zb + epsilon
  
  # Data frame with full data
  data.full = data.frame(id,sq.cd4,time,ord)
  
  #########################
  ### MAR - missingness ###
  #########################
  
  time.axis_w = time[id==1]
  beta_w = c(3.956,-0.221)
  kappa_w = 1.0
  
  rweibull = function(beta,kappa,x,time.axis)
  {
    ni = length(time.axis)
    Delta.t = time.axis[2:ni]^kappa - time.axis[1:(ni-1)]^kappa
    
    exbeta = exp(c(x%*%beta)) 
    
    # Simulate from uniform
    u = runif(1)
    ls = -log(u)
    
    # Find the appropriate intervals
    cut = c(0,cumsum(Delta.t*exbeta[1:(ni-1)]))
    int = findInterval(ls,cut)
  
    sample = ( (ls - cut[int])/exbeta[int] + time.axis[int]^kappa )^(1/kappa)
   
    return(sample)
  }
  
  surv = rep(NA,G)
  
  for (i in 1:G)
  {
    surv[i] = rweibull(beta_w,kappa_w,x = cbind(1,sq.cd4[id==i]),time.axis_w)
  }
  
  # Data.id : data.frame with the first obs of every subject
  data.id = data.full[ord==1,]
  
  # The observed survival time is the minimum of
  # true survival time and 5 years (study termination)
  data.id$time = pmin(5,surv)
  data.id$event = 1*(surv<5)
  
  # Create missing indicator
  data.full$mis = F
  
  # Now we need to delete the appropriate cases 
  # from the "longitudinal" data frame
  
  for (i in which(surv<5))
  {
    # For each patient who failed, find the visit times 
    # after the survival time. These obsrevations will be missing.
    data.full$mis[data.full$id==i]=data.full$time[data.full$id==i]>surv[i]
  }
    
  # Observed data 
  data.obs = data.full[data.full$mis==FALSE,]
  data.id[data.id$time==5,"time"] = 5.01
  
  names(data.obs)[3]="obstime"
  data.obs$time = data.id$time[data.obs$id]
  data.obs$event = data.id$event[data.obs$id]
  data.obs$kappa = kappa_w
  data.obs$Study = j
  
  # Set working directory and write data
  setwd(WDMAR)  
  path1 = paste(paste("data.obs",j,sep=""),".csv",sep="")
  write.csv(data.obs,path1,row.names=F)
  
# print(j)

}

