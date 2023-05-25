/*==========================================================================================================
-EFV modified the code by allowing for Power-of-X model with %let POM=POX. 
 When one specifies the option _HESS_=YES under macro %InitialModelOptions the macro %DoAll
 will cycle up through 8 possible joint models depending on the convergence status of 
 the hierarchy of model options as specified within the macro %InitialModelOptions. The 
 hierarchy of model options as specified by 

 %InitialModelOptions(_POM_=SS,_ACR_=YES,_CE_=YES,_Prop_=YES,_BOUNDS_=YES,_SP_threshold=15,_HESS_=YES);

 are as follows where SP stands for use of a SP model for informative censoring if there
 are 15 censoring events or more (with 15 being the default but one can change its value):

		eGFR Model 1: POM = SS 
		              Proportional = YES (Kappa estimated)
		              SP  = YES if >=15 ESRD/Deaths 
		              SP  = NO  if <15 ESRD/Deaths  
		eGFR Model 2: POM = SS 
		              Proportional = NO (Kappa = 0)
		              SP  = YES if >=15 ESRD/Deaths 
		              SP  = NO  if <15 ESRD/Deaths  
		eGFR Model 3: POM = POX (Power-of-X), 
		              Proportional = YES (Kappa estimated)
		              SP  = YES if >=15 ESRD/Deaths 
		              SP  = NO  if <15 ESRD/Deaths  
		eGFR Model 4: POM = POX, (Power-of-X) 
		              Proportional = NO (Kappa = 0)
		              SP  = YES if >=15 ESRD/Deaths 
		              SP  = NO  if <15 ESRD/Deaths  
		eGFR Model 5: POM = NO, 
		              Proportional = YES (Kappa estimated)
		              SP  = YES if >=15 ESRD/Deaths 
		              SP  = NO  if <15 ESRD/Deaths  
		eGFR Model 6: POM = NO, 
		              Proportional = NO (Kappa = 0)
		              SP  = YES if >=15 ESRD/Deaths 
		              SP  = NO  if <15 ESRD/Deaths  
		eGFR Model 7: POM = NO, 
		              Proportional = NO (Kappa = 0)
		              SP  = NO  (SP component is dropped)     
		eGFR Model 8: POM = NO, 
		              Proportional = NO (Kappa = 0)
		              SP  = NO  (SP component is dropped)
		              PSI21 = NO (correlation(b1i b2i)=0)

 One can shut this cycling of models off by specifying _HESS_=NO in which case it will 
 run based on whatever specifications you give to each of the options.  
 Below are descriptions of the various MACROS called by the overall program.
==========================================================================================================*/


/*==================================================================
                  MACRO InitialModelOptions   

The following macro just initializes the global macro variables 
 _POM_=SS;            ** Order of POM option:      SS,PA,NO **
 _ACR_=YES;           ** Order of ACR option:      YES, NO  **
 _CE_ =YES;           ** Order of CE option:       YES, NO  **
 _Prop_=YES;          ** Order of _PROP_ option:   YES, NO  **                      
 _BOUNDS_=YES;        ** Order of _BOUNDS_ option: YES, NO  **
                      ** YES = set Bounds kappa>-1 on kappa **
                      ** NO  = no Bounds statement on kappa **
 _SP_threshold=15;    ** Sets SP event threshold at 15      **
 _PSI21_=YES;         ** Order of PSI21 option:    YES, NO  **
 _HESS_=YES;          ** Order of HESS option:    YES, NO
                         This checks Hessian matrix in order to run 
                         alternative models if convergence or 
                         Hessian fails (non p.d. or neg eigenvalues)
 _bGFR_=YES;          ** Allows modeling mean baseline eGFR (intercept)
 _Log_ACR_=YES;       ** Allows modeling mean Log ACR (intercept only) 
 _QUAD_=NO;           ** Order of QUAD option:     NO, YES  **    
 _TRUNC_=NO;          ** Order of TRUNC option:    NO, YES  **    
 _TRUNCATE_=27;       ** Sets a value for the truncation period. This
                         macro variable is ignored if _TRUNC_ = NO
*******************************************************************
     The three options QUAD, TRUNC, TRUNCATE are new as they allow  
     for a quadratic term (QUAD=YES)) in the chronic phase and for  
     a truncated analysis (TRUNC=YES) with (TRUNCATED=##) with the 
     default follow-up time set at 36 months or 3 months after the 
     default knot = 3 as defined in the algorithm 
*******************************************************************
   
******************************************************************* 
     The following two options are now listed in the algorithm  
 _bGFR_=YES;          ** Order of _bGFR_ option: YES, NO **
 _Log_ACR_=YES;       ** Order of _Log_ACR_ option: YES, NO **
*******************************************************************

==================================================================*/
%macro InitialModelOptions(_POM_=SS, _ACR_=YES, _CE_=YES, _Prop_=YES, _BOUNDS_=YES, 
                           _SP_threshold=15, _PSI21_=YES, _HESS_=YES, _bGFR_=YES, 
                           _Log_ACR_=YES, _QUAD_=NO, _TRUNC_=NO, _TRUNCATE_=27 );
 %let POM=%upcase(&_POM_);
 %let ACR=%upcase(&_ACR_);
 %let CE =%upcase(&_CE_);
 %let Proportional=%upcase(&_Prop_);
 %if %index(&Proportional, NO) %then %let &_BOUNDS_=NO);
 %let BOUNDS=%upcase(&_BOUNDS_);
 %let SP_Threshold=&_SP_threshold;
 %let PSI21=%upcase(&_PSI21_);
 %let HESS=%upcase(&_HESS_);
 %let bGFR=%upcase(&_bGFR_);
 %let Log_ACR=%upcase(&_Log_ACR_);
 %let QUAD=%upcase(&_QUAD_);
 %if %index(&QUAD, YES) %then %let &_TRUNC_=NO;
 %let TRUNC=%upcase(&_TRUNC_); 
 %let TRUNCATE=&_TRUNCATE_; 
%mend;

/** HT added macro zInitialModelOptions on 2/13/23 **/
%macro zInitialModelOptions(_POM_=SS, _ACR_=YES, _CE_=YES, _Prop_=YES, _BOUNDS_=YES, 
                           _SP_threshold=15, _PSI21_=YES, _HESS_=YES, _bGFR_=YES, 
                           _Log_ACR_=YES,_Acute_GFR_=YES, _QUAD_=NO, _TRUNC_=NO, _TRUNCATE_=27 );
 %let POM=%upcase(&_POM_);
 %let ACR=%upcase(&_ACR_);
 %let CE =%upcase(&_CE_);
 %let Proportional=%upcase(&_Prop_);
 %if %index(&Proportional, NO) %then %let &_BOUNDS_=NO);
 %let BOUNDS=%upcase(&_BOUNDS_);
 %let SP_Threshold=&_SP_threshold;
 %let PSI21=%upcase(&_PSI21_);
 %let HESS=%upcase(&_HESS_);
 %let bGFR=%upcase(&_bGFR_);
 %let Log_ACR=%upcase(&_Log_ACR_);
 %let Acute_GFR=%upcase(&_Acute_GFR_);
 %let QUAD=%upcase(&_QUAD_);
 %if %index(&QUAD, YES) %then %let &_TRUNC_=NO;
 %let TRUNC=%upcase(&_TRUNC_); 
 %let TRUNCATE=&_TRUNCATE_; 
%mend;



/*==================================================================
                         MACRO Truncate  

The following macro modifies dataset STUDIES with truncated data so
that one can truncate at 36, 24 or 18 months to see what impact 
a shorter-term study could have had on parameter estimates and 
inference compared to a longer study. This macro is called right 
right before running the macro program 
       TRUNC=      -defines whether we use a truncated dataset in
                    which eGFR follow-up times are truncated or not
                    Valid values are: 
                       TRUNC=YES (use truncated data)
                          or
                       TRUNC=NO (use original data)
                    The default value is TRUNC=NO  
    TRUNCATE=      -defines the truncation period. All follow-up
                     data after TRUNCATE will be deleted and the
                     clinical events will be censored at TRUNCATE
                     if they occur after the value of TRUNCATE   
                     Valid values are:
                      TRUNCATE=18, 24 and 36 
                     with eGFR followup truncated at TRUNCATE value.
                     If &TRUNC = NO then TRUNCATE is set to missing.
                     The default value is TRUNCATE=36 
IMPORATNT NOTE:      If the macro variable option QUAD=YES then 
                     the value of TRUNC=NO as the truncation period
                     is likely too short to capture nonlinearity. 
                     Likewise if the macro variable TRUNC=YES then
                     the value of QUAD=NO for same reason.  
----------------------------------------------------------------*/
%macro Truncate;
	%if %index(&TRUNC, YES) %then %do;
	data temp.study;
	 set temp.study;
	 b_CKDegfr_Indiv = b_CKDegfr_Mean + b_CKDegfr;  ** = bCKDegfr is database **;
	 Truncate=&TRUNCATE;
	 /* For truncated data at truncate months */
	 if Month>Truncate then delete;
	 if fu_dx>Truncate then do;
	  fu_dx=Truncate;
	  ev_dx=0;
	 end;
	run;
	%end;
	%else %if %index(&TRUNC, NO) %then %do;
	data temp.study;
	 set temp.study;
	 b_CKDegfr_Indiv = b_CKDegfr_Mean + b_CKDegfr;
	run;
	%end;
%mend;

/*------------------------------------------------------- 
 This macro checks whether we have necessary number of 
 clinical events for all 9 event types for a given study
-------------------------------------------------------*/ 
%macro Check_CE;
	proc means data=temp.study sum nway noprint;
	 where visit=1;
	 class TrtID;
	 var ev1-ev9;
	 output out=temp.Check_CE sum=c1-c9;  
	run;
	proc transpose data=temp.Check_CE out=temp.Check_CE_All prefix=sum;
	 id TrtID;
	 var c1-c9;
	run;
	data temp.Check_CE_All;
	 set temp.Check_CE_All;
	 sum=sum1+sum2;
	 CE="NO ";
	 if sum>9 and sum1>1 and sum2>1 then CE="YES";
	run;
	proc sort data=temp.Check_CE_All;
	 by CE;
	run;
	data temp.Check_CE_All; 
	 set temp.Check_CE_All end=last;
	 by CE;
	 if last then do;
	  call symput('CE',left(CE)); 
	 end;
	run;
%mend;


/*---------------------------------------------------------------------------- 
 This macro counts event&EventID_C, if the event count is less than 10, assign
 a value of NO to macro variable include&EventID_C, otherwise assign YES
----------------------------------------------------------------------------*/ 
%macro CountEvent(EventID_C=1 );
	proc tabulate data=temp.study out=temp.nnn_ev&EventID_C;
	class TrtID;
	var ev&EventID_C;
	table TrtID, ev&EventID_C*sum;
	where visit=1;
	run;
	data temp.nnn_ev&EventID_C;
	set temp.nnn_ev&EventID_C;
	rename ev&EventID_C._Sum=count;
	drop _TYPE_--_TABLE_;
	run;
	proc transpose data=temp.nnn_ev&EventID_C out=temp.nnn_ev&EventID_C prefix=c;
		 id TrtID;
		 var count;
		run;
	data temp.nnn_ev&EventID_C;
	set temp.nnn_ev&EventID_C;
	c=c1+c2;
*	if c>5 and c1>0 and c2>0 then include&EventID_C ="YES"; ** OLD CODE;
	if c>9 and c1>1 and c2>1 then include&EventID_C ="YES"; ** NEW CODE;
	else include&EventID_C ="NO";
	call symput("include&EventID_C",left(include&EventID_C)); 
	run;
	%put include&EventID_C=&&include&EventID_C;
%mend;
*CountEvent(EventID_C=6 );


/*------------------------------------------------------------  
 This macro generates the summary statistics needed to find  
 out interval number and also generate the interval number. 
------------------------------------------------------------*/
%macro StudyDescrip(EventID=1 );
	proc means data=temp.study nway n;
	 where Visit=1;
	 class Study;
	 var b_CKDegfr;
	 output out=temp2.SampleSize n=Patients;
	run;
 
	proc means data=temp.study nway min median max;
	 where Visit=1;
	 class Study;
	 var fu&EventID;
	 output out=temp2.EventTime min=MinTime median=MedianTime max=MaxTime;
	run;
	/*========================================================================= 
	   Assess how many events occur in each study and whether we need worry 
	   about informative censoring for a given study with low event rates.
	=========================================================================*/
	proc means data=temp.study nway noprint n mean median min max range;
	 where visit=1;
	 class Study ev&EventID;
	 var fu&EventID;
	 output out=temp2.NumberEvents n=n mean=mean median=median min=min max=max range=range; 
	run;
	proc sort data=temp2.NumberEvents;
	 by Study ev&EventID;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_n prefix=n;
	 by study;
	 id ev&EventID;
	 var n;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_mean prefix=mean;
	 by study;
	 id ev&EventID;
	 var mean;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_median prefix=median;
	 by study;
	 id ev&EventID;
	 var median;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_min prefix=min;
	 by study;
	 id ev&EventID;
	 var min;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_max prefix=max;
	 by study;
	 id ev&EventID;
	 var max;
	run;
	proc transpose data=temp2.NumberEvents out=temp2.Events_range prefix=range;
	 by study;
	 id ev&EventID;
	 var range;
	run;
	data temp2.SummaryOfEvents;
	 merge temp2.Events_n temp2.Events_mean temp2.Events_median temp2.Events_min temp2.Events_max temp2.Events_range; 
	 PctEvents=n1/(n0+n1);
	 /*-----------------------------------------------------------------------------
	          DETERMINATION OF NUMBER OF PIECEWISE EXPONENTIAL (PE) INTERVALS
	          The number of PE intervals is chosen to give a target of approximately 
	          10 events per per interval assuming a constant event rate. This is
              based on the paper by Eric Vittinghoff and Charles E. McCulloch,
              (American Journal of Epidemiology 165(6): 710-718, 2007) which looks
              at number of events per variable in a Cox model needed to give adequate
              confidence interval coverge and minimize bias in parameter estimates. 
              Here we use n1/10 assuming no other covariates in the model where n1 is
              the number of events in total. This should provide a reasonable number
	          of intervals with which one can then use to estimate the interval
	          widths that yield approximately equal number of events per interval.
	          A minimum of 10 events per interval should also allow us to estimate the
	          piecewise baseline hazard rate parameters, eta01, eta02, ... with minimal
	          bias. A maximum of no more than 9 intervals is assumed for the PE model.  
	 ------------------------------------------------------------------------------*/
	 MaxWidth=6;
	 MaxEventTime=Max(round(max0+3), round(max1+3)); 
	 MaxIntervals=min(9, floor(MaxEventTime/MaxWidth));
	 NIntervals=min(MaxIntervals, ceil(n1/10));
	 drop _NAME_;
	run;
	/*  
	proc print data=temp2.SummaryOfEvents;
	run;
	*/
	data temp.StudyDescrip;
	 merge temp2.SampleSize(in=a)   temp2.EventTime(in=c) temp2.SummaryOfEvents(in=d);
	 by Study;
	 drop _TYPE_ _FREQ_ ;
	run;
	data temp.StudyDescrip;
	 set temp.StudyDescrip;
	run;

	proc sort data=temp.study;
	 by Study subject TrtID Month;
	run;
	
	/* Merge in StudyDescrip data containing MinimumMonth = Min(Month of follow-up post-baseline) etc. */
	data temp.study;
	set temp.study;
	*** Drop those varibles from last event so it can be replaced by those of the new events ***;
	drop Patients--NIntervals; 
	run;
	data temp.study;
	 merge temp.study temp.StudyDescrip;
	 by Study;
	run;
