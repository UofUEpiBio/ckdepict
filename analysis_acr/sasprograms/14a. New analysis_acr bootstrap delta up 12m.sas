%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean3 "&path1\analysis_acr\datasets";
libname Exports "&path1\analysis_acr\acr_exports";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");
data studies;
 set pclean3.b_gfr_up_12m;
run;
proc sort data=studies;
 by allrx;
run;
/** Get all events **/
libname events excel "&path1\macros\eventsnames.xlsx" mixed=yes;
data eventsfile;
 set events."events3$"n;
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
%nboot12m(800,1);
%nboot12m(800,2);
%nboot12m(800,3);
%nboot12m(800,4);
%nboot12m(800,5);
%nboot12m(800,6);
%nboot12m(800,7);
%nboot12m(800,8);
%nboot12m(800,9);
%nboot12m(800,10);
%nboot12m(800,11);
%nboot12m(800,12);
%nboot12m(800,13);
%nboot12m(800,14);
%nboot12m(800,15);
%nboot12m(800,16);
%nboot12m(800,17);
%nboot12m(800,18);
%nboot12m(800,19);
data Exports.ratios_corrs12m;
 set Exports.ratios_corrs12m1 Exports.ratios_corrs12m2 Exports.ratios_corrs12m3 Exports.ratios_corrs12m4 Exports.ratios_corrs12m5
     Exports.ratios_corrs12m6 Exports.ratios_corrs12m7 Exports.ratios_corrs12m8 Exports.ratios_corrs12m9 Exports.ratios_corrs12m10
     Exports.ratios_corrs12m11 Exports.ratios_corrs12m12 Exports.ratios_corrs12m13 Exports.ratios_corrs12m14 Exports.ratios_corrs12m15
     Exports.ratios_corrs12m16 Exports.ratios_corrs12m17 Exports.ratios_corrs12m18 Exports.ratios_corrs12m19;
run;










