if compress(UP_MeasureToUse)="PER" then do;
     if .<base_24_upro_tot<50 then zup50_ld=0;
     else if base_24_upro_tot>=50 then zup50_ld=1;
end;

if compress(UP_MeasureToUse)="AER" then do;
     if .<base_24_ualb_tot<30 then zup50_ld=0;
     else if base_24_ualb_tot>=30 then zup50_ld=1;
end;

if compress(UP_MeasureToUse)="PCR" then do;
if female=1 then do;
     if .<base_24_upro_rat<25*1.67 then zup50_ld=0;
     else if base_24_upro_rat>=25*1.667 then zup50_ld=1;
end;
if female=0 then do;
     if .<base_24_upro_rat<17*1.67 then zup50_ld=0;
     else if base_24_upro_rat>=17*1.667 then zup50_ld=1;

end;
end;

if compress(UP_MeasureToUse)="ACR" then do;
if female=1 then do;
     if .<base_24_ualb_rat<25 then zup50_ld=0;
     else if base_24_ualb_rat>=25 then zup50_ld=1;
end;
if female=0 then do;
     if .<base_24_ualb_rat<17 then zup50_ld=0;
     else if base_24_ualb_rat>=17 then zup50_ld=1;
end;

end;

if compress(UP_MeasureToUse)="SPCR" then do;
if female=1 then do;
     if .<base_spot_upro_rat<25*1.67 then zup50_ld=0;
     else if base_spot_upro_rat>=25*1.667 then zup50_ld=1;
end;
if female=0 then do;
     if .<base_spot_upro_rat<17*1.67 then zup50_ld=0;
     else if base_spot_upro_rat>=17*1.667 then zup50_ld=1;
end;
end;

if compress(UP_MeasureToUse)="SACR" then do;
if female=1 then do;
     if .<base_spot_ualb_rat<25 then zup50_ld=0;
     else if base_spot_ualb_rat>=25 then zup50_ld=1;
end;
if female=0 then do;
     if .<base_spot_ualb_rat<17 then zup50_ld=0;
     else if base_spot_ualb_rat>=17 then zup50_ld=1;
end;
end;
