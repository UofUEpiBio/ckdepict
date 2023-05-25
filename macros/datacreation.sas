%macro datacreation(long,short,event,knot,truncation,window);
data short;
 length new_id $24;
 set &short;
 ev_d2y=ev_d;
 if ev_d2y=1 and fu_d > 24 then ev_d2y=0;
 keep allrx study_num new_id base_scr b_ckdegfr 
		ev_&event fu_&event	treat1 treat2 treat3 t_assign age female black 
        adm_studyendmos adm_1mos
		adm_6mos  /*key endpt for censoring for events*/
		max_adm_studyend adj_adm_studyend altmax_mos_adm altadj_mos_adm ev_d2y ev_d ev_x;
run;
data long0;
 set &long;
 keep study_num new_id visit_time /*base_scr b_ckdegfr*/ scr fu_CKDegfr;
run;
data short0;
 set short;
 keep study_num allrx new_id t_assign treat1 treat2;
run;
proc sort data=short0;
 by study_num new_id;
run;
proc sort data=long0;
 by study_num new_id;
run;
proc sql; 
  create table long1 as
  select  * 
  from short0,long0
  where short0.study_num=long0.study_num and short0.new_id=long0.new_id;
quit;
proc sort data=short;
 by allrx new_id;
run;
proc sort data=long1;
 by allrx new_id;
run;
proc sort data=short;
 by allrx new_id;
run;
data long2;
 merge long1(in=a) short(in=b); 
 by allrx new_id;
 if a and b;
run;
data long3;
 set long2;
 drop study_num;
run;
data long4;
 set long3;
 Study_num=allrx;
 Study_ID=study_num;                    ** study_id = numeric version of study_num;
 Month=visit_time;                      ** alternative name for visit_time for efv;
 _Month_=round(Month,1);                ** rounded version of month;
       if t_assign=0 then Trt_Assign="Placebo/Control";
  else if t_assign=1 then Trt_Assign="Treatment      ";
  /*==================================================================================== 
  Define a single variable containing administrative censoring times based on the     
  values of adm_mos and adm_mosvis1 so that logical comparisons can be made of the   
  different event times (e.g., fu_d, fu_x, etc.) compared to mos_admcensor                    
 ====================================================================================*/

 /****** WHAT THE IS THE EQUIVALENT TOF THIS .... *************************
 if mos_adm>. then mos_admcensor = mos_adm; else mos_admcensor=mos_admvis1;*/
 mos_admcensor=adm_6mos;
 /*==================================================================================== 
  Define a variable Trt which is the value of Treat1 and a variable BP which is Treat2
  Define a variable BP_Trt which is the unique BP by Trt combination for those studies     
 involving both BP and Drug Trt interventions. 
 ====================================================================================*/
 Trt=treat1;
 BP=treat2;
 BP_Trt=right(treat1)||left("/")||left(treat2);
 if visit_time=. then delete;   
run;
data long4;      
 set long4;
 Trt_counter=1;
 Treatment=Trt_Assign;
 Trt_Assign_ID=Trt;
run;
/*==============================================================================================
 We create a sequential counter variable, Study, that is different from the actual study number 
(Study_ID and Study_num) and a treatment ID variable, TrtID, for MACRO programming purposes. 
 The variable Study allows us to run a model for a given study as well as run a model for all 
 studies using a simple DO loop. The variable TrtID is necessary when evaluating different 
 treatment groups in models run with NLMIXED as there is no CLASS statement in NLMIXED.   
 The dataset SASdata.Study_Info created below allows us to merge in the original Study_num 
 and Study_ID into generated output datasets so we can identify what Study_num goes with 
the value of the variable Study.   
==============================================================================================*/
proc sort data=long4;
 by study_id trt_counter treatment bp trt;
run;
data long4;
 set long4;
 retain Study 0 TrtID 0;    
 by study_id trt_counter treatment bp trt;
 if first.trt_counter then Study+1;
 if first.trt_counter then TrtID=0;
 if first.treatment then TrtID=TrtID+1;
