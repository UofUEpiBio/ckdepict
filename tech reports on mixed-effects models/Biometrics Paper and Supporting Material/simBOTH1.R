###################################################################################
### Simulated data on the CD4 cell count decline under MAR and MNAR missingness ###
### where there is a considerbally lower percentage of MAR dropout              ###
###################################################################################

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

set.seed(2356)

for (j in 1:it)
{
  # Simulation of random effects
  b = rmvnorm(n = G,mean = c(0,0),sigma = D.true)
  # b1 is the column vector on random intercept effects  
  b1 = b[,1]
  # b2 is the column vector on random slope effects  
  b2 = b[,2] 
  zb = rowSums(b[id,]*x)
  
  # Within patient errors
  sd.e = sqrt(5.3)
  epsilon = rnorm(n,0,sd = sd.e)
  
  # Simulate the full data
  # sq.cd4 is the current observed CD4 measured with error 
  sq.cd4 = c(x%*%beta.true) + zb + epsilon
  
  # Data frame with full data
  data.full = data.frame(id,sq.cd4,time,ord)
  
  ##################################
  ### MAR and MNAR - missingness ###
  ##################################

  # The following time.axis is for MAR mechanism 
  time.axis_w1 = time[id==1]

  ##########################################################
  # beta_w1, kappa_w1 and rweibull_1 are for MAR mechanism #
  # The value of -0.321 is 0.10 lower than -0.221 which    #
  # yields a lower rate of MAR dropout under a BOTH mech.  #
  ##########################################################

  beta_w1 = c(3.956,-0.321)
  kappa_w1 = 1.0
  
  rweibull_1 = function(beta,kappa,x,time.axis)
  {
    ni = length(time.axis)
    Delta.t = time.axis[2:ni]^kappa - time.axis[1:(ni-1)]^kappa
    
    exbeta1 = exp(c(x%*%beta)) 
    
    # Simulate from uniform
    u1 = runif(1)
    ls1 = -log(u1)
    
    # Find the appropriate intervals
    cut = c(0,cumsum(Delta.t*exbeta1[1:(ni-1)]))
    int = findInterval(ls1,cut)
  
    sample1 = ( (ls1 - cut[int])/exbeta1[int] + time.axis_w1[int]^kappa )^(1/kappa)
   
    return(sample1)
  }

  # The following time.axis is for MNAR (NIM) mechanism
    time.axis_w2 = c(0, 5.0)

  # beta_w2, kappa_w2 and rweibull_2 are for MNAR mechanism 

  beta_w2 = c(-1.8563,-0.10536,-2.23144)
  kappa_w2 = 1.0

  rweibull_2 = function(beta,kappa,x,time.axis)
  {
    exbeta2 = exp(c(x%*%beta)) 

    # Simulate from uniform
    u2 = runif(1)
    ls2 = -log(u2)

    sample2 = ( ls2/exbeta2 )^(1/kappa)
     
    return(sample2)
  }

  
  surv1 = rep(NA,G)
  surv2 = rep(NA,G)
  surv  = rep(NA,G)
    
  for (i in 1:G)
  {
    surv1[i] = rweibull_1(beta_w1,kappa_w1,x = cbind(1,sq.cd4[id==i]),time.axis_w1)
    surv2[i] = rweibull_2(beta_w2,kappa_w2,x = cbind(1,b1[i],b2[i]),time.axis_w2)
  }

  surv = pmin(surv1, surv2);

  # Data.id : data.frame with the first obs of every subject
  data.id = data.full[ord==1,]
  
  # The observed MAR survival time is the minimum of
  # true survival time and 5 years (study termination)
  data.id$time_MAR = pmin(5,surv1)
  data.id$event_MAR = 1*(surv1<5)

  # The observed MNAR survival time is the minimum of
  # true survival time and 5 years (study termination)
  data.id$time_NIM = pmin(5,surv2)
  data.id$event_NIM = 1*(surv2<5)

  # The observed survival time is the minimum of
  # the MAR and MNAR true survival times
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
  data.obs$time_MAR = data.id$time_MAR[data.obs$id]
  data.obs$event_MAR = data.id$event_MAR[data.obs$id]
  data.obs$kappa_MAR = kappa_w1
  data.obs$time_NIM = data.id$time_NIM[data.obs$id]
  data.obs$event_NIM = data.id$event_NIM[data.obs$id]
  data.obs$kappa_NIM = kappa_w2
  data.obs$Study = j
  
  # Set working directory and write data
  setwd(WDBOTH1)  
  path1 = paste(paste("data.obs",j,sep=""),".csv",sep="")
  write.csv(data.obs,path1,row.names=F)
  
# print(j)

}

