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

Sets  ccdg   carbon capture: dac     / kclg, kbpd, sdbn, molg /;

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

* ================================ E_Network Modeling================================ *
* E_Network parameters
$include %Cfolder%/E_Network_Param.gms

*Techno-economic parameters
Scalars ir      interest rates          / 0.05 /
        cfa     accountable factor      / 0.5  /;

Parameters dn(y);      // Discount rates in year y

dn(yr) = 1 / ((1 + ir) ** (ord(yr) - 1));      // 0.28 ~ 1.0

* Screening useful operation years for power and storage technologies
Sets fwz(z)                 offshore wind cities      / FJ, GD, GX, HE, HI, JS, LN, SD, SH, TJ, ZJ /
     cnu(z)                 nuclear cities            / BJ, FJ, GD, GS, GX, HI, JS, LN, SD, ZJ /
     xcphs(z)               no pumped storage cities  / SH, TJ /
     xcoal(z)               no coal gen cities        / BJ, XZ /
     xccgt(z)               no ccgt gen cities        / GZ, QH, YN /
     xhydo(z)               no hydo cities            / SH /;

Sets
     J_ET_s(er,z,n)         installation year of power technologies
     J_ET_u(er,z,n,yr)      useful operation years for technology installed in z and n
     J_ET_r(er,z,yr)        technology available in zone z year yr;
     
Sets
     J_PW_s(epw,pz,pj,n)
     J_PW_u(epw,pz,pj,n,yr)
     J_PW_r(epw,pz,pj,yr);
     
Sets
     J_CG_s(cngg,pz,pj,n)
     J_CG_u(cngg,pz,pj,n,yr)
     J_CG_r(cngg,pz,pj,yr)  
     J_CG_c(ecg,pz,pj,n,yr)     technology existed or installed in year n retrofitted in year yr
     J_CG_uo(ecg,pz,pj,n,yr,yn) useful operation years for technology installed in year n retrofit in year yr;     

       
* 过滤拥有对应发电技术的城市
Sets cpv(pz,pj)     Solar PV generation in city pj province pz
     cwt(pz,pj)     Onshore wind generation in city pj province pz
     cco(pz,pj)     Coal generation in city pj province pz
     cng(pz,pj)     Gas generation in city pj province pz
     cfu(pz,pj)     Coal and gas generation in city pj province pz
     cpf(pz,pj)     Province and pref match;

cpv(pz,pj)$(PV_Cap(pz,pj)) = yes;                            
cwt(pz,pj)$(WT_Cap(pz,pj)) = yes;
cco(pz,pj)$(coal_Excap(pz,pj)) = yes;                            
cng(pz,pj)$(gtcc_Excap(pz,pj)) = yes;
cfu(pz,pj)$(cco(pz,pj) or cng(pz,pj)) = yes;
cpf(pz,pj)$(pref_mt(pz,pj)) = yes;

display cpv, cwt, cco, cng, cpf, cfu;

Parameters U_PW_exn(epw,pz,pj), U_CG_exn(cngg,pz,pj);
U_PW_exn('pv',pz,pj)$cpv(pz,pj) = PV_Excap(pz,pj);
U_PW_exn('nwd',pz,pj)$cwt(pz,pj) = WT_Excap(pz,pj);
U_CG_exn(ccsga,pz,pj) = 0;
U_CG_exn('coal',pz,pj) = coal_Excap(pz,pj);
U_CG_exn('gtcc',pz,pj) = gtcc_Excap(pz,pj);

display U_PW_exn, U_CG_exn;


* Useful operation years for existing technologies
J_ET_u(er,z,'y0',yr)$(U_ET_exn(er,z) and (ord(yr) <= ET_Specs(er,'ltm'))) = yes;   // No gcics or coics

J_PW_u('pv',pz,pj,'y0',yr)$(cpv(pz,pj) and U_PW_exn('pv',pz,pj) and (ord(yr) <= ET_Specs('pv','ltm'))) = yes;
J_PW_u('nwd',pz,pj,'y0',yr)$(cwt(pz,pj) and U_PW_exn('nwd',pz,pj) and (ord(yr) <= ET_Specs('nwd','ltm'))) = yes;

J_CG_u(cofg,pz,pj,'y0',yr)$(cco(pz,pj) and U_CG_exn(cofg,pz,pj) and (ord(yr) <= ET_Specs(cofg,'ltm'))) = yes;
J_CG_u(ngfg,pz,pj,'y0',yr)$(cng(pz,pj) and U_CG_exn(ngfg,pz,pj) and (ord(yr) <= ET_Specs(ngfg,'ltm'))) = yes;

