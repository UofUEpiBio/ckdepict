############################################################
############################################################
############################################################
# This R Script produces first, posterior
# predictive distributions (PPDs) of three different types
# and then, those PPDs can be used calculate 95%
# prediction intervals, PPVs, etc. 
############################################################
############################################################
############################################################

# Set wd.
setwd("Your WD")

# Load in file with mcmc draws from trial-level model 
# fitting. 
psts = read.csv("Your Posteriors File.csv")

####################
# The following code block can be used to generate PPDs 
# taking into account uncertainty only in the meta-regression
# slope and intercept assuming no error in the surrogate effect
# used as input. This loops across possible values for the
# true effect on the surrogate and generates a .csv with columns
# representing a PPD for each true effect on the surrogate. 

# Note 1: This can be used for PPD for confidence bands (no error-SD assumed).
# Note 2: The parameter names need to be changed (indicated below) depending
# on names in the posteriors file used. 

surr.effs = c(0.5,0.75,1) # Change this line for the desired effects of interest on the surrogate.

ppd.mat1 = matrix(NA,nrow=nrow(psts),ncol=length(surr.effs))

for (s in 1:length(surr.effs)) {
  
  for (m in 1:nrow(psts)) {
    
    ppd.mat1[m,s] = psts$alphaClnMod[m] + psts$betaSurEffClnMod[m]*surr.effs[s] # Change "alphaClnMod", "betaSurEffClnMod" accordingly.
    
  }
  
}

ppd.mat1 = as.data.frame(ppd.mat1)
colnames(ppd.mat1) = as.character(surr.effs)
write.csv(ppd.mat1, "PPDs_Name-of-File.csv")

####################
# The following code block can be used to generate PPDs 
# taking into account uncertainty in the meta-regression
# slope, intercept, and error-SD (!!), but assumes no error in the surrogate effect
# used as input. This loops across possible values for the
# true effect on the surrogate and generates a .csv with columns
# representing a PPD for each true effect on the surrogate. 

# Note: Change the meta-regression paramter names below depending on
# how they are named in the .csv file containing posteriors. 

surr.effs = c(0.5,0.75,1) # Change this line for the desired effects of interest on the surrogate.

ppd.mat2 = matrix(NA,nrow=nrow(psts),ncol=length(surr.effs))

for (s in 1:length(surr.effs)) {
  
  for (m in 1:nrow(psts)) {
    
    ppd.mat2[m,s] = psts$alphaClnMod[m] + psts$betaSurEffClnMod[m]*surr.effs[s] + rnorm(1,0,sqrt(psts$sigSqClnMod[m]))
    
  }
  
}

ppd.mat2 = as.data.frame(ppd.mat2)
colnames(ppd.mat2) = as.character(surr.effs)
write.csv(ppd.mat2, "PPDs_Name-of-File.csv")

####################
# The following loop can be used to generate PPDs 
# taking into account uncertainty in the meta-regression
# slope, intercept, error-SD, AND the estimated surrogate effect
# used as input. Thus, it requires specification of a standard error
# of the estimated surrogate effect (e.g. those used for "modest"
# vs. "large" RCTs). This loops across possible values for the
# true effect on the surrogate AND the SEs of interest, and it
# generates a .csv with columns representing a PPD for each 
# true effect on the surrogate, and generates a separate .csv for 
# each SE.

# Note: Change the meta-regression paramter names below depending on
# how they are named in the .csv file containing posteriors. 

surr.effs = c(0.5,0.75,1) # Change this line for the desired effects of interest on the surrogate.

# Chronic Slope:
SEs = c(0.485435,0.343254,0.242718) # Go in order of small, modest, large. 

# 3-Yr Total Slope:
SEs = c(0.423947,0.299776,0.211973) # Go in order of small, modest, large. 

# Note: Change the meta-regression paramter names below depending on
# how they are named in the .csv file containing posteriors. 

ppd.mats3 = list()

for (ses in 1:length(SEs)) {

  ppd.mats3[[ses]] = matrix(NA,nrow=nrow(psts),ncol=length(surr.effs))
  
  for (s in 1:length(surr.effs)) {
    
    for (m in 1:nrow(psts)) {
      
      mySigma = sqrt(1/(1/100 + 1/(SEs[ses]^2)))
      
      myMu = (1/(1/100 + 1/(SEs[ses]^2)))*(1/(SEs[ses]^2))*surr.effs[s] + (1/(1/100 + 1/(SEs[ses]^2)))*(1/100)*psts$muSurCtrl[m]
      
      est.surr.eff = rnorm(1,myMu,mySigma)
      
      ppd.mats3[[ses]][m,s] = psts$alphaClnMod[m] + psts$betaSurEffClnMod[m]*est.surr.eff + rnorm(1,0,sqrt(psts$sigSqClnMod[m]))
      
    }
    
  }

}

smalltrial.PPDs = as.data.frame(ppd.mats3[[1]])
modesttrial.PPDs = as.data.frame(ppd.mats3[[2]])
largetrial.PPDs = as.data.frame(ppd.mats3[[3]])

colnames(smalltrial.PPDs) = as.character(surr.effs)
colnames(modesttrial.PPDs) = as.character(surr.effs)
colnames(largetrial.PPDs) = as.character(surr.effs)

write.csv(smalltrial.PPDs,"PPDs_Small_Trial.csv")
write.csv(modesttrial.PPDs,"PPDs_Modest_Trial.csv")
write.csv(largetrial.PPDs,"PPDs_Large_Trial.csv")

######### This loop takes MCMCs and identifies an effect on the 
# surrogate which gives PPV >= 0.975. 

slope.effs = seq(0.3,1.7,by=0.01)

# Set SE in advance (1 at a time).

# Chronic Slope:
SEs = c(0.485435,0.343254,0.242718) # Go in order of small, modest, large. 

# 3-Yr Total Slope:
#SEs = c(0.423947,0.299776,0.211973) # Go in order of small, modest, large. 

SE = SEs[3]

PPVs = c()

for (e in 1:length(slope.effs)) {
  
  ppd = c()
  
  for (m in 1:nrow(psts)) {
  
    mySigma = sqrt(1/(1/100 + 1/(SE^2)))
    
    myMu = (1/(1/100 + 1/(SE^2)))*(1/(SE^2))*slope.effs[e] + (1/(1/100 + 1/(SE^2)))*(1/100)*psts$muSurCtrl[m]
    
    est.surr.eff = rnorm(1,myMu,mySigma)
    
    ppd[m] = psts$alphaClnMod[m] + psts$betaSurEffClnMod[m]*est.surr.eff + rnorm(1,0,sqrt(psts$sigSqClnMod[m]))
    
  }
  
  PPVs[e] = mean(ppd < 0)
  
  print(e)
  
}

slope.effs[which(PPVs >= 0.975)]


















