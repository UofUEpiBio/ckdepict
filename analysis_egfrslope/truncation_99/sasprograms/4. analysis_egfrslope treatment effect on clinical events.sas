%let t=truncation_99;
%let path1=d:\userdata\shared\ckd_endpts\root;

libname Master "&path1\steps\maindatasets";
libname SASdata  "&path1\analysis_egfrslope\&t.\datasets";
libname Exports  "&path1\analysis_egfrslope\&t.\&t._exports";

 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path1\macros");

data allrxstudies;
 set exports.allrxdata;
run;
proc sort data=allrxstudies;
 by allrx;
run;
data zallrxstudies;
 set exports.zallrxdata;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
/** All **/
/** 1. Delete missing or negative visit_time
    3. Delete any visit of eGFR after fu_dx
**/
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
proc sort data=ddlong;
 by new_id study_num;
run;
proc sort data=unique_ids;
 by new_id study_num;
run;
data dlongx;
 merge ddlong(in=in1) unique_ids(in=in2) fu_dx;
 by new_id study_num;
 if in1 and in2;
run;
data dlongy;
 set dlongx;
 if visit_time > fu_dx then delete;
run;
data dlong;
 set dlongy;
 drop fu_dx;
run;
data base;
 set dshort;
 %include "&path1\macros\diseases.sas";
 %include "&path1\macros\regions.sas";
 %include "&path1\macros\pooled.sas";
 %include "&path1\macros\interventions.sas";
 %include "&path1\macros\study_interventions_dummies.sas";
run;
/** Get all events **/
libname events excel "&path1\macros\eventsnames.xlsx" mixed=yes;
data eventsfile;
 set events."events3$"n;
run;
libname events clear;
data eventsfile1;
 set eventsfile;
 if eventnumber=. then delete;
run;
proc sql noprint;
  select eventnumber into :eventcounter separated by ' '
  from eventsfile1;
quit;
%macro coxdata1(data,eventfile,out);
proc datasets nolist;
 delete out1 tm0 t1;
run;
quit;
data out1;
 set &data;
 event=0;
 timeevent=0;
 eventnumber=0;
 keep new_id allrx t_assign event timeevent eventnumber combo ztrt1 ztrt2;
run;
%let eventcount=%numwords(&eventcounter);
%do aa1=1 %to &eventcount;
%let eventnumber=%scan(&eventcounter,&aa1,' ');
proc datasets nolist;
 delete tm0 t1;
run;
quit;
data tm0;
 set &eventfile;
 if eventnumber=&eventnumber;
run;
proc sql noprint;
  select eventx,timex into :event,:time
  from tm0;
quit;
data t1;
 set &data;
 event=&event;
 timeevent=&time;
 eventnumber=&eventnumber;
 keep new_id allrx t_assign event timeevent eventnumber combo ztrt1 ztrt2;
run;
data out1;
 set out1 t1;
run;
proc datasets nolist;
 delete tm0 t1;
run;
quit;
%end;
data &out;
 set out1;
 if eventnumber=0 then delete;
run;
proc datasets nolist;
 delete out1 tm0 t1;
run;
quit;
%mend;
%coxdata1(base,eventsfile1,coxbase);
proc sql noprint;
 create table totalevents as
 select eventnumber,allrx, sum(event) as alltotalevents
from coxbase
group by eventnumber,allrx;
quit;
proc sql noprint;
 create table totalevents_tassign as
 select eventnumber,allrx,t_assign, sum(event) as alltotalevents
from coxbase
group by eventnumber,allrx,t_assign;
quit;
data totalevents_tassign0;
 set totalevents_tassign;
 if t_assign=0;
 rename alltotalevents=alltotalevents0;
run;
data totalevents_tassign1;
 set totalevents_tassign;
 if t_assign=1;
 rename alltotalevents=alltotalevents1;
