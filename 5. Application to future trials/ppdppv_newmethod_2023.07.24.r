 ############################################################
############################################################
############################################################
# This R Script provides two functions. One generates
# a .csv file containing posterior predictive distributions
# for treatment effects on the clinical endpoint. Each
# column of the file produced represents a posterior
# predictive distribution for a given treatment effect
# on a surrogate. The number of columns total depend
# on the number of surrogate effects of interest, as
# specified by the user.  

# The second function generates a threshold for
# clinical benefit of a desired probability for a future
# trial of a particular design, as governed by the size
# of the SE used as a function input. 

# Additional details below for each function.
############################################################
############################################################
############################################################

############################################################
# Function 1: Posterior predictive distributions.
############################################################

# FUNCTION INPUTS DESCRIBED HERE

# posteriors_location
# Location of the file where the mcmc draws for the trial
# level model parameters are stored.

# SE_filename
# Name of th file containing standard errors of the 
# surrogate effect estimate for a future trial, if
# reporting results from prediction for clinical effects
# for a future trial not of "infinite" sample size.

# outcome_var
# This is the name of the outcome/dependent/established variable
# of the meta-regression - the variable being predicted.
# List any one of:
# "Chronic","Total2yr","Total3yr","ACR", "Clinical_Endpoint"

# input_var 
# This is the name of the independent/surrogate variable of the
# meta-regression. Or, equivalently, the variable
# being used to predict the outcome variable.
# List any one of:
# "Chronic","Total2yr","Total3yr","ACR"

# slope_name
# The name of the parameter for the meta-regression
# slope in the posteriors file. 

# intercept_name
# The name of the parameter for the meta-regression
# intercept in the posteriors file. 

# error_variance_name
# The name of the parameter for the meta-regression
# error variance in the posteriors file.

# mean_surrogate_effect_name
# The name of the parameter for the between-study
# population mean true treatment effect on the surrogate.

# variance_surrogate_effect_name
# The name of the parameter for the between-study
# variance for the true treatment effects on the surrogate.

#####
# method
# Key: One of three methods should be specified:
#
# ## 1) "confidence": This means PPDs are produced taking into
# account uncertainty only in the meta-regression intercept and slope.
# USE THIS FOR PLOTTING CONFIDENCE BANDS.
# 
# ## 2) "prediction": 
# This means PPDs are produced taking into
# account uncertainty from the meta-regression slope and intercept
# and residual SD. Note: This can be used for
# a future trial of "infinite" sample size.
# USE THIS FOR PLOTTING PREDICTION BANDS.
#
# ## 3) "future-trial": 
# This means PPDs are produced taking into
# account uncertainty in ALL meta-regression parameters AND
# in uncertainty in the estimated effect on the surrogate. 
# USE THIS FOR PPVS FOR A FUTURE TRIAL.
#####

# trial_sizes
# This indicates the trial size used if prediction is for 
# prediction summaries for a future trial. This needs to be one
# of:
# "Small","Medium","Large"
# Note: These can be all placed in a vector such as:
# trial_sizes = c("Small","Medium","Large")

# standard_error
# This is necessary if using prediction for a future trial. The
# standard error for the estimated effect on the surrogate
# needs to be provided directly. 

# surr_effs
# This is a scalar or vector of the proposed treatment effects
# on the surrogate of interest in generating predictions. Needs
# to be of the format used for model-fitting. 

# output_location
# This is the location you want to save your file of predictive 
# distributions.

# abs_or_rel
# Enter either "absolute" or "relative".
# If relative, the function will create values for the surrogate
# effects used for prediction, these are tied to the mean
# true effects on the surrogate based on past analyses.
# If "absolute", the user must specify the effects on the
# surrogate used. 

