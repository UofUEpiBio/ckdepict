%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean3 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");

/** Allrx, allrxname, study, studyname in one file **/
data dallrx;
 set pclean3.fda2_allrx;
run;
proc sort data=dallrx out=dallrx nodupkey;
 by allrx;
run;
data pclean3.allrx_acr_sens;
 set dallrx;
 keep allrx incl_acr_efct_alb;
run; 
data dallrx;
 set dallrx;
 keep allrx allrxname study_num;
run; 
data dstudy;
 set pclean3.fda2_study;
run;
proc sort data=dstudy out=dstudy nodupkey;
 by study_num;
run;
data dstudy;
 set dstudy;
 keep study_num studyname;
run; 
proc sort data=dallrx;
 by study_num;
run;
proc sort data=dstudy;
 by study_num;
run;
data allrxstudy;
 merge dstudy dallrx;
 by study_num;
run;
proc sort data=allrxstudy;
 by allrx;
run;
data allrxstudy;
 length allrx 8. allrxname $17.
        study_num 8. studyname $17.;
 set allrxstudy;
run;
data pclean3.allrxstudy;
 set allrxstudy;
run;
data Exports.allrxstudy;
 set allrxstudy;
run;
%contentsdata(allrxstudy,&path1\analysis_acr\datasets);
%zexportxlsx(allrxstudy,allrxstudy,&path1\analysis_acr\datasets);
%contentsdata(allrxstudy,&path1\analysis_acr\acr_exports);
%zexportxlsx(allrxstudy,allrxstudy,&path1\analysis_acr\acr_exports);


/** Allrx level **/
data fda2_allrx;
 set pclean3.fda2_allrx;
run;
proc sort data=fda2_allrx out=allrxdata nodupkey;
 by allrx;
run;
data allrxdata;
 set allrxdata;
 keep allrx allrxname intervention intervention_fmt intervention_abrev include_ia pooled pooled_fmt 
      region region_fmt disease disease_fmt disease2 disease2_fmt allrx_year;
run; 
data allrxdata;
 length allrx 8. allrxname $19. 
        allrx_year $18.
        region 8. region_fmt $13. 
        pooled 8. pooled_fmt $19. 
        intervention 8. intervention_fmt $29. intervention_abrev $7.
	    disease 8.  disease_fmt $22. 
		disease2 8. disease2_fmt $22.
        include_ia 8.;
 set allrxdata;
run;
data pclean3.allrxdata;
 set allrxdata;
run;
data Exports.allrxdata;
 set allrxdata;
run;
%contentsdata(allrxdata,&path1\analysis_acr\datasets);
%zexportxlsx(allrxdata,allrxdata,&path1\analysis_acr\datasets);
%contentsdata(allrxdata,&path1\analysis_acr\acr_exports);
%zexportxlsx(allrxdata,allrxdata,&path1\analysis_acr\acr_exports);
/** New allrx name and other allrx level variables needed **/
/** Allrx level new names **/
data zfda2_allrx;
 set pclean3.fda2_allrx;
 allrxname1=studyname1;
 zallrx=allrx;
 if zallrx=500 then zallrx=80;
run;
proc sort data=zfda2_allrx out=zallrxdata nodupkey;
 by allrx;
run;
data zallrxdata;
 set zallrxdata;
 keep allrx zallrx allrxname1 study_code;
run; 
proc sort data=zallrxdata;
 by zallrx;
run;
data zallrxdata;
 length allrx zallrx 8. allrxname1 $18. study_code $5.;
 set zallrxdata;
run;
data pclean3.zallrxdata;
 set zallrxdata;
run;
data Exports.zallrxdata;
 set zallrxdata;
run;
%contentsdata(zallrxdata,&path1\analysis_acr\datasets);
%zexportxlsx(zallrxdata,zallrxdata,&path1\analysis_acr\datasets);
%contentsdata(zallrxdata,&path1\analysis_acr\acr_exports);
%zexportxlsx(zallrxdata,zallrxdata,&path1\analysis_acr\acr_exports);
/** All: Baseline eGFR and UP **/
data baseall;
 set pclean3.fda2_allrx;
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
data b_gfr_up_all;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_all;
run;
data pclean3.b_gfr_up_all;
 set b_gfr_up_all;
run;
data Exports.b_gfr_up_all;
 set b_gfr_up_all;
run;
%contentsdata(b_gfr_up_all,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_all,b_gfr_up_all,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_all,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_all,b_gfr_up_all,&path1\analysis_acr\acr_exports);
/** 6-month: Baseline eGFR and UP **/
data base6m;
 set pclean3.fda2_allrx;
 if delupro6=. then delete;
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
data b_gfr_up_6m;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_6m;
run;
data pclean3.b_gfr_up_6m;
 set b_gfr_up_6m;
run;
data Exports.b_gfr_up_6m;
 set b_gfr_up_6m;
run;
%contentsdata(b_gfr_up_6m,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_6m,b_gfr_up_6m,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_6m,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_6m,b_gfr_up_6m,&path1\analysis_acr\acr_exports);
/** 12-month: Baseline eGFR and UP **/
data base12m;
 set pclean3.fda2_allrx;
 if delupro12=. then delete;
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
data b_gfr_up_12m;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_12m;
run;
data pclean3.b_gfr_up_12m;
 set b_gfr_up_12m;
run;
data Exports.b_gfr_up_12m;
 set b_gfr_up_12m;
run;
%contentsdata(b_gfr_up_12m,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_12m,b_gfr_up_12m,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_12m,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_12m,b_gfr_up_12m,&path1\analysis_acr\acr_exports);
/** 9-month: Baseline eGFR and UP **/
data base9m;
 set pclean3.fda2_allrx;
 if delupro9=. then delete;
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
data b_gfr_up_9m;
length  dataused 8. datausedname $15. 
        datagrp2 8. datagrp1 $12. 
        allrx 8.;
 set b_gfr_up_9m;
run;
data pclean3.b_gfr_up_9m;
 set b_gfr_up_9m;
run;
data Exports.b_gfr_up_9m;
 set b_gfr_up_9m;
run;
%contentsdata(b_gfr_up_9m,&path1\analysis_acr\datasets);
%zexportxlsx(b_gfr_up_9m,b_gfr_up_9m,&path1\analysis_acr\datasets);
%contentsdata(b_gfr_up_9m,&path1\analysis_acr\acr_exports);
%zexportxlsx(b_gfr_up_9m,b_gfr_up_9m,&path1\analysis_acr\acr_exports);
/** study level **/
data fda2_study;
 set pclean3.fda2_study;
run;
proc sort data=fda2_study out=studydata nodupkey;
 by study_num;
run;
data studydata;
 length study_num 8. studyname $17. 
        study_year 8.
        region 8. region_fmt $13. 
        disease 8. disease_fmt $22.
        disease2 8. disease2_fmt $22.;
 set studydata;
 keep study_num studyname study_year region region_fmt disease disease_fmt disease2 disease2_fmt;
run; 
data pclean3.studydata;
 set studydata;
run;
data Exports.studydata;
 set studydata;
run;
%contentsdata(studydata,&path1\analysis_acr\datasets);
%zexportxlsx(studydata,studydata,&path1\analysis_acr\datasets);
%contentsdata(studydata,&path1\analysis_acr\acr_exports);
%zexportxlsx(studydata,studydata,&path1\analysis_acr\acr_exports);
