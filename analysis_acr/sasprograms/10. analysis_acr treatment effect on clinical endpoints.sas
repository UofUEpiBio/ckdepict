%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean3 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");

data zallrxstudies;
 set pclean3.zallrxdata;
run;
data upro_change6m;
 set pclean3.fda2_allrx;
 delta_up=delupro6;
 dataset="2.6m ";
 keep datagrp2 dataset allrx new_id delta_up;
run;
data upro_change12m;
 set pclean3.fda2_allrx;
 delta_up=delupro12;
 dataset="3.12m";
 keep datagrp2 dataset allrx new_id delta_up;
run;
data upro_all;
 set upro_change6m upro_change12m;
run;
data bstudies;
 set pclean3.allrxdata;
run;
data cstudies;
 set pclean3.b_gfr_up_all pclean3.b_gfr_up_6m pclean3.b_gfr_up_12m;
      if datausedname="All included"    then dataset="1.All";
 else if datausedname="6-month sample"  then dataset="2.6m ";
 else if datausedname="12-month sample" then dataset="3.12m";
run;
proc sort data=bstudies;
 by allrx;
run;
proc sort data=cstudies;
 by allrx;
run;
data studies;
 merge bstudies cstudies;
 by allrx;
run;
data baseall;
 set pclean3.fda2_allrx;
run;
proc sort data=baseall;
 by datagrp2 allrx new_id;
run;
proc sort data=upro_all;
 by datagrp2 allrx new_id;
run;
data baseall1;
 merge baseall upro_all;
 by datagrp2 allrx new_id;
run;
data baseall2;
 set baseall (in=in1) baseall1;
 if in1 then do;
 dataset="1.All";
 delta_up=9999;
 end;
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
 keep datagrp2 dataset new_id allrx t_assign event timeevent eventnumber delta_up combo ztrt1 ztrt2;
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
 keep datagrp2 dataset new_id allrx t_assign event timeevent eventnumber delta_up combo ztrt1 ztrt2;
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
 if dataset="2.6m " and delta_up=. then do;event=.;timeevent=.;end;
 if dataset="3.12m" and delta_up=. then do;event=.;timeevent=.;end;
run;
proc datasets nolist;
 delete out1 tm0 t1;
run;
quit;
%mend;
%coxdata1(baseall2,eventsfile1,cox_baseall);
data cox_baseall1;
 set cox_baseall;
run;
proc sql noprint;
 create table totalevents as
 select datagrp2,dataset,eventnumber,allrx, sum(event) as alltotalevents
from cox_baseall1
group by datagrp2,dataset,eventnumber,allrx;
quit;
proc sql noprint;
 create table totalevents_tassign as
 select datagrp2,dataset,eventnumber,allrx,t_assign, sum(event) as alltotalevents
from cox_baseall1
group by datagrp2,dataset,eventnumber,allrx,t_assign;
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
%coxps(cox_baseall1,datagrp2 dataset eventnumber allrx,timeevent,event,combo,t_assign,ztrt1 ztrt2,allcoxmodels);
proc sort data=allcoxmodels;
 by dataset datagrp2 allrx;
run;
proc sort data=studies;
 by dataset datagrp2 allrx;
run;
data allcoxmodels1;
 merge studies allcoxmodels(in=in1);
 by dataset datagrp2 allrx;
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
 by datagrp2 dataset eventnumber allrx;
run; 
proc sort data=totalevents;
 by datagrp2 dataset eventnumber allrx;
run; 
proc sort data=totalevents_tassign0;
 by datagrp2 dataset eventnumber allrx;
run; 
proc sort data=totalevents_tassign1;
 by datagrp2 dataset eventnumber allrx;
run; 
data allcoxmodels3;
 merge allcoxmodels2 totalevents totalevents_tassign0(drop=t_assign) totalevents_tassign1(drop=t_assign);
 by datagrp2 dataset eventnumber allrx;
run; 
data allcoxmodels4;
 length dataused 8. datausedname $15. datagrp2 8. datagrp1 $12. allrx 8. allrxname $19.  allrx_year $16. 
        region 8. region_fmt $13. pooled 8. pooled_fmt $19. intervention 8. intervention_fmt $29. intervention_abrev $7.
	    disease 8. disease_fmt $22. disease2 8. disease2_fmt $22. include_ia 8. calc_b_n_egfr	calc_b_mean_egfr calc_b_n_up calc_b_median_up 8. 
        eventnumber 8. eventname $8. dataset $5.;
 set allcoxmodels3;
 if alltotalevents < 10 then use_allrx=1;
  else if alltotalevents >= 10 and min(alltotalevents0,alltotalevents1) < 3 then use_allrx=2;
  else use_allrx=3;
 drop eventx timex eventname1;
 if dataused=. then delete;
run;
proc sort data=allcoxmodels4;
 by allrx;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
data allcoxmodels4;
 merge allcoxmodels4(in=in1) zallrxstudies;
 by allrx;
 if in1;
run;
proc sort data=allcoxmodels4;
 by datagrp2 dataset eventnumber zallrx;
run;
%zexportcsv(allcoxmodels4,txt_effects_endpoints2,&path1\analysis_acr\acr_exports);
%zexportxlsx2007(allcoxmodels4,txt_effects_endpoints2,&path1\analysis_acr\acr_exports);
data Exports.txt_effects_endpoints2;
 set allcoxmodels4;
run;
/** This is for a linked Excel table, keep only the t_assign row **/
data zallcoxmodels4;
 length dataused 8. datausedname $15. datagrp2 8. datagrp1 $12. allrx 8. allrxname $19.  allrx_year $16. 
        region 8. region_fmt $13. pooled 8. pooled_fmt $19. intervention 8. intervention_fmt $29. intervention_abrev $7.
	    disease 8. disease_fmt $22. disease2 8. disease2_fmt $22. include_ia 8. calc_b_n_egfr	calc_b_mean_egfr calc_b_n_up calc_b_median_up 8. 
        eventnumber 8. eventname $8. dataset $5.;
 set allcoxmodels3;
 if alltotalevents < 10 then use_allrx=1;
  else if alltotalevents >= 10 and min(alltotalevents0,alltotalevents1) < 3 then use_allrx=2;
  else use_allrx=3;
 drop eventx timex eventname1;
 if dataused=. then delete;
 if compress(parameter)="T_assign";
 *if datausedname="All included" then delete;
 if stderr=. or stderr > 1000 or status=2 then do;
  hazardratio=.;
  hrlowercl=.;
  hruppercl=.;
 end;
run;
proc sort data=zallcoxmodels4;
 by allrx;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
data zallcoxmodels4;
 merge zallcoxmodels4(in=in1) zallrxstudies;
 by allrx;
 if in1;
run;
proc sort data=zallcoxmodels4;
 by datagrp2 dataset eventnumber zallrx;
run;
%zexportcsv(zallcoxmodels4,txt_effects_endpoints2a,&path1\analysis_acr\acr_exports);