%mend StudyDescrip;


/*----------------------------------------------
 This macro generates data for the SP model 
 NOTE: If &SP = NO then this macro does not
       create a SP data component. 
----------------------------------------------*/
%macro Getdata_SP;
	/*=====================================
      Create a data set that just contains 
      eGFR profile data 
    =====================================*/ 
    proc sort data=temp.study; by subject Month; run;
	data temp.Study_eGFR;
	 set temp.study;
	 by Study Subject Month;

	/*=====================================
      Define an indicator variable which is
      1 if event is the response variable  
	  0 if eGFR is the response variable 
	=====================================*/ 
	 Indicator=0; 
	 eventID=0;

	/*=========================================
	  The following ensures that Interval_ID,  
	  t1, t2, RiskTime, and Outcome are not 
	  missing values in the final SP dataset 
	  when the indicator variable is 0
	==========================================*/
  	 NIntervals=1;Interval_ID=1;t1=0; t2=0; Risktime=0; Log_RiskTime=0; Outcome=0;   
	 keep Study Subject Indicator eventID Visit Month b_CKDegfr  b_CKDegfr_Mean fu_CKDegfr 
          lg_b_CKDegfr delta_lg_ACR lg_b_ACR blogacr gfrdiff gfr0c TrtID  
          t1 t2 RiskTime Log_RiskTime Outcome NIntervals Interval_ID;
	run;

	data temp.Study_Event;
	 set temp.study; 
	 by  Subject Month;
	 RiskTime=fu_dx*1; 
	 Log_RiskTime=log(RiskTime);
	 Outcome=ev_dx;
	 Indicator=1;
	 eventID=0;
	 fu_CKDegfr=0; 
	 gfr0c=b_CKDegfr - b_CKDegfr_Mean;
 	 if last.Subject;
  	 NIntervals=1;Interval_ID=1;t1=0; t2=0;  fu_CKDegfr =0;
	 keep Study Subject Indicator eventID Visit Month b_CKDegfr b_CKDegfr_Mean fu_CKDegfr 
          lg_b_CKDegfr delta_lg_ACR lg_b_ACR  blogacr gfrdiff gfr0c  TrtID   
          t1 t2 RiskTime Log_RiskTime Outcome NIntervals Interval_ID;
	run;

	/*-------------------------------------------------
	  Create a dataset for a given study suitable for 
	  a SP model with a WEIBULL survival component 
	-------------------------------------------------*/
	data temp.SP_data;
	 set temp.Study_eGFR(in=a)
	 %if %index(&SP, YES) %then %do;
	   temp.Study_Event (in=b)
	 %end;
     ;
	 by  Subject;
	 if a then response=fu_CKDegfr;
	 %if %index(&SP, YES) %then %do;
	   if b then response=Outcome;
	 %end;
	 N_Trt=2;
	run;
	data temp.SP_data;
	set temp.SP_data end=last;
	 if last then do;
      call symput("b_CKDegfr_Mean",left(b_CKDegfr_Mean)); 
	 end;
	run;
%mend  Getdata_SP;


/*------------------------------------------------------- 
  This macro generates the dataset for PE model of a time
  to event outcome specified by the parameter EventID 
--------------------------------------------------------*/
%macro Getdata_PE(EventID=1 );
	data temp.study;
	 set temp.study end=last;
	 if last then do;
      call symput("NIntervals&EventID",left(NIntervals)); 
      call symput('MaxEventTime',left(MaxEventTime)); 
      call symput('Patients',left(Patients)); 
	 end;
	run;
	/*=====================================
      Create a data set that just contains 
      survival data 
    =====================================*/ 
	data temp.Study_Event&EventID;
	 set temp.study; 
	 by  Subject Month;
	 Indicator=1;
	 eventID=&EventID;
	 fu_CKDegfr=0; 
 	 if last.Subject;
	 keep Study Subject Indicator eventID Visit Month b_CKDegfr  fu_CKDegfr 
          lg_b_CKDegfr delta_lg_ACR lg_b_ACR  blogacr gfrdiff gfr0c TrtID   
          ev&EventID fu&EventID MaxEventTime NIntervals;
	run;

	 /*=====================================================================================================
	   The following code computes the interval widths for the number of intervals, NIntervals, to be used
       for a given study. It is designed to give approximatley an equal number of events within each interval.
       It also provides the parameter estimates from PHREG for a piecewise exponential (PE) model based on
	   the interval widths determinined by PHREG.   
	 ======================================================================================================*/  

	ods output partition=temp2.Intervals_PE parameterestimates=temp2.PHREG_PE;
 	ods select partition parameterestimates;
	proc phreg data=temp.Study_Event&EventID;
	 class TrtID;
	 model fu&EventID*ev&EventID(0) = TrtID;
	 Bayes Piecewise=LogHazard (NInterval=&&NIntervals&EventID Prior=Uniform) nbi=10 nmc=10;
	run;

* 	proc print data=temp2.Intervals_PE;run; ** EFV added this to see if we get uppertime=0;


	 /*=====================================================================================================
	   The following code computes the width of the last interval for the number of intervals, NIntervals, 
	   to be used for a given study. This is set to be the maximum Event Time + 6 months.                               
 	 ======================================================================================================*/  
	data temp.Intervals_PE;
	 set temp2.Intervals_PE end=last;
	 Interval_ID=_n_;
	 if last then UpperTime=&MaxEventTime;  ** Set upper bound of last interval to be MaxEventTime = MaxTime + 6 months; 
	 t1=round(LowerTime, 0.001); t2=round(UpperTime, 0.001);
	run;
	data temp2.Intervals_PE;
	 set temp.Intervals_PE;
	 keep Interval_ID t1 t2;
	run;


	 /*=====================================================================================================
	   The following code creates a SAS dataset containing time to event survival data for a piecewise    
       exponential (PE) survival model. The final dataset name is Study_Event_PE .
	 ======================================================================================================*/  
 	data temp2.Study_Event_PE;
	 set temp.Study_Event&EventID;
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
	 by  Subject Interval_ID;
	run;
	data temp2.Study_Event_PE;
	 set temp2.Study_Event_PE;
	 by  Subject Interval_ID;
	 EventModel="PE     ";
	 Model=3;
	 Outcome=0;
	 RiskTime=t2-t1;
	 if t1<fu&EventID<=t2 then do;
	  Outcome=ev&EventID;
	  RiskTime=fu&EventID-t1;
	 end;
	 Log_RiskTime=log(RiskTime);
	 if fu&EventID<t1 then delete;
	run;
	proc sort data=temp2.Study_Event_PE; by subject Month; run;
	%put 'NIntervals=' &&NIntervals&EventID 'MaxEventTime=' &MaxEventTIme 'N_Trt=' &N_Trt;
	data temp.Study_Event_PE&EventID;
	 set temp2.Study_Event_PE;
	 EventID=&EventID;
	 Response=Outcome;
	 drop ev&EventID fu&EventID;
	run;
*	delete all intermediate data;
	proc datasets lib=temp2  nolist kill;
	quit;
	run;
%mend Getdata_PE;

/*-------------------------------------------
   This macro gets parameters for a SP model 
-------------------------------------------*/
%macro getparam_SP;
ods output ConvergenceStatus=temp2.cs1  SolutionF=temp2.pe1  CovParms=temp2.cov1 InfoCrit=temp2.ic1; 
	proc mixed data=temp.Study_eGFR ic method=ML cl;
	 class Subject TrtID;
	 model fu_CKDegfr = TrtID Month*TrtID b_CKDegfr Month*b_CKDegfr/ s noint; 
	*NOTE: Both intercept and slope are adjusted by baseline eGFR by adding b_CKDegfr Month*b_CKDegfr;
	 random intercept Month     / subject=Subject type=un ;
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
	 if Effect='b_CKDegfr' then  Parameter="beta5"; 
	 if Effect='Month*b_CKDegfr' then  Parameter="beta6"; 
	 
	 if CovParm='UN(1,1)'  then Parameter='psi11';
	 if CovParm='UN(2,1)'  then Parameter='psi21';
	 if CovParm='UN(2,2)'  then Parameter='psi22';
	 if CovParm='Residual' then Parameter='sigma';
	run; 

	proc transpose data=temp2.pe1_ out= temp2.pe_wide;
	 id Parameter;
	 var Estimate;
	run;

	 data temp2.pe_wide;
	 set temp2.pe_wide;
	 drop _name_;
	 run;
	 data temp2.pe_wide;
	 set temp2.pe_wide;
	 %if %index(&POM, SS) or %index(&POM, PA) %then %do;
		 do sigma=0.1 to 1 by .3, 2, 4, 6, 8, 10, 15, 20,40,80;
	      do theta=0 to 1.25 by .25;
		     output;
		  end;
		 end;
	 %end;
	 %if %index(&POM, POX) %then %do;
		 do sigma=0.1 to 1 by .3, 2, 4, 6, 8, 10, 15, 20,40,80;
	      do theta=-1 to 1 by .2;
		     output;
		  end;
		 end;
	 %end;
*	proc print data=temp2.pe_wide;
*	title "Initial Starting Values";
	run;
	/*=====================================================================================================
	  The following code computes the initial parameter estimates for a proportional hazards Weibull model 
	  using LIFEREG. It creates a SAS dataset containing the initial parameters representing the log hazard 
	  ratios for the various BP by Treatment combinations that a particular study investigated. These 
	  estimates are obtained using LIFEREG. There are two possible choices for the starting values that 
	  LIFEREG uses: 1) it uses the OLS estimates ignoring censoring (the default) or 2) one can specify 
	  user-defined starting values with the INEST option. Here we use the default OLS estimates as 
	  starting values. The final MLE estimates from LIFEREG are then used as starting values for the
	  NLMIXED code when fitting the SP model.

	  NOTE: The above explanation presented here clarifies what previous versions of the SAS code had 
	  which EFV found to be very confusing.          
	======================================================================================================*/  
	ods output ParameterEstimates= temp2.ParmsSurvModel_WEIBULL_MLE;
	proc lifereg data=temp.Study_Event;
	 class TrtID; 
	 model RiskTime*Outcome(0) = TrtID lg_b_CKDegfr/ distribution=WEIBULL;  
	*NOTE: HR for treatment is adjusted by log(baseline eGFR);
	run;
	ods listing;
	data temp2.Parms_WEIBULL ;
	 set  temp2.ParmsSurvModel_WEIBULL_MLE ;
	 Level=Level1+0;
	 if Parameter='TrtID' and Level=1 then Parameter="eta11"; 
	 Model=4;
	 if Parameter='Intercept' then Parameter="eta01"; 
	 if Parameter='lg_b_CKDegfr' then Parameter="eta6"; 
	 if Parameter='Weibull Shape' then Parameter="gamma"; 
	 if Parameter='Scale' then delete; 
	 if DF=0 then delete;
	run;
	data temp2.Parms_WEIBULL ;
	 length Parameter $12.;
	 set temp2.Parms_WEIBULL ;
	run;
 	proc transpose data=temp2.Parms_WEIBULL  out=temp2.pe_surv_WEIBULL;
	 id Parameter;
	 var Estimate;
	run;
	data temp2.pe_surv_WEIBULL;
	 set temp2.pe_surv_WEIBULL;
	 drop _NAME_; 
	run;

	data temp2.pe_surv_WEIBULL_all;
	 merge temp2.pe_surv_WEIBULL   ;
	run;

	data  temp.sp_parms  ;
	 set temp2.pe_wide ;
	  %if %index(&SP, YES) %then %do;
	   if _n_=1 then set temp2.pe_surv_WEIBULL_all ;
	  %end;
	 run;

	 ************************************************;
	 * Assign a grid search for eta_b0i and eta_b1i *;
	 ************************************************;
	 data temp.sp_parms  ;
	  set temp.sp_parms  ;
	   %if %index(&SP, YES) %then %do;
	    do eta_b0i=0, 0.03, 0.08, 0.13, 0.18;
 	     do eta_b1i=0, 0.50, 1.00, 1.50, 2.00;
          output;
		 end;
		end;
       %end;
	 run;

	 ***********************************************;
	 * NEW CODE FOR INCLUSION OF QUADRATIC EFFECTS *;
	 * We set beta21 & beta22 to 0 assuming there  *;
	 * is no quadratic effect as presumed in our   *;
	 * initial modeling assumptions.               *;
	 ***********************************************;
	 data temp.sp_parms  ;
	  set temp.sp_parms  ;
	  ************************************************;
	  *  Assign default values for beta21 and beta22 *;
	  ************************************************;
	  %if %index(&QUAD, YES) %then %do;
	    beta21=0;
 	    beta22=0;
 	  %end;
	run;

	/* Delete all intermediate data */
	proc datasets lib=temp2  nolist kill;
	quit;
%mend getparam_SP;


/*-------------------------------------------
   This macro gets parameters for PE model 
-------------------------------------------*/
%macro getparam_PE(EventID);
	 /*=====================================================================================================
	   The following code computes the initial parameter estimates for a piecewwise exponential model with 
	   interval widths determined from PHREG. It creates a SAS dataset containing the initial parameters 
	   representing the piecewise log hazard rates for each interval as well as the log hazard ratios for
       the various BP by Treatment combinations that a particular study investigated. These estimates are
       obtained using GENMOD and may differ slidghtly from those obatined using PHREG.    
	 ======================================================================================================*/  
	ods listing ;
	ods output ParameterEstimates=temp.ParmsSurvModel_PE;
	proc genmod data=temp.Study_Event_PE&EventID;
	 class Interval_ID TrtID; 
	 model Outcome = Interval_ID TrtID / noint dist=Poisson 
	                        offset=Log_RiskTime type3; 
	run;
 	ods listing;

	data temp2.Parms_PE;
	 set temp.ParmsSurvModel_PE;
	 Level=Level1+0;
     %do i=1 %to &N_Trt-1;
	 if Parameter='TrtID' and Level=&i then Parameter="eta1&i"; 
	 %end;
	 Model=3;

     %do j=1 %to &&NIntervals&EventID;
	 if Parameter='Interval_ID' and Level=&j then Parameter="eta0&j"; 
	 %end;
	 if DF=0 then delete;
	run;
	data temp2.Parms_PE;
	 length Parameter $12.;
	 set temp2.Parms_PE;
	run;
	data temp.Parms_PE&EventID;
	 set temp2.Parms_PE;
	 EventID=&EventID;
	run;
*	delete all intermediate data;
	proc datasets lib=temp2  nolist kill;
	quit;
%mend  getparam_PE;


/*-------------------------------------------
   This macro gets parameters for ACR model 
   This was the initial version.
-------------------------------------------*/
%macro getparam_ACR;
	ods output ParameterEstimates=temp2.PE_ACR  ANOVA=temp2.ANOVA;
	proc reg data=temp.Study_SP_PE;
	 model delta_lg_ACR= TrtID lg_b_ACR;
	 where ACR_indicator=1;
	run;
	quit;
	data temp2.ANOVA;
	 set temp2.ANOVA;
     Parameter="var_ACR";
	 rename MS=Estimate;
	 keep Parameter MS;
	 if Source="Error";
	run;
	data temp2.PE_ACR;
	 set temp2.PE_ACR;
	 if Variable='TrtID'   then Parameter="beta12_ACR"; 
	 if Variable='Intercept'   then Parameter="beta0_ACR"; 
	 if Variable='lg_b_ACR'   then Parameter="beta5_ACR"; 
	data temp2.PE_ACR;
	 set temp2.PE_ACR temp2.ANOVA ; 
	run;
	proc transpose data=temp2.PE_ACR out=temp2.PE_ACR;
	 id Parameter;
	 var Estimate;
	run;
	data temp.PE_ACR;
	 set temp2.PE_ACR;
	 drop _NAME_ _LABEL_ ;
	run;
  
	proc datasets lib=temp2  nolist kill;
	quit;
