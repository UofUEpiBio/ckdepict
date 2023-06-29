*******************************************************************;
**   PROGRAM: SIM Supplement - SAS code for MDRD-B Example.sas   **;
**   WRITTEN: SEP 26, 2018                                       **;
**   UPDATED: FEB 12, 2019                                       **;
**   REVISED: MAR 10, 2021                                       **;
**   AUTHOR : Edward Vonesh                                      **;
**   PURPOSE: This program provides the SAS code used to fit the **;
**            shared parameter (SP) models used in the examples  **;
**            for the Statistics in Medicine (SIM) paper titled: **;
**                             TITLE                             **;  
**            Mixed-effects models for slope-based endpoints in  **; 
**            clinical trials of chronic kidney disease.         **;
**                            AUTHORS                            **;
**            Vonesh E, Tighiouart H, Ying J, Heerspink HL,      **;
**            Lewis J, Staplin N, Inker L and Greene T.          **;
**                                                               **;
**                       MODEL OPTIONS                           **;
**   OPTIONS: POM:   SS/PA/NO (SS->PA->NO based on convergence)  **;
**            SP:    YES/NO (YES->NO based on number of events)  **;
**            PE:    YES/NO (YES for PE survival, N0 for Weibull)**;
**            SIMPLE:YES/NO (YES for simple LME model, else NO   **;
**                           for the linear spline ME model)     **;   
**            Kappa: YES/NO (based on convergence behaviour)     **;
**                                                               **;
** REVISIONS: An error in the original program occurs whenever   **;
**            one uses the FIXED_KNOT= option of the SAS macro   **;
**            %GetKnot. The program when run in its original form**;
**            uses %GetKnot without any options. This performs a **;
**            grid search of knot values ranging from 3-12 months**;
**            in 1 month increments and selects the knot that    **;
**            provides the best fit (lowest AIC) which turns out **;
**            to be 6 months for the MDRD-B study. It also gives **;
**            good estimates of SIGMA and THETA parameters on top**;
**            of the startng grid values given these parameters  **;
**            in the macro %GetParam_SP. However, whenever one   **;
**            specifies %GetKnot(FIXED_KNOT='value') so as to    **;
**            force a knot at a user assigned value, the program **;
**            will produce an error as a result of not computing **;
**            the good estimates of SIGMA and THETA that would   **;
**            otherwise be assigned to the macro variables &sigma**;
**            and &theta within %GetKnot. The error occurs when  **;
**            the macro %GetParam_SP is called as it expects that**;
**            values of the macro variables &sigma and &theta    **;
**            would be present but are instead missing. This has **;
**            been corrected so that the same results will be    **;
**            obtained whether one specifies %GetKnot alone or   **;
**            one specifies %GetKnot(FIXED_KNOT=6) which forces  **;
**            the knot to occur at month 6 without doing a grid  **;
**            search for the best fitting knot.                  **;
*******************************************************************;


options nodate nonumber ps=60 ls=120;
run;
/* Define global macro variables */
%global SIM_Directory Knot theta sigma;

/* Define macro variable Sim_Directory location */
*%let SIM_Directory='your directory location here';

/* Example */
 %let SIM_Directory=d:\Stat in Med\;

/*=================================================================
  The following creates the following directories with &SIM_Directory  
  being the root directory of your choice defined above.
=================================================================*/
options dlcreatedir;
libname SIM     "&SIM_Directory.\SIM_Data";
libname temp    "&SIM_Directory.\temp";
libname temp2   "&SIM_Directory.\temp2";

%put SIM= &SIM_Directory;

/*==================================================================
                      MACRO Create_SIM_data 
  This macro creates the SAS dataset SIM.studies which is stored in   
  the directory SIM created above. It uses the MDRD-B dataset which 
  one can access from the SAS author web page as indicated below. This 
  is the dataset used in the second example of the SIM paper. One can 
  adapt this macro for alternative datasets one may choose to create 
  using the same variable names, etc.

  Step 1: Download the SAS dataset mdrd_data.sas7bdat from the 
          the SAS author webpage of Edward F. Vonesh at 

          https://support.sas.com/en/books/authors/edward-vonesh.html

          and store it in a libname directory SIM created above. 
  Step 2: Run the following SAS macros to 1) create the SAS dataset  
          used for the analyses and 2) the SAS macros used to get 
          the knot and starting parameter values to run with the 
          primary macro MODEL needed to run the example. 
===================================================================*/
%macro Create_SIM_dataset;
	proc print data=SIM.mdrd_data;
	 title1 "Print of raw MDRD-B data downloaded from the SAS author web page:";
	 title2 "https://support.sas.com/en/books/authors/edward-vonesh.html";
	run;
	/*===================================================================
	  The following code creates a SAS dataset, SIM.studies, by 
	  formatting the raw MDRD-B dataset into a common format one can 
	  use for any given study. The common variables for the dataset
	  SIM.studies are as follows:

	   VARIABLE NAME	DESCRIPTION
	   Study			Study number identifying a particular study			           
 	   Studyname		Study name 
	   Subject 			A subject ID number (de-identidfied for MDRD-B)
	   TrtID 			Treatment group number (1=Control, 2=Treated)
	   Trt				Trt description (Control, Treated) based on TrtID 
	   Visit			Sequential visit number (1,2,...) with 1=baseline
	   Month 			Time of visit in months (Visit 1 has Month=0) 
	   eGFR				Value of eGFR at the given visit/month 
	   eGFR0			Baseline value of eGFR at visit=1 (month=0) 
	   ev_dx			Indicator variable for Dropout Event = Death/ESKD
 						with Event=1 if death or ESKD occured, 0 otherwise        
	   fu_dx 			Follow-up time to event (event time) in months

	  The code within this macro was written specifically to format MDRD-B
	  data to comply with a standard format for SIM.studies. This is the
	  same format used for the IDNT study example.      
	====================================================================*/
	proc sort data=SIM.mdrd_data out=SIM.studies;
	 by ptid Months;
	run;
	data SIM.studies;
	 set SIM.studies;
	 length Studyname $10;
	 by ptid Months;
	 Study=99;
	 Studyname='MDRD-B(BP)'; 
	 Subject=ptid;
	 if DietL_NormBP=1 or DietK_NormBP=1 then do; TrtID=1; Trt='Control';end; 
	 if DietL_LowBP=1  or DietK_LowBP=1  then do; TrtID=2; Trt='Treated';end;
	 if first.ptid then Visit=0;
	 Visit+1;
	 Month=Months;
	 retain eGFR0 0;
	 if first.ptid then eGFR0=GFR;
	 eGFR=GFR;
	 ev_dx=dropout;
	 fu_dx=FollowupMonths;
	 keep Study Studyname Subject TrtID Trt Visit Month eGFR eGFR0 ev_dx fu_dx; 
	run;
	proc print data=SIM.studies split='|';
	 label ev_dx = 'Event|Indicator|(Death or ESKD)'
           fu_dx = 'Event|Follow-up|Time (Months)'; 
	run;
%mend Create_SIM_dataset;

%Create_SIM_dataset;  


/*======================================================================
                          MACRO SIM_Data
  Get one specific Study and create a RESULTS directory for this Study 
  Study=    -defines what study should be run from the dataset
             SIM.studies based on the assigned study number.   
  Results=  -defines a final study-specific results sub-directory that 
             stores dataset SP_Data and all created ODS OUTPUT datasets
=======================================================================*/
%macro SIM_Data(Study=99, Results=);
	options dlcreatedir;
	libname SIM_out "&SIM_Directory.\SIM_Out";
	libname results "&SIM_Directory.\SIM_Out\&Results";
	libname SIM_out clear;
	data SIM.study&study;
	 set SIM.Studies;
	 if Study=&Study;
	 keep Study studyname Subject TrtID Trt Visit Month eGFR eGFR0 ev_dx fu_dx;
	run;
	proc print data=SIM.study&study(obs=20) noobs;
	 var Study studyname Subject TrtID Trt Visit Month eGFR eGFR0 ev_dx fu_dx;
	 title 'Partial list of Test data';
	run;
%mend;

options mprint symbolgen;


/*========================================================================
                   MACRO ClearTempDirectories 
 This macro clears all temp and temp2 datasets. This should only be called
 once at the very beginning of running code for a given study. One does 
 not need to reset the temporary datasets when running different SP models 
 for the same study.   
=========================================================================*/
%macro ClearTempDirectories;
	proc datasets nolist;
	 delete start1 end1;
	run;
	quit;
	proc datasets lib=temp2 nolist kill;
	run;
	quit;
	proc datasets lib=temp nolist kill;
	run;
	quit;
	proc datasets nolist;
	 delete Hessian matrix beta HessData HessOut est label se_model;
	run;
	quit;
%mend; 

/*=====================================================
                Macro Merge_study 
 One can use IF _n_=1 then SET temp.studyinfo to merge 
 Study and Studyname into a created ODS output dataset 
 that may not contain Study or Studyname information.  
======================================================*/
%macro Merge_study;
	data temp.studyinfo;
	 set temp.study;
	 if _n_=1;
	 keep Study Studyname;
	run;
%mend;

