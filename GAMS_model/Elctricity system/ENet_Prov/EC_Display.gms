* ================================== Electricity network results ==================================

Parameters U_ET_acm_z(er,z,yr), U_ET_acm_ys(er,yr), 
           U_ELi_acm_ys(m,z,zx,yr), U_ELi_acm_ys_sum(z,zx,yr), 
           P_EG_gen_ys(er,yr), P_EG_gen_sum(yr), 
           D_ES_sum(yr), Elc_Dem(yr), Edem_flag(yr);

U_ET_acm_z(eg,z,yr)  = U_EG_acm.l(eg,z,yr);               // 按城市统计
U_ET_acm_z(ecg,z,yr) = U_EG_acm.l(ecg,z,yr);              // 按城市统计
U_ET_acm_z(es,z,yr)  = U_ES_acm.l(es,z,yr);               // 按城市统计

U_ET_acm_ys(eg,yr) = sum(z, U_EG_acm.l(eg,z,yr));         // 按年份统计, GW    
U_ET_acm_ys(ecg,yr) = sum(z, U_EG_acm.l(ecg,z,yr));       // 按年份统计, GW  
U_ET_acm_ys(es,yr) = sum(z, U_ES_acm.l(es,z,yr));         // 按年份统计, GW 

U_ELi_acm_ys(m,z,zx,yr) = U_ELi_acm.l(m,z,zx,yr);
U_ELi_acm_ys_sum(z,zx,yr) = sum(m, U_ELi_acm_ys(m,z,zx,yr));   // GW

P_EG_gen_ys(eno,yr) = sum((J_ET_r(eno,z,yr), h), nds * P_EG_gen.l(eno,z,yr,h)) / ths;      // TWh
P_EG_gen_ys(evg,yr) = sum((J_RN_r(evg,z,yr), h), nds * P_EG_gen.l(evg,z,yr,h)) / ths;      // TWh

P_EG_gen_ys(ecg,yr) = sum((J_ET_r(ecg,z,yr), h), nds * P_EG_gen.l(ecg,z,yr,h)) / ths;   // TWh

P_EG_gen_sum(yr) = sum(eg, P_EG_gen_ys(eg,yr)) + sum(ecg, P_EG_gen_ys(ecg,yr));         // TWh

D_ES_sum(yr) = sum((J_ET_r(es,z,yr), h), nds * D_ES.l(es,z,yr,h)) / ths;   // TWh

Elc_Dem(yr) = sum((z,h), nds * Edem(z,yr,h)) / ths;              // TWh

Edem_flag(yr) = D_ES_sum(yr) - Elc_Dem(yr);   // Flag for excess electricity, 电力过剩


Parameters U_ET_dnm_ys(er,z,yr), U_ET_dnm_ys_sum(er,yr), U_ET_dnm_sum(yr), 
           U_ET_CCS_ys(er,z,yr), U_ET_CCS_ys_sum(er,yr), U_ET_CCS_sum(yr), 
           U_ET_RO_ys_sum(er,yr), U_ET_RO_sum(yr);

U_ET_dnm_ys(erg,z,yr) = sum(J_ET_u(erg,z,n,yr), U_EG_dnm.l(erg,z,n,yr));
U_ET_dnm_ys_sum(erg,yr) = sum(z, U_ET_dnm_ys(erg,z,yr));
U_ET_dnm_sum(yr) = sum(erg, U_ET_dnm_ys_sum(erg,yr));     // coal, gtcc退役容量统计

U_ET_CCS_ys(erg,z,yr) = sum(J_ET_u(erg,z,n,yr), U_EG_CCS.l(erg,z,n,yr));
U_ET_CCS_ys_sum(erg,yr) = sum(z, U_ET_CCS_ys(erg,z,yr));
U_ET_CCS_sum(yr) = sum(erg, U_ET_CCS_ys_sum(erg,yr));     // coal, gtcc加装CCS容量统计

