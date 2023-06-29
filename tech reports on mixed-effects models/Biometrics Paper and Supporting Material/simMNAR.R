##########################################################################
### Simulated data on the CD4 cell count decline under MAR missingness ###
##########################################################################

beta.true = c(23.60,-1.30)
# G is the number of subjects (G=1000)
# 5 years maximum study duration
# 1 Visit every 3 months
time = rep(seq(0,60,by=3)/12,G)

# Design matrix of the fixed effects
x = cbind(1,time)

# Number of obs by patient
ni = length(seq(0,60,by=3))
n = nrow(x)

# print(n)

# Patient id and order of visits
id = rep(1:G,each = ni)
ord = rep(1:ni,G)

# Random intercept and slope model
# D.true covariance matrix of random effects
D.true = matrix(c(22.6,-2.07,-2.07,1.85),nr = 2, nc = 2)


#####################################
### Simulation of it MNAR datasets ###
#####################################

set.seed(8456)

for (j in 1:it)
{
  # Simulation of random effects
  b = rmvnorm(n = G,mean = c(0,0),sigma = D.true)
  # b1 is the column vector on random intercept effects  
  b1 = b[,1]
  # b2 is the column vector on random slope effects  
  b2 = b[,2] 
  zb = rowSums(b[id,]*x)

  # The following is NEW as of 07/30/2020 to put ranom effects 
  # into the final full dataset to be created. We have too use
  # u1i and u2i as b1i and b2i are in the SAS program 
  u1i = rep(b1[1], ni);
  u2i = rep(b2[1], ni);

#  print(j)
#  print(u1i)
#  print(u2i)

  for (k in 2:G)
  {
    u1k = rep(b1[k],ni)
    u1i <- rbind(u1i, u1k)
    u2k = rep(b2[k],ni) 
    u2i <- rbind(u2i, u2k)
   }

   
  # Within patient errors
  sd.e = sqrt(5.3)
  epsilon = rnorm(n,0,sd = sd.e)
  
  # Simulate the full data
  # sq.cd4 is the current observed CD4 measured with error 
  sq.cd4 = c(x%*%beta.true) + zb + epsilon
  
  # Data frame with full data
  data.full = data.frame(id,sq.cd4,time,ord)
  
  ##########################
  ### MNAR - missingness ###
  ##########################
  
  # The following time.axis is for MNAR (NIM) 
    time.axis_w = c(0, 5.0)

  # The following call for beta_w is for the MNAR random effects mechanism.
  # The baseline log hazard rate of exp(beta0)=exp(-1.8563)=0.15625 corresponds 
  # to 54%-55% dropout at 5 years if there is no effect of the random effects  
  # on dropout (i.e., when log[HR(b1)] = 0 and log[HR(b2)] = 0 so MNAR is void. 
  # The value of beta0 = -1.8563=3.9560-0.221*26.3 is, on average, the baseline
  # hazard function starting at time 0 under the MAR mechanism and there is no  
  # effect of changing CD4 on the hazard of dropout post-baseline (i.e., the 
  # log[HR(Obs CD4)] = beta1 = 0 so the MAR mechanism is essentialy void (MCAR).
  # Under the MNAR we set eta0 = -1.8563, eta1 = -0.10536 = log(0.90) which 
  # corresponds to HR=0.90 per 1 unit increase in random intercept effect (b1)
  # and eta2 = -2.23144 = log(0.80)/0.1 which corresponds to HR=1.25 per 0.1  
  # unit decrease in the random slope effect (b2)
    
    beta_w = c(-1.8563,-0.10536,-2.23144)
    kappa_w = 1.0
  
  rweibull = function(beta,kappa,x,time.axis)
  {
    exbeta = exp(c(x%*%beta)) 

    # Simulate from uniform
    u = runif(1)
    ls = -log(u)

    sample = ( ls/exbeta )^(1/kappa)
     
    return(sample)
  }
  
  surv = rep(NA,G)

 
  for (i in 1:G)
  {
     surv[i] = rweibull(beta_w,kappa_w,x = cbind(1,b1[i],b2[i]),time.axis_w)
  }
  
  # Data.id : data.frame with the first obs of every subject
  data.id = data.full[ord==1,]
  
  # The observed survival time is the minimum of
  # true survival time and 5 years (study termination)
    data.id$time = pmin(5,surv)
    data.id$event = 1*(surv<5)

  # This is NEW as of 07/29/2020 to put ranom effects 
  # u1i and u2i into the full dataset
    data.id$u1i = u1i
    data.id$u2i = u2i
  
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
  data.obs$u1i = data.id$u1i[data.obs$id]
  data.obs$u2i = data.id$u2i[data.obs$id]
  data.obs$kappa = kappa_w
  data.obs$Study = j
  
  # Set working directory and write data
  setwd(WDMNAR)  
  path1 = paste(paste("data.obs",j,sep=""),".csv",sep="")
  write.csv(data.obs,path1,row.names=F)
  
# print(j)

}

