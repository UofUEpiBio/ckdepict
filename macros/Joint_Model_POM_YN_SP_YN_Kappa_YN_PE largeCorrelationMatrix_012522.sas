*this macro checks whether we have necessary number of clinical events for all 9 event types for a given study;
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
*this macro count event&EventID_C, if the event count is less than 6, assign value NO to macro variable include&EventID_C, otherwise YES;
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
*if c>5 and c1>0 and c2>0 then include&EventID_C ="YES"; ** OLD CODE;
if c>9 and c1>1 and c2>1 then include&EventID_C ="YES";  ** NEW CODE;
else include&EventID_C ="NO";
call symput("include&EventID_C",left(include&EventID_C)); 
run;
%put include&EventID_C=&&include&EventID_C;
%mend;
* %CountEvent(EventID_C=6 );

*this macro generate summarization statistics needed to find out interval number and also generate  interval number;
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
	          NOTE: The number of PE intervals is chosen to give a target of approximately 
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
	drop Patients--NIntervals; *drop those varibles from last event so it can be replaced by those of the new events;
	run;
	data temp.study;
	 merge temp.study temp.StudyDescrip;
	 by Study;
	run;
%mend StudyDescrip;

*this macro generates data for the SP model;
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

	 /* The following ensures that Interval_ID,  
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
 	 if last.Subject;
  	 NIntervals=1;Interval_ID=1;t1=0; t2=0;  fu_CKDegfr =0;
	 keep Study Subject Indicator eventID Visit Month b_CKDegfr b_CKDegfr_Mean fu_CKDegfr 
          lg_b_CKDegfr delta_lg_ACR lg_b_ACR  blogacr gfrdiff gfr0c  TrtID   
          t1 t2 RiskTime Log_RiskTime Outcome NIntervals Interval_ID;
	run;

	/* Create a dataset for a given study suitable for a SP model with a WEIBULL survival component */
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

*this macro generates the dataset for PE model of a time to event outcome specified by the parameter EventID;
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

*get params for SP model;
%macro getparam_SP;
ods output ConvergenceStatus=temp2.cs1  SolutionF=temp2.pe1  CovParms=temp2.cov1 InfoCrit=temp2.ic1; 
	proc mixed data=temp.Study_eGFR ic method=ML cl;
	 class Subject TrtID;
	 model fu_CKDegfr = TrtID Month*TrtID b_CKDegfr Month*b_CKDegfr/ s noint; *both intercept and slope are adjusted by baseline eGFR by adding b_CKDegfr Month*b_CKDegfr;
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
*	 title "Initial Starting Values";
	run;
	 /*=====================================================================================================
	   The following code computes the initial parameter estimates for a proportional hazards Weibull model 
	   using LIFEREG. It creates a SAS dataset containing the initial parameters representing the log hazard 
	   ratios for the various BP by Treatment combinations that a particular study investigated. These 
	   estimates are obtained using LIFREG. There are two possible choices for the starting values.
          2) Use final MLE estimates as computed using LIFEREG based on the starting OLS values in 1) above 
	 ======================================================================================================*/  

	ods output ParameterEstimates= temp2.ParmsSurvModel_WEIBULL_MLE;
	proc lifereg data=temp.Study_Event;
	 class TrtID; 
	 model RiskTime*Outcome(0) = TrtID lg_b_CKDegfr/ distribution=WEIBULL;  *HR of treatment is adjusted by log(baseline eGFR);
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
	 data temp.sp_parms  ;
	 set temp.sp_parms  ;
	 *assign default value for theta and eta;
	   %if %index(&SP, YES) %then %do;
	    eta_b0i=0.03;
        eta_b1i=1.5;  
       %end;
	run;

	*delete all intermediate data;
	proc datasets lib=temp2  nolist kill;
	quit;
%mend getparam_SP;

*get params for PE model;
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

*get params for ACR model;
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

*get params for ACR model using ANCOVA ML estimates - EFV alternative;
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
*	proc print data=temp.PE_ACR;run;
  
	proc datasets lib=temp2  nolist kill;
	quit;
%mend  getparam_ACR_EFV;




*get params for log ACR model;
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




*get params for bGFR model;
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




*get params for Acute GFR change model;
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
	 if Variable='Intercept'   then Parameter="beta0_Acute_GFR"; 
	 if Variable='TrtID'   then Parameter="beta12_Acu_GFR"; 
	 if Variable='gfr0c'   then Parameter="beta5_Acute_GFR"; 
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


