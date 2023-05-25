%macro zexportxlsx2007(datain,dataout,path);
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
proc export data=&datain
            outfile="&path\&dataout..xlsx"
            dbms=excel2007 replace;
			sheet="&dataout";
run;
data _null_;
fname='todelete';
rc=filename(fname,"&path\&dataout..xlsx.bak");
rc=fdelete(fname);
rc=filename(fname);
run;
ods listing;
options notes mprint symbolgen mlogic;
%mend;