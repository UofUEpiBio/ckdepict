%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\trunc24\datasets";
libname Exports "&path1\analysis_sets\trunc24\Exports";
 
options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");
data ntassign01;
 set SASdata.studies;
run;
proc sort data=ntassign01 out=ntassign11 nodupkey;
 by study new_id;
run;
data ntassign11a;
 set ntassign11;
 if t_assign=0;
run;
data ntassign11b;
 set ntassign11;
 if t_assign=1;
run;
proc sql; 
  create table txt0 as
  select study,count(*) as npatients0
  from ntassign11a
  group by study;
quit;
proc sql; 
  create table txt1 as
  select study,count(*) as npatients1
  from ntassign11b
  group by study;
quit;
proc sort data=txt0;
 by study;
run;
proc sort data=txt1;
 by study;
run;
data txt01;
 merge txt0 txt1;
 by study;
run;
data gfrlopes_ma;
 set SASdata.nfirstmodelinseqperstudyt99;
 if cs_reason ne "NOTE: GCONV convergence criterion satisfied." then delete;
run;
data zacute;
 length parameter $16. parameternumber 8.;
 set gfrlopes_ma;
 parameter="zAcute";
 estimate=zbeta11_beta12_est;
 se=zbeta11_beta12_se;
 estimate1=zbeta11_est;
 se1=zbeta11_se;
 estimate2=zbeta12_est;
 se2=zbeta12_se;
 parameternumber=-1;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data acute;
 length parameter $16. parameternumber 8.;
 set gfrlopes_ma;
 parameter="Acute";
 estimate=beta11_beta12_est;
 se=beta11_beta12_se;
 estimate1=beta11_est;
 se1=beta11_se;
 estimate2=beta12_est;
 se2=beta12_se;
 parameternumber=0;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data chronic;
 length parameter $16. parameternumber 8.;
 set gfrlopes_ma;
 parameter="Chronic";
 estimate=beta31_beta32_est;
 se=beta31_beta32_se;
 estimate1=beta31_est;
 se1=beta31_se;
 estimate2=beta32_est;
 se2=beta32_se;
 parameternumber=1;
 keep study parameter parameternumber estimate se estimate1 se1 estimate2 se2 zallrx allrx allrxname allrxname1 study_code npatients nevents region region_fmt 
      pooled pooled_fmt intervention intervention_fmt intervention_abrev disease disease_fmt disease2 disease2_fmt;
run;
data slopes_t99_ma;
 set zacute acute chronic;
run;
proc sort data=slopes_t99_ma;
 by study;
run;
proc sort data=txt01;
 by study;
run;
data slopes_t99_trunc24_ma;
 merge slopes_t99_ma txt01;
 by study;
run;
proc sort data=slopes_t99_trunc24_ma;
 by parameternumber zallrx;
run;
data SASdata.slopes_t99_trunc24_ma;
 set slopes_t99_trunc24_ma;
run;
%zexportcsv(slopes_t99_trunc24_ma,slopes_t99_trunc24_ma,&path1\analysis_sets\trunc24\Datasets);

data Exports.slopes_t99_trunc24_ma;
 set slopes_t99_trunc24_ma;
run;
%zexportcsv(slopes_t99_trunc24_ma,slopes_t99_trunc24_ma,&path1\analysis_sets\trunc24\Exports);
