%macro options_off;
ods listing close;
options nonotes nosource nosource2 nomprint nosymbolgen nomlogic;
%mend;