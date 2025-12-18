**Overview**

Kidney disease is a worldwide  public health problem, disproportionately affecting older people and lower and middle income countries, with major outcomes including kidney failure and cardiovascular disease. The CKD Epidemiology Collaboration (CKD-EPI) is a research group founded in 2003 and has interests in evaluation of surrogate endpoints for clinical trials in CKD (CKD-EPI CT) along with estimation and measurement of glomerular filtration rate (GFR). 

The programs shown here were used to study the association between treatment effects on surrogate endpoints (slope of the GFR, and albuminuria) with treatment effects on clinical endpoints (kidney failure with replacement therapy), in order to validate the use of these surrogate endpoints in clinical trials of chronic kidney disease. Results from our latest analyses are presented in Inker, et al, Nature Medicine 2023 and Heerpspink, et al, Lancet Diabetes Endocrinol, 2019.

Our meta-analytic approach followed seven main steps: 
(a) Search and identify data from published randomized control trials (RCTs) using a standardized approach
(b) Obtain agreement for use of individual data and transfer to Data Coordinating Center at Tufts Medical center or identify methods for cloud based data access
(c) Within each RCT, use intent-to-treat analyses to estimate a) the effect of the treatment on GFR slope under a shared parameter mixed effect model, and b) the effect of the treatment on clinical endpoint (defined as a composite of kidney failure, sustained GFR <15 mL/min per 1.73 m2; or doubling of serum creatinine) under a Cox proportional hazards regression model
(d) Quantify the association between treatment effects on the GFR slope and treatment effects on clinical endpoints across RCTs using trial-level Bayesian meta-regression analysis
(e) Identify outliers and evaluate model adequacy across the individual trials by using a cross-validation approach to compare the observed treatment effect on the clinical endpoint in each trial to the posterior predictive distribution for that trial derived from the trial-level model fit to the remaining trials
(f) Quantify the consistency in these associations across disease subgroups using Bayesian meta-regression with partial pooling
(g) Assess the utility of using slope as a surrogate endpoint in a future trial by providing 95% Bayesian prediction intervals and trial level positive predictive values corresponding with a range of possible treatment effects on the slope endpoint in a hypothetical future trial. 

The analytic approach is based on the causal association framework in which the validity of surrogate endpoints is evaluated based on the relationship between the average causal effect of the treatment on the surrogate endpoint and the average causal effect of the treatment on the clinical endpoint across a population of RCTs. This approach takes advantage of the fact that the average causal effects on the surrogate and clinical endpoints can be estimated with little bias within each RCT by applying intent-to-treat analyses (Joffe, et al, Biometrics 2009; Daniels, et al, Statistics in medicine, 1997; Burzykowski, et al, Pharmaceutical statistics, 2006; Burzykowski, Springer, New York, 2005). Confidence in the use of these results for a future new trial is increased when the previously conducted trials provide evidence that the treatment effect on the clinical endpoint is consistently predicted from the treatment effect on the surrogate across a broad collection of RCTs evaluating treatments which operate through diverse mechanisms and across diverse patient populations. As a result, the empirical support for a surrogate endpoint is enhanced when the trial-level meta-regression is conducted over a heterogeneous rather than a homogenous collection of previously conducted RCTs. 


**Below are the detailed steps for analyses that correspond with the programs in this GitHub.**
(Note: The  numbers below do not follow the bullet numbers in the seven steps in the overview.)

