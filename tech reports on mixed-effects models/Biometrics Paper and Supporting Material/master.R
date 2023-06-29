################################################
### Master file carrying out the simulations ###
################################################

# The folder of the project
W = "d:/edward/RM/Missing Data/Biometrics Reader Reaction/CD4"
WP = paste(W,"programs",sep = "/")
WD = paste(W,"data",sep = "/")
WDMAR   = paste(WD,"MAR_scenarios/Exponential",sep = "/")
WDMCAR  = paste(WD,"MCAR_scenarios/Exponential",sep = "/")
WDMNAR  = paste(WD,"MNAR_scenarios/Exponential",sep = "/")
WDBOTH  = paste(WD,"BOTH_scenarios/Exponential",sep = "/")
WDBOTH1 = paste(WD,"BOTH1_scenarios/Exponential",sep = "/")
WDBOTH2 = paste(WD,"BOTH2_scenarios/Exponential",sep = "/")

# Simulation is performed in R, but all models are fitted in SAS.

# Importing libraries
install_packages = F
if (install_packages)
{
  install.packages(c("mvtnorm","nlme","survival","Matrix","xtable"))
}
library(mvtnorm)
library(nlme)
library(survival)
library(splines)
library(Matrix)
library(compiler)
library(modeest)
library(xtable)

# Number of subjects
  G = 1000
 
# Number of simulations
  it = 500
 
# Run!
  setwd(WP)

# Simulate under MAR
  setwd(WP)
  source("simMAR.R")

# Simulate under MCAR which can be used to create a MAR
# mechanism based on a CD4 threshold value if one wishs
# NOTE: This was not used in the Biometrics submission. 
# setwd(WP)  
# source("simMCAR.R")

# Simulate under MNAR
  setwd(WP)  
  source("simMNAR.R")

# Simulate under BOTH (T1_MIN) with a high % of MAR
  setwd(WP)  
  source("simBOTH.R")

# Simulate under BOTH1 (T2_MIN) with a lower % of MAR
  setwd(WP)  
  source("simBOTH1.R")

# Simulate under BOTH2 (T3_MIN) with the lowest % of MAR
  setwd(WP)  
  source("simBOTH2.R")


