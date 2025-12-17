%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\quad\datasets";
libname Exports  "&path1\analysis_sets\quad\exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");

data allrxstudies;
 set SASdata.allrxdata;
run;
proc sort data=allrxstudies;
 by allrx;
run;
data zallrxstudies;
 set SASdata.zallrxdata;
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
 %include "&path2\macros\zupro.sas";
 %include "&path2\macros\zuprobinary.sas";
 zupro=zacr;
 zzupro=zacr;
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
proc sort data=fu_dx;
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
data fdac2;
 set dshort;
 ev1=ev_d;
 ev2=ev_s;
 ev3=ev_15_t_con;
 ev4=ev_x;
 ev5=ev_dgs_con;
 ev6=ev_dgsx_con;
 fu1=fu_dgs_con;
 fu2=fu_dgsx_con;
 datagrp1="Overall";
 datagrp2=1;
run;
data fdac2ev;
 set dshort;
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
datagrp1="Overall";
datagrp2=1;
run;
/** Get few variables from StudyDescrip **/
data studydescrip;
 set SASdata.studydescrip;
 allrx=study_num;
 keep allrx knot mean_n_egfr mean_max_visit_time;
run;
/** All **/
%macro table1(data,var,out1,out2,out3,out4);
/** by allrx **/
data base;
 set &data;
 if &var=. then delete;
run;
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,allrx,count(*) as n_allrx_num
 from base
 group by datagrp2,allrx;
quit;
proc sort data=size nodupkey;
 by datagrp2 allrx;
run;
proc sort data=base;
 by datagrp2 allrx;
run;
proc means data=base sum mean std median p25 p75;
 var age female black diab b_ckdegfr zzupro zup1000 zup500 zup50 zup50_500 zup50_1000 ev1 ev2 ev3 ev4 ev5 ev6 fu1 fu2;
 class datagrp2 allrx;
 ods output summary=t0;
run;
data t0;
 length allrx datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75 8.;
 set t0;
 keep allrx datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75;
run;
proc sort data=size;
 by datagrp2 allrx;
run;
proc sort data=t0;
 by datagrp2 allrx;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 allrx;
 if in3;
run;
proc sort data=xt1;
 by allrx;
run;
proc sort data=allrxstudies;
 by allrx;
run;
data t2;
 merge xt1(in=in3) allrxstudies(in=in1);
 by allrx;
 if in3;
run;
proc sort data=t2;
 by allrx;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
proc sort data=studydescrip;
 by allrx;
run;
data t3;
 merge t2(in=in1) zallrxstudies studydescrip;
 by allrx;
 if in1;
run;
proc sort data=t3;
 by datagrp2 zallrx;
run;
%zexportcsv(t3,&out1,&path1\analysis_sets\quad\exports);

data SASdata.updatedallrxdata;
 set t3;
run;

data updatedallrxdata;
 set t3;
run;
%zexportcsv(updatedallrxdata,updatedallrxdata,&path1\analysis_sets\quad\datasets);

data Exports.updatedallrxdata;
 set t3;
run;
%zexportcsv(updatedallrxdata,updatedallrxdata,&path1\analysis_sets\quad\exports);

proc datasets nolist;
 delete t1 t2 t3 xt1 t0 size;
run;
quit;
/** by intervention **/
data base1;
 set base;
 if pooled not in (2);
run;
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,intervention,count(*) as n_intervention
 from base1
 group by datagrp2,intervention;
quit;
proc sort data=size nodupkey;
 by datagrp2 intervention;
run;
proc sort data=base1;
 by datagrp2 intervention;
run;
proc means data=base1 n mean std median p25 p75 sum;
 var age female black diab b_ckdegfr zzupro zup1000 zup500 zup50 zup50_500 zup50_1000 ev1 ev2 ev3 ev4 ev5 ev6 fu1 fu2;
 class datagrp2 intervention;
 ods output summary=t0;
run;
data t0;
 length intervention datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75 8.;
 set t0;
 keep intervention datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75;
run;
proc sort data=size;
 by datagrp2 intervention;
run;
proc sort data=t0;
 by datagrp2 intervention;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 intervention;
 if in3;
run;
proc sort data=xt1;
 by intervention;
run;
proc sort data=allrxstudies out=interventions(keep=intervention intervention_fmt intervention_abrev) nodupkey;
 by intervention;
run;
data t2;
 merge xt1(in=in3) interventions(in=in1);
 by intervention;
 if in3;
run;
proc sort data=t2;
 by datagrp2 intervention;