run;
/*==============================================================================================
   We need the exact sequential number of each study for MACRO programming purposes.   
   The dataset SASdata.Study_Info allows us to merge in original study_num and Study_ID later 
   so as to identify from what clinical trial the value of the variable Study correpsonds to. 
==============================================================================================*/
data sasdata.study_info; 
 set long4;
 by study_id trt_counter;
 if last.trt_counter;
 Trts=TrtID;  ** number of unique bp and trt combinations; 
 keep study study_id trt_counter study_num trts;
run; 
/*==============================================================================================
  We need to extract the TrtID value and its associated Treatment, BP and Trt values to be merged 
  back with parameter estimates later so we can identify what beta01 beta02, etc. correspond to.
==============================================================================================*/
data sasdata.trtid;  
 set long4;
 by study_id trt_counter treatment bp trt;
 if first.treatment;
 keep study_id study_num study trt_counter treatment bp trt trt_assign_id trtid;
run; 
/*==============================================================================================
  Get a unique variable identifying what the treatment groups are for the 43 extended "studies" 
  This can be used later when we try and summarize results for the 43 extended "studies"  
  NOTE: One can adapt preceding and current code to capture the ALLRX treatments. 
==============================================================================================*/
data trt_label1;
 set sasdata.trtid;
 by study_id trt_counter treatment bp trt;
 if trtid=1;
 trt_label_1=trt_assign_id;
 keep study_id trt_counter study trt_label_1; 
run;
data trt_label2;
 set sasdata.trtid;
 by study_id trt_counter treatment bp trt;
 if trtid=2;
 trt_label_2=trt_assign_id;
 keep study_id trt_counter study trt_label_2; 
run;
data sasdata.trt_label;
 merge trt_label1 trt_label2;
 by study_id trt_counter;
 trt_label=right(trt_label_1)||left(',')||left(trt_label_2);
 keep study_id study trt_label;
run;
proc sort data=sasdata.trt_label;
 by study_id study;
run;
proc sort data=sasdata.study_info; 
 by study_id study;
run;
data sasdata.study_info;
 merge sasdata.study_info sasdata.trt_label;
 by study_id study;
run;
data xshort;
 set short;
 study_num=allrx;
 study_id=study_num;    
 visit_time=0;
 Month=0;
 _Month_=0;
 scr=base_scr;
 fu_CKDegfr=b_ckdegfr;
       if t_assign=0 then trt_assign="Placebo/Control";
  else if t_assign=1 then trt_assign="Treatment      ";
 Trt=treat1;
 BP=treat2;
 BP_Trt=right(treat1)||left("/")||left(treat2);
 Trt_counter=1;
 Treatment=Trt_assign;
 Trt_Assign_ID=Trt;
 if t_assign=0 then TrtID=1;
 else if t_assign=1 then TrtID=2;
 mos_admcensor=adm_6mos;
run;
proc sort data=long4 out=t1(keep=allrx study) nodupkey;
 by allrx;
run;
proc sort data=long4 out=t2(keep=allrx new_id) nodupkey;
 by allrx new_id;
run;
proc sort data=xshort;
 by allrx;
run;
data zshort;
 merge xshort t1;
 by allrx;
run;
data long4a;
 set zshort long4;
run;
proc sort data=t2;
 by allrx new_id;
run;
proc sort data=long4a;
 by allrx new_id;
run;
data long5;
 merge long4a(in=in1) t2(in=in2);
 by allrx new_id;
 *if in1 and in2; /** I have commented this line on 8/24/2017 to keep those with baseline and no fup **/
run;
proc sort data=long5;
 by allrx new_id visit_time;
run;
data long5;
 set long5;
 by allrx new_id visit_time;
 if first.new_id then visit=0;else visit+1;
run;
proc sort data=long5 out=studies;
 by study_num study new_id treatment t_assign treat1 treat2 visit_time;
run;
data studies;
 set studies;
 retain subject 0;
 by study_num study new_id treatment t_assign treat1 treat2 visit_time;
 if first.study then subject=0;
 if first.new_id then do;
   subject=subject+1;
  end;
