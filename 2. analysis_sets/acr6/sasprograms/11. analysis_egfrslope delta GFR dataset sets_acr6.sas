%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\acr6\datasets";
libname Exports  "&path1\analysis_sets\acr6\exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");

data studies;
 set SASdata.studies;
 if 0<=visit_time<=25.5;/** this max number should match the number used below in the macro %futimes **/
run;
data allrxdata;
 set SASdata.allrxdata;
run;
proc sort data=allrxdata;
 by allrx;
run;
proc sort data=studies;
 by allrx;
run;
data studies;
 merge studies(in=in1) allrxdata;
 by allrx;
 if in1;
run;
proc sort data=studies;
 by allrx new_id visit_time;
run;
%macro numwordsp(lst);
   %local i v;
   %let i = 1;
   %let v = %scan(&lst,&i,'+');
   %do %while (%length(&v) > 0);
      %let i = %eval(&i + 1);
      %let v = %scan(&lst,&i,'+');
      %end;
   %eval(&i - 1)
%mend;
%macro closest(in,out);
proc datasets nolist;
 delete temp1 temp2 temp3;
run;
quit;
data temp1;
 set &in;
 if vtime=. then delete;
 d1=visit_time-vtime;
 d2=abs(d2);
run;
proc sort data=temp1;
 by new_id vtime d2 d1;
run;
data temp2;
 set temp1;
 by new_id vtime d2 d1;
 if first.vtime;
run;
data temp3;
 set temp2;
 drop d1 d2;
run;
data &out;
 set temp3;
run;
proc datasets nolist;
 delete temp1 temp2 temp3;
run;
quit;
%mend;
%macro futimes(allrx,times,gap,max);
proc datasets nolist;
 delete ztemp0 ztemp1 ztemp2 ztemp3 freqs1 freqs2;
run;
quit;
%let n=%numwordsP(&times);
%let m=%numwordsP(&times)-1;
data ztemp0;
 set studies;
 if allrx=&allrx;
run;
data ztemp1;
 set ztemp0;
 if visit_time=0 then vtime=0;
 if visit_time <= &max;
 %do i=2 %to &n;
  %let target=%scan(&times,&i,"+");
  %let j=&i-1;
  %let k=&i+1;
  %let before=%scan(&times,&j,"+");
  %let  after=%scan(&times,&k,"+");
  %if &i=&n %then %do; 
  %let after=&max; 
  %end;
  %let width1=(&target-&before)/2;
  %let width2=(&after-&target)/2;
  %if (&allrx=40 or &allrx=41 or &allrx=42) and &before=0 %then %do;
  if 0<visit_time<=1.25 then vtime=&target;
  %end;
  %else %do;
  if &target-min(&width1,&gap)<visit_time<=&target+min(&width2,&gap) then vtime=&target;
  %end;
  %end;
run;
data ztemp1;
 set ztemp1;
 if vtime=. then vtime_miss=1;else vtime_miss=0;
run;
data missed_&allrx;
 set ztemp1;
 if vtime=.;
 keep allrx new_id visit_time;
run;
proc freq data=ztemp1;
 table vtime vtime_miss;
 ods output onewayfreqs=freqs1;
 title "Allrx = &allrx";
run;
data freqs1;
 set freqs1;
 drop f_vtime f_vtime_miss;
run;
%closest(ztemp1,ztemp2);
data allrx_&allrx;
 set ztemp2;
run;
proc freq data=ztemp2;
 table vtime;
 ods output onewayfreqs=freqs2;
 title "Allrx = &allrx";
run;
data freqs2;
 set freqs2;
 drop f_vtime;
run;
data freqs1;
 set freqs1;
 time=vtime;
 if vtime=. then time=vtime_miss;
 rename frequency=frequency1 percent=percent1 cumfrequency=cumfrequency1 cumpercent=cumpercent1;
 drop vtime vtime_miss;
run;
data freqs2;
 set freqs2;
 rename vtime=time frequency=frequency2 percent=percent2 cumfrequency=cumfrequency2 cumpercent=cumpercent2;
run;
proc sort data=freqs1;
 by table time;
run;
proc sort data=freqs2;
 by table time;
run;
data freqs_&allrx;
 length allrx 8. table $30. time 8.;
 merge freqs1 freqs2;
 by table time;
 allrx=&allrx;
run;
proc datasets nolist;
 delete ztemp0 ztemp1 ztemp2 ztemp3 freqs1 freqs2;
run;
quit;
%mend;
%options_off;
%futimes(505,0+1+3+6+12+18+24,1.5,25.5); /** User input needed here **/
%macro set_all(name,out,vars);
proc datasets nolist;
 delete out1 unique_allrx;
run;
quit;
proc sort data=studies out=unique_allrx nodupkey;
 by allrx;
