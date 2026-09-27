$Title Carbon Network System Optimization

$eolCom //

$Set Dfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Data
$Set Cfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Code/Stage3_CNet/Cnet_Prov
$Set Rfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Results


$Set Data_E_Net   %Dfolder%/Data_E_Net
$Set Data_C_Net   %Dfolder%/Data_C_Net

$Set Data_DEM  %Dfolder%/Data_Dem
$Set Data_VRE  %Dfolder%/Data_VRE
$Set Data_PRF  %Dfolder%/Data_Pref

* Power demand
$Set Ele_Dem  Edem_4TD

* scn: cost scenario; dcs: emission scenario; ctx: carbon tax scenario
$Set scn  mid
$Set dcs  cn50
$Set ctx  cadv

* Run mode (tflag): 0 => Testing, 1 >= normal optimization.
* Model Specification (mflag): 1 => E_Net, 2 => E_Net + C_Net.
* CO2 constraining methd (cflag): 1 => Carbon caps, 2 => Carbon tax.
$Set tflag  1
$Set mflag  2
$Set cflag  1


* ================================== Set definition =========================================
* ar: total number of optimization years
* rs: number of hours in a year (288h -> 12TD) (96h -> 4TD)
$Set ar  26   //26
$Set rs  96   //288

* hrs: number of hours in a day (for truck trans)
$Set  hrs  24
$Eval tds  %rs% / %hrs%

* sr, mr: decision years for generation and transmission technologies
$Set sr  y1, y6, y11, y16, y21, y26           // y1, y2, y4, y6, y8, y10, y12, y14, y16, y18, y20, y22, y24, y26
$Set mr  y1, y6, y11, y16, y21, y26


Sets t       time          / h0 * h%rs% / 
     h(t)    hours         / h1 * h%rs% /     // hours in a year
     y       index years   / y0 * y%ar% /
     yr(y)   opr. years    / y1 * y%ar% /

     n(y)    ins. years    / y0, %sr%   /     // for technology   // y1, y6, y11, y16, y21, y26
     ni(y)   ins. years    / y0, %mr%   /;    // for transmission // y1, y11, y21

Sets yx(yr)    / y1, y6, y11, y16, y21/;     // Decommission and retrofit years //  


Sets z city    / AH, BJ, CQ, FJ, GD, GS, GX, GZ, HA, HB, HE, HI, HL,	
                 HN, JL, JS, JX, LN, MD, MX, NX, QH, SC, SD, SH, SN, 
                 SX, TJ, XJ, XZ, YN, ZJ/;

Alias(z, zx);    // zones in a region
Alias(yr,yn);    // operation years in planning horizon

Sets er   electricity technology     / pv, nwd, fwd, 
                                       nu, bio, beccs, hydo,
                                       gtcc, gcics, gccs,
                                       coal, coics, cocs,
                                       phs, lib4 /;               // Electricity generation and storage technologies

Sets eg(er)  elec. generation        / pv, nwd, fwd
                                       nu, bio, beccs, hydo,
                                       gtcc, gccs, coal, cocs /   // Newly built generation
     ecg(er) tech. with CCS          / gcics, coics /             // Retrofit with CCS
     es(er)  elec. storage           / phs, lib4 /;               // Newly built storage      

Sets c    tech. scenarios            / high, mid, low /           // Technology cost scenarios
     ces   clean energy scens        / bau, ndc, endc, cn50 /     // Four decarbonization scenarios 
     esp  tech. specification        / eta, ro, mu, lm, cfn, cfm, epn, ltm /
     m    inter-transmission lines   / ac, dc /
     cxs  carbon tax scenarios       / cmid, cadv /;              // Carbon tax scenarios

Parameters tau_es(es)  discharge duration hr        / phs 12, lib4 4 /
           lntm        transmission line lifetime   / 40   /
           ndys        num. of days in a year       / 365  /
           nhys        num. of hours in a year      / 8760 /;

Scalars ths   thousand     / 1.0e+3 /
        mms   million      / 1.0e+6 /
        yys   0.1 billion  / 1.0e+8 /
        nds   typical das;                                         

nds = nhys / %rs%;         // number of typical days in a year

Display er, yr, n, ni, yx;

*Techno-economic parameters
Scalars ir      interest rates          / 0.05 /
        cfa     accountable factor      / 0.5  /;

