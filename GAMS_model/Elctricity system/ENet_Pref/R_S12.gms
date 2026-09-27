$Title China Electricity-Carbon System Optimization: Stage2_Pref modling for ENet

$eolCom //

// 场景设置参考 Zhuo et al. (Cost increase)

$Set Dfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Data
$Set Cfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Code/Stage2_Pref 
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



* Set definition
* =========================================================================== *
* ar: total number of optimization years
* rs: number of hours in a year (288h -> 12TD) (96h -> 4TD)
$Set ar  26   //26
$Set rs  96   //288

* hrs: number of hours in a day (for truck trans)
$Set  hrs  24
$Eval tds  %rs% / %hrs%

* sr, mr: decision years for generation and transmission technologies
$Set sr  y1, y6, y11, y16, y21, y26
$Set mr  y1, y6, y11, y16, y21


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

Sets eg(er)  elec. generation        / pv, nwd, fwd,
                                       nu, bio, beccs, hydo,
                                       gtcc, gccs, coal, cocs /   // Newly built generation
     epv(eg) elec. prov              / fwd, nu, bio, beccs, hydo/
     epf(er) elec. pref              / pv, nwd,
                                       gtcc, gcics, gccs,
                                       coal, coics, cocs /        // pref tech.
     es(er)  elec. storage           / phs, lib4 /                // Newly built storage
     epw(er)                         / pv, nwd   /                // pref pv and onshore wind 
     cngg(er)                        / gtcc, gcics, gccs, coal, coics, cocs /  // all pref coal and gas
     ecng(cngg)                      / gtcc, gccs, coal, cocs /
     egg(ecng)                       / gccs, cocs /               // Install with CCS
     ecg(cngg) tech. with CCS        / gcics, coics /             // Retrofit with CCS
     erg(ecng)                       / gtcc, coal /;              // Deconmission and retrofit with CCS

Sets c    tech. scenarios            / high, mid, low /           // Technology cost scenarios
     ces   clean energy scens        / bau, ndc, endc, cn50 /     // Four decarbonization scenarios 
     esp  tech. specification        / eta, ro, mu, lm, cfn, cfm, epn, ltm /
     m    inter-transmission lines   / ac, dc /
     cxs  carbon tax scenarios       / cmid, cadv /;              // Carbon tax scenarios
     
Sets cgmg(ecng)   / gtcc, coal /                              // Emission with no CCS
     ncsg(er)     / nu, bio /                     // Generation with no CCS, eta, prov
     ncsgh(er)    / nu, bio, hydo /               // Generation with no CCS, prov
     ncsgall(er)  / nu, bio, hydo, coal, gtcc /   // All generation with no CCS
     ccsg(er)     / gcics, gccs, coics, cocs, beccs /         // Generation with CCS
     ccsga(cngg)  / gcics, gccs, coics, cocs /
     ccsgb(er)    / beccs /
     ngfg(cngg)   / gtcc, gcics, gccs /                     // NG consumpton
     cofg(cngg)   / coal, coics, cocs /                     // coal consumption
     ngcc(ccsga)  / gcics, gccs /                           // NG CCS
     cocc(ccsga)  / coics, cocs /                           // CO CCS
     avbg(er)     / nu, bio, hydo, gtcc, gcics, gccs, coal, coics, cocs /     // availabiliy -- lm
     clng(er)     / nu, bio, beccs, hydo /                                    // Capacity factor: clean generation with min/max generation -- cfn/cfm
*    cngg(er)     / gtcc, gcics, gccs, coal, coics, cocs /                    // Capacity factor: coal and natural gas with max generation -- cfm
     ccgg(er)     / gtcc, gcics, gccs, coal, coics, cocs, beccs /             // co2 emission caculation
     rmpg(er)     / nu, bio, hydo /                                           // Technology ramping
     watg(er)     / coal, coics, cocs, gtcc, gcics, gccs, nu, bio, beccs /    // power generation cosuming water
     fmeg(er)     / nu, bio, beccs, hydo, gtcc, gcics, gccs, coal, coics, cocs /
     fmega(fmeg)  / nu, bio, beccs, hydo/
     fmegb(fmeg)  / gtcc, gcics, gccs, coal, coics, cocs /;                   // Firm generation: resreve

Parameters tau_es(es)  discharge duration hr        / phs 8, lib4 4 /
           lntm        transmission line lifetime   / 40   /
           ndys        num. of days in a year       / 365  /
           nhys        num. of hours in a year      / 8760 /;

Scalars ths   thousand     / 1.0e+3 /
        mms   million      / 1.0e+6 /
        yys   0.1 billion  / 1.0e+8 /
        nds   typical das;                                         

nds = nhys / %rs%;         // number of typical days in a year

Display er, yr, n, ni, yx;

* ============================== = Input Data ================================ *
$include %Cfolder%/E_Network_Data.gms
$include %Cfolder%/E_Network_Data_Pref.gms