gen.ppds = function(posteriors_location,SE_filename=NA,slope_name,
                    intercept_name,error_variance_name,mean_surrogate_effect_name,variance_surrogate_effect_name,
                    method,standard_error=NA,surr_effs=NA,
                    output_location,model_number,
                    date,trial_sizes=NA, outcome_var,input_var,abs_or_rel,
                    save.output=T) {
  
  posteriors_filename = paste("PS_data_",model_number,"_",date,".csv",sep="")
  
  psts=read.csv(file.path(posteriors_location, posteriors_filename))
  intercept = psts[,which(names(psts) == intercept_name)]
  slope = psts[,which(names(psts) == slope_name)]
  error_variance = psts[,which(names(psts) == error_variance_name)]
  mean_surr_eff = psts[,which(names(psts) == mean_surrogate_effect_name)]
  var_surr_eff = psts[,which(names(psts) == variance_surrogate_effect_name)]
  
  if (abs_or_rel == "absolute") {surr_effs = surr_effs}
  if (abs_or_rel == "relative") {
    
      mean = median(mean_surr_eff)
      sd = median(sqrt(var_surr_eff))
      k = c(-3,-3/2,-1,-1/2,-1/4,0,1/4,1/2,1,3/2,3)
      surr_effs = mean + k*sd
    
    }
  
  ppd.mat = matrix(NA,nrow=nrow(psts),ncol=length(surr_effs))
  
  if (method == "confidence") {
    
    for (s in 1:length(surr_effs)) {
      
        ppd.mat[,s] = intercept + slope*surr_effs[s] 
      
    }
    
    ppd.mat = as.data.frame(ppd.mat)
    colnames(ppd.mat)[1:length(surr_effs)] = paste("Surrogate Effect:",as.character(surr_effs), sep="")
    ppd.mat$model_number = rep(model_number,times = dim(ppd.mat)[1])
    ppd.mat$date = rep(date,times = dim(ppd.mat)[1])
    ppd.mat$surrogate_effects = c(surr_effs,rep(NA,dim(ppd.mat)[1]-length(surr_effs)))
    fileName1 = file.path(output_location, paste("Model_No",model_number,"_",date,"_",
                                                 "Outcome-",outcome_var,"_PredictionVar-",input_var,"_Confidence_",abs_or_rel,".csv",sep=""))
    
  }
  
  if (method == "prediction") {
    
    for (s in 1:length(surr_effs)) {
      
      ppd.mat[,s] = intercept + slope*surr_effs[s] + rnorm(nrow(psts),0,sqrt(error_variance))
      
    }
    
    ppd.mat = as.data.frame(ppd.mat)
    colnames(ppd.mat)[1:length(surr_effs)] = paste("Surrogate Effect:",as.character(surr_effs), sep="")
    ppd.mat$model_number = rep(model_number,times = dim(ppd.mat)[1])
    ppd.mat$date = rep(date,times = dim(ppd.mat)[1])
    ppd.mat$surrogate_effects = c(surr_effs,rep(NA,dim(ppd.mat)[1]-length(surr_effs)))
    fileName1 = file.path(output_location, paste("Model_No",model_number,"_",date,"_",
                                                 "Outcome-",outcome_var,"_PredictionVar-",input_var,"_Prediction_",abs_or_rel,".csv",sep=""))

  }
  
  if (method == "future-trial") {
    
    SE_file=read.csv(file.path(posteriors_location, SE_filename))
    
    for (se in 1:length(trial_sizes)) {
    
      if (input_var %in% c("Total1yr","Chronic","Total2yr","Total3yr")) {
        
        SE = SE_file$SlopeSE[which(SE_file$SlopeEndpoint == input_var & SE_file$Size == trial_sizes[se])]
        
      }
      
      if (input_var %in% c("ACR")) {
        
        SE = SE_file$ACRSE[SE_file$Size == trial_sizes[se]]
        SE = SE[1]
        
      }
      
      for (s in 1:length(surr_effs)) {
        
        for (m in 1:nrow(psts)) {
          
          #Generates a standard deviation based on the SE of surrogate effect specified in input SE file
          mySigma = sqrt(1/(1/100 + 1/(SE^2))) 
          
          #Generates a mean based on 
          #1) the SE of surrogate effect specified in input SE file (SE)
          #2) the "true" surrogate effect specified in input (surr_effs[s])
          #3) the mean surrogate effect as estimated in meta-regression (mean_surr_eff[m], often the input is "muSur")
          myMu = (1/(1/100 + 1/(SE^2)))*(1/(SE^2))*surr_effs[s] + (1/(1/100 + 1/(SE^2)))*(1/100)*mean_surr_eff[m]
          
          #Randomly generates a surrogate effect for the future trial based on normal distribution
          est.surr.eff = rnorm(1,myMu,mySigma) 
          
          #Generates the predicted outcome effect
          ppd.mat[m,s] = intercept[m] + slope[m]*est.surr.eff + rnorm(1,0,sqrt(error_variance[m]))
          
        }
      }
    
      ppd.mat = as.data.frame(ppd.mat)
      colnames(ppd.mat)[1:length(surr_effs)] = paste("Surrogate Effect:",as.character(surr_effs), sep="")
      ppd.mat$model_number = rep(model_number,times = dim(ppd.mat)[1])
      ppd.mat$date = rep(date,times = dim(ppd.mat)[1])
      ppd.mat$surrogate_effects = c(surr_effs,rep(NA,dim(ppd.mat)[1]-length(surr_effs)))
      fileName1 = file.path(output_location, paste("Model_No",model_number,"_",date,"_",
                                                   "Outcome-",outcome_var,"_PredictionVar-",input_var,"_TrialSize-",trial_sizes[se],"_Future-Trial_",abs_or_rel,".csv",sep=""))
      
    }    
      
  }
  
  if(save.output==T){
    write.csv(ppd.mat,fileName1,na="",row.names = FALSE)
  }
  return(ppd.mat)
}

# Here is an example run:

