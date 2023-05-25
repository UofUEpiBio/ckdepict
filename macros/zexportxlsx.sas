%macro zexportxlsx(datain,dataout,path);
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
proc export data=&datain
            outfile="&path\&dataout..xlsx"
            dbms=xlsx replace;
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