Parameters dn(y);      // Discount rates in year y

dn(yr) = 1 / ((1 + ir) ** (ord(yr) - 1));      // 0.28 ~ 1.0

* 投资建设速率缩放系数
Parameter invSpan(y);

invSpan(y) = 1;
invSpan(n)$(ord(n) > 1)  = 2;
invSpan(ni)$(ord(ni) > 1) = 2;

* ================================== Cnetwork modeling =========================================
* C_Network = CC + CP + CT + CS
* CC -> CCS + DAC
* CP -> Carbon compressors
* CT -> CO2 Pipeline
* CS -> Underground Storage
* CC -> CP -> CT -> CS

Sets  cn       carbon network technology      / kclg, kbpd, sdbn, molg,
                                                comp, dsac /;

Sets  ccdg(cn) carbon capture: dac     / kclg, kbpd, sdbn, molg /     // CC = CCS + DAC, CCS用E_Net部分结果
      cp(cn)   carbon compressors      / comp /          
      ct       carbon transimission    / ppln /
      cs(cn)   carbon storage          / dsac /;                      // DSA -> 深层咸水层封存 / EOR -> 采油增强封存, DSA技术成熟度及存储量远大于EOR

Sets  csp      tech. specification     / eta, ro, mu, lm, cfn, cfm, ltm, etae, etaq /;    // kton CO2/GWh Fuel, etae, etaq: 电，热 GWh/kton CO2

Parameters  tau_cs  discharge duration hr    / dsac 240  /
            ctlm    carbon trans pipeline    / 40 /;   

// Import data for Carbon Network optimization
* =========================================================================== *
$include %Cfolder%/C_Network_Data.gms

$include %Cfolder%/C_Network_Data_Pref.gms

$include %Cfolder%/C_Network_Param.gms



* ======================== Stage2 Results: Carbon Capture ======================== *
Parameters CO2_CCS(z,pj,yr,h), CO2_DAC(z,yr,h);   // kton
Parameters CO2_CCS_z(z,yr,h);

Execute_load "%Rfolder%/Stage_2_fix.gdx", CO2_CCS, CO2_DAC;

CO2_CCS(z,pj,yr,h)$(CO2_CCS(z,pj,yr,h) < 1e-3) = 0;
CO2_DAC(z,yr,h)$(CO2_DAC(z,yr,h) < 1e-4) = 0;
CO2_CCS_z(z,yr,h) = sum(pj, CO2_CCS(z,pj,yr,h));

                                    
display CO2_CCS, CO2_DAC, CO2_CCS_z;

    

* ======================== Carbon Network Modeling ======================== *
* Screening useful operation years for Carbon Network technologies
Sets  xcsz(z)               no carbon storage cities      / BJ, FJ, GD, GX, HI, JX, SH, XZ, ZJ /;

Sets  J_CN_s(cn,z,n)        installation year of carbon network technologies
      J_CN_u(cn,z,n,yr)     useful operation years for technology installed in z and n
      J_CN_r(cn,z,yr)       technology available in zone z year yr
      J_DAC_v(z,yr);

* Useful operation years for existing technologies 
J_CN_u(cn,z,'y0',yr)$(U_CN_exn(cn,z) and (ord(yr) <= CNet_Specs(cn,'ltm'))) = yes; 

* Useful operation years for newly installed technologies 
J_CN_u(cn,z,n(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + CNet_Specs(cn,'ltm') - 1), card(yr)))) = yes;

* Filter operation years for carbon storage technologies unavailable in cities
J_CN_u('dsac',z,n,yr)$((ord(n) > 1) and xcsz(z)) = no;

* installation years
Loop(J_CN_u(cn,z,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), J_CN_s(cn,z,n) = yes); 