run;
data unique_allrx;
 set unique_allrx;
 keep allrx study_num allrxname intervention intervention_abrev intervention_fmt disease disease_fmt disease2 disease2_fmt;
run;
proc freq data=studies;
 table allrx;
 ods output onewayfreqs=allrx;
run;
proc sql noprint;
select allrx into :allrx separated by '+' from allrx;
quit;
%let n=%numwordsP(&allrx);
data out1;
 set %do i=1 %to &n;
 %let h=%scan(&allrx,&i,"+");
 &name._&h 
 %end;
 ;
run;
proc sort data=unique_allrx;
 by allrx;
run;
proc sort data=out1;
 by allrx;
run;
data &out;
 merge out1(in=in1) unique_allrx;
 by allrx;
 if in1;
run;
proc sort data=&out;
 by &vars;
run;
proc datasets nolist;
 delete out1 unique_allrx;
run;
quit;
%mend;
%set_all(allrx,studies_lsmeans,allrx new_id vtime);
%set_all(freqs,freqs_lsmeans,allrx table time);
%set_all(missed,missed_lsmeans,allrx new_id visit_time);
data SASdata.fdata;
 set studies_lsmeans;
run;
data Exports.freqs_lsmeans;
 set freqs_lsmeans;
run;
%zexportxlsx(freqs_lsmeans,freqs_lsmeans,&path1\analysis_sets\acr6\exports);
data Exports.missed_lsmeans;
 set missed_lsmeans;
run;
%zexportxlsx(missed_lsmeans,missed_lsmeans,&path1\analysis_sets\acr6\exports);
/** Acute for Sprint is at 3m: this part of the code might change depending on the studies used and in particular 
    if the timing of acute effect varies by the studies used together **/
data t0;
 set studies_lsmeans;
 if vtime=0;
 gfr=fu_CKDegfr;
 gfr0=gfr;
 if gfr0=. then delete;
 keep new_id allrx allrxname gfr0;
run;
data t_delta;
 set studies_lsmeans;
 gfr=fu_CKDegfr;
 if vtime=3; /** User input needed here 3 is the acute time anchor **/
 if gfr=. then delete;
 keep allrx allrxname new_id t_assign gfr;
run;
proc sort data=t0;
 by new_id allrx allrxname;
run;
proc sort data=t_delta;
 by new_id allrx allrxname;
run;
data t_delta1;
 merge t0(in=in1) t_delta(in=in2);
 by new_id allrx allrxname;
 if in1 and in2;
run;
proc sql noprint;
 create table t_delta2 as
 select *,mean(gfr0) as gfr0_mean
 from t_delta1;
quit;
data deltaGFR;
 set t_delta2;
 gfrdiff=gfr-gfr0;
 gfr0c=gfr0-gfr0_mean;
run;
data SASdata.deltaGFR;
 set deltaGFR;
run;
/** Run ANCOVA **/
proc sort data=deltaGFR;
 by allrx;
run;
proc reg data=deltaGFR;
 model gfrdiff=gfr0c t_assign/clb;
 by allrx;
 ods output parameterestimates=pe1(drop=model df dependent);
 ods output fitStatistics=fit1;
 ods output nobs=nobs1;
run;
quit;
data rsq1;
 set fit1;
 a=1;
 if label2="R-Square";
 rsquare=cvalue2;
 keep allrx a rsquare;
run;
data arsq1;
 set fit1;
 a=1;
 if label2="Adj R-Sq";
 arsquare=cvalue2;
 keep allrx a arsquare;
run;
data rmse1;
 set fit1;
 a=1;
 if label1="Root MSE";
 rmse=cvalue1;
 keep allrx a rmse;
run;
data obs1;
 set nobs1;
 a=1;
 if label="Number of Observations Used";
 n=nobsused;
 keep allrx a n;
run;
data pe1;
 set pe1;
 a=1;
 order=_n_;
run;
proc sort data=pe1;
 by allrx a;
run;
proc sort data=obs1;
 by allrx a;
run;
proc sort data=rsq1;
 by allrx a;
run;
proc sort data=arsq1;
 by allrx a;
run;
proc sort data=rmse1;
 by allrx a;
run;
data pe11;
 merge pe1 obs1 rsq1 arsq1 rmse1;
 by allrx a;
run;
proc sort data=pe11;
 by allrx order;
run;
data pe11;
 set pe11;
 drop a order;
 type="Difference";
 if compress(upcase(variable))="T_ASSIGN";
 est01=estimate;
 stderr01=stderr;
 nobs=n;
 if allrx=505 then time_acute=3;/** Make sure you change this according to the study used **/
 keep allrx est01 stderr01 nobs time_acute;
run;
data pe11;
 set pe11;
 rename nobs=n;
run;
data Exports.ancova_deltaGFR;
 set pe11;
run;
data SASdata.ancova_deltaGFR;
 set pe11;
run;































