/* CKD baseline urine-protein / albumin measure standardisation.

   The block below is the ckdepict macros/zupro.sas fragment: based on the
   UP_MeasureToUse code (PER, AER, PCR, ACR, SPCR, SACR) it derives the
   standardised urine-protein (zupro) and albumin-creatinine (zacr) values
   from the matching baseline measurement, applying the 1.67 protein/albumin
   conversion factor where the source measure is protein-based. The logic is
   unchanged; a small set of baseline rows feeds it here. */

data baseline;
   length UP_MeasureToUse $5;
   input UP_MeasureToUse $ base_24_upro_tot base_24_ualb_tot
         base_24_upro_rat base_24_ualb_rat
         base_spot_upro_rat base_spot_ualb_rat;
   datalines;
PER   2.50 .    .    .    .    .
AER   .    1.20 .    .    .    .
PCR   .    .    1.80 .    .    .
ACR   .    .    .    0.95 .    .
SPCR  .    .    .    .    2.10 .
SACR  .    .    .    .    .    1.05
;
run;

data zderived;
   set baseline;
if compress(UP_MeasureToUse)="PER" then do;
	zupro=base_24_upro_tot*1;
	 zacr=base_24_upro_tot/1.67;
 end;
if compress(UP_MeasureToUse)="AER" then do;
	zupro=base_24_ualb_tot*1;
     zacr=base_24_ualb_tot*1;
 end;
if compress(UP_MeasureToUse)="PCR" then do;
	zupro=base_24_upro_rat*1;
   	 zacr=base_24_upro_rat/1.67;
 end;
if compress(UP_MeasureToUse)="ACR" then do;
	zupro=base_24_ualb_rat*1;
     zacr=base_24_ualb_rat*1;
 end;
if compress(UP_MeasureToUse)="SPCR" then do;
	zupro=base_spot_upro_rat*1; 
 	 zacr=base_spot_upro_rat/1.67;  
 end;
if compress(UP_MeasureToUse)="SACR" then do;
	zupro=base_spot_ualb_rat*1; 
     zacr=base_spot_ualb_rat*1; 
 end;
run;

proc print data=zderived noobs;
   var UP_MeasureToUse zupro zacr;
   format zupro zacr 8.4;
run;