# Step 1: Data cleaning   
# A) Basic data management
[Steps to be done using researchers' own SAS/R/other codes]
a. The goal of this step is to create preliminary datasets to match the template provided in the Excel sheet “Datasets template”. Since each study is different we are unable to provide programs for getting to these preliminary datasets. Please use your own way of coding for deriving them. 
The three datasets you should have at the end of this step are: Baseline,	Scr,	UP
The Excel template has tabs corresponding to each of these datasets, with the first three rows providing the variable name to be used and the definition or calculation method for each variable and the rows after that showing examples. 
b.	Conditions to be applied to the data
  •	Keep only participants aged 18 years or older
  •	Keep only randomized participants (even in the follow-up data), or if available, only participants used in ‘full analysis set’ in the original study
  •	Keep only visits at or after randomization. Sometimes a variable indicating no. of days since randomization may have a negative value in the original dataset. But the dataset  might have a separate variable indicating if the given visit was considered as the baseline despite having a negative value. In this case, set the value for visit_time as 0.
c. Rename your variables with the exact names in the template, including caps. This is a crucial step.
d.	Please fill out the relevant cells in the tab “At a glance” to document your variable selection process and as a means of communicating with the data coordinating center (TuftsMC) about doubts or limitations.
e.	Save the datasets in the folder “2 Clean data”.

# B) Creating derived variables
[Steps using code in the folder 1_data_cleaning]
a.	Once you have the above 3 datasets, the rest of the data management can be done using the SAS program “Steps code”. 
b.	To run this code, assign the file path of the Root directory to path1.
c.	Assign the location of your recently cleaned data to the library ‘clean_data’.
d.	Press control + H to replace “newstudy” with a 6 character name for your study.
e.	You should see these additional datasets generated in the “2 Clean data” folder.
newstudy_baseline,	newstudy_egfr,	newstudy_upro, fdac2_baseline,	fdac2_studygfr,	fdac2_studygfrup, fdac2_tx_allendpts,	fdac2_tx_slctendpts,	fdac2_visits, fdac2_visits_interim,	upro_change9m,	upro_change9m (Excel)

# C) Data checks   
a.	Step 1b outputs a summary of variables. Please check the values generated against the published results of your study to ensure at least the published variables are coded correctly.
b.	This is also an opportunity to check other variables and rerun analysis as needed. Negative values for variables indicating number of days, very high or very low values for lab parameters are some red flags to be aware of.
c.	Another check performed by step 2 is if there are sufficient values for conducting change in albuminuria analysis. Please work with TuftsMC data manager to decide if the study is eligible for albuminuria analysis.
d.	After this step, you should have datasets that have been deemed okay by you and TuftsMC data manager and are ready for analysis.

# Step 2: Treatment effect estimation and computing correlations between different treatment effects

Please refer to the analysis_sets folder. Here, we applied the mixed effects models to estimate the treatment effects on GFR slope or albuminuria within each study by treatment arm, with treatment effects expressed as differences in the mean GFR slopes between the treatment versus control groups in units of ml/min/1.73m2/year. We estimated treatment effects on the clinical endpoint by performing separate Cox proportional hazard regressions to estimate log hazard ratios for the treatment in each trial. We summarized the mean treatment effects on each individual endpoint using restricted maximum likelihood with study as a random effect (rma.uni function in R metafor package).

For steps 2 onwards, make subfolders in your directory as shown in the repository.
The different subfolders under analysis_sets are:
1. acr6 and acr12 -- ACR (i.e. albuminuria) analysis
2. all -- GFR slope analysis using the full follow-up period
3. trunc18 and trunc24 -- GFR slope analysis using truncated follow-up periods
4. quad -- GFR slope analysis using quadratic method
   
Sequentially run codes displayed under sasprograms subfolder under these analysis_sets. 
Please save the SAS logs under exports for each program that you run so that we can go back and check them if we face issues during the meta-analysis.

# Step 3: Merging summary data from each study in your database
1. Using your own code, merge 'nt99a' file from each study (found in the exports subfolder under analysis_sets\all or acr6 or acr12 etc.)
2. This is the pooled trial-level input file for the next steps.

# Step 4: Trial-level analysis - Bayesian meta-regression

We applied a trial-level Bayesian mixed effects meta-regression model to relate the treatment effects on the clinical endpoint to the treatment effects on GFR slope with study as the unit of analysis41,50. The model relates the treatment effects on the two endpoints after accounting for the standard deviations of the random errors in the estimated effects in each study and the correlation of these errors with each other. This approach takes advantage of the fact that the average causal effects on the surrogate and clinical endpoints can be estimated with little bias within each randomized trial by applying intent-to-treat analyses51-53. The model includes two stages, where the first stage relates the estimated treatment effects to the true latent treatment effects within each trial, and the second stage describes the relationships between the true latent treatment effects across the different trials. 

The trial-level analysis will support GFR slope or albuminuria as a surrogate endpoint if the slope of the meta-regression relating the treatment effect on the clinical endpoint to the treatment effect on the designated GFR slope endpoint or albuminuria differs substantially from 0, the R2 and RMSE or the meta-regression indicates that the estimated treatment effect on the GFR slope endpoint can reliably predict the treatment effect on the clinical endpoint, and the intercept of the meta-regression line is close to 0, indicating that the absence of a treatment effect on the GFR slope endpoint is not systematically associated with a non-zero treatment effect on the clinical endpoint. 

Set up and run the R function 'Surrogate_Meta_Regression_RCode_Pipeline_20250529.R'. Instructions/sample code for calling the function are provided at the end of the function.

# Step 5: Application of results to future trials - predictions

Here we apply the trial level meta-regression to a newly conducted randomized trial.

Set up and run the R function 'ppdppv_newmethod_2023.07.24.r'.


# //Step 2 as per an older method which was used until 2025//
# Step 2:	Treatment effect estimation

a) ACR (i.e. albuminuria) analysis - folder analysis_acr
1.	Sequentially run codes under path1\analysis_acr\sasprograms.
Please save the SAS logs under acr_exports for each program that you run so that we can go back and check them if we face issues during the meta-analysis.

b) GFR slope analysis  - folder analysis_egfrslope/truncation_99
1.	Sequentially run the codes under path1\analysis_egfrslope\truncation_99\sasprograms. Please save the SAS logs under truncation_99_exports for each program that you run so that we can go back and check if we face issues during the meta-analysis.
2.	Sequentially run the codes under path1\analysis_egfrslope\truncation_99_acr30\sasprograms. Please save the SAS logs under truncation_99_acr30_exports for each program that you run so that we can go back and check them if we face issues during the meta-analysis.
3. ACR>100 or ACR>30 analyses: 1. Repeat Steps 3 using the right subset of data.

