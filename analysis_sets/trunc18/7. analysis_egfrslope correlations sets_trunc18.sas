%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\trunc18\datasets";
libname results "&path1\analysis_sets\trunc18\correlations\results";
libname temp "&path1\analysis_sets\trunc18\correlations\temp";
libname temp2 "&path1\analysis_sets\trunc18\correlations\temp2";

 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");

%include "&path2\macros\Macros_JointModel_EFV27JAN2023.sas";

%let N_trt=2;
%let N_Trt_1=1;

 %let N_event=9;        *!!!!!!!___modify the count of endpoints____!!!!!!!!;
 %macro declearNIntervals;
  %do ki = 1 %to &N_event; %global NIntervals&ki include&ki;  %end;
 %mend;
 %declearNIntervals;
 %global  b_CKDegfr_Mean;
 %global  ACR;          *!!!!!!___New macro variable option to include or exclude ACR modeling;   
 %global  bGFR; 
 %global  Log_ACR;
 %global  Acute_GFR;
 %global  CE;           *!!!!!!___New macro variable option to include or exclude clinical event (CE) modeling;       
 %global  Proportional;
 %global  BOUNDS;       *!!!!!!___New macro variable option to set bounds on kappa estimation;
 %global  POM;
 %global  SP_threshold; *!!!!!!___EFV: This may be necessary to allow us to change this within macro Run_Model;  
 %global  SP;
 %global  HESS;  
 %global  TRUNC;        *!!!!!!___New macro variable option to allow for a truncated analysis; 
 %global  TRUNCATE;     *!!!!!!___New macro variable option that defined the length of truncation; 
 %global  QUAD;         *!!!!!!___New macro variable option to include or exclude fixed-effects quadratic 
                                  regression coefficients in the eGFR model to investigate possible nonlinearity; 
 %global  PSI21;        *!!!!!!___EFV: This global macro variable is only defined in DOALL as a last resort eGFR
                                  model in combination with the macro variable HESS. The default is PSI21=YES so
                                  that the parameter psi21 is included in the random effects covariance structure. 
                                  However, one can set PSI21=NO which will force PSI21=0 for any given model 
                                  one wishes to run;
 %let ACR=YES;          *!!!!!!___set YES/NO to include (YES) or exclude (NO) ACR in the joint model;
 %let bGFR=YES;         *!!!!!!___set YES/NO to include (YES) or exclude (NO) bGFR in the joint model;
 %let Log_ACR=YES;      *!!!!!!___set YES/NO to include (YES) or exclude (NO) Log_ACR in the joint model;
 %let Acute_GFR=NO;    *!!!!!!___set YES/NO to include (YES) or exclude (NO) Aute_GFR in the joint model;
 %let CE=YES;           *!!!!!!___set YES/NO to include (YES) or exclude (NO) clinical events in the joint model;
 
 %let Proportional=YES; *!!!!!!___set YES/NO to allow (estimated kappa) or not allow (kappa=0) for different   
                                  random slope effect variances for the two treatment groups;
 %let BOUNDS=YES;       *!!!!!!___set YES/NO to BOUNDS=YES so as to allow for a constrained estimate of kappa>-1.0    
                                  to ensure that one can then execute the ESTIMATE log(1+kappa) statement or set 
                                  the option to BOUNDS=NO so as to allow kappa to be freely estimated as was done  
                                  in the original calls to the program but which can result in a termination of the
                                  program for a study when the options for that study (e.g., truncation) result
                                  in an estimate of kappa<-1.0 causing termination when the ESTIMATE log(1+kappa)
                                  statement is called from within the NLMIXED program; 
 %let POM=SS;           *!!!!!!___set SS/PA/NO to allow or not allow power of mean (POM) residual variance;
 %let SP_threshold=15;  *!!!!!!___set threshold for SP model, if the total count of ev_dx event is less than this 
                                  threshold, then only the POM model will be run, otherwise SP model will be run;
 %let HESS=YES;         *!!!!!!___set HESS=YES if you want to allow automatic switch from SS-POM to PA-POM when 
                                  the Hessian matrix is a problem under SS-POM or if you want to further allow 
                                  automatic switch from PA-POM to NO-POM when Hessian is a problem under PA-POM, 
                                  or set HESS=NO if you want to run all three POM options and compare results
                                  using macros Compare_POM and Summary - see end of program for example;
 %let PSI21=YES;        *!!!!!!___set YES/NO to include (YES) or exclude (NO) the parameter psi21 from the random 
                                  effects covariamce structue;   
 %let QUAD=NO ;         *!!!!!!___set YES/NO to include (YES) or exclude (NO) fixed-effects quadratic regression 
                                  parameters as a means for testing if there is any nonlinearity in chronic phase;   
 %let TRUNC=NO;         *!!!!!!___set YES/NO to use a truncated eGFR follow-up time dataset (YES) or to use the
                                  original dataset without any truncation (NO).;   
 %let TRUNCATE=36;      *!!!!!!___set to 36, 24 or 18 for a truncated analsyis at 36, 24 and 18 months (default=36);   
 %let knot=3;           *!!!!!!___set knot=3 to be fixed for the simplified one-slope mixed-effects model;  
  
/** Acute **/
data acute;
 set SASdata.deltaGFR;
run;
/** Get baseline UP **/
data ddshort;
 set Master.fdac2_tx_allendpts;
 if b_ckdegfr=. then delete;