run;
/*==============================================================
  Define an artificial total study period such that we can     
  investigate what impact study follow-up length for eGFR has 
  on the chronic slope estimates. So if we have a 1-year study
  what would the chronic slope be compared to a 3 year study.
  Also, define values for ev_s and fu_s for 2xSCr events based
  on definitions of ev_d, ev_x, ev_dx, ev_dsx and fu_d, fu_x
  fu_dx and fu_dsx.          
==============================================================*/ 
data studies;
 set studies;
 truncation=&truncation;
 window=&window;
 by study_num study new_id treatment t_assign treat1 treat2 visit_time;
 if visit_time <= truncation + window;
run;
proc sort data=studies;
 by study_num study new_id treatment t_assign treat1 treat2 visit_time;
run;
data Studies;
 set Studies;
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2 Visit Visit_Time;
 Event=ev_&event;          
 EventTime=fu_&event;  
 EventType="&event";
 LogT=log(EventTime);
 T=EventTime;
 if EventTime in (. 0) then delete;
run;
/*===============================================
   Get very last visit for each patient and summarize occurrences of 2xSCr and eGFR<15 
   events and also assign the type of event (Death, 2xSCr, ESRD, Uncertain) based on 
   the known relationship between ev_dgsx_con and ev_dgsx for death as well as educated  
   guesses as to 2xSCr based on when the event occurs (perior to or after last visit) and
  whether we observed one or more 2xSCr events.    
===============================================*/
proc sort data=Studies;
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2 Visit Visit_Time;
run;
data LastVisit;
 set Studies;
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2 Visit Visit_Time;
 if last.New_ID;
run;
data LastVisit;
 set LastVisit;
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2 Visit Visit_Time;
 LastVisit=Visit;
 LastMonth=Month;
 FinalMonth=floor(Month);                          ** FinalMonth = LastMonth rounded to the whole month 
                                                                   based on floor(.) function; 
 EventMonth=floor(EventTime);
 if EventTime>mos_admcensor                    then Censored='> Administrative Censoring Time'; 
 if EventTime<mos_admcensor                    then Censored='< Administrative Censoring Time'; 
 if (mos_admcensor<=EventTime<=mos_admcensor)  then Censored='= Administrative Censoring Time'; 
 if EventTime>LastMonth                        then Dropout='> Last time eGFR was measured'; 
 if EventTime<LastMonth-1                      then Dropout='< Last time eGFR was measured'; 
 if (LastMonth-1)<=EventTime<=LastMonth        then Dropout='= Last time eGFR was measured';
 if EventTime>LastMonth                        then _Dropout_='> Last time eGFR was measured'; 
 if EventTime<LastMonth                        then _Dropout_='< Last time eGFR was measured'; 
 if (LastMonth)<=EventTime<=LastMonth          then _Dropout_='= Last time eGFR was measured';
 keep Study_num Study New_ID Treatment T_Assign Treat1 Treat2 Trt_Assign Censored Dropout _Dropout_ 
          LastVisit LastMonth FinalMonth Event EventTime EventMonth EventType mos_admcensor 
          ev_&event fu_&event;
run;
data sasdata.LastVisit;
 set LastVisit;
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2;
 drop ev_&event fu_&event mos_admcensor;
run;
data Studies;
 set Studies;
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2 Visit Visit_Time;
run;
/*======================================================================== 
  Merge in potentially useful LastVisit variables with primary dataset 
========================================================================*/ 
data Studies;
 merge Studies(in=a) sasdata.LastVisit(in=b);
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2;
run;
/*======================================================================== 
  Redefine eGFR values based on whether or not Censor = YES  
  When Censor=YES, we delete all visit times that occur after mos_admcensor
  which is defined to be mos_adm when present or mos_admvis1 when mos_adm is 
  missing.  The dataset Studies_Delete is a temporary dataset that is
  currently not created as the work group needs to make a decision
  regarding using eGFR values following adminitsrative censoring times. 
  One can either delete the observations when visit_time>mos_admcensor or 
  assign eGFR values to be missing by assigning SAS variables eGFR=&eGFR
  and then setting eGFGR=. if EventTime<LastMonth. The latter approach may 
     be prefered as we then preserve the original values of &eGFR.   
=======================================================================*/ 
data Studies;
 set Studies;
 by Study_num Study New_ID Treatment T_Assign Treat1 Treat2;
 if Month <= /*&CensorTime*/ 1000000; 
run;
proc sort data=Studies out=sasdata.Studies;
 by Study_num Study_ID Study New_ID Treatment T_Assign Treat1 Treat2 Visit Visit_Time;