/*=====================================================
                  Macro GetKnot 
 This macro obtains suggested knot for the linear spline 
 mixed-effects model. One can either fix the knot at a
 user specified value via macro variable FIXED_KNOT= 
 or one can iterate PROC MIXED to get the knot with 
 the best fit (lowest AIC). 
 KEY:
 Fixed_Knot= Defines the use of a specified fixed knot
    Listing= Defines whether generated output is listed
             For no generated output, set Listing=close     
             For generated output,    set Listing=     
======================================================*/
%macro GetKnot(FIXED_KNOT=, Listing=close);
%if %length(&FIXED_KNOT) %then %do;
	%let N_Trt=2;         /* Can change this if more than two treatment groups */ 
	%Merge_study;
	data temp.ic_knot;set _null_;run;
	ods listing &listing; /* Set Listing= in call to see all the generated output */ 
	%do knot=&FIXED_KNOT %to &FIXED_KNOT;    
	data temp.study_knot;
	 set temp.study;
	 knot=&knot;
	 Month_t = MAX(Month-knot, 0);
	run;
	data temp.study_baseline;
	 set temp.study;
	 if Visit=1;
	 eGFR0 = eGFR;
	 keep Study Studyname TrtID Trt eGFR0; 
	run;
	proc sort data=temp.study_knot;
	 by TrtID Subject Month;
	run;
	ods output CovParms=temp2.cov0_&knot;
	proc mixed data=temp.study_knot ic method=ML;
	 class Subject TrtID;
	 model eGFR  = TrtID TrtID*Month TrtID*Month_t / s noint outp=temp2.mu_ij_&knot;
	 random intercept Month Month_t / subject=Subject type=un ;
	run; 
	data temp2.mu_ij_&knot;
	 set temp2.mu_ij_&knot;
	 wij = log(pred**2);
	run;
	data temp2.un0_&knot;
	 set temp2.cov0_&knot;
	 if CovParm='Residual' then delete;
	run;
	data temp2.res0_&knot;
	 set temp2.cov0_&knot;
	 if CovParm='Residual';
	 keep CovParm Estimate;
	run;
	data temp2.dummy_&knot;
	 CovParm='EXP wij'; Estimate=0; 
	run;
	data temp2.covparms_&knot;
	 set temp2.un0_&knot temp2.dummy_&knot temp2.res0_&knot;
 	run;
	/*===================================================== 
	  To see what the created datasets look like, one will 
	  need to comment out the ods listing close statement 
	=====================================================*/ 
	proc print data=temp2.covparms_&knot;run;
	proc print data=temp2.mu_ij_&knot(obs=15);run;

	ods output ConvergenceStatus=temp2.cs_&knot SolutionF=temp2.pe_&knot 
                  CovParms=temp2.cov_&knot InfoCrit=temp2.ic_&knot; 
	proc mixed data=temp2.mu_ij_&knot ic method=ML;
	 class Subject TrtID;
	 model eGFR  = TrtID TrtID*Month TrtID*Month_t / s noint;
	 random intercept Month Month_t / subject=Subject type=un ;
	 repeated / local=exp(wij);
	 parms / parmsdata=temp2.covparms_&knot;
	run; 
	data temp2.cs_&knot; 
	 set temp2.cs_&knot;
	run;
	data temp.ic_knot;
	  set temp.ic_knot temp2.ic_&knot(in=b);
	  if b then knot=&knot;
	run;
	proc sort data=temp.ic_knot;
	 by knot;
	run;
	%end;

	ods listing;
	proc rank data=temp.ic_knot out=temp.AIC_knot_fit;
	 var AIC; ranks Rank;
	run;
	proc print data=temp.AIC_knot_fit;
	run;

	data results.AIC_knot_fit;
	 set temp.AIC_knot_fit;
	 if _n_=1 then set temp.studyinfo;
	run;
	data temp.knot;
	 set temp.AIC_knot_fit;
	 if Rank=1;
	run;
	data temp.knot;
	 set temp.knot;
	 call symput('knot',left(knot)); 
	run;

	/*===================================================== 
	  Based on the selected knot that gives the best fit to
	  the data, get the corresponding parameter estimates 
	  to be merged in with the parameter estimates one    
	  gets with MACRO GetParms_SP.
	=====================================================*/ 
	data temp2.initialparms_&knot;
	 set temp2.pe_&knot temp2.cov_&knot;
	 if Effect='TrtID' then do;
      %do i=1 %to &N_Trt;
		if TrtID=&i then Parameter="beta0&i"; 
      %end;
	 end;
	 if Effect='Month*TrtID' then do;
      %do i=1 %to &N_Trt; 
		if TrtID=&i then Parameter="beta1&i"; 
	  %end;
	 end;
	 if Effect='Month_t*TrtID' then do;
      %do i=1 %to &N_Trt; 
		if TrtID=&i then Parameter="beta2&i"; 
	  %end;
	 end;
	 if CovParm='UN(1,1)'  then Parameter='psi11';
	 if CovParm='UN(2,1)'  then Parameter='psi21';
	 if CovParm='UN(2,2)'  then Parameter='psi22';
	 if CovParm='UN(3,1)'  then Parameter='psi31';
	 if CovParm='UN(3,2)'  then Parameter='psi32';
	 if CovParm='UN(3,3)'  then Parameter='psi33';
	 if CovParm='EXP wij'  then Parameter='theta';
	 if CovParm='Residual' then Parameter='sigma';
	 if CovParm='Residual' then Estimate=Estimate*100; ** Scaled up for use with NLMIXED **;
	run; 

	proc transpose data=temp2.initialparms_&knot out= temp2.initialparms_wide;
	 id Parameter;
	 var Estimate;
	run;
	data temp2.initialparms_wide;
	 set temp2.initialparms_wide;
	 kappa=0;
	 drop _name_;
	run;
	data temp.theta;
	 set temp2.cov_&knot;
	 if CovParm='EXP wij';
	 theta=round(estimate, 0.0001);
	run;
	data temp.theta;
	 set temp.theta;
	 call symput('theta',compress(left(theta))); 
	run; 
	data temp.sigma;
	 set temp2.cov_&knot;
	 if CovParm='Residual';
	 sigma=estimate*100;
	 sigma=round(sigma,0.0001); 
	run;
	data temp.sigma;
	 set temp.sigma;
	 call symput('sigma',compress(left(sigma))); 
	run; 
%end;

%else %do;
	%let N_Trt=2;         /* Currently, the program only allows 2 treatment groups */ 
	%Merge_study;
	data temp.ic_knot;set _null_;run;
	ods listing &listing; /* Set Listing= in call to see all the generated output  */ 
	%do knot=3 %to 12;    /* One can change the range of possible knots as needed  */
	data temp.study_knot;
	 set temp.study;
	 knot=&knot;
	 Month_t = MAX(Month-knot, 0);
	run;
	data temp.study_baseline;
	 set temp.study;
	 if Visit=1;
	 eGFR0 = eGFR;
	 keep Study Studyname TrtID Trt eGFR0; 
	run;
	proc sort data=temp.study_knot;
	 by TrtID Subject Month;
	run;
	ods output CovParms=temp2.cov0_&knot;
	proc mixed data=temp.study_knot ic method=ML;
	 class Subject TrtID;
	 model eGFR  = TrtID TrtID*Month TrtID*Month_t / s noint outp=temp2.mu_ij_&knot;
	 random intercept Month Month_t / subject=Subject type=un ;
	run; 
	data temp2.mu_ij_&knot;
	 set temp2.mu_ij_&knot;
	 wij = log(pred**2);
	run;
	data temp2.un0_&knot;
	 set temp2.cov0_&knot;
	 if CovParm='Residual' then delete;
	run;
	data temp2.res0_&knot;
	 set temp2.cov0_&knot;
	 if CovParm='Residual';
	 keep CovParm Estimate;
	run;
	data temp2.dummy_&knot;
	 CovParm='EXP wij'; Estimate=0; 
	run;
	data temp2.covparms_&knot;
	 set temp2.un0_&knot temp2.dummy_&knot temp2.res0_&knot;
 	run;
	/*===================================================== 
	  To see what the created datasets look like, one will 
	  need to comment out the ods listing close statement 
	=====================================================*/ 
	proc print data=temp2.covparms_&knot;run;
	proc print data=temp2.mu_ij_&knot(obs=15);run;

	ods output ConvergenceStatus=temp2.cs_&knot SolutionF=temp2.pe_&knot 
                  CovParms=temp2.cov_&knot InfoCrit=temp2.ic_&knot; 
	proc mixed data=temp2.mu_ij_&knot ic method=ML;
	 class Subject TrtID;
	 model eGFR  = TrtID TrtID*Month TrtID*Month_t / s noint;
	 random intercept Month Month_t / subject=Subject type=un ;
	 repeated / local=exp(wij);
	 parms / parmsdata=temp2.covparms_&knot;
	run; 
	data temp2.cs_&knot; 
	 set temp2.cs_&knot;
	run;
	data temp.ic_knot;
	  set temp.ic_knot temp2.ic_&knot(in=b);
	  if b then knot=&knot;
	run;
	proc sort data=temp.ic_knot;
	 by knot;
	run;
	%end;

	ods listing;
	proc rank data=temp.ic_knot out=temp.AIC_knot_fit;
	 var AIC; ranks Rank;
	run;
	proc print data=temp.AIC_knot_fit;
	run;

	data results.AIC_knot_fit;
	 set temp.AIC_knot_fit;
	 if _n_=1 then set temp.studyinfo;
	run;
	data temp.knot;
	 set temp.AIC_knot_fit;
	 if Rank=1;
	run;
	data temp.knot;
	 set temp.knot;
	 call symput('knot',left(knot)); 
	run;

	/*===================================================== 
	  Based on the selected knot that gives the best fit to
	  the data, get the corresponding parameter estimates 
	  to be merged in with the parameter estimates one    
	  gets with MACRO GetParms_SP.
	=====================================================*/ 
	data temp2.initialparms_&knot;
	 set temp2.pe_&knot temp2.cov_&knot;
	 if Effect='TrtID' then do;
      %do i=1 %to &N_Trt;
		if TrtID=&i then Parameter="beta0&i"; 
      %end;
	 end;
	 if Effect='Month*TrtID' then do;
      %do i=1 %to &N_Trt; 
		if TrtID=&i then Parameter="beta1&i"; 
	  %end;
	 end;
	 if Effect='Month_t*TrtID' then do;
      %do i=1 %to &N_Trt; 
		if TrtID=&i then Parameter="beta2&i"; 
	  %end;
	 end;
	 if CovParm='UN(1,1)'  then Parameter='psi11';
	 if CovParm='UN(2,1)'  then Parameter='psi21';
	 if CovParm='UN(2,2)'  then Parameter='psi22';
	 if CovParm='UN(3,1)'  then Parameter='psi31';
	 if CovParm='UN(3,2)'  then Parameter='psi32';
	 if CovParm='UN(3,3)'  then Parameter='psi33';
	 if CovParm='EXP wij'  then Parameter='theta';
	 if CovParm='Residual' then Parameter='sigma';
	 if CovParm='Residual' then Estimate=Estimate*100; ** Scaled up for use with NLMIXED **;
	run; 

	proc transpose data=temp2.initialparms_&knot out= temp2.initialparms_wide;
	 id Parameter;
	 var Estimate;
	run;
	data temp2.initialparms_wide;
	 set temp2.initialparms_wide;
	 kappa=0;
	 drop _name_;
	run;
	data temp.theta;
	 set temp2.cov_&knot;
	 if CovParm='EXP wij';
	 theta=round(estimate, 0.0001);
	run;
	data temp.theta;
	 set temp.theta;
	 call symput('theta',compress(left(theta))); 
	run; 
	data temp.sigma;
	 set temp2.cov_&knot;
	 if CovParm='Residual';
	 sigma=estimate*100;
	 sigma=round(sigma,0.0001); 
	run;
	data temp.sigma;
	 set temp.sigma;
	 call symput('sigma',compress(left(sigma))); 
	run; 