%mend  getparam_ACR;


/*-------------------------------------------
   This macro gets parameters for ACR model 
   This version gets parameters for the ACR 
   model using ANCOVA ML estimates and is 
   an alternative approach suggested by EFV 
-------------------------------------------*/
%macro getparam_ACR_EFV;
	ods output SolutionF=temp2.PE_ACR  CovParms=temp2.ANOVA;
	proc mixed data=temp.Study_SP_PE method=ml;
	 class TrtID(ref='1');
	 model delta_lg_ACR= TrtID lg_b_ACR /s;
	 where ACR_indicator=1;
	run;
	quit;
	data temp2.ANOVA;
	 set temp2.ANOVA;
	 Parameter="var_ACR";
	 keep Parameter Estimate;
	run;
	data temp2.PE_ACR;
	 set temp2.PE_ACR;
	 if Effect='TrtID' and TrtID='2' then Parameter="beta12_ACR"; 
	 if Effect='Intercept'   then Parameter="beta0_ACR "; 
	 if Effect='lg_b_ACR'   then Parameter="beta5_ACR "; 
	 if TrtID='1' then delete;
	run;
	data temp2.PE_ACR;
	 set temp2.PE_ACR temp2.ANOVA ; 
	run;
	proc transpose data=temp2.PE_ACR out=temp2.PE_ACR;
	 id Parameter;
	 var Estimate;
	run;
	data temp.PE_ACR;
	 set temp2.PE_ACR;
	 drop _NAME_ _LABEL_ ;
	run;
	proc datasets lib=temp2  nolist kill;
	quit;
%mend  getparam_ACR_EFV;


/*-------------------------------------------
   This macro gets parameters for the log
   ACR model 
-------------------------------------------*/
%macro getparam_lgACR;
	ods output ParameterEstimates=temp2.PE_lgACR  ANOVA=temp2.ANOVA;
	proc reg data=temp.Study_SP_PE;
	 model b_CKDegfr=  ;
	 where Log_ACR_indicator=1;
	run;
	quit;
	data temp2.ANOVA;
	 set temp2.ANOVA;
     Parameter="var_Log_ACR";
	 rename MS=Estimate;
	 keep Parameter MS;
	 if Source="Error";
	run;
	data temp2.PE_lgACR;
	 set temp2.PE_lgACR;
	 if Variable='Intercept'   then Parameter="beta0_Log_ACR"; 
 	data temp2.PE_lgACR;
	 set temp2.PE_lgACR temp2.ANOVA ; 
	run;
	proc transpose data=temp2.PE_lgACR out=temp2.PE_lgACR;
	 id Parameter;
	 var Estimate;
	run;
	data temp.PE_lgACR;
	 set temp2.PE_lgACR;
	 drop _NAME_ _LABEL_ ;
	run;
  
	proc datasets lib=temp2  nolist kill;
	quit;
%mend  getparam_lgACR;

/*-------------------------------------------
   This macro gets parameters for the  
   bGFR model.
-------------------------------------------*/
%macro getparam_bGFR;
	ods output ParameterEstimates=temp2.PE_bGFR  ANOVA=temp2.ANOVA;
	proc reg data=temp.Study_SP_PE;
	 model b_CKDegfr=  ;
	 where bGFR_indicator=1;
	run;
	quit;
	data temp2.ANOVA;
	 set temp2.ANOVA;
     Parameter="var_bGFR";
	 rename MS=Estimate;
	 keep Parameter MS;
	 if Source="Error";
	run;
	data temp2.PE_bGFR;
	 set temp2.PE_bGFR;
	 if Variable='Intercept'   then Parameter="beta0_bGFR"; 
 	data temp2.PE_bGFR;
	 set temp2.PE_bGFR temp2.ANOVA ; 
	run;
	proc transpose data=temp2.PE_bGFR out=temp2.PE_bGFR;
	 id Parameter;
	 var Estimate;
	run;
	data temp.PE_bGFR;
	 set temp2.PE_bGFR;
	 drop _NAME_ _LABEL_ ;
	run;
  
	proc datasets lib=temp2  nolist kill;
	quit;
%mend  getparam_bGFR;


/*-------------------------------------------
   This macro gets parameters for the Acute 
   GFR change model.
   NOTES:
   1.) gfrdiff = fu_CDKegfr(t)-b_CKDegfr
       where t is closest time post 3 months
   2.) gfr0c = b_CKDegfr-b)CKDegfr_Mean.  
-------------------------------------------*/
%macro getparam_Acute_GFR;
	ods output ParameterEstimates=temp2.PE_Acute_GFR  ANOVA=temp2.ANOVA;
	proc reg data=temp.Study_SP_PE;
	 model gfrdiff=TrtID gfr0c;
	 where Acute_GFR_indicator=1;
	run;
	quit;
	data temp2.ANOVA;
	 set temp2.ANOVA;
     Parameter="var_Acute_GFR";
	 rename MS=Estimate;
	 keep Parameter MS;
	 if Source="Error";
	run;
	data temp2.PE_Acute_GFR;
	 set temp2.PE_Acute_GFR;
	 if Variable='Intercept' then Parameter="beta0_Acute_GFR"; 
	 if Variable='TrtID'     then Parameter="beta12_Acu_GFR"; 
	 if Variable='gfr0c'     then Parameter="beta5_Acute_GFR"; 
	data temp2.PE_Acute_GFR;
	 set temp2.PE_Acute_GFR temp2.ANOVA ; 
	run;
	proc transpose data=temp2.PE_Acute_GFR out=temp2.PE_Acute_GFR;
	 id Parameter;
	 var Estimate;
	run;
	data temp.PE_Acute_GFR;
	 set temp2.PE_Acute_GFR;
	 drop _NAME_ _LABEL_ ;
	run;
  
	proc datasets lib=temp2  nolist kill;
	quit;
%mend  getparam_Acute_GFR;


/*===========================================================
   The following macro creates the dataset temp.Study_SP_PE 
   for when the PE model is used for survival. 
===========================================================*/  
%macro merge_data;
	/*-- Create a dataset for a given study suitable for a SP model with a PE survival component --*/
	%if %index(&CE, YES) %then %do;
	data temp.Study_SP_PE;
	 set temp.Sp_data %do k=1 %to &N_event; temp.Study_event_pe&k %end;   ;
   	run;
	%end;
	%else %if %index(&CE, NO) %then %do;
	data temp.Study_SP_PE;
	 set temp.Sp_data;
   	run;
	%end;
	proc sort data=temp.Study_SP_PE; by subject; run;
	 data  temp.Study_SP_PE;
	 set  temp.Study_SP_PE;
	 ACR_indicator=0;
	 if indicator=1 and missing(fu_CKDegfr) then fu_CKDegfr=0;
	run;

   /*-- Prepare ACR data --*/
    data  temp.baselinedata;
	 set  temp.Study_SP_PE;
	 by subject;
	 Indicator=1;  EventID=-1; * By assiging these values, those records will not be used in modeling eGFR, and clinical events;
	 if missing(fu_CKDegfr) then fu_CKDegfr=0;
     if  first.subject;        * Only the first row is going to be used for modeling ACR;
	run;
	 data temp.ACR;
	 set  temp.baselinedata;
	 response=delta_lg_ACR;
     ACR_indicator=1;
     run;

	data temp.Study_SP_PE;
	 set temp.Study_SP_PE;
	 if    missing(lg_b_ACR) then lg_b_ACR=0;
	 if    missing(delta_lg_ACR) then delta_lg_ACR=0;
	run;
	data  temp.Study_SP_PE;
	 set  temp.Study_SP_PE 
     %if %index(&ACR, YES) %then %do;
          temp.ACR
	 %end;
	 ;
	run;

    /*-- Prepare mean GFR data --*/
	data  temp.GFR;
	 set temp.baselinedata;
     bGFR_indicator=1;
	 response=b_CKDegfr;
     run;
	data  temp.Study_SP_PE;
	 set  temp.Study_SP_PE 
     %if %index(&bGFR, YES) %then %do;
          temp.GFR
	 %end;
	 ;
	run;


	/*-- Prepare Log ACR data --*/
	data  temp.Log_ACR;
	 set  temp.baselinedata;
     Log_ACR_indicator=1;
	 response=blogacr;
     run;
	data  temp.Study_SP_PE;
	 set  temp.Study_SP_PE 
     %if %index(&Log_ACR, YES) %then %do;
          temp.Log_ACR
	 %end;
	 ;
	run;

	/*-- Prepare delta GFR acute data --*/
	data  temp.Acute_GFR;
	 set  temp.baselinedata;
     Acute_GFR_indicator=1;
	 response=gfrdiff;
     run;
	data  temp.Study_SP_PE;
	 set  temp.Study_SP_PE 
     %if %index(&Acute_GFR, YES) %then %do;
          temp.Acute_GFR
	 %end;
	 ;
	run;
	data  temp.Study_SP_PE;
	 set  temp.Study_SP_PE ;
	 if missing(ACR_indicator) then ACR_indicator=0;
	 if missing(bGFR_indicator) then bGFR_indicator=0;
	 if missing(Log_ACR_indicator) then Log_ACR_indicator=0;
	 if missing(Acute_GFR_indicator) then Acute_GFR_indicator=0;
	run;
%mend merge_data;


/*===========================================================
   The following macro creates the dataset temp.Study_SP_PE 
   for when the PE model is used for survival. 
===========================================================*/  
%macro mergeParms;
	%if %index(&CE, YES) %then %do;
	data temp2.all_Parms_pe;
	set 
	%do ev_id=1 %to &N_event;
	 temp.Parms_pe&ev_id
	%end;
	;
	run;
	data temp2.all_Parms_pe;
	set temp2.all_Parms_pe;
	Parameter1=compress("ev"||compress(EventID)||"_"||compress(Parameter));
	run;
	proc transpose data=temp2.all_Parms_pe  out=temp2.all_Parms_pe_wide;
	id Parameter1;
	var Estimate;
	run;

	data temp2.all_Parms_pe_wide;
	set temp2.all_Parms_pe_wide;
	drop _NAME_;
	run;

	data  temp2.sp_parms  ;
	set temp.sp_parms ;
	if _n_=1 then set temp2.all_Parms_pe_wide ;
	run;
	data temp.sp_parms  ;
	set temp2.sp_parms  ;
	%if %index(&Proportional, YES) %then %do;
	 kappa=0;
	%end;
	run;
	%end;

	%else %if %index(&CE, NO) %then %do;
	*else do;
	data  temp2.sp_parms  ;
	set temp.sp_parms ;
	run;
	data temp.sp_parms  ;
	set temp2.sp_parms  ;
	%if %index(&Proportional, YES) %then %do;
	 kappa=0;
	%end;
	run;
	%end;

	data temp.Sp_parms;
	 set temp.Sp_parms ;
	 %if %index(&ACR, YES) %then %do;
	  if _n_=1 then set temp.PE_ACR ;
	 %end;
	run;

	data temp.Sp_parms;
	 set temp.Sp_parms ;
	 %if %index(&bGFR, YES) %then %do;
	  if _n_=1 then set temp.PE_bGFR;
	 %end;
	run;

	data temp.Sp_parms;
	 set temp.Sp_parms ;
	 %if %index(&Log_ACR, YES) %then %do;
	  if _n_=1 then set temp.PE_LgACR ;
	 %end;
	run;

	data temp.Sp_parms;
	 set temp.Sp_parms ;
	 %if %index(&Acute_GFR, YES) %then %do;
	  if _n_=1 then set temp.PE_Acute_GFR ;
	 %end;
	run;
%mend mergeParms;

%MACRO NewEstimates_ORIGINAL;
 	 %do i=1 %to &N_Trt;
 	  estimate "eGFR&i at t=12 Months"  beta0&i+beta1&i *12;
 	  estimate "eGFR&i at t=24 Months"  beta0&i+beta1&i *24;
 	  estimate "eGFR&i at t=36 Months"  beta0&i+beta1&i *36;
 	  estimate "eGFR&i at t=48 Months"  beta0&i+beta1&i *48;
	  estimate "acute slope &i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean)/(3/12);
      estimate "acute slope &i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean)/(4/12);
	  estimate "acute slope &i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean)/(6/12);
	  estimate "acute slope &i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean)/(8/12);
	  *difference in eGFR from baseline;
	  estimate "acute diff &i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean) ;
      estimate "acute diff &i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean) ;

	  estimate "total slope &i at t=12 Months"  (beta0&i+beta1&i *12-&b_CKDegfr_Mean)/1;
 	  estimate "total slope &i at t=24 Months"  (beta0&i+beta1&i *24-&b_CKDegfr_Mean)/2;
 	  estimate "total slope &i at t=36 Months"  (beta0&i+beta1&i *36-&b_CKDegfr_Mean)/3;
 	  estimate "total slope &i at t=48 Months"  (beta0&i+beta1&i *48-&b_CKDegfr_Mean)/4;
 	 %end; 
 	 %do i=1 %to &N_Trt_1;
	  %let next=%eval(&i+1);
	  %do j=&next %to &N_Trt;
	  *treatment effect in terms of slope in acute phase (Tom told me to do this way, but I also added that
	   in terms of eGFR value below) ;
	   estimate "beta4&j - beta4&i at t=3 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(3/12);
	   estimate "beta4&j - beta4&i at t=4 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(4/12);
	   estimate "beta4&j - beta4&i at t=6 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(6/12);
	   estimate "beta4&j - beta4&i at t=8 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(8/12);
	  *treatment effect in terms of eGFR value in acute phase   ;
	   estimate "diff in eGFR at t=3 Months" (beta1&j -beta1&i)*3 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=4 Months" (beta1&j -beta1&i)*4 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=6 Months" (beta1&j -beta1&i)*6 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=8 Months" (beta1&j -beta1&i)*8 + (beta0&j -beta0&i) ;

 	   estimate "beta4&j - beta4&i at t=12 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/1;
 	   estimate "beta4&j - beta4&i at t=24 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/2;
 	   estimate "beta4&j - beta4&i at t=36 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/3;
 	   estimate "beta4&j - beta4&i at t=48 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/4;
	   estimate "difference between treatment effect in 1 year total slope and chronic slope"  (beta0&j -beta0&i)/1;
 	   estimate "difference between treatment effect in 2 year total slope and chronic slope"  (beta0&j -beta0&i)/2;
 	   estimate "difference between treatment effect in 3 year total slope and chronic slope"  (beta0&j -beta0&i)/3;
 	   estimate "difference between treatment effect in 4 year total slope and chronic slope"  (beta0&j -beta0&i)/4;
	  %end;
 	 %end; 
%mend NewEstimates_ORIGINAL;