* Useful operation years for newly installed technologies
J_ET_u(er,z,n(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs(er,'ltm') - 1), card(yr)))) = yes;

J_PW_u('pv',pz,pj,n(y),yr)$(cpv(pz,pj) and (ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs('pv','ltm') - 1), card(yr)))) = yes;
J_PW_u('nwd',pz,pj,n(y),yr)$(cwt(pz,pj) and (ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs('nwd','ltm') - 1), card(yr)))) = yes;

J_CG_u(cofg,pz,pj,n(y),yr)$(cco(pz,pj) and (ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs(cofg,'ltm') - 1), card(yr)))) = yes;
J_CG_u(ngfg,pz,pj,n(y),yr)$(cng(pz,pj) and (ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs(ngfg,'ltm') - 1), card(yr)))) = yes;

* Filter operation years for power and storage technologies unavailable in zones
J_ET_u('nu',z,n,yr)$((ord(n) > 1)   and (NOT cnu(z))) = no;
J_ET_u('fwd',z,n,yr)$((ord(n) > 1)  and (NOT fwz(z))) = no;
J_ET_u('phs',z,n,yr)$((ord(n) > 1)  and xcphs(z)) = no;
J_ET_u('hydo',z,n,yr)$(ord(n) > 1) = no;

J_CG_u(cofg,pz,pj,n,yr)$((ord(n) > 1) and (NOT cco(pz,pj))) = no;
J_CG_u(ngfg,pz,pj,n,yr)$((ord(n) > 1) and (NOT cng(pz,pj))) = no;
J_CG_u(ecg,pz,pj,n,yr)$(ord(n) > 1) = no;       // No gcics and coics installation: only be retrofitted from gas and coal generation

J_CG_c('gcics',pz,pj,'y0',yr)$((ord(yr) > 1) and J_CG_u('gtcc',pz,pj,'y0',yr)) = yes;                       // Retrofit of existing gas and coal generation
J_CG_c('coics',pz,pj,'y0',yr)$((ord(yr) > 1) and J_CG_u('coal',pz,pj,'y0',yr)) = yes;
J_CG_c('gcics',pz,pj,n(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)) and J_CG_u('gtcc',pz,pj,n,yr)) = yes;   // Retrofit of newly built gas and coal generation
J_CG_c('coics',pz,pj,n(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)) and J_CG_u('coal',pz,pj,n,yr)) = yes;

* Power generation and storage technologies: installation years
Loop(J_ET_u(er,z,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), J_ET_s(er,z,n) = yes);   // Index year for tech. installation when n > 0: No gcics and coics
Loop(J_PW_u(epw,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), J_PW_s(epw,pz,pj,n) = yes);
Loop(J_CG_u(cngg,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), J_CG_s(cngg,pz,pj,n) = yes);

* J_ET_u: for eg + es: operation years; for ecg:  retrofit years
* J_ET_u的不同含义：对于eg+es，J_ET_u指的是第n年安装的技术的运行年份；对于ecg，J_ET_u指的是第n年安装的技术进行改造的年份
J_CG_u(ecg,pz,pj,'y0',yr)$(J_CG_c(ecg,pz,pj,'y0',yr)) = yes;
J_CG_u(ecg,pz,pj,n,yr)$((ord(n) > 1) and J_CG_c(ecg,pz,pj,n,yr)) = yes;      // Retrofit years of gas and coal generation

