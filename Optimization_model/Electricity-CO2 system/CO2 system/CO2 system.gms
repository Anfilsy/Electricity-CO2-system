$Title Carbon Network System Optimization

$eolCom //

$Set Dfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Data
$Set Cfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Code
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
$Set sr  y1, y6, y11, y16, y21, y26
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

Scalars  tau_cs  discharge duration hr    /  240  /
         ctlm    carbon trans pipeline    /  40 /;   

// Import data for Carbon Network optimization
* =========================================================================== *
$include %Cfolder%/C_Network_Data_Pref.gms

$include %Cfolder%/C_Network_Data.gms

$include %Cfolder%/C_Network_Param.gms


* ======================== Carbon Capture ======================== *
Parameters CO2_CCS(z,pj,yr,h), CO2_DAC(z,yr,h);   // kton

Execute_load "%Rfolder%/Stage_2_fix.gdx", CO2_CCS, CO2_DAC;

CO2_CCS(z,pj,yr,h)$(CO2_CCS(z,pj,yr,h) < 1e-3) = 0;
CO2_DAC(z,yr,h)$(CO2_DAC(z,yr,h) < 1e-4) = 0;
                                    
display CO2_CCS, CO2_DAC;

Positive Variables DAC_exp(z,yr,h), DAC_imp(z,yr,h);
Equation eqDAC_epip;
eqDAC_epip(z,yr,h) .. CO2_DAC(z,yr,h) * ths =E= DAC_exp(z,yr,h) + DAC_imp(z,yr,h);
       
       
* ======================== Province carbon pipelines ======================== *       
Parameters Fix_U_Prv_nom(z,zx,ni);
Parameters Fix_F_CT(z,zx,yr,h);

Positive variables U_Prv_nom(z,zx,ni), F_Prov(z,zx,yr,h);

Execute_load "%Rfolder%/Stage3_Cnet_Prov.gdx", Fix_U_Prv_nom, Fix_F_CT;

Fix_F_CT(z,zx,yr,h)$(Fix_F_CT(z,zx,yr,h) < 1e-3) = 0;
U_Prv_nom.fx(z,zx,ni) = Fix_U_Prv_nom(z,zx,ni);
*F_Prov.fx(z,zx,yr,h) = Fix_F_CT(z,zx,yr,h);

* ======================== Carbon Network Modeling ======================== *
* Screening useful operation years for Carbon Network technologies
Sets  xcsz(z)               no carbon storage cities      / BJ, FJ, GD, GX, HI, JX, SH, XZ, ZJ /;

Sets  J_CN_s(cn,pz,pj,n)        installation year of carbon network technologies
      J_CN_u(cn,pz,pj,n,yr)     useful operation years for technology installed in z and n
      J_CN_r(cn,pz,pj,yr)       technology available in zone z year yr;
      
Sets  cpf(pz,pj)     Province and pref match
      csf(pz,pj)     Prefecture with CS
      cnt(z,zx)      Carbon network stracture;
      
cpf(pz,pj)$(pref_mt(pz,pj)) = yes;
csf(pz,pj)$(U_CS_rLim('dsac',pz,pj) > 0) = yes;
cnt(z,zx)$(ETNS_dstn(z,zx) > 0) = yes;

display cpf, csf, cnt;
      
Parameter U_CN_exn_pref(cn,pz,pj);
U_CN_exn_pref(cn,pz,pj)$(cpf(pz,pj)) = 0;

* Useful operation years for existing technologies 
J_CN_u(cn,pz,pj,'y0',yr)$(cpf(pz,pj) and U_CN_exn_pref(cn,pz,pj) and (ord(yr) <= CNet_Specs(cn,'ltm'))) = yes; 

* Useful operation years for newly installed technologies 
J_CN_u(cn,pz,pj,n(y),yr)$(cpf(pz,pj) and (ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + CNet_Specs(cn,'ltm') - 1), card(yr)))) = yes;

* Filter operation years for carbon storage technologies unavailable in cities
J_CN_u('dsac',pz,pj,n,yr)$(not csf(pz,pj)) = no;
J_CN_u('dsac',pz,pj,n,yr)$((ord(n) > 1) and xcsz(pz)) = no;