run;
%zexportcsv(t2,&out2,&path1\analysis_sets\quad\exports);
proc datasets nolist;
 delete t1 t2 xt1 t0 size;
run;
quit;
/** by disease **/
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,disease,count(*) as n_disease
 from base1
 group by datagrp2,disease;
quit;
proc sort data=size nodupkey;
 by datagrp2 disease;
run;
proc sort data=base1;
 by datagrp2 disease;
run;
proc means data=base1 n mean std median p25 p75 sum;
 var age female black diab b_ckdegfr zzupro zup1000 zup500 zup50 zup50_500 zup50_1000 ev1 ev2 ev3 ev4 ev5 ev6 fu1 fu2;
 class datagrp2 disease;
 ods output summary=t0;
run;
data t0;
 length disease datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75 8.;
 set t0;
 keep disease datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75;
run;
proc sort data=size;
 by datagrp2 disease;
run;
proc sort data=t0;
 by datagrp2 disease;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 disease;
 if in3;
run;
proc sort data=xt1;
 by disease;
run;
proc sort data=allrxstudies out=diseases(keep=disease disease_fmt) nodupkey;
 by disease;
run;
data t2;
 merge xt1(in=in3) diseases(in=in1);
 by disease;
 if in3;
run;
proc sort data=t2;
 by datagrp2 disease;
run;
%zexportcsv(t2,&out3,&path1\analysis_sets\quad\exports);
proc datasets nolist;
 delete t1 t2 xt1 t0 size;
run;
quit;
/** by disease2 **/
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,disease2,count(*) as n_disease2
 from base1
 group by datagrp2,disease2;
quit;
proc sort data=size nodupkey;
 by datagrp2 disease2;
run;
proc sort data=base1;
 by datagrp2 disease2;
run;
proc means data=base1 n mean std median p25 p75 sum;
 var age female black diab b_ckdegfr zzupro zup1000 zup500 zup50 zup50_500 zup50_1000 ev1 ev2 ev3 ev4 ev5 ev6 fu1 fu2;
 class datagrp2 disease2;
 ods output summary=t0;
run;
data t0;
 length disease2 datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75 8.;
 set t0;
 keep disease2 datagrp2 age_mean age_stddev female_sum female_mean black_sum black_mean 
      diab_sum diab_mean b_ckdegfr_mean b_ckdegfr_stddev zzupro_median zzupro_p25 zzupro_p75
	  zup1000_sum zup1000_mean zup500_sum zup500_mean zup50_sum zup50_mean zup50_500_sum zup50_500_mean zup50_1000_sum zup50_1000_mean
	  ev1_sum ev1_mean ev2_sum ev2_mean ev3_sum ev3_mean ev4_sum ev4_mean ev5_sum ev5_mean ev6_sum ev6_mean
	  fu1_median fu1_p25 fu1_p75 fu2_median fu2_p25 fu2_p75;
run;
proc sort data=size;
 by datagrp2 disease2;
run;
proc sort data=t0;
 by datagrp2 disease2;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 disease2;
 if in3;
run;
proc sort data=xt1;
 by disease2;
run;
proc sort data=allrxstudies out=disease2s(keep=disease2 disease2_fmt) nodupkey;
 by disease2;
run;
data t2;
 merge xt1(in=in3) disease2s(in=in1);
 by disease2;
 if in3;
run;
proc sort data=t2;
 by datagrp2 disease2;
run;
%zexportcsv(t2,&out4,&path1\analysis_sets\quad\exports);
proc datasets nolist;
 delete t1 t2 xt1 t0 size base base1;
run;
quit;
%mend;
ods listing close;
options nonotes;
%table1(fdac2,age,xxt1b,xxt1c,xxt1d,xxt1e);
/** Event table **/
%macro eventstable(data,var,out1,out2,out3,out4);
/** by allrx **/
data base;
 set &data;
 if &var=. then delete;
run;
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,allrx,count(*) as n_allrx_num
 from base
 group by datagrp2,allrx;
quit;
proc sort data=size nodupkey;
 by datagrp2 allrx;
run;
proc sort data=base;
 by datagrp2 allrx;
run;
proc means data=base sum mean median p25 p75 nway;
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8;
 class datagrp2 allrx;
 ods output summary=t0;
run;
data t0;
 length allrx datagrp2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75 8.;
 set t0;
 keep allrx datagrp2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75;
run;
proc sort data=size;
 by datagrp2 allrx;
run;
proc sort data=t0;
 by datagrp2 allrx;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 allrx;
 if in3;
run;
proc sort data=xt1;
 by allrx;
run;
proc sort data=allrxstudies;
 by allrx;
