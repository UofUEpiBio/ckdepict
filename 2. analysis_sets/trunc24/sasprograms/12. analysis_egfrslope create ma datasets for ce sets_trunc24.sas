%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\trunc24\datasets";
libname Exports "&path1\analysis_sets\trunc24\Exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");

data ce_t99_trunc24_ma;
 set Exports.egfrslope_txteff_ce_r;
 if stderr > 1000 then do;
 estimate=.;
 stderr=.;
 end;
 rename stderr=SE;
 keep eventnumber eventname estimate stderr zallrx allrx allrxname allrxname1 study_code region region_fmt pooled pooled_fmt intervention intervention_fmt
      intervention_abrev disease disease_fmt disease2 disease2_fmt total event;
run;
proc sort data=ce_t99_trunc24_ma;
 by eventnumber zallrx;
run;
data SASdata.ce_t99_trunc24_ma;
 set ce_t99_trunc24_ma;
run;
%zexportcsv(ce_t99_trunc24_ma,ce_t99_trunc24_ma,&path1\analysis_sets\trunc24\Datasets);

data Exports.ce_t99_trunc24_ma;
 set ce_t99_trunc24_ma;
run;
%zexportcsv(ce_t99_trunc24_ma,ce_t99_trunc24_ma,&path1\analysis_sets\trunc24\Exports);