run;
/** Add studies information 7/5/2017 **/
data zstudies0;
 set sasdata.studies;
 if visit_time=. or fu_ckdegfr=. then delete;
run;
proc sql noprint;
 create table zstudies1 as
 select new_id,study,count(*) as n_egfr, max(visit_time) as max_visit_time,max(b_CKDegfr) as xb_CKDegfr,max(ev_dx) as xev_dx,
        max(ev_d) as xev_d,max(ev_x) as xev_x,max(ev_d2y) as xev_d2y
 from zstudies0
 group by study,new_id;
quit;
proc sql noprint;
 create table zstudies2 as
 select study, count(*) as n_study, mean(n_egfr) as mean_n_egfr,mean(max_visit_time) as mean_max_visit_time,
        mean(xb_CKDegfr) as mean_b_CKDegfr,min(xb_CKDegfr) as min_b_CKDegfr,max(xb_CKDegfr) as max_b_CKDegfr,
		sum(xev_dx) as sum_ev_dx,sum(xev_d) as sum_ev_d,sum(xev_x) as sum_ev_x,sum(xev_d2y) as sum_ev_d2y
 from zstudies1
 group by study;
quit;
data zstudies3;
 set zstudies2;
 pct_ev_dx=100*sum_ev_dx/n_study;
 pct_ev_x=100*sum_ev_x/n_study;
 pct_ev_d2y=100*sum_ev_d2y/n_study;
run;
proc sort data=zstudies3;
 by study;
run;
/** Timing of first eGFR after baseline to help with knot added on 7/5/2017 **/
data zstudies00;
 set zstudies0;
 if visit_time in (0 .) then delete;
run;
proc sort data=zstudies00;
 by study new_id visit_time;
run;
data zstudies000;
 set zstudies00;
 by study new_id visit_time;
 if first.new_id;
run;
data zstudies000;
 set zstudies000;
 if 0 < visit_time <= 4 then v4time=1;
 else if 4 < visit_time <= 6 then v4time=2;
 else if visit_time > 6 then v4time=3;
 v4time1=(v4time=1);
 v4time2=(v4time=2);
 v4time3=(v4time=3);
run;
proc sql noprint;
 create table v4time as
 select study, count(*) as nv4time,sum(v4time1) as v4time1s,sum(v4time2) as v4time2s,sum(v4time3) as v4time3s
 from zstudies000
 group by study;
quit;
data v4time;
 set v4time;
 pv4time1=100*v4time1s/nv4time;
 pv4time2=100*v4time2s/nv4time;
 pv4time3=100*v4time3s/nv4time;
run;
/** %MasterData END TEMPORARILY HERE AND RESUME LATER **/
/** %StudyDescrip START HERE **/
proc means data=sasdata.Studies nway n noprint;
 where Visit=0;
 class Study_num Study_ID Study;
 var &eGFR0;
 output out=SampleSize n=Patients;
run;
proc means data=sasdata.Studies nway min median max noprint;
 where Visit=1;
 class Study_num Study_ID Study;
 var Month;
 output out=FirstMonth median=MedianMonth min=MinimumMonth max=MaximumMonth;
run;
proc means data=sasdata.Studies nway min median max noprint;
 where Visit=0;
 class Study_num Study_ID Study;
 var EventTime;
 output out=EventTime min=MinTime median=MedianTime max=MaxTime;
run;
/*========================================================================= 
  Assess how many events occur in each study and whether we need worry 
  about informative censoring for a given study with low event rates.
=========================================================================*/
proc means data=sasdata.Studies nway n mean median min max range noprint;
 where Month=0;
 class Study_num Study_ID Study Event;
 var EventTime;
 output out=NumberEvents n=n mean=mean median=median min=min max=max range=range; 
run;
proc sort data=NumberEvents;
 by Study_num Study_ID Study Event;
run;
proc transpose data=NumberEvents out=Events_n prefix=n;
 by Study_num Study_ID Study;
 id Event;
 var n;
run;
proc transpose data=NumberEvents out=Events_mean prefix=mean;
 by Study_num Study_ID Study;
 id Event;
 var mean;
