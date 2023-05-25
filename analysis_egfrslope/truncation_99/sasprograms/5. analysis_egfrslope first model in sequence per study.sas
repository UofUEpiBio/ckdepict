%let t=truncation_99;
%let path1=d:userdata\Shared\CKD_Endpts\FDA Conference 2\Data\Cleaned Data\FIGARO-DKD;
%let path2=d:userdata\Shared\CKD_Endpts\FDA Conference 2\Data\Cleaned Data\FIGARO-DKD\57pdecline;
%let pathm=d:userdata\Shared\CKD_Endpts\CKD-EPI CT\Codes for external treatment effects analysis\Root;

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&pathm\macros");

libname Master "&path1";
libname SASdata  "&path1\analysis_egfrslope\&t.\datasets";
libname Exports  "&path2\analysis_egfrslope\&t.\&t._exports";
libname results "&path2\analysis_egfrslope\&t.\models\results";
libname temp "&path2\analysis_egfrslope\&t.\models\temp";
libname temp2 "&path2\analysis_egfrslope\&t.\models\temp2";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&pathm\macros");

%include "&pathm\macros\Updated Joint_Model_POM_YN_SP_YN_Kappa_YN_PE.sas";

%let N_trt=2;
%let N_Trt_1=1;

%let N_event=10;*!!!!!!!___modify the count of endpoints____!!!!!!!!;
%macro declearNIntervals;
%do ki = 1 %to &N_event; %global NIntervals&ki include&ki;  %end;
%mend;
%declearNIntervals;
%global  b_CKDegfr_Mean;
%global  ACR;          *!!!!!!___New macro variable option to include or exclude ACR modeling;     
%global  CE;           *!!!!!!___New macro variable option to include or exclude clinical event (CE) modeling;       
%global  Proportional;
%global  POM;
%global  SP_threshold; *!!!!!!___EFV: This may be necessary to allow us to change this within macro Run_Model;  
%global  SP;
%global  HESS;   
%global  PSI21;        *!!!!!!___EFV: This global macro variable is only defined in DOALL as a last resort eGFR model 
                                 in combination with the macro variable HESS. The default is PSI21=YES so that the
                                 the parameter psi21 is included in the random effects covariance structure. However,
                                 one can set PSI21=NO which will force PSI21=0 for any given model one wishes to run;
%let ACR=NO;          *!!!!!!___set YES/NO to include (YES) or exclude (NO) ACR in the joint model;
%let CE=NO;           *!!!!!!___set YES/NO to include (YES) or exclude (NO) clinical events (CE) in the joint model;
%let Proportional=YES; *!!!!!!___set YES/NO to allow or not allow different random slope variance for different treatments_____!!!!!!!!!!!!!!;
%let POM=SS;           *!!!!!!___set SS/PA/NO to allow or not allow power of mean (POM) residual variance!!!!!!!!!!!!!!;
%let SP_threshold=15;  *!!!!!!___set threshold for SP model, if the total count of ev_dx event is less than this threshold, POM model will be run, otherwise SP model will be run!!!!!!!!!!!!!!;
%let HESS=YES;         *!!!!!!___set HESS=YES if you want to allow automatic switch from SS-POM to PA-POM when Hessian is a problem under SS-POM
                                 or if you want to further allow automatic switch from PA-POM to NO-POM when Hessian is a problem under PA-POM, 
                                 set HESS=NO if you want to run all three POM options and compare results using macros Compare_POM and Summary - see end of program for example !!!!!!!!!!!!!!;
%let PSI21=YES;        *!!!!!!___set YES/NO to include (YES) or exclude the parameter psi21 from the random effects del;   
data allrxdata;
 set SASdata.allrxdata;
 study_num=allrx;
run;
data studydescrip;
 set SASdata.studydescrip;
 npatients=patients;
 nevents=n1;
 keep study_num study npatients nevents knot v4time1s pv4time1 v4time2s pv4time2 v4time3s pv4time3 mean_n_egfr 
      mean_max_visit_time mean_b_CKDegfr min_b_CKDegfr max_b_CKDegfr sum_ev_dx sum_ev_d sum_ev_x sum_ev_d2y pct_ev_dx 
      pct_ev_x pct_ev_d2y;
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
proc sort data=ddshort out=fu_dx(keep=new_id study_num fu_dx) nodupkey;
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
data base;
 set dshort;
 %include "&pathm\macros\zupro.sas";
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
proc sort data=allrxdata;
 by study_num;
run;
proc sort data=base_up;
 by study_num;
run;
proc sort data=studydescrip;
 by study_num;
run;
data allrxleveldata;
 merge studydescrip allrxdata base_up;
 by study_num;
run;
data studies;
 set SASdata.studies;
run;
proc tabulate data=studies out=mean_bsl;
 class study_num;
 var b_CKDegfr;
 table b_CKDegfr*mean, study_num;
 where visit_time=0;
run;
data mean_bsl;
set mean_bsl;
drop _TYPE_--_TABLE_;
run;
proc sort data=studies; 
 by study_num;
run;
proc sort data=mean_bsl; 
 by study_num;
run;
data studies;
 merge studies mean_bsl;
 by study_num;
run;
data studies;
 set studies;
 Month=visit_time;
 lg_b_CKDegfr=log(b_CKDegfr); 
 b_CKDegfr=b_CKDegfr-b_CKDegfr_Mean;
 TrtID=T_assign+1;
run;
proc sort data=studies; 
 by study subject Month; 
run;
%initialize_studies(1);

ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
*options notes mprint symbolgen mlogic;
*ods listing;
%InitialModelOptions(_POM_=SS,_ACR_=NO,_CE_=NO,_Prop_=YES,_SP_threshold=15,_HESS_=YES);
%doall(1);


