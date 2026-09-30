$Title China Electricity-Carbon System Optimization: Stage2_Pref modling for ENet

$eolCom //

// 场景设置参考 Zhuo et al. (Cost increase)

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
Positive variables GHG_Enet(yr);
variables GHG(yr);

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


* The first year and final years: electricity and storage technologies
Parameters yen(er,z,n), yeo(er,z,n), yem(er,z,n);
yen(er,z,'y0')$(J_ET_u(er,z,'y0','y1')) = 1;                                                 // No gcics and coics
Loop(J_ET_u(er,z,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), yen(er,z,n) = ord(yr));   // The first operation year
yeo(er,z,n)$(yen(er,z,n)) = sum(yr$(J_ET_u(er,z,n,yr)), 1);                                  // The operation period
yem(er,z,n)$(yen(er,z,n)) = yeo(er,z,n) + yen(er,z,n) - 1;                                   // The last operation year

Display yen, yeo, yem;

Parameters ycgn(cngg,pz,pj,n), ycgo(cngg,pz,pj,n), ycgm(cngg,pz,pj,n);
ycgn(cngg,pz,pj,'y0')$(J_CG_u(cngg,pz,pj,'y0','y1')) = 1;
Loop(J_CG_u(cngg,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ycgn(cngg,pz,pj,n) = ord(yr));   // The first operation year
ycgo(cngg,pz,pj,n)$(ycgn(cngg,pz,pj,n)) = sum(yr$(J_CG_u(cngg,pz,pj,n,yr)), 1);                                  // The operation period
ycgm(cngg,pz,pj,n)$(ycgn(cngg,pz,pj,n)) = ycgo(cngg,pz,pj,n) + ycgn(cngg,pz,pj,n) - 1;

ycgn('gcics',pz,pj,'y0')$(J_CG_u('gtcc',pz,pj,'y0','y1')) = 2;                                        // The first retrofit year: gcics and coics
ycgn('coics',pz,pj,'y0')$(J_CG_u('coal',pz,pj,'y0','y1')) = 2;
Loop(J_CG_u(ecg,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y) = ord(yr))), ycgn(ecg,pz,pj,n) = ord(yr));   // The first retrofit year: gcics and coics
ycgo(ecg,pz,pj,n)$(ycgn(ecg,pz,pj,n)) = sum(yr$(J_CG_u(ecg,pz,pj,n,yr)), 1);                               // The operation period from the first retrofit:   gcics and coics
ycgm(ecg,pz,pj,n)$(ycgn(ecg,pz,pj,n)) = ycgo(ecg,pz,pj,n) + ycgn(ecg,pz,pj,n) - 1;                               // The last operation year for the first retrofit: gcics and coics

Display ycgn, ycgo, ycgm;

* The first year and final years: Prefx Solar and Onshore wind
Parameters ypwn(epw,pz,pj,n), ypwo(epw,pz,pj,n), ypwm(epw,pz,pj,n);
ypwn(epw,pz,pj,'y0')$(J_PW_u(epw,pz,pj,'y0','y1')) = 1;
Loop(J_PW_u(epw,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ypwn(epw,pz,pj,n) = ord(yr));   // The first operation year
ypwo(epw,pz,pj,n)$(ypwn(epw,pz,pj,n)) = sum(yr$(J_PW_u(epw,pz,pj,n,yr)), 1);                                  // The operation period
ypwm(epw,pz,pj,n)$(ypwn(epw,pz,pj,n)) = ypwo(epw,pz,pj,n) + ypwn(epw,pz,pj,n) - 1;

Display ypwn, ypwo, ypwm;

* Operation years for gas and coal generation installed in year n retrofitted in year yr
J_CG_uo(ecg,pz,pj,n,yr,yn)$(J_CG_u(ecg,pz,pj,n,yr) and (ord(yn) >= ord(yr)) and (ord(yn) <= ycgm(ecg,pz,pj,n))) =yes;

Display J_CG_uo; 

* Discounted share of lifetime for electricity technologies
Parameters ET_afr(er), ET_dsm(er,n), ET_TM(er,n), ycgrm(ecg,pz,pj,n,yr), CG_R_dsm(ecg,pz,pj,n,yr), CG_R_dsm_TM(ecg,pz,pj,n,yr);

ET_afr(er) = (1 - 1 / (1 + ir)) / (1 - 1 / ((1 + ir) ** ET_Specs(er,'ltm')));   // Annualized factor for technologies, 年化因子, 把投资平摊到每年

ET_dsm(eg,n(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, ET_Specs(eg,'ltm'))))) / (1 - 1 / (1 + ir));  //贴现寿命份额权重，实际运行年份比例
ET_dsm(es,n(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, ET_Specs(es,'ltm'))))) / (1 - 1 / (1 + ir));

ET_TM(eg,n) = ET_afr(eg) * ET_dsm(eg,n);
ET_TM(es,n) = ET_afr(es) * ET_dsm(es,n);

* Operation years for retrofitted technologies
ycgrm(ecg,pz,pj,n,yr)$(J_CG_u(ecg,pz,pj,n,yr)) = sum(yn$J_CG_uo(ecg,pz,pj,n,yr,yn), 1);

* Discounted share of lifetime for retrofitted technologies
CG_R_dsm(ecg,pz,pj,n,yr)$(J_CG_u(ecg,pz,pj,n,yr)) = (1 - 1 / ((1 + ir) ** ycgrm(ecg,pz,pj,n,yr))) / (1 - 1 / (1 + ir));
CG_R_dsm_TM(ecg,pz,pj,n,yr) = ET_afr(ecg) * CG_R_dsm(ecg,pz,pj,n,yr);

Display ET_afr, ET_dsm, ET_TM, ycgrm, CG_R_dsm, CG_R_dsm_TM;


* ========= Capacity sizing: Power generation technologies
* Positive variables U_EG_nom(er,z,n), U_PW_nom(epw,pz,pj,n), U_CG_nom(ecng,pz,pj,n);
Positive variables U_CG_nom(ecng,pz,pj,n);

* Equations eqFix_CG_nom_gtcc, eqFix_CG_nom_coal;

U_CG_nom.fx('gccs',pz,pj,n) = 0;
U_CG_nom.fx('cocs',pz,pj,n) = 0;   
* eqFix_CG_nom_gtcc(z,n)$(ord(n) > 1) .. sum(pj$cng(z,pj), U_CG_nom('gtcc',z,pj,n)) =E= Fix_UEGnom_cngg('gtcc',z,n);   
* eqFix_CG_nom_coal(z,n)$(ord(n) > 1) .. sum(pj$cco(z,pj), U_CG_nom('coal',z,pj,n)) =E= Fix_UEGnom_cngg('coal',z,n);
   
Equations eqU_EG_nom, eqU_EG_bLim;
eqU_EG_nom(J_ET_s(epv,z,n)) .. U_EG_nom(epv,z,n) =L= U_EG_Max(epv,z);                           // GW, 1.0 ~ 1.0
eqU_EG_bLim(epv,n)$(ord(n) > 1) .. sum(J_ET_s(epv,z,n), U_EG_nom(epv,z,n)) =L= U_EG_bLim(epv) * invSpan(n);   // GW, 1.0 ~ 1.0

Equations eqU_PW_noma, eqU_PW_nomb;
eqU_PW_noma(J_PW_s('pv',pz,pj,n)) .. U_PW_nom('pv',pz,pj,n) =L= PV_Cap(pz,pj);    // GW
eqU_PW_nomb(J_PW_s('nwd',pz,pj,n)) .. U_PW_nom('nwd',pz,pj,n) =L= WT_Cap(pz,pj);    // GW

Equations eqU_CG_nom, eqU_CG_bLim;                                                            
eqU_CG_nom(J_CG_s(ecng,pz,pj,n)) .. U_CG_nom(ecng,pz,pj,n) =L= U_CG_Max(ecng,pz,pj);                         
eqU_CG_bLim(ecng,n)$(ord(n) > 1) .. sum(J_CG_s(ecng,pz,pj,n), U_CG_nom(ecng,pz,pj,n)) =L= U_CG_bLim(ecng) * invSpan(n);

* Power capacity continuation
Sets evg(eg)   / pv, nwd, fwd /                       // Constraints on RE caps
     epg(eg)   / pv, nwd, fwd, bio, nu /              // Clean energy potential limition
     edg(eg)   / fwd, nu, bio, beccs, hydo/;          // Deconmission and retrofit with CCS

Sets J_RN_r(evg,z,yr), J_NCSG_r(ncsgall,z,yr), J_CCSG_r(ccsg,z,yr);
Sets J_NGFG_r(ngfg,z,yr), J_COFG_r(cofg,z,yr), J_FMEG_r(fmeg,z,yr);
Sets J_COEM_r(ccgg,z,yr), J_CNGG_r(cngg,z,yr);

J_RN_r('fwd',z,yr) = J_ET_r('fwd',z,yr);
J_RN_r('pv',z,yr)$(sum(J_PW_r('pv',z,pj,yr), 1) >= 1) = yes;
J_RN_r('nwd',z,yr)$(sum(J_PW_r('nwd',z,pj,yr), 1) >= 1) = yes;

J_NCSG_r('nu',z,yr) = J_ET_r('nu',z,yr);
J_NCSG_r('bio',z,yr) = J_ET_r('bio',z,yr);
J_NCSG_r('hydo',z,yr) = J_ET_r('hydo',z,yr);
J_NCSG_r('coal',z,yr)$(sum(J_CG_r('coal',z,pj,yr), 1) >= 1) = YES;
J_NCSG_r('gtcc',z,yr)$(sum(J_CG_r('gtcc',z,pj,yr), 1) >= 1) = YES;

