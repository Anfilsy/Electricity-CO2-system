$Title Carbon Network System Optimization
* DAC

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

Parameters  tau_cs(cs)  discharge duration hr    / dsac 240  /
            ctlm(ct)    carbon trans pipeline    / ppln 40 /;   



// Import data for Carbon Network optimization
* =========================================================================== *
$include %Cfolder%/C_Network_Data.gms

* ======================== Carbon Network Parameters ======================== *
$include %Cfolder%/C_Network_Param.gms



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



* ====================== CC: Carbon  Capture ====================== *
* CC = DAC + CCS (直接空气碳捕集 + 点源碳捕集)
* 1. DAC technologies

* ========= Capacity sizing: DAC
Positive variables U_DAC_nom(ccdg,z,n);      // ton/hr
Equations eqU_DAC_nom, eqU_DAC_bLim;

* U_DAC_nom.fx(ccdg,z,n) = 0;

eqU_DAC_nom(J_CN_s(ccdg,z,n)) .. U_DAC_nom(ccdg,z,n) =L= U_DAC_Max(ccdg,z);                          // ton/hr  
eqU_DAC_bLim(ccdg,n)$(ord(n) > 1) .. sum(J_CN_s(ccdg,z,n), U_DAC_nom(ccdg,z,n)) =L= U_DAC_bLim(ccdg) * invSpan(n);     // ton/hr

Positive variables U_DAC_anom(ccdg,z,n,yr), U_DAC_dnm(ccdg,z,n,yr);
Equations eqU_DAC_dgnn, eqU_DAC_dgcm;

