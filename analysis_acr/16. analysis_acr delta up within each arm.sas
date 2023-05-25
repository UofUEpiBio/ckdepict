%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean4 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");

data baseall;
 set pclean4.fda2_allrx;
 if compress(UP_MeasureToUse)="PER" then do;
	 delupro6=delupro6/1.67;
	 delupro12=delupro12/1.67;
 end;
 if compress(UP_MeasureToUse)="AER" then do;
	 delupro6=delupro6;
	 delupro12=delupro12;
 end;
 if compress(UP_MeasureToUse)="PCR" then do;
	 delupro6=delupro6/1.67;
	 delupro12=delupro12/1.67;
 end;
 if compress(UP_MeasureToUse)="ACR" then do;
	 delupro6=delupro6;
	 delupro12=delupro12;
 end;
 if compress(UP_MeasureToUse)="SPCR" then do;
	 delupro6=delupro6/1.67;
	 delupro12=delupro12/1.67; 
 end;
 if compress(UP_MeasureToUse)="SACR" then do;
	 delupro6=delupro6;
	 delupro12=delupro12;
 end;
run;
data upro6;
 set baseall;
 keep datagrp1 datagrp2 allrx new_id logdelupro6 t_assign;
run;
data upro12;
 set baseall;
 keep datagrp1 datagrp2 allrx new_id logdelupro12 t_assign;
run;
data prot_models0;
 set upro6(in=in1) upro12(in=in2);

 if in1 then do;
 y=logdelupro6;
 period="2.6m ";
 end;

 if in2 then do;
  y=logdelupro12;
  period="3.12m";
 end;
 keep datagrp1 datagrp2 new_id allrx y period t_assign;
run;
proc sort data=prot_models0;
 by period datagrp2 datagrp1 allrx t_assign;
run;
proc means data=prot_models0 n mean stderr;
 var y;
 by period datagrp2 datagrp1 allrx t_assign;
 ods output summary=a0;
run;
data a1;
 set a0;
 if y_mean=. or y_stderr=. then delete;
 rename y_n=fmissingtype1 y_mean=estimate y_stderr=se;
run;
proc sort data=a1;
 by period datagrp2 datagrp1 allrx;
run;
data txt_effects_up2;
 set Exports.txt_effects_up2;
 if variable="Intercept" and model="1. Unadjusted";
 keep dataused	datausedname	datagrp2	datagrp1	period	allrx	allrxname	pooled	pooled_fmt	intervention	intervention_fmt	
   intervention_abrev	disease	disease_fmt	disease2	disease2_fmt	include_ia	zallrx	allrxname1	study_code;
run;
proc sort data=txt_effects_up2;
 by period datagrp2 datagrp1 allrx;
run;
data deltaup_group;
 merge a1(in=in2) txt_effects_up2(in=in1);
 by period datagrp2 datagrp1 allrx;
 if in2;
run;
data Exports.deltaup_group;
 set deltaup_group;
 *if datagrp2=1;
run;
%zexportcsv(deltaup_group,deltaup_group,&path1\analysis_acr\acr_exports);

 