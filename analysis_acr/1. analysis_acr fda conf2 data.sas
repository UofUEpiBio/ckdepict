%let path1=d:\userdata\shared\ckd_endpts\root;

libname pclean "&path1\2 Clean data";
libname pclean3 "&path1\analysis_acr\datasets";

options validvarname=v7 nodate center nonumber replace xsync noxwait nofmterr ls=96 nomlogic nomrecall mprint symbolgen mautosource 
sasautos=("&path1\macros");
data fda_study_allendpts;
 length studynamex $17.;
 set pclean.fdac2_studygfrup;
 studynamex=compress(studyname);
 drop studyname;
 if include_acr=1;
run;
data fda_study_allendpts;
 set fda_study_allendpts;
 rename studynamex=studyname;
run;
data pclean3.fda2_study;
 set fda_study_allendpts(in=in1) 
     fda_study_allendpts(in=in2)  fda_study_allendpts(in=in3)
     fda_study_allendpts(in=in4)  fda_study_allendpts(in=in5)
     fda_study_allendpts(in=in6)  fda_study_allendpts(in=in7) 
     fda_study_allendpts(in=in8)  fda_study_allendpts(in=in9) 
     fda_study_allendpts(in=in10) fda_study_allendpts(in=in11)
     fda_study_allendpts(in=in12) fda_study_allendpts(in=in13)
     fda_study_allendpts(in=in14) fda_study_allendpts(in=in15)
     fda_study_allendpts(in=in16) fda_study_allendpts(in=in17)
     fda_study_allendpts(in=in18) fda_study_allendpts(in=in19);
 %include "&path1\macros\zupro.sas";
 %include "&path1\macros\zuprobinary.sas";
 %include "&path1\macros\zuprobinary_ld.sas";
 zupro=zacr;
 zzupro=zacr;
 %include "&path1\macros\diseases.sas";
 %include "&path1\macros\regions.sas";
 %include "&path1\macros\pooled.sas";
 %include "&path1\macros\study_year.sas";
 if in1  then do;                     datagrp1="Overall    ";datagrp2=1;end;
 if in2  then do;if female=0;         datagrp1="Men        ";datagrp2=2;end;
 if in3  then do;if female=1;         datagrp1="Women      ";datagrp2=3;end;
 if in4  then do;if black=1;          datagrp1="Black      ";datagrp2=4;end;
 if in5  then do;if black=0;          datagrp1="Non-black  ";datagrp2=5;end;
 if in6  then do;if .<b_ckdegfr<60;   datagrp1="eGFR<60    ";datagrp2=6;end;
 if in7  then do;if 60<=b_ckdegfr;    datagrp1="eGFR>=60   ";datagrp2=7;end;
 if in8  then do;if zup1000=0;        datagrp1="ACR<600    ";datagrp2=8;end;
 if in9  then do;if zup1000=1;        datagrp1="ACR>=600   ";datagrp2=9;end;
 if in10 then do;if zup500=0;         datagrp1="ACR<300    ";datagrp2=10;end;
 if in11 then do;if zup500=1;         datagrp1="ACR>=300   ";datagrp2=11;end;
 if in12 then do;if zup50=0;          datagrp1="ACR<30     ";datagrp2=12;end;
 if in13 then do;if zup50=1;          datagrp1="ACR>=30    ";datagrp2=13;end;
 if in14 then do;if zup50_500=1;      datagrp1="30<ACR<300 ";datagrp2=14;end;
 if in15 then do;if zup50_1000=1;     datagrp1="30<ACR<600 ";datagrp2=15;end;
 if in16 then do;if .<age<60;         datagrp1="Age<60     ";datagrp2=16;end;
 if in17 then do;if age>=60;          datagrp1="Age>=60    ";datagrp2=17;end;
 if in18 then do;if zup50_ld=0;       datagrp1="ACR<30     ";datagrp2=18;end;
 if in19 then do;if zup50_ld=1;       datagrp1="ACR>=30    ";datagrp2=19;end;