* Power generation and storage technologies available in year yr
J_ET_r(er,z,yr)$(sum(J_ET_u(er,z,n(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;
J_PW_r(epw,pz,pj,yr)$(sum(J_PW_u(epw,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;
J_CG_r(cngg,pz,pj,yr)$(sum(J_CG_u(cngg,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;

Display J_ET_s, J_ET_u, J_ET_r;
Display J_PW_s, J_PW_u, J_PW_r;
Display J_CG_s, J_CG_u, J_CG_r, J_CG_c;


** ================================== Read Stage_1_Prov results ========================================= **
* Power Generation
Positive Variables U_CG_nom(ecng,pz,pj,n), U_CG_dnm(erg,pz,pj,n,yr), U_CG_CCS(erg,pz,pj,n,yr),
                   U_CG_RO(ecg,pz,pj,yr),  U_CG_acm(cngg,pz,pj,yr), CC_CCS_h(pz,pj,yr,h), CC_DAC_h(z,yr,h),
                   U_DAC_nom(ccdg,z,n), U_DAC_acm(ccdg,z,yr);

Parameters
    U_CG_acm_ys(cngg,yr)
    U_CG_acm_z(cngg,z,yr);

Execute_load "%Rfolder%/Stage_2_Pref.gdx", U_CG_nom, U_CG_dnm, U_CG_acm, U_CG_CCS, U_CG_RO, CC_CCS_h, CC_DAC_h, U_DAC_nom, U_DAC_acm;

U_CG_acm_z('coal',z,yr) = sum(pj$cco(z,pj), U_CG_acm.l('coal',z,pj,yr));
U_CG_acm_z('cocs',z,yr) = sum(pj$cco(z,pj), U_CG_acm.l('cocs',z,pj,yr));
U_CG_acm_z('coics',z,yr) = sum(pj$cco(z,pj), U_CG_acm.l('coics',z,pj,yr));

U_CG_acm_z('gtcc',z,yr) = sum(pj$cng(z,pj), U_CG_acm.l('gtcc',z,pj,yr));
U_CG_acm_z('gccs',z,yr) = sum(pj$cng(z,pj), U_CG_acm.l('gccs',z,pj,yr));

U_CG_acm_ys(ecng,yr) = sum(z, U_CG_acm_z(ecng,z,yr));
U_CG_acm_ys('coics',yr) = sum(z, U_CG_acm_z('coics',z,yr));


Parameters
    U_CG_dnm_ys(erg,z,yr)
    U_CG_dnm_ys_sum(erg,yr)
    
    U_CG_CCS_ys(erg,z,yr)
    U_CG_CCS_ys_sum(erg,yr)
    
    U_CG_RO_ys_sum(ecg,yr);
    
U_CG_dnm_ys('coal',z,yr) = sum(pj$cco(z,pj), sum(J_CG_u('coal',z,pj,n,yr), U_CG_dnm.l('coal',z,pj,n,yr)));
U_CG_dnm_ys('gtcc',z,yr) = sum(pj$cng(z,pj), sum(J_CG_u('gtcc',z,pj,n,yr), U_CG_dnm.l('gtcc',z,pj,n,yr)));
U_CG_dnm_ys_sum(erg,yr) = sum(z, U_CG_dnm_ys(erg,z,yr));

U_CG_CCS_ys('coal',z,yr) = sum(pj$cco(z,pj), sum(J_CG_u('coal',z,pj,n,yr), U_CG_CCS.l('coal',z,pj,n,yr)));
U_CG_CCS_ys('gtcc',z,yr) = sum(pj$cng(z,pj), sum(J_CG_u('gtcc',z,pj,n,yr), U_CG_CCS.l('gtcc',z,pj,n,yr)));
U_CG_CCS_ys_sum(erg,yr) = sum(z, U_CG_CCS_ys(erg,z,yr));

U_CG_RO_ys_sum('coics',yr) = sum((z,pj)$cco(z,pj), U_CG_RO.l('coics',z,pj,yr));
U_CG_RO_ys_sum('gcics',yr) = sum((z,pj)$cco(z,pj), U_CG_RO.l('gcics',z,pj,yr));


Parameters CO2_CCS(z,pj,yr,h), CO2_DAC(z,yr,h);
Parameters U_DAC_nom_czy(ccdg,z,n), U_DAC_acm_czy(ccdg,z,yr), U_DAC_acm_zyr(z,yr), U_DAC_acm_ys(ccdg,yr), U_DAC_acm_ys_sum(yr);

CO2_CCS(z,pj,yr,h)$(cpf(z,pj)) = CC_CCS_h.l(z,pj,yr,h);

CO2_DAC(z,yr,h) = CC_DAC_h.l(z,yr,h);
U_DAC_nom_czy(ccdg,z,n) = U_DAC_nom.l(ccdg,z,n);
U_DAC_acm_czy(ccdg,z,yr) = U_DAC_acm.l(ccdg,z,yr);
U_DAC_acm_zyr(z,yr) = sum(ccdg, U_DAC_acm.l(ccdg,z,yr));
U_DAC_acm_ys(ccdg,yr) = sum(z, U_DAC_acm.l(ccdg,z,yr));    // ton/hr
U_DAC_acm_ys_sum(yr) = sum(ccdg, U_DAC_acm_ys(ccdg,yr));   // ton/hr

Execute_unload "%Rfolder%/Stage_2_fix.gdx",
    U_CG_acm_ys,
    U_CG_acm_z,
    U_CG_dnm_ys,
    U_CG_dnm_ys_sum,
    U_CG_CCS_ys,
    U_CG_CCS_ys_sum,
    U_CG_RO_ys_sum,
    CO2_CCS,
    CO2_DAC,
    U_DAC_nom_czy, U_DAC_acm_czy, U_DAC_acm_zyr, U_DAC_acm_ys, U_DAC_acm_ys_sum;