##SEfilename needed only for method="future-trial"
## if abs_or_rel = absolute then you must specify a vector for surr_effs, but if relative then ignore surr_effs
## trial_sizes only needed for future-trial 
# 
# idx=1
# 
# loc.in="U:/Shared/CKD_Endpts/willem/predictions_Rcode/willem_rcode/07292022_jm"
# loc.out="U:/Shared/CKD_Endpts/willem/predictions_Rcode/willem_rcode/07292022_jm"
# mod.num=idx
# date.ymd="20220513"
# 
# gen.ppds(posteriors_location=loc.in,SE_filename="SlopeSEJuly12.csv",
#          slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#          mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#          method="future-trial",surr_effs=c(0,0.5,1,1.5,2),output_location=loc.out,
#          model_number=mod.num,date=date.ymd,trial_sizes=c("Small","Medium","Large"),outcome_var="Clinical_Endpoint",input_var="Chronic",abs_or_rel="absolute")
# 
# gen.ppds(posteriors_location=loc.in
#          ,slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#          mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#          method="confidence",surr_effs=c(0,0.5,1,1.5,2),output_location=loc.out,
#          model_number=mod.num,date=date.ymd,outcome_var="Clinical_Endpoint",input_var="Chronic",abs_or_rel="absolute")
# 
# gen.ppds(posteriors_location=loc.in
#          ,slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#          mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#          method="prediction",surr_effs=c(0,0.5,1,1.5,2),output_location=loc.out,
#          model_number=mod.num,date=date.ymd,outcome_var="Clinical_Endpoint",input_var="Chronic",abs_or_rel="absolute")
# 
# 
# # Another example run using the relative effects. 
# 
# gen.ppds(posteriors_location="U:\\Shared\\CKD_Endpts\\willem\\predictions_Rcode\\willem_rcode\\07192022",SE_filename="SlopeSEJuly12.csv"
#          ,slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#          mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#          method="future-trial",output_location="U:\\Shared\\CKD_Endpts\\willem\\predictions_Rcode\\willem_rcode\\07192022"
#          ,model_number=159,date="20220513",trial_sizes=c("Small","Medium","Large"),outcome_var="Clinical_Endpoint",input_var="Chronic",abs_or_rel="relative")
# 
# 
# gen.ppds(posteriors_location="U:\\Shared\\CKD_Endpts\\willem\\predictions_Rcode\\willem_rcode\\07192022"
#          ,slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#          mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#          method="confidence",output_location="U:\\Shared\\CKD_Endpts\\willem\\predictions_Rcode\\willem_rcode\\07192022"
#          ,model_number=159,date="20220513",outcome_var="Clinical_Endpoint",input_var="Chronic",abs_or_rel="relative")
# 
# 
# gen.ppds(posteriors_location="U:\\Shared\\CKD_Endpts\\willem\\predictions_Rcode\\willem_rcode\\07192022"
#          ,slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#          mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#          method="prediction",output_location="U:\\Shared\\CKD_Endpts\\willem\\predictions_Rcode\\willem_rcode\\07192022"
#          ,model_number=159,date="20220513",outcome_var="Clinical_Endpoint",input_var="Chronic",abs_or_rel="relative")
# 
# # Here is an example where we generate PPVs for the 
# # large trial using the output from this function
# # NOTE: The surrogate effects for each PPV are
# # extracted from the data and attached. 
# 
# a.type="TrialSize-Large_Future-Trial_absolute"
# 
# myPreds=read.csv(paste0(loc.out,"/Model_No",mod.num,"_20220513_Outcome-Clinical_Endpoint_PredictionVar-Chronic_",a.type,".csv"))
# myPreds1=myPreds[1:length(grep("Surrogate.Effect",colnames(myPreds),value=TRUE))]
# surr_effs=myPreds$surrogate_effects[which(!is.na(myPreds$surrogate_effects))]
# PPV1=colMeans(myPreds1<log(1))
# PPV2=colMeans(myPreds1<log(0.9))
# PPV3=colMeans(myPreds1<log(0.8))
# mean=apply(myPreds1,2,mean)
# median=apply(myPreds1,2,median)
# p10=apply(myPreds1,2,function(x) quantile (x,probs=0.1))
# p20=apply(myPreds1,2,function(x) quantile (x,probs=0.2))
# p30=apply(myPreds1,2,function(x) quantile (x,probs=0.3))
# p40=apply(myPreds1,2,function(x) quantile (x,probs=0.4))
# p50=apply(myPreds1,2,function(x) quantile (x,probs=0.5))
# p60=apply(myPreds1,2,function(x) quantile (x,probs=0.6))
# p70=apply(myPreds1,2,function(x) quantile (x,probs=0.7))
# p80=apply(myPreds1,2,function(x) quantile (x,probs=0.8))
# p90=apply(myPreds1,2,function(x) quantile (x,probs=0.9))
# p25=apply(myPreds1,2,function(x) quantile (x,probs=0.25))
# p75=apply(myPreds1,2,function(x) quantile (x,probs=0.75))
# p2_5=apply(myPreds1,2,function(x) quantile (x,probs=0.025))
# p97_5=apply(myPreds1,2,function(x) quantile (x,probs=0.975))
# p01=apply(myPreds1,2,function(x) quantile (x,probs=0.01))
# p05=apply(myPreds1,2,function(x) quantile (x,probs=0.05))
# p95=apply(myPreds1,2,function(x) quantile (x,probs=0.95))
# p99=apply(myPreds1,2,function(x) quantile (x,probs=0.99))
# min=apply(myPreds1,2,min)
# max=apply(myPreds1,2,max)
# std=apply(myPreds1,2,sd)
# percentiles=cbind(surr_effs,mean,std,min,p01,p2_5,p05,p10,p20,p25,p30,p40,p50,median,p60,p70,p75,p80,p90,p95,p97_5,p99,max,PPV1,PPV2,PPV3)
# percentiles=as.data.frame(percentiles)
# percentiles$mod.number=rep(myPreds$model_number[1],dim(percentiles)[1])
# percentiles$run.date=rep(myPreds$date[1],dim(percentiles)[1])
# write.csv(percentiles,paste0(loc.out,"/My_Predictions_Example_Percentiles.csv",sep=""),na="",row.names=FALSE)
# 