run;
data fda_treatment_allendpts;
 length allrxname $17.;
 set pclean.fdac2_tx_allendpts;
 disx=disease;
 disx2=disease2;
 allrxname=studyname;
 if allrx=100 then allrxname="IgA-steroid";
 if allrx=101 then allrxname="IgA-MMF";
 if allrx=102 then allrxname="IgA-ACEI";
 if allrx=103 then allrxname="IgA-AZA";
 if allrx=200 then allrxname="Mem_Pontall";
 if allrx=100 then study_num=100;
 if allrx=101 then study_num=101;
 if allrx=102 then study_num=102;
 if allrx=103 then study_num=103;
 if allrx=200 then study_num=200;
 if include_acr=1;
 drop intervention_abrev disease disease2 studyname;
run;
data fda_treatment_allendpts;
 set fda_treatment_allendpts;
 rename disx=disease disx2=disease2;
run;
data pclean3.fda2_allrx;
 set fda_treatment_allendpts(in=in1) 
     fda_treatment_allendpts(in=in2)  fda_treatment_allendpts(in=in3)
     fda_treatment_allendpts(in=in4)  fda_treatment_allendpts(in=in5)
     fda_treatment_allendpts(in=in6)  fda_treatment_allendpts(in=in7) 
     fda_treatment_allendpts(in=in8)  fda_treatment_allendpts(in=in9)
     fda_treatment_allendpts(in=in10) fda_treatment_allendpts(in=in11)
     fda_treatment_allendpts(in=in12) fda_treatment_allendpts(in=in13)
     fda_treatment_allendpts(in=in14) fda_treatment_allendpts(in=in15)
     fda_treatment_allendpts(in=in16) fda_treatment_allendpts(in=in17)
     fda_treatment_allendpts(in=in18) fda_treatment_allendpts(in=in19);
 %include "&path1\macros\zupro.sas";
 %include "&path1\macros\zuprobinary.sas";
 %include "&path1\macros\zuprobinary_ld.sas";
 zupro=zacr;
 zzupro=zacr;
 %include "&path1\macros\study_interventions_dummies.sas";
 %include "&path1\macros\interventions.sas";
 %include "&path1\macros\diseases.sas";
 %include "&path1\macros\regions.sas";
 %include "&path1\macros\pooled.sas";
 %include "&path1\macros\allrx_year.sas";
 if in1  then do;                     datagrp1="Overall    ";datagrp2=1;end;
 if in2  then do;if female=0;         datagrp1="Men        ";datagrp2=2;end;
 if in3  then do;if female=1;         datagrp1="Women      ";datagrp2=3;end;
 if in4  then do;if black=1;          datagrp1="Black      ";datagrp2=4;end;
 if in5  then do;if black=0;          datagrp1="Non-black  ";datagrp2=5;end;
 if in6  then do;if .<b_ckdegfr<60;   datagrp1="eGFR<60    ";datagrp2=6;end;
 if in7  then do;if 60<=b_ckdegfr;    datagrp1="eGFR>=60   ";datagrp2=7;end;
 if in8  then do;if zup1000=0;        datagrp1="ACR<600    ";datagrp2=8;end;
 if in9  then do;if zup1000=1;        datagrp1="ACR>=600   ";datagrp2=9;end;
 if in10 then do;if zup500=0;         datagrp1="ACR<300    ";datagrp2=10;end;
 if in11 then do;if zup500=1;         datagrp1="ACR>=300   ";datagrp2=11;end;
 if in12 then do;if zup50=0;          datagrp1="ACR<30     ";datagrp2=12;end;
 if in13 then do;if zup50=1;          datagrp1="ACR>=30    ";datagrp2=13;end;
 if in14 then do;if zup50_500=1;      datagrp1="30<ACR<300 ";datagrp2=14;end;
 if in15 then do;if zup50_1000=1;     datagrp1="30<ACR<600 ";datagrp2=15;end;
 if in16 then do;if .<age<60;         datagrp1="Age<60     ";datagrp2=16;end;
 if in17 then do;if age>=60;          datagrp1="Age>=60    ";datagrp2=17;end;
 if in18 then do;if zup50_ld=0;       datagrp1="ACR<30     ";datagrp2=18;end;
 if in19 then do;if zup50_ld=1;       datagrp1="ACR>=30    ";datagrp2=19;end;
run;
