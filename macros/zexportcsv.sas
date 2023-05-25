%macro zexportcsv(datain,dataout,path);
ods listing close;
options nonotes nomprint nosymbolgen nomlogic;
proc export data=&datain
            outfile="&path\&dataout..csv"
            dbms=csv replace;
run;
ods listing;
options notes mprint symbolgen mlogic;
%mend;