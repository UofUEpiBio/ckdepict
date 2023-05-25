%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean3 "&path1\analysis_acr\datasets";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");

data allrxstudies;
 set pclean3.allrxdata;
run;
proc sort data=allrxstudies;
 by allrx;
run;
data zallrxstudies;
 set pclean3.zallrxdata;
run;
data fda2_allrx;
 set pclean3.fda2_allrx;
 ev1=ev_d;
 ev2=ev_s;
 ev3=ev_15_t_con;
 ev4=ev_x;
 ev5=ev_dgs_con;
 ev6=ev_dgsx_con;
 fu1=fu_dgs_con;
 fu2=fu_dgsx_con;
 if include_ia=1;
 if datagrp2=1;
 /** for IDNT, change allrx so we have 1 row for this study **/
 if allrx in (38 39) then allrx=38;
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
data t3;
 merge t2(in=in1) zallrxstudies;
 by allrx;
 if in1;
run;
proc sort data=t3;
 by datagrp2 zallrx;
run;
%zexportcsv(t3,&out1,&path1\analysis_acr\acr_exports);
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
%zexportcsv(t2,&out2,&path1\analysis_acr\acr_exports);
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
%zexportcsv(t2,&out3,&path1\analysis_acr\acr_exports);
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
%zexportcsv(t2,&out4,&path1\analysis_acr\acr_exports);
proc datasets nolist;
 delete t1 t2 xt1 t0 size base base1;
run;
quit;
%mend;
ods listing close;
options nonotes;
%table1(fda2_allrx,age,zxt1b,zxt1c,zxt1d,zxt1e);