run;
data t2;
 merge xt1(in=in3) allrxstudies(in=in1);
 by allrx;
 if in3;
run;
proc sort data=t2;
 by allrx;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
proc sort data=studydescrip;
 by allrx;
run;
data t3;
 merge t2(in=in1) zallrxstudies studydescrip;
 by allrx;
 if in1;
run;
proc sort data=t3;
 by datagrp2 zallrx;
run;
%zexportcsv(t3,&out1,&path1\analysis_sets\quad\exports);
proc datasets nolist;
 delete t1 t2 t3 xt1 t0 size;
run;
quit;
/** by intervention **/
data base1;
 set base;
 if pooled not in (2);
run;
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,intervention,count(*) as n_intervention
 from base1
 group by datagrp2,intervention;
quit;
proc sort data=size nodupkey;
 by datagrp2 intervention;
run;
proc sort data=base1;
 by datagrp2 intervention;
run;
proc means data=base1 sum mean median p25 p75 nway;
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8;
 class datagrp2 intervention;
 ods output summary=t0;
run;
data t0;
 length datagrp2 intervention 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75 8.;
 set t0;
 keep datagrp2 intervention 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75;
run;
proc sort data=size;
 by datagrp2 intervention;
run;
proc sort data=t0;
 by datagrp2 intervention;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 intervention;
 if in3;
run;
proc sort data=xt1;
 by intervention;
run;
proc sort data=allrxstudies out=interventions(keep=intervention intervention_fmt intervention_abrev) nodupkey;
 by intervention;
run;
data t2;
 merge xt1(in=in3) interventions(in=in1);
 by intervention;
 if in3;
run;
proc sort data=t2;
 by datagrp2 intervention;
run;
%zexportcsv(t2,&out2,&path1\analysis_sets\quad\exports);
proc datasets nolist;
 delete t1 t2 xt1 t0 size;
run;
quit;
/** All by disease **/
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,disease,count(*) as n_disease
 from base1
 group by datagrp2,disease;
quit;
proc sort data=size nodupkey;
 by datagrp2 disease;
run;
proc sort data=base1;
 by datagrp2 disease;
run;
proc means data=base1 sum mean median p25 p75 nway;
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8;
 class datagrp2 disease;
 ods output summary=t0;
run;
data t0;
 length datagrp2 disease 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75 8.;
 set t0;
 keep datagrp2 disease 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75;
run;
proc sort data=size;
 by datagrp2 disease;
run;
proc sort data=t0;
 by datagrp2 disease;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 disease;
 if in3;
run;
proc sort data=xt1;
 by disease;
run;
proc sort data=allrxstudies out=diseases(keep=disease disease_fmt) nodupkey;
 by disease;
run;
data t2;
 merge xt1(in=in3) diseases(in=in1);
 by disease;
 if in3;
run;
proc sort data=t2;
 by datagrp2 disease;
run;
%zexportcsv(t2,&out3,&path1\analysis_sets\quad\exports);
proc datasets nolist;
 delete t1 t2 xt1 t0 size;
run;
quit;
/** All by disease22 **/
proc sql noprint;
 create table size as
 select datagrp1,datagrp2,disease2,count(*) as n_disease2
 from base1
 group by datagrp2,disease2;
quit;
proc sort data=size nodupkey;
 by datagrp2 disease2;
run;
proc sort data=base1;
 by datagrp2 disease2;
run;
proc means data=base1 sum mean median p25 p75 nway;
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8;
 class datagrp2 disease2;
 ods output summary=t0;
run;
data t0;
 length datagrp2 disease2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75 8.;
 set t0;
 keep datagrp2 disease2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75;
run;
proc sort data=size;
 by datagrp2 disease2;
run;
proc sort data=t0;
 by datagrp2 disease2;
run;
data xt1;
 merge size(in=in2) t0(in=in3);
 by datagrp2 disease2;
 if in3;
run;
proc sort data=xt1;
 by disease2;
run;
proc sort data=allrxstudies out=disease2s(keep=disease2 disease2_fmt) nodupkey;
 by disease2;
run;
data t2;
 merge xt1(in=in3) disease2s(in=in1);
 by disease2;
 if in3;
run;
proc sort data=t2;
 by datagrp2 disease2;
run;
%zexportcsv(t2,&out4,&path1\analysis_sets\quad\exports);
proc datasets nolist;
 delete t1 t2 xt1 t0 size base base1;
run;
quit;
%mend;
ods listing close;
options nonotes;
%eventstable(fdac2ev,age,evxt1b,evxt1c,evxt1d,evxt1e);