%macro merge_data;
	 /*=====================================================================================================
	   The following code creates the  dataset temp.Study_SP_PE for when the PE model is used for survival. 
	 ======================================================================================================*/  
	/* Create a dataset for a given study suitable for a SP model with a PE survival component */
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
   *prepare ACR data;

    data  temp.baselinedata;
	 set  temp.Study_SP_PE;
	 by subject;
	 Indicator=1;  EventID=-1; *by assiging these values, those records will not be used in modeling eGFR, and clinical events;
	 if missing(fu_CKDegfr) then fu_CKDegfr=0;
     if  first.subject; *only the first row is going to be used for modeling ACR;
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
    *prepare mean GFR data;
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


	*prepare Log ACR data;
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


	*prepare delta GFR acute data;
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

%else %do;
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

%MACRO NewEstimates;
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
	  *treatment effect in terms of slope in acute phase (Tom told me to do this way, but I also added that in terms of  eGFR value below) ;
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
%mend NewEstimates;

**EFV modified POM global options to be NO, SS, or PA - see GLOBAL macro variables setup **;
%macro model(Nloptions=%str(tech=NRRIDG maxiter=300 maxfunc=1000 qpoints=1)); 
%put TECH= &TECH POM= &POM, ACR= &ACR, CE= &CE, Proportional=&Proportional, PSI21= &PSI21, HESS= &HESS, SP_threshhold=&SP_threshold;
%if %index(&PSI21, NO) %then %do;
 data temp.sp_parms;
  set temp.sp_parms;
  drop psi21;
 run;
%end;

proc sort data=temp.Study_SP_PE; 
 by subject eventID month; 
run;

ods output     Hessian= Hessian
               IterHistory=temp.SP_PE_iter0
               ConvergenceStatus=temp.SP_PE_cs0
               FitStatistics=temp.SP_PE_ic0 
               ParameterEstimates= temp.SP_PE_pe0 
               AdditionalEstimates=temp.SP_PE_est0
			   CorrMatAddEst  =temp.SP_PE_est0_cor;