* technologies available in zone z year yr
J_CN_r(cn,z,yr)$(sum(J_CN_u(cn,z,n(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;

* DAC technologies available in zone z year yr
J_DAC_v(z,yr)$(sum(J_CN_r(ccdg,z,yr), 1) >= 1) = yes;

Display J_CN_s, J_CN_u, J_CN_r, J_DAC_v;


* The first year and final years: carbon network technologies 
Parameters ycn(cn,z,n), yco(cn,z,n), ycm(cn,z,n);
ycn(cn,z,'y0')$(J_CN_u(cn,z,'y0','y1')) = 1; 
Loop(J_CN_u(cn,z,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ycn(cn,z,n) = ord(yr));   // The first operation year 
yco(cn,z,n)$(ycn(cn,z,n)) = sum(yr$(J_CN_u(cn,z,n,yr)), 1);                                  // The operation period
ycm(cn,z,n)$(ycn(cn,z,n)) = yco(cn,z,n) + ycn(cn,z,n) - 1;                                   // The last operation year

Display ycn, yco, ycm;


* Discounted share of lifetime for technologies
Parameters CN_afr(cn), CN_dsm(cn,n), CN_TM(cn,n);

CN_afr(cn) = (1 - 1 / (1 + ir)) / (1 - 1 / ((1 + ir) ** CNet_Specs(cn,'ltm')));   // Annualized factor for technologies
CN_dsm(cn,n(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, CNet_Specs(cn,'ltm'))))) / (1 - 1 / (1 + ir));
CN_TM(cn,n) = CN_afr(cn) * CN_dsm(cn,n);

Display CN_afr, CN_dsm, CN_TM;


* ====================== CP: Carbon Compressors ====================== *
Scalars  c_CP       / 0.105 /;    // GWh/kton CO2

* ========= Carbon compression capacities
Positive variables U_CP_nom(cp,z,n);

* Carbon compression capacity continuation
Positive variables U_CP_anom(cp,z,n,yr), U_CP_dnm(cp,z,n,yr);
Equations eqU_CP_cpnn,        // Technology installation capacity when n >= 1
          eqU_CP_cpcma, eqU_CP_cpcmb;

* Fix U_CP_anom(cp,z,n,n) to U_CP_anom(cp,z,n): All newly installed technologies
* 第n年安装的技术在第n年的容量 等于 第n年安装的容量
eqU_CP_cpnn(J_CN_u(cp,z,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_CP_anom(cp,z,n,yr) =E= U_CP_nom(cp,z,n);   // ton/hr, ~1

* Technology capacities when n = 0
U_CP_anom.fx(cp,z,'y0','y1') = U_CN_exn(cp,z); 
eqU_CP_cpcma(J_CN_u(cp,z,'y0',yr))$(ord(yr) < ycm(cp,z,'y0')) .. U_CP_anom(cp,z,'y0',yr+1) =E= U_CP_anom(cp,z,'y0',yr);

* Technology decommission when n = 0 or n >= 1
* n = 0, n >= 1
eqU_CP_cpcmb(J_CN_u(cp,z,n,yr))$(ord(yr) < ycm(cp,z,n)) .. U_CP_anom(cp,z,n,yr+1) =E= U_CP_anom(cp,z,n,yr);   // ton/hr, ~1, 

* For computing cumulative capacity, ton/hr    
Positive variables U_CP_acm(cp,z,yr); 
Equations eqU_cp_acm;       

eqU_cp_acm(J_CN_r(cp,z,yr)) .. U_CP_acm(cp,z,yr) =E= sum(J_CN_u(cp,z,n(y),yr)$(ord(y)-1 <= ord(yr)), U_CP_anom(cp,z,n,yr));   // ton/hr, ~1

* ========= Carbon compressor operation
Positive variables M_CP(cp,z,yr,h), P_CP(z,yr,h);                         // ton, GWh
Equations eqM_CPa, eqM_CPb, eqP_CP;

* 压缩量 = 碳捕集量（DAC + CCS）
eqM_CPa(J_CN_r(cp,z,yr), h) ..  M_CP(cp,z,yr,h) =L= U_CP_acm(cp,z,yr);
eqM_CPb(z,yr,h) .. sum(J_CN_r(cp,z,yr), M_CP(cp,z,yr,h)) =E= (CO2_CCS_z(z,yr,h) + CO2_DAC(z,yr,h)) * ths;
eqP_CP(z,yr,h) .. P_CP(z,yr,h) =E= c_CP * (CO2_CCS_z(z,yr,h) + CO2_DAC(z,yr,h));    // GWh

* ========= Investment and operation costs
Parameters CNet_uCaPx(cn,y);
CNet_uCaPx(cn,yr) = CNet_CaPx(cn,'%scn%',yr);

Positive variables CaPx_CP(n), FOM_CP(yr);
Equations eqCaPx_CP, eqFOM_CP;              // no vom

eqCaPx_CP(n)$(ord(n) > 1) .. CaPx_CP(n) =E= sum(J_CN_s(cp,z,n), dn(n) * CN_afr(cp) * CN_dsm(cp,n) * CNet_uCaPx(cp,n) * ths * U_CP_nom(cp,z,n));     // k USD

eqFOM_CP(yr) .. FOM_CP(yr) =E= sum(J_CN_r(cp,z,yr), dn(yr) * CNet_FOM(cp,'%scn%',yr) / ths * U_CP_acm(cp,z,yr));        // k USD


* ====================== CT: Carbon Transmission ====================== *
Scalars dt   decend rate for carbon transportation   / 0.015 /;
Parameters cdt(y);     // carbon transportation decrease rates

cdt(yr) = 1 / ((1 + dt) ** (ord(yr) - 1));

Scalars   CT_ECON    / 0.00025 /     // MWh/ton/km: power needed during pipeline transmission
          CT_loss    / 0.000008 /;   // Line loss: 0.8% per 1000km

* Carbon transmission costs: ppln (5% of CaPx)
Scalars   CT_CaPx    / 1.504 /      // ppln: k USD/ton/hr/km      
          CT_FOM     / 0.0526 /     // ppln: k USD/ton/hr/km/yr
          CT_VOM     / 11.213 /;    // ppln: USD/ton/hr/km;

* ========= Carbon transimission
Sets ico(z,zx)            existing internal transmission lines
     ics(z,zx)            newly built lines for inter-zone transmission
     icz(z,zx)            transmission lines for capacity expansion
     icx(z,zx)            all possible bidirectional transmission

     J_CT_n(z,zx,ni,yr)   useful operation years for carbon pipelines       // From z to zx, z < zx
     J_CT_v(z,zx,yr)      pipeline transmission available in year yr
     J_CT_pn(z,yr)           carbon pipeline connection with z in year yr;

* Carbon transmission expansion
ico(z,zx)$(CTNS_dstn(z,zx) and (ord(z) < ord(zx))) = yes;  // Existing transmission lines, z < zx
icz(z,zx) = ico(z,zx);                                     // Possible transmission lines for expansion
icx(z,zx)$(CTNS_dstn(z,zx)) = yes;                         // All possible bidirectional transmission

icz('SH','LN') = no;
icz('JS','LN') = no;
icz('SD','LN') = no;
icz('SH','JL') = no;
icz('JS','JL') = no;
icz('SD','JL') = no;
icz('SH','HL') = no;
icz('JS','HL') = no;
icz('SD','HL') = no;

icz('LN','SH') = no;
icz('LN','JS') = no;
icz('LN','SD') = no;
icz('JL','SH') = no;
icz('JL','JS') = no;
icz('JL','SD') = no;
icz('HL','SH') = no;
icz('HL','JS') = no;
icz('HL','SD') = no;


icx('SH','LN') = no;
icx('JS','LN') = no;
icx('SD','LN') = no;
icx('SH','JL') = no;
icx('JS','JL') = no;
icx('SD','JL') = no;
icx('SH','HL') = no;
icx('JS','HL') = no;
icx('SD','HL') = no;

icx('LN','SH') = no;
icx('LN','JS') = no;
icx('LN','SD') = no;
icx('JL','SH') = no;
icx('JL','JS') = no;
icx('JL','SD') = no;
icx('HL','SH') = no;
icx('HL','JS') = no;
icx('HL','SD') = no;

* pipeline define
J_CT_n(z,zx,'y0',yr) = no;                  // Existing transmission pipelines
J_CT_n(icz(z,zx),ni(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ctlm - 1), card(yr)))) = yes;   // Possible transmission pipelines
J_CT_v(z,zx,yr)$(sum(J_CT_n(z,zx,ni(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;      // z < zx, lines connecting z and zx in year yr
J_CT_pn(z,yr)$(sum(icx(z,zx), 1) >= 1) = yes;      // carbon pipeline connection with z

Display icz, icx, J_CT_n, J_CT_v, J_CT_pn;

* The first year and final years: carbon pipeline transmission
Parameters ypn(z,zx,ni), ypo(z,zx,ni), ypm(z,zx,ni);
ypn(z,zx,'y0')$(J_CT_n(z,zx,'y0','y1')) = 1;
Loop(J_CT_n(z,zx,ni(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ypn(z,zx,ni) = ord(yr););   // The first operation year
ypo(z,zx,ni)$(ypn(z,zx,ni)) = sum(yr$(J_CT_n(z,zx,ni,yr)), 1);                               // The operation period
ypm(z,zx,ni)$(ypn(z,zx,ni)) = ypo(z,zx,ni) + ypn(z,zx,ni) - 1;                            // The last  operation year

Display ypn, ypo, ypm;

* Discounted share of lifetime for hydrogen transmission technologies
Parameters CT_afr, CT_dsm(ni), CT_TM(ni);

CT_afr = (1 - 1 / (1 + ir)) / (1 - 1 / ((1 + ir) ** ctlm));   // Annualized factor for hydrogem transmission
CT_dsm(ni(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, ctlm)))) / (1 - 1 / (1 + ir));

CT_TM(ni) = CT_afr * CT_dsm(ni);

Display CT_afr, CT_dsm, CT_TM;


* ========= Capacity sizing
Positive variables U_Prv_nom(z,zx,ni);   // ton/hr
Equations eqU_Prv_nom, eqU_CT_bLim;

eqU_Prv_nom(icz(z,zx), ni)$(ord(ni) > 1) .. U_Prv_nom(z,zx,ni) =L= U_CT_Max(z,zx);        // installation cap. <= max. caps, ton/hr
eqU_CT_bLim(ni)$(ord(ni) > 1) .. sum(icz(z,zx), U_Prv_nom(z,zx,ni)) =L= U_CT_bLim * invSpan(ni);   // Max. building rates, ton/hr

* Capacity continuation
Positive variables U_CT_anom(z,zx,ni,yr);
Equations eqU_CT_anoma, eqU_CT_anomb, eqU_CT_anomc;

* Fix capacity U_CT_anom(z,zx,ni,ni) to U_Prv_nom(z,zx,ni)
eqU_CT_anoma(J_CT_n(z,zx,ni(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_CT_anom(z,zx,ni,yr) =E= U_Prv_nom(z,zx,ni);

* Pipeline transmission technologies decommission when n = 0
U_CT_anom.fx(z,zx,'y0','y1') = 0;
eqU_CT_anomb(J_CT_n(z,zx,'y0',yr))$(ord(yr) < ypm(z,zx,'y0')) .. U_CT_anom(z,zx,'y0',yr+1) =E= U_CT_anom(z,zx,'y0',yr);

* Transimission technology decommission when n >= 1
eqU_CT_anomc(J_CT_n(z,zx,ni,yr))$((ord(ni) > 1) and (ord(yr) < ypm(z,zx,ni))) .. U_CT_anom(z,zx,ni,yr+1) =E= U_CT_anom(z,zx,ni,yr);   

* Cumulative capacity of pipeline transmission
Positive variables U_CT_acm(z,zx,yr);   // ton/hr
Equations eqU_CT_acm;

eqU_CT_acm(J_CT_v(z,zx,yr)) .. U_CT_acm(z,zx,yr) =E= sum(J_CT_n(z,zx,ni(y),yr)$(ord(y)-1 <= ord(yr)), U_CT_anom(z,zx,ni,yr));   // accumulative caps



* ========= Pipeline Operations
Positive variables F_CT(z,zx,yr,h);      // ton/hr
Equations eqF_CTa, eqF_CTb, eqF_CTc;

eqF_CTa(J_CT_v(z,zx,yr), h) .. F_CT(z,zx,yr,h) * (1 - CTNS_dstn(z,zx) * CT_loss) =L= U_CT_acm(z,zx,yr);   // Carbon flow <= caps: z to zx
eqF_CTb(J_CT_v(z,zx,yr), h) .. F_CT(zx,z,yr,h) * (1 - CTNS_dstn(zx,z) * CT_loss) =L= U_CT_acm(z,zx,yr);   // Carbon flow <= caps: zx to z
eqF_CTc(J_CT_v(z,zx,yr), h) .. (F_CT(z,zx,yr,h) + F_CT(zx,z,yr,h)) * (1 - CTNS_dstn(z,zx) * CT_loss) =L= U_CT_acm(z,zx,yr);


* ========= Investment and operation costs
Positive variables CaPx_CT(ni), FOM_CT(yr), VOM_CT(yr);
Equations eqCaPx_CT, eqFOM_CT; 

eqCaPx_CT(ni)$(ord(ni) > 1) .. CaPx_CT(ni) =E= sum(icz(z,zx), 
                      dn(ni) * cdt(ni) * CT_afr * CT_dsm(ni) * CT_CaPx * CTNS_dstn(z,zx) * U_Prv_nom(z,zx,ni));   // k USD, ~30

eqFOM_CT(yr) ..  FOM_CT(yr) =E= sum(J_CT_v(z,zx,yr), dn(yr) * cdt(yr) * CT_FOM * CTNS_dstn(z,zx) * U_CT_acm(z,zx,yr));      // k USD, ~0.4



* ====================== CS: Carbon Storage ====================== *
* ========= Capacity sizing: Carbon storage technologies
Positive variables U_CS_nom(cs,z,n);
Equations eqU_CS_nom, eqU_CS_bLim;

eqU_CS_nom(J_CN_s(cs,z,n)) .. U_CS_nom(cs,z,n) =L= U_CS_Max(cs,z);                           // ton/hr
eqU_CS_bLim(cs,n)$(ord(n) > 1) .. sum(J_CN_s(cs,z,n), U_CS_nom(cs,z,n)) =L= U_CS_bLim(cs) * invSpan(n);   // ton/hr

* Capacity continuation
Positive variables U_CS_anom(cs,z,n,yr);        // ton/hr
Equations eqU_CS_anoma, eqU_CS_anomb, eqU_CS_anomc;

* Fix U_CS_anom(cs,z,n,n) to U_CS_nom(cs,z,n): All newly installed storage technologies
eqU_CS_anoma(J_CN_u(cs,z,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_CS_anom(cs,z,n,yr) =E= U_CS_nom(cs,z,n);

* Storage technology decommission when n = 0
U_CS_anom.fx(cs,z,'y0','y1') = U_CN_exn(cs,z);
eqU_CS_anomb(J_CN_u(cs,z,'y0',yr))$(ord(yr) < ycm(cs,z,'y0')) .. U_CS_anom(cs,z,'y0',yr+1) =E= U_CS_anom(cs,z,'y0',yr);          

* Storage technology decommission when n >= 1
eqU_CS_anomc(J_CN_u(cs,z,n,yr))$((ord(n) > 1) and (ord(yr) < ycm(cs,z,n))) .. U_CS_anom(cs,z,n,yr+1) =E= U_CS_anom(cs,z,n,yr);   

Positive variables U_CS_acm(cs,z,yr);      
Equations eqU_CS_acm;

eqU_CS_acm(J_CN_r(cs,z,yr)) ..  U_CS_acm(cs,z,yr) =E= sum(J_CN_u(cs,z,n(y),yr)$(ord(y)-1 <= ord(yr)), U_CS_anom(cs,z,n,yr));

* ========= Operations: Carbon storage technologies
Parameters CS_loss(cs)   / dsac 0 /;

Positive Variables
    C_CS(cs,z,yr,h)     "hourly CO2 injection rate, ton/h"
    En_CS(cs,z,yr)      "cumulative stored CO2 up to year yr, ton";

Equations eqC_CS, eqEn_CS_y1, eqEn_CS_yr, eqEn_CS_lim;

eqC_CS(J_CN_r(cs,z,yr), h) .. C_CS(cs,z,yr,h) =L= CNet_Specs(cs,'lm') * U_CS_acm(cs,z,yr);

eqEn_CS_y1(J_CN_r(cs,z,'y1')) .. En_CS(cs,z,'y1') =E= sum(h, nds * CNet_Specs(cs,'eta') * C_CS(cs,z,'y1',h));
eqEn_CS_yr(J_CN_r(cs,z,yr))$(ord(yr) > 1) .. En_CS(cs,z,yr) =E= En_CS(cs,z,yr-1) * (1- CS_loss(cs)) + sum(h, nds * CNet_Specs(cs,'eta') * C_CS(cs,z,yr,h));

eqEn_CS_lim(J_CN_r(cs,z,yr)) .. En_CS(cs,z,yr) =L= U_CS_rLim(cs,z) * 1e6;

* ========= Investment and operation costs
Positive variables CaPx_CS(n), FOM_CS(yr), FOM_CS_U(yr);
Equations eqCaPx_CS, eqFOM_CS, eqFOM_CS_kUSD;

eqCaPx_CS(n)$(ord(n) > 1) .. CaPx_CS(n) =E= sum(J_CN_s(cs,z,n), dn(n) * CN_afr(cs) * CN_dsm(cs,n) * CNet_uCaPx(cs,n) * ths * U_CS_nom(cs,z,n));   // k USD

eqFOM_CS(yr) .. FOM_CS_U(yr) =E= sum(J_CN_r(cs,z,yr), dn(yr) * CNet_FOM(cs,'%scn%',yr) * U_CS_acm(cs,z,yr));      // USD

* eqVOM_CS(yr) .. VOM_CS(yr) =E= sum((J_CN_r(cs,z,yr),h), nds * dn(yr) * CNet_VOM(cs,'%scn%',yr) / ths * (C_CS(cs,z,yr,h) + D_CS(cs,z,yr,h)));   // k USD

eqFOM_CS_kUSD(yr) .. FOM_CS(yr) =E= FOM_CS_U(yr) / ths;    // k USD


* ========================== Carbon flow balances ========================== *
* ton
Positive variables CS_in(z,yr,h), CS_ex(z,yr,h), CS_sum(z,yr,h);
Equations eqCS1, eqCS2;
Equations eqCflow, eqCS;

eqCS(z,yr,h)  .. CS_sum(z,yr,h) =E= sum(J_CN_r(cs,z,yr), C_CS(cs,z,yr,h));
eqCS1(z,yr,h) .. CS_sum(z,yr,h) =E= CS_in(z,yr,h) + CS_ex(z,yr,h);
eqCS2(z,yr,h) .. CS_ex(z,yr,h)  =E= sum(icx(zx,z), F_CT(zx,z,yr,h) * (1 - CTNS_dstn(zx,z) * CT_loss)); 

* 碳流平衡                                         
eqCflow(z,yr,h) .. (CO2_CCS_z(z,yr,h) + CO2_DAC(z,yr,h)) * ths =E= sum(icx(z,zx), F_CT(z,zx,yr,h)) + CS_in(z,yr,h);

* 区域碳平衡(冗余)
* eqCbalance(z,yr,h) .. CC_Sum_h(z,yr,h) * ths + sum(icx(z,zx), F_CT(zx,z,yr,h) * (1 - CTNS_dstn(zx,z) * CT_loss)) =E= sum(icx(z,zx), F_CT(z,zx,yr,h)) + sum(J_CN_r(cs,z,yr), C_CS(cs,z,yr,h));



* ========================== Invesment and operation costs ========================== *
* CC/CP/CT/CS

Variables TSC_Cnet;
Positive variables CaPx_Cnet, FOM_Cnet;
Equations eqCaPx_Cnet, eqFOM_Cnet, eqTSC_Cnet;

eqCaPx_Cnet .. CaPx_Cnet =E= sum(n$(ord(n) > 1), CaPx_CS(n) + CaPx_CP(n)) + sum(ni$(ord(ni) > 1), CaPx_CT(ni));     // k USD

*eqFCS_Cnet .. FCS_Cnet   =E= sum(yr, FCS_DAC(yr));                                  // k USD

eqFOM_Cnet .. FOM_Cnet =E= sum(yr, FOM_CP(yr) + FOM_CT(yr) + FOM_CS(yr));          // k USD

eqTSC_Cnet .. TSC_Cnet =E= (CaPx_Cnet + FOM_Cnet);                       // k USD



* ========================== Model solving ========================== *
Model China_Carbon_Network / all /;

// Solution options
Options lp = gurobi, optcr = 0.03, reslim = 164000, limrow = 0, limcol = 0, threads = 64; //, limcol = 0, solprint = on, sysout = off;

$onEcho > gurobi.opt
Method 2
Presolve 2
PreSparsify 2
ScaleFlag 2
BarConvTol 1e-6
FeasibilityTol 1e-5
OptimalityTol 1e-5
NumericFocus 1
CrossoverBasis 1
$offEcho

China_Carbon_Network.optfile = 1;

Solve China_Carbon_Network using lp minimizing TSC_Cnet;

* Fixed variables
U_Prv_nom.fx(z,zx,ni)$(abs(U_Prv_nom.l(z,zx,ni)) < 1e-3) = 0;

* Display optimization results
$include %Cfolder%/EC_Display.gms

* Save results into GDX files
$include %Cfolder%/EC_Results.gms