run;
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
%coxps(coxbase,eventnumber allrx,timeevent,event,combo,t_assign,ztrt1 ztrt2,allcoxmodels);
ods listing;
options notes nomprint nosymbolgen nomlogic;
proc sort data=allcoxmodels;
 by allrx;
run;
proc sort data=allrxstudies;
 by allrx;
run;
data allcoxmodels1;
 merge allrxstudies allcoxmodels(in=in1);
 by allrx;
 if in1;
run;
proc sort data=allcoxmodels1;
 by eventnumber;
run;
proc sort data=eventsfile1;
 by eventnumber;
run;
data allcoxmodels2;
 merge allcoxmodels1 eventsfile1;
 by eventnumber;
run;
proc sort data=allcoxmodels2;
 by eventnumber allrx;
run; 
proc sort data=totalevents;
 by eventnumber allrx;
run; 
proc sort data=totalevents_tassign0;
 by eventnumber allrx;
run; 
proc sort data=totalevents_tassign1;
 by eventnumber allrx;
run; 
data allcoxmodels3;
 merge allcoxmodels2 totalevents totalevents_tassign0(drop=t_assign) totalevents_tassign1(drop=t_assign);
 by eventnumber allrx;
run; 
data allcoxmodels4;
 length allrx 8. allrxname $19.  region 8. region_fmt $13. pooled 8. pooled_fmt $19. intervention 8. intervention_fmt $29. intervention_abrev $7.
	    disease 8. disease_fmt $22. disease2 8. disease2_fmt $22. include_ia 8. eventnumber 8. eventname $8.;
 set allcoxmodels3;
 if alltotalevents < 10 then use_allrx=1;
  else if alltotalevents >= 10 and min(alltotalevents0,alltotalevents1) < 3 then use_allrx=2;
  else use_allrx=3;
 drop eventx timex eventname1;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
proc sort data=allcoxmodels4;
 by allrx;
run;
data allcoxmodels4;
 merge allcoxmodels4(in=in1) zallrxstudies;
 by allrx;
 if in1;
run;
proc sort data=allcoxmodels4;
 by zallrx eventnumber;
run;
%zexportcsv(allcoxmodels4,egfrslope_txteff_ce,&path1\analysis_egfrslope\&t.\&t._exports);
data Exports.egfrslope_txteff_ce;
 set allcoxmodels4;
run;
/** t_assign row only **/
data zzallcoxmodels4;
 length allrx 8. allrxname $19.  region 8. region_fmt $13. pooled 8. pooled_fmt $19. intervention 8. intervention_fmt $29. intervention_abrev $7.
	    disease 8. disease_fmt $22. disease2 8. disease2_fmt $22. include_ia 8. eventnumber 8. eventname $8.;
 set allcoxmodels4;
 if compress(parameter)="T_assign";
 if stderr=. or stderr > 1000 or status=2 then do;
  hazardratio=.;
  hrlowercl=.;
  hruppercl=.;
 end;
run;
%zexportcsv(zzallcoxmodels4,egfrslope_txteff_ce1,&path1\analysis_egfrslope\&t.\&t._exports);
/** data for MA in R **/
data updatedallrxdata;
 set exports.updatedallrxdata;
 keep allrx b_ckdegfr_mean zzupro_median;
run;
proc sort data=updatedallrxdata;
 by allrx;
run;
proc sort data=zzallcoxmodels4;
 by allrx;
run;
data egfrslope_txteff_ce_r;
 merge zzallcoxmodels4(in=in1) updatedallrxdata;
 by allrx;
 if in1;
run;
proc sort data=egfrslope_txteff_ce_r;
 by zallrx eventnumber;
run;
data Exports.egfrslope_txteff_ce_r;
 set egfrslope_txteff_ce_r;
run;
%zexportcsv(egfrslope_txteff_ce_r,egfrslope_txteff_ce_r,&path1\analysis_egfrslope\&t.\&t._exports);