* Fix U_DAC_anom(ccdg,z,n,n) to U_DAC_nom(ccdg,z,n): All newly installed DAC technologies
* 第n年安装的技术在第n年的容量 等于 第n年安装的容量
eqU_DAC_dgnn(J_CN_u(ccdg,z,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_DAC_anom(ccdg,z,n,yr) =E= U_DAC_nom(ccdg,z,n);   // ton/hr, ~1

* 现有技术第1年的装机容量 等于 现存的容量
U_DAC_anom.fx(ccdg,z,'y0','y1') = U_CN_exn(ccdg,z);   

* n = 0或n>= 1，新安装DAC技术可以退役
eqU_DAC_dgcm(J_CN_u(ccdg,z,n,yr))$(ord(yr) < ycm(ccdg,z,n)) .. U_DAC_anom(ccdg,z,n,yr+1) =E= U_DAC_anom(ccdg,z,n,yr);   // ton/hr, ~1, - U_DAC_dnm(ccdg,z,n,yr+1)

* 限制退役的容量
U_DAC_dnm.fx(J_CN_u(ccdg,z,n,yr)) = 0.0; 

* For computing cumulative capacity, ton/hr
Positive variables U_DAC_acm(ccdg,z,yr);      
Equations eqU_DAC_acm;   

eqU_DAC_acm(J_CN_r(ccdg,z,yr)) .. U_DAC_acm(ccdg,z,yr) =E= sum(J_CN_u(ccdg,z,n(y),yr)$(ord(y)-1 <= ord(yr)), U_DAC_anom(ccdg,z,n,yr));   // ton/hr, ~1 


* ========= Operations: DAC
Positive variables M_CO2_DAC(ccdg,z,yr,h), P_CO2_DAC(ccdg,z,yr,h), Q_CO2_DAC(ccdg,z,yr,h);
Equations eqM_CO2_DAC, eqP_CO2_DAC, eqQ_CO2_DAC;

eqM_CO2_DAC(J_CN_r(ccdg,z,yr), h) .. M_CO2_DAC(ccdg,z,yr,h) =L= U_DAC_acm(ccdg,z,yr);     // ton/hr, hourly capture rates

eqP_CO2_DAC(J_CN_r(ccdg,z,yr), h) .. P_CO2_DAC(ccdg,z,yr,h) =E= CNet_Specs(ccdg,'etae') * M_CO2_DAC(ccdg,z,yr,h);       // MWh, 0.3~6
eqQ_CO2_DAC(J_CN_r(ccdg,z,yr), h) .. Q_CO2_DAC(ccdg,z,yr,h) =E= CNet_Specs(ccdg,'etaq') * M_CO2_DAC(ccdg,z,yr,h);       // MWh, 0~3

* DAC capacity factors: Maximun and Minimun
Equations eqDAC_CFm, eqDAC_CFn;

eqDAC_CFm(J_CN_r(ccdg,z,yr)) .. sum(h, nds * M_CO2_DAC(ccdg,z,yr,h)) =L= nhys * CNet_Specs(ccdg,'cfm') * U_DAC_acm(ccdg,z,yr);    // ton, 1~8760
eqDAC_CFn(J_CN_r(ccdg,z,yr)) .. sum(h, nds * M_CO2_DAC(ccdg,z,yr,h)) =G= nhys * CNet_Specs(ccdg,'cfn') * U_DAC_acm(ccdg,z,yr);    // ton, 1~8760

* DAC ramping
Equations eqDAC_rampa, eqDAC_rampb;
eqDAC_rampa(J_CN_r(ccdg,z,yr), h)$(ord(h) > 1) .. M_CO2_DAC(ccdg,z,yr,h) - M_CO2_DAC(ccdg,z,yr,h-1) =L=  CNet_Specs(ccdg,'ro') * U_DAC_acm(ccdg,z,yr);    // ton, 0.3~1
eqDAC_rampb(J_CN_r(ccdg,z,yr), h)$(ord(h) > 1) .. M_CO2_DAC(ccdg,z,yr,h) - M_CO2_DAC(ccdg,z,yr,h-1) =G= -CNet_Specs(ccdg,'ro') * U_DAC_acm(ccdg,z,yr);    // ton, 0.3~1

* Captured CO2 and energy consumption
Positive variables P_DAC(z,yr,h), CO2_DAC(yr), Q_DAC_NG(z,yr);
Equations eqP_DAC, eqCO2_DAC, eqQ_DAC_NG;

eqP_DAC(J_DAC_v(z,yr),h) .. P_DAC(z,yr,h) * ths =E= sum(J_CN_r(ccdg,z,yr), P_CO2_DAC(ccdg,z,yr,h));                 // GWh, 1~1000
eqCO2_DAC(yr) .. CO2_DAC(yr) * ths =E= sum((J_CN_r(ccdg,z,yr), h), nds * M_CO2_DAC(ccdg,z,yr,h));                   // kton, 1~1000
eqQ_DAC_NG(J_DAC_v(z,yr)) .. Q_DAC_NG(z,yr) * ths =E= sum((J_CN_r(ccdg,z,yr), h), nds * Q_CO2_DAC(ccdg,z,yr,h));    // GWh, 1~1000


* ======= Investment and operation costs
Parameters DAC_uCaPx(ccdg,y);
DAC_uCaPx(ccdg,yr) = CNet_CaPx(ccdg,'%scn%',yr);   // M USD/ton/yr

Positive variables CaPx_DAC(n), FCS_DAC(yr), FOM_DAC(yr);   
Equations eqCaPx_DAC, eqFCS_DAC, eqFOM_DAC;

eqCaPx_DAC(n)$(ord(n) > 1) .. CaPx_DAC(n) =E= sum(J_CN_s(ccdg,z,n), dn(n) * CN_afr(ccdg) * CN_dsm(ccdg,n) * DAC_uCaPx(ccdg,n) * ths * nhys * U_DAC_nom(ccdg,z,n));   // k USD/yr, ~0.6-5

eqFCS_DAC(yr) .. FCS_DAC(yr) =E= sum(J_DAC_v(z,yr), dn(yr) * (c_NG * Q_DAC_NG(z,yr)));                                                       // k USD/yr, ~0.008

eqFOM_DAC(yr) .. FOM_DAC(yr) =E= sum(J_CN_r(ccdg,z,yr), dn(yr) * CNet_FOM(ccdg,'%scn%',yr) / ths * nhys * U_DAC_acm(ccdg,z,yr));             // k USD/yr, 0.02~0.15


* 2. CCS technologies
* Computing cumulative carbon (DAC + CCS)
* 此处z,yr,h三种尺度计算均给出

Positive Variables CC_DAC_zyr(z,yr), CC_DAC_h(z,yr,h);
Positive Variables CC_CCS_zyr(z,yr), CC_CCS_yr(yr), CC_CCS_h(z,yr,h);
Positive Variables CC_Sum_zyr(z,yr), CC_Sum_yr(yr), CC_Sum_h(z,yr,h);

Equations eqCC_DAC_zyr, eqCC_DAC_h, eqCC_CCS_zyr, eqCC_CCS_yr, eqCC_CCS_h;
Equations eqCC_Sum_zyr, eqCC_Sum_yr, eqCC_Sum_h;

eqCC_DAC_zyr(J_DAC_v(z,yr)) .. CC_DAC_zyr(z,yr) * ths =E= sum((J_CN_r(ccdg,z,yr),h), nds * M_CO2_DAC(ccdg,z,yr,h));      // kton
eqCC_DAC_h(J_DAC_v(z,yr),h) .. CC_DAC_h(z,yr,h) * ths =E= sum(J_CN_r(ccdg,z,yr), M_CO2_DAC(ccdg,z,yr,h));                // kton

eqCC_CCS_zyr(J_CCS_v(z,yr)) .. CC_CCS_zyr(z,yr) =E= sum((J_ET_r(ccsg,z,yr),h), nds * E_EG_CO2(ccsg,z,yr,h));             // kton
eqCC_CCS_yr(yr) .. CC_CCS_yr(yr) =E= sum((J_ET_r(ccsg,z,yr),h), nds * E_EG_CO2(ccsg,z,yr,h));                            // kton
eqCC_CCS_h(J_CCS_v(z,yr),h) .. CC_CCS_h(z,yr,h) =E= sum(J_ET_r(ccsg,z,yr), E_EG_CO2(ccsg,z,yr,h));                       // kton
 
eqCC_Sum_zyr(z,yr) .. CC_Sum_zyr(z,yr) =E= CC_DAC_zyr(z,yr) + CC_CCS_zyr(z,yr);                                          // kton
eqCC_Sum_yr(yr) .. CC_Sum_yr(yr) =E= CC_CCS_yr(yr) + CO2_DAC(yr);                                                        // kton
eqCC_Sum_h(z,yr,h) .. CC_Sum_h(z,yr,h) =E= CC_DAC_h(z,yr,h) + CC_CCS_h(z,yr,h);                                          // kton



* ========================== Power consumption ========================== *
* CC/CP/CT
Positive variables P_Cnet(z,yr,h);
Equations eqP_Cnet;

eqP_Cnet(z,yr,h) .. P_Cnet(z,yr,h) =E= P_DAC(z,yr,h);


* ========================== Invesment and operation costs ========================== *
* CC/CP/CT/CS
Positive variables CaPx_Cnet, FCS_Cnet, FOM_Cnet, TSC_Cnet;
Equations eqCaPx_Cnet, eqFCS_Cnet, eqFOM_Cnet, eqTSC_Cnet;

eqCaPx_Cnet .. CaPx_Cnet =E= sum(n$(ord(n) > 1), CaPx_DAC(n));     // k USD

eqFCS_Cnet .. FCS_Cnet   =E= sum(yr, FCS_DAC(yr));                                  // k USD

eqFOM_Cnet .. FOM_Cnet =E= 0.035 * CaPx_Cnet;          // k USD

eqTSC_Cnet .. TSC_Cnet =E= (CaPx_Cnet + FCS_Cnet + FOM_Cnet) / ths;                 // M USD