J_CCSG_r('beccs',z,yr) = J_ET_r('beccs',z,yr);
J_CCSG_r('cocs',z,yr)$(sum(J_CG_r('cocs',z,pj,yr), 1) >= 1) = YES;
J_CCSG_r('coics',z,yr)$(sum(J_CG_r('coics',z,pj,yr), 1) >= 1) = YES;
J_CCSG_r('gccs',z,yr)$(sum(J_CG_r('gccs',z,pj,yr), 1) >= 1) = YES;
J_CCSG_r('gcics',z,yr)$(sum(J_CG_r('gcics',z,pj,yr), 1) >= 1) = YES;

J_NGFG_r(ngfg,z,yr)$(sum(J_CG_r(ngfg,z,pj,yr), 1) >= 1) = YES;
J_COFG_r(cofg,z,yr)$(sum(J_CG_r(cofg,z,pj,yr), 1) >= 1) = YES;
J_CNGG_r(cngg,z,yr)$(sum(J_CG_r(cngg,z,pj,yr), 1) >= 1) = YES;

J_FMEG_r(fmega,z,yr) = J_ET_r(fmega,z,yr);
J_FMEG_r('coal',z,yr)$(sum(J_CG_r('coal',z,pj,yr), 1) >= 1) = YES;
J_FMEG_r('gtcc',z,yr)$(sum(J_CG_r('gtcc',z,pj,yr), 1) >= 1) = YES;
J_FMEG_r('cocs',z,yr)$(sum(J_CG_r('cocs',z,pj,yr), 1) >= 1) = YES;
J_FMEG_r('coics',z,yr)$(sum(J_CG_r('coics',z,pj,yr), 1) >= 1) = YES;
J_FMEG_r('gccs',z,yr)$(sum(J_CG_r('gccs',z,pj,yr), 1) >= 1) = YES;
J_FMEG_r('gcics',z,yr)$(sum(J_CG_r('gcics',z,pj,yr), 1) >= 1) = YES;

J_COEM_r('beccs',z,yr) = J_ET_r('beccs',z,yr);
J_COEM_r('coal',z,yr)$(sum(J_CG_r('coal',z,pj,yr), 1) >= 1) = YES;
J_COEM_r('gtcc',z,yr)$(sum(J_CG_r('gtcc',z,pj,yr), 1) >= 1) = YES;
J_COEM_r('cocs',z,yr)$(sum(J_CG_r('cocs',z,pj,yr), 1) >= 1) = YES;
J_COEM_r('coics',z,yr)$(sum(J_CG_r('coics',z,pj,yr), 1) >= 1) = YES;
J_COEM_r('gccs',z,yr)$(sum(J_CG_r('gccs',z,pj,yr), 1) >= 1) = YES;
J_COEM_r('gcics',z,yr)$(sum(J_CG_r('gcics',z,pj,yr), 1) >= 1) = YES;

display J_RN_r, J_NCSG_r, J_CCSG_r, J_NGFG_r, J_COFG_r, J_FMEG_r, J_COEM_r, J_CNGG_r;

Parameters dcap_eg(erg)   / gtcc 10, coal 20 /,       // Decommission caps for province, GW
           rcap_eg(erg)   / gtcc 10, coal 20 /;       // Retrofit caps for province, GW

* 装机容量及建设速度限制
* Positive variables U_EG_anom(eg,z,n,yr), U_EG_dnm(eg,z,n,yr);
* Positive variables U_PW_anom(epw,pz,pj,n,yr);
Positive variables U_CG_anom(ecng,pz,pj,n,yr), U_CG_dnm(erg,pz,pj,n,yr), U_CG_CCS(erg,pz,pj,n,yr);

U_CG_CCS.fx('gtcc',pz,pj,n,yr)$(cng(pz,pj)) = 0;

Equations eqU_EG_egnn,         // Technology installation capacity when n >= 1
          eqU_EG_edg0,         // Technology decommission when n = 0
          eqU_EG_edgn;         // Technology decommission when n >=1
          
Equations eqU_PW_egnn,         // Technology installation capacity when n >= 1
          eqU_PW_edg0,         // Technology decommission when n = 0
          eqU_PW_edgn;
          
Equations eqU_CG_egnn,         // Technology installation capacity when n >= 1
          eqU_CG_edg0,         // Technology decommission when n = 0
          eqU_CG_edgn;

* U_EG_anom(eg,z,n,yr)  ———— 第n年安装的技术在第yr年的容量
* U_EG_dnm(eg,z,n,yr)   ———— 第n年安装的技术在第yr年退役的容量
* U_EG_CCS(erg,z,n,yr)  ———— 第n年安装的coal、ccgt在第yr年改造的容量           

