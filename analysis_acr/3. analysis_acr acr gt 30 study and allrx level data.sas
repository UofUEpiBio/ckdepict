%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean3 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");

/** All: Baseline eGFR and UP **/
data baseall;
 set pclean3.fda2_allrx;
 if zacr > 30;
run;
ods listing close;
proc means data=baseall n mean median;
 var b_CKDegfr zzupro;
 class datagrp1 datagrp2 allrx;
 ods output summary=b_gfr_up_all;
run;
data b_gfr_up_all;
 set b_gfr_up_all;
 calc_b_n_egfr=b_CKDegfr_n;
 calc_b_mean_egfr=b_CKDegfr_mean;
 calc_b_n_up=zzupro_n;
 calc_b_median_up=zzupro_median;
 dataused=1;
 datausedname="All included ";
 keep dataused datausedname allrx datagrp1 datagrp2 calc_b_mean_egfr calc_b_median_up calc_b_n_egfr
      calc_b_n_up;
run;
proc sort data=b_gfr_up_all;
 by datagrp2 allrx;
run;
data b_gfr_up_all_acr30;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_all;
run;
data pclean3.b_gfr_up_all_acr30;
 set b_gfr_up_all_acr30;
run;
data Exports.b_gfr_up_all_acr30;
 set b_gfr_up_all_acr30;
run;
%contentsdata(b_gfr_up_all_acr30,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_all_acr30,b_gfr_up_all_acr30,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_all_acr30,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_all_acr30,b_gfr_up_all_acr30,&path1\analysis_acr\acr_exports);
/** 6-month: Baseline eGFR and UP **/
data base6m;
 set pclean3.fda2_allrx;
 if delupro6=. then delete;
 if zacr > 30;
run;
ods listing close;
proc means data=base6m n mean median;
 var b_CKDegfr zzupro;
 class datagrp1 datagrp2 allrx;
 ods output summary=b_gfr_up_6m;
run;
data b_gfr_up_6m;
 set b_gfr_up_6m;
 calc_b_n_egfr=b_CKDegfr_n;
 calc_b_mean_egfr=b_CKDegfr_mean;
 calc_b_n_up=zzupro_n;
 calc_b_median_up=zzupro_median;
 dataused=2;
 datausedname="6-month sample ";
 keep dataused datausedname allrx datagrp1 datagrp2 calc_b_mean_egfr calc_b_median_up calc_b_n_egfr
      calc_b_n_up;
run;
proc sort data=b_gfr_up_6m;
 by datagrp2 allrx;
run;
data b_gfr_up_6m_acr30;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_6m;
run;
data pclean3.b_gfr_up_6m_acr30;
 set b_gfr_up_6m_acr30;
run;
data Exports.b_gfr_up_6m_acr30;
 set b_gfr_up_6m_acr30;
run;
%contentsdata(b_gfr_up_6m_acr30,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_6m_acr30,b_gfr_up_6m_acr30,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_6m_acr30,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_6m_acr30,b_gfr_up_6m_acr30,&path1\analysis_acr\acr_exports);
/** 12-month: Baseline eGFR and UP **/
data base12m;
 set pclean3.fda2_allrx;
 if delupro12=. then delete;
 if zacr > 30;
run;
ods listing close;
ods listing;
proc means data=base12m n mean median;
 var b_CKDegfr zzupro;
 class datagrp1 datagrp2 allrx;
 ods output summary=b_gfr_up_12m;
run;
data b_gfr_up_12m;
 set b_gfr_up_12m;
 calc_b_n_egfr=b_CKDegfr_n;
 calc_b_mean_egfr=b_CKDegfr_mean;
 calc_b_n_up=zzupro_n;
 calc_b_median_up=zzupro_median;
 dataused=3;
 datausedname="12-month sample";
 keep dataused datausedname allrx datagrp1 datagrp2 calc_b_mean_egfr calc_b_median_up calc_b_n_egfr calc_b_n_up;
run;
proc sort data=b_gfr_up_12m;
 by datagrp2 allrx;
run;
data b_gfr_up_12m_acr30;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_12m;
run;
data pclean3.b_gfr_up_12m_acr30;
 set b_gfr_up_12m_acr30;
run;
data Exports.b_gfr_up_12m_acr30;
 set b_gfr_up_12m_acr30;
run;
%contentsdata(b_gfr_up_12m_acr30,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_12m_acr30,b_gfr_up_12m_acr30,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_12m_acr30,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_12m_acr30,b_gfr_up_12m_acr30,&path1\analysis_acr\acr_exports);
/** 9-month: Baseline eGFR and UP **/
data base9m;
 set pclean3.fda2_allrx;
 if delupro9=. then delete;
 if zacr > 30;
run;
ods listing close;
ods listing;
proc means data=base9m n mean median;
 var b_CKDegfr zzupro;
 class datagrp1 datagrp2 allrx;
 ods output summary=b_gfr_up_9m;
run;
data b_gfr_up_9m;
 set b_gfr_up_9m;
 calc_b_n_egfr=b_CKDegfr_n;
 calc_b_mean_egfr=b_CKDegfr_mean;
 calc_b_n_up=zzupro_n;
 calc_b_median_up=zzupro_median;
 dataused=4;
 datausedname="9-month sample";
 keep dataused datausedname allrx datagrp1 datagrp2 calc_b_mean_egfr calc_b_median_up calc_b_n_egfr calc_b_n_up;
run;
proc sort data=b_gfr_up_9m;
 by datagrp2 allrx;
run;
data b_gfr_up_9m_acr30;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_9m;
run;
data pclean3.b_gfr_up_9m_acr30;
 set b_gfr_up_9m_acr30;
run;
data Exports.b_gfr_up_9m_acr30;
 set b_gfr_up_9m_acr30;
run;
%contentsdata(b_gfr_up_9m_acr30,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_9m_acr30,b_gfr_up_9m_acr30,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_9m_acr30,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_9m_acr30,b_gfr_up_9m_acr30,&path1\analysis_acr\acr_exports);
/** study level **/
data fda2_study;
 set pclean3.fda2_study;
 if zacr > 30;
run;
proc sort data=fda2_study out=studydata nodupkey;
 by study_num;
run;
data studydata_acr30;
 length study_num 8. studyname $17. 
        study_year 8.
        region 8. region_fmt $13. 
        disease 8. disease_fmt $22.
        disease2 8. disease2_fmt $22.;
 set studydata;
 keep study_num studyname study_year region region_fmt disease disease_fmt disease2 disease2_fmt;
run; 
data pclean3.studydata_acr30;
 set studydata_acr30;
run;
data Exports.studydata_acr30;
 set studydata_acr30;
run;
%contentsdata(studydata_acr30,&path1\analysis_acr\datasets);
%zexportxlsx(studydata_acr30,studydata_acr30,&path1\analysis_acr\datasets);
%contentsdata(studydata_acr30,&path1\analysis_acr\acr_exports);
%zexportxlsx(studydata_acr30,studydata_acr30,&path1\analysis_acr\acr_exports);