%end;
%mend GetKnot;

/*==========================================================
                    MACRO StudyDescrip
  This macro generates summary statistics needed to find and
  generate the intervals needed for a PE survival model.
  Visit=1 here corresponds to the baseline visit (Month=0)
===========================================================*/ 
%macro StudyDescrip;
	proc means data=temp.study nway n noprint;
	 where Visit=1;
	 var eGFR;
	 output out=temp2.SampleSize n=Patients;
	run;
	proc means data=temp.study nway min median max noprint;
	 where Visit=1;
	 var fu_dx;
	 output out=temp2.EventTime min=MinTime 
                median=MedianTime max=MaxTime;
	run;
	/*=======================================================
	 Assess how many events occur in the study and whether 
	 we need worry about informative censoring for the given
	 study if low event rates.
	========================================================*/
	proc means data=temp.study nway noprint n mean 
                               median min max range;
	 where visit=1;
	 class ev_dx;
	 var fu_dx;
	 output out=temp2.NumberEvents n=n mean=mean median=median 
                                   min=min max=max range=range; 
	run;
	proc sort data=temp2.NumberEvents;
	 by ev_dx;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_n 
	 prefix=n;
	 id ev_dx;
	 var n;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_mean 
	 prefix=mean;
	 id ev_dx;
	 var mean;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_median
	 prefix=median;
	 id ev_dx;
	 var median;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_min 
	 prefix=min;
	 id ev_dx;
	 var min;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_max 
	 prefix=max;
	 id ev_dx;
	 var max;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_range  
	 prefix=range;
	 id ev_dx;
	 var range;
	run;
	data temp2.SummaryOfEvents;
	 merge temp2.Events_n temp2.Events_mean temp2.Events_median
              temp2.Events_min temp2.Events_max temp2.Events_range; 
     PctEvents=n1/(n0+n1);
	 /*----------------------------------------------------------------------
	 DETERMINATION OF NUMBER OF PIECEWISE EXPONENTIAL (PE) INTERVALS
	 NOTE: The number of PE intervals is chosen to give a target of
              approximately 10 events per interval assuming a constant event
              rate. This is based on the paper by Eric Vittinghoff and
              Charles E. McCulloch,(American Journal of Epidemiology 165(6):
              710-718, 2007) which looks at number of events per variable in
              a Cox model needed to give adequate confidence interval 
              coverage and minimize bias in parameter estimates. 
              Here we use n1/10 assuming no other covariates in the model where
              n1 is the number of events in total. This should provide a 
              reasonable number of intervals with which one can then use to
              estimate the interval widths that yield approximately an equal 
              number of events per interval.
              A minimum of 10 events per interval should also allow us to
              estimate the piecewise baseline hazard rate parameters, eta01, 
              eta02, ... with minimal bias. A maximum of no more than 9
              intervals is assumed for the PE model.  
	 ----------------------------------------------------------------------*/
	 MaxWidth=6;
	 MaxEventTime=Max(round(max0+3), round(max1+3)); 
	 MaxIntervals=min(9, floor(MaxEventTime/MaxWidth));
	 NIntervals=min(MaxIntervals, ceil(n1/10));
	 drop _NAME_;
	run;
	data temp.StudyDescrip;
	 merge temp2.SampleSize(in=a) temp2.EventTime(in=c)
              temp2.SummaryOfEvents(in=d);
	 drop _TYPE_ _FREQ_ ;
	run;

	proc sort data=temp.study;
	 by Subject TrtID Month;
	run;
	
	/*==================================================== 
      Merge in StudyDescrip data containing MinimumMonth  
      Min(Month of follow-up post-baseline) etc. 
	=====================================================*/
	data temp.study;
	 set temp.study;
     if _n_=1 then set temp.StudyDescrip;
	run;
%mend StudyDescrip;


/*==========================================================
                    MACRO Getdata_PE
 This macro generates a dataset for a PE survival model 
===========================================================*/ 
%macro Getdata_PE;
	data temp.study;
	 set temp.study end=last;
	 if last then do;
      call symput("NIntervals",left(NIntervals)); 
      call symput('MaxEventTime',left(MaxEventTime)); 
      call symput('Patients',left(Patients)); 
	 end;
	run;
    /*=====================================
      Create a data set that just contains 
      survival data 
    =====================================*/ 
	data temp.Study_Event;
	 set temp.study; 
	 by  Subject Month;
	 Indicator=1;
	 eGFR=0; 
 	 if last.Subject;
	 keep Study Studyname Subject TrtID Indicator Month Visit 
	      eGFR ev_dx fu_dx MaxEventTime NIntervals;
	run;
	proc sort data=temp.Study_Event;
	 by Study Studyname;
	run;
	/*===================================================
	  The following code computes the interval widths 
	  for the number of intervals, NIntervals, to be used
	  for the study. It is designed to give approximatley
	  an equal number of events within each interval. 
	  It also provides the parameter estimates from PHREG 
	  for a piecewise exponential (PE) model based on the
	  interval widths determined by PHREG. 
	====================================================*/ 
	ods output partition=temp2.Intervals_PE
               parameterestimates=temp2.PHREG_PE;
 	ods select partition parameterestimates;
	proc phreg data=temp.Study_Event;
	 by Study Studyname;
	 class TrtID;
	 model fu_dx*ev_dx(0)=TrtID;
	 Bayes Piecewise=LogHazard (NInterval=&NIntervals Prior=Uniform)
        nbi=10 nmc=10;
	run;

	** Print this to see if we get uppertime=0 **;
  	proc print data=temp2.Intervals_PE;
	 title 'PE intervals from PHREG';
	run; 

	/*===================================================
	 The following code computes the width of the last 
	 interval for the number of intervals, NIntervals, 
	 to be used for the study. This is set to be the 	
	 maximum Event Time + 3 months rounded to whole month
	====================================================*/  
	data temp.Intervals_PE;
	 set temp2.Intervals_PE end=last;
	 Interval_ID=_n_;
	 if last then UpperTime=&MaxEventTime;  
	 t1=round(LowerTime, 0.001); t2=round(UpperTime, 0.001);
	run;
	data temp2.Intervals_PE;
	 set temp.Intervals_PE;
	 keep Interval_ID t1 t2;
	run;
	/*===================================================
	 The following code creates a SAS dataset containing 
	 time to event survival data for a piecewise exponential
	 (PE) survival model. The final dataset name
	 is Study_Event_PE.	 
 	====================================================*/  
	data temp2.Study_Event_PE;
	 set temp.Study_Event;
	 by Study Studyname;
	 do i=1 to NIntervals by 1;
	  Interval_ID=i;
	  output;
	 end;
	run;

	proc sort data=temp2.Study_Event_PE;
	 by Interval_ID;
	run;
	proc sort data=temp2.Intervals_PE;
	 by Interval_ID;
	run;
	data temp2.Study_Event_PE;
	 merge temp2.Study_Event_PE temp2.Intervals_PE;
	 by Interval_ID;
	run;
	proc sort data=temp2.Study_Event_PE;
	 by Study Studyname Subject Interval_ID;
	run;
	data temp2.Study_Event_PE;
	 set temp2.Study_Event_PE;
	 by  Subject Interval_ID;
	 EventModel="PE     ";
	 Outcome=0;
	 RiskTime=t2-t1;
	 if t1<fu_dx<=t2 then do;
	  Outcome=ev_dx;
	  RiskTime=fu_dx-t1;
	 end;
	 Log_RiskTime=log(RiskTime);
	 if fu_dx<t1 then delete;
	run;
	proc sort data=temp2.Study_Event_PE; 
	 by Study Studyname Subject Interval_ID;
	run;

	%put 'NIntervals=' 'MaxEventTime=' &MaxEventTIme;

	data temp.Study_Event_PE;
	 set temp2.Study_Event_PE;
	 by Study Studyname Subject Interval_ID;
	 Response=Outcome; 
	run;
%mend Getdata_PE;


/*==========================================================
                    MACRO Getdata_SP
 This macro creates a dataset for SP models using the 
 Piecewise Exponential (PE) survival model for dropout.
===========================================================*/ 
%macro Getdata_SP;
	/*=====================================
	 Create a data set that just contains 
	 eGFR profile data 
	=====================================*/ 
	proc sort data=temp.study; 
	 by Subject Month; 
	run;
	data temp.Study_eGFR;
	 set temp.study;
	 by Subject Month;
	/*=====================================
	 Define an indicator variable which is
	 1 if event is the response variable  
	 0 if eGFR is the response variable 
	=====================================*/ 
	 Indicator=0; 
	 Knot=&knot;
	/*==========================================
	 The following ensures that Interval_ID,  
	 t1, t2, RiskTime, and Outcome are not 
	 missing values in the final SP dataset 
	 when the indicator variable is 0
	==========================================*/
	 NIntervals=1;Interval_ID=1;t1=0; t2=0; Risktime=0; 
	 Log_RiskTime=0; Outcome=0;   
	 keep Study Studyname Subject Indicator Visit Month Knot eGFR 
	      TrtID t1 t2 ev_dx fu_dx RiskTime Log_RiskTime 
	      Outcome NIntervals Interval_ID;
	run;
	/*=====================================
	 Create a data set that just contains 
	 PE survival model 
	=====================================*/ 
	%StudyDescrip;
	%Getdata_PE;

	proc print data=temp.StudyDescrip;
	title 'StudyDescrip';
	run;

	proc sort data=temp.Study_Event_PE;
	 by Subject Month; 
	run;

	data temp.Study_Event;
	 set temp.Study_Event_PE;
	 by  Subject Month;
	 Indicator=1;
 	 eGFR =0;
	 keep Study Studyname Subject Indicator Visit Month eGFR 
	      TrtID t1 t2 ev_dx fu_dx RiskTime Log_RiskTime 
	      Outcome NIntervals Interval_ID;
	run;

	/*=================================================== 
	   Create a dataset for the study suitable for a 
	   SP model with a PE survival component 
	====================================================*/
	data temp.SP_data;
	 set temp.Study_eGFR(in=a)
	     temp.Study_Event(in=b);
	 by  Subject;
	 if a then response=eGFR;
     if b then response=Outcome;
	 N_Trt=2;
	run;
    /*=====================================
      Create final dataset results.sp_data   
      to contain the final choice of a knot
	  and truncated line function, Month_t
    ======================================*/   
	data results.SP_data;
	 set temp.SP_data;
	 by Subject;
	 knot=&knot;
	 Month_t = MAX(Month-knot, 0);
	run;
	data results.SP_data;
	 set results.SP_data;
	 if indicator=1 and missing(eGFR) then eGFR=0;
	run;