############################################################
# Function 2: Threshold for clinical benefit.
############################################################

# Function inputs are described above, except one new addition:

# benefit_threshold
# This is the log-hazard-ratio, below which we define clinical
# benefit. Typically this would have been log(1)=0.

gen.trt.thresh = function(posteriors_location,slope_name,SE_filename=NA,
                    intercept_name,error_variance_name,mean_surrogate_effect_name,
                    surr_effs,model_number,
                    date,probability_threshold,trial_sizes,outcome_var,input_var,
                    benefit_threshold,variance_surrogate_effect_name) {
  
  posteriors_filename = paste("PS_data_",model_number,"_",date,".csv",sep="")
  
  psts=read.csv(file.path(posteriors_location, posteriors_filename))
  intercept = psts[,which(names(psts) == intercept_name)]
  slope = psts[,which(names(psts) == slope_name)]
  error_variance = psts[,which(names(psts) == error_variance_name)]
  mean_surr_eff = psts[,which(names(psts) == mean_surrogate_effect_name)]
  var_surr_eff = psts[,which(names(psts) == variance_surrogate_effect_name)]
  
  thresholds=c()
  
  SE_file=read.csv(file.path(posteriors_location, SE_filename))
  
  for (se in 1:length(trial_sizes)) {
  
      if (input_var %in% c("Total1yr","Chronic","Total2yr","Total3yr")) {
        
        SE = SE_file$SlopeSE[which(SE_file$SlopeEndpoint == input_var & SE_file$Size == trial_sizes[se])]
        
      }
      
      if (input_var %in% c("ACR")) {
        
        SE = SE_file$ACRSE[SE_file$Size == trial_sizes[se]]
        SE = SE[1]
        
      }
    
    ppd.mat = matrix(NA,nrow=nrow(psts),ncol=length(surr_effs))
    
    for (s in 1:length(surr_effs)) {
      
      for (m in 1:nrow(psts)) {
        
        mySigma = sqrt(1/(1/100 + 1/(SE^2)))
        
        myMu = (1/(1/100 + 1/(SE^2)))*(1/(SE^2))*surr_effs[s] + (1/(1/100 + 1/(SE^2)))*(1/100)*mean_surr_eff[m]
        
        est.surr.eff = rnorm(1,myMu,mySigma)
        
        ppd.mat[m,s] = intercept[m] + slope[m]*est.surr.eff + rnorm(1,0,sqrt(error_variance[m]))
        
      }
    }
  
    if(outcome_var %in% c("Total1yr","Total2yr","Total3yr","Chronic")){
      PPVs = colMeans(ppd.mat > benefit_threshold)
    }else{
      PPVs = colMeans(ppd.mat < benefit_threshold)
    }
    
    if(length(which(PPVs > probability_threshold)) == 0) {
      
      thresholds[se] = "Threshold does not exist among surr_effs considered"
      
    }
    
    if(length(which(PPVs > probability_threshold)) > 0) {
   
      if (input_var=="ACR") {
    
      rev.PPV = rev(PPVs)
      rev.surreffs = rev(surr_effs)
    
      loc.above.thresh = which(rev.PPV > probability_threshold)[1] # Find the weakest surrogate effect that produces a PPV above the threshold of interest
      loc.below.thresh = which(rev.PPV > probability_threshold)[1]-1 # Find the next weakest surrogate effect (PPV below threshold)
    
      ppv1 = rev.PPV[loc.below.thresh]
      ppv2 = rev.PPV[loc.above.thresh]
    
      surreffs1 = rev.surreffs[loc.below.thresh]
      surreffs2 = rev.surreffs[loc.above.thresh]
    
      interp.mod = lm(c(surreffs1,surreffs2) ~ c(ppv1,ppv2)) # To map the surrogate effect that gives the desired PPV of interest
     
      } 
      if(input_var %in% c("Total1yr","Total2yr","Total3yr","Chronic")){
      
        rev.PPV = PPVs
        rev.surreffs = surr_effs
      
        loc.above.thresh = which(rev.PPV > probability_threshold)[1] # Find the weakest surrogate effect that produces a PPV above the threshold of interest
        loc.below.thresh = which(rev.PPV > probability_threshold)[1]-1 # Find the next weakest surrogate effect (PPV below threshold)
      
        ppv1 = rev.PPV[loc.below.thresh]
        ppv2 = rev.PPV[loc.above.thresh]
      
        surreffs1 = rev.surreffs[loc.below.thresh]
        surreffs2 = rev.surreffs[loc.above.thresh]
      
        interp.mod = lm(c(surreffs1,surreffs2) ~ c(ppv1,ppv2)) # To map the surrogate effect that gives the desired PPV of interest
      
      }
    
      thresholds[se] = as.numeric(interp.mod$coefficients[1] + interp.mod$coefficients[2]*probability_threshold)
    
    }
    
  }
  
  return(as.data.frame(cbind(trial_sizes,thresholds)))

}