U_ET_RO_ys_sum(ecg,yr)  = sum(z, U_EG_RO.l(ecg,z,yr));
U_ET_RO_sum(yr) = sum((ecg,z), U_EG_RO.l(ecg,z,yr));      // coal, gtcc改造CCS容量统计

Parameters ECap_EG_CO2(yr), ECap_EG_BECO2(yr), GHG_Enet_M(yr), GHG_M(yr),
           P_ELi_H(z,zx,yr,h), P_Eli_M(z,zx,yr), 
           F_EG_NG_M(yr), F_EG_Coal_M(yr), PS_MC(z,yr,h);

ECap_EG_CO2(yr) = sum((J_ET_r(ccsg,z,yr), h), nds * E_EG_CO2.l(ccsg,z,yr,h)) / ths;     // Million tons
ECap_EG_BECO2(yr) = sum((J_ET_r(ccsgb,z,yr), h), nds * E_EG_CO2.l(ccsgb,z,yr,h)) / ths;     // - Million tons,生物质负碳排放

GHG_Enet_M(yr) = GHG_Enet.l(yr) / ths;   // Million tons
GHG_M(yr) = GHG.l(yr) / ths;             // Million tons

P_ELi_H(z,zx,yr,h) = sum(m, P_Eli.l(m,z,zx,yr,h));   // 按小时统计传输电量, GW

P_Eli_M(z,zx,yr) = sum((m,h), nds * P_Eli.l(m,z,zx,yr,h)) / ths;   // 按年份汇总传输传输电量, TWh

F_EG_NG_M(yr) = sum(z, F_EG_NG.l(z,yr)) / LHV_NG;         // billion m3
F_EG_Coal_M(yr) = sum(z, F_EG_Coal.l(z,yr)) / LHV_CO;     // million ton

PS_MC(z,yr,h) = eqEbalance.m(z,yr,h);   // 对偶变量

Display U_EG_nom.l, U_ES_nom.l, U_ET_acm_z, U_ET_acm_ys;

Display U_ET_dnm_ys, U_ET_dnm_ys_sum, U_ET_dnm_sum, U_ET_CCS_ys, U_ET_CCS_ys_sum, U_ET_CCS_sum, U_ET_RO_sum;

Display U_ELi_nom.l, U_ELi_acm_ys, U_ELi_acm_ys_sum;

Display P_EG_gen_ys, P_EG_gen_sum, D_ES_sum, Elc_Dem, Edem_flag;

Display Edis_Sum.l, ECap_EG_CO2, GHG_Enet_M, P_Eli_M, F_EG_NG_M, F_EG_Coal_M;

Display CaPx_Enet.l, CaPx_RO_Enet.l, FCS_Enet.l, FOM_Enet.l, VOM_Enet.l, Edis_Enet.l, TSC_Enet.l;


* ===================== Cost Analysis 
* Generation and storate technologies
Parameters CaPx_ET_PW(er,n), RO_EG_PW(er,yr), FOM_ET_PW(er,yr), VOM_ET_PW(er,yr), FCS_Nu_PW(yr), FCS_EG_PW(yr);   // 按技术，年份计算 

CaPx_ET_PW(eg,n) = sum(J_ET_s(eg,z,n), dn(n) * ET_afr(eg) * ET_dsm(eg,n) * ET_uCaPx(eg,n) * U_EG_nom.l(eg,z,n));   // M USD

RO_EG_PW('gcics',yr) = sum(J_ET_u('gcics',z,n,yr), 
                    dn(yr) * ET_afr('gcics') * ET_R_dsm('gcics',z,n,yr) * ET_uCaPx('gcics',yr) * U_EG_CCS.l('gtcc',z,n,yr));   // M USD

RO_EG_PW('coics',yr) = sum(J_ET_u('coics',z,n,yr),
                    dn(yr) * ET_afr('coics') * ET_R_dsm('coics',z,n,yr) * ET_uCaPx('coics',yr) * U_EG_CCS.l('coal',z,n,yr));   // M USD

FCS_Nu_PW(yr) = sum((cnu(z)), dn(yr) * (c_Nu * F_EG_Nu.l(z,yr)));    