%mend Getdata_SP;

/*==========================================================
                    MACRO GetParam_SP
 This macro creates the necessary dataset containing 
 starting values for a SP model. The following are the macro 
 variable options
 Listing=    Defines if one wants all generated output listed
             For no generated output,  set Listing=close     
             For generated output,     set Listing=     
 SP_Model=1  SP covariates = TrtID 
             NOTE: SP model 1 is simply a model for eGFR 
             assuming dropout is at random and missing data
             are MAR. This assumes dropout is ignorable.   
 SP_Model=2  SP covariates = TrtID, b0i b1i b3i
             NOTE: SP model 2 is a non-ignorable dropout model
 SP_Model=3  SP covariates = TrtID, eGFRij 
             NOTE: SP model 3 is a non-ignorable dropout model
             where eGFRij is the unobserved eGFR measured  
             without error at start of PE interval  
 SP_Model=4  SP covariates = TrtID, b0i b1i b3i eGFRij 
             NOTE: SP model 4 is a non-ignorable dropout model
             which includes the covariates of SP models 2 & 3  
 The macro creates a permanent dataset results.SP_Parms
 that one can re-use for the given SP_Model  
==========================================================*/ 
%macro GetParam_SP(SP_Model=1, Listing=close);
	ods listing &listing;
	%let N_Trt=2;   /* Can change this if more than two treatment groups */ 
	ods output ConvergenceStatus=temp2.cs1  
               SolutionF=temp2.pe1  
               CovParms=temp2.cov1 
               InfoCrit=temp2.ic1; 
	proc mixed data=results.SP_data ic method=ML cl;
	 where indicator=0;
	 class Subject TrtID;
	 model eGFR  = TrtID Month*TrtID Month_t*TrtID / s noint;
	 random intercept Month Month_t / subject=Subject type=un ;
	run;

	data temp2.pe1_;
	 set temp2.pe1 temp2.cov1;
	 if Effect='TrtID' then do;
      %do i=1 %to &N_Trt;
		if TrtID=&i then Parameter="beta0&i"; 
      %end;
	 end;
	 if Effect='Month*TrtID' then do;
      %do i=1 %to &N_Trt; 
		if TrtID=&i then Parameter="beta1&i"; 
	  %end;
	 end;
	 if Effect='Month_t*TrtID' then do;
      %do i=1 %to &N_Trt; 
		if TrtID=&i then Parameter="beta2&i"; 
	  %end;
	 end;
	 if CovParm='UN(1,1)'  then Parameter='psi11';
	 if CovParm='UN(2,1)'  then Parameter='psi21';
	 if CovParm='UN(2,2)'  then Parameter='psi22';
	 if CovParm='UN(3,1)'  then Parameter='psi31';
	 if CovParm='UN(3,2)'  then Parameter='psi32';
	 if CovParm='UN(3,3)'  then Parameter='psi33';
	 if CovParm='Residual' then Parameter='sigma';
	run; 

	proc transpose data=temp2.pe1_ out= temp2.eGFR_pe_wide;
	 id Parameter;
	 var Estimate;
	run;

	data temp2.eGFR_pe_wide;
	 set temp2.eGFR_pe_wide;
	 drop _name_;
	run;
	data temp2.eGFR_pe_wide;
	 set temp2.eGFR_pe_wide;
	 do sigma=0.1 to 1 by .3, 2, 4, 6, 8, 10, 15, 20, 40, 80, &sigma;
      do theta=0 to 1.25 by .25, &theta;
	   do kappa=0;
	     output;
	   end;
	  end;
	 end;
	run;
	/* Include the initial parameter estimates from MACRO GetKnot */  
	data temp2.eGFR_pe_wide_all;
	 set temp2.eGFR_pe_wide temp2.initialparms_wide;
	run;

	/*== Printing all starting values - COMMENTED OUT ==*/
	/*===================================================
 	proc print data=temp2.eGFR_pe_wide_all;
 	 title "Initial Starting Values for eGFR model only";
 	run;
	====================================================*/

	/*====================================================
	 The following code computes the initial parameter 
  	 estimates for a proportional hazards PE survival model
	 using GENMOD. It creates a SAS dataset containing the 
  	 initial parameters representing the log hazard 
	 ratio for comparing the two treatment groups. These 
  	 estimates are ML estimates as obtained using GENMOD.  
	=====================================================*/  
	data results.SP_data;
	 set results.SP_data end=last;
	 if last then do;
      call symput("NIntervals",left(NIntervals)); 
	 end;
	run;
	ods output ParameterEstimates=temp2.ParmsSurvModel_PE;
	proc genmod data=results.SP_data;
	 where indicator=1;
	 class Interval_ID TrtID; 
	 model Outcome = Interval_ID TrtID / noint dist=Poisson 
	                        offset=Log_RiskTime type3; 
	run;  
                                                                    
	data temp2.Parms_PE;
	 set temp2.ParmsSurvModel_PE;
	 Level=Level1+0;
	 /*====================================================
	  eta_Trt and eta01-eta0k are parameters for the PE model
      component to all SP models. The parameter eta_Trt is the
	  log HR for TrtID while eta01-eta0k are the baseline 
      hazard rates of the PE model where k = NIntervals.  
 	 =====================================================*/  
	 if Parameter='TrtID' and Level=1 then Parameter="eta_Trt"; 	 
	 %do j=1 %to &NIntervals;  
	 if Parameter='Interval_ID' and Level=&j then Parameter="eta0&j"; 
	 %end;
	 if DF=0 then delete;
	run;
	data temp2.all_Parms_PE;
	 length Parameter $12.;
	 set temp2.Parms_PE;
	run;
	proc transpose data=temp2.all_Parms_pe out=temp2.Survival_pe_wide;
	 id Parameter;
	 var Estimate;
	run;

	data temp2.Survival_pe_wide;
	 set temp2.Survival_pe_wide;
	 drop _NAME_;
	run;

	data temp.SP_parms  ;
	 set temp2.eGFR_pe_wide_all ;
	 if _n_=1 then set temp2.Survival_pe_wide ;
	run;

	data temp.SP_parms  ;
	  set temp.SP_parms  ;
	   %if &SP_Model=2 %then %do;
	    eta_b0i=0;
        eta_b1i=0;  
        eta_b3i=0;  
       %end;
	   %if &SP_Model=3 %then %do;
	    eta_eGFRij=0;
       %end;
	   %if &SP_Model=4 %then %do;
	    eta_b0i=0;
        eta_b1i=0;  
        eta_b3i=0;  
	    eta_eGFRij=0;
       %end;
	run;

	data results.SP_Parms;
	 set temp.SP_Parms;
	run;

	proc sort data=results.SP_data;
	 by Study Studyname TrtID Subject Indicator Visit Month;
	run; 

	ods listing;
%mend GetParam_SP;

/*===========================================================================
                             MACRO NewEstimates
This MACRO constructs additional ESTIMATE statements which one can include 
within the MACRO Model as needed. Here we express the slopes in units of years
as opposed to months under a two-slope linear spline mixed-effects model.
============================================================================*/
%MACRO NewEstimates;
	 %let N_Trt=2;   /* Can change these if more than two treatment groups */ 
	 %let N_Trt_1=1; /* Can change these if more than two treatment groups */ 
	 %if %index(&SIMPLE, NO) %then %do;
 	 %do i=1 %to &N_Trt;
 	  estimate "beta1&i/yr" (beta1&i)*12;
 	  estimate "beta2&i/yr" (beta2&i)*12;
 	  estimate "beta3&i/yr" (beta1&i + beta2&i)*12;
 	  estimate "beta4&i at t=12 Months" (beta1&i + beta2&i) - beta2&i*(&knot)/12;
 	  estimate "beta4&i at t=24 Months" (beta1&i + beta2&i) - beta2&i*(&knot)/24;
 	  estimate "beta4&i at t=36 Months" (beta1&i + beta2&i) - beta2&i*(&knot)/36;
 	  estimate "beta4&i at t=48 Months" (beta1&i + beta2&i) - beta2&i*(&knot)/48;
 	  estimate "beta4&i/yr at t=12 Months" (beta1&i + beta2&i)*12 - beta2&i*(&knot)*12/12;
 	  estimate "beta4&i/yr at t=24 Months" (beta1&i + beta2&i)*12 - beta2&i*(&knot)*12/24;
 	  estimate "beta4&i/yr at t=36 Months" (beta1&i + beta2&i)*12 - beta2&i*(&knot)*12/36;
 	  estimate "beta4&i/yr at t=48 Months" (beta1&i + beta2&i)*12 - beta2&i*(&knot)*12/48;
 	 %end; 
 	 %do i=1 %to &N_Trt_1;
	  %let next=%eval(&i+1);
	  %do j=&next %to &N_Trt;
 	   estimate "beta4&i - beta4&j at t=12 Months" (beta1&i + beta2&i - beta2&i*(&knot)/12) - (beta1&j + beta2&j - beta2&j*(&knot)/12);
 	   estimate "beta4&i - beta4&j at t=24 Months" (beta1&i + beta2&i - beta2&i*(&knot)/24) - (beta1&j + beta2&j - beta2&j*(&knot)/24);
 	   estimate "beta4&i - beta4&j at t=36 Months" (beta1&i + beta2&i - beta2&i*(&knot)/36) - (beta1&j + beta2&j - beta2&j*(&knot)/36);
 	   estimate "beta4&i - beta4&j at t=48 Months" (beta1&i + beta2&i - beta2&i*(&knot)/48) - (beta1&j + beta2&j - beta2&j*(&knot)/48);
 	   estimate "beta4&i-beta4&j /yr at t=1 Years" ((beta1&i + beta2&i - beta2&i*(&knot)/12) - (beta1&j + beta2&j - beta2&j*(&knot)/12))*12;
 	   estimate "beta4&i-beta4&j /yr at t=2 Years" ((beta1&i + beta2&i - beta2&i*(&knot)/24) - (beta1&j + beta2&j - beta2&j*(&knot)/24))*12;
 	   estimate "beta4&i-beta4&j /yr at t=3 Years" ((beta1&i + beta2&i - beta2&i*(&knot)/36) - (beta1&j + beta2&j - beta2&j*(&knot)/36))*12;
 	   estimate "beta4&i-beta4&j /yr at t=4 Years" ((beta1&i + beta2&i - beta2&i*(&knot)/48) - (beta1&j + beta2&j - beta2&j*(&knot)/48))*12;
	  %end;
 	 %end; 
	 %end;

	 %if %index(&SIMPLE, YES) %then %do;
 	 %do i=1 %to &N_Trt;
 	  estimate "beta1&i/yr" (beta1&i)*12;
 	  estimate "beta2&i/yr" (beta2&i)*12;
 	 %end; 
	 %end;
