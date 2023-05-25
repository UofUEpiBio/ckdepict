%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean3 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");
data studies;
 set pclean3.b_gfr_up_6m;
run;
proc sort data=studies;
 by allrx;
run;
/** Get all events **/
libname events excel "&path1\macros\eventsnames.xlsx" mixed=yes;
data eventsfile;
 set events."events3$"n;
 drop lai_comments;
run;
libname events clear;
data eventsfile1;
 set eventsfile;
 if eventnumber=. then delete;
run;
proc sql noprint;
  select eventnumber into :eventcounter separated by ' '
  from eventsfile1;
quit;
options notes mprint symbolgen mlogic;
%nboot6m(800,1);
%nboot6m(800,2);
%nboot6m(800,3);
%nboot6m(800,4);
%nboot6m(800,5);
%nboot6m(800,6);
%nboot6m(800,7);
%nboot6m(800,8);
%nboot6m(800,9);
%nboot6m(800,10);
%nboot6m(800,11);
%nboot6m(800,12);
%nboot6m(800,13);
%nboot6m(800,14);
%nboot6m(800,15);
%nboot6m(800,16);
%nboot6m(800,17);
%nboot6m(800,18);
%nboot6m(800,19);
data Exports.ratios_corrs6m;
 set Exports.ratios_corrs6m1 Exports.ratios_corrs6m2 Exports.ratios_corrs6m3 Exports.ratios_corrs6m4 Exports.ratios_corrs6m5
     Exports.ratios_corrs6m6 Exports.ratios_corrs6m7 Exports.ratios_corrs6m8 Exports.ratios_corrs6m9 Exports.ratios_corrs6m10
     Exports.ratios_corrs6m11 Exports.ratios_corrs6m12 Exports.ratios_corrs6m13 Exports.ratios_corrs6m14 Exports.ratios_corrs6m15
     Exports.ratios_corrs6m16 Exports.ratios_corrs6m17 Exports.ratios_corrs6m18 Exports.ratios_corrs6m19;
run;