FCS_EG_PW(yr) = sum(z, dn(yr) * (c_NG * F_EG_NG.l(z,yr))) +          
                sum(z, dn(yr) * (c_CO * F_EG_Coal.l(z,yr))); 

FOM_ET_PW(fmeg,yr) = sum(J_ET_r(fmeg,z,yr), dn(yr) * ET_FOM(fmeg,'%scn%',yr) * U_EG_acm.l(fmeg,z,yr));    
VOM_ET_PW(fmeg,yr) = sum((J_ET_r(fmeg,z,yr),h), nds * dn(yr) * ET_VOM(fmeg,'%scn%',yr) * P_EG_gen.l(fmeg,z,yr,h));

CaPx_ET_PW(es,n) = sum(J_ET_s(es,z,n), dn(n) * ET_afr(es) * ET_dsm(es,n) * ET_uCaPx(es,n) * U_ES_nom.l(es,z,n));
FOM_ET_PW(es,yr)  = sum(J_ET_r(es,z,yr), dn(yr) * ET_FOM(es,'%scn%',yr) * U_ES_acm.l(es,z,yr));
VOM_ET_PW(es,yr)  = sum((J_ET_r(es,z,yr),h), nds * dn(yr) * ET_VOM(es,'%scn%',yr) * (C_ES.l(es,z,yr,h) + D_ES.l(es,z,yr,h)));

* Transmission technologies
Parameters CaPx_ELi_PW(ni), FOM_ELi_PW(yr), VOM_ELi_PW(yr);

CaPx_ELi_PW(ni) = sum(imz(m,z,zx),
                   dn(ni) * ldn(ni) * ELi_afr(m) * ELi_dsm(m,ni) * ELi_CaPx(m) * ETNS_dstn(z,zx) * U_ELi_nom.l(m,z,zx,ni));

FOM_ELi_PW(yr) = sum(J_ET_v(m,z,zx,yr), dn(yr) * ldn(yr) * ELi_FOM(m) * ETNS_dstn(z,zx) * U_ELi_acm.l(m,z,zx,yr)); 

VOM_ELi_PW(yr) = sum((J_ET_v(m,z,zx,yr), h), nds * dn(yr) * ELi_VOM(m) * (P_Eli.l(m,z,zx,yr,h) + P_Eli.l(m,zx,z,yr,h)));


* ================================== Carbon network results ==================================
$ifThen "%mflag%" == "2"

* CC results
Parameters U_DAC_nom_czy(ccdg,z,n), U_DAC_acm_czy(ccdg,z,yr), U_DAC_acm_zyr(z,yr), U_DAC_acm_ys(ccdg,yr), U_DAC_acm_ys_sum(yr);
Parameters CO2_DAC_M(yr), CO2_CCS_M(yr), CO2_TT_M(yr);

U_DAC_nom_czy(ccdg,z,n) = U_DAC_nom.l(ccdg,z,n);
U_DAC_acm_czy(ccdg,z,yr) = U_DAC_acm.l(ccdg,z,yr);
U_DAC_acm_zyr(z,yr) = sum(ccdg, U_DAC_acm.l(ccdg,z,yr));
U_DAC_acm_ys(ccdg,yr) = sum(z, U_DAC_acm.l(ccdg,z,yr));    // ton/hr
U_DAC_acm_ys_sum(yr) = sum(ccdg, U_DAC_acm_ys(ccdg,yr));   // ton/hr

CO2_DAC_M(yr) = CO2_DAC.l(yr);     // k tons
CO2_CCS_M(yr) = CC_CCS_yr.l(yr);   // k tons
CO2_TT_M(yr) = CC_Sum_yr.l(yr);    // k tons

Display U_DAC_nom.l, U_DAC_acm_ys, U_DAC_acm_ys_sum, CO2_DAC_M, CO2_CCS_M, CO2_TT_M;

* ===================== Cost Analysis 
Display CaPx_Cnet.l, FCS_Cnet.l, FOM_Cnet.l, TSC_Cnet.l;