* Fix U_EG_anom(eg,z,n,n) to U_EG_nom(eg,z,n): All newly installed generation technologies
* 第n年安装的技术在第n年的容量 等于 第n年安装的容量
eqU_EG_egnn(J_ET_u(epv,z,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_EG_anom(epv,z,n,yr) =E= U_EG_nom(epv,z,n);   // GW, ~1.0
eqU_PW_egnn(J_PW_u(epw,pz,pj,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_PW_anom(epw,pz,pj,n,yr) =E= U_PW_nom(epw,pz,pj,n);
eqU_CG_egnn(J_CG_u(ecng,pz,pj,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_CG_anom(ecng,pz,pj,n,yr) =E= U_CG_nom(ecng,pz,pj,n);

* Technology decommission and retrofit with CCS when n = 0
* 现有技术第1年的装机容量 等于 现存的容量
U_EG_anom.fx(epv,z,'y0','y1') = U_ET_exn(epv,z);
U_PW_anom.fx(epw,pz,pj,'y0','y1') = U_PW_exn(epw,pz,pj);
U_CG_anom.fx(ecng,pz,pj,'y0','y1') = U_CG_exn(ecng,pz,pj);

* 除了gtcc和coal可以中途退役或改造，其余技术持续到自然寿命结束
* n = 0
eqU_EG_edg0(J_ET_u(edg,z,'y0',yr))$(ord(yr) < yem(edg,z,'y0')) .. U_EG_anom(edg,z,'y0',yr+1) =E= U_EG_anom(edg,z,'y0',yr);          // GW, ~1.0,  - U_EG_dnm(edg,z,'y0',yr+1)
* n >= 1
eqU_EG_edgn(J_ET_u(edg,z,n,yr))$((ord(n) > 1) and (ord(yr) < yem(edg,z,n))) .. U_EG_anom(edg,z,n,yr+1) =E= U_EG_anom(edg,z,n,yr);   // GW, ~1.0,  - U_EG_dnm(edg,z,n,yr+1)

* n = 0
eqU_PW_edg0(J_PW_u(epw,pz,pj,'y0',yr))$(ord(yr) < ypwm(epw,pz,pj,'y0')) .. U_PW_anom(epw,pz,pj,'y0',yr+1) =E= U_PW_anom(epw,pz,pj,'y0',yr);          // GW, ~1.0 
* n >= 1
eqU_PW_edgn(J_PW_u(epw,pz,pj,n,yr))$((ord(n) > 1) and (ord(yr) < ypwm(epw,pz,pj,n))) .. U_PW_anom(epw,pz,pj,n,yr+1) =E= U_PW_anom(epw,pz,pj,n,yr);   // GW, ~1.0

* n = 0
eqU_CG_edg0(J_CG_u(egg,pz,pj,'y0',yr))$(ord(yr) < ycgm(egg,pz,pj,'y0')) .. U_CG_anom(egg,pz,pj,'y0',yr+1) =E= U_CG_anom(egg,pz,pj,'y0',yr);          // GW, ~1.0 
* n >= 1
eqU_CG_edgn(J_CG_u(egg,pz,pj,n,yr))$((ord(n) > 1) and (ord(yr) < ycgm(egg,pz,pj,n))) .. U_CG_anom(egg,pz,pj,n,yr+1) =E= U_CG_anom(egg,pz,pj,n,yr);   // GW, ~1.0

* CCGT and Coal generation decommission and retrofit with CCS
Equations eqU_CG_erg0,   // Technology decomission and retrofit with CCS when n = 0
          eqU_CG_ergn;   // Technology decomission and retrofit with CCS when n >= 1

* n = 0，gtcc和coal可以退役或进行CCS改造
eqU_CG_erg0(J_CG_u(erg,pz,pj,'y0',yr))$(ord(yr) < ycgm(erg,pz,pj,'y0')) .. U_CG_anom(erg,pz,pj,'y0',yr+1) =E= U_CG_anom(erg,pz,pj,'y0',yr)
                                                                                               - U_CG_dnm(erg,pz,pj,'y0',yr+1) - U_CG_CCS(erg,pz,pj,'y0',yr+1);      // GW, ~1.0
* n >= 1，新安装的gtcc和coal可以退役或进行CCS改造
eqU_CG_ergn(J_CG_u(erg,pz,pj,n,yr))$((ord(n) > 1) and (ord(yr) < ycgm(erg,pz,pj,n))) .. U_CG_anom(erg,pz,pj,n,yr+1) =E= U_CG_anom(erg,pz,pj,n,yr)
                                                                                               - U_CG_dnm(erg,pz,pj,n,yr+1) - U_CG_CCS(erg,pz,pj,n,yr+1);  // GW, ~1.0

* 限制退役和改造的容量，只允许特定年份（yx）退役及改造
U_CG_dnm.fx(J_CG_u(erg,pz,pj,n,yr)) = 0.0;
U_CG_CCS.fx(J_CG_u(erg,pz,pj,n,yr)) = 0.0;

U_CG_dnm.up(J_CG_u(erg,pz,pj,n,yx)) = inf;
U_CG_CCS.up(J_CG_u(erg,pz,pj,n,yx)) = inf;

Equations eqDcap_CG_prov(erg,z,n,yr), eqRcap_CG_prov(erg,z,n,yr);

eqDcap_CG_prov(erg,z,n,yr)$(yx(yr)) .. sum(pj$J_CG_u(erg,z,pj,n,yr), U_CG_dnm(erg,z,pj,n,yr)) =L= dcap_eg(erg);
eqRcap_CG_prov(erg,z,n,yr)$(yx(yr)) .. sum(pj$J_CG_u(erg,z,pj,n,yr), U_CG_CCS(erg,z,pj,n,yr)) =L= rcap_eg(erg);

* For computing retrofitted capacities: GW，截至yr年改造的总容量
Positive variables U_CG_RO(ecg,pz,pj,yr);  
Equations eqU_CG_ROa, eqU_CG_ROb;
eqU_CG_ROa(J_CG_r('gcics',pz,pj,yr)) .. U_CG_RO('gcics',pz,pj,yr) =E= sum(J_CG_u('gcics',pz,pj,n(y),yr)$(ord(y) <= ord(yr)), U_CG_CCS('gtcc',pz,pj,n,yr));    // GW, ~1.0
eqU_CG_ROb(J_CG_r('coics',pz,pj,yr)) .. U_CG_RO('coics',pz,pj,yr) =E= sum(J_CG_u('coics',pz,pj,n(y),yr)$(ord(y) <= ord(yr)), U_CG_CCS('coal',pz,pj,n,yr));    // GW, ~1.0

* Record CCS retrofit capacities, yr年改造, 第yn年的容量
* 第yn年CCS的容量 = 第yr年改造的容量
* 第yn（yn > yr）年CCS的容量 = 第yr年改造的容量, 改造后保持同样容量至寿命结束
Positive variables U_CG_CCS_anom(ecg,pz,pj,n,yr,yn);
Equations eqU_CG_CCS_anoma, eqU_CG_CCS_anomb, eqU_CG_CCS_anomc, eqU_CG_CCS_anomd;

eqU_CG_CCS_anoma(J_CG_uo('gcics',pz,pj,n,yr,yn))$(ord(yr) = ord(yn)) .. U_CG_CCS_anom('gcics',pz,pj,n,yr,yn) =E= U_CG_CCS('gtcc',pz,pj,n,yr);              // GW, ~1.0
eqU_CG_CCS_anomb(J_CG_uo('gcics',pz,pj,n,yr,yn))$(ord(yn) < ycgm('gcics',pz,pj,n)) ..
                                                                        U_CG_CCS_anom('gcics',pz,pj,n,yr,yn+1) =E= U_CG_CCS_anom('gcics',pz,pj,n,yr,yn);    // GW, ~1.0

eqU_CG_CCS_anomc(J_CG_uo('coics',pz,pj,n,yr,yn))$(ord(yr) = ord(yn)) .. U_CG_CCS_anom('coics',pz,pj,n,yr,yn) =E= U_CG_CCS('coal',pz,pj,n,yr);              // GW, ~1.0
eqU_CG_CCS_anomd(J_CG_uo('coics',pz,pj,n,yr,yn))$(ord(yn) < ycgm('coics',pz,pj,n)) ..
                                                                        U_CG_CCS_anom('coics',pz,pj,n,yr,yn+1) =E= U_CG_CCS_anom('coics',pz,pj,n,yr,yn);   // GW, ~1.0

* For computing cumulative capacity, GW, 截至yr年技术总容量（包含改造）
* Positive variables U_EG_acm(er,z,yr), U_PW_acm(epw,pz,pj,yr), U_CG_acm(cngg,pz,pj,yr);
Positive variables U_CG_acm(cngg,pz,pj,yr);

Equations eqU_EG_acm;
Equations eqU_PW_acm, eqU_EGPW_acm1, eqU_EGPW_acm2;
Equations eqU_CG_acma, eqU_CG_acmb, eqU_CG_acmc, eqU_EGCG_acm1, eqU_EGCG_acm2;

eqU_EG_acm(J_ET_r(epv,z,yr)) .. U_EG_acm(epv,z,yr) =E= sum(J_ET_u(epv,z,n(y),yr)$(ord(y)-1 <= ord(yr)), U_EG_anom(epv,z,n,yr));   // GW, ~1.0

eqU_PW_acm(J_PW_r(epw,pz,pj,yr)) .. U_PW_acm(epw,pz,pj,yr) =E= sum(J_PW_u(epw,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), U_PW_anom(epw,pz,pj,n,yr));
eqU_EGPW_acm1(z,yr) .. U_EG_acm('pv',z,yr) =E= sum(pj$cpv(z,pj), U_PW_acm('pv',z,pj,yr));
eqU_EGPW_acm2(z,yr) .. U_EG_acm('nwd',z,yr) =E= sum(pj$cwt(z,pj), U_PW_acm('nwd',z,pj,yr));

eqU_CG_acma(J_CG_r(ecng,pz,pj,yr)) .. U_CG_acm(ecng,pz,pj,yr) =E= sum(J_CG_u(ecng,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), U_CG_anom(ecng,pz,pj,n,yr));
eqU_CG_acmb(J_CG_r('gcics',pz,pj,yn)) .. U_CG_acm('gcics',pz,pj,yn) =E= sum(J_CG_uo('gcics',pz,pj,n,yr,yn), U_CG_CCS_anom('gcics',pz,pj,n,yr,yn));   // GW, ~1.0
eqU_CG_acmc(J_CG_r('coics',pz,pj,yn)) .. U_CG_acm('coics',pz,pj,yn) =E= sum(J_CG_uo('coics',pz,pj,n,yr,yn), U_CG_CCS_anom('coics',pz,pj,n,yr,yn));   // GW, ~1.0
eqU_EGCG_acm1(ngfg,z,yr) .. U_EG_acm(ngfg,z,yr) =E= sum(pj$cng(z,pj), U_CG_acm(ngfg,z,pj,yr));
eqU_EGCG_acm2(cofg,z,yr) .. U_EG_acm(cofg,z,yr) =E= sum(pj$cco(z,pj), U_CG_acm(cofg,z,pj,yr));


* ========= Operations: Power generation technologies
Scalars cfr      / 0.03 /;      // fuel increase factor
Scalars c_Nu_0   / 2.392 /      // USD/MWh
        c_NG_0   / 31.86 /      // USD/MWh
        c_CO_0   / 10.45 /;     // USD/MWh

Parameters c_Nu(yr), c_NG(yr), c_CO(yr);
c_Nu(yr) = c_Nu_0 * (1 + cfr) ** (ord(yr) - 1) / ths;     // M USD/GWh, ~ 0.002
c_NG(yr) = c_NG_0 * (1 + cfr) ** (ord(yr) - 1) / ths;     // M USD/GWh, ~ 0.03
c_CO(yr) = c_CO_0 * (1 + cfr) ** (ord(yr) - 1) / ths;     // M USD/GWh, ~ 0.01

Parameters rho_ccs(er)    / gcics 0.95, gccs 0.95, coics 0.95, cocs 0.95, beccs 0.9 /             // Capture ratio
           phi_ccs(er)    / gcics 0.387, gccs 0.387, coics 0.156, cocs 0.156, beccs 0.261 /;      // CO2 capture energy: GWh/kton

* 发电量、燃料、碳排放
* Positive variables P_EG_gen(er,z,yr,h), F_EG_fcs(er,z,yr,h), EM_EG_CO2(er,z,yr,h);
* Positive Variables P_PW_gen(epw,pz,pj,yr,h);
Positive variables P_CG_gen(cngg,pz,pj,yr,h), F_CG_fcs(cngg,pz,pj,yr,h), EM_CG_CO2(cngg,pz,pj,yr,h);

* Prefx Solar and WT generation: GWh, pv/nwd
Equations eqP_PV_pref, eqP_WT_pref;
eqP_PV_pref(J_PW_r('pv',pz,pj,yr),h) .. P_PW_gen('pv',pz,pj,yr,h) =E= PV_CF(pz,pj,yr,h) * U_PW_acm('pv',pz,pj,yr);
eqP_WT_pref(J_PW_r('nwd',pz,pj,yr),h) .. P_PW_gen('nwd',pz,pj,yr,h) =E= WT_CF(pz,pj,yr,h) * U_PW_acm('nwd',pz,pj,yr);

* Renewable generation: GWh, pv/nwd/fwd
Equations eqP_EG_pv, eqP_EG_nwd, eqP_EG_fwd;
eqP_EG_pv(J_RN_r('pv',z,yr),h)   .. P_EG_gen('pv',z,yr,h) =E= sum(pj$cpv(z,pj), P_PW_gen('pv',z,pj,yr,h));       // GW, ~0.05 - 0.9
eqP_EG_nwd(J_RN_r('nwd',z,yr),h)  .. P_EG_gen('nwd',z,yr,h) =E= sum(pj$cwt(z,pj), P_PW_gen('nwd',z,pj,yr,h));    // GW, ~0.05 - 0.9
eqP_EG_fwd(J_ET_r('fwd',z,yr), h) .. P_EG_gen('fwd',z,yr,h) =E= offshwd(z,yr,h) * U_EG_acm('fwd',z,yr);   // GW, ~0.05 - 0.9

* (1)发电量、碳排放计算
* Generation technologies with no CCS: GWh, nu, bio, gtcc, coal(eta)
Equations eqP_EG_ncsg, eqP_EG_ncsg_max, eqEM_EG_CO2_cgmg1, eqEM_EG_CO2_cgmg2;
Equations eqP_CG_ncsg, eqP_CG_ncsg_max, eqEM_CG_CO2_cgmg;
Equations eqP_EG_cgmg1, eqP_EG_cgmg2;

eqP_EG_ncsg(J_ET_r(ncsg,z,yr), h) .. P_EG_gen(ncsg,z,yr,h) =E= ET_Specs(ncsg,'eta') * F_EG_fcs(ncsg,z,yr,h);    // Power generation: GWh, ~ 0.3 - 0.7
eqP_EG_ncsg_max(J_ET_r(ncsgh,z,yr), h) .. P_EG_gen(ncsgh,z,yr,h) =L= ET_Specs(ncsgh,'lm') * U_EG_acm(ncsgh,z,yr);   // Power availability: GWh, ~ 0.9 

eqP_CG_ncsg(J_CG_r(cgmg,pz,pj,yr), h) .. P_CG_gen(cgmg,pz,pj,yr,h) =E= ET_Specs(cgmg,'eta') * F_CG_fcs(cgmg,pz,pj,yr,h);    // Power generation: GWh, ~ 0.3 - 0.7
eqP_CG_ncsg_max(J_CG_r(cgmg,pz,pj,yr), h) .. P_CG_gen(cgmg,pz,pj,yr,h) =L= ET_Specs(cgmg,'lm') * U_CG_acm(cgmg,pz,pj,yr);   // Power availability: GWh, ~ 0.9 

eqP_EG_cgmg1(J_NCSG_r('coal',z,yr),h) .. P_EG_gen('coal',z,yr,h) =E= sum(pj$cco(z,pj), P_CG_gen('coal',z,pj,yr,h));
eqP_EG_cgmg2(J_NCSG_r('gtcc',z,yr),h) .. P_EG_gen('gtcc',z,yr,h) =E= sum(pj$cng(z,pj), P_CG_gen('gtcc',z,pj,yr,h));

// CO2 emissions: gtcc and coal: kilo ton
eqEM_CG_CO2_cgmg(J_CG_r(cgmg,pz,pj,yr), h) .. EM_CG_CO2(cgmg,pz,pj,yr,h) =E= ET_Specs(cgmg,'epn') * F_CG_fcs(cgmg,pz,pj,yr,h);    // kilo ton, ~ 0.2
eqEM_EG_CO2_cgmg1(J_NCSG_r('coal',z,yr),h) .. EM_EG_CO2('coal',z,yr,h) =E= sum(pj$cco(z,pj), EM_CG_CO2('coal',z,pj,yr,h));
eqEM_EG_CO2_cgmg2(J_NCSG_r('gtcc',z,yr),h) .. EM_EG_CO2('gtcc',z,yr,h) =E= sum(pj$cng(z,pj), EM_CG_CO2('gtcc',z,pj,yr,h));

* Generation technologies with CCS: retrofit with CCS or new plants with CCS: gcics, gccs, coics, cocs, beccs
* Positive variables P_EG_gen_ncs(er,z,yr,h), E_EG_CO2(er,z,yr,h);
Equations eqP_EG_gen_ncs, eqP_EG_gen_ncs_max, eqP_EG_gen_ccsgb, eqE_EG_CO2_ccsgb, eqEM_EG_CO2_ccsgb;
Equations eqEM_EG_CO2_ccsga1, eqEM_EG_CO2_ccsga2, eqEM_EG_CO2_ccsga3, eqEM_EG_CO2_ccsga4, eqE_CG_CO2_ccsga;
Equations eqP_EG_gen_ccsga, eqP_EG_gen_ccsga1, eqP_EG_gen_ccsga2, eqP_EG_gen_ccsga3, eqP_EG_gen_ccsga4;

Positive variables P_CG_gen_ncs(cngg,pz,pj,yr,h), E_CG_CO2(cngg,pz,pj,yr,h);
Equations eqP_CG_gen_ncs, eqP_CG_gen_ncs_max, eqE_CG_CO2_ccsga, eqEM_CG_CO2_ccsga;

* Generation technologies: compute power and fuel with no CCS,先计算不包含ccs的部分，再扣除ccs的能耗以及碳排放
eqP_EG_gen_ncs(J_ET_r(ccsgb,z,yr), h) .. P_EG_gen_ncs(ccsgb,z,yr,h) =E= ET_Specs(ccsgb,'eta') * F_EG_fcs(ccsgb,z,yr,h);                  // Power with no CCS: GWh, ~0.4-0.5
eqP_EG_gen_ncs_max(J_ET_r(ccsgb,z,yr), h)  .. P_EG_gen_ncs(ccsgb,z,yr,h) =L= ET_Specs(ccsgb,'lm') * U_EG_acm(ccsgb,z,yr);                // Power availability: GWh, ~0.9
eqE_EG_CO2_ccsgb(J_ET_r(ccsgb,z,yr), h) .. E_EG_CO2(ccsgb,z,yr,h) =L= rho_ccs(ccsgb) * ET_Specs(ccsgb,'epn') * P_EG_gen_ncs(ccsgb,z,yr,h); // Captured CO2: kilo ton, BECCS, 碳排放针对发电侧

eqP_CG_gen_ncs(J_CG_r(ccsga,pz,pj,yr), h) .. P_CG_gen_ncs(ccsga,pz,pj,yr,h) =E= ET_Specs(ccsga,'eta') * F_CG_fcs(ccsga,pz,pj,yr,h);                  // Power with no CCS: GWh, ~0.4-0.5
eqP_CG_gen_ncs_max(J_CG_r(ccsga,pz,pj,yr), h)  .. P_CG_gen_ncs(ccsga,pz,pj,yr,h) =L= ET_Specs(ccsga,'lm') * U_CG_acm(ccsga,pz,pj,yr);                // Power availability: GWh, ~0.9
eqE_CG_CO2_ccsga(J_CG_r(ccsga,pz,pj,yr), h) .. E_CG_CO2(ccsga,pz,pj,yr,h) =L= rho_ccs(ccsga) * ET_Specs(ccsga,'epn') * F_CG_fcs(ccsga,pz,pj,yr,h);     // Captured CO2: kilo ton, 碳排放针对燃料测

* gcics, gccs, coics, cocs, beccs技术的最终发电量以及碳排放. beccs为负碳排放
eqP_EG_gen_ccsgb(J_ET_r(ccsgb,z,yr), h) .. P_EG_gen(ccsgb,z,yr,h) =E= P_EG_gen_ncs(ccsgb,z,yr,h) - phi_ccs(ccsgb) * E_EG_CO2(ccsgb,z,yr,h);         // Power with CCS: GWh, 0.2~0.3
eqP_EG_gen_ccsga(J_CG_r(ccsga,pz,pj,yr), h) .. P_CG_gen(ccsga,pz,pj,yr,h) =E= P_CG_gen_ncs(ccsga,pz,pj,yr,h) - phi_ccs(ccsga) * E_CG_CO2(ccsga,pz,pj,yr,h);
eqP_EG_gen_ccsga1(J_CCSG_r('gccs',z,yr),h) .. P_EG_gen('gccs',z,yr,h) =E= sum(pj$cng(z,pj), P_CG_gen('gccs',z,pj,yr,h));
eqP_EG_gen_ccsga2(J_CCSG_r('gcics',z,yr),h) .. P_EG_gen('gcics',z,yr,h) =E= sum(pj$cng(z,pj), P_CG_gen('gcics',z,pj,yr,h));
eqP_EG_gen_ccsga3(J_CCSG_r('cocs',z,yr),h) .. P_EG_gen('cocs',z,yr,h) =E= sum(pj$cco(z,pj), P_CG_gen('cocs',z,pj,yr,h));
eqP_EG_gen_ccsga4(J_CCSG_r('coics',z,yr),h) .. P_EG_gen('coics',z,yr,h) =E= sum(pj$cco(z,pj), P_CG_gen('coics',z,pj,yr,h));

eqEM_EG_CO2_ccsgb(J_ET_r(ccsgb,z,yr), h) .. EM_EG_CO2(ccsgb,z,yr,h) =E= 0 - E_EG_CO2(ccsgb,z,yr,h);    // Emission for BECCS, 不计入生物质中性碳排放，结果为负碳排放
eqEM_CG_CO2_ccsga(J_CG_r(ccsga,pz,pj,yr), h) .. EM_CG_CO2(ccsga,pz,pj,yr,h) =E= ET_Specs(ccsga,'epn') * F_CG_fcs(ccsga,pz,pj,yr,h) -  E_CG_CO2(ccsga,pz,pj,yr,h);   // Emission with CCS: kilo ton, ~0.17-0.3
eqEM_EG_CO2_ccsga1(J_CCSG_r('gccs',z,yr),h) .. EM_EG_CO2('gccs',z,yr,h) =E= sum(pj$cng(z,pj), EM_CG_CO2('gccs',z,pj,yr,h));
eqEM_EG_CO2_ccsga2(J_CCSG_r('gcics',z,yr),h) .. EM_EG_CO2('gcics',z,yr,h) =E= sum(pj$cng(z,pj), EM_CG_CO2('gcics',z,pj,yr,h));
eqEM_EG_CO2_ccsga3(J_CCSG_r('cocs',z,yr),h) .. EM_EG_CO2('cocs',z,yr,h) =E= sum(pj$cco(z,pj), EM_CG_CO2('cocs',z,pj,yr,h));
eqEM_EG_CO2_ccsga4(J_CCSG_r('coics',z,yr),h) .. EM_EG_CO2('coics',z,yr,h) =E= sum(pj$cco(z,pj), EM_CG_CO2('coics',z,pj,yr,h));
 
* (2)最大、最小出力因子
* Generation capacity factors: Maximun and Minimun
Equations eqP_EG_CFm_clng, eqP_EG_CFn_clng, eqP_EG_CFm_cngg;

* Clean generation: capacity factors based on net output power: P_EG_gen -- nu/hydo/bio/beccs, min/max generation
eqP_EG_CFm_clng(J_ET_r(clng,z,yr)) .. sum(h, nds * P_EG_gen(clng,z,yr,h)) =L= nhys * ET_Specs(clng,'cfm') * ET_Specs(clng,'lm') * U_EG_acm(clng,z,yr);   // GW, ~1 - 8000
eqP_EG_CFn_clng(J_ET_r(clng,z,yr)) .. sum(h, nds * P_EG_gen(clng,z,yr,h)) =G= nhys * ET_Specs(clng,'cfn') * ET_Specs(clng,'lm') * U_EG_acm(clng,z,yr);   // GW, ~1 - 2400
* gcics, gccs, coics, and coccs: capacity factors based on net output power: P_EG_gen, /max generation
eqP_EG_CFm_cngg(J_CNGG_r(cngg,z,yr)) .. sum(h, nds * P_EG_gen(cngg,z,yr,h)) =L= nhys * ET_Specs(cngg,'cfm') * ET_Specs(cngg,'lm') * U_EG_acm(cngg,z,yr);   // GW, ~1 - 8000

* (3)机组爬坡约束
* Technology ramping with no CCS
Equations eqP_EG_rampa, eqP_EG_rampb, eqP_EG_rampc, eqP_EG_rampd;
Equations eqP_EG_ramp1, eqP_EG_ramp2, eqP_EG_ramp3, eqP_EG_ramp4;

* Ramping with no CCS and prov
eqP_EG_rampa(J_ET_r(rmpg,z,yr), h)$(ord(h) > 1) .. P_EG_gen(rmpg,z,yr,h) - P_EG_gen(rmpg,z,yr,h-1) =L=  ET_Specs(rmpg,'ro') * U_EG_acm(rmpg,z,yr);   // GW, ~0.25-1
eqP_EG_rampb(J_ET_r(rmpg,z,yr), h)$(ord(h) > 1) .. P_EG_gen(rmpg,z,yr,h) - P_EG_gen(rmpg,z,yr,h-1) =G= -ET_Specs(rmpg,'ro') * U_EG_acm(rmpg,z,yr);   // GW, ~0.25-1

* Ramping with no CCS and pref
eqP_EG_ramp1(J_CG_r(cgmg,pz,pj,yr), h)$(ord(h) > 1) .. P_CG_gen(cgmg,pz,pj,yr,h) - P_CG_gen(cgmg,pz,pj,yr,h-1) =L=  ET_Specs(cgmg,'ro') * U_CG_acm(cgmg,pz,pj,yr);   // GW, ~0.25-1
eqP_EG_ramp2(J_CG_r(cgmg,pz,pj,yr), h)$(ord(h) > 1) .. P_CG_gen(cgmg,pz,pj,yr,h) - P_CG_gen(cgmg,pz,pj,yr,h-1) =G= -ET_Specs(cgmg,'ro') * U_CG_acm(cgmg,pz,pj,yr); 

* Ramping with CCS: based on generation plants
eqP_EG_rampc(J_ET_r(ccsgb,z,yr), h)$(ord(h) > 1) .. P_EG_gen_ncs(ccsgb,z,yr,h) - P_EG_gen_ncs(ccsgb,z,yr,h-1) =L=  ET_Specs(ccsgb,'ro') * U_EG_acm(ccsgb,z,yr);   // GW, ~0.25-1
eqP_EG_rampd(J_ET_r(ccsgb,z,yr), h)$(ord(h) > 1) .. P_EG_gen_ncs(ccsgb,z,yr,h) - P_EG_gen_ncs(ccsgb,z,yr,h-1) =G= -ET_Specs(ccsgb,'ro') * U_EG_acm(ccsgb,z,yr);   // GW, ~0.25-1

eqP_EG_ramp3(J_CG_r(ccsga,pz,pj,yr), h)$(ord(h) > 1) .. P_CG_gen_ncs(ccsga,pz,pj,yr,h) - P_CG_gen_ncs(ccsga,pz,pj,yr,h-1) =L=  ET_Specs(ccsga,'ro') * U_CG_acm(ccsga,pz,pj,yr);   // GW, ~0.25-1
eqP_EG_ramp4(J_CG_r(ccsga,pz,pj,yr), h)$(ord(h) > 1) .. P_CG_gen_ncs(ccsga,pz,pj,yr,h) - P_CG_gen_ncs(ccsga,pz,pj,yr,h-1) =G= -ET_Specs(ccsga,'ro') * U_CG_acm(ccsga,pz,pj,yr);   // GW, ~0.25-1

* (4)备用容量约束
* Positive variables R_EG_frm(er,z,yr,h), R_CG_frm(cngg,pz,pj,yr,h);
Positive variables R_CG_frm(cngg,pz,pj,yr,h);

Equations eqR_EG_frma, eqR_EG_frmb;
Equations eqR_EG_frm1, eqR_EG_frm2, eqR_EG_frm3, eqR_EG_frm4;

eqR_EG_frma(J_ET_r(fmega,z,yr), h) .. R_EG_frm(fmega,z,yr,h) =L= ET_Specs(fmega,'lm') * U_EG_acm(fmega,z,yr) - P_EG_gen(fmega,z,yr,h);   // GW, 0.9  ~ 1.0
eqR_EG_frmb(J_ET_r(fmega,z,yr), h) .. R_EG_frm(fmega,z,yr,h) =L= ET_Specs(fmega,'ro') * U_EG_acm(fmega,z,yr);

eqR_EG_frm1(J_CG_r(cngg,pz,pj,yr), h) .. R_CG_frm(cngg,pz,pj,yr,h) =L= ET_Specs(cngg,'lm') * U_CG_acm(cngg,pz,pj,yr) - P_CG_gen(cngg,pz,pj,yr,h);   // GW, 0.9  ~ 1.0
eqR_EG_frm2(J_CG_r(cngg,pz,pj,yr), h) .. R_CG_frm(cngg,pz,pj,yr,h) =L= ET_Specs(cngg,'ro') * U_CG_acm(cngg,pz,pj,yr);

eqR_EG_frm3(J_NGFG_r(ngfg,z,yr),h) .. R_EG_frm(ngfg,z,yr,h) =E= sum(pj$cng(z,pj), R_CG_frm(ngfg,z,pj,yr,h));
eqR_EG_frm4(J_COFG_r(cofg,z,yr),h) .. R_EG_frm(cofg,z,yr,h) =E= sum(pj$cco(z,pj), R_CG_frm(cofg,z,pj,yr,h));

* (5) Fuel consumption: Nuclear, NG, Coal
Positive variables F_CG_NG(pz,pj,yr), F_CG_Coal(pz,pj,yr);
* Positive variables F_EG_Nu(z,yr), F_EG_NG(z,yr), F_EG_Coal(z,yr);
Equations eqF_EG_Nu, eqF_EG_NG1, eqF_EG_Coal1, eqF_EG_NG2, eqF_EG_Coal2;

eqF_EG_Nu(cnu(z),yr) .. F_EG_Nu(z,yr) =E= sum((J_ET_r('nu',z,yr), h), nds * F_EG_fcs('nu',z,yr,h));       

eqF_EG_NG1(pz,pj,yr) .. F_CG_NG(pz,pj,yr) =E= sum((J_CG_r(ngfg,pz,pj,yr), h), nds * F_CG_fcs(ngfg,pz,pj,yr,h));           
eqF_EG_NG2(J_NGFG_r(ngfg,z,yr)) .. F_EG_NG(z,yr) =E= sum(pj$cng(z,pj), F_CG_NG(z,pj,yr));            

eqF_EG_Coal1(pz,pj,yr) .. F_CG_Coal(pz,pj,yr) =E= sum((J_CG_r(cofg,pz,pj,yr), h), nds * F_CG_fcs(cofg,pz,pj,yr,h));        // GWh, 1 ~ 1
eqF_EG_Coal2(J_COFG_r(cofg,z,yr)) .. F_EG_Coal(z,yr) =E= sum(pj$cco(z,pj), F_CG_Coal(z,pj,yr)); 

* (6) Clean energy resource limition
Equation eqU_EG_CE_rLim_pv, eqU_EG_CE_rLim_nwd, eqU_EG_CE_rLim_fwd, eqU_EG_CE_rLim_nu, eqU_EG_CE_rLim_bio;

eqU_EG_CE_rLim_pv(J_PW_r('pv',pz,pj,yr))  .. U_PW_acm('pv',pz,pj,yr) =L= PV_Cap(pz,pj);
eqU_EG_CE_rLim_nwd(J_PW_r('nwd',pz,pj,yr)) .. U_PW_acm('nwd',pz,pj,yr) =L= WT_Cap(pz,pj);
eqU_EG_CE_rLim_fwd(J_ET_r('fwd',z,yr)) .. U_EG_acm('fwd',z,yr) =L= CE_rLim('fwd',z);
eqU_EG_CE_rLim_nu(J_ET_r('nu',z,yr))  .. U_EG_acm('nu',z,yr) =L= CE_rLim('nu',z);
eqU_EG_CE_rLim_bio(z,yr) .. sum((J_ET_r('bio',z,yr), h), nds * F_EG_fcs('bio',z,yr,h)) + sum((J_ET_r('beccs',z,yr), h), nds * F_EG_fcs('beccs',z,yr,h)) =L= CE_rLim('bio',z);


* ========= Investment and operation costs
Parameters ET_uCaPx(er,y);
ET_uCaPx(er,yr) = ET_CaPx(er,'%scn%',yr);

Positive variables CaPx_EG(n), CaPx_EG_RO(yx), FCS_EG(yr), FOM_EG(yr), VOM_EG(yr);
Equations eqCaPx_EG, eqCaPx_EG_RO, eqFCS_EG, eqFOM_EG, eqVOM_EG;

eqCaPx_EG(n)$(ord(n) > 1) .. CaPx_EG(n) =E= sum(J_ET_s(epv,z,n), dn(n) * ET_afr(epv) * ET_dsm(epv,n) * ET_uCaPx(epv,n) * U_EG_nom(epv,z,n)) +
                                            sum(J_PW_s(epw,pz,pj,n), dn(n) * ET_afr(epw) * ET_dsm(epw,n) * ET_uCaPx(epw,n) * U_PW_nom(epw,pz,pj,n)) +
                                            sum(J_CG_s(ecng,pz,pj,n), dn(n) * ET_afr(ecng) * ET_dsm(ecng,n) * ET_uCaPx(ecng,n) * U_CG_nom(ecng,pz,pj,n));    // M USD, 投资成本-计算安装时的容量即可

eqCaPx_EG_RO(yx(yr))$(ord(yr) > 1) .. CaPx_EG_RO(yx) =E= sum(J_CG_u('gcics',pz,pj,n,yr),
                                                         dn(yr) * ET_afr('gcics') * CG_R_dsm('gcics',pz,pj,n,yr) * ET_uCaPx('gcics',yr) * U_CG_CCS('gtcc',pz,pj,n,yr)) +
                                                         sum(J_CG_u('coics',pz,pj,n,yr),
                                                         dn(yr) * ET_afr('coics') * CG_R_dsm('coics',pz,pj,n,yr) * ET_uCaPx('coics',yr) * U_CG_CCS('coal',pz,pj,n,yr));   // M USD, 400~600

eqFCS_EG(yr) .. FCS_EG(yr) =E= sum(cnu(z), dn(yr) * (c_Nu(yr) * F_EG_Nu(z,yr))) +           // M USD/GWh, ~0.002
                               sum(z,      dn(yr) * (c_NG(yr) * F_EG_NG(z,yr))) +           // M USD/GWh, ~0.03
                               sum(z,      dn(yr) * (c_CO(yr) * F_EG_Coal(z,yr)));          // M USD/GWh, ~0.01

eqFOM_EG(yr) .. FOM_EG(yr) =E= sum(J_ET_r(epv,z,yr), dn(yr) * ET_FOM(epv,'%scn%',yr) * U_EG_acm(epv,z,yr)) +
                               sum(J_PW_r(epw,pz,pj,yr), dn(yr) * ET_FOM(epw,'%scn%',yr) * U_PW_acm(epw,pz,pj,yr)) +
                               sum(J_CG_r(cngg,pz,pj,yr), dn(yr) * ET_FOM(cngg,'%scn%',yr) * U_CG_acm(cngg,pz,pj,yr));                  // M USD/GWh, ~0.01-0.15

eqVOM_EG(yr) .. VOM_EG(yr) =E= sum((J_ET_r(ncsgh,z,yr),h), nds * dn(yr) * ET_VOM(ncsgh,'%scn%',yr) * P_EG_gen(ncsgh,z,yr,h)) +
                               sum((J_ET_r(ccsgb,z,yr),h), nds * dn(yr) * ET_VOM(ccsgb,'%scn%',yr) * P_EG_gen(ccsgb,z,yr,h)) +
                               sum((J_CG_r(cngg,pz,pj,yr),h), nds * dn(yr) * ET_VOM(cngg,'%scn%',yr) * P_CG_gen(cngg,pz,pj,yr,h));   // M USD/GWh, ~0.002-0.02

eqFCS_EG.scale(yr) = 0.001;
eqFOM_EG.scale(yr) = 0.01;
eqVOM_EG.scale(yr) = 0.01;



* ========================== Power storage technolgies ========================== *
* ========= Capacity sizing: Power storage technologies
* Positive variables U_ES_nom(es,z,n);
Equations eqU_ES_nom, eqU_ES_bLim;

eqU_ES_nom(J_ET_s(es,z,n)) .. U_ES_nom(es,z,n) =L= U_ES_Max(es,z);                           // GW
eqU_ES_bLim(es,n)$(ord(n) > 1) .. sum(J_ET_s(es,z,n), U_ES_nom(es,z,n)) =L= U_ES_bLim(es) * invSpan(n);   // GW, 1.0 ~ 1.0

* Capacity continuation
* Positive variables U_ES_anom(es,z,n,yr), U_ES_dnm(es,z,n,yr);
Equations eqU_ES_anoma, eqU_ES_anomb, eqU_ES_anomc;

* Fix U_ES_anom(es,z,n,n) to U_ES_nom(es,z,n): All newly installed storage technologies
eqU_ES_anoma(J_ET_u(es,z,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_ES_anom(es,z,n,yr) =E= U_ES_nom(es,z,n);

* Storage technology decommission when n = 0
U_ES_anom.fx(es,z,'y0','y1') = U_ET_exn(es,z);
eqU_ES_anomb(J_ET_u(es,z,'y0',yr))$(ord(yr) < yem(es,z,'y0')) .. U_ES_anom(es,z,'y0',yr+1) =E= U_ES_anom(es,z,'y0',yr);   // - U_ES_dnm(es,z,'y0',yr+1)

* Storage technology decommission when n >= 1
eqU_ES_anomc(J_ET_u(es,z,n,yr))$((ord(n) > 1) and (ord(yr) < yem(es,z,n))) .. U_ES_anom(es,z,n,yr+1) =E= U_ES_anom(es,z,n,yr);

* Storage: No decommission
U_ES_dnm.fx(J_ET_u(es,z,n,yr)) = 0;

* Positive variables U_ES_acm(es,z,yr), U_lib_acm_ys(es,yr);      // For computing cumulative capacity, GW
Equations eqU_ES_acm, eq_lib_acm(es,yr);
eqU_ES_acm(J_ET_r(es,z,yr)) .. U_ES_acm(es,z,yr) =E= sum(J_ET_u(es,z,n(y),yr)$(ord(y)-1 <= ord(yr)), U_ES_anom(es,z,n,yr));
*eqES_acmyr(J_ET_r(es,z,yr))$((ord(yr)) > 1 and (ord(yr) < card(yr))) .. U_ES_acm(es,z,yr+1) =G= U_ES_acm(es,z,yr);
eq_lib_acm('lib4',yr) .. U_lib_acm_ys('lib4',yr) =E= sum(z, U_ES_acm('lib4',z,yr));

Equations eqlib_2027, eqlib_2030, eqlib_2035, eqlib_2050;
eqlib_2027('lib4','y3') .. U_lib_acm_ys('lib4','y3') =G= 180 * 0.95;
eqlib_2030('lib4','y6') .. U_lib_acm_ys('lib4','y6') =G= 240 * 0.95;
eqlib_2035('lib4','y11') .. U_lib_acm_ys('lib4','y11') =G= 300 * 0.94;
eqlib_2050('lib4','y26') .. U_lib_acm_ys('lib4','y26') =G= 420 * 0.93;

* Pumped hydro storage resource availability
Equations eqU_ES_rlim;
eqU_ES_rlim(J_ET_r('phs',z,yr))  .. U_EG_acm('phs',z,yr) =L= CE_rLim('phs',z);


* ========= Operations: Power storage technologies
Parameters ES_loss(es)   / phs 0.005, lib4 0.002 /;

* Positive variables En_ES(es,z,yr,t), C_ES(es,z,yr,h), D_ES(es,z,yr,h);   // t时刻储存的电量GWh、充放电功率GW
Equations eqEn_ES, eqEm_ES, eqC_ES, eqD_ES, eq_C_D_EScon;

eqEn_ES(J_ET_r(es,z,yr), h(t)) .. En_ES(es,z,yr,t) =E= En_ES(es,z,yr,t-1) * (1 - ES_loss(es)) + C_ES(es,z,yr,h) * ET_Specs(es,'eta') - D_ES(es,z,yr,h);
eqEm_ES(J_ET_r(es,z,yr), h) .. En_ES(es,z,yr,h) =L= tau_es(es) * U_ES_acm(es,z,yr);

eqC_ES(J_ET_r(es,z,yr), h) .. C_ES(es,z,yr,h) =L= ET_Specs(es,'lm') * U_ES_acm(es,z,yr);
eqD_ES(J_ET_r(es,z,yr), h) .. D_ES(es,z,yr,h) =L= ET_Specs(es,'lm') * U_ES_acm(es,z,yr);
eq_C_D_EScon(J_ET_r(es,z,yr), h) .. C_ES(es,z,yr,h) + D_ES(es,z,yr,h) =L= ET_Specs(es,'lm') * U_ES_acm(es,z,yr);

* Initial and final states in a year: Correct!
Equations eqEn_ES_yr, eqEn_ES_h;
En_ES.fx(es,z,'y1','h0')$(J_ET_r(es,z,'y1')) = 0;  // 初始状态
eqEn_ES_yr(J_ET_r(es,z,yr), h)$((ord(yr) < card(yr)) and (ord(h) = card(h))) .. En_ES(es,z,yr+1,'h0') =E= En_ES(es,z,yr,h);  //跨年状态连续
eqEn_ES_h(J_ET_r(es,z,yr), t)$((ord(t) > 1) and (mod(ord(t)-1,%hrs%) = 0)) .. En_ES(es,z,yr,t) =E= En_ES(es,z,yr,'h0'); //典型日内完成充放

* Operation reserves
* Positive variables R_ES_frm(es,z,yr,h);
Equations eqR_ES_frma, eqR_ES_frmb;

eqR_ES_frma(J_ET_r(es,z,yr), h) .. R_ES_frm(es,z,yr,h) =L= ET_Specs(es,'lm') * U_ES_acm(es,z,yr) - D_ES(es,z,yr,h);
eqR_ES_frmb(J_ET_r(es,z,yr), h(t)) .. R_ES_frm(es,z,yr,h) =L= En_ES(es,z,yr,t-1) + ET_Specs(es,'eta') * C_ES(es,z,yr,h) - D_ES(es,z,yr,h);


* ========= Investment and operation costs
Positive variables CaPx_ES(n), FOM_ES(yr), VOM_ES(yr);
Equations eqCaPx_ES, eqFOM_ES, eqVOM_ES;

eqCaPx_ES(n) .. CaPx_ES(n) =E= sum(J_ET_s(es,z,n), dn(n) * ET_afr(es) * ET_dsm(es,n) * ET_uCaPx(es,n) * U_ES_nom(es,z,n));   // M USD, 800~1500

eqFOM_ES(yr) .. FOM_ES(yr) =E= sum(J_ET_r(es,z,yr), dn(yr) * ET_FOM(es,'%scn%',yr) * U_ES_acm(es,z,yr));      // M USD, ~0.02-0.05

eqVOM_ES(yr) .. VOM_ES(yr) =E= sum((J_ET_r(es,z,yr),h), nds * dn(yr) * ET_VOM(es,'%scn%',yr) * (C_ES(es,z,yr,h) + D_ES(es,z,yr,h)));   // M USD, ~0.002-0.003

eqFOM_ES.scale(yr) = 0.01;
eqVOM_ES.scale(yr) = 0.01;



* ========================== Power transmission technologis ========================== *
Scalars ld   decend rate for lines   / 0.015 /;
Parameters ldn(y);     // Transmission line decrease rates

ldn(yr) = 1 / ((1 + ld) ** (ord(yr) - 1));

* Transmission line costs, 假设AC/DC参数一致
Parameters ELi_CaPx(m)   / ac 398,   dc 398 /    // USD/MW/km
           ELi_FOM(m)    / ac 14.0,  dc 14.0  /    // USD/MW/km/yr, 3.5% of CaPx
           ELi_VOM(m)    / ac 5.00,  dc 5.00  /;    // USD/MWh

ELi_CaPx(m) = ELi_CaPx(m) / ths;   //  M USD/GW/km, ~0.3
ELi_FOM(m)  = ELi_FOM(m)  / ths;   // M USD/GW/km/yr, 0.012
ELi_VOM(m)  = ELi_VOM(m)  / ths;   // M USD/GWh, 0.002

* ========= Internal transimission
Sets imo(m,z,zx)            existing internal transmission lines
     ims_145(m,z,zx)        14th Five-Year lines for transmission   / ac.HE.SD, ac.SC.CQ, dc.SX.TJ,
                                                                      dc.SC.HB, dc.GS.SD, dc.XJ.CQ, 
                                                                      dc.NX.HN, dc.SN.AH, dc.SN.HA,
                                                                      dc.MX.HE, dc.MX.BJ, dc.MX.TJ,
                                                                      dc.XZ.GD, dc.GS.ZJ /
     ims_aft_145(m,z,zx)    after 14th Five-Year for transmission   / ac.SX.MX, dc.MX.SH, dc.MX.JX,
                                                                      dc.MX.SD, dc.MX.CQ, dc.MX.SC, 
                                                                      dc.MX.JS, dc.JL.BJ, dc.HL.HE,
                                                                      dc.LN.TJ /
     imz(m,z,zx)            transmission lines for capacity expansion

     J_ET_m(m,z,zx,ni,yr)   useful operation years for transmission lines      // From z to zx, z < zx
     J_ET_v(m,z,zx,yr)      transmission line available in year yr   
     J_ET_vm(m,z,zx,yr)     possible bidirectional power flow in yr;

* Transmission expansion
imo(m,z,zx)$(U_ET_iln(m,z,zx)) = yes;                                       // Existing transmission lines
imz(m,z,zx) = imo(m,z,zx) + ims_145(m,z,zx);  // + ims_aft_145(m,z,zx);          // Possible transmission lines for expansion

J_ET_m(m,z,zx,'y0',yr)$(U_ET_iln(m,z,zx) and (ord(yr) <= lntm)) = yes;
J_ET_m(imz(m,z,zx),ni(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + lntm - 1), card(yr)))) = yes;

J_ET_v(m,z,zx,yr)$(sum(J_ET_m(m,z,zx,ni(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;     // z < zx

J_ET_vm(m,z,zx,yr)$(J_ET_v(m,z,zx,yr)) = yes;     // Bidirectional flows for transmission
J_ET_vm(m,zx,z,yr)$(J_ET_v(m,z,zx,yr)) = yes;     // 双向传输流

Display J_ET_m, J_ET_v, J_ET_vm;

* The first year and final years: inter-eleCtricity transmission
Parameters yin(m,z,zx,ni), yio(m,z,zx,ni), yim(m,z,zx,ni);
yin(m,z,zx,'y0')$(J_ET_m(m,z,zx,'y0','y1')) = 1;
Loop(J_ET_m(m,z,zx,ni(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), yin(m,z,zx,ni) = ord(yr););   // The first operation year
yio(m,z,zx,ni)$(yin(m,z,zx,ni)) = sum(yr$(J_ET_m(m,z,zx,ni,yr)), 1);                                // The operation period
yim(m,z,zx,ni)$(yin(m,z,zx,ni)) = yio(m,z,zx,ni) + yin(m,z,zx,ni) - 1;                              // The last  operation year

Display yin, yio, yim;

* Discounted share of lifetime for power transmission technologies
Parameters ELi_afr(m), ELi_dsm(m,ni), ELi_TM(m,ni);

ELi_afr(m) = (1 - 1 / (1 + ir)) / (1 - 1 / ((1 + ir) ** lntm));   // Annualized factor for technologies
ELi_dsm(m,ni(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, lntm)))) / (1 - 1 / (1 + ir));

ELi_TM(m,ni) = ELi_afr(m) * ELi_dsm(m,ni);

Display ELi_afr, ELi_dsm, ELi_TM;

* 电力网络扩容影响
* ========= Capacity sizing
* Positive variables U_ELi_nom(m,z,zx,ni);   // GW
Equations eqU_ELi_nom, eqU_ELi_bLim;

eqU_ELi_nom(imz(m,z,zx),ni)$(ord(ni) > 1) .. U_ELi_nom(m,z,zx,ni) =L= U_ELi_Max(m,z,zx);     // installation cap. <= max. caps, GW
eqU_ELi_bLim(ni)$(ord(ni) > 1) .. sum(imz(m,z,zx), U_ELi_nom(m,z,zx,ni)) =L= U_ELi_bLim * invSpan(ni);     // Max. building rates

* Capacity continuation
* Positive variables U_ELi_anom(m,z,zx,ni,yr), U_ELi_dnm(m,z,zx,ni,yr);
Equations eqU_ELi_anoma, eqU_ELi_anomb, eqU_ELi_anomc;

* Fix line capacity U_ELi_anom(m,z,zx,ni,ni) to U_ELi_nom(m,z,zx,ni)
eqU_ELi_anoma(J_ET_m(m,z,zx,ni(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_ELi_anom(m,z,zx,ni,yr) =E= U_ELi_nom(m,z,zx,ni);

* Transmission technologies decommission when n = 0
U_ELi_anom.fx(m,z,zx,'y0','y1') = U_ET_iln(m,z,zx);
eqU_ELi_anomb(J_ET_m(m,z,zx,'y0',yr))$(ord(yr) < yim(m,z,zx,'y0')) .. U_ELi_anom(m,z,zx,'y0',yr+1) =E= U_ELi_anom(m,z,zx,'y0',yr);   // - U_ELi_dnm(m,z,zx,'y0',yr+1)

* Transimission technology decommission when n >= 1
eqU_ELi_anomc(J_ET_m(m,z,zx,ni,yr))$((ord(ni) > 1) and (ord(yr) < yim(m,z,zx,ni))) .. U_ELi_anom(m,z,zx,ni,yr+1) =E= U_ELi_anom(m,z,zx,ni,yr);   // - U_ELi_dnm(m,z,zx,ni,yr+1)

U_ELi_dnm.fx(J_ET_m(m,z,zx,ni,yr)) = 0;   // No transimission line decommission

* Cumulative capacity of transmission lines in year yr
* Positive variables U_ELi_acm(m,z,zx,yr);   // GW
Equations eqU_ELi_acm;

eqU_ELi_acm(J_ET_v(m,z,zx,yr)) .. U_ELi_acm(m,z,zx,yr) =E= sum(J_ET_m(m,z,zx,ni(y),yr)$(ord(y)-1 <= ord(yr)), U_ELi_anom(m,z,zx,ni,yr));   // accumulative caps


* ========= Operations
Parameters ELi_loss(m)   / ac 0.0001, dc 0.0001 /;   // Line loss: per km

* Positive variables P_Eli(m,z,zx,yr,h);      // GWh
Equations eqP_Elia, eqP_ELib, eqP_ELic;

eqP_Elia(J_ET_v(m,z,zx,yr), h) .. P_Eli(m,z,zx,yr,h) * (1 - ETNS_dstn(z,zx) * ELi_loss(m)) =L= U_ELi_acm(m,z,zx,yr);   // Power flow <= caps: z to zx
eqP_ELib(J_ET_v(m,z,zx,yr), h) .. P_Eli(m,zx,z,yr,h) * (1 - ETNS_dstn(zx,z) * ELi_loss(m)) =L= U_ELi_acm(m,z,zx,yr);   // Power flow <= caps: zx to z
eqP_ELic(J_ET_v(m,z,zx,yr), h) .. (P_Eli(m,z,zx,yr,h) + P_Eli(m,zx,z,yr,h)) * (1 - ETNS_dstn(z,zx) * ELi_loss(m)) =L= U_ELi_acm(m,z,zx,yr);


* ========= Investment and operation costs
* Positive variables CaPx_ELi(ni), FOM_ELi(yr), VOM_ELi(yr);
Equations eqCaPx_ELi, eqFOM_ELi;

eqCaPx_ELi(ni) .. CaPx_ELi(ni) =E= sum(imz(m,z,zx),
                   dn(ni) * ldn(ni) * ELi_afr(m) * ELi_dsm(m,ni) * ELi_CaPx(m) * ETNS_dstn(z,zx) * U_ELi_nom(m,z,zx,ni));               // M USD, ~30

eqFOM_ELi(yr) .. FOM_ELi(yr) =E= sum(J_ET_v(m,z,zx,yr), dn(yr) * ldn(yr) * ELi_FOM(m) * ETNS_dstn(z,zx) * U_ELi_acm(m,z,zx,yr));        // M USD, ~0.4

Equations eqVOM_ELi;
eqVOM_ELi(yr) .. VOM_ELi(yr) =E= sum((J_ET_v(m,z,zx,yr), h), nds * dn(yr) * ELi_VOM(m) * (P_Eli(m,z,zx,yr,h) + P_Eli(m,zx,z,yr,h)));    // M USD, ~0.002
eqVOM_ELi.scale(yr) = 0.01;


* ========================== C_Network System Options ========================== *
* Model Specification (mflag): 1 => E_Net, 2 => E_Net + C_Net.
$ifthen "%mflag%" == "2"
$include %Cfolder%/CO2 system.gms

$endif


* ========================== System balance and reserves ========================== *
Scalars E_rsm        reserve margin    / 0.05 /
        E_drs        dynamic reserve   / 0.1  /  
        Edem_Sc      scale factor      / 1.0  /;

Parameters Edem_sum(yr)   electricity demand in year yr;
Edem_sum(yr) = sum((z,h), nds * Edem(z,yr,h));        // Annual electricity demand

* E_Network
* Positive variables Edem_dis(z,yr,h), Edis_Sum(z,yr);  // Load shedding

$ifthen "%mflag%" == "1"
Equations eqEbalance;
eqEbalance(z,yr,h) .. sum(J_RN_r(evg,z,yr), P_EG_gen(evg,z,yr,h)) +
                      sum(J_NCSG_r(ncsgall,z,yr), P_EG_gen(ncsgall,z,yr,h)) + sum(J_ET_r(J_CCSG_r,z,yr), P_EG_gen(ccsg,z,yr,h)) +
                      sum(J_ET_r(es,z,yr),  D_ES(es,z,yr,h) -  C_ES(es,z,yr,h)) +
                      sum(J_ET_vm(m,zx,z,yr), P_Eli(m,zx,z,yr,h) * (1 - ELi_loss(m) * ETNS_dstn(zx,z))) -
                      sum(J_ET_vm(m,z,zx,yr), P_Eli(m,z,zx,yr,h)) 
                      =E= Edem(z,yr,h) / ths * Edem_Sc - Edem_dis(z,yr,h);        // GW,  负荷Edem(z,yr,h)可考虑缩放因子

$elseif "%mflag%" == "2"
Equations eqEbalance;
eqEbalance(z,yr,h) .. sum(J_RN_r(evg,z,yr), P_EG_gen(evg,z,yr,h)) +
                      sum(J_NCSG_r(ncsgall,z,yr), P_EG_gen(ncsgall,z,yr,h)) + sum(J_CCSG_r(ccsg,z,yr), P_EG_gen(ccsg,z,yr,h)) +
                      sum(J_ET_r(es,z,yr),  D_ES(es,z,yr,h) -  C_ES(es,z,yr,h)) +
                      sum(J_ET_vm(m,zx,z,yr), P_Eli(m,zx,z,yr,h) * (1 - ELi_loss(m) * ETNS_dstn(zx,z))) -
                      sum(J_ET_vm(m,z,zx,yr), P_Eli(m,z,zx,yr,h)) 
                      - P_Cnet(z,yr,h)
                      =E= Edem(z,yr,h) / ths * Edem_Sc - Edem_dis(z,yr,h);  
$endif

Equations eqEdis_Sum;
eqEdis_Sum(z,yr) .. Edis_Sum(z,yr) =E= sum(h, nds * Edem_dis(z,yr,h));   // Annual discarded power demand

Equations eqERsv;
eqERsv(z,yr,h) .. sum(J_FMEG_r(fmeg,z,yr), R_EG_frm(fmeg,z,yr,h)) + sum(J_ET_r(es,z,yr), R_ES_frm(es,z,yr,h)) =G=
                  E_rsm * Edem(z,yr,h) / ths + E_drs * sum(J_RN_r(evg,z,yr), P_EG_gen(evg,z,yr,h));
                  


* ================================ System Emissions ================================ *
* E_Network emissions
* Model Specification (mflag): 1 => E_Net, 2 => E_Net + C_Net.
* CO2 constraining methd (cflag): 1 => Carbon caps, 2 => Carbon tax.

$ifthen "%mflag%" == "2"

* Positive variables GHG_Enet(yr);
Equations eqCO2_Enet;
eqCO2_Enet(yr) .. GHG_Enet(yr) =E= sum((J_COEM_r(ccgg,z,yr), h), nds * EM_EG_CO2(ccgg,z,yr,h));   // kton, 1~365, CCS已经被计入
                               
* Positive variables GHG(yr);
Equations eqGHG;
eqGHG(yr) .. GHG(yr) =E= GHG_Enet(yr) - CO2_DAC(yr);

$ifthen "%cflag%" == "1"
Equations eqCO2_Lim;
eqCO2_Lim(yr) .. GHG(yr) =L= CBDyr('%dcs%', yr) * 100000;                      // kilo ton, 1~10^6

$else
Positive variables GHG_TAX(yr), GHG_STAX;
Equations eqGHG_TAX, eqGHG_STAX;
eqGHG_TAX(yr) .. GHG_TAX(yr) =E= dn(yr) * CO2_Tax(yr,'%ctx%') * GHG(yr);    // M USD, 1~10^6
eqGHG_STAX .. GHG_STAX =E= sum(yr, GHG_TAX(yr));                            // M USD
$endif

$endif


* ================================ Objective functions ================================ *
* E_Network
Scalars Edis_Pen   / 100 /;   // M USD/GWh
Positive variables CaPx_Enet, CaPx_RO_Enet, FCS_Enet, FOM_Enet, VOM_Enet, Edis_Enet, TSC_Enet;
Equations eqCaPx_Enet, eqCaPx_RO_Enet, eqFCS_Enet, eqFOM_Enet, eqVOM_Enet, eqEdis_Enet, eqTSC_Enet;

eqCaPx_Enet .. CaPx_Enet =E= sum(n$(ord(n) > 1), CaPx_EG(n) + CaPx_ES(n)) +
                             sum(ni$(ord(ni) > 1), CaPx_ELi(ni));                                 // M USD
                         
eqCaPx_RO_Enet .. CaPx_RO_Enet =E= sum(yx$(ord(yx) > 1), CaPx_EG_RO(yx));                         // M USD

eqFCS_Enet  .. FCS_Enet =E= sum(yr, FCS_EG(yr));                                                  // M USD
eqFOM_Enet  .. FOM_Enet =E= sum(yr, FOM_EG(yr) + FOM_ES(yr) + FOM_ELi(yr));                       // M USD
eqVOM_Enet  .. VOM_Enet =E= sum(yr, VOM_EG(yr) + VOM_ES(yr) + VOM_ELi(yr));                       // M USD
eqEdis_Enet .. Edis_Enet =E= sum((z,yr), dn(yr) * Edis_Pen * Edis_Sum(z,yr));                     // M USD

eqTSC_Enet .. TSC_Enet =E= CaPx_Enet + CaPx_RO_Enet + FCS_Enet + FOM_Enet + VOM_Enet + Edis_Enet; // M USD

* Objective function
* Run mode (tflag): 0 => Testing, 1 >= normal optimization.
* Model Specification (mflag): 1 => E_Net, 2 => E_Net + C_Net.
* CO2 constraining methd (cflag): 1 => Carbon caps, 2 => Carbon tax.
Variables TSC;
Equations eqTSC;

$ifthen "%tflag%" == "0"
eqTSC .. TSC =E= 0;                              // Model testing
$else

$ifthen "%mflag%" == "1"
$ifthen "%cflag%" == "1"
eqTSC .. TSC =E= TSC_Enet;                         // M USD
$else

eqTSC .. TSC =E= TSC_Enet + GHG_STAX;              // M USD
$endif

$elseif "%mflag%" == "2"
$ifthen "%cflag%" == "1"
eqTSC .. TSC =E= TSC_Enet + TSC_Cnet;              // M USD
$else
eqTSC .. TSC =E= TSC_Enet + TSC_Cnet + GHG_STAX;   // M USD
$endif
$endif

$endif


* ======================= Model generation and solution ======================= *
Model China_EC_Network / all /;

// Solution options
Options lp = gurobi, optcr = 0.03, reslim = 164000, limrow = 0, limcol = 0, threads = 64; //, limcol = 0, solprint = on, sysout = off;

$onEcho > gurobi.opt
 method 2
 presovle 2
 ScaleFlag 1
 BarHomogeneous 1
 iis 1
$offEcho

Solve China_EC_Network using lp minimizing TSC;

* Display optimization results
* $include %Cfolder%/EC_Display.gms

* Save results into GDX files
$include %Cfolder%/EC_Results.gms