run;
proc transpose data=NumberEvents out=Events_median prefix=median;
 by Study_num Study_ID Study;
 id Event;
 var median;
run;
proc transpose data=NumberEvents out=Events_min prefix=min;
 by Study_num Study_ID Study;
 id Event;
 var min;
run;
proc transpose data=NumberEvents out=Events_max prefix=max;
 by Study_num Study_ID Study;
 id Event;
 var max;
run;
proc transpose data=NumberEvents out=Events_range prefix=range;
 by Study_num Study_ID Study;
 id Event;
 var range;
run;
data SummaryOfEvents;
 merge Events_n Events_mean Events_median Events_min Events_max Events_range; 
 if n0=. then n0=0;
 if n1=. then n1=0;
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
data StudyDescrip;
 merge SampleSize(in=a) FirstMonth(in=b) EventTime(in=c) SummaryOfEvents(in=d);
 by Study_num Study_ID Study;
 drop _TYPE_ _FREQ_ ;
run;
proc sort data=StudyDescrip;
 by study;
run;
proc sort data=v4time;
 by study;
run;
data StudyDescrip;
 merge StudyDescrip v4time;
 by study;
run;
data StudyDescrip;
 set StudyDescrip;
 knot=&knot;
 *if MinimumMonth>=6 then knot=6;
 /** New code for knot **/
 if pv4time1 > 50 then knot=4;
  else if pv4time2 > 50 then knot=6;
  else knot=8;
run;
proc sort data=sasdata.Studies;
 by Study_num Study_ID Study New_ID T_Assign Treat1 Treat2 Visit Visit_Time;
run;
data sasdata.Studies;
 set sasdata.Studies;
 by Study_num Study_ID Study New_ID T_Assign Treat1 Treat2 Visit Visit_Time;
 if Visit>=0;
run;
proc sort data=sasdata.Studies;
 by Study_num Study_ID Study Subject Month;
run;
/* Get the number of treatment groups (=N_Trt) based on last TrtID per study and merge into StudyDescrip */
proc sort data=sasdata.TrtID out=TrtID1;
 by Study_num Study_ID Study TrtID;
run;
data TrtID1;
 set TrtID1; 
 by Study_num Study_ID Study TrtID;
 N_Trt=TrtID;
 if last.Study;
 keep Study_num Study_ID Study N_Trt; 
run;
data StudyDescrip;
 merge StudyDescrip TrtID1;
 by Study_num Study_ID Study;
 Events="&event";
run;
/** Merge additional studies infor with old study descrip **/
proc sort data=StudyDescrip;
 by study;
run;
proc sort data=zstudies3;
 by study;
run;
data StudyDescrip;
 merge StudyDescrip zstudies3;
 by study;
run;
/* Merge in StudyDescrip data containing Patients, MinimumMonth = Min(Month of follow-up post-baseline) etc. */
data sasdata.Studies;
 merge sasdata.Studies StudyDescrip;
 by Study_num Study_ID Study;
run;
data exports.StudyDescrip;
 set StudyDescrip;
run;
data sasdata.StudyDescrip;
 set StudyDescrip;
run;
/*========================================================================= 
 Merge in dataset EventsByTrtID with SASdata.TrtID so we have a summary
 of how many events occur in each study treatment group and whether we  
 can even model hazard rates when some treatment groups having no events
=========================================================================*/
proc means data=sasdata.Studies nway n sum noprint;
 where Visit=0;
 class Study_num Study_ID Study TrtID;
 var Event;
 output out=EventsByTrtID n=Patients_per_TrtID sum=Events_per_TrtID;
run;
data EventsByTrtID;
 set EventsByTrtID;
 drop _TYPE_ _FREQ_;
run;
proc sort data=EventsByTrtID;
 by Study_num Study_ID Study TrtID;
run;
proc sort data=sasdata.TrtID;
 by Study_num Study_ID Study TrtID;
run;
data sasdata.TrtID;
 merge sasdata.TrtID(in=a) EventsByTrtID(in=b);
 by Study_num Study_ID Study TrtID;
run;
proc sort data=sasdata.Studies;
 by Study_num Study_ID Study New_ID Visit Visit_Time Treatment T_Assign Treat1 Treat2;
run;
%mend;