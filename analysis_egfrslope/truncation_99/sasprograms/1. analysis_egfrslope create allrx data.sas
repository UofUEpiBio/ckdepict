%let t=truncation_99;
%let path1=d:\userdata\shared\ckd_endpts\root;

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path1\macros");

libname Master "&path1\steps\maindatasets";
libname SASdata  "&path1\analysis_egfrslope\&t.\datasets";
libname Exports  "&path1\analysis_egfrslope\&t.\&t._exports";
data allrxdata;
length allrx 8. allrxname $19. 
        allrx_year $16.
        region 8. region_fmt $13. 
        pooled 8. pooled_fmt $19. 
        intervention 8. intervention_fmt $29. intervention_abrev $7.
	    disease 8.  disease_fmt $22. 
		disease2 8. disease2_fmt $22.
        include_ia 8.;
 set Master.fdac2_tx_allendpts;
 %include "&path1\macros\diseases.sas";
 %include "&path1\macros\regions.sas";
 %include "&path1\macros\pooled.sas";
 %include "&path1\macros\interventions.sas";
 %include "&path1\macros\study_interventions_dummies.sas";
 %include "&path1\macros\allrx_year.sas";
 allrxname=studyname;
 if allrx=100 then do;allrxname="IgA-steroid";allrxname1="IgA-steroid";end;
 if allrx=101 then do;allrxname="IgA-MMF";allrxname1="IgA-MMF";end;
 if allrx=102 then do;allrxname="IgA-ACEI";allrxname1="IgA-ACEI";end;
 if allrx=103 then do;allrxname="IgA-AZA";allrxname1="IgA-AZA";end;
 if allrx=200 then do;allrxname="Mem-Ponticelli";allrxname1="Mem-Ponticelli";end;
 keep allrx allrxname intervention Include_IA pooled region Disease disease_fmt Disease2 disease2_fmt region_fmt pooled_fmt 
     intervention_fmt intervention_abrev allrx_year;
run;
proc sort data=allrxdata nodupkey out=allrxdata;
 by allrx;
run;
data Exports.allrxdata;
 set allrxdata;
run;
%zexportcsv(allrxdata,allrxdata,&path1\analysis_egfrslope\&t.\&t._exports);
/*%zexportxlsx2007(allrxdata,allrxdata,&path1\analysis_egfrslope\&t.\&t._exports);*/
data fdac2_tx_allendpts;
 set Master.fdac2_tx_allendpts;
run;
data fdac2_visits;
 set Master.fdac2_visits;
run;
/** New allrx name and other allrx level variables needed **/
/** Allrx level new names **/
data zfda2_allrx;
 set Master.fdac2_tx_allendpts;
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
data Exports.zallrxdata;
 set zallrxdata;
run;
%zexportcsv(zallrxdata,zallrxdata,&path1\analysis_egfrslope\&t.\&t._exports);
%zexportxlsx2007(zallrxdata,zallrxdata,&path1\analysis_egfrslope\&t.\&t._exports);

