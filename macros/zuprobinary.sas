if compress(UP_MeasureToUse)="PER" then do;
	if .<base_24_upro_tot<1000 then zup1000=0;
	else if base_24_upro_tot>=1000 then zup1000=1;
	if .<base_24_upro_tot<500 then zup500=0;
	else if base_24_upro_tot>=500 then zup500=1;
	if .<base_24_upro_tot<50 then zup50=0;
	else if base_24_upro_tot>=50 then zup50=1;
	if 50<base_24_upro_tot<500 then zup50_500=1;
    else if base_24_upro_tot ne . then zup50_500=0;
	if 50<base_24_upro_tot<1000 then zup50_1000=1;
    else if base_24_upro_tot ne . then zup50_1000=0;
 end;
 if compress(UP_MeasureToUse)="AER" then do;
	if .<base_24_ualb_tot<600 then zup1000=0;
	else if base_24_ualb_tot>=600 then zup1000=1;
	if .<base_24_ualb_tot<300 then zup500=0;
	else if base_24_ualb_tot>=300 then zup500=1;
	if .<base_24_ualb_tot<30 then zup50=0;
	else if base_24_ualb_tot>=30 then zup50=1;
	if 30<base_24_ualb_tot<300 then zup50_500=1;
	else if base_24_ualb_tot ne . then zup50_500=0;
	if 30<base_24_ualb_tot<600 then zup50_1000=1;
	else if base_24_ualb_tot ne . then zup50_1000=0;
 end;
 if compress(UP_MeasureToUse)="PCR" then do;
	if .<base_24_upro_rat<1000 then zup1000=0;
	else if base_24_upro_rat>=1000 then zup1000=1;
	if .<base_24_upro_rat<500 then zup500=0;
	else if base_24_upro_rat>=500 then zup500=1;
	if .<base_24_upro_rat<50 then zup50=0;
	else if base_24_upro_rat>=50 then zup50=1;
    if 50<base_24_upro_rat<500 then zup50_500=1;
    else if base_24_upro_rat ne . then zup50_500=0;
	if 50<base_24_upro_rat<1000 then zup50_1000=1;
    else if base_24_upro_rat ne . then zup50_1000=0;
 end;
 if compress(UP_MeasureToUse)="ACR" then do;
	if .<base_24_ualb_rat<600 then zup1000=0;
	else if base_24_ualb_rat>=600 then zup1000=1;
	if .<base_24_ualb_rat<300 then zup500=0;
	else if base_24_ualb_rat>=300 then zup500=1;
	if .<base_24_ualb_rat<30 then zup50=0;
	else if base_24_ualb_rat>=30 then zup50=1;
    if 30<base_24_ualb_rat<300 then zup50_500=1;
    else if base_24_ualb_rat ne . then zup50_500=0;
	if 30<base_24_ualb_rat<600 then zup50_1000=1;
    else if base_24_ualb_rat ne . then zup50_1000=0;
end;
 if compress(UP_MeasureToUse)="SPCR" then do;
	if .<base_spot_upro_rat<1000 then zup1000=0;
	else if base_spot_upro_rat>=1000 then zup1000=1;
	if .<base_spot_upro_rat<500 then zup500=0;
	else if base_spot_upro_rat>=500 then zup500=1;
	if .<base_spot_upro_rat<50 then zup50=0;
	else if base_spot_upro_rat>=50 then zup50=1;
    if 50<base_spot_upro_rat<500 then zup50_500=1;
	else if base_spot_upro_rat ne . then zup50_500=0;
	if 50<base_spot_upro_rat<1000 then zup50_1000=1;
	else if base_spot_upro_rat ne . then zup50_1000=0;
 end;
 if compress(UP_MeasureToUse)="SACR" then do;
	if .<base_spot_ualb_rat<600 then zup1000=0;
	else if base_spot_ualb_rat>=600 then zup1000=1;
	if .<base_spot_ualb_rat<300 then zup500=0;
	else if base_spot_ualb_rat>=300 then zup500=1;
	if .<base_spot_ualb_rat<30 then zup50=0;
	else if base_spot_ualb_rat>=30 then zup50=1;
    if 30<base_spot_ualb_rat<300 then zup50_500=1;
	else if base_spot_ualb_rat ne . then zup50_500=0;
	if 30<base_spot_ualb_rat<600 then zup50_1000=1;
    else if base_spot_ualb_rat ne . then zup50_1000=0;
 end;


