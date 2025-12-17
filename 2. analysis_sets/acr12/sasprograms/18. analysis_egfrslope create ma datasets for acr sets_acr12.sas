%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\acr12\datasets";
libname Exports "&path1\analysis_sets\acr12\Exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");

data acr_t99_acr12_ma;
 set Exports.txt_effects_up2;
 if compress(variable)="T_assign" and compress(model)="2.ANCOVA";
run;
data SASdata.acr_t99_acr12_ma;
 set acr_t99_acr12_ma;
run;
%zexportcsv(acr_t99_acr12_ma,acr_t99_acr12_ma,&path1\analysis_sets\acr12\Datasets);

data Exports.acr_t99_acr12_ma;
 set acr_t99_acr12_ma;
run;
%zexportcsv(acr_t99_acr12_ma,acr_t99_acr12_ma,&path1\analysis_sets\acr12\Exports);
