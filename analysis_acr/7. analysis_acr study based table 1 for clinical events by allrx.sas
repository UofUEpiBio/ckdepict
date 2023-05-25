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
 ev1=ev_dg_40_p_con;
 fu1=fu_dg_40_p_con;
 ev2=ev_dg_30_p_con;
 fu2=fu_dg_30_p_con;
 ev3=ev_dgs_con;
 fu3=fu_dgs_con;
 ev4=ev_dg_con;
 fu4=fu_dg_con;
 ev5=ev_dgsx_con;
 fu5=fu_dgsx_con;
 ev6=ev_d;
 fu6=fu_d;
 ev7=ev_dx;
 fu7=fu_dx;
 ev8=ev_40_p_con;
 fu8=mos_40_p_con;
 ev9=ev_30_p_con;
 fu9=mos_30_p_con;
 if include_ia=1;
 if datagrp2=1;
 /** for IDNT, change allrx so we have 1 row for this study **/
 if allrx in (38 39) then allrx=38;
 /** Note to Hiddo: We did this to keep only one unique study for each allrx, 
           You need to change this only if you have to **/
run;
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
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 ev9 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8 fu9;
 class datagrp2 allrx;
 ods output summary=t0;
run;
data t0;
 length allrx datagrp2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75 8.;
 set t0;
 keep allrx datagrp2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75;
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
proc means data=base1 sum mean median p25 p75 nway;
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 ev9 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8 fu9;
 class datagrp2 intervention;
 ods output summary=t0;
run;
data t0;
 length datagrp2 intervention 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75 8.;
 set t0;
 keep datagrp2 intervention 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75;
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
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 ev9 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8 fu9;
 class datagrp2 disease;
 ods output summary=t0;
run;
data t0;
 length datagrp2 disease 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75 8.;
 set t0;
 keep datagrp2 disease 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75;
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
 var ev1 ev2 ev3 ev4 ev5 ev6 ev7 ev8 ev9 fu1 fu2 fu3 fu4 fu5 fu6 fu7 fu8 fu9;
 class datagrp2 disease2;
 ods output summary=t0;
run;
data t0;
 length datagrp2 disease2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75 8.;
 set t0;
 keep datagrp2 disease2 
     ev1_sum ev1_mean fu1_median fu1_p25 fu1_p75 ev2_sum ev2_mean fu2_median fu2_p25 fu2_p75
	 ev3_sum ev3_mean fu3_median fu3_p25 fu3_p75 ev4_sum ev4_mean fu4_median fu4_p25 fu4_p75
	 ev5_sum ev5_mean fu5_median fu5_p25 fu5_p75 ev6_sum ev6_mean fu6_median fu6_p25 fu6_p75
	 ev7_sum ev7_mean fu7_median fu7_p25 fu7_p75 ev8_sum ev8_mean fu8_median fu8_p25 fu8_p75
	 ev9_sum ev9_mean fu9_median fu9_p25 fu9_p75;
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
%eventstable(fda2_allrx,age,zevxt1b,zevxt1c,zevxt1d,zevxt1e);