* installation years
Loop(J_CN_u(cn,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), J_CN_s(cn,pz,pj,n) = yes);

* technologies available in zone z year yr
J_CN_r(cn,pz,pj,yr)$(sum(J_CN_u(cn,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;

Display J_CN_s, J_CN_u, J_CN_r;


* The first year and final years: carbon network technologies 
Parameters ycn(cn,pz,pj,n), yco(cn,pz,pj,n), ycm(cn,pz,pj,n);
ycn(cn,pz,pj,'y0')$(J_CN_u(cn,pz,pj,'y0','y1')) = 1; 
Loop(J_CN_u(cn,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ycn(cn,pz,pj,n) = ord(yr));   // The first operation year 
yco(cn,pz,pj,n)$(ycn(cn,pz,pj,n)) = sum(yr$(J_CN_u(cn,pz,pj,n,yr)), 1);                                  // The operation period
ycm(cn,pz,pj,n)$(ycn(cn,pz,pj,n)) = yco(cn,pz,pj,n) + ycn(cn,pz,pj,n) - 1;                                   // The last operation year

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
Positive variables U_CP_nom(cp,pz,pj,n);

* Carbon compression capacity continuation
Positive variables U_CP_anom(cp,pz,pj,n,yr);
Equations eqU_CP_cpnn,        // Technology installation capacity when n >= 1
          eqU_CP_cpcma,
          eqU_CP_cpcmb;
          
* Fix U_CP_anom(cp,z,n,n) to U_CP_anom(cp,z,n): All newly installed technologies
* 第n年安装的技术在第n年的容量 等于 第n年安装的容量
eqU_CP_cpnn(J_CN_u(cp,pz,pj,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_CP_anom(cp,pz,pj,n,yr) =E= U_CP_nom(cp,pz,pj,n);   // ton/hr, ~1

* Technology capacities when n = 0
U_CP_anom.fx(cp,pz,pj,'y0','y1') = U_CN_exn_pref(cp,pz,pj); 
eqU_CP_cpcma(J_CN_u(cp,pz,pj,'y0',yr))$(ord(yr) < ycm(cp,pz,pj,'y0')) .. U_CP_anom(cp,pz,pj,'y0',yr+1) =E= U_CP_anom(cp,pz,pj,'y0',yr);

* Technology decommission when n = 0 or n >= 1
* n = 0, n >= 1
eqU_CP_cpcmb(J_CN_u(cp,pz,pj,n,yr))$(ord(yr) < ycm(cp,pz,pj,n)) .. U_CP_anom(cp,pz,pj,n,yr+1) =E= U_CP_anom(cp,pz,pj,n,yr);   // ton/hr, ~1,

* For computing cumulative capacity, ton/hr    
Positive variables U_CP_acm(cp,pz,pj,yr); 
Equations eqU_cp_acm;       

eqU_cp_acm(J_CN_r(cp,pz,pj,yr)) .. U_CP_acm(cp,pz,pj,yr) =E= sum(J_CN_u(cp,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), U_CP_anom(cp,pz,pj,n,yr));   // ton/hr, ~1

* ========= Carbon compressor operation
Positive variables M_CP(cp,pz,pj,yr,h), P_CP(pz,pj,yr,h);                         // ton, GWh
Equations eqM_CPa, eqM_CPb, eqP_CP;

* 压缩量 = 碳捕集量（CCS）, DAC捕集量较少暂时不考虑
eqM_CPa(J_CN_r(cp,pz,pj,yr), h) ..  M_CP(cp,pz,pj,yr,h) =L= U_CP_acm(cp,pz,pj,yr);
eqM_CPb(pz,pj,yr,h)$cpf(pz,pj) .. sum(J_CN_r(cp,pz,pj,yr), M_CP(cp,pz,pj,yr,h)) =E= CO2_CCS(pz,pj,yr,h) * ths;
eqP_CP(pz,pj,yr,h)$cpf(pz,pj) .. P_CP(pz,pj,yr,h) =E= c_CP * CO2_CCS(pz,pj,yr,h);    // GWh

* ========= Investment and operation costs
Parameters CNet_uCaPx(cn,y);
CNet_uCaPx(cn,yr) = CNet_CaPx(cn,'%scn%',yr);

Positive variables CaPx_CP(n), FOM_CP(yr);
Equations eqCaPx_CP, eqFOM_CP;              // no vom

eqCaPx_CP(n)$(ord(n) > 1) .. CaPx_CP(n) =E= sum(J_CN_s(cp,pz,pj,n), dn(n) * CN_afr(cp) * CN_dsm(cp,n) * CNet_uCaPx(cp,n) * ths * U_CP_nom(cp,pz,pj,n));     // k USD

eqFOM_CP(yr) .. FOM_CP(yr) =E= sum(J_CN_r(cp,pz,pj,yr), dn(yr) * CNet_FOM(cp,'%scn%',yr) / ths * U_CP_acm(cp,pz,pj,yr));        // k USD


* ====================== CS: Carbon Storage ====================== *
* ========= Capacity sizing: Carbon storage technologies
Positive variables U_CS_nom(cs,z,pj,n);
Equations eqU_CS_nom, eqU_CS_bLim;

eqU_CS_nom(cs,z,n)$(ord(n) > 1 and sum(pj$csf(z,pj), 1)) .. sum(pj$cpf(z,pj),U_CS_nom(cs,z,pj,n)) =L= U_CS_Max(cs,z);                    // ton/hr
eqU_CS_bLim(cs,n)$(ord(n) > 1) .. sum(J_CN_s(cs,z,pj,n), U_CS_nom(cs,z,pj,n)) =L= U_CS_bLim(cs) * invSpan(n);   // ton/hr

U_CS_nom.fx(cs,z,pj,n)$(not csf(z,pj)) = 0;
U_CS_nom.fx(cs,z,pj,'y0') = 0;

* Capacity continuation
Positive variables U_CS_anom(cs,z,pj,n,yr);        // ton/hr
Equations eqU_CS_anoma, eqU_CS_anomb, eqU_CS_anomc;

* Fix U_CS_anom(cs,z,n,n) to U_CS_nom(cs,z,n): All newly installed storage technologies
eqU_CS_anoma(J_CN_u(cs,z,pj,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_CS_anom(cs,z,pj,n,yr) =E= U_CS_nom(cs,z,pj,n);

* Storage technology decommission when n = 0
U_CS_anom.fx(cs,z,pj,'y0','y1') = 0;
eqU_CS_anomb(J_CN_u(cs,z,pj,'y0',yr))$(ord(yr) < ycm(cs,z,pj,'y0')) .. U_CS_anom(cs,z,pj,'y0',yr+1) =E= U_CS_anom(cs,z,pj,'y0',yr);          

* Storage technology decommission when n >= 1
eqU_CS_anomc(J_CN_u(cs,z,pj,n,yr))$((ord(n) > 1) and (ord(yr) < ycm(cs,z,pj,n))) .. U_CS_anom(cs,z,pj,n,yr+1) =E= U_CS_anom(cs,z,pj,n,yr);   

Positive variables U_CS_acm(cs,z,pj,yr);      
Equations eqU_CS_acm;

eqU_CS_acm(J_CN_r(cs,z,pj,yr)) ..  U_CS_acm(cs,z,pj,yr) =E= sum(J_CN_u(cs,z,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), U_CS_anom(cs,z,pj,n,yr));

* ========= Operations: Carbon storage technologies
Parameters CS_loss(cs)   / dsac 0 /;

Positive Variables
    C_CS(cs,z,pj,yr,h)     "hourly CO2 injection rate, ton/h"
    En_CS(cs,z,pj,yr)      "cumulative stored CO2 up to year yr, ton";

Equations eqC_CS, eqEn_CS_y1, eqEn_CS_yr, eqEn_CS_lim;

eqC_CS(J_CN_r(cs,z,pj,yr), h) .. C_CS(cs,z,pj,yr,h) =L= CNet_Specs(cs,'lm') * U_CS_acm(cs,z,pj,yr);

eqEn_CS_y1(J_CN_r(cs,z,pj,'y1')) .. En_CS(cs,z,pj,'y1') =E= sum(h, nds * CNet_Specs(cs,'eta') * C_CS(cs,z,pj,'y1',h));
eqEn_CS_yr(J_CN_r(cs,z,pj,yr))$(ord(yr) > 1) .. En_CS(cs,z,pj,yr) =E=
                                                En_CS(cs,z,pj,yr-1) * (1- CS_loss(cs)) + sum(h, nds * CNet_Specs(cs,'eta') * C_CS(cs,z,pj,yr,h));

eqEn_CS_lim(J_CN_r(cs,z,pj,yr)) .. En_CS(cs,z,pj,yr) =L= U_CS_rLim(cs,z,pj) * 1e6;

* ========= Investment and operation costs
Positive variables CaPx_CS(n), FOM_CS(yr), FOM_CS_U(yr);
Equations eqCaPx_CS, eqFOM_CS, eqFOM_CS_kUSD;

eqCaPx_CS(n)$(ord(n) > 1) .. CaPx_CS(n) =E= sum(J_CN_s(cs,z,pj,n), dn(n) * CN_afr(cs) * CN_dsm(cs,n) * CNet_uCaPx(cs,n) * ths * U_CS_nom(cs,z,pj,n));   // k USD

eqFOM_CS(yr) .. FOM_CS_U(yr) =E= sum(J_CN_r(cs,z,pj,yr), dn(yr) * CNet_FOM(cs,'%scn%',yr) * U_CS_acm(cs,z,pj,yr));      // USD

eqFOM_CS_kUSD(yr) .. FOM_CS(yr) =E= FOM_CS_U(yr) / ths;    // k USD


* ====================== CT: Carbon Transmission from city pj tp px in z, or from province z to zx====================== *
Scalars dt   decend rate for carbon transportation   / 0.015 /;
Parameters cdt(y);     // carbon transportation decrease rates

cdt(yr) = 1 / ((1 + dt) ** (ord(yr) - 1));

Scalars   CT_ECON    / 0.00025 /     // MWh/ton/km: power needed during pipeline transmission
          CT_loss    / 0.000008 /;   // Line loss: 0.8% per 1000km

* Carbon transmission costs: ppln (3.5% of CaPx)
Scalars   CT_CaPx    / 1.504 /      // ppln: k USD/ton/hr/km      
          CT_FOM     / 0.0526 /     // ppln: k USD/ton/hr/km/yr
          CT_VOM     / 11.213 /;    // ppln: USD/ton/hr/km;

* ========= Carbon transimission
Sets vco(z,zx)            existing internal transmission lines
     vcz(z,zx)            transmission lines for capacity expansion
     vcx(z,zx)            all possible bidirectional transmission           // Province transmission
     
     fco(z,pj,px)         existing internal transmission lines
     fcz(z,pj,px)         transmission lines for capacity expansion
     fcx(z,pj,px)         all possible bidirectional transmission;          // Prefecture transmission

Sets
     J_TV_u(z,zx,ni,yr)   useful operation years for carbon pipelines       // From z to zx, z < zx
     J_TV_r(z,zx,yr)      pipeline transmission available in year yr
     J_TV_pn(z,yr)        carbon pipeline connection with z in year yr
     
     J_TF_u(z,pj,px,ni,yr)   useful operation years for carbon pipelines    // From pj to px, pj < px
     J_TF_r(z,pj,px,yr)      pipeline transmission available in year yr
     J_TF_pn(z,pj,yr)        carbon pipeline connection with pj in year yr;

* Carbon transmission expansion
vco(z,zx)$(Pv_Dstn(z,zx) and (ord(z) < ord(zx))) = yes;  // Existing transmission lines, z < zx
vcz(z,zx) = vco(z,zx);                                   // Possible transmission lines for expansion
vcx(z,zx)$(Pv_Dstn(z,zx)) = yes;                         // All possible bidirectional transmission

vcz('SH','LN') = no;
vcz('JS','LN') = no;
vcz('SD','LN') = no;
vcz('SH','JL') = no;
vcz('JS','JL') = no;
vcz('SD','JL') = no;
vcz('SH','HL') = no;
vcz('JS','HL') = no;
vcz('SD','HL') = no;

vcz('LN','SH') = no;
vcz('LN','JS') = no;
vcz('LN','SD') = no;
vcz('JL','SH') = no;
vcz('JL','JS') = no;
vcz('JL','SD') = no;
vcz('HL','SH') = no;
vcz('HL','JS') = no;
vcz('HL','SD') = no;


vcx('SH','LN') = no;
vcx('JS','LN') = no;
vcx('SD','LN') = no;
vcx('SH','JL') = no;
vcx('JS','JL') = no;
vcx('SD','JL') = no;
vcx('SH','HL') = no;
vcx('JS','HL') = no;
vcx('SD','HL') = no;

vcx('LN','SH') = no;
vcx('LN','JS') = no;
vcx('LN','SD') = no;
vcx('JL','SH') = no;
vcx('JL','JS') = no;
vcx('JL','SD') = no;
vcx('HL','SH') = no;
vcx('HL','JS') = no;
vcx('HL','SD') = no;

fco(z,pj,px)$(cpf(z,pj) and cpf(z,px) and Pf_Dstn(z,pj,px) and (ord(pj) < ord(px))) = yes; 
fcz(z,pj,px) = fco(z,pj,px);
fcx(z,pj,px)$(cpf(z,pj) and cpf(z,px) and Pf_Dstn(z,pj,px)) = yes;

display vco, vcz, vcx, fco, fcz, fcx;

* Pipeline define for province
J_TV_u(z,zx,'y0',yr) = no;                     // Existing transmission pipelines
J_TV_u(vcz(z,zx),ni(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ctlm - 1), card(yr)))) = yes;   // Possible transmission pipelines
J_TV_r(z,zx,yr)$(sum(J_TV_u(z,zx,ni(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;      // z < zx, lines connecting z and zx in year yr
J_TV_pn(z,yr)$(sum(vcx(z,zx), 1) >= 1) = yes;                                          // carbon pipeline connection with z

* Pipeline define for prefecture
J_TF_u(z,pj,px,'y0',yr)$(Pf_Dstn(z,pj,px)) = no;                                              // Existing transmission pipelines
J_TF_u(fcz(z,pj,px),ni(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ctlm - 1), card(yr)))) = yes;   // Possible transmission pipelines
J_TF_r(z,pj,px,yr)$(sum(J_TF_u(z,pj,px,ni(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;       // z < zx, lines connecting z and zx in year yr
J_TF_pn(z,pj,yr)$(cpf(z,pj) and sum(fcx(z,pj,px), 1) >= 1) = yes;                                           // carbon pipeline connection with z

display J_TV_u, J_TV_r, J_TV_pn, J_TF_u, J_TF_r, J_TF_pn;

* The first year and final years: carbon pipeline transmission
Parameters ypvn(z,zx,ni), ypvo(z,zx,ni), ypvm(z,zx,ni);
ypvn(z,zx,'y0')$(J_TV_u(z,zx,'y0','y1')) = 1;
Loop(J_TV_u(z,zx,ni(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ypvn(z,zx,ni) = ord(yr););   // The first operation year
ypvo(z,zx,ni)$(ypvn(z,zx,ni)) = sum(yr$(J_TV_u(z,zx,ni,yr)), 1);                                 // The operation period
ypvm(z,zx,ni)$(ypvn(z,zx,ni)) = ypvo(z,zx,ni) + ypvn(z,zx,ni) - 1;                               // The last  operation year

Parameters ypfn(z,pj,px,ni), ypfo(z,pj,px,ni), ypfm(z,pj,px,ni);
ypfn(z,pj,px,'y0')$(J_TF_u(z,pj,px,'y0','y1')) = 1;
Loop(J_TF_u(z,pj,px,ni(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ypfn(z,pj,px,ni) = ord(yr););    // The first operation year
ypfo(z,pj,px,ni)$(ypfn(z,pj,px,ni)) = sum(yr$(J_TF_u(z,pj,px,ni,yr)), 1);                               // The operation period
ypfm(z,pj,px,ni)$(ypfn(z,pj,px,ni)) = ypfo(z,pj,px,ni) + ypfn(z,pj,px,ni) - 1;                          // The last  operation year

Display ypvn, ypvo, ypvm, ypfn, ypfo, ypfm;

* Discounted share of lifetime for hydrogen transmission technologies
Parameters CT_afr, CT_dsm(ni), CT_TM(ni);

CT_afr = (1 - 1 / (1 + ir)) / (1 - 1 / ((1 + ir) ** ctlm));   // Annualized factor for hydrogem transmission
CT_dsm(ni(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, ctlm)))) / (1 - 1 / (1 + ir));

CT_TM(ni) = CT_afr * CT_dsm(ni);

Display CT_afr, CT_dsm, CT_TM;


* ========= Capacity sizing
Positive variables U_Pef_nom(z,pj,px,ni);   // ton/hr
Equations eqU_CT_nom1, eqU_CT_nom2, eqU_CT_bLim1, eqU_CT_bLim2;

eqU_CT_nom1(vcz(z,zx), ni)$(ord(ni) > 1) .. U_Prv_nom(z,zx,ni) =L= U_CT_Max(z,zx);             // installation cap. <= max. caps, ton/hr
eqU_CT_nom2(fcz(z,pj,px), ni)$(ord(ni) > 1) .. U_Pef_nom(z,pj,px,ni) =L= U_CT_Pf_Max(z,pj,px);
eqU_CT_bLim1(ni)$(ord(ni) > 1) .. sum(vcz(z,zx), U_Prv_nom(z,zx,ni)) =L= U_CT_Pv_bLim * invSpan(ni);         // Max. building rates, ton/hr
eqU_CT_bLim2(ni)$(ord(ni) > 1) .. sum(fcz(z,pj,px), U_Pef_nom(z,pj,px,ni)) =L= U_CT_Pf_bLim * invSpan(ni);   

* Capacity continuation
Positive variables U_Prv_anom(z,zx,ni,yr), U_Pef_anom(z,pj,px,ni,yr);
Equations eqU_CT_anoma, eqU_CT_anomb, eqU_CT_anomc;
Equations eqU_CT_anom1, eqU_CT_anom2, eqU_CT_anom3;

* Fix capacity U_CT_anom(ct,z,zx,ni,ni) to U_CT_nom(ct,z,zx,ni)
eqU_CT_anoma(J_TV_u(z,zx,ni(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_Prv_anom(z,zx,ni,yr) =E= U_Prv_nom(z,zx,ni);
eqU_CT_anom1(J_TF_u(z,pj,px,ni(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_Pef_anom(z,pj,px,ni,yr) =E= U_Pef_nom(z,pj,px,ni);

* Pipeline transmission technologies decommission when n = 0
U_Prv_anom.fx(z,zx,'y0','y1') = 0;
eqU_CT_anomb(J_TV_u(z,zx,'y0',yr))$(ord(yr) < ypvm(z,zx,'y0')) .. U_Prv_anom(z,zx,'y0',yr+1) =E= U_Prv_anom(z,zx,'y0',yr);

U_Pef_anom.fx(z,pj,px,'y0','y1')$(Pf_Dstn(z,pj,px)) = 0;
eqU_CT_anom2(J_TF_u(z,pj,px,'y0',yr))$(ord(yr) < ypfm(z,pj,px,'y0')) .. U_Pef_anom(z,pj,px,'y0',yr+1) =E= U_Pef_anom(z,pj,px,'y0',yr);

* Transimission technology decommission when n >= 1
eqU_CT_anomc(J_TV_u(z,zx,ni,yr))$((ord(ni) > 1) and (ord(yr) < ypvm(z,zx,ni))) .. U_Prv_anom(z,zx,ni,yr+1) =E= U_Prv_anom(z,zx,ni,yr);   
eqU_CT_anom3(J_TF_u(z,pj,px,ni,yr))$((ord(ni) > 1) and (ord(yr) < ypfm(z,pj,px,ni))) .. U_Pef_anom(z,pj,px,ni,yr+1) =E= U_Pef_anom(z,pj,px,ni,yr);   

* Cumulative capacity of pipeline transmission
Positive variables U_Prv_acm(z,zx,yr), U_Pef_acm(z,pj,px,yr);   // ton/hr
Equations eqU_CT_acm1, eqU_CT_acm2;

eqU_CT_acm1(J_TV_r(z,zx,yr)) .. U_Prv_acm(z,zx,yr) =E= sum(J_TV_u(z,zx,ni(y),yr)$(ord(y)-1 <= ord(yr)), U_Prv_anom(z,zx,ni,yr));               // accumulative caps
eqU_CT_acm2(J_TF_r(z,pj,px,yr)) .. U_Pef_acm(z,pj,px,yr) =E= sum(J_TF_u(z,pj,px,ni(y),yr)$(ord(y)-1 <= ord(yr)), U_Pef_anom(z,pj,px,ni,yr));   // accumulative caps

* ========= Pipeline Operations
Positive variables F_City(z,pj,px,yr,h);    // ton/hr
Equations eqF_Prov1, eqF_Prov2, eqF_Prov3;                                          
Equations eqF_City1, eqF_City2, eqF_City3; 

eqF_City1(J_TF_r(z,pj,px,yr),h) .. F_City(z,pj,px,yr,h) * (1 - CT_loss * Pf_Dstn(z,pj,px)) =L= U_Pef_acm(z,pj,px,yr);    // Carbon flow <= caps: pj to jx in z
eqF_City2(J_TF_r(z,pj,px,yr),h) .. F_City(z,px,pj,yr,h) * (1 - CT_loss * Pf_Dstn(z,px,pj)) =L= U_Pef_acm(z,pj,px,yr);    // Carbon flow <= caps: px to pj in z
eqF_City3(J_TF_r(z,pj,px,yr),h) .. (F_City(z,px,pj,yr,h) + F_City(z,pj,px,yr,h)) * (1 - CT_loss * Pf_Dstn(z,pj,px)) =L= U_Pef_acm(z,pj,px,yr);

eqF_Prov1(J_TV_r(z,zx,yr),h) .. F_Prov(z,zx,yr,h) * (1 - CT_loss * Pv_Dstn(z,zx)) =L= U_Prv_acm(z,zx,yr);                // Carbon flow <= caps: z to zx
eqF_Prov2(J_TV_r(z,zx,yr),h) .. F_Prov(zx,z,yr,h) * (1 - CT_loss * Pv_Dstn(zx,z)) =L= U_Prv_acm(z,zx,yr);                // Carbon flow <= caps: zx to z
eqF_Prov3(J_TV_r(z,zx,yr),h) .. (F_Prov(zx,z,yr,h) + F_Prov(z,zx,yr,h)) * (1 - CT_loss * Pv_Dstn(z,zx)) =L= U_Prv_acm(z,zx,yr);

* Summartion of export and import
Positive variables CT_exp(z,yr,h), CT_imp(z,yr,h);
Positive variables F_exp(z,pj,yr,h), F_imp(z,pj,yr,h);         // ton/hr

Equations eq_CT_exp, eq_CT_imp; 
eq_CT_exp(z,yr,h) .. CT_exp(z,yr,h) =E= sum(pj$cpf(z,pj), F_exp(z,pj,yr,h)) + DAC_exp(z,yr,h);
eq_CT_imp(z,yr,h) .. CT_imp(z,yr,h) =E= sum(pj$cpf(z,pj), F_imp(z,pj,yr,h));

Equations eq_F_prov_exp, eq_F_prov_imp;
eq_F_prov_exp(z,yr,h) .. CT_exp(z,yr,h) =E= sum(vcx(z,zx), F_Prov(z,zx,yr,h));
eq_F_prov_imp(z,yr,h) .. CT_imp(z,yr,h) =E= sum(vcx(zx,z), F_Prov(zx,z,yr,h) * (1 - CT_loss * Pv_Dstn(z,zx))) + DAC_imp(z,yr,h);

* ========= Investment and operation costs
Positive variables CaPx_CT(ni), FOM_CT(yr);
Equations eqCaPx_CT, eqFOM_CT; 

eqCaPx_CT(ni)$(ord(ni) > 1) .. CaPx_CT(ni) =E= sum(vcz(z,zx), 
                                               dn(ni) * cdt(ni) * CT_afr * CT_dsm(ni) * CT_CaPx * Pv_Dstn(z,zx) * U_Prv_nom(z,zx,ni)) +
                                               sum(fcz(z,pj,px),
                                               dn(ni) * cdt(ni) * CT_afr * CT_dsm(ni) * CT_CaPx * Pf_Dstn(z,pj,px) * U_Pef_nom(z,pj,px,ni));   // k USD, ~30

eqFOM_CT(yr) ..  FOM_CT(yr) =E= sum(J_TV_r(z,zx,yr), dn(yr) * cdt(yr) * CT_FOM * Pv_Dstn(z,zx) * U_Prv_acm(z,zx,yr)) +
                                sum(J_TF_r(z,pj,px,yr), dn(yr) * cdt(yr) * CT_FOM * Pf_Dstn(z,pj,px) * U_Pef_acm(z,pj,px,yr));      // k USD, ~0.4


* ========================== Carbon flow balances ========================== *
* Parameters CO2_CCS(z,pj,yr,h), CO2_DAC(z,yr,h);
*Positive variables CO2_dis(z,pj,yr,h);

Positive variables CS_in(z,pj,yr,h), CS_out(z,pj,yr,h), CS_sum(z,pj,yr,h);      // ton/hr
Equations eqCS1, eqCS2;
Equations eqCflow, eqCS;

eqCS(z,pj,yr,h)$cpf(z,pj)  .. CS_sum(z,pj,yr,h) =E= sum(J_CN_r(cs,z,pj,yr), C_CS(cs,z,pj,yr,h));
eqCS1(z,pj,yr,h)$cpf(z,pj) .. CS_sum(z,pj,yr,h) =E= CS_in(z,pj,yr,h) + CS_out(z,pj,yr,h);
eqCS2(z,pj,yr,h)$cpf(z,pj) .. CS_out(z,pj,yr,h) =E= F_imp(z,pj,yr,h) + sum(px$(cpf(z,px) and fcx(z,px,pj)), F_City(z,px,pj,yr,h) * (1 - CT_loss * Pf_Dstn(z,px,pj)));

eqCflow(z,pj,yr,h)$cpf(z,pj) .. CO2_CCS(z,pj,yr,h) * ths =E= F_exp(z,pj,yr,h) + CS_in(z,pj,yr,h) + sum(px$(cpf(z,px) and fcx(z,pj,px)), F_City(z,pj,px,yr,h));


* ========================== Invesment and operation costs ========================== *
* CC/CP/CT/CS
* Scalar CO2_DIS_PEN / 10 /;      // USD/ton

Variables TSC_Cnet;
Positive variables CaPx_Cnet, FOM_Cnet, DIS_Cnet;
Equations eqCaPx_Cnet, eqFOM_Cnet, eqTSC_Cnet;    // eqDIS_Cnet;

eqCaPx_Cnet .. CaPx_Cnet =E= sum(n$(ord(n) > 1), CaPx_CS(n) + CaPx_CP(n)) + sum(ni$(ord(ni) > 1), CaPx_CT(ni));     // k USD

*eqFCS_Cnet .. FCS_Cnet   =E= sum(yr, FCS_DAC(yr));                                // k USD

eqFOM_Cnet .. FOM_Cnet =E= sum(yr, FOM_CP(yr) + FOM_CT(yr) + FOM_CS(yr));          // k USD

*eqDIS_Cnet .. DIS_Cnet =E= sum((z,pj,yr,h)$cpf(z,pj), dn(yr) * nds * CO2_DIS_PEN / ths * CO2_dis(z,pj,yr,h));       // k USD

eqTSC_Cnet .. TSC_Cnet =E= (CaPx_Cnet + FOM_Cnet);                                 // k USD, + DIS_Cnet


* ========================== Model solving ========================== *
Model China_Carbon_Network / all /;

// Solution options
Options lp = gurobi, optcr = 0.03, reslim = 164000, limrow = 0, limcol = 0, threads = 64; //, limcol = 0, solprint = on, sysout = off;

* Crossover 0
* method 2
* presolve 2
* ScaleFlag 1
* BarHomogeneous 1

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


* Display optimization results
$include %Cfolder%/EC_Display.gms

* Save results into GDX files
$include %Cfolder%/EC_Results.gms