run;
data ddlong;
 set Master.fdac2_visits;
 if visit_time=. or visit_time <= 0 or fu_ckdegfr=. then delete;
run;
proc sort data=ddshort out=ddshort_unique(keep=new_id study_num) nodupkey;
 by new_id study_num;
run;
proc sort data=ddlong out=ddlong_unique(keep=new_id study_num) nodupkey;
 by new_id study_num;
run;
data unique_ids;
 merge ddshort_unique(in=in1) ddlong_unique(in=in2);
 by new_id study_num;
run;
proc sort data=ddshort;
 by new_id study_num;
run;
proc sort data=unique_ids;
 by new_id study_num;
run;
data dshort;
 merge ddshort(in=in1) unique_ids(in=in2);
 by new_id study_num;
 if in1 and in2;
run;
data bacr;
 set dshort;
 %include "&path2\macros\zupro.sas";
 bzacr=zacr;
 if bzacr>0 then blogacr=log(bzacr);else if bzacr=0 then blogacr=log(0.01);
 keep allrx new_id bzacr blogacr;
run;
data base;
 set dshort;
 %include "&path2\macros\zupro.sas";
 zzupro=zupro/1000;
 keep allrx zzupro;
run;
data base1;
 set base;
 rename allrx=study_num;
run;
proc means data=base1 median;
 var zzupro;
 class study_num;
 ods output summary=base_up(drop=nobs);
run;
proc sort data=base_up;
 by study_num;
run;

*_____________________data management starts_________________________________________;
data events0;
 set Master.fdac2_tx_allendpts;
 if b_ckdegfr=. then delete;
run;
*!!!!!!!!____rename composite events, please refer back to here for the mean of those events_____!!!!!!!!!!!;
data events;
set events0;
ev1=ev_dg_30_p_con;	
fu1=fu_dg_30_p_con;
ev2=ev_dg_40_p_con;	
fu2=fu_dg_40_p_con;
ev3=ev_dgs_con;	
fu3=fu_dgs_con;
ev4=ev_dg_57_p_con;	
fu4=fu_dg_57_p_con;
ev5=ev_dg_con;	
fu5=fu_dg_con;
ev6=ev_d;	
fu6=fu_d;
ev7=ev_dgsx_con;	
fu7=fu_dgsx_con;
ev8=ev_dx;	
fu8=fu_dx;
/** Create EV9 but not used so that it is conformed with macro because assume 9 events **/
ev9=0;
fu9=fu_d;
keep allrx new_id--studyname1 b_CKDegfr T_assign ev1 fu1 ev2 fu2 ev3 fu3 ev4 fu4 ev5 fu5 ev6 fu6 ev7 fu7 ev8 fu8 ev9 fu9;
run;
data GFR;
 set SASdata.studies;
 keep allrx new_id--visit_time b_CKDegfr fu_CKDegfr subject study;
run;
proc sort data=GFR; 
 by allrx new_id;
run;
proc sort data=events; 
 by allrx new_id;
run;
proc sort data=bacr; 
 by allrx new_id;
run;
proc sort data=acute; 
 by allrx new_id;
run;
data studies1;
 merge GFR(in=a) events(in=b) bacr acute;
 by allrx new_id;
run;
data studies1;
 set studies1;
 if study=. then delete;
run;
proc sort data=gfr; 
 by allrx new_id visit_time;
run;
data baseline;
 set GFR;
 by allrx new_id visit_time;
 if first.new_id;
run;
proc tabulate data=baseline out=mean_bsl;
 class allrx;
 var b_CKDegfr;
 table b_CKDegfr*mean, allrx;
run;
data mean_bsl;
set mean_bsl;
drop _TYPE_--_TABLE_;
run;
proc sort data=studies1; 
 by allrx;
run;
proc sort data=mean_bsl; 
 by allrx;
run;
data studies2;
 merge studies1(in=in1) mean_bsl;
 by allrx;
 if in1;
run;
data studies3;
 set studies2;
 bCKDegfr=b_CKDegfr;
 Month=visit_time;
 lg_b_CKDegfr=log(b_CKDegfr); *lg_b_CKDegfr is calculated before b_CKDegfr is centralized;
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;
***!!!!!!!centralize baseline eGFR, but follow-up eGFR is not centralized;
 b_CKDegfr=b_CKDegfr-b_CKDegfr_Mean;
 TrtID=T_assign+1;
run;
proc sort data=studies3; 
 by study subject Month; 
run;
data studies_bgfr_bacr;
 set studies3;
 if month=0;
 keep new_id study bCKDegfr blogacr;
run;
proc means data=studies_bgfr_bacr n mean stderr;
var bCKDegfr blogacr;
class study;
ods output summary=SASdata.sum_means_gfr_acr(keep=study bCKDegfr_N bCKDegfr_StdErr blogacr_N blogacr_mean blogacr_StdErr);
run;
/** For larger studies N>1600, use a subset for correlations: execution time is large the default is to use 800 per arm max **/
%large(studies3,1600,800,studies);
%zinitialize_studies(1);
%options_off;
%zInitialModelOptions(_POM_=SS,_ACR_=NO,_CE_=YES,_Prop_=YES,_BOUNDS_=NO,_SP_threshold=15,_PSI21_=YES, _HESS_=YES,_bGFR_=YES,
_Log_ACR_=YES,_Acute_GFR_=YES,_QUAD_=NO,_TRUNC_=YES,_TRUNCATE_=21);
%doall(1);