/*===================================================================================================
                             IMPORTANT UPDATE TO MACRO NewEstimates
 The following macro defines all new/additional ESTIMATE statements for meta-analyses purposes. All
 Estimates that were created using previous IML code should be translated into ESTIMATE statements 
 here so as to generate both model-based and robust stanadard errors as well as correlation estimates
 based on the robust correlation matrix to be used in assessing correlation between eGFR parameters 
 (e.g. the chronic slope treatment effect vs. a clinical event HR). Below we define the key regression
 parameters (intercept, chronic slope, total slope, acute slope and quadratic regression parameter). 
 We can uses these parameter definitions to better label (i.e. shorten) various ESTIMATE statements. 
 EFV commnented out the original estimates using longer label statements but if it is easier to use 
 the original LABEL for a given ESTIMATE statment, one just as easily comment out the newer LABEL 
 statments in favour of the original LABEL statements. 

 KEY Parameters:
  - beta0&i = Projected eGFR intercept for the simplified eGFR model
  - beta1&i = Chronic eGFR slope for the simplified eGFR model 
  - beta2&i = Quadtratic eGFR parameter when &QUAD = YES for nonlinearity assessment
  - beta3&i = Acute eGFR slope for months 3, 4, 6 and 8 (same basic formulation as used for the total 
              slope calculation but just easier to identify in the output as targeting acute effects.  
  - beta4&i = Total GFR slope for months 12, 24, 36 and 48
===================================================================================================*/
%MACRO NewEstimates;
%do i=1 %to &N_Trt;
	%if %index(&QUAD, NO) and %index(&TRUNC, NO) %then %do;
** EFV NOTE: Mean eGFR estimates under a strict linearity assumption (QUAD=NO) in the chronic phase.
	         Here we also confine estimates to the case where TRUNC=NO so as to avoid those cases
	         where truncation YES could potentially conflict with the t=24,36 or 48 time points.;
 	  estimate "eGFR&i at t=12 Months"  beta0&i + beta1&i *12;
 	  estimate "eGFR&i at t=24 Months"  beta0&i + beta1&i *24;
 	  estimate "eGFR&i at t=36 Months"  beta0&i + beta1&i *36;
 	  estimate "eGFR&i at t=48 Months"  beta0&i + beta1&i *48;
	%end;
	%if %index(&QUAD, NO) %then %do;
** EFV NOTE: Estimated acute slope under a strict linearity assumption in the chronic phase.
             EFV replaced label="acute slope &i" with label="beta3&i" to be consistent with acute  
	         slope treatment effects defined later in the treatment comparison code. One can easily  
	         revert back to the original label statements by removing * and then commenting
	         out the beta4&i estimate statements.;
	 *estimate "acute slope &i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean)/(3/12);
	 *estimate "acute slope &i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean)/(4/12);
	 *estimate "acute slope &i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean)/(6/12);
	 *estimate "acute slope &i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean)/(8/12);
	  estimate "beta3&i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean)/(3/12);
	  estimate "beta3&i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean)/(4/12);
	  estimate "beta3&i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean)/(6/12);
	  estimate "beta3&i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean)/(8/12);
** EFV NOTE: Acute difference in eGFR from baseline under a strict linearity assumption in the chronic phase;
	  estimate "acute diff &i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean) ;
	%end;
	%if %index(&QUAD, NO) and %index(&TRUNC, NO) %then %do;
** EFV NOTE: Total slope estimates under a strict linearity assumption in the chronic phase 
	         EFV replaced label="total slope &i" with label="beta4&i" but one can easily  
	         revert back to the original label statements by removing * and then commenting
	         out the beta3&i estimate statements. Here we also confine estimates to the case 
	         where TRUNC=NO so as to avoid those cases where truncation YES could potentially
	         conflict with the t=24,36 or 48 time points.;
	 *estimate "total slope &i at t=12 Months"  (beta0&i+beta1&i *12-&b_CKDegfr_Mean)/1;
 	 *estimate "total slope &i at t=24 Months"  (beta0&i+beta1&i *24-&b_CKDegfr_Mean)/2;
 	 *estimate "total slope &i at t=36 Months"  (beta0&i+beta1&i *36-&b_CKDegfr_Mean)/3;
 	 *estimate "total slope &i at t=48 Months"  (beta0&i+beta1&i *48-&b_CKDegfr_Mean)/4;
	  estimate "beta4&i at t=12 Months"  (beta0&i+beta1&i *12-&b_CKDegfr_Mean)/1;
 	  estimate "beta4&i at t=24 Months"  (beta0&i+beta1&i *24-&b_CKDegfr_Mean)/2;
 	  estimate "beta4&i at t=36 Months"  (beta0&i+beta1&i *36-&b_CKDegfr_Mean)/3;
 	  estimate "beta4&i at t=48 Months"  (beta0&i+beta1&i *48-&b_CKDegfr_Mean)/4;
	%end;

**********************************************************************************************
	                    NEW PARAMETER ESTIMATES FOR NONLINEARITY TESTS
** EFV NOTE: The beta2i values are the quadratic regression coefficients starting at knot=3   
**********************************************************************************************;
	%if %index(&QUAD, YES) %then %do;  
** EFV NOTE: Mean eGFR estimates under a quadratic nonlinearity assumption in the chronic phase. Note
	         also that when QUAD=YES then the value of TRUNC is set equal to NO as nonlinearity will 
	         likely occur later at times like 24, 36 or 48 months;
** EFV NOTE: These estimates reflect the nonlinear quadratic term in the post 3 month chronic period
	         for t=12, 24, 36 and 48 months and are the mean eGFR estimates under nonlinearity;
 	  estimate "eGFR&i at t=12 Months"  beta0&i + beta1&i *12 + beta2&i *(12-3)**2;
 	  estimate "eGFR&i at t=24 Months"  beta0&i + beta1&i *24 + beta2&i *(24-3)**2;
 	  estimate "eGFR&i at t=36 Months"  beta0&i + beta1&i *36 + beta2&i *(36-3)**2;
 	  estimate "eGFR&i at t=48 Months"  beta0&i + beta1&i *48 + beta2&i *(48-3)**2;

** EFV NOTE: Estimated acute slope under a quadratic nonlinearity assumption in the chronic phase;
** EFV WARNING: These estimates DO NOT reflect the nonlinear quadratic term in the post 3 month 
	            period for t=4, 6 and 8 months and therefore have a questionable interpretation.
	            It is not clear to EFV as to whether one should include a quadratic term or not. 
 	            As it stands, the acute slopes, beta4&i, represent what the predicted acute slopes  
	            would be based soley on the chronic slope estimates which ignores any impact the 
	            quadratic parameters have on the predicted mean eGFR post 3 months. If necessary
	            we can modify the code for months 4, 6 and 8 to reflect nonlinearity;
	 *estimate "acute slope &i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean)/(3/12);
	 *estimate "acute slope &i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean)/(4/12);
	 *estimate "acute slope &i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean)/(6/12);
	 *estimate "acute slope &i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean)/(8/12);
	  estimate "beta3&i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean)/(3/12);
	  estimate "beta3&i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean)/(4/12);
	  estimate "beta3&i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean)/(6/12);
	  estimate "beta3&i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean)/(8/12);

** EFV NOTE: These estimates DO TAKE INTO account the nonlinear quadratic term in the post 3 month 
	         period for t=4, 6 and 8 months and are labeled as adj beta4&i slopes with the t=3 month
	         acute slope being the same as above. These adjusted estimates take into account the 
	         predicted mean eGFR post 3-months which includes the quadratic parameters beta2&i;
	  estimate "adj beta3&i at t=4 Months"  (beta0&i+beta1&i *4 + beta2&i *(4-3)**2 - &b_CKDegfr_Mean)/(4/12);
	  estimate "adj beta3&i at t=6 Months"  (beta0&i+beta1&i *6 + beta2&i *(6-3)**2 - &b_CKDegfr_Mean)/(6/12);
	  estimate "adj beta3&i at t=8 Months"  (beta0&i+beta1&i *8 + beta2&i *(8-3)**2 - &b_CKDegfr_Mean)/(8/12);

** EFV NOTE: Acute difference in mean eGFR change from baseline under a quadratic nonlinearity
	         assumption in the chronic phase;