%mend NewEstimates;


/*===========================================================================
                             MACRO Contrasts 
This MACRO constructs the appropriate CONTRAST statements for comparing the
Treatment cell mean regression parameters (intercept, acute slope, change
slope and chronic slope) under a two-slope linear spline mixed-effects model.
============================================================================*/
%MACRO Contrasts;
	 %if %index(&SIMPLE, NO) %then %do;
	  contrast "H0: No Trt LogHR Effect    "	    eta_Trt; 
	  contrast "H0: No Trt Intercept Effect    "	beta01 - beta02; 
	  contrast "H1: No Trt Acute Slope Effect  "  	beta11 - beta12; 
	  contrast "H2: No Trt Change Slope Effect "	beta21 - beta22; 
	  contrast "H3: No Trt Chronic Slope Effect"  	(beta11 + beta21) - (beta12 + beta22);
	  contrast "H4: No Total Slope Effect: 1 Yr" 	(beta11 + beta21 - beta21*(&knot)/12) - (beta12 + beta22 - beta22*(&knot)/12);
	  contrast "H4: No Total Slope Effect: 2 Yr" 	(beta11 + beta21 - beta21*(&knot)/24) - (beta12 + beta22 - beta22*(&knot)/24);
	  contrast "H4: No Total Slope Effect: 3 Yr" 	(beta11 + beta21 - beta21*(&knot)/36) - (beta12 + beta22 - beta22*(&knot)/36);
	  contrast "H4: No Total Slope Effect: 4 Yr" 	(beta11 + beta21 - beta21*(&knot)/48) - (beta12 + beta22 - beta22*(&knot)/48);
	 %end;
	 %if %index(&SIMPLE, YES) %then %do;
	  contrast "H0: No Trt LogHR Effect        "    eta_Trt; 
	  contrast "H0: No Trt Intercept Effect    "	beta01 - beta02; 
	  contrast "H1: No Trt Slope Effect        "  	beta11 - beta12; 
	 %end;
%mend Contrasts;

/*=======================================================================
   MACRO Results - This macro creates summary datasets based on results
                   from NLMIXED in conjunction with macro variable
                   options ROBUST= and SP_Model=. The created datasets 
                   and descriptions are stored in directory RESULTS  
                   (as created in MACRO SIM_Data) as follows: 

           CREATED DATASET                   RESULTS SUMMARIZED   
    RESULTS.cs_&ROBUST_&SP_Model           convergence status    
    RESULTS.ic_&ROBUST_&SP_Model           information criteria   
    RESULTS.pe_&ROBUST_&SP_Model           parameter estimates   
    RESULTS.est_&ROBUST_&SP_Model          additiona parameter estimates   
    RESULTS.contrast_&ROBUST_&SP_Model     contrast results   
    RESULTS.predict_&ROBUST_&SP_Model      predicted means   

   where the value of &ROBUST is YES or NO depending on the option one
   specifies for ROBUST= in MACRO Model and the value of &SP_Model is 1,
   2, 3, or 4 depending on the option one specifies for SP_Model= in 
   MACRO Model.

   This macro is called from within MACRO Model so that results are 
   stored if there is a successful convergence. If convergence is not
   successful because it failed to converge or it resulted in a Hessian
   matrix that is either non-positive definite or has one or more 
   negative eigenvalues resulting, one will need to re-run MACRO Model  
   again with OPTION GetParms=NO so that is uses same starting values 
   subject to changes made to POM= and PROP= and Nloptions= . 
========================================================================*/
%macro Results;
	data temp.SP_PE_cs0_&ROBUST;
	 set temp.SP_PE_cs0_&ROBUST;
	 Tech="&TECH";
	 SP_Model=&SP_Model;
	 POM="&POM";
	 PROP="&PROP";
	 Knot=&knot;
	 Robust="&ROBUST";
	 SIMPLE="&SIMPLE";
	run;
	data results.cs_&ROBUST._&SP_Model;
	 set temp.SP_PE_cs0_&ROBUST;
	run;

	data temp.SP_PE_ic0_&ROBUST;
	 set temp.SP_PE_ic0_&ROBUST;
	 Tech="&TECH";
	 SP_Model=&SP_Model;
	 POM="&POM";
	 PROP="&PROP";
	 Knot=&knot;
	 Robust="&ROBUST";
	 SIMPLE="&SIMPLE";
	run;
	data results.ic_&ROBUST._&SP_Model;
	 set temp.SP_PE_ic0_&ROBUST;
	run;

	data temp.SP_PE_pe0_&ROBUST;
	 set temp.SP_PE_pe0_&ROBUST;
	 Tech="&TECH";
	 SP_Model=&SP_Model;
	 POM="&POM";
	 PROP="&PROP";
	 Knot=&knot;
	 Robust="&ROBUST";
	 SIMPLE="&SIMPLE";
	run;
	data results.pe_&ROBUST._&SP_Model;
	 set temp.SP_PE_pe0_&ROBUST;
	run;

	data temp.SP_PE_est0_&ROBUST;
	 set temp.SP_PE_est0_&ROBUST;
	 Tech="&TECH";
	 SP_Model=&SP_Model;
	 POM="&POM";
	 PROP="&PROP";
	 Knot=&knot;
	 Robust="&ROBUST";
	 SIMPLE="&SIMPLE";
	run;
	data results.est_&ROBUST._&SP_Model;
	 set temp.SP_PE_est0_&ROBUST;
	run;

	data temp.SP_PE_contrast0_&ROBUST; 
	 set temp.SP_PE_contrast0_&ROBUST;
	 Tech="&TECH";
	 SP_Model=&SP_Model;
	 POM="&POM";
	 PROP="&PROP";
	 Knot=&knot;
	 Robust="&ROBUST";
	 SIMPLE="&SIMPLE";
	run;
	data results.contrast_&ROBUST._&SP_Model;
	 set temp.SP_PE_contrast0_&ROBUST;
	run;

	data temp.SP_PE_Omega0_&ROBUST; 
	 set temp.SP_PE_Omega0_&ROBUST;
	 Tech="&TECH";
	 SP_Model=&SP_Model;
	 POM="&POM";
	 PROP="&PROP";
	 Knot=&knot;
	 Robust="&ROBUST";
	 SIMPLE="&SIMPLE";
	run;
	data results.Omega_&ROBUST._&SP_Model;
	 set temp.SP_PE_Omega0_&ROBUST; 
	run;

	data temp.SP_PE_pred0_&ROBUST;
	 set temp.SP_PE_pred0_&ROBUST;
	 Tech="&TECH";
	 SP_Model=&SP_Model;
	 POM="&POM";
	 PROP="&PROP";
	 Knot=&knot;
	 Robust="&ROBUST";
	 SIMPLE="&SIMPLE";
	run;
	data results.pred_&ROBUST._&SP_Model;
	 set temp.SP_PE_pred0_&ROBUST;
	run;

	data end1;
	 endtime=datetime();
	 format endtime datetime.;
	run;
	data results.Runtime_SP_Model_&SP_Model;
	 merge start1 end1;
	 hours=(endtime/(60*60))-(starttime/(60*60));
	run;
	options nodate nonumber ps=60 ls=120;
	proc print data=results.cs_&ROBUST._&SP_Model;
	 title "Convergence status";
	run;
	proc print data=results.Runtime_SP_Model_&SP_Model;
	 title "Run time for NLMIXED to converge";
	run;
%mend Results;


