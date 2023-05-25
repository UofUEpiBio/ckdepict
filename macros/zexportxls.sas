%macro zexportxls(datain,dataout,path);
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
proc export data=&datain
            outfile="&path\&dataout..xls"
            dbms=xls replace;
run;
data _null_;
fname='todelete';
rc=filename(fname,"&path\&dataout..xls.bak");
rc=fdelete(fname);
rc=filename(fname);
run;
ods listing;
options notes mprint symbolgen mlogic;
%mend;