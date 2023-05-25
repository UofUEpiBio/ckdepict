# ckdepict
# Step 1a: Data cleaning   
1.	Steps to be done manually, i.e. no code provided:
a.	The goal of this step is to create preliminary datasets to match the template provided in the Excel sheet “Datasets template”. The three datasets you should have at the end of this step are: 
Baseline,	Scr,	UP
The template has tabs corresponding to each of these datasets, with the first three rows providing the variable name to be used and the definition or calculation method for each variable and the rows after that showing examples. 
b.	Rename your variables with the exact names in the template, including caps. This is a crucial step.
c.	Since each study is different we are unable to provide programs for getting to these preliminary datasets. Please use your own way of coding for deriving them. 
d.	Please fill out the relevant cells in the tab “At a glance” to document your variable selection process and as a means of communicating with the data coordinating center (TuftsMC) about doubts or limitations.
e.	Save the datasets in the folder “2 Clean data”.

Conditions to be applied to the data
•	Keep only participants aged 18 years or older
•	Keep only randomized participants (even in the follow-up data), or if available, only participants used in ‘full analysis set’ in the original study
•	Keep only visits at or after randomization. 
i.	Sometimes a variable indicating no. of days since randomization may have a negative value in the original dataset. But the dataset might have a separate variable indicating if the given visit was considered as the baseline despite having a negative value. In this case, set the value for visit_time as 0.

# Step 1b: Automated - folder data_cleaning 
a.	Once you have the above 3 datasets, the rest of the cleaning can be done using the SAS program “Steps code”. 
b.	To run this code, assign the file path of the Root directory to path1.
c.	Assign the location of your recently cleaned data to the library ‘clean_data’.
d.	Press control + H to replace “newstudy” with a 6 character name for your study.
e.	You should see these additional datasets generated in the “2 Clean data” folder.
newstudy_baseline	newstudy_egfr	newstudy_upro
fdac2_baseline	fdac2_studygfr	fdac2_studygfrup
fdac2_tx_allendpts	fdac2_tx_slctendpts	fdac2_visits
fdac2_visits_interim	upro_change9m	upro_change9m (Excel)

# Step 1c: Data checks   
a.	Step 2 outputs a summary of variables. Please check the values generated against the published results of your study to ensure at least the published variables are coded correctly.
b.	This is also an opportunity to check other variables and rerun analysis as needed. Negative values for variables indicating number of days, very high or very low values for lab parameters are some red flags to be aware of.
c.	Another check performed by step 2 is if there are sufficient values for conducting change in albuminuria analysis. Please work with TuftsMC data manager to decide if the study is eligible for albuminuria analysis.
d.	After this step, you should have datasets that have been deemed okay by you and TuftsMC data manager and are ready for analysis.

# Step 2:	ACR (i.e. albuminuria) analysis - folder analysis_acr
1.	Sequentially run codes under path1\analysis_acr\sasprograms.
Please save the SAS logs under acr_exports for each program that you run so that we can go back and check them if we face issues during the meta-analysis.

# Step 3: GFR slope analysis  - folder analysis_egfrslope/truncation_99
1.	Sequentially run the codes under path1\analysis_egfrslope\truncation_99\sasprograms. Please save the SAS logs under truncation_99_exports for each program that you run so that we can go back and check if we face issues during the meta-analysis.
2.	Sequentially run the codes under path1\analysis_egfrslope\truncation_99_acr30\sasprograms. Please save the SAS logs under truncation_99_acr30_exports for each program that you run so that we can go back and check them if we face issues during the meta-analysis.
3. ACR>100 or ACR>30 analyses: 1. Repeat Steps 3 using the right subset of data.

**# Step 4: Merging summary data from each study in your database**
1. Using your own code, merge 'nt99a_ce_up_corrs_updated' file from each study (found in ...\Root\analysis_egfrslope\truncation_99\truncation_99_exports)
2. This file is the main input file for the next steps.

# Step 5: Trial-level analysis
Set up and run the R fucntion 'Surrogate_Meta_Regression_RCode_Pipeline_UpDate_02-09-23jm' in your own R code.

# Step 6: Application of results to future trials - predictions
Set up and run the R function 'PPD-PPV_R_Script' in your own R code.
