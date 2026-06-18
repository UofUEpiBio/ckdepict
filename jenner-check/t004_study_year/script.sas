/* CKD trial publication-year lookup.

   The if-then assignment ladder is a subset of the ckdepict
   macros/study_year.sas fragment, which maps each internal study number to
   the trial's year of publication. The study_num -> study_year values below
   are taken unchanged from that fragment; a representative span of study
   numbers (early 1990s through 2022) is exercised here. */

data studies;
   input study_num;
   datalines;
1
5
10
24
30
49
53
72
77
89
91
98
;
run;

data study_pub;
   set studies;
if study_num=1	then study_year=1992;
if study_num=5	then study_year=1997;
if study_num=10	then study_year=2000;
if study_num=24	then study_year=2005;
if study_num=30	then study_year=1989;
if study_num=49	then study_year=2010;
if study_num=53	then study_year=2015;
if study_num=72	then study_year=2016;
if study_num=77	then study_year=2018;
if study_num=89 then study_year=2021;
if study_num=91 then study_year=2022;
if study_num=98 then study_year=2022;
run;

proc print data=study_pub noobs;
   var study_num study_year;
run;

proc means data=study_pub min max mean n;
   var study_year;
run;