ods exclude Hessian CovMatAddEst CovMatParmEst;   ** EFV added the exclude so as to minimize output **;
proc nlmixed data=temp.Study_SP_PE  &nloptions EMPIRICAL HESS ECORR COV NOSORTSUB ZNLP;
	 parms /data=temp.sp_parms best=1;            ** EFV added in Best=1 so as to minimize output **; 
	 array _beta0_[2] beta01 - beta02;
	 array _beta1_[2] beta11 - beta12;
	 beta0=0;
	 beta1=0;
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
	   beta0  = beta0  + _beta0_[k]*(TrtID=k); ** PA intercept as a linear function of BP x Trt effects; 
	   beta1  = beta1  + _beta1_[k]*(TrtID=k); ** PA acute slope as a linear function of BP and Trt effects;
	 end;
	 beta0i = beta0 + u0i;                     ** SS intercept as a linear function of BP x Trt effects; 
	 beta1i = beta1 + u1i;                     ** SS acute slope as a linear function of BP and Trt effects;

	 mu = beta0+beta1*Month+beta5*b_CKDegfr+beta6*Month*b_CKDegfr;     ** PA predicted mean response over time as a linear function of BP and Trt,both intercept and slope are adjusted by baseline eGFR by adding b_CKDegfr Month*b_CKDegfr;
	 mu_i = beta0i+beta1i*Month+beta5*b_CKDegfr+beta6*Month*b_CKDegfr; ** SS predicted mean response over time as a linear function of BP and Trt;
	%if %index(&POM, SS) %then %do;
     var = (sigma/100)*((mu_i**2)**theta);       ** SS Intra-subject variance function with rescaled sigma;
    *var = (sigma)*((mu_i**2)**theta);           ** SS Intra-subject variance function with un-scaled sigma;
    %end; 
	%if %index(&POM, PA) %then %do;
     var = (sigma/100)*((mu**2)**theta);         ** PA Intra-subject variance function with rescaled sigma;
    *var = (sigma)*((mu**2)**theta);             ** PA Intra-subject variance function with un-scaled sigma;
    %end; 
	%if %index(&POM, POX) %then %do;
     var = (sigma/100)*exp(theta*Month); 
    *var = (sigma)*exp(theta*Month); 
	                                             ** Power-of-X (POX) structure preserving 1st and 2nd order orthogonality;
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
      Note that b0i, b1i and b2i are the random intercept
	  and random slope parameters.
	 ===================================================*/ 
	 ll_Y = (1-indicator)*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((fu_CKDegfr - mu_i)**2)/(var) 
	                        - 0.5*log(var) );  ** The Gaussian log L function for modeling the 
							                      variable Y = eGFR conditional on random effects b;

    /*modeling ACR, assuming 2 treatment levels and level 1 as reference****/
	%if %index(&ACR, YES) %then %do;
     mu_ACR=beta0_ACR+beta12_ACR*(TrtID=2)+beta5_ACR*lg_b_ACR;
	 ll_Y_ACR = ACR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((delta_lg_ACR - mu_ACR)**2)/(var_ACR) 
	                        - 0.5*log(var_ACR) );
	%end; 
   /*end modeling ACR, assuming 2 treatmetn levels and level 1 as reference****/

	    /*modeling bGFR, intercept only****/
	%if %index(&bGFR, YES) %then %do;
     mu_bGFR=beta0_bGFR;
	 ll_Y_bGFR = bGFR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((b_CKDegfr - mu_bGFR)**2)/(var_bGFR) 
	                        - 0.5*log(var_bGFR) );
	%end; 
   /*end modeling bGFR****/


	    /*modeling mean Log ACR:, intercept only****/
	%if %index(&Log_ACR, YES) %then %do;
     mu_Log_ACR=beta0_Log_ACR;
	 ll_Y_Log_ACR = Log_ACR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((blogacr - mu_Log_ACR)**2)/(var_Log_ACR) 
	                        - 0.5*log(var_Log_ACR) );
	%end; 
   /*end modeling  mean Log ACR****/


	    /*modeling delta GFR acute, assuming 2 treatment levels and level 1 as reference****/
	%if %index(&Acute_GFR, YES) %then %do;
     mu_Acute_GFR=beta0_Acute_GFR+beta12_Acu_GFR*(TrtID=2)+ beta5_Acute_GFR*gfr0c;;
	 ll_Y_Acute_GFR = Acute_GFR_indicator*( - 0.5*log(2*CONSTANT('PI'))
                            - 0.5*((gfrdiff - mu_Acute_GFR)**2)/(var_Acute_GFR) 
	                        - 0.5*log(var_Acute_GFR) );
	%end; 
   /*end modeling delta GFR acute, assuming 2 treatmetn levels and level 1 as reference****/
 	
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

 	 eta_i = eta01 + eta1 +eta6*lg_b_CKDegfr+ eta_b0i*u0i + eta_b1i*u1i ; ******!!!!!!!!***********HR of treatment is adjusted by log(baseline eGFR);
                           ** The interval log hazard rate per unit of time for SP Model 2.
	                          Note the SP covariates u1i and u2i have different variances when
	                          we assume a proportional effect on the randon slope variances; 

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
 
	%if %index(&ACR, YES) %then %do;
       estimate "trtment effect in ACR change" beta12_ACR;
	%end;
       estimate "beta02 - beta01" (beta02 - beta01);
 	   estimate "beta12 - beta11" (beta12 - beta11)*12;
	   estimate "beta11" (beta11)*12;
	   estimate "beta12" (beta12)*12;
 	   estimate "beta12/beta11"   (beta12/beta11);    /* EFV added this 5/4/2018 */
	  %if %index(&SP, YES) %then %do;
	  	estimate "LogHR( TrtID=2 : TrtID=1 )" eta11*gamma;   
	                                                  ** equivalent to logHR which we then exponentiate the conf. limits;
 

	 	estimate "LogHR(b0i)"  -eta_b0i*gamma;  
	  	estimate "LogHR(b1i)"  -eta_b1i*gamma/12;     ** this is correct! it should not be -eta_b1i*gamma*12 -Jian;
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
	%end;
	%NewEstimates;
	%if %index(&&bGFR, YES) %then %do;
       estimate "Mean Baseline GFR" beta0_bGFR;
	%end;
		%if %index(&Log_ACR, YES) %then %do;
       estimate "Mean lg ACR" beta0_Log_ACR;
	%end;
		%if %index(&Acute_GFR, YES) %then %do;
       estimate "trtment effect in delta GFR acute" beta12_Acu_GFR;
	%end;

	id Study TrtID u0i u1i b0i b1i beta0: beta1: psi: 
       sigma var mu mu_i eta: Hazard_i
	 %if %index(&POM, SS) or %index(&POM, PA) or %index(&POM, POX) %then %do; theta %end;
	 %if %index(&Proportional, YES) %then %do; kappa %end;  
	;  
 	predict var out=temp.SP_PE_pred0 DER;
	run; 

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
*	proc print data=temp.SP_PE_iter0;run;
%mend model;
*%model;

* This macro checks if any model-based standard errors are missing indicating a problem with Hessian
  and it merges convergence status and last value of iteration history such if XCONV is achieved but
  the value of Iter =1 (indicating no iterations after starting value) then Status is changed to 1 
  within dataset temp.SP_PE_cs0 - EFV;
%macro Check_Hessian;
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
data temp.study;
set studies;
if   Study= &study  and  Month>=3; /*remove measurement before 3 months*/;
run;
proc sort data=temp.study; by subject Month; run;
data temp.study;
set temp.study;
by subject Month;
if first.subject then visit=0;
visit+1;
run;
			/*determine to run SP or POM*/
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
 				/*end*/
