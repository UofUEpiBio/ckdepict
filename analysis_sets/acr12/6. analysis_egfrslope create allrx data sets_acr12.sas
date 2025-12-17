%let path1=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\Data\TRIALNAME;
%let path2=d:\userdata\Shared\CKD_Endpts\CKD-EPI CT\0_Master_SAS_R_programs\1 TxtEffects;

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 mautosource 
sasautos=("&path2\macros");

libname Master "&path1";
libname SASdata  "&path1\analysis_sets\acr12\datasets";
libname Exports  "&path1\analysis_sets\acr12\exports";

data fdac2_tx_allendpts;
 set Master.fdac2_tx_allendpts;
run;
data fda2_allrx;
 set SASdata.fda2_allrx;
 if delupro12=. then delete;
 keep new_id allrx;
run;
proc sort data=fdac2_tx_allendpts;
 by new_id allrx;
run;
proc sort data=fda2_allrx;
 by new_id allrx;
run;
data fdac2_tx_allendpts;
 merge fdac2_tx_allendpts(in=in1) fda2_allrx(in=in2);
 by new_id allrx;
 if in1 and in2;
run;
data allrxdata;
length allrx 8. allrxname $19. 
        allrx_year $16.
        region 8. region_fmt $13. 
        pooled 8. pooled_fmt $19. 
        intervention 8. intervention_fmt $29. intervention_abrev $12.
	    disease 8.  disease_fmt $22. 
		disease2 8. disease2_fmt $22.
        include_ia 8.;
 set fdac2_tx_allendpts;
 %include "&path2\macros\diseases.sas";
 %include "&path2\macros\regions.sas";
 %include "&path2\macros\pooled.sas";
 %include "&path2\macros\interventions.sas";
 %include "&path2\macros\study_interventions_dummies.sas";
 %include "&path2\macros\allrx_year.sas";
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
data SASdata.allrxdata;
 set allrxdata;
run;
data Exports.allrxdata;
 set allrxdata;
run;
%zexportcsv(allrxdata,allrxdata,&path1\analysis_sets\acr12\datasets);
%zexportcsv(allrxdata,allrxdata,&path1\analysis_sets\acr12\exports);
/** New allrx name and other allrx level variables needed **/
/** Allrx level new names **/
data zfda2_allrx;
 set fdac2_tx_allendpts;
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
data SASdata.zallrxdata;
 set zallrxdata;
run;
data Exports.zallrxdata;
 set zallrxdata;
run;
%zexportcsv(zallrxdata,zallrxdata,&path1\analysis_sets\acr12\datasets);
%zexportcsv(zallrxdata,zallrxdata,&path1\analysis_sets\acr12\exports);