/*=======================================================================
   MACRO Model - This macro runs a SP model with specified NLOPTIONS
                 as well as an option to conduct inference based on 
                 EMPIRICAL standard errors. To obtains ML estimates 
                 of the eGFR slopes assuming missing data are MAR 
                 one should choose SP Model = 1. The macro calls the 
                 macros: GetParam_SP, NewEstimates, Contrasts, Results 
                  
   MACRO OPTIONS:
  
   GetParms= YES specifies running MACRO GetParms for initial run of
                 a given SP Model.
           = NO  specifies to NOT run macro GetParms. This option should 
                 be used in cases where one is re-running the same basic 
                 model with possible changes to POM=, PROP=, and some of 
                 the options for NLMIXED  
                 For example, if the initial call to Model uses Tech=NRRIDG
                 and it failed to converge then one can re-run the same model
                 with Tech=DBLDOG to see if that works.  
        POM= SS  specifies use of conditional or SS mean eGFR for POM 
           = NO  specifies no POM structure = homogeneous errors 
       PROP= YES specifies modeling a treatment-dependent effect on 
                 the random slope effects yielding a heterogeneous 
                 between-subject covariance structure. Specifically, the
                 variance of the random intercept effect, b0i, is assumed  
                 to be the same for both treatment groups while the  
                 the variances and covariances of the two random slope 
                 effects, b1i and b2i, associated with the acute and 
                 change slopes for the treatment group are assumed to 
                 be proportional to the variances and covariances of 
                 the corresponding random slope effects for the control
                 group by a ratio factor of (1+kappa)**2. 
           = NO  specifies modeling a uniform treatment effect on all 
                 random effects yielding a common between-subject covariance 
                 structure between the two treatment groups.  
     SIMPLE= YES specifies using the simple LME model with a single slope
                 parameter per treatment group. This is achieved in the 
                 MACRO by dropping the change (delta) slope from the 
                 model (and PARMS dataset) and defining it to be a
                 constant equal to 0
           = NO  specifies using default linear spline mixed-effects model
   SP_MODEL= 1   specifies the SP covariates = TrtID (Primary Model)  
   SP_MODEL= 2   specifies the SP covariates = TrtID, b0i b1i b3i
   SP_MODEL= 3   specifies the SP covariates = TrtID, eGFRij
   SP_MODEL= 4   specifies the SP covariates = TrtID, b0i b1i b3i eGFRij
       TECH= NRRIDG (preferred NLMIXED 2nd-order optimization technique) 
           = DBLDOG (alternative 1st-order optimization technique)
     ROBUST= YES specifies using robust (i.e., empirical) standard errors
           = NO  specifies using default model-based standard errors
  NLoptions= Specifies other PROC NLMIXED options like QPOINTS=1 and 
             MAXITER=100, MAXFUNC=1000 etc. which can be useful when 
             one runs into convergence problems.
========================================================================*/
%macro Model(GetParms=YES, POM=SS, PROP=YES, SP_Model=1, TECH=NRRIDG, ROBUST=NO, 
             SIMPLE=NO, NLoptions=%str(maxiter=100 maxfunc=1000 qpoints=1)); 
	%let N_Trt=2;   /* Can change thie if more than two treatment groups */ 
	%let GetParms=%upcase(&GetParms); 
	%let Robust=%upcase(&Robust); 
	%let POM=%upcase(&POM); 
	%let PROP=%upcase(&PROP);
	%let SIMPLE=%upcase(&SIMPLE);
	%if %index(&GetParms, YES) %then %do; 
	 %GetParam_SP(SP_Model=&SP_Model);
	%end;
	%if %index(&Robust, YES) %then %do;
     %let EMPIRICAL=Empirical;
    %end;  
	%if %index(&Robust, NO) %then %do;
     %let EMPIRICAL=;
    %end; 
	data temp.SP_Parms;
	 set results.SP_Parms;  
	run;
 	%if %index(&POM, NO) %then %do;
	data temp.SP_parms; set temp.SP_parms; 
	 drop theta;
	run;
	%end;
	%if %index(&PROP, NO) %then %do;
	data temp.SP_parms; set temp.SP_parms; 
	 drop kappa;
	run;
	%end;
	%if %index(&SIMPLE, YES) %then %do;
	data temp.SP_parms; set temp.SP_parms; 
	 drop beta21 beta22 psi31 psi32 psi33 eta_b3i;
	run;
	%end;
	proc print data=temp.SP_parms;
	 title 'Grid of SP model parameter starting values'; 
 	run;

	proc datasets nolist;
	 delete start1 end1;
	run;
	quit;
	data start1;
	 starttime=datetime();
	 format starttime datetime.;
	run;

	proc sort data=results.SP_Data; 
	 by Study Studyname Subject Indicator Month t1; 
	run;
	ods output  Hessian= Hessian                           /* Hessian matrix */ 
                IterHistory=temp.SP_PE_iter0_&ROBUST
	            ConvergenceStatus=temp.SP_PE_cs0_&ROBUST
	            FitStatistics=temp.SP_PE_ic0_&ROBUST 
	            ParameterEstimates= temp.SP_PE_pe0_&ROBUST 
	            AdditionalEstimates=temp.SP_PE_est0_&ROBUST
                Contrasts= temp.SP_PE_contrast0_&ROBUST 
                CovMatParmEst=temp.SP_PE_Omega0_&ROBUST;
	ods exclude Hessian CovMatParmEst CovMatAddEst 
                CorrMatParmEst CorrMatAddEst;  ** To minimize output **;
	proc nlmixed data=results.SP_Data START TECH=&TECH 
                 &NLoptions &EMPIRICAL HESS ECORR COV NOSORTSUB ZNLP ;
	 by Study Studyname;
	 parms /data=temp.SP_parms best=1; 
	 /*========================================================
      The following is required in order to fit a simple     
	  linear mixed-effects model with a single slope per group
     ========================================================*/ 
	 %if %index(&SIMPLE, YES) %then %do;
	 beta21=0; 
	 beta22=0;
	 beta31=beta11;
	 beta32=beta12;
	 u2i=0; 
	 %end;

	 array _beta0_[2] beta01 - beta02;
	 array _beta1_[2] beta11 - beta12;
	 array _beta2_[2] beta21 - beta22;
	 array _beta3_[2] beta31 - beta32;
	 beta0=0;
	 beta1=0;
	 beta2=0;
	 /*========================================================
      The following allows for a proportional treatment effect
	  on the random slope effects u1i and u2i which yields a
      heterogeneous covariance structure in which the ratio of 
	  the variances and the ratio of the covariances of the  
	  random slope effects between the treatment and control 
	  groups is given by a common ratio factor of (1+kappa)**2 
	  as described by Equation 4 and Table 1 of the paper. 
     =========================================================*/ 
	 %if %index(&PROP, YES) %then %do;
	 b0i = u0i;
	 b1i = (1+kappa*(TrtID=2))*u1i;
	 b2i = (1+kappa*(TrtID=2))*u2i;
	 %end;
	 %else  %do;
	 b0i = u0i;
	 b1i = u1i;
	 b2i = u2i;
	 %end;
	 b3i = b1i+b2i;                            ** Random chronic slope effect; 
 

	 do k=1 to 2;                              ** We are only modeling studies with 2 treatment groups; 
	   beta0  = beta0  + _beta0_[k]*(TrtID=k); ** PA intercept as a linear function of Trt effects; 
	   beta1  = beta1  + _beta1_[k]*(TrtID=k); ** PA acute slope as a linear function of Trt effects;
	   beta2  = beta2  + _beta2_[k]*(TrtID=k); ** PA delta slope as a linear function of Trt effects;
	  _beta3_[k] = _beta1_[k] + _beta2_[k];    ** PA parameter describing PA chronic slope for a specific  Trt group;
	 end;
	 beta0i = beta0 + b0i;                     ** SS intercept as a linear function of Trt effects; 
	 beta1i = beta1 + b1i;                     ** SS acute slope as a linear function of Trt effects;
	 beta2i = beta2 + b2i;                     ** SS delta slope as a linear function of Trt effects;
	 beta3  = beta1 + beta2;                   ** PA chronic slope as a linear function of Trt effects;
	 beta3i = beta3 + b3i;                     ** SS chronic slope as a linear function of Trt effects; 

	 %if %index(&SIMPLE, YES) %then %do;
	 mu = beta0+beta1*Month;                   ** PA predicted mean response over time as a linear function of Trt;
	 mu_i = beta0i+beta1i*Month;               ** SS predicted mean response over time as a linear function of Trt;
     eGFRij = beta0i+beta1i*t1;                ** eGFR measured without error at beginning of each interval (i.e., at t1); 
	 %end;
	 %if %index(&SIMPLE, NO) %then %do;
	 mu = beta0+beta1*Month+beta2*Month_t;     ** PA predicted mean response over time as a linear function of Trt;
	 mu_i = beta0i+beta1i*Month+beta2i*Month_t;** SS predicted mean response over time as a linear function of Trt;
     eGFRij = beta0i+beta1i*t1+beta2i*(MAX(t1-knot, 0));
                                               ** eGFR measured without error at beginning of each interval (i.e., at t1); 
	 %end;
	 %if %index(&POM, SS) %then %do;
     var = (sigma/100)*(mu_i**2)**theta;       ** SS Intra-subject variance function with rescaled sigma;
     %end; 
     %if %index(&POM, NO) %then %do;
     var=sigma;                                ** NO Intra-subject POM structure - assumes homogeneous variability;
     %end;

	 /*==================================================
      ll_Y is the conditional log-likelihood of Y=eGFR 
      which is assumed to be normally distributed with   
      conditional mean mu_i and conditional variance     
      defined by the POM variance structure given by
 			var = (sigma)*(mu_i**2)**theta  
      Note that b0i, b1i and b2i are the random intercept
	  and random slope parameters.
	 ===================================================*/ 
	 ll_Y = (1-indicator)*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((eGFR - mu_i)**2)/(var) 
	                        - 0.5*log(var) );  ** The Gaussian log L function for modeling the 
							                      variable Y = eGFR conditional on random effects b;

	 /*==================================================
      The following code defines the log-likelihood of  
      T=time to dropout which is assumed to follow a    
      piecewise exponential (PE) survival model      
	 ===================================================*/ 
	 array _eta0_[&NIntervals] eta01 - eta0&NIntervals;
	 eta0 = 0;
	 do j=1 to NIntervals;
       eta0 = eta0 + _eta0_[j]*(Interval_ID=j); 
	 end;
	 eta1 = eta_Trt*(TrtID=2);                 ** eta_Trt is log HR for treatment group (TRC101) effect;  
	 %if &SP_Model=1 %then %do;
	 eta_i = eta0 + eta1;                      ** The interval log hazard rate per unit of time for SP Model 1;   
	 %end;

	 %if &SP_Model=2 %then %do;
	 %if %index(&SIMPLE, NO) %then %do;
 	 eta_i = eta0 + eta1 + eta_b0i*b0i + eta_b1i*b1i + eta_b3i*b3i;
					                           ** The interval log hazard rate per unit of time for SP Model 2.
						                          Note the SP covariates b1i and b3i have different variances when
						                          we assume a proportional effect on the randon slope variances; 
	 %end;
	 %if %index(&SIMPLE, YES) %then %do;
 	 eta_i = eta0 + eta1 + eta_b0i*b0i + eta_b1i*b1i;
					                           ** The interval log hazard rate per unit of time for SP Model 2.
						                          Note the SP covariates b1i have different variances when
						                          we assume a proportional effect on the randon slope variances; 
	 %end;
	 %end;

	 %if &SP_Model=3 %then %do;
     eta_i = eta0 + eta1 + eta_eGFRij*eGFRij;  ** The interval log hazard rate per unit of time for SP Model 3;    	                                          
	 %end;

	 %if &SP_Model=4 %then %do;
 	 %if %index(&SIMPLE, NO) %then %do;
	 eta_i = eta0 + eta1 + eta_b0i*b0i + eta_b1i*b1i + eta_b3i*b3i + eta_eGFRij*eGFRij;
					                           ** The interval log hazard rate per unit of time for SP Model 4.
						                          Note the SP covariates b1i and b3i have different variances when
						                          we assume a proportional effect on the randon slope variances; 
	 %end;
 	 %if %index(&SIMPLE, YES) %then %do;
	 eta_i = eta0 + eta1 + eta_b0i*b0i + eta_b1i*b1i + eta_eGFRij*eGFRij;
					                           ** The interval log hazard rate per unit of time for SP Model 4.
						                          Note the SP covariates b1i have different variances when
						                          we assume a proportional effect on the randon slope variances; 
	 %end;
	 %end;

	 %if &SP_Model=5 %then %do;
 	 %if %index(&SIMPLE, NO) %then %do;
 	 eta_i = eta0 + eta1 + eta_b0i*b0i + eta_b1i*b1i + eta_b2i*b2i;
					                           ** The interval log hazard rate per unit of time for SP Model 5.
						                          Note the SP covariates b1i and b2i have different variances when
						                          we assume a proportional effect on the randon slope variances; 
	 %end;
 	 %if %index(&SIMPLE, YES) %then %do;
 	 eta_i = eta0 + eta1 + eta_b0i*b0i + eta_b1i*b1i;
					                           ** The interval log hazard rate per unit of time for SP Model 5.
						                          Note the SP covariates b1i have different variances when
						                          we assume a proportional effect on the randon slope variances; 
	 %end;
	 %end;

	 lambda_i = exp(eta_i);                    ** The interval hazard rate per unit of time for the PE model; 
	 Hazard_i=lambda_i*RiskTime;               ** The interval hazard rate per months at risk for the PE model; 
	 /*==================================================
      ll_T is the conditional log-likelihood of T. 
      Here T=EventTime is distributed across intervals   
      using the variable RiskTime which is defined as the
      amount of time at risk within each interval and 
	  Outcome is an indicator of whether the event occured.   
      b0i, b1i and b2i serve as time-independent latent 
	  random effect covariates while eGFRij serves as a 
	  time-dependent latent random effect covariate
	 ===================================================*/ 
	 ll_T = indicator*( Outcome*(eta_i) - 
                        lambda_i*RiskTime );   ** The Piecewise Exponential log L function for modeling the 
						                          variable T = EventTime= time to dropout conditional on 
						                          a set of random effects b fopr functions f(b) of random effects;

     ll = ll_Y + ll_T;                         ** The SP model log-likelihood function for (Y|b, T|b);


	 model response ~ general(ll);             ** response = eGFR for indicator=0 and EventTime*(Outcome) for indicator=1; 

 	 %if %index(&SIMPLE, NO) %then %do;
	 random u0i u1i u2i ~ Normal( [0,0,0], 
                                  [psi11,
                                   psi21, psi22,  
                                   psi31, psi32, psi33] ) subject=Subject;
	 %end;

 	 %if %index(&SIMPLE, YES) %then %do;
	 random u0i u1i ~ Normal( [0,0], 
                              [psi11,
                               psi21, psi22] ) subject=Subject;
	 %end;

	%if %index(&SIMPLE, NO) %then %do;
	 estimate "beta31" beta11 + beta21;              ** chronic slope control group in mL/min/1.73m2/month;
	 estimate "beta32" beta12 + beta22;              ** chronic slope treated group in mL/min/1.73m2/month; 
	 estimate "beta02-beta01" (beta02-beta01);       ** intercept differences expressed in mL/min/1.73m2;
	 estimate "beta12-beta11" (beta12-beta11);       ** acute slope difference expressed in mL/min/1.73m2/month;
	 estimate "beta22-beta21" (beta22-beta21);       ** delta slope difference expressed in mL/min/1.73m2/month;
	 estimate "beta32-beta31" (beta12+beta22)- (beta11+beta21);
                                                     ** chronic slope difference expressed in mL/min/1.73m2/month;
	 estimate "beta12-beta11 /yr" (beta12-beta11)*12;** acute slope difference expressed in mL/min/1.73m2/year;
	 estimate "beta22-beta21 /yr" (beta22-beta21)*12;** delta slope difference expressed in mL/min/1.73m2/year;
	 estimate "beta32-beta31 /yr" (beta12+beta22)*12 - (beta11+beta21)*12;
                                                     ** chronic slope difference expressed in mL/min/1.73m2/year;
	 %if &SP_Model=1 %then %do;
	 estimate "LogHR(TrtID=2:TrtID=1)" eta_Trt;      ** equivalent to logHR which we then exponentiate the conf. limits;
	 %end;
	 %if &SP_Model=2 %then %do;
	 estimate "LogHR(TrtID=2:TrtID=1)" eta_Trt;      ** equivalent to logHR which we then exponentiate the conf. limits;
	 estimate "LogHR(b0i)"  eta_b0i;  
	 estimate "LogHR(b1i)"  eta_b1i;                 ** log HR per month;
	 estimate "LogHR(b3i)"  eta_b3i;                 ** log HR per month;
	 %end;
	 %if &SP_Model=3 %then %do;
	 estimate "LogHR(TrtID=2:TrtID=1)" eta_Trt;      ** equivalent to logHR which we then exponentiate the conf. limits;
	 estimate "LogHR(eGFR)"  eta_eGFRij;             ** log HR per 1 mL/min/1.73m2 change in eGFR; 
	 %end;
	 %if &SP_Model=4 %then %do;
	 estimate "LogHR(TrtID=2:TrtID=1)" eta_Trt;      ** equivalent to logHR which we then exponentiate the conf. limits;
 	 estimate "LogHR(b0i)"   eta_b0i;  
	 estimate "LogHR(b1i)"   eta_b1i;                ** log HR per month;
	 estimate "LogHR(b3i)"   eta_b3i;                ** log HR per month;
	 estimate "LogHR(eGFR)"  eta_eGFRij;             ** log HR per 1 mL/min/1.73m2 change in eGFR; 
	 %end;
	 %if &SP_Model=5 %then %do;
	 estimate "LogHR(TrtID=2:TrtID=1)" eta_Trt;      ** equivalent to logHR which we then exponentiate the conf. limits;
	 estimate "LogHR(b0i)"  eta_b0i;  
	 estimate "LogHR(b1i)"  eta_b1i;                 ** log HR per month;
	 estimate "LogHR(b2i)"  eta_b2i;                 ** log HR per month;
	 %end;
	 %if %index(&PROP, YES) %then %do;
	 estimate "kappa" kappa;
	 %end;
	%end;

	%NewEstimates;
	%Contrasts;

	id Study Studyname Trt Treat1 Treat2 u0i u1i u2i b0i b1i b2i beta0: beta1: beta2: beta3: psi: 
       sigma mu mu_i eta: lambda_i Hazard_i
	 %if %index(&POM, SS)   %then %do; theta	%end;
	 %if %index(&PROP, YES) %then %do; kappa	%end;
	;
 	predict mu_i out=temp.SP_PE_pred0_&ROBUST DER;
	run; 

	data matrix;
	 set Hessian;
	 drop Study Studyname row Parameter;
	run;

	proc iml;
	 use work.matrix;
	 read all var _ALL_ into H;
	 close matrix;

	 /* Determine problems with Hessian matrix so that convergence status can be updataed to reflect this */
	 DetH = det(H);                ** If 0 then Hessian is not p.d. or is singular; 
	 EigenH=eigval(H);             ** If a negative eigenvalue then second-order optimality is violated ;
	 MinEigenH = min(eigval(H));   ** One or more eigenvalue are negative, second-order optimality is violated ;  
	 Status_H=0;                    
	 pdH = 0;                      ** Hessian is p.d. (i.e., non-singular with DET(H) not equal to 0);
	 negH = 0;                     ** Hessian does not have any negative eigenvalues;
     if DetH=0 then pdH=1;         ** Hessian is non p.d. (DET(H)=0);  
     if MinEigenH<0 then negH=1;   ** Hessian has 1 or more negative eigenvalues; 
	 Status_H=max(pdH, negH);      ** Status_H =0 => Hessian is OK, else Hessian is non p.d. or has eigenvalues<0;
	*print DetH EigenH MinEigenH pdH negH Status_H;
	 HessOut = DetH||pdH||MinEigenH||negH||Status_H;
 	*print HessOut;
	 create HessData from HessOut;
     append from HessOut;
	 close HessData; 
	 /* End of Check on Hessian */

	 /* Determine model-based standard errors when EMPIRICAL option is specified */
	 var0=vecdiag(inv(H));
	 var0=(var0+abs(var0))/2;  ** Replace negative variance with 0, this is just to allow se0 below to be 
	                              calculated and eventually the 0 se will be set as missing in the output dataset;
	 se0=sqrt(var0);
	 create se_model from se0;
	 append from se0;
	 close se_model;
	/* End of model-based standard errors */
	quit;

	/* Merge Hessian checks with convergence status in dataset temp.SP_PE_cs0 */
	data HessData;
	 set HessData;
	 rename col1=DetH col2=pdH col3=MinEigenH col4=negH col5=Status_H;
	run;
	data temp.SP_PE_cs0_&ROBUST;
	 set temp.SP_PE_cs0_&ROBUST;
	 if _n_=1 then set HessData;
	run;

	data se_model;
	 set se_model;
	 rename col1=SE_Model_Based;
	run;
	data se_model;
	 set se_model;
	 if se_model_based=0 then se_model_based=.;  ** The 0 SE is set to be missing consistent with the behavior of SAS;
	run;
	%if %index(&Empirical, EMPIRICAL) %then %do;
	data temp.SP_PE_pe0_&ROBUST;
	 merge  temp.SP_PE_pe0_&ROBUST se_model;
	run;
	data temp.SP_PE_pe0_&ROBUST;
	 set temp.SP_PE_pe0_&ROBUST;
	 rename StandardError=SE_Empirical;
	run;
	%end;

	data temp.SP_PE_iter0_&ROBUST;
	 set temp.SP_PE_iter0_&ROBUST end=last;
	 if last; 
	run;
	data temp.SP_PE_cs0_&ROBUST;
	 merge temp.SP_PE_cs0_&ROBUST temp.SP_PE_iter0_&ROBUST;
	 if Reason='NOTE: XCONV convergence criterion satisfied.' and Iter=1 then Status=1;
	 if Status_H=0 then Hessian='Hessian is p.d. with no issues            ';
	 if Status_H=1 then Hessian='Hessian is not p.d. or has eigenvalue(s)<0';
	run;
	data temp.SP_PE_cs0_&ROBUST;
	 set temp.SP_PE_cs0_&ROBUST;
	 ReRun="NO ";
	 if Status=1 or Status_H=1 then Rerun="YES";
	run;
	data temp.SP_PE_cs0_&ROBUST;
	 set temp.SP_PE_cs0_&ROBUST;
	 call symput('ReRun',left(ReRun)); 
	run;
	%Results;
