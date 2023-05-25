%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean3 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");

data zallrxstudies;
 set pclean3.zallrxdata;
run;
data txt_endpt;
 set Exports.txt_effects_endpoints2;
run;
data txt_up;
 set Exports.txt_effects_up2;
run;
data noint_txt_up;
 set Exports.noint_txt_effects_up2;
run;
data txt_up1;
 set txt_up;
 if compress(variable)="T_assign";
 keep datagrp1 datagrp2 allrxname allrx period model gmr gmr_lcl95 gmr_ucl95 _rsq_
      dataused datausedname allrx_year region region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev 
      disease disease_fmt disease2 disease2_fmt include_ia calc_b_n_egfr calc_b_mean_egfr calc_b_n_up calc_b_median_up;
run;
data txt_up2;
 set noint_txt_up;
 if compress(variable)="t_assign0";
 gmr0=gmr;
 gmr0_lcl95=gmr_lcl95;
 gmr0_ucl95=gmr_ucl95;
 keep datagrp1 datagrp2 allrxname allrx period model gmr0 gmr0_lcl95 gmr0_ucl95
      dataused datausedname allrx_year region region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev 
     disease disease_fmt disease2 disease2_fmt include_ia calc_b_n_egfr calc_b_mean_egfr calc_b_n_up calc_b_median_up;
run;
data txt_up3;
 set noint_txt_up;
 if compress(variable)="t_assign1";
 gmr1=gmr;
 gmr1_lcl95=gmr_lcl95;
 gmr1_ucl95=gmr_ucl95;
 keep datagrp1 datagrp2 allrxname allrx period model gmr1 gmr1_lcl95 gmr1_ucl95
     dataused datausedname allrx_year region region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev 
     disease disease_fmt disease2 disease2_fmt include_ia calc_b_n_egfr calc_b_mean_egfr calc_b_n_up calc_b_median_up;
run;
proc sort data=txt_up1;
 by datagrp2 allrx period model;
run;
proc sort data=txt_up2;
 by datagrp2 allrx period model;
run;
proc sort data=txt_up3;
 by datagrp2 allrx period model;
run;
data all_txt_up;
 merge txt_up1 txt_up2 txt_up3;
 by datagrp2 allrx period model;
run;
data txt_endpt1;
 set txt_endpt;
 if compress(Parameter)="T_assign";
 if stderr=. or stderr > 1000 or status=2 then do;
  hazardratio=.;
  hrlowercl=.;
  hruppercl=.;
 end;
 keep datagrp1 datagrp2 allrxname allrx dataset hazardratio hrlowercl hruppercl freq0 colp0 freq1 colp1 total event 
      eventnumber eventname alltotalevents alltotalevents1 alltotalevents0 use_allrx
      dataused datausedname allrx_year region region_fmt pooled pooled_fmt intervention intervention_fmt intervention_abrev 
      disease disease_fmt disease2 disease2_fmt include_ia calc_b_n_egfr calc_b_mean_egfr calc_b_n_up calc_b_median_up eventnumber eventname;
run;
proc sql; 
  create table t8 as
  select  * 
  from txt_endpt1,all_txt_up
  where txt_endpt1.allrx=all_txt_up.allrx and txt_endpt1.datagrp2=all_txt_up.datagrp2;
quit;
data t8both;
 set t8;
 ratio=hazardratio/gmr;
 if compress(dataset)="1.All" or (compress(period)="2.6m" and compress(dataset)="2.6m")
    or (compress(period)="3.12m" and compress(dataset)="3.12m");
run;
proc sort data=t8both;
 by allrx;
run;
proc sort data=zallrxstudies;
 by allrx;
run;
data t8both;
 merge t8both(in=in1) zallrxstudies;
 by allrx;
 if in1;
run;
proc sort data=t8both;
 by datagrp2 zallrx period model eventnumber;
run;
%zexportcsv(t8both,txteffectstable,&path1\analysis_acr\acr_exports);
%zexportxlsx2007(t8both,txteffectstable,&path1\analysis_acr\acr_exports);
data Exports.txteffectstable;
 set t8both;
run;
data txteffectstable1;
 set t8both;
 if compress(model)="1.Unadjusted" then delete;
 if compress(period)="2.6m" and compress(dataset) not in ("2.6m") then delete;
 if compress(period)="3.12m" and compress(dataset) not in ("3.12m") then delete;
run;
%zexportcsv(txteffectstable1,txteffectstable1,&path1\analysis_acr\acr_exports);
%zexportxlsx2007(txteffectstable1,txteffectstable1,&path1\analysis_acr\acr_exports);
data Exports.txteffectstable1;
 set txteffectstable1;
run;