%Getdata_SP;
%getparam_SP;
%Check_CE;

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
proc datasets lib=temp nolist kill;
run;
quit;
proc datasets lib=temp2 nolist kill;
run;
quit;
proc datasets nolist;
 delete Hessian matrix beta HessData HessOut est label se_model;
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
 CORR="&PSI21";
run;
data results.ic&studyid;
 set temp.SP_PE_ic0;
run;

data temp.SP_PE_pe0;
 set temp.SP_PE_pe0;
 study=&studyid;
 Tech="&tech1";
 ACR="&&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 CORR="&PSI21";
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
 CORR="&PSI21";
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
 CORR="&PSI21";
run;
data results.cs&studyid;
 set temp.SP_PE_cs0;
run;

data temp.SP_PE_est0_cor;
 set temp.SP_PE_est0_cor;
 study=&studyid;
 Tech="&tech1";
 ACR="&ACR";
 CE="&CE";
 SP="&SP";
 POM="&POM";
 PROP="&Proportional";
 CORR="&PSI21";
run;
data results.cor&studyid;
 set temp.SP_PE_est0_cor;
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
 CORR="&PSI21";
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
proc datasets nolist;
 delete Hessian matrix beta HessData HessOut est label se_model;
run;
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
data results.corr_runtime_study&k;
 set _null_; 
run;
data results.ic&k;
 set _null_; 
run;
%mend zinitialize_studies;

/*==================================================================
The following macro just initializes the global macro variables 
 _POM_=SS;            ** Order of POM option: SS, PA, NO **
 _ACR_=YES;           ** Order of ACR option: YES, NO **
 _CE_ =YES;           ** Order of CE option:  YES, NO **
 _Prop_=YES;          ** Order of Proportional option: YES, NO **
 _SP_threshold=15;    ** Sets the SP threshold at 15 **
 _PSI21_=YES;         ** Order of PSI21 option: YES, NO **
 _HESS_=NO;           ** Order of HESS option: YES, NO
                         This checks Hessian matrix in order to run 
                         alternative models if convergence or 
                         Hessian fails (non p.d. or neg eigenvalues)
==================================================================*/
%macro InitialModelOptions(_POM_=SS, _ACR_=YES, _CE_=YES, _Prop_=YES, _SP_threshold=15, _PSI21_=YES, _HESS_=YES);
 %let POM=%upcase(&_POM_);
 %let ACR=%upcase(&_ACR_);
 %let CE =%upcase(&_CE_);
 %let Proportional=%upcase(&_Prop_);
 %let SP_Threshold=&_SP_threshold;
 %let PSI21=%upcase(&_PSI21_);
 %let HESS=%upcase(&_HESS_);
%mend;


%macro zInitialModelOptions(_POM_=SS, _ACR_=YES, _CE_=YES, _Prop_=YES, _SP_threshold=15, _PSI21_=YES, _HESS_=YES,_bGFR_=YES,_log_ACR_=YES,
_Acute_GFR_=YES);
 %let POM=%upcase(&_POM_);
 %let ACR=%upcase(&_ACR_);
 %let CE =%upcase(&_CE_);
 %let Proportional=%upcase(&_Prop_);
 %let SP_Threshold=&_SP_threshold;
 %let PSI21=%upcase(&_PSI21_);
 %let HESS=%upcase(&_HESS_);
 %let bGFR=%upcase(&_bGFR_);
 %let Log_ACR=%upcase(&_log_ACR_);
 %let Acute_GFR=%upcase(&_Acute_GFR_);
%mend;

/*==================================================================
The following macro creates dataset STUDIES with truncated data so
that one can truncate at 24 months or 18 months to see what impact 
a shorter-term study could have had on parameter estimates and 
inference compared to a longer study. One would call this macro
right  
    truncate=       -defines the turncation period. All follwo-up
                     data after TRUNCATE will be deleted and the
                     clinical events will be censored at TRUNCATE
                     if they occur after TRUNCATE   
                     Valid values are:
                      TRUNCATE=
                         or
                      TRUNCATE=24 (or 18 or any truncation period)  
                     When one specifies TRUNCATE= then the original
                     dataset studies=dat.studies will be used 
==================================================================*/
%macro truncate(truncate=);
	data studies;
	 set dat.studies_update;
	 b_CKDegfr_Indiv = b_CKDegfr_Mean + b_CKDegfr;
	 %if %length(&truncate) %then %do;
	 truncate=&truncate;
	 /* For truncated data at truncate months */
	 if Month>truncate then delete;
	 if fu_dx>truncate then do;
	  fu_dx=truncate;
	  ev_dx=0;
	 end;
	 %end;
	run;
%mend;