%mend Model;




/*====================================================
       START OF RUNNING CODE FOR A GIVEN STUDY
======================================================
 Begin running code for a specific study identified by 
 a study number. 

 For the Statistics in Medicine paper, the MDRD-B
 study corresponding to Study=99 is used to illustrate 
 the code needed to fit SP models 1 and 2 summarized 
 in the paper. 

 The following call to MACRO SIM_Data creates the SAS
 dataset SIM.Study99 based on MDRD-B(BP) data using the  
 MDRD-B dataset available from Vonesh author webpage.
 
 All subsequent created datasets containing results are 
 stored in the sub-directory MDRD_B
 of the results directory that is automatically created. 
=======================================================

=====================================================*/
%SIM_Data(study=99, results=MDRD_B);

/* Clear all datasets in defined temporary directories */
%ClearTempDirectories;

proc print data=SIM.study99(obs=10);
run;

/*================================================
  Create a temporary version of the closed dataset
  SIM.Study99 which contains the variable _Month_ 
  which is rounded values of variable Month so that
  one can plot data at discrete monthly values.

  For the IDNT study, we added additional code not 
  shown here to select values of _Month_ that 
  coincide with the planned visits at the following
  months: 0, 3, 6, 12, 18, 24, 30, 36, 48 and 54.
 
  For the MDRD-B study, the planned visits will
  correspond to months 0, 2, 4, 8, 12 and every 4 
  months thereafter to study completion. 
=================================================*/
data temp.study;
 set SIM.study99;
 if Month=0 then _Month_ = 0;
 if 0<Month<.5 then _Month_ = Ceil(Month);         
 if Month>=.5 then _Month_ = round(Month, 1); 