** ================================== Read Stage_1_Prov results ========================================= **
* Power Generation
Positive Variables U_EG_nom(er,z,n), U_PW_nom(epw,pz,pj,n);
Positive variables U_EG_anom(eg,z,n,yr), U_EG_dnm(eg,z,n,yr);
Positive variables U_PW_anom(epw,pz,pj,n,yr);
Positive variables U_EG_acm(er,z,yr), U_PW_acm(epw,pz,pj,yr);
Positive variables P_EG_gen(er,z,yr,h), F_EG_fcs(er,z,yr,h), EM_EG_CO2(er,z,yr,h);
Positive variables P_EG_gen_ncs(er,z,yr,h), E_EG_CO2(er,z,yr,h);
Positive Variables P_PW_gen(epw,pz,pj,yr,h);
Positive variables R_EG_frm(er,z,yr,h);
Positive variables F_EG_Nu(z,yr), F_EG_NG(z,yr), F_EG_Coal(z,yr);

* Power Storage
Positive variables U_ES_nom(es,z,n);
Positive variables U_ES_anom(es,z,n,yr), U_ES_dnm(es,z,n,yr);
Positive variables U_ES_acm(es,z,yr), U_lib_acm_ys(es,yr);
Positive variables En_ES(es,z,yr,t), C_ES(es,z,yr,h), D_ES(es,z,yr,h);
Positive variables R_ES_frm(es,z,yr,h);
Positive variables CaPx_ES(n), FOM_ES(yr), VOM_ES(yr);

* Power Transmission
Positive variables U_ELi_nom(m,z,zx,ni);
Positive variables U_ELi_anom(m,z,zx,ni,yr), U_ELi_dnm(m,z,zx,ni,yr);
Positive variables U_ELi_acm(m,z,zx,yr);
Positive variables P_Eli(m,z,zx,yr,h);
Positive variables CaPx_ELi(ni), FOM_ELi(yr), VOM_ELi(yr);

* E_Network
Positive variables Edem_dis(z,yr,h), Edis_Sum(z,yr);
Positive variables GHG_Enet(yr), GHG(yr);


Parameters
    Fix_UEGnom_epv(epv,z,n)
    Fix_UPWnom(epw,pz,pj,n)
    Fix_UEGnom_cngg(cngg,z,n)
    Fix_UEGacm_cngg(cngg,z,yr)
    Fix_UEGacm_coal(cngg,z,yr)
    Fix_UEGacm_gtcc(cngg,z,yr)
    Fix_UESnom(es,z,n)
    Fix_UELinom(m,z,zx,ni);

Execute_load "%Rfolder%/Stage_1_Prov.gdx", U_EG_nom, U_PW_nom, U_EG_acm, U_ES_nom, U_ELi_nom;

Fix_UEGnom_epv(epv,z,n)     = U_EG_nom.l(epv,z,n);
Fix_UEGnom_epv(epv,z,n)$(Fix_UEGnom_epv(epv,z,n) < 1e-3) = 0;

Fix_UPWnom(epw,pz,pj,n)     = U_PW_nom.l(epw,pz,pj,n);
Fix_UPWnom(epw,pz,pj,n)$(Fix_UPWnom(epw,pz,pj,n) < 1e-3) = 0;

Fix_UEGnom_cngg(cngg,z,n)   = U_EG_nom.l(cngg,z,n);
Fix_UEGnom_cngg(cngg,z,n)$(Fix_UEGnom_cngg(cngg,z,n) < 1e-3) = 0;

Fix_UEGacm_cngg(cngg,z,yr)  = U_EG_acm.l(cngg,z,yr);
Fix_UEGacm_cngg(cngg,z,yr)$(Fix_UEGacm_cngg(cngg,z,yr) < 1e-3) = 0;

Fix_UEGacm_coal('coal',z,yr) = U_EG_acm.l('coal',z,yr);
Fix_UEGacm_gtcc('gtcc',z,yr) = U_EG_acm.l('gtcc',z,yr);
Fix_UEGacm_coal('coal',z,yr)$(Fix_UEGacm_coal('coal',z,yr) < 1e-3) = 0;
Fix_UEGacm_gtcc('gtcc',z,yr)$(Fix_UEGacm_gtcc('gtcc',z,yr) < 1e-3) = 0;

Fix_UESnom(es,z,n)          = U_ES_nom.l(es,z,n);
Fix_UESnom(es,z,n)$(Fix_UESnom(es,z,n) < 1e-3) = 0;

Fix_UELinom(m,z,zx,ni)      = U_ELi_nom.l(m,z,zx,ni);
Fix_UELinom(m,z,zx,ni)$(Fix_UELinom(m,z,zx,ni) < 1e-3) = 0;

Execute_unload "%Rfolder%/Stage_1_fix.gdx",
    Fix_UEGnom_epv,
    Fix_UPWnom,
    Fix_UEGnom_cngg,
    Fix_UEGacm_cngg,
    Fix_UEGacm_coal,
    Fix_UEGacm_gtcc,
    Fix_UESnom,
    Fix_UELinom;
