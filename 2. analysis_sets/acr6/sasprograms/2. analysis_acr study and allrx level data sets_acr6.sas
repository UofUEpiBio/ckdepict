%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname SASdata "&path1\analysis_sets\acr6\datasets";
libname Exports "&path1\analysis_sets\acr6\exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path2\macros");

/** Allrx, allrxname, study, studyname in one file **/
data dallrx;
 set SASdata.fda2_allrx;
run;
proc sort data=dallrx out=dallrx nodupkey;
 by allrx;
run;
data SASdata.allrx_acr_sens;
 set dallrx;
 keep allrx incl_acr_efct_alb;
run; 
data dallrx;
 set dallrx;
 keep allrx allrxname study_num;
run; 
data dstudy;
 set SASdata.fda2_study;
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
data allrxstudy_acr6;
 length allrx 8. allrxname $17.
        study_num 8. studyname $17.;
 set allrxstudy;
run;
data SASdata.allrxstudy_acr6;
 set allrxstudy;
run;
data Exports.allrxstudy_acr6;
 set allrxstudy;
run;
%zexportcsv(allrxstudy_acr6,allrxstudy_acr6,&path1\analysis_sets\acr6\datasets);
%zexportcsv(allrxstudy_acr6,allrxstudy_acr6,&path1\analysis_sets\acr6\exports);

/** Allrx level **/
data fda2_allrx;
 set SASdata.fda2_allrx;
run;
proc sort data=fda2_allrx out=allrxdata nodupkey;
 by allrx;
run;
data allrxdata;
 set allrxdata;
 keep allrx allrxname intervention intervention_fmt intervention_abrev include_ia pooled pooled_fmt 
      region region_fmt disease disease_fmt disease2 disease2_fmt allrx_year;
run; 
data allrxdata_acr6;
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
data SASdata.allrxdata_acr6;
 set allrxdata_acr6;
run;
data Exports.allrxdata_acr6;
 set allrxdata_acr6;
run;
%zexportcsv(allrxdata_acr6,allrxdata_acr6,&path1\analysis_sets\acr6\datasets);
%zexportcsv(allrxdata_acr6,allrxdata_acr6,&path1\analysis_sets\acr6\exports);
/** New allrx name and other allrx level variables needed **/
/** Allrx level new names **/
data zfda2_allrx;
 set SASdata.fda2_allrx;
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
data zallrxdata_acr6;
 length allrx zallrx 8. allrxname1 $18. study_code $5.;
 set zallrxdata;
run;
data SASdata.zallrxdata_acr6;
 set zallrxdata_acr6;
run;
data Exports.zallrxdata_acr6;
 set zallrxdata_acr6;
run;
%zexportcsv(zallrxdata_acr6,zallrxdata_acr6,&path1\analysis_sets\acr6\datasets);
%zexportcsv(zallrxdata_acr6,zallrxdata_acr6,&path1\analysis_sets\acr6\exports);
/** 6-month: Baseline eGFR and UP **/
data base6m;
 set SASdata.fda2_allrx;
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
data SASdata.b_gfr_up_6m;
 set b_gfr_up_6m;
run;
data Exports.b_gfr_up_6m;
 set b_gfr_up_6m;
run;
%zexportcsv(b_gfr_up_6m,b_gfr_up_6m,&path1\analysis_sets\acr6\datasets);
%zexportcsv(b_gfr_up_6m,b_gfr_up_6m,&path1\analysis_sets\acr6\exports);

/** study level **/
data fda2_study;
 set SASdata.fda2_study;
run;
proc sort data=fda2_study out=studydata nodupkey;
 by study_num;
run;
data studydata_acr6;
 length study_num 8. studyname $17. 
        study_year 8.
        region 8. region_fmt $13. 
        disease 8. disease_fmt $22.
        disease2 8. disease2_fmt $22.;
 set studydata;
 keep study_num studyname study_year region region_fmt disease disease_fmt disease2 disease2_fmt;
run; 
data SASdata.studydata_acr6;
 set studydata_acr6;
run;
data Exports.studydata_acr6;
 set studydata_acr6;
run;
%zexportcsv(studydata_acr6,studydata_acr6,&path1\analysis_sets\acr6\datasets);
%zexportcsv(studydata_acr6,studydata_acr6,&path1\analysis_sets\acr6\exports);