run;

proc means data=temp.study nway n sum mean std min max maxdec=2;
 where month=0;
 class TrtID;
 var eGFR0 ev_dx fu_dx;
 title 'A description of baseline eGFR values, events and event times';
run;

options mprint symbolgen;

/*========================================
 The following call to MACROS GetKnot and
 GetData_SP need only be called one time 
 unless one wishes to change the value
 of knot. NOTE that one will now get the 
 same results for the MDRD-B study if one 
 specifies %GetKnot(FIXED_KNOT=6) rather
 than let %GetKnot determine that the best
 knot occurs at month 6. 
========================================*/
%GetKnot;
%Getdata_SP;
%put knot= &knot;
proc print data=results.aic_knot_fit;
 title 'AIC of best knot fit'; 
run; 
proc print data=results.SP_Data(obs=200);
 var Study Studyname TrtID Subject knot Visit Month eGFR outcome response t1 t2 risktime Indicator ;
 title 'Partial printout of SP dataset to be analyzed'; 
run;
title;

/*================================================================
 The following calls to MACRO Model runs sensitivity analyses for 
 the eGFR slope analysis under different non-ignorable dropout 
 mechanisms as specified by SP models 2, 3 and 4 using model-based 
 standard errors. Here we fit only SP models 1 and 2 for the MDRD-B
 study as summarized in the paper but one can run SP models 3 and 4 
 as well (they are commented out below).
 NOTE: Once a model has been run using the set options, it should  
       be commented out so as to not run it again.
=================================================================*/
 %Model(GetParms=YES, POM=SS, PROP=YES, SP_Model=1, TECH=NRRIDG, ROBUST=NO, 
       Nloptions=%str(maxiter=100 maxfunc=1000 qpoints=1));  ** Model succeeded; 

 %Model(GetParms=YES, POM=SS, PROP=YES, SP_Model=2, TECH=NRRIDG, ROBUST=NO, 
       Nloptions=%str(maxiter=100 maxfunc=1000 qpoints=1));  ** Model succeeded; 

*%Model(GetParms=YES, POM=SS, PROP=YES, SP_Model=3, TECH=NRRIDG, ROBUST=NO, 
       Nloptions=%str(maxiter=100 maxfunc=1000 qpoints=1));  ** Model succeeded;

*%Model(GetParms=YES, POM=SS, PROP=YES, SP_Model=4, TECH=NRRIDG, ROBUST=NO, 
       Nloptions=%str(maxiter=100 maxfunc=1000 qpoints=1));  ** Model succeeded;
run;


/*========================================
 Start of program that summarizes results
 for a given study via summary datasets
========================================*/
libname summary "&SIM_Directory.\SIM_Out\MDRD_B";
run;


/*========================================
            MACRO HR_results
 This macro takes additional estimates   
 from NLMIXED output and creates HR output 
 datasets with estimated HR estimates and 
 corresponding 95% confidene intervals.
========================================*/
%macro HR_results(Robust=, SP_Model=);
	data HR;
	 set summary.est_&robust._&SP_Model;
	 if Label in ('LogHR(TrtID=2:TrtID=1)' 'LogHR(eGFR)' 'LogHR(b0i)' 'LogHR(b1i)' 'LogHR(b2i)' 'LogHR(b3i)' );
	 if Label in ( 'LogHR(b1i)' 'LogHR(b2i)' 'LogHR(b3i)') then do; 
	  Unit='1 mL/min/1.73m2/year';
	  HR=exp(Estimate/12);
	  LowerHR=exp(Lower/12);
	  UpperHR=exp(Upper/12);
	  if Label in ( 'LogHR(b1i)' ) then 
      Comparison = 'HR(b1i) per 1 mL/min/1.73m2/year'; 
	  if Label in ( 'LogHR(b2i)' ) then 
      Comparison = 'HR(b2i) per 1 mL/min/1.73m2/year'; 
	  if Label in ( 'LogHR(b3i)' ) then 
      Comparison = 'HR(b3i) per 1 mL/min/1.73m2/year'; 
	 end;
	 if Label in ('LogHR(eGFR)' 'LogHR(b0i)') then do; 
	  Unit='1 mL/min/1.73m2     ';
	  HR=exp(Estimate);
	  LowerHR=exp(Lower);
	  UpperHR=exp(Upper);
	  if Label in ( 'LogHR(eGFR)' ) then 
      Comparison = 'HR(eGFR) per 1 mL/min/1.73m2    '; 
	  if Label in ( 'LogHR(b0i)' ) then 
      Comparison = 'HR(b0i) per 1 mL/min/1.73m2     '; 
	 end;
	 if Label in ('LogHR(TrtID=2:TrtID=1)') then do;  
      Comparison = 'HR(Treated:Control)             ';
      Unit='Treated vs Control  ';
	  HR=exp(Estimate);
	  LowerHR=exp(Lower);
	  UpperHR=exp(Upper);
	 end;
	run;

	data summary.HR_&robust._&SP_Model;
	 set HR;
	run;
	proc print data=summary.HR_&robust._&SP_Model;
	run;
%mend HR_Results;
%HR_results(Robust=no, SP_Model=1);
%HR_results(Robust=no, SP_Model=2);

/*========================================
         MACRO SummaryResults
 This macro takes all created output results
 from NLMIXED and creats a summary across  
 all SP models run using the MODEL options. 
 Below we only collect summary results for
 SP models 1 and 2 based on model-based 
 standard errors as specified by the 
 macro variable option ROBUST=
 Key:
   ROBUST= YES (get output for ROBUST=YES)
   ROBUST= NO  (get output for ROBUST=NO )
========================================*/
%macro SummaryResults(robust=) ;
	data summary.cs_&robust._all;
	 set summary.cs_&robust._1 summary.cs_&robust._2;
	run;
	data summary.ic_&robust._all;
	 set summary.ic_&robust._1 summary.ic_&robust._2;
	run;
	data summary.pe_&robust._all;
	 set summary.pe_&robust._1 summary.pe_&robust._2;
	run;
	data summary.contrast_&robust._all;
	 set summary.contrast_&robust._1 summary.contrast_&robust._2;
	run;
	data summary.est_&robust._all;
	 set summary.est_&robust._1 summary.est_&robust._2;
	run;
	data summary.HR_&robust._all;
	 set summary.HR_&robust._1 summary.HR_&robust._2;
	run;

%mend SummaryResults;
%SummaryResults(robust=no);

proc print data=summary.cs_no_all;
 var Study Studyname SP_Model Status Reason DetH pdH MinEigenH Hessian Tech POM PROP Knot Robust Simple;
 title "Table 1: Convergence status from NLMIXED";
run;
proc print data=summary.ic_no_all;
 format Value 9.3;
 title "Table 2: Information criteria from NLMIXED";
run;
proc print data=summary.pe_no_all;
 var Study Studyname SP_Model Parameter Estimate StandardError DF tValue Probt Lower Upper POM PROP Knot Robust Simple;
 title "Table 3: Parameter estimates from NLMIXED";
run;
proc print data=summary.contrast_no_all;
 title "Table 4: Contrast tests from NLMIXED";
run;
proc print data=summary.est_no_all;
 var Study Studyname SP_Model Label Estimate StandardError Probt Lower Upper POM PROP Knot Robust Simple;
 title "Table 5: Additional parameter estimates from NLMIXED";
run;
proc print data=summary.HR_no_all;
 var Study Studyname SP_Model Label Estimate StandardError Probt Comparison HR LowerHR UpperHR POM PROP Knot Robust Simple;
 title "Table 6: Hazard ratio estimates from NLMIXED";
run;