# Example run:
# thres.out=gen.trt.thresh(posteriors_location="U:/Shared/CKD_Endpts/willem/predictions_Rcode/willem_rcode/07292022_jm",
#                          SE_filename="SlopeSEJuly12.csv",model_number=1,date="20220513",
#                          slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur", 
#                          mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#                          surr_effs=seq(0,2,0.025),probability_threshold=0.975,benefit_threshold=log(1),trial_sizes=c("Large","Medium","Small"),
#                          outcome_var="Clinical_Endpoint",input_var="Chronic")





#Example run: Main prediction
# loc.in="U:/Shared/CKD_Endpts/CKD-EPI CT/Transfer of trial level to R/Predictions/test_results/20230713/Rloop"
# loc.out="U:/Shared/CKD_Endpts/CKD-EPI CT/Transfer of trial level to R/Predictions/test_results/20230713/outputR"
# file.se="gense_75_230216.csv"; date.ymd="20230713"
# # a.type="TrialSize-Large_Future-Trial_absolute"
# 
# # table_cond_t01=as.data.frame(readxl::read_xlsx("U:/Shared/CKD_Endpts/CKD-EPI CT/AlbvsSlope/Overall/results/20230602/rcode/tbl_triallev_param_ct230602.xlsx"))
# table_cond_t01=as.data.frame(readxl::read_xlsx("U:/Shared/CKD_Endpts/CKD-EPI CT/Transfer of trial level to R/Predictions/test_results/20230713/rcode/tbl_triallev_param_ct230713.xlsx"))
# mod.list=1:16
# percentiles.out=data.frame(mod.number=numeric(),run.date=character(),in.file=character(),
#                            name.surr=character(),name.est=character(),evt.num=numeric(),
#                            name.subset=character(),name.excl=character(),
#                            prior.surr=character(),prior.est=character(),
#                            abs.or.rel=character(),method=character(),
#                            trial.size=character(),surr_effs=numeric(),
#                            mean=numeric(),std=numeric(),min=numeric(),
#                            p01=numeric(),p2_5=numeric(),p05=numeric(),p10=numeric(),p20=numeric(),
#                            p25=numeric(),p30=numeric(),p40=numeric(),p50=numeric(),median=numeric(),
#                            p60=numeric(),p70=numeric(),p75=numeric(),p80=numeric(),p90=numeric(),
#                            p95=numeric(),p97_5=numeric(),p99=numeric(),max=numeric(),
#                            PPV1=numeric(),PPV2=numeric(),PPV3=numeric(),
#                            PPV0_slp=numeric(),PPV1_slp=numeric(),PPV2_slp=numeric(),PPV3_slp=numeric(),
#                            PPV_hr_0=numeric(),PPV_hr_n0_2=numeric(),
#                            PPV_hr_n0_3=numeric(),PPV_hr_n0_5=numeric(),
#                            PPV_slp_0_75=numeric(),PPV_slp_0_9=numeric(),
#                            PPV_slp_1=numeric(),PPV_slp_1_1=numeric(),
#                            PPV_slp_1_2=numeric() )
# thres.out=data.frame(mod.number=numeric(),run.date=character(),
#                      name.surr=character(),name.est=character(),evt.num=numeric(),
#                      name.subset=character(),name.excl=character(),
#                      prior.surr=character(),prior.est=character(),
#                      trial.size=character(),thresholds97_5=numeric(),
#                      thresholds95=numeric(),thresholds90=numeric() )
# 
# for(idx.mod in mod.list){
#   table_cond_t01_s=subset(table_cond_t01,mod.num==idx.mod)
#   l_slp="ACR"; surr_effs_ppd=seq(0,1,0.25); surr_effs_thres=seq(-3,1,0.1)
#   if(l_slp=="ACR"){
#     surr_effs_ppd=log(surr_effs_ppd); surr_effs_thres=log(surr_effs_thres)
#   }
#   l_out=ifelse(table_cond_t01_s$name.outcome=="chronic-slope","Chronic",
#                ifelse(table_cond_t01_s$name.outcome=="total-slope-2y","Total2yr",
#                       ifelse(table_cond_t01_s$name.outcome=="total-slope-3y","Total3yr",
#                              "Clinical_Endpoint")))
#   
#   for(idx.abs in c("absolute","relative")){
#     for(idx.method in c("future-trial","confidence","prediction")){
#       if(idx.method=="future-trial"){
#         for(idx.trialsize in c("Large","Medium","Small")){
#           ppd.mat.out=gen.ppds(posteriors_location=loc.in,SE_filename=file.se,
#                                slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#                                mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#                                method=idx.method,surr_effs=surr_effs_ppd,output_location=loc.out,
#                                model_number=idx.mod,date=date.ymd,trial_sizes=idx.trialsize,
#                                outcome_var=l_out,input_var=l_slp,abs_or_rel=idx.abs,save.output=T)
#           
#           myPreds1=ppd.mat.out[1:length(grep("Surrogate.Effect",colnames(ppd.mat.out),value=TRUE))]
#           percentiles.temp=data.frame(mod.number=ppd.mat.out$model_number[1],run.date=ppd.mat.out$date[1],
#                                       in.file=table_cond_t01_s$in.file,
#                                       name.surr=table_cond_t01_s$effect.est,name.est=table_cond_t01_s$outcome.est,
#                                       name.subset=table_cond_t01_s$subset.desc,name.excl=table_cond_t01_s$excl.name,
#                                       prior.surr=table_cond_t01_s$prior.sur,prior.est=table_cond_t01_s$prior.err,
#                                       abs.or.rel=idx.abs,method=idx.method,trial.size=idx.trialsize,
#                                       surr_effs=ppd.mat.out$surrogate_effects[which(!is.na(ppd.mat.out$surrogate_effects))],
#                                       mean=apply(myPreds1,2,mean),std=apply(myPreds1,2,sd),
#                                       min=apply(myPreds1,2,min),
#                                       p01=apply(myPreds1,2,function(x) quantile (x,probs=0.01)),
#                                       p2_5=apply(myPreds1,2,function(x) quantile (x,probs=0.025)),
#                                       p05=apply(myPreds1,2,function(x) quantile (x,probs=0.05)),
#                                       p10=apply(myPreds1,2,function(x) quantile (x,probs=0.1)),
#                                       p20=apply(myPreds1,2,function(x) quantile (x,probs=0.2)),
#                                       p25=apply(myPreds1,2,function(x) quantile (x,probs=0.25)),
#                                       p30=apply(myPreds1,2,function(x) quantile (x,probs=0.3)),
#                                       p40=apply(myPreds1,2,function(x) quantile (x,probs=0.4)),
#                                       p50=apply(myPreds1,2,function(x) quantile (x,probs=0.5)),
#                                       median=apply(myPreds1,2,median),
#                                       p60=apply(myPreds1,2,function(x) quantile (x,probs=0.6)),
#                                       p70=apply(myPreds1,2,function(x) quantile (x,probs=0.7)),
#                                       p75=apply(myPreds1,2,function(x) quantile (x,probs=0.75)),
#                                       p80=apply(myPreds1,2,function(x) quantile (x,probs=0.8)),
#                                       p90=apply(myPreds1,2,function(x) quantile (x,probs=0.9)),
#                                       p95=apply(myPreds1,2,function(x) quantile (x,probs=0.95)),
#                                       p97_5=apply(myPreds1,2,function(x) quantile (x,probs=0.975)),
#                                       p99=apply(myPreds1,2,function(x) quantile (x,probs=0.99)),
#                                       max=apply(myPreds1,2,max),
#                                       PPV1=colMeans(myPreds1<log(1)),PPV2=colMeans(myPreds1<log(0.9)),
#                                       PPV3=colMeans(myPreds1<log(0.8)),
#                                       PPV0_slp=colMeans(myPreds1>0),PPV1_slp=colMeans(myPreds1>0.5),
#                                       PPV2_slp=colMeans(myPreds1>0.75),PPV3_slp=colMeans(myPreds1>1),
#                                       PPV_hr_0=colMeans(myPreds1<0),PPV_hr_n0_2=colMeans(myPreds1<(-0.2)),
#                                       PPV_hr_n0_3=colMeans(myPreds1<(-0.3)),PPV_hr_n0_5=colMeans(myPreds1<(-0.5)),
#                                       PPV_slp_0_75=colMeans(myPreds1<0.75),PPV_slp_0_9=colMeans(myPreds1<0.9),
#                                       PPV_slp_1=colMeans(myPreds1<1),PPV_slp_1_1=colMeans(myPreds1<1.1),
#                                       PPV_slp_1_2=colMeans(myPreds1<1.2),
#                                       evt.num=table_cond_t01_s$evt.num)
#           percentiles.out=rbind(percentiles.out,percentiles.temp); rm(percentiles.temp)
#           
#           if(idx.abs=="absolute"){
#             thres.raw97_5=gen.trt.thresh(posteriors_location=loc.in,SE_filename=file.se,model_number=idx.mod,date=date.ymd,
#                                      slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#                                      mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#                                      surr_effs=surr_effs_thres,probability_threshold=0.975,benefit_threshold=0,trial_sizes=idx.trialsize,
#                                      outcome_var=l_out,input_var=l_slp)
#             thres.raw95=gen.trt.thresh(posteriors_location=loc.in,SE_filename=file.se,model_number=idx.mod,date=date.ymd,
#                                      slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#                                      mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#                                      surr_effs=surr_effs_thres,probability_threshold=0.95,benefit_threshold=0,trial_sizes=idx.trialsize,
#                                      outcome_var=l_out,input_var=l_slp)
#             thres.raw90=gen.trt.thresh(posteriors_location=loc.in,SE_filename=file.se,model_number=idx.mod,date=date.ymd,
#                                      slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#                                      mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#                                      surr_effs=surr_effs_thres,probability_threshold=0.9,benefit_threshold=0,trial_sizes=idx.trialsize,
#                                      outcome_var=l_out,input_var=l_slp)
#             thres.temp=data.frame(mod.number=ppd.mat.out$model_number[1],run.date=ppd.mat.out$date[1],
#                                   name.surr=table_cond_t01_s$effect.est,name.est=table_cond_t01_s$outcome.est,
#                                   name.subset=table_cond_t01_s$subset.desc,name.excl=table_cond_t01_s$excl.name,
#                                   prior.surr=table_cond_t01_s$prior.sur,prior.est=table_cond_t01_s$prior.err,
#                                   trial.size=thres.raw97_5$trial_sizes,
#                                   thresholds97_5=thres.raw97_5$thresholds, thresholds95=thres.raw95$thresholds, thresholds90=thres.raw90$thresholds,
#                                   evt.num=table_cond_t01_s$evt.num)
#             thres.out=rbind(thres.out,thres.temp); rm(thres.temp)
#             
#           }
#           
#           rm(ppd.mat.out)
#         }
#         
#       }else{
#         ppd.mat.out=gen.ppds(posteriors_location=loc.in,SE_filename=file.se,
#                              slope_name="beta",intercept_name="alpha",error_variance_name="sigSqClinonSur",
#                              mean_surrogate_effect_name="muSur",variance_surrogate_effect_name="sigSqSur",
#                              method=idx.method,surr_effs=surr_effs_ppd,output_location=loc.out,
#                              model_number=idx.mod,date=date.ymd,trial_sizes=NA,
#                              outcome_var=l_out,input_var=l_slp,abs_or_rel=idx.abs,save.output=T)
#         
#         myPreds1=ppd.mat.out[1:length(grep("Surrogate.Effect",colnames(ppd.mat.out),value=TRUE))]
#         percentiles.temp=data.frame(mod.number=ppd.mat.out$model_number[1],run.date=ppd.mat.out$date[1],
#                                     in.file=table_cond_t01_s$in.file,
#                                     name.surr=table_cond_t01_s$effect.est,name.est=table_cond_t01_s$outcome.est,
#                                     name.subset=table_cond_t01_s$subset.desc,name.excl=table_cond_t01_s$excl.name,
#                                     prior.surr=table_cond_t01_s$prior.sur,prior.est=table_cond_t01_s$prior.err,
#                                     abs.or.rel=idx.abs,method=idx.method,trial.size=NA,
#                                     surr_effs=ppd.mat.out$surrogate_effects[which(!is.na(ppd.mat.out$surrogate_effects))],
#                                     mean=apply(myPreds1,2,mean),std=apply(myPreds1,2,sd),
#                                     min=apply(myPreds1,2,min),
#                                     p01=apply(myPreds1,2,function(x) quantile (x,probs=0.01)),
#                                     p2_5=apply(myPreds1,2,function(x) quantile (x,probs=0.025)),
#                                     p05=apply(myPreds1,2,function(x) quantile (x,probs=0.05)),
#                                     p10=apply(myPreds1,2,function(x) quantile (x,probs=0.1)),
#                                     p20=apply(myPreds1,2,function(x) quantile (x,probs=0.2)),
#                                     p25=apply(myPreds1,2,function(x) quantile (x,probs=0.25)),
#                                     p30=apply(myPreds1,2,function(x) quantile (x,probs=0.3)),
#                                     p40=apply(myPreds1,2,function(x) quantile (x,probs=0.4)),
#                                     p50=apply(myPreds1,2,function(x) quantile (x,probs=0.5)),
#                                     median=apply(myPreds1,2,median),
#                                     p60=apply(myPreds1,2,function(x) quantile (x,probs=0.6)),
#                                     p70=apply(myPreds1,2,function(x) quantile (x,probs=0.7)),
#                                     p75=apply(myPreds1,2,function(x) quantile (x,probs=0.75)),
#                                     p80=apply(myPreds1,2,function(x) quantile (x,probs=0.8)),
#                                     p90=apply(myPreds1,2,function(x) quantile (x,probs=0.9)),
#                                     p95=apply(myPreds1,2,function(x) quantile (x,probs=0.95)),
#                                     p97_5=apply(myPreds1,2,function(x) quantile (x,probs=0.975)),
#                                     p99=apply(myPreds1,2,function(x) quantile (x,probs=0.99)),
#                                     max=apply(myPreds1,2,max),
#                                     PPV1=colMeans(myPreds1<log(1)),PPV2=colMeans(myPreds1<log(0.9)), #For UP vs slope analyses, use 0.5, 0.75, etc.
#                                     PPV3=colMeans(myPreds1<log(0.8)),
#                                     PPV0_slp=colMeans(myPreds1>0),PPV1_slp=colMeans(myPreds1>0.5),
#                                     PPV2_slp=colMeans(myPreds1>0.75),PPV3_slp=colMeans(myPreds1>1),
#                                     PPV_hr_0=colMeans(myPreds1<0),PPV_hr_n0_2=colMeans(myPreds1<(-0.2)),
#                                     PPV_hr_n0_3=colMeans(myPreds1<(-0.3)),PPV_hr_n0_5=colMeans(myPreds1<(-0.5)),
#                                     PPV_slp_0_75=colMeans(myPreds1>0.75),PPV_slp_0_9=colMeans(myPreds1>0.9),
#                                     PPV_slp_1=colMeans(myPreds1>1),PPV_slp_1_1=colMeans(myPreds1>1.1),
#                                     PPV_slp_1_2=colMeans(myPreds1>1.2),
#                                     evt.num=table_cond_t01_s$evt.num)
#         percentiles.out=rbind(percentiles.out,percentiles.temp); rm(percentiles.temp); rm(ppd.mat.out)
#       }
#     }
#     
#   }
#   
# }
# # write.csv(percentiles.out,paste0(loc.out,"/predictions_altR_230713.csv"),na="",row.names=FALSE)
# # write.csv(thres.out,paste0(loc.out,"/thresholds_altR_230713.csv"),na="",row.names=FALSE)
# 
# percentiles.out=read.csv(paste0(loc.out,"/predictions_altR_230713.csv"))
# t4=percentiles.out[percentiles.out$abs.or.rel=="absolute" & percentiles.out$method=="future-trial",
#                    c("mod.number","run.date","in.file","name.surr","name.est","evt.num","name.subset",
#                      "name.excl","prior.surr","prior.est","trial.size","surr_effs","p2_5","p10","median",
#                      "p90","p97_5","PPV1")]
# t4$surr_effs=format(round(exp(t4$surr_effs),2),digits=2,nsmall=2)
# t4$p2_5=format(ifelse(t4$name.est=="loghr2_est",round(exp(t4$p2_5),2),round(t4$p2_5,2)),digits=2,nsmall=2)
# t4$p10=format(ifelse(t4$name.est=="loghr2_est",round(exp(t4$p10),2),round(t4$p10,2)),digits=2,nsmall=2) 
# t4$median=format(ifelse(t4$name.est=="loghr2_est",round(exp(t4$median),2),round(t4$median,2)),digits=2,nsmall=2)
# t4$p90=format(ifelse(t4$name.est=="loghr2_est",round(exp(t4$p90),2),round(t4$p90,2)),digits=2,nsmall=2)
# t4$p97_5=format(ifelse(t4$name.est=="loghr2_est",round(exp(t4$p97_5),2),round(t4$p97_5,2)),digits=2,nsmall=2) 
# t4$PPV1=format(t4$PPV1,digits=2,nsmall=2)
# t4$ci95=paste0(t4$p2_5,", ",t4$p97_5); t4$ci80=paste0(t4$p10,", ",t4$p90)
# t4=t4[,c(1:12,15,19,20,18)]
# # write.csv(t4,paste0("U:/Shared/CKD_Endpts/CKD-EPI CT/Transfer of trial level to R/Predictions/test_results/20230713/summary_files",
# #                     "/ppd_summary_R.csv"),na="",row.names=FALSE)
# 
# 
# 
# 
# ##For Posterior MCMC
# 
# t4_1b=t4_1[,c("name.est","surr_effs","min","p2_5","p05","p10","p20","p25","p40","p50",
#               "p60","p75","p80","p90","p95","p97_5","max","mean","std","PPV_slp_0_75",
#               "PPV_slp_0_9","PPV_slp_1","PPV_slp_1_1","PPV_slp_1_2")]
# t4_1b$surr_effs=round(exp(t4_1b$surr_effs),1)
# t4_1b$name.est=ifelse(t4_1b$name.est=="beta41_42_2y_est","Total slope at 2 years",
#                       ifelse(t4_1b$name.est=="beta41_42_3y_est","Total slope at 3 years",
#                              ifelse(t4_1b$name.est=="beta41_42_1y_est","Total slope at 1 year",
#                                     "Chronic slope")))
# # write.csv(t4_1b,paste0("U:/Shared/CKD_Endpts/CKD-EPI CT/AlbvsSlope/Overall/results/20230602/summary_files",
# #                     "/posteriorMCMCsummary_GFRslope.csv"),na="",row.names=FALSE)
# 
# t4_2b=t4_2[,c("evt.num","surr_effs","min","p2_5","p05","p10","p20","p25","p40","p50",
#               "p60","p75","p80","p90","p95","p97_5","max","mean","std","PPV_hr_0",
#               "PPV_hr_n0_2","PPV_hr_n0_3","PPV_hr_n0_5")]
# t4_2b$surr_effs=round(exp(t4_2b$surr_effs),1)
# t4_2b$evt.num=ifelse(t4_2b$evt.num==3,"KRT, eGFR<15 or double sCR",
#                       ifelse(t4_2b$evt.num==4,"KRT or eGFR<15",
#                              ifelse(t4_2b$evt.num==2,"KRT, eGFR<15 or 30% eGFR decline",
#                                     ifelse(t4_2b$evt.num==1,"KRT, eGFR<15 or 40% eGFR decline",
#                                            ifelse(t4_2b$evt.num==8,"40% eGFR decline",
#                                                   ifelse(t4_2b$evt.num==9,"30% eGFR decline",
#                                                          ""))))))
# t4_2b$min=exp(t4_2b$min); t4_2b$p2_5=exp(t4_2b$p2_5); t4_2b$p5=exp(t4_2b$p5); t4_2b$p10=exp(t4_2b$p10)
# t4_2b$p20=exp(t4_2b$p20); t4_2b$p25=exp(t4_2b$p25); t4_2b$p40=exp(t4_2b$p40); t4_2b$p50=exp(t4_2b$p50)
# t4_2b$p60=exp(t4_2b$p60); t4_2b$p75=exp(t4_2b$p75); t4_2b$p80=exp(t4_2b$p80); t4_2b$p90=exp(t4_2b$p90)
# t4_2b$p95=exp(t4_2b$p95); t4_2b$p97_5=exp(t4_2b$p97_5); t4_2b$max=exp(t4_2b$max)
# t4_2b$mean=exp(t4_2b$mean); t4_2b$std=exp(t4_2b$std)
# # write.csv(t4_2b,paste0("U:/Shared/CKD_Endpts/CKD-EPI CT/AlbvsSlope/Overall/results/20230602/summary_files",
# #                     "/posteriorMCMCsummary_CE.csv"),na="",row.names=FALSE)