** EFV WARNING: These estimates DO NOT reflect the nonlinear quadratic term in the post 3 month 
	            period for t=4, 6 and 8 months and therefore have a questionable interpretation.    
	            It is not clear to EFV as to whether we should include a quadratic term or not.   
	            If necessary we can modify the code for months 4, 6 and 8 to reflect nonlinearity;
	  estimate "acute diff &i at t=3 Months"  (beta0&i+beta1&i *3-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=4 Months"  (beta0&i+beta1&i *4-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=6 Months"  (beta0&i+beta1&i *6-&b_CKDegfr_Mean) ;
	  estimate "acute diff &i at t=8 Months"  (beta0&i+beta1&i *8-&b_CKDegfr_Mean) ;

** EFV NOTE: Total Slope estimates under a quadratic nonlinearity assumption in the chronic phase;
** EFV NOTE: These estimates DO reflect the nonlinear quadratic term in the post 3 month chronic phase for
	         t=12, 24, 36 and 48 months and are therefore the correct total slope estimates under nonlinearity;
	 *estimate "total slope &i at t=12 Months"  (beta0&i+beta1&i *12 + beta2&i *(12-3)**2 - &b_CKDegfr_Mean)/1;
 	 *estimate "total slope &i at t=24 Months"  (beta0&i+beta1&i *24 + beta2&i *(24-3)**2 - &b_CKDegfr_Mean)/2;
 	 *estimate "total slope &i at t=36 Months"  (beta0&i+beta1&i *36 + beta2&i *(36-3)**2 - &b_CKDegfr_Mean)/3;
 	 *estimate "total slope &i at t=48 Months"  (beta0&i+beta1&i *48 + beta2&i *(48-3)**2 - &b_CKDegfr_Mean)/4;
	  estimate "beta4&i at t=12 Months"  (beta0&i+beta1&i *12 + beta2&i *(12-3)**2 - &b_CKDegfr_Mean)/1;
 	  estimate "beta4&i at t=24 Months"  (beta0&i+beta1&i *24 + beta2&i *(24-3)**2 - &b_CKDegfr_Mean)/2;
 	  estimate "beta4&i at t=36 Months"  (beta0&i+beta1&i *36 + beta2&i *(36-3)**2 - &b_CKDegfr_Mean)/3;
 	  estimate "beta4&i at t=48 Months"  (beta0&i+beta1&i *48 + beta2&i *(48-3)**2 - &b_CKDegfr_Mean)/4;
	%end;
%end; 


%do i=1 %to &N_Trt_1;
	%let next=%eval(&i+1);
	%do j=&next %to &N_Trt;
	 %if %index(&QUAD, NO) %then %do;
** EFV NOTE: ACUTE SLOPE treatment effect (per year) under a strict linearity assumption in the chronic phase;
	 * JIAN Comment: Treatment effect in terms of slope in acute phase (Tom told me to do this way, but I also 
	                 added that in terms of eGFR value below) ;
	   estimate "beta3&j - beta3&i at t=3 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(3/12);
	   estimate "beta3&j - beta3&i at t=4 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(4/12);
	   estimate "beta3&j - beta3&i at t=6 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(6/12);
	   estimate "beta3&j - beta3&i at t=8 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(8/12);

** EFV NOTE: Mean eGFR acute treatment effect under a strict linearity assumption in the chronic phase;
	 * JIAN Comment: treatment effect in terms of eGFR value in acute phase   ;
	   estimate "diff in eGFR at t=3 Months" (beta1&j -beta1&i)*3 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=4 Months" (beta1&j -beta1&i)*4 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=6 Months" (beta1&j -beta1&i)*6 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=8 Months" (beta1&j -beta1&i)*8 + (beta0&j -beta0&i) ;
	 %end;

	 %if %index(&QUAD, NO) and %index(&TRUNC, NO) %then %do;
** EFV NOTE: TOTAL SLOPE treatment effect under a strict linearity assumption in the chronic phase.
	         Here we also confine estimates to the case where TRUNC=NO so as to avoid those cases
	         where truncation YES could potentially conflict with the t=24,36 or 48 time points.;
 	   estimate "beta4&j - beta4&i at t=12 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/1;
 	   estimate "beta4&j - beta4&i at t=24 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/2;
 	   estimate "beta4&j - beta4&i at t=36 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/3;
 	   estimate "beta4&j - beta4&i at t=48 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/4;

 * EFV NOTE: Total Slope Trt Effect(t) - Chronic Slope Trt Effect = (beta4&j - beta4&i) - (beta1&j - beta1&i);
	  *estimate "difference between treatment effect in 1 year total slope and chronic slope"  (beta0&j -beta0&i)/1;
 	  *estimate "difference between treatment effect in 2 year total slope and chronic slope"  (beta0&j -beta0&i)/2;
 	  *estimate "difference between treatment effect in 3 year total slope and chronic slope"  (beta0&j -beta0&i)/3;
 	  *estimate "difference between treatment effect in 4 year total slope and chronic slope"  (beta0&j -beta0&i)/4;
	   estimate "(beta4&j - beta4&i) - (beta1&j - beta1&i) at year 1"   (beta0&j -beta0&i)/1;
 	   estimate "(beta4&j - beta4&i) - (beta1&j - beta1&i) at year 2"   (beta0&j -beta0&i)/2;
 	   estimate "(beta4&j - beta4&i) - (beta1&j - beta1&i) at year 3"   (beta0&j -beta0&i)/3;
 	   estimate "(beta4&j - beta4&i) - (beta1&j - beta1&i) at year 4"   (beta0&j -beta0&i)/4;
	 %end;

	 %if %index(&QUAD, YES) %then %do;  
** EFV NOTE: Acute slope treatment effect (per year) under a quadratic nonlinearity assumption 
	         in the chronic phase. These acute slope effects account for a nonlinear mean eGFR response;
	 * JIAN Comment:  Treatment effect in terms of slope in acute phase (Tom told me to do this way, 
	                  but I also added that in terms of eGFR value below) ;
     * Treatment effect in terms of ACUTE SLOPES UNADJUSTED for quadratic trend in mean eGFR post 3 months;
	   estimate "beta3&j - beta3&i at t=3 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(3/12);
	   estimate "beta3&j - beta3&i at t=4 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(4/12);
	   estimate "beta3&j - beta3&i at t=6 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(6/12);
	   estimate "beta3&j - beta3&i at t=8 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(8/12);

     * Treatment effect in terms of ACUTE SLOPES ADJUSTED for quadratic trend in mean eGFR post 3 months.
	   Note that we need not adjust at t = 3 as the formal truncation period occurs after 3 months;
	 * estimate "adj beta4&j - beta4&i at t=3 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/(3/12);
	   estimate "adj beta3&j - beta3&i at t=4 Months" ( (beta0&j+beta1&j *4 + beta2&j *(4-3)**2 - &b_CKDegfr_Mean)/(4/12) ) - 
	                                                  ( (beta0&i+beta1&i *4 + beta2&i *(4-3)**2 - &b_CKDegfr_Mean)/(4/12) );
	   estimate "adj beta3&j - beta3&i at t=6 Months" ( (beta0&j+beta1&j *6 + beta2&j *(6-3)**2 - &b_CKDegfr_Mean)/(6/12) ) - 
	                                                  ( (beta0&i+beta1&i *6 + beta2&i *(6-3)**2 - &b_CKDegfr_Mean)/(6/12) );
	   estimate "adj beta3&j - beta3&i at t=8 Months" ( (beta0&j+beta1&j *8 + beta2&j *(8-3)**2 - &b_CKDegfr_Mean)/(8/12) ) - 
	                                                  ( (beta0&i+beta1&i *8 + beta2&i *(8-3)**2 - &b_CKDegfr_Mean)/(8/12) );

	 * Treatment effect in terms of eGFR value in acute phase   ;
	   estimate "diff in eGFR at t=3 Months" (beta1&j -beta1&i)*3 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=4 Months" (beta1&j -beta1&i)*4 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=6 Months" (beta1&j -beta1&i)*6 + (beta0&j -beta0&i) ;
	   estimate "diff in eGFR at t=8 Months" (beta1&j -beta1&i)*8 + (beta0&j -beta0&i) ;

 	 * Treatment effect in terms of TOTAL SLOPES UNADJUSTED for quadratic trends in chronic phase ;
	   estimate "beta4&j - beta4&i at t=12 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/1;
 	   estimate "beta4&j - beta4&i at t=24 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/2;
 	   estimate "beta4&j - beta4&i at t=36 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/3;
 	   estimate "beta4&j - beta4&i at t=48 Months" (beta1&j -beta1&i)*12 + (beta0&j -beta0&i)/4;

 	 * Treatment effect in terms of TOTAL SLOPES ADJUSTED for quadratic trends in chronic phase ;
	   estimate "adj beta4&j - beta4&i at t=12 Months" ( (beta0&j+beta1&j *12 + beta2&j *(12-3)**2 - &b_CKDegfr_Mean)/1 ) - 
	                                                   ( (beta0&i+beta1&i *12 + beta2&i *(12-3)**2 - &b_CKDegfr_Mean)/1 );
	   estimate "adj beta4&j - beta4&i at t=24 Months" ( (beta0&j+beta1&j *24 + beta2&j *(24-3)**2 - &b_CKDegfr_Mean)/2 ) - 
	                                                   ( (beta0&i+beta1&i *24 + beta2&i *(24-3)**2 - &b_CKDegfr_Mean)/2 );
	   estimate "adj beta4&j - beta4&i at t=36 Months" ( (beta0&j+beta1&j *36 + beta2&j *(36-3)**2 - &b_CKDegfr_Mean)/3 ) - 
	                                                   ( (beta0&i+beta1&i *36 + beta2&i *(36-3)**2 - &b_CKDegfr_Mean)/3 );
	   estimate "adj beta4&j - beta4&i at t=48 Months" ( (beta0&j+beta1&j *48 + beta2&j *(48-3)**2 - &b_CKDegfr_Mean)/4 ) - 
	                                                   ( (beta0&i+beta1&i *48 + beta2&i *(48-3)**2 - &b_CKDegfr_Mean)/4 );

 	 * Treatment effect in terms of TOTAL SLOPES ADJUSTED for quadratic effects in chronic phase;
	  *estimate "difference between treatment effect in 1 year total slope and chronic slope"  
	        ( (beta0&j + beta2&j *(12-3)**2) - (beta0&i + beta2&i *(12-3)**2) )/1;
	  *estimate "difference between treatment effect in 2 year total slope and chronic slope"  
	        ( (beta0&j + beta2&j *(24-3)**2) - (beta0&i + beta2&i *(24-3)**2) )/2;
	  *estimate "difference between treatment effect in 3 year total slope and chronic slope"  
	        ( (beta0&j + beta2&j *(36-3)**2) - (beta0&i + beta2&i *(36-3)**2) )/3;
	  *estimate "difference between treatment effect in 4 year total slope and chronic slope"  
	        ( (beta0&j + beta2&j *(48-3)**2) - (beta0&i + beta2&i *(48-3)**2) )/4;
	   estimate "(beta4&j - beta4&i)-(beta1&j - beta1&i) at year 1"  
	        ( (beta0&j + beta2&j *(12-3)**2) - (beta0&i + beta2&i *(12-3)**2) )/1;
	   estimate "(beta4&j - beta4&i)-(beta1&j - beta1&i) at year 2"
	        ( (beta0&j + beta2&j *(24-3)**2) - (beta0&i + beta2&i *(24-3)**2) )/2;
	   estimate "(beta4&j - beta4&i)-(beta1&j - beta1&i) at year 3"
	        ( (beta0&j + beta2&j *(36-3)**2) - (beta0&i + beta2&i *(36-3)**2) )/3;
	   estimate "(beta4&j - beta4&i)-(beta1&j - beta1&i) at year 4"  
	        ( (beta0&j + beta2&j *(48-3)**2) - (beta0&i + beta2&i *(48-3)**2) )/4;
	   %end;
	  %end;
%end; 
%mend NewEstimates;

/*===============================================
              MACRO EFV_IML_Code    
 This macro computes both model-based as well as
 robust standard errors for all parameters listed
 in the ESTIMATE statements. It also includes 
 both model-based and robust standard errors for 
 all the original parameters in the NLMIXED Model
 as	defined by the dataset ParameterEstimates.  
 KEY: PRINT= -Defines whether we print the data
	          sets defined in the macro. The two
              options are:
	           PRINT=YES
               PRINT=NO (the default) 
	          This option allows one to check if
              things are working OK. I would 
	          suggest PRINT=YES only if there 
	          appears ERROR messages.
===============================================*/

%macro EFV_IML_Code(PRINT=NO);

%let PRINT=%upcase(&PRINT);

/*============================================ 
Temporary dataset names created in NLMIXED 
   Hessian             = Hessian
   IterHistory         = temp.SP_PE_iter0
   ConvergenceStatus   = temp.SP_PE_cs0
   FitStatistics       = temp.SP_PE_ic0 
   ParameterEstimates  = temp.SP_PE_pe0 
   AdditionalEstimates = temp.SP_PE_est0
   DerAddEst           = temp.SP_PE_der
   CovMatAddEst        = temp.SP_PE_emp_cov
   CorrMatAddEst       = temp.SP_PE_emp_cor
============================================*/

/* Rename Standard Errors as Robust Standard Errors */ 
data temp.SP_PE_pe0;              
	rename StandardError=RobustStandardError; 
	set temp.SP_PE_pe0;
run;
%if %index(&PRINT, YES) %then %do;
proc print data=temp.SP_PE_pe0;
 title 'Data temp.SP_PE_pe0';
run;
%end;

/* Rename Standard Errors as Robust Standard Errors */ 
data temp.SP_PE_est0;              
	rename StandardError=RobustStandardError; 
	set temp.SP_PE_est0;
run;
%if %index(&PRINT, YES) %then %do;
proc print data=temp.SP_PE_est0;
 title 'Data temp.SP_PE_est0';
run;
%end;

/* Hessian matrix from which we derive all model-based standard errors */
/* as well as provide a check on convergence issues for our algorithm. */
data Hessian;
	set temp.Hessian;            
	drop row Parameter;
run;

/* We create new SAS datasets because IML does not take */
/* dataset names like work.temp.SP_PE_pe for example    */  
data SP_PE_pe0;                   ** SP_PE_pe with robust standard errors to be used in IML code **;  
	set temp.SP_PE_pe0;
run;

data SP_PE_est0;                  ** SP_PE_est with robust standard errors to be used in IML code **;  
	set temp.SP_PE_est0;
run;

data Derivatives;                 ** Derivatives of ESTIMATE functions to apply DELTA method in IML code **; 
	set temp.SP_PE_der;
	drop row;
run;

data RobustCov;                   ** Robust Covariance matrix based on the EMPIRICAL option in NLMIXED **;  
 set temp.SP_PE_emp_cov;
run;

data RobustCorr;                  ** Robust Correlation matrix based on the EMPIRICAL option in NLMIXED **; 
 set temp.SP_PE_emp_cor;
run;

%if %index(&PRINT, YES) %then %do;
 proc print data=SP_PE_pe0;        title "Model parameter estimates with robust standard errors";run;
 proc print data=Hessian;          title "Hessian";run;
 proc print data=SP_PE_est0;       title "Additional parameter estimates with robust standard errors";run;
 proc print data=Derivatives;      title "Derivative Matrix";run;
 proc print data=RobustCov;        title "Robust Covariance Matrix";run;
 proc print data=RobustCorr;       title "Robust Correlation Matrix";run;
%end;

/*==============================================================================*/
/* Begin IML code to be used to create necessary datasets for the Meta-Analysis */
/*==============================================================================*/
proc iml;
	use work.Hessian;
	read all var _ALL_ into Hessian;
	close Hessian;
	Omega=Inv(Hessian);                          ** Defines Model-based Covariance Matrix **;
	StandardError = VecDiag(sqrt(diag(Omega)));  ** Defines Model-based standard errors   **; 

/* Determine if there are problems with Hessian */
	H = Hessian;
	DetH = det(H);                ** If 0 then Hessian is not p.d. or is singular; 
	EigenH=eigval(H);             ** If a negative eigenvalue then second-order optimality is violated ;
	MinEigenH = min(eigval(H));   ** One or more eigenvalue are negative, second-order optimality is violated ;  
	Status_H=0;                    
	pdH = 0;                      ** Hessian is p.d. (i.e., non-singular with DET(H) not equal to 0);
	negH = 0;                     ** Hessian does not have any negative eigenvalues;
    if DetH=0 then pdH=1;         ** Hessian is non p.d. (DET(H)=0);  
    if MinEigenH<0 then negH=1;   ** Hessian has 1 or more negative eigenvalues; 
	Status_H=max(pdH, negH);      ** Status_H =0 => Hessian is OK, else Hessian is non p.d. or has eigenvalues<0;
*	print DetH EigenH MinEigenH pdH negH Status_H;
	HessOut = DetH||pdH||MinEigenH||negH||Status_H;
*	print HessOut;
	create HessData from HessOut;
    append from HessOut;
	close HessData; 
/* End of Hessian checks */

/* Get Model-based Standard Errors for original model parameters in NLMIXED Model */ 
	use work.SP_PE_pe0;
	read all var _CHAR_ into Parameter;
	use work.SP_PE_pe0;
	read all var _ALL_ into Estimates [colname=varNames1];
	close work.SP_PE_pe0;
	out_pe0 = Estimates || StandardError;
	varNames=varNames1 || {"StandardError"};
	create SP_PE_pe0 from out_pe0 [colName=varNames rowName=Parameter];
	append from out_pe0 [rowname = Parameter];
	%if %index(&PRINT, YES) %then %do;
	print Parameter, Estimates, StandardError, out_pe0;
	%end;

/* Get Model-based Standard Errors for additional parameters estimated from ESTIMATE statements */ 
	use work.SP_PE_est0;
	read all var _CHAR_ into Label;
	use work.SP_PE_est0;
	read all var _ALL_ into AddedEstimates [colname=varNames2];
	close work.SP_PE_est0;
	use work.Derivatives;
	read all var _ALL_ into Derivatives;
	close Derivatives;
	%if %index(&PRINT, YES) %then %do;
	print AddedEstimates, Derivatives;
	%end;
	D  = Derivatives;
	Dt = D`;
	Omega_AddEst = D*Omega*D`;                            ** DELTA method to get standard errors of ESTIMATES **;   
	StandardErrorEst = VecDiag(sqrt(diag(Omega_AddEst))); ** Defines additional model-based standard errors   **; 
	out_est0 = AddedEstimates || StandardErrorEst;
	varNamesEst=varNames2 || {"StandardError"};
	create SP_PE_est0 from out_est0 [colName=varNamesEst rowName=Label];
	append from out_est0 [rowname = Label];
	%if %index(&PRINT, YES) %then %do;
	print Dt, D, Omega_Addest, StandardErrorEst;
	%end;
quit;
	/*===========================================
	 The following code is used to determine if 
	 any model-based Standard Errors are missing
	 in which case this used in the SAS Macro 
	 Check_Hessian as a flag for running one of
	 the alternative models as a missing standard
	 error indicates a problem with the Hessain.  
	============================================*/
 	data SP_PE_pe0;
	 set SP_PE_pe0;
	 if StandardError=0 then StandardError=.;
	run;

%if %index(&PRINT, YES) %then %do;
	proc print data=SP_PE_pe0;
	 title 'Initial Parameter Estimates with both model-based and robust standard errors';
	run;
	proc print data=SP_PE_est0;
	 title 'Additional Parameter Estimates with both model-based and robust standard errors';
	run;
	proc print data=RobustCov; 
	title "Robust Covariance Matrix";
	run;
	proc print data=RobustCorr; 
	title "Robust Correlation Matrix";
	run;
%end;

/*========================================================== 
  The following code checks that the temporary datasets 
  temp.SP_PE_pe0 and temp.SP_PE_est0 are changed as needed 
===========================================================*/ 
data temp.SP_PE_pe0;
 set SP_PE_pe0;
run;

%if %index(&PRINT, YES) %then %do;
	proc print data=temp.SP_PE_pe0;
	 title 'Check that temp.SP_PE_pe0 has changed to include both model-based and robust standard errors';
	run;
%end;

data temp.SP_PE_est0;
 set SP_PE_est0;
run;

%if %index(&PRINT, YES) %then %do;
	proc print data=temp.SP_PE_est0;
	 title 'Check that temp.SP_PE_est0 has changed to include both model-based and robust standard errors';
	run;

	proc print data= temp.SP_PE_der;
	 title 'Print of temp.SP_PE_der with derivatives calculated by NLMIXED EDER option.';
	run;

	proc print data=temp.SP_PE_emp_cov;
	 title 'Print of temp.SP_PE_emp_cov as calculated by NLMIXED ECOV option.';
	run;

	proc print data=temp.SP_PE_emp_cor;
	 title 'Print of temp.SP_PE_emp_cor as calculated by NLMIXED ECORR option.';
	run;
%end;

/*======================================= 
 Update datset temp.SP_PE_cs0 to include
 Hessian convergence diagnostics 
========================================*/
data HessData;
 set HessData;
 rename col1=DetH col2=pdH col3=MinEigenH col4=negH col5=Status_H;
run;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 if _n_=1 then set HessData;
run;
/*
 proc print data=SP_PE_pe0;   title "Model parameter estimates with robust standard errors";     run;
 proc print data=Hessian;     title "Hessian";                                                   run;
 proc print data=SP_PE_est0;  title "Additional parameter estimates with robust standard errors";run;
 proc print data=Derivatives; title "Derivative Matrix";                                         run;
 proc print data=RobustCov;   title "Robust Covariance Matrix";                                  run;
 proc print data=RobustCorr;  title "Robust Correlation Matrix";                                 run;
*/
%mend EFV_IML_Code;


/*===============================================
         MACRO Original_JIAN_IML_Code    
 This macro computes both model-based as well as
 robust standard errors for all parameters listed
 in the ESTIMATE statements. This was the code Jian 
 developed to get both empirical standard error 
 estimates given by the EMPIRICAL option of NLMIXED
 as well as IML-based model-based standard error 
 estimates based on the inverse of the Hessain matrix.  
===============================================*/
%macro Original_Jian_IML_code;
	data matrix;
	set Hessian;
	drop row  Parameter;
	run;
	data beta;
	set temp.SP_PE_pe0;
	keep Estimate;
	run;

	proc iml;
	use work.matrix;
	read all var _ALL_ into H;
	close matrix;

	use work.beta;
	read all var _ALL_ into b0;
	close beta;
	/* Determine problems with Hessian */
	DetH = det(H);                ** If 0 then Hessian is not p.d. or is singular; 
	EigenH=eigval(H);             ** If a negative eigenvalue then second-order optimality is violated ;
	MinEigenH = min(eigval(H));   ** One or more eigenvalue are negative, second-order optimality is violated ;  
	Status_H=0;                    
	pdH = 0;                      ** Hessian is p.d. (i.e., non-singular with DET(H) not equal to 0);
	negH = 0;                     ** Hessian does not have any negative eigenvalues;
    if DetH=0 then pdH=1;         ** Hessian is non p.d. (DET(H)=0);  
    if MinEigenH<0 then negH=1;   ** Hessian has 1 or more negative eigenvalues; 
	Status_H=max(pdH, negH);      ** Status_H =0 => Hessian is OK, else Hessian is non p.d. or has eigenvalues<0;
*	print DetH EigenH MinEigenH pdH negH Status_H;
	/* End of Check on Hessian */

	cov0=inv(H);
*	print cov0;
	b=b0[1:4];
*	print b;
	L={-1 1 0 0,
	      0 0 -12 12,
	      1 0 12 0,
		  1 0 24 0,
		  1 0 36 0,
		  1 0 48 0,
		  0 1 0 12,
		  0 1 0 24,
		  0 1 0 36,
		  0 1 0 48,
		  -1 1 -12 12,
		  -1 1 -24 24,
		  -1 1 -36 36,
		  -1 1 -48 48,
		  -1 1 0 0,
		  -1 1 0 0,
		  -1 1 0 0,
		  -1 1 0 0,
		   1 0 12 0,
		  1 0 24 0,
		  1 0 36 0,
		  1 0 48 0,
		  0 1 0 12,
		  0 1 0 24,
		  0 1 0 36,
		  0 1 0 48,
		  1 0 3 0,
		  1 0 4 0,
		  1 0 6 0,
		  1 0 8 0,
		  0 1 0 3,
		  0 1 0 4,
		  0 1 0 6,
		  0 1 0 8,
		  1 0 3 0,
		  1 0 4 0,
		  1 0 6 0,
		  1 0 8 0,
		  0 1 0 3,
		  0 1 0 4,
		  0 1 0 6,
		  0 1 0 8,
		  -4 4 -12 12,
		  -3 3 -12 12,
		  -2 2 -12 12,
		  -1.5 1.5 -12 12,
		  -1 1 -3 3,
	 	  -1 1 -4 4,
		  -1 1 -6 6,
		  -1 1 -8 8,
		   0 0 12 0,
		   0 0 0 12

	      };
	L[12,]=L[12,]/2;
	L[13,]=L[13,]/3;
	L[14,]=L[14,]/4;
	L[16,]=L[16,]/2;
	L[17,]=L[17,]/3;
	L[18,]=L[18,]/4;
	L[20,]=L[20,]/2;
	L[21,]=L[21,]/3;
	L[22,]=L[22,]/4;
	L[24,]=L[24,]/2;
	L[25,]=L[25,]/3;
	L[26,]=L[26,]/4;

	L[27,]=L[27,]/(3/12);
	L[28,]=L[28,]/(4/12);
	L[29,]=L[29,]/(6/12);
	L[30,]=L[30,]/(8/12);
	L[31,]=L[31,]/(3/12);
	L[32,]=L[32,]/(4/12);
	L[33,]=L[33,]/(6/12);
	L[34,]=L[34,]/(8/12);
	print L;
	est=L*b;
	est[19]=est[19]-&b_CKDegfr_Mean;
	est[20]=est[20]-&b_CKDegfr_Mean/2;
	est[21]=est[21]-&b_CKDegfr_Mean/3;
	est[22]=est[22]-&b_CKDegfr_Mean/4;
	est[23]=est[23]-&b_CKDegfr_Mean;
	est[24]=est[24]-&b_CKDegfr_Mean/2;
	est[25]=est[25]-&b_CKDegfr_Mean/3;
	est[26]=est[26]-&b_CKDegfr_Mean/4;

	est[27]=est[27]-&b_CKDegfr_Mean/(3/12);
	est[28]=est[28]-&b_CKDegfr_Mean/(4/12);
	est[29]=est[29]-&b_CKDegfr_Mean/(6/12);
	est[30]=est[30]-&b_CKDegfr_Mean/(8/12);
	est[31]=est[31]-&b_CKDegfr_Mean/(3/12);
	est[32]=est[32]-&b_CKDegfr_Mean/(4/12);
	est[33]=est[33]-&b_CKDegfr_Mean/(6/12);
	est[34]=est[34]-&b_CKDegfr_Mean/(8/12);

	est[35]=est[35]-&b_CKDegfr_Mean;
	est[36]=est[36]-&b_CKDegfr_Mean;
	est[37]=est[37]-&b_CKDegfr_Mean;
	est[38]=est[38]-&b_CKDegfr_Mean;
	est[39]=est[39]-&b_CKDegfr_Mean;
	est[40]=est[40]-&b_CKDegfr_Mean;
	est[41]=est[41]-&b_CKDegfr_Mean;
	est[42]=est[42]-&b_CKDegfr_Mean;

*	print est;
	cov1=cov0[1:4,1:4];
*	print cov1;
	cov=L*cov1*L`;
*	print cov;
	se=sqrt(vecdiag(cov));
*	print se;
	label={"beta02 - beta01",
	           "beta12 - beta11",
			   "eGFR1 at t=12 Months",
			   "eGFR1 at t=24 Months",
			   "eGFR1 at t=36 Months",
			   "eGFR1 at t=48 Months",
			   "eGFR2 at t=12 Months",
			   "eGFR2 at t=24 Months",
			   "eGFR2 at t=36 Months",
			   "eGFR2 at t=48 Months",
			   "beta42 - beta41 at t=12 Months",
			   "beta42 - beta41 at t=24 Months",
			   "beta42 - beta41 at t=36 Months",
			   "beta42 - beta41 at t=48 Months",
			   "difference between treatment effect in 1 year total slope and chronic slope",
			   "difference between treatment effect in 2 year total slope and chronic slope",
			   "difference between treatment effect in 3 year total slope and chronic slope",
			   "difference between treatment effect in 4 year total slope and chronic slope",
			   "total slope 1 at t=12 Months",
			   "total slope 1 at t=24 Months",
			   "total slope 1 at t=36 Months",
			   "total slope 1 at t=48 Months",
			   "total slope 2 at t=12 Months",
			   "total slope 2 at t=24 Months",
			   "total slope 2 at t=36 Months",
			   "total slope 2 at t=48 Months",
			   "acute slope 1 at t=3 Months",
			   "acute slope 1 at t=4 Months",
			   "acute slope 1 at t=6 Months",
			   "acute slope 1 at t=8 Months",
			   "acute slope 2 at t=3 Months",
			   "acute slope 2 at t=4 Months",
			   "acute slope 2 at t=6 Months",
			   "acute slope 2 at t=8 Months",

			   "acute diff 1 at t=3 Months",
			   "acute diff 1 at t=4 Months",
			   "acute diff 1 at t=6 Months",
			   "acute diff 1 at t=8 Months",
			   "acute diff 2 at t=3 Months",
			   "acute diff 2 at t=4 Months",
			   "acute diff 2 at t=6 Months",
			   "acute diff 2 at t=8 Months",

			   "beta42 - beta41 at t=3 Months",
			   "beta42 - beta41 at t=4 Months",
			   "beta42 - beta41 at t=6 Months",
			   "beta42 - beta41 at t=8 Months",

			   "diff in eGFR at t=3 Months",
			   "diff in eGFR at t=4 Months",
			   "diff in eGFR at t=6 Months",
			   "diff in eGFR at t=8 Months",
			   "beta11",
			   "beta12"



			   
	};
*	print DetH EigenH MinEigenH pdH negH Status_H;
	HessOut = DetH||pdH||MinEigenH||negH||Status_H;
*	print HessOut;
	create HessData from HessOut;
    append from HessOut;
	close HessData; 

	out=est||se;
*	print out;
	create est from out;
	append from out;
	close est;
	create label from label;
	append from label;
	close label;

	var0=vecdiag(inv(H));
	var0=(var0+abs(var0))/2; *replace negative variance with 0, this is just to allow se0 below to be calculated and eventually the 0 se will be set as missing in the output dataset;
	se0=sqrt(var0);
	create se_model from se0;
	append from se0;
	close se_model;
	quit;

	data est;
	 set est;
	 rename col1=estimate_model
	        col2=SE_model;
	run;
	data label;
	 set label;
	 rename col1=label;
	run;
	data est;
	 merge label est;
	run;

	data se_model;
	 set se_model;
	 rename col1=se_model_based;
	run;
	data se_model;
	 set se_model;
	 if se_model_based=0 then se_model_based=.;  *the 0 se is set to be missing which is what it should be and in consistency with the behavior of SAS;
	run;
	data temp.SP_PE_pe0;
	 merge  temp.SP_PE_pe0 se_model;
	run;
	data temp.SP_PE_pe0;
	 set temp.SP_PE_pe0;
	 rename StandardError=se_empirical;
	run;
	proc sort data=est; by label; run;
	proc sort data=temp.SP_PE_est0; by label; run;
	data temp.SP_PE_est0; 
	 merge temp.SP_PE_est0 est;
	 by label;
	run;
	data HessData;
	 set HessData;
	 rename col1=DetH col2=pdH col3=MinEigenH col4=negH col5=Status_H;
	run;
	data temp.SP_PE_cs0;
	 set temp.SP_PE_cs0;
	 if _n_=1 then set HessData;
	run;
%mend Original_Jian_IML_Code; 

** EFV modified POM global options to be NO, SS, or PA - see GLOBAL macro variables setup **;
%macro model(Nloptions=%str(tech=NRRIDG maxiter=300 maxfunc=1000 qpoints=1)); 
%put POM= &POM, ACR= &ACR, CE= &CE, Proportional=&Proportional, BOUNDS= &Bounds, PSI21= &PSI21,  
     HESS= &HESS, SP_threshhold=&SP_threshold, QUAD= &QUAD, TRUNC= &TRUNC, Truncate= &Truncate;
%if %index(&PSI21, NO) %then %do;
 data temp.sp_parms;
  set temp.sp_parms;
  drop psi21;
 run;
%end;
/* NEW FOR EFV on 01/20/2023 */
proc print data=temp.sp_parms;title 'New by EFV to check on whether SP model is run'; run;

proc sort data=temp.Study_SP_PE; 
 by subject eventID month; 
run;

ods output     Hessian             = temp.Hessian
               IterHistory         = temp.SP_PE_iter0
               ConvergenceStatus   = temp.SP_PE_cs0
               FitStatistics       = temp.SP_PE_ic0 
               ParameterEstimates  = temp.SP_PE_pe0 
               AdditionalEstimates = temp.SP_PE_est0
			   DerAddEst           = temp.SP_PE_der
			   CovMatAddEst        = temp.SP_PE_emp_cov
			   CorrMatAddEst       = temp.SP_PE_emp_cor;
ods exclude Hessian CovMatAddEst CovMatParmEst;   ** EFV added the exclude so as to minimize output **;
proc nlmixed data=temp.Study_SP_PE  &nloptions EMPIRICAL HESS ECORR EDER COV ECOV NOSORTSUB ZNLP;
	 parms /data=temp.sp_parms best=1;            ** EFV added in Best=1 so as to minimize output **; 
	 array _beta0_[2] beta01 - beta02;
	 array _beta1_[2] beta11 - beta12;
	 beta0=0;
	 beta1=0;
	 %if %index(&QUAD, YES) %then %do;
	  array _beta2_[2] beta21 - beta22;
	  beta2=0;
	 %end;
	 /*======================================================
	   New code to ensure we can use ESTIMATE log(1+kappa)
       by restricting the kappa value to be > -1.0  
     ======================================================*/ 
	 %if %index(&Proportional, YES) and %index(&BOUNDS, YES) %then %do;
	  bounds kappa>-1.0;
	 %end;
	 /*======================================================
      The following allows for proportional treatment effects
	  with respect to the variance-covariances of slopes but
	  only when there are just two treatment groups.
     ======================================================*/ 
	 %if %index(&Proportional, YES) %then %do;
	   u0i = b0i;
	   u1i = (1+kappa*(TrtID=2))*b1i;
	 %end;
	 %else  %do;
	   u0i = b0i;
	   u1i = b1i;
	 %end;

	 do k=1 to 2;
	   beta0  = beta0  + _beta0_[k]*(TrtID=k);  ** PA intercept as a linear function of Trt effects; 
	   beta1  = beta1  + _beta1_[k]*(TrtID=k);  ** PA acute slope as a linear function of Trt effects;
	 %if %index(&QUAD, YES) %then %do;
	   beta2  = beta2  + _beta2_[k]*(TrtID=k);  ** PA quadratic regression coefficients for Trt groups;
	 %end;
	 end;
	 beta0i = beta0 + u0i;                      ** SS intercept as a linear function of Trt effects; 
	 beta1i = beta1 + u1i;                      ** SS acute slope as a linear function of Trt effects;

	 /*=================================================================
	   Compute the population-average (PA) and subject-specific (SS) 
	   predicted means for the Trt groups adjusted for baseline eGFR.
     =================================================================*/ 
	%if %index(&QUAD, NO) %then %do;
	 ** mu is the PA predicted mean response over time as a linear function of the
	    Trt group. Both the intercept (beta0) and slope (beta1) are adjusted by 
	    baseline eGFR via the terms beta5*b_CKDegfr and beta6*Month*b_CKDegf;
	 mu   = beta0+beta1*Month+beta5*b_CKDegfr+beta6*Month*b_CKDegfr;     
	 ** mu_i is the corresponding SS predicted mean response over time as a linear
	    function of Trt group adjusted for baseline eGFR.;
	 mu_i = beta0i+beta1i*Month+beta5*b_CKDegfr+beta6*Month*b_CKDegfr; 
	%end;
	%if %index(&QUAD, YES) %then %do;
	 ** mu is the PA predicted mean response over time as a linear function of the
	    Trt group. Both the intercept (beta0) and slope (beta1) are adjusted by 
	    baseline eGFR via the terms beta5*b_CKDegfr and beta6*Month*b_CKDegf;
	 mu   = beta0+beta1*Month+beta2*(Month**2)+beta5*b_CKDegfr+beta6*Month*b_CKDegfr;     
	 ** mu_i is the corresponding SS predicted mean response over time as a linear
	    function of Trt group adjusted for baseline eGFR.;
	 mu_i = beta0i+beta1i*Month+beta2*(Month**2)+beta5*b_CKDegfr+beta6*Month*b_CKDegfr; 
	%end; 
	%if %index(&POM, SS) %then %do;
     var = (sigma/100)*((mu_i**2)**theta);      ** SS Intra-subject variance function with rescaled sigma;
    *var = (sigma)*((mu_i**2)**theta);          ** SS Intra-subject variance function with un-scaled sigma;
    %end; 
	%if %index(&POM, PA) %then %do;
     var = (sigma/100)*((mu**2)**theta);        ** PA Intra-subject variance function with rescaled sigma;
    *var = (sigma)*((mu**2)**theta);            ** PA Intra-subject variance function with un-scaled sigma;
    %end; 
	%if %index(&POM, POX) %then %do;
     var = (sigma/100)*exp(theta*Month);        ** Power-of-X (POX) structure preserving 1st and 2nd order orthogonality;
    *var = (sigma)*exp(theta*Month);            ** Power-of-X (POX) variance function with un-scaled sigma;
    %end; 
    %if %index(&POM, NO) %then %do;
      var=sigma;
    %end;

	 /*==================================================
      ll_Y is the conditional log-likelihood of Y=eGFR 
      which is assumed to be normally distributed with   
      conditional mean mu_i and conditional variance     
      defined by the POM variance structure given by
 			var = (sigma)*(mu_i**2)**theta  
      Note that b0i and b1i are the random intercept
	  and random slope parameters.
	 ===================================================*/ 
	 ll_Y = (1-indicator)*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((fu_CKDegfr - mu_i)**2)/(var) 
	                        - 0.5*log(var) );  

	/*------------------------------------------------------ 
	 Modeling ACR, assuming 2 treatment levels with level 1
	 (i.e., TrtID=0) as the reference Trt group
	------------------------------------------------------*/
	%if %index(&ACR, YES) %then %do;
     mu_ACR=beta0_ACR+beta12_ACR*(TrtID=2)+beta5_ACR*lg_b_ACR;
	 ll_Y_ACR = ACR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((delta_lg_ACR - mu_ACR)**2)/(var_ACR) 
	                        - 0.5*log(var_ACR) );
	%end; 
	/*---------------- End of modeling ACR ----------------*/

	/*------------------------------------------------------ 
             Modeling mean baseline eGFR (intercept) 
	-------------------------------------------------------*/
	%if %index(&bGFR, YES) %then %do;
     mu_bGFR=beta0_bGFR;
	 ll_Y_bGFR = bGFR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((b_CKDegfr - mu_bGFR)**2)/(var_bGFR) 
	                        - 0.5*log(var_bGFR) );
	%end; 
   /*---------------- End of modeling bGFR ----------------*/


   /*--------------------------------------------------------
             Modeling mean Log ACR: intercept only           
	-------------------------------------------------------*/
	%if %index(&Log_ACR, YES) %then %do;
     mu_Log_ACR=beta0_Log_ACR;
	 ll_Y_Log_ACR = Log_ACR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((blogacr - mu_Log_ACR)**2)/(var_Log_ACR) 
	                        - 0.5*log(var_Log_ACR) );
	%end; 
   /*------------ End of modeling mean Log ACR ------------*/

   /*--------------------------------------------------------
             Modeling delta GFR acute treatment effect 
             assuming 2 treatment levels with level 1
	         serving as the reference
	-------------------------------------------------------*/
	%if %index(&Acute_GFR, YES) %then %do;
     mu_Acute_GFR=beta0_Acute_GFR+beta12_Acu_GFR*(TrtID=2)+ beta5_Acute_GFR*gfr0c;
	 ll_Y_Acute_GFR = Acute_GFR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((gfrdiff - mu_Acute_GFR)**2)/(var_Acute_GFR) 
	                        - 0.5*log(var_Acute_GFR) );
	%end; 
    /*----- End of modeling delta GFR acute trt effect ----*/


	%if %index(&SP, YES) %then %do;
     eta1 = eta11*(TrtID=1);

     /*============================================================================= 
	            WEIBULL shape, scale and lambda parameters in LIFEREG 
              when one models the log-likelihood of the WEIBULL directly
      SHAPE = gamma (a parameter input)
      SCALE = sigma = 1/gamma
	  lambda_i = exp(-(eta0 + eta1*X1 + eta2*X2 +...+ etap*Xp)/sigma)
               = exp(-eta_i/sigma) where eta0, eta1, etc, are parameter inputs
     =============================================================================*/
*	 sigma=1/gamma;
*	 eta_i = eta01 + eta1;
*	 lambda_i = exp(-eta_i/sigma);
 
	 /*============================================================================= 
	             Hazard function, h(t), under the LIFEREG Weibull model 
	  h(t) = f(t)/S(t) = gamma*lambda_i*(t**(gamma-1))
	                   = gamma*(exp(-eta_i/sigma)*(t**(gamma-1))
	 =============================================================================*/
*	 hazard_i = gamma*lambda_i*(EventTime**(gamma-1)); 

     /*============================================================================= 
	                    PDF, f(t), under the LIFEREG Weibull model 
      f(t) = gamma*lambda_i*(t**(gamma-1))*exp(-lambda_i*(t**gamma))
           = hazard_i*exp(-lambda_i*(t**gamma))
	 =============================================================================*/
*	 pdf_i = hazard_i*exp(-lambda_i*(EventTime**gamma));

	 /*============================================================================= 
	            Survival function, S(t), under the LIFEREG Weibull model 
	  S(t) = exp(-lambda_i*(t**gamma))
	 =============================================================================*/
*     survival_i = exp(-lambda_i*(EventTime**gamma));

	 /*=============================================================================
	    ll_T is the conditional log-likelihood of the Weibull distribution for 
	    T = EventTime. We use indicator=1 to select the single observation for a 
	    given subject containing the correct time to dropout variables EventTime and 
	    Outcome where Outcome is an indicator of whether the event occured. The 
        value of ll_T = log( [f(t)**delta]*[S(t)**(1-delta)] ) 
	                  = delta*log(f(t) + (1-delta)*log(S(t))
                      = Outcome*log(hazard_i) -(lambda_i*(EventTime**gamma)) 
	    where delta is the censoring variable = 1 if event occured and 0 if 
	    censored which in this case is delta = Outcome. f(t) and S(t) are as 
	    defined above for the Weibull model as parameterized in LIFEREG. Note that
	    we would include b0i, b1i and b2i as latent random effect covariates in the
	    shared parameter (SP) model as a means of adjusting for informative censoring. 
	 ==============================================================================*/ 
	*ll_T = indicator*( Outcome*log(hazard_i) -(lambda_i*(EventTime**gamma)) );   


     /*============================================================================= 
	           EXTREME VALUE shape, scale and mean (mu) parameters in LIFEREG 
      SHAPE = gamma (a parameter input)
      SCALE = _sigma_ = 1/gamma
	  Mu    = (eta0 + eta1*X1 + eta2*X2 +...+ etap*Xp) = X`Eta = eta_i
     =============================================================================*/
 
 	 _sigma_=1/gamma;      ** Scale parameter for Weibull based on log(T);

 	 ************ HR of treatment is adjusted by log(baseline eGFR) ***************;
	 eta_i = eta01 + eta1 +eta6*lg_b_CKDegfr+ eta_b0i*u0i + eta_b1i*u1i ; 
	 ******************************************************************************;
     ******* The interval log hazard rate per unit of time for SP Model 2. *********
             Note the SP covariates u1i and u2i have different variances when
             we assume a proportional effect on the randon slope variances
	 ******************************************************************************; 

	 /*============================================================================= 
	                     EXTREME VALUE DISTRIBUTION log(T)
	       Hazard function, h(w), under the LIFEREG Weibull model for w=log(T)
	  h(w) = (1/sigma)* exp((w - mu_w)/sigma)
	       = (1/sigma)* exp((w-eta_i)/sigma) where w=log(t)
	 =============================================================================*/
 	 hazard_i = (1/_sigma_)*exp((Log_RiskTime - eta_i)/_sigma_);
 
	 /*============================================================================= 
	                Hazard Ratios under the LIFEREG Weibull model 
	  Let X be a covariate and let X`Eta = eta0 + eta1*X. Then based on the actual
      Weibull hazard function where sigma=1/gamma, 
	    h(t,X) = gamma*(exp((-eta0-eta1*X)/sigma)*(t**(gamma-1))
	           = exp(-X`Eta/sigma)*gamma*(t**(gamma-1))
	  the hazard ratio for X=x relative to X=0 is given by 
	    HR(X=x|X=0)) = h(t|X=x)/h(t|X=0) = exp((-eta0-eta1*x)/sigma)/exp((-eta0)/sigma)	
                                         = exp(-eta1*x/sigma) 
      Hence the hazard ratio is 
        HR(TrtID=1|TrtID=2)=exp(-eta11/sigma) when we have two treatment groups
	  where TrtID=2 is the reference group in our models for two groups
                                       or
        HR(TrtID=1|TrtID=4)=exp(-eta11/sigma) when we have four treatment groups 
        HR(TrtID=2|TrtID=4)=exp(-eta12/sigma) when we have four treatment groups 
        HR(TrtID=3|TrtID=4)=exp(-eta13/sigma) when we have four treatment groups 
	  where TrtID=4 is the reference group in our models for four groups
                                       etc. 
	 =============================================================================*/


     /*============================================================================= 
	                     EXTREME VALUE DISTRIBUTION log(T)
	            PDF, f(w), under the LIFEREG Weibull model for w=log(T)
      f(w) = (1/sigma)* exp((w - mu_w)/sigma)*exp(-exp((w - mu_w)/sigma))
	       = hazard_i*exp(-sigma*hazard_i)
	 =============================================================================*/
 	 pdf_i = hazard_i*exp(-_sigma_*hazard_i);

	 /*============================================================================= 
	            Survival function, S(t), under the LIFEREG Weibull model 
	  S(t) = exp(-exp((w - mu_w)/sigma))
	       = exp(-sigma*hazard_i)
	 =============================================================================*/
     survival_i = exp(-_sigma_*hazard_i);

	 /*=============================================================================
	    ll_logT is the conditional log-likelihood of the extreme value distribution 
	    corresponding to the Weibull distribution when we model log(T) rather than T 
	    where log(T) = log(EventTime) is what is modeled using the LIFEREG procedure. 
	    We use indicator=1 to select the single observation for a given subject  
	    containing the correct time to dropout variable EventTime and 
	    Outcome where Outcome is an indicator of whether the event occured. The 
        value of ll_logT = log( [f(t)**delta]*[S(t)**(1-delta)] ) 
	                     = delta*log(f(t) + (1-delta)*log(S(t))
                         = Outcome*log(hazard_i) - sigma*hazard_i) 
	    where delta is the censoring variable = 1 if event occured and 0 if 
	    censored which in this case is delta = Outcome. f(w) and S(w) are as 
	    defined above for the Weibull model as parameterized in LIFEREG on the log
	    scale (i.e., using the extreme value distriubution). Note that
	    we would include b0i, b1i and b2i as latent random effect covariates in the
	    shared parameter (SP) model as a means of adjusting for informative censoring. 
	 ==============================================================================*/ 
	 ll_logT = indicator*(eventID=0)*( Outcome*log(hazard_i) - _sigma_*hazard_i );   
	%end;

	%if %index(&CE, YES) %then %do;
	 %do jj=1 %to &N_event;
	  %if %index(&&include&jj, YES) %then %do;
	 	**log likelihood of event  jj;
	 	array _ev&jj._eta0_[&&NIntervals&jj] ev&jj._eta01 - ev&jj._eta0&&NIntervals&jj;
	  	array _ev&jj._eta1_[1] ev&jj._eta11;

	 	ev&jj._eta0=0;
	 	ev&jj._eta1=0;

		do j=1 to &&NIntervals&jj;
       	ev&jj._eta0 = ev&jj._eta0 + _ev&jj._eta0_[j]*(Interval_ID=j); 
	 	end;
	    ev&jj._eta1 =ev&jj._eta1 + _ev&jj._eta1_[1]*(TrtID=1);

	 ev&jj._eta_i = ev&jj._eta0 + ev&jj._eta1;               ** The interval log hazard rate per unit of time for SP Model 1;   
	 ev&jj._lambda_i = exp(ev&jj._eta_i);                    ** The interval hazard rate per unit of time for the PE model; 
	 ev&jj._Hazard_i=ev&jj._lambda_i*RiskTime;               ** The interval hazard rate per months at risk for the PE model; 
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
	 ev&jj._ll_T = indicator*(eventID=&jj )*( Outcome*(ev&jj._eta_i) - 
                        ev&jj._lambda_i*RiskTime );   ** The Piecewise Exponential log L function for modeling the 
						                                 variable T = EventTime= time to dropout conditional on a
						                                 set of random effects b fopr functions f(b) of random effects;
	**************end *********************;
	  %end;
	 %end;
	%end;
	ll = ll_Y 
	%if %index(&ACR, YES) %then %do;
     + ll_Y_ACR
	%end;
	%if %index(&bGFR, YES) %then %do;
     + ll_Y_bGFR
	%end;
	%if %index(&Log_ACR, YES) %then %do;
     + ll_Y_Log_ACR
	%end;
	%if %index(&Acute_GFR, YES) %then %do;
     + ll_Y_Acute_GFR
	%end;
	%if %index(&SP, YES) %then %do;
	 + ll_logT 
	%end;
	%if %index(&CE, YES) %then %do;
	 %do kkk=1 %to &N_event;
	    %if %index(&&include&kkk, YES) %then %do;
	      + ev&kkk._ll_T  
		%end;
	 %end;
	%end;
	;
	 model response ~ general(ll);                    ** response = eGFR for indicator=0 and EventTime*(Outcome) for indicator=1; 
	%if %index(&PSI21, NO) %then %do;
	 psi21=0;
	%end;
	 random b0i b1i  ~ Normal( [0,0], 
                               [psi11, 
                                psi21, psi22]
                               ) subject=Subject;******!!!!!!!!***********;
 
	    estimate "beta01" (beta01);                         /* EFV added this on 01/12/2023 */
	    estimate "beta02" (beta02);                         /* EFV added this on 01/12/2023 */
	    estimate "beta11" (beta11)*12;
	    estimate "beta12" (beta12)*12;
	    estimate "beta02 - beta01" (beta02 - beta01);
	    estimate "beta12 - beta11" (beta12 - beta11)*12;
	    estimate "beta12/beta11" beta12/beta11;             /* EFV added this on 12/16/2022 */

	   *estimate "log(beta12/beta11)" log(beta12/beta11);   /* EFV removed this estimate as 
                                                               study 2 (and perhaps others)  
                                                               had beta12>0, beta11<0 with no
		                                                       way to check this in NLMIXED  
		                                                       resulting in a termination of 
		                                                       pgm with no added estimates. */
	%if %index(&QUAD, YES) %then %do;
	    estimate "beta21" (beta21);                         /* EFV added this on 01/12/2023 */
	    estimate "beta22" (beta22);                         /* EFV added this on 01/12/2023 */
	    estimate "beta22 - beta21" (beta22 - beta21);       /* EFV added this on 01/12/2023 */
	%end;
	%if %index(&SP, YES) %then %do;
		estimate "LogHR( TrtID=2 : TrtID=1 )" eta11*gamma;   
	                                                  ** Equivalent to logHR which we then exponentiate the conf. limits;
		estimate "LogHR(b0i)"  -eta_b0i*gamma;  
		estimate "LogHR(b1i)"  -eta_b1i*gamma/12;     ** This is correct! it should not be -eta_b1i*gamma*12 -Jian;
	%end;
	%if %index(&ACR, YES) %then %do;
        estimate "Trtment effect in ACR change" beta12_ACR;
		estimate "Control ACR change" beta0_ACR; /** HT added on 3/20/2023 **/
        estimate "Treated ACR change" beta0_ACR+beta12_ACR; /** HT added on 3/20/2023 **/
	%end;
	%if %index(&Log_ACR, YES) %then %do;
        estimate "Mean Log ACR" beta0_Log_ACR;
	%end;
	%if %index(&CE, YES) %then %do; 
	 %do iii=1 %to &N_event;
	  %if %index(&&include&iii, YES) %then %do;
	  	estimate "LogHR( TrtID=2 : TrtID=1 ) for event &iii" -ev&iii._eta11 ;   
	  %end;
	 %end;
	%end;
	%if %index(&Proportional, YES) %then %do;
	    estimate "kappa" kappa;
	 %if %index(&BOUNDS, YES) %then %do;
	    estimate "Log(1+kappa)" log(1+kappa);               /* EFV modified this on 01/26/2023 */
	 %end;
	%end;
	%if %index(&bGFR, YES) %then %do;
        estimate "Mean Baseline GFR" beta0_bGFR;
	%end;
	%if %index(&Acute_GFR, YES) %then %do;
        estimate "Trtment effect in delta GFR acute" beta12_Acu_GFR;
	%end;
	/* Additional Estimates not shown above */
	%NewEstimates;                                         /* EFV revised the macro on 01/12/2023 */
	id Study TrtID u0i u1i b0i b1i beta0: beta1: psi: 
       sigma var mu mu_i Hazard_i
	 %if %index(&SP, YES) %then %do; eta: %end;
	 %if %index(&POM, SS) or %index(&POM, PA) or %index(&POM, POX) %then %do; theta %end;
	 %if %index(&Proportional, YES) %then %do; kappa %end;  
	;  
 	predict var out=temp.SP_PE_pred0 DER;
	run;

	%EFV_IML_Code;

%mend model;

* This macro checks if any model-based standard errors are missing indicating a problem with Hessian
  and it merges convergence status and last value of iteration history such if XCONV is achieved but
  the value of Iter =1 (indicating no iterations after starting value) then Status is changed to 1 
  within dataset temp.SP_PE_cs0 - EFV;
%macro Original_Check_Hessian;
	data temp.Check_Hessian;
	 set temp.SP_PE_pe0;
	run;
	proc sort data=temp.Check_Hessian;
	 by se_model_based;
	run;
	data temp.Check_Hessian;
	 set temp.Check_Hessian;
	 by se_model_based;
	 if _n_=1;
	run;

	data temp.Check_Hessian;
	 set temp.Check_Hessian;
	 StdErrors_Missing="NO ";
	 if se_model_based=. then StdErrors_Missing="YES";
	 keep StdErrors_Missing;
	run;
	data temp.SP_PE_iter0;
	 set temp.SP_PE_iter0 end=last;
	 if last; 
	run;
*	proc print data=temp.SP_PE_iter0;run;
	data temp.SP_PE_cs0;
	 merge temp.SP_PE_cs0 temp.SP_PE_iter0;
	 if Reason='NOTE: XCONV convergence criterion satisfied.' and Iter=1 then Status=1;
	run;
*	proc print data=temp.SP_PE_cs0;run;
	data temp.Check_Hessian;
	 merge temp.Check_Hessian temp.SP_PE_cs0;
	 if Status_H=0 then Hessian='Hessian is p.d. with no issues            ';
	 if Status_H=1 then Hessian='Hessian is not p.d. or has eigenvalue(s)<0';
	run;
%mend Original_Check_Hessian;


* This macro checks if any model-based standard errors are missing indicating a problem with Hessian
  and it merges convergence status and last value of iteration history such if XCONV is achieved but
  the value of Iter =1 (indicating no iterations after starting value) then Status is changed to 1 
  within dataset temp.SP_PE_cs0 - EFV;
%macro Check_Hessian;
	data temp.Check_Hessian;
	 set temp.SP_PE_pe0;
	run;
	proc sort data=temp.Check_Hessian;
	 by StandardError;
	run;
	data temp.Check_Hessian;
	 set temp.Check_Hessian;
	 by StandardError;
	 if _n_=1;
	run;
	data temp.Check_Hessian;
	 set temp.Check_Hessian;
	 StdErrors_Missing="NO ";
	 if StandardError=. then StdErrors_Missing="YES";
	 keep StdErrors_Missing;
	run;

	data temp.SP_PE_iter0;
	 set temp.SP_PE_iter0 end=last;
	 if last; 
	run;
*	proc print data=temp.SP_PE_iter0;run;
	data temp.SP_PE_cs0;
	 merge temp.SP_PE_cs0 temp.SP_PE_iter0;
	 if Reason='NOTE: XCONV convergence criterion satisfied.' and Iter=1 then Status=1;
	run;
*	proc print data=temp.SP_PE_cs0;run;
	data temp.Check_Hessian;
	 merge temp.Check_Hessian temp.SP_PE_cs0;
	 if Status_H=0 then Hessian='Hessian is p.d. with no issues            ';
	 if Status_H=1 then Hessian='Hessian is not p.d. or has eigenvalue(s)<0';
	run;
%mend Check_Hessian;


%macro obsnumber(dataset);
%global nobs;
%let dsid=%sysfunc(open(&dataset));
%if &dsid %then %do;
%let nobs=%sysfunc(attrn(&dsid,nobs));
%let rc=%sysfunc(close(&dsid));
%end;
%eval(&nobs)
%mend;

%MACRO Check_PSI(study=);
	data temp;
	 set Results.pe&study;
	run;
	proc print data=temp;run;
	data psi11;
	 set temp;
	 if Parameter='psi11';
	 PSI11=Estimate;
	 keep Study Tech SP POM PE SP PROP Knot PSI11;
	run;
	data psi21;
	 set temp;
	 if Parameter='psi21';
	 PSI21=Estimate;
	 keep Study Tech SP POM PE SP PROP Knot PSI21;
	run;
	data psi22;
	 set temp;
	 if Parameter='psi22';
	 PSI22=Estimate;
	 keep Study Tech SP POM PE SP PROP Knot PSI22;
	run;

	%if %index(&PROP, YES) %then %do;
	data kappa;
	 set temp;
	 if Parameter='kappa';
	 Kappa=Estimate;
	 keep Study Tech SP POM PE SP PROP Knot Kappa;
	run;
	%end;

	data PSI_&study;
	 %if %index(&PROP, YES) %then %do;
	 merge PSI11 PSI21 PSI22 Kappa;
	 %end;
	 %if %index(&PROP, NO) %then %do;
	 merge PSI11 PSI21 PSI22 ;
	 %end;
	 Corr21 = PSI21/(sqrt(PSI11)*sqrt(PSI22));
	 if Kappa=. then Kappa=0;
	 Phi = (1+Kappa)**2;
	 Var_b0 = PSI11;
	 Var_b1 = PSI22;
	 Var_b1_phi = Phi*PSI22;
	run;
	proc print data=PSI_&study;
	run;
%mend;

%macro run_model(study=1,Nloptions=%str(tech=NRRIDG maxiter=100 maxfunc=1000 qpoints=1));

	/* Remove measurements before 3 months and run macro Truncate */
	data temp.study;
	 set studies;
	 if   Study= &study  and  Month>=3; 
	run;
	%Truncate;
	proc sort data=temp.study; 	
	 by subject Month; 
	run;
	data temp.study;
	 set temp.study;
	 by subject Month;
	 if first.subject then visit=0;
	 visit+1;
	run;
	/* Determine whether to run SP or POM */
	proc tabulate data=temp.study out=temp.dx_count;
	var ev_dx;
	table sum*ev_dx;
	where visit=1;
	run;

	data temp.dx_count;
	set temp.dx_count;
	if ev_dx_Sum>=&SP_threshold then SP="YES"; else SP="NO";
	call symput("SP",left(SP)); 
	run;
	%put "run SP? " &SP;
	/* End */
	%Getdata_SP;
	%Getparam_SP;

	/*=============================================*/
	/* This %DO is new as of March 24, 2022 by EFV */
	/* It was added as running macro Check_CE will */
	/* automatically set CE=YES or NO based on data*/ 
	/* If CE=NO was defined in InitialModelOptions */
	/* then macro Check_CE will not be run per EFV */
	/*=============================================*/
	%if %index(&CE, YES) %then %do;
	%Check_CE;
	%end;

	%if %index(&CE, YES) %then %do;
	%do ev_id=1 %to &N_event;
	 %CountEvent(EventID_C=&ev_id );
	 %if %index(&&include&ev_id, YES) %then %do;
		%StudyDescrip(EventID=&ev_id);
		%Getdata_PE(EventID=&ev_id );
		%getparam_PE(EventID=&ev_id);
	 %end;
	 %else %do;
	   data temp.Parms_pe&ev_id;
	    set _NULL_;
	   run;
	   data temp.Study_event_pe&ev_id;
	    set _NULL_;
	   run;
	 %end;
	%end;
	%end;
	%merge_data;
	%if %index(&ACR, YES) %then %do;
	%getparam_ACR;
	%end;
	%if %index(&bGFR, YES) %then %do;
	%getparam_bGFR;
	%end;
	%if %index(&Log_ACR, YES) %then %do;
	%getparam_LgACR;
	%end;
	%if %index(&Acute_GFR, YES) %then %do;
	%getparam_Acute_GFR;
	%end;
	%mergeParms;
	%model(Nloptions=&Nloptions);
	%Check_Hessian;
%mend run_model;

%macro doall(studyid);
** Delete temporary datasets created during a single run of macros for a given study **;
proc datasets lib=temp nolist kill;
run;
quit;
proc datasets lib=temp2 nolist kill;
run;
quit;
proc datasets nolist;
*delete Hessian matrix beta HessData HessOut est label se_model; ** Jiam IML Code creates these temp datasets;
 delete Hessian HessData HessOut SP_PE_pe0 SP_PE_est0
        Derivatives RobustCov RobustCorr;                        ** EFV IML code creates these temp datasets;
run;
quit;
proc datasets nolist;
 delete start1 end1;
run;
quit;

data start1;
 starttime=datetime();
 format starttime datetime.;
 study=&studyid;
run;

/*===============================================
  Hierarchy of modified 1-slope eGFR models
  obtainsed when macro variable HESS=YES
===============================================*/


/*===============================================
eGFR Model 1: POM = SS, 
              Proportional = YES (Kappa estimated)
              SP  = YES if >=15 ESRD/Deaths 
              SP  = NO  if <15 ESRD/Deaths  
================================================*/
%let tech1=NRRIDG;
%run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
%let tech1=DBLDOG;
%run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
%end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

/*===============================================
eGFR Model 2: POM = SS_POM 
              Proportional = NO (Kappa estimated)
              SP  = YES if >=15 ESRD/Deaths 
              SP  = NO  if <15 ESRD/Deaths  
================================================*/
%if %index(&HESS, YES) and %index(&POM, SS) and %index(&Proportional, YES) %then %do;
 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let POM=SS;
  %let Proportional=NO;
  %let tech1=NRRIDG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let tech1=DBLDOG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%end;
/*===============================================
eGFR Model 3: POM = POX (Power-of-X), 
              Proportional = YES (Kappa estimated)
              SP  = YES if >=15 ESRD/Deaths 
              SP  = NO  if <15 ESRD/Deaths  
================================================*/
%if %index(&HESS, YES) and %index(&POM, SS) and %index(&Proportional, NO) %then %do;
 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let POM=POX;
  %let Proportional=YES;
  %let tech1=NRRIDG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let tech1=DBLDOG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%end;
/*===============================================
eGFR Model 4: POM = POX, (Power-of-X) 
              Proportional = NO (Kappa = 0)
              SP  = YES if >=15 ESRD/Deaths 
              SP  = NO  if <15 ESRD/Deaths  
================================================*/
%if %index(&HESS, YES) and %index(&POM, POX) and %index(&Proportional, YES) %then %do;
 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let Proportional=NO;
  %let tech1=NRRIDG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let tech1=DBLDOG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%end;
/*===============================================
eGFR Model 5: POM = NO, 
              Proportional = YES (Kappa estimated)
              SP  = YES if >=15 ESRD/Deaths 
              SP  = NO  if <15 ESRD/Deaths  
================================================*/
%if %index(&HESS, YES) and %index(&POM, POX) and %index(&Proportional, NO) %then %do;
 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let POM=NO;
  %let Proportional=YES;
  %let tech1=NRRIDG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let tech1=DBLDOG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%end;
/*===============================================
eGFR Model 6: POM = NO, 
              Proportional = NO (Kappa = 0)
              SP  = YES if >=15 ESRD/Deaths 
              SP  = NO  if <15 ESRD/Deaths  
================================================*/
%if %index(&HESS, YES) and %index(&POM, NO) and %index(&Proportional, YES) %then %do;
 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let POM=NO;
  %let Proportional=NO;
  %let tech1=NRRIDG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let tech1=DBLDOG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%end;
/*===============================================
eGFR Model 7: POM = NO, 
              Proportional = NO (Kappa = 0)
              SP  = NO  (SP component is dropped)     
================================================*/
%if %index(&HESS, YES) and %index(&POM, NO) and %index(&Proportional, NO) %then %do;
 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let SP_threshold=10000;  ** This will force macro variable SP to be NO within call to macro run_model;
  %let tech1=NRRIDG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let tech1=DBLDOG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%end;
/*===============================================
eGFR Model 8: POM = NO, 
              Proportional = NO (Kappa = 0)
              SP  = NO  (SP component is dropped)
              PSI21 = NO (correlation(b1i b2i)=0
================================================*/
%if %index(&HESS, YES) and %index(&POM, NO) and %index(&Proportional, NO) %then %do;
 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let SP_threshold=10000;  ** This will force macro variable SP to be NO within call to macro run_model;
  %let PSI21=NO;             ** This forces 0 correlation between random intercept and random slope;
  %let tech1=NRRIDG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

 %if %EVAL(&Status)=1 or %EVAL(&Status_H)=1 %then %do;
  %let tech1=DBLDOG;
  %run_model(study=&studyid,Nloptions=%str(tech=&tech1 maxiter=200 maxfunc=2000 qpoints=1));
 %end;

%if %eval(%sysfunc(exist(temp.SP_PE_cs0)))=1 and %eval(%obsnumber(temp.SP_PE_cs0)>0) %then %do;
data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 call symput('Status',left(Status)); 
run;
%end;
%else %do;
%let Status=1;
%end;
%if %eval(%sysfunc(exist(temp.Check_Hessian)))=1 and %eval(%obsnumber(temp.Check_Hessian)>0) %then %do;
data temp.Check_Hessian;
 set temp.Check_Hessian;
 call symput('Status_H',left(Status_H)); 
run;
%end;
%else %do;
%let Status_H=1;
%end;

%end;

data temp.SP_PE_ic0;
 set temp.SP_PE_ic0;
 if _n_=1 then set temp.Check_Hessian;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.ic&studyid;
 set temp.SP_PE_ic0;
run;

data temp.SP_PE_pe0;
 set temp.SP_PE_pe0;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.pe&studyid;
 set temp.SP_PE_pe0;
run;

data temp.SP_PE_est0;
 set temp.SP_PE_est0;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.est&studyid;
 set temp.SP_PE_est0;
run;

data temp.SP_PE_cs0;
 set temp.SP_PE_cs0;
 if _n_=1 then set temp.Check_Hessian;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.cs&studyid;
 set temp.SP_PE_cs0;
run;

data temp.SP_PE_der;
 set temp.SP_PE_der;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.der&studyid;
 set temp.SP_PE_der;
run;


data temp.SP_PE_emp_cor;
 set temp.SP_PE_emp_cor;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.cor&studyid;
 set temp.SP_PE_emp_cor;
run;

data temp.SP_PE_emp_cov;
 set temp.SP_PE_emp_cov;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.cov&studyid;
 set temp.SP_PE_emp_cov;
run;

data temp.SP_PE_pred0;
 set temp.SP_PE_pred0;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 BOUNDS="&BOUNDS";
 CORR="&PSI21";
 QUAD="&QUAD";
 TRUNC="&TRUNC";
 TRUNCATE="&TRUNCATE";
 bGFR="&bGFR";
 Log_ACR="&Log_ACR";
 Acute_GFR="&Acute_GFR";
run;
data results.pred&studyid;
 set temp.SP_PE_pred0;
run;

data Study_SP_PE;
 set temp.Study_SP_PE;
run;

proc datasets lib=temp nolist kill;
run;
quit;

data end1;
 endtime=datetime();
 format endtime datetime.;
run;
data results.corr_runtime_study&studyid;
 merge start1 end1;
 hours=(endtime/(60*60))-(starttime/(60*60));
run;
proc datasets nolist;
 delete start1 end1;
run;
quit;

proc datasets lib=temp2 nolist kill;
run;
quit;
/*
proc datasets nolist;
 delete Hessian HessData HessOut SP_PE_pe0 SP_PE_est0 
        Derivatives RobsutCov RobustCorr;  
run;
*/
quit;
%mend doall;

%macro initialize_studies(k);
data results.pe&k;
 set _null_; 
run;
data results.est&k;
 set _null_; 
run;
data results.cs&k;
 set _null_; 
run;
data results.cor&k;
 set _null_; 
run;
data results.corr_runtime_study&k;
 set _null_; 
run;
%mend initialize_studies;

%macro zinitialize_studies(k);
data results.pe&k;
 set _null_; 
run;
data results.est&k;
 set _null_; 
run;
data results.cs&k;
 set _null_; 
run;
data results.cor&k;
 set _null_; 
run;
data results.cov&k;
 set _null_; 
run;
data results.corr_runtime_study&k;
 set _null_; 
run;
data results.ic&k;
 set _null_; 
run;
%mend zinitialize_studies;

