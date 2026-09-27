$Title China Electricity-Carbon System Optimization

$eolCom //

// 场景设置参考 Zhuo et al. (Cost increase)

$Set Dfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Data
$Set Cfolder   /dssg/home/acct-zmliu/lsy_ynwa/EC_Final/EC_4TD/CN50/Code/Stage1_ENet 
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
$Set sr  y1, y6, y11, y16, y21, y26         //y1, y2, y4, y6, y8, y10, y12,y14,y16,y18,y20,y22,y24,y26
$Set mr  y1, y6, y11, y16, y21


Sets t       time          / h0 * h%rs% / 
     h(t)    hours         / h1 * h%rs% /     // hours in a year
     y       index years   / y0 * y%ar% /
     yr(y)   opr. years    / y1 * y%ar% /

     n(y)    ins. years    / y0, %sr%   /     // for technology   // y1, y6, y11, y16, y21, y26
     ni(y)   ins. years    / y0, %mr%   /;    // for transmission // y1, y11, y21

Sets yx(yr)    / y1, y6, y11, y16, y21 /;     // Decommission and retrofit years // 


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
     eno(eg) elec. no pvwt           / fwd, nu, bio, beccs, hydo,
                                       gtcc, gccs, coal, cocs /
     ecg(er) tech. with CCS          / gcics, coics /             // Retrofit with CCS
     es(er)  elec. storage           / phs, lib4 /                // Newly built storage
     epw(er)                         / pv, nwd   /;               // pref pv and onshore wind    

Sets c    tech. scenarios            / high, mid, low /           // Technology cost scenarios
     ces   clean energy scens        / bau, ndc, endc, cn50 /     // Four decarbonization scenarios 
     esp  tech. specification        / eta, ro, mu, lm, cfn, cfm, epn, ltm /
     m    inter-transmission lines   / ac, dc /
     cxs  carbon tax scenarios       / cmid, cadv /;              // Carbon tax scenarios

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

* 投资建设速率缩放系数
Parameter invSpan(y);

invSpan(y) = 1;
invSpan(n)$(ord(n) > 1)  = 2;
invSpan(ni)$(ord(ni) > 1) = 2;



* ================================ Input Data ================================ *
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
     J_ET_c(er,z,n,yr)      technology existed or installed in year n retrofitted in year yr
     J_ET_r(er,z,yr)        technology available in zone z year yr
     J_ET_uo(er,z,n,yr,yn)  operation years for technology installed in year n retrofit in year yr
     J_CCS_v(z,yr)          CCS technologies available in zone z year yr;
     
Sets
     J_PW_s(epw,pz,pj,n)
     J_PW_u(epw,pz,pj,n,yr)
     J_PW_r(epw,pz,pj,yr);
       

Sets cpv(pz,pj)      Solar PV generation in city pj province pz
     cwt(pz,pj)      Onshore wind generation in city pj province pz;

cpv(pz,pj)$(PV_Cap(pz,pj)) = yes;                            
cwt(pz,pj)$(WT_Cap(pz,pj)) = yes;

display cpv, cwt;

Parameters U_PW_exn(epw,pz,pj);
U_PW_exn('pv',pz,pj)$cpv(pz,pj) = PV_Excap(pz,pj);
U_PW_exn('nwd',pz,pj)$cwt(pz,pj) = WT_Excap(pz,pj);

display U_PW_exn;

* Useful operation years for existing technologies
J_ET_u(er,z,'y0',yr)$(U_ET_exn(er,z) and (ord(yr) <= ET_Specs(er,'ltm'))) = yes;   // No gcics or coics
J_PW_u('pv',pz,pj,'y0',yr)$(cpv(pz,pj) and U_PW_exn('pv',pz,pj) and (ord(yr) <= ET_Specs('pv','ltm'))) = yes;
J_PW_u('nwd',pz,pj,'y0',yr)$(cwt(pz,pj) and U_PW_exn('nwd',pz,pj) and (ord(yr) <= ET_Specs('nwd','ltm'))) = yes;

* Useful operation years for newly installed technologies
J_ET_u(er,z,n(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs(er,'ltm') - 1), card(yr)))) = yes;
J_PW_u('pv',pz,pj,n(y),yr)$(cpv(pz,pj) and (ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs('pv','ltm') - 1), card(yr)))) = yes;
J_PW_u('nwd',pz,pj,n(y),yr)$(cwt(pz,pj) and (ord(y) > 1) and (ord(yr) >= ord(y)-1) and (ord(yr) <= min((ord(y)-1 + ET_Specs('nwd','ltm') - 1), card(yr)))) = yes;

* Filter operation years for power and storage technologies unavailable in zones
J_ET_u('nu',z,n,yr)$((ord(n) > 1)   and (NOT cnu(z))) = no;
J_ET_u('fwd',z,n,yr)$((ord(n) > 1)  and (NOT fwz(z))) = no;
J_ET_u('phs',z,n,yr)$((ord(n) > 1)  and xcphs(z)) = no;
J_ET_u('coal',z,n,yr)$((ord(n) > 1) and xcoal(z)) = no;
J_ET_u('gtcc',z,n,yr)$((ord(n) > 1) and xccgt(z)) = no;
* J_ET_u('hydo',z,n,yr)$((ord(n) > 1) and xhydo(z)) = no;
J_ET_u('hydo',z,n,yr)$(ord(n) > 1) = no;
J_ET_u(ecg,z,n,yr)$(ord(n) > 1) = no;       // No gcics and coics installation: only be retrofitted from gas and coal generation

J_ET_c('gcics',z,'y0',yr)$((ord(yr) > 1) and J_ET_u('gtcc',z,'y0',yr)) = yes;                       // Retrofit of existing gas and coal generation
J_ET_c('coics',z,'y0',yr)$((ord(yr) > 1) and J_ET_u('coal',z,'y0',yr)) = yes;
J_ET_c('gcics',z,n(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)) and J_ET_u('gtcc',z,n,yr)) = yes;   // Retrofit of newly built gas and coal generation
J_ET_c('coics',z,n(y),yr)$((ord(y) > 1) and (ord(yr) >= ord(y)) and J_ET_u('coal',z,n,yr)) = yes;


* Power generation and storage technologies: installation years
Loop(J_ET_u(er,z,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), J_ET_s(er,z,n) = yes);   // Index year for tech. installation when n > 0: No gcics and coics
Loop(J_PW_u(epw,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), J_PW_s(epw,pz,pj,n) = yes);

* J_ET_u: for eg + es: operation years; for ecg:  retrofit years
* J_ET_u的不同含义：对于eg+es，J_ET_u指的是第n年安装的技术的运行年份；对于ecg，J_ET_u指的是第n年安装的技术进行改造的年份
J_ET_u(ecg,z,'y0',yr)$(J_ET_c(ecg,z,'y0',yr)) = yes;
J_ET_u(ecg,z,n,yr)$((ord(n) > 1) and J_ET_c(ecg,z,n,yr)) = yes;      // Retrofit years of gas and coal generation

* Power generation and storage technologies available in year yr
J_ET_r(er,z,yr)$(sum(J_ET_u(er,z,n(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;
J_PW_r(epw,pz,pj,yr)$(sum(J_PW_u(epw,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), 1) >= 1) = yes;

Display J_ET_s, J_ET_u, J_ET_c, J_ET_r;
display J_PW_s, J_PW_u, J_PW_r;


* The first year and final years: electricity and storage technologies
Parameters yen(er,z,n), yeo(er,z,n), yem(er,z,n);
yen(er,z,'y0')$(J_ET_u(er,z,'y0','y1')) = 1;                                                 // No gcics and coics
Loop(J_ET_u(er,z,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), yen(er,z,n) = ord(yr));   // The first operation year
yeo(er,z,n)$(yen(er,z,n)) = sum(yr$(J_ET_u(er,z,n,yr)), 1);                                  // The operation period
yem(er,z,n)$(yen(er,z,n)) = yeo(er,z,n) + yen(er,z,n) - 1;                                   // The last operation year

yen('gcics',z,'y0')$(J_ET_u('gtcc',z,'y0','y1')) = 2;                                        // The first retrofit year: gcics and coics
yen('coics',z,'y0')$(J_ET_u('coal',z,'y0','y1')) = 2;
Loop(J_ET_u(ecg,z,n(y),yr)$((ord(y) > 1) and (ord(y) = ord(yr))), yen(ecg,z,n) = ord(yr));   // The first retrofit year: gcics and coics
yeo(ecg,z,n)$(yen(ecg,z,n)) = sum(yr$(J_ET_u(ecg,z,n,yr)), 1);                               // The operation period from the first retrofit:   gcics and coics
yem(ecg,z,n)$(yen(ecg,z,n)) = yeo(ecg,z,n) + yen(ecg,z,n) - 1;                               // The last operation year for the first retrofit: gcics and coics

Display yen, yeo, yem;


* The first year and final years: Prefx Solar and Onshore wind
Parameters ypwn(epw,pz,pj,n), ypwo(epw,pz,pj,n), ypwm(epw,pz,pj,n);
ypwn(epw,pz,pj,'y0')$(J_PW_u(epw,pz,pj,'y0','y1')) = 1;
Loop(J_PW_u(epw,pz,pj,n(y),yr)$((ord(y) > 1) and (ord(y)-1 = ord(yr))), ypwn(epw,pz,pj,n) = ord(yr));   // The first operation year
ypwo(epw,pz,pj,n)$(ypwn(epw,pz,pj,n)) = sum(yr$(J_PW_u(epw,pz,pj,n,yr)), 1);                                  // The operation period
ypwm(epw,pz,pj,n)$(ypwn(epw,pz,pj,n)) = ypwo(epw,pz,pj,n) + ypwn(epw,pz,pj,n) - 1;

Display ypwn, ypwo, ypwm;


* Operation years for gas and coal generation installed in year n retrofitted in year yr
J_ET_uo(ecg,z,n,yr,yn)$(J_ET_u(ecg,z,n,yr) and (ord(yn) >= ord(yr)) and (ord(yn) <= yem(ecg,z,n))) = yes;


* Discounted share of lifetime for electricity technologies
Parameters ET_afr(er), ET_dsm(er,n), ET_TM(er,n), yerm(ecg,z,n,yr), ET_R_dsm(ecg,z,n,yr), ET_R_dsm_TM(ecg,z,n,yr);

ET_afr(er) = (1 - 1 / (1 + ir)) / (1 - 1 / ((1 + ir) ** ET_Specs(er,'ltm')));   // Annualized factor for technologies, 年化因子, 把投资平摊到每年

ET_dsm(eg,n(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, ET_Specs(eg,'ltm'))))) / (1 - 1 / (1 + ir));  //贴现寿命份额权重，实际运行年份比例
ET_dsm(es,n(y))$(ord(y) > 1) = (1 - 1 / ((1 + ir) ** (min(card(yr) - (ord(y)-1) + 1, ET_Specs(es,'ltm'))))) / (1 - 1 / (1 + ir));

ET_TM(eg,n) = ET_afr(eg) * ET_dsm(eg,n);
ET_TM(es,n) = ET_afr(es) * ET_dsm(es,n);

* Operation years for retrofitted technologies
yerm(ecg,z,n,yr)$(J_ET_u(ecg,z,n,yr)) = sum(yn$J_ET_uo(ecg,z,n,yr,yn), 1);

* Discounted share of lifetime for retrofitted technologies
ET_R_dsm(ecg,z,n,yr)$(J_ET_u(ecg,z,n,yr)) = (1 - 1 / ((1 + ir) ** yerm(ecg,z,n,yr))) / (1 - 1 / (1 + ir));
ET_R_dsm_TM(ecg,z,n,yr) = ET_afr(ecg) * ET_R_dsm(ecg,z,n,yr);

Display ET_afr, ET_dsm, ET_TM, yerm, ET_R_dsm, ET_R_dsm_TM;


* ========= Capacity sizing: Power generation technologies
Positive variables U_EG_nom(er,z,n), U_PW_nom(epw,pz,pj,n);    // 除epw城市级别建模外，eno均为省份尺度建模
Equations eqU_EG_nom, eqU_EG_bLim;

eqU_EG_nom(J_ET_s(eno,z,n)) .. U_EG_nom(eno,z,n) =L= U_EG_Max(eno,z);                           // GW, 1.0 ~ 1.0
eqU_EG_bLim(eno,n)$(ord(n) > 1) .. sum(J_ET_s(eno,z,n), U_EG_nom(eno,z,n)) =L= U_EG_bLim(eno) * invSpan(n);   // GW, 1.0 ~ 1.0

Equations eqU_PW_noma, eqU_PW_nomb;

eqU_PW_noma(J_PW_s('pv',pz,pj,n)) .. U_PW_nom('pv',pz,pj,n) =L= PV_Cap(pz,pj);    // GW
eqU_PW_nomb(J_PW_s('nwd',pz,pj,n)) .. U_PW_nom('nwd',pz,pj,n) =L= WT_Cap(pz,pj);    // GW

* Power capacity continuation
Sets evg(eg)   / pv, nwd, fwd /                       // Constraints on RE caps
     epg(eg)   / pv, nwd, fwd, bio, nu /              // Clean energy potential limition
     edg(eg)   / fwd, nu, bio, beccs, hydo,
                 gccs, cocs /                         // Only decommission
     erg(eg)   / gtcc, coal /;                        // Deconmission and retrofit with CCS

Sets J_RN_r(evg,z,yr);
J_RN_r('fwd',z,yr) = J_ET_r('fwd',z,yr);
J_RN_r('pv',z,yr)$(sum(J_PW_r('pv',z,pj,yr), 1) >= 1) = yes;
J_RN_r('nwd',z,yr)$(sum(J_PW_r('nwd',z,pj,yr), 1) >= 1) = yes;

display J_RN_r;

Parameters dcap_eg(erg)   / gtcc 10, coal 20 /,       // Decommission caps for province, GW
           rcap_eg(erg)   / gtcc 10, coal 20 /;       // Retrofit caps for province, GW
           
* 装机容量及建设速度限制
Positive variables U_EG_anom(eg,z,n,yr), U_EG_dnm(eg,z,n,yr), U_EG_CCS(erg,z,n,yr);
Positive variables U_PW_anom(epw,pz,pj,n,yr);

Equations eqU_EG_egnn,         // Technology installation capacity when n >= 1
          eqU_EG_edg0,         // Technology decommission when n = 0
          eqU_EG_edgn;         // Technology decommission when n >=1
          
Equations eqU_PW_egnn,         // Technology installation capacity when n >= 1
          eqU_PW_edg0,         // Technology decommission when n = 0
          eqU_PW_edgn;

* U_EG_anom(eg,z,n,yr)  ———— 第n年安装的技术在第yr年的容量
* U_EG_dnm(eg,z,n,yr)   ———— 第n年安装的技术在第yr年退役的容量
* U_EG_CCS(erg,z,n,yr)  ———— 第n年安装的coal、ccgt在第yr年改造的容量

* Fix U_EG_anom(eg,z,n,n) to U_EG_nom(eg,z,n): All newly installed generation technologies
* 第n年安装的技术在第n年的容量 等于 第n年安装的容量
eqU_EG_egnn(J_ET_u(eno,z,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_EG_anom(eno,z,n,yr) =E= U_EG_nom(eno,z,n);   // GW, ~1.0
eqU_PW_egnn(J_PW_u(epw,pz,pj,n(y),yr))$((ord(y) > 1) and (ord(y)-1 = ord(yr))) .. U_PW_anom(epw,pz,pj,n,yr) =E= U_PW_nom(epw,pz,pj,n);

* Technology decommission and retrofit with CCS when n = 0
* 现有技术第1年的装机容量 等于 现存的容量
U_EG_anom.fx(eno,z,'y0','y1') = U_ET_exn(eno,z);
U_PW_anom.fx(epw,pz,pj,'y0','y1') = U_PW_exn(epw,pz,pj);


* 除了gtcc和coal可以中途退役或改造，其余技术持续到自然寿命结束
* n = 0
eqU_EG_edg0(J_ET_u(edg,z,'y0',yr))$(ord(yr) < yem(edg,z,'y0')) .. U_EG_anom(edg,z,'y0',yr+1) =E= U_EG_anom(edg,z,'y0',yr);          // GW, ~1.0,  - U_EG_dnm(edg,z,'y0',yr+1)
* n >= 1
eqU_EG_edgn(J_ET_u(edg,z,n,yr))$((ord(n) > 1) and (ord(yr) < yem(edg,z,n))) .. U_EG_anom(edg,z,n,yr+1) =E= U_EG_anom(edg,z,n,yr);   // GW, ~1.0,  - U_EG_dnm(edg,z,n,yr+1)

* n = 0
eqU_PW_edg0(J_PW_u(epw,pz,pj,'y0',yr))$(ord(yr) < ypwm(epw,pz,pj,'y0')) .. U_PW_anom(epw,pz,pj,'y0',yr+1) =E= U_PW_anom(epw,pz,pj,'y0',yr);          // GW, ~1.0 
* n >= 1
eqU_PW_edgn(J_PW_u(epw,pz,pj,n,yr))$((ord(n) > 1) and (ord(yr) < ypwm(epw,pz,pj,n))) .. U_PW_anom(epw,pz,pj,n,yr+1) =E= U_PW_anom(epw,pz,pj,n,yr);   // GW, ~1.0


* CCGT and Coal generation decommission and retrofit with CCS
Equations eqU_EG_erg0,   // Technology decomission and retrofit with CCS when n = 0
          eqU_EG_ergn;   // Technology decomission and retrofit with CCS when n >= 1

* n = 0，gtcc和coal可以退役或进行CCS改造
eqU_EG_erg0(J_ET_u(erg,z,'y0',yr))$(ord(yr) < yem(erg,z,'y0')) .. U_EG_anom(erg,z,'y0',yr+1) =E= U_EG_anom(erg,z,'y0',yr)
                                                                                               - U_EG_dnm(erg,z,'y0',yr+1) - U_EG_CCS(erg,z,'y0',yr+1);      // GW, ~1.0
* n >= 1，新安装的gtcc和coal可以退役或进行CCS改造
eqU_EG_ergn(J_ET_u(erg,z,n,yr))$((ord(n) > 1) and (ord(yr) < yem(erg,z,n))) .. U_EG_anom(erg,z,n,yr+1) =E= U_EG_anom(erg,z,n,yr)
                                                                                                         - U_EG_dnm(erg,z,n,yr+1) - U_EG_CCS(erg,z,n,yr+1);  // GW, ~1.0

* 限制退役和改造的容量，只允许特定年份（yx）退役及改造
U_EG_dnm.fx(J_ET_u(edg,z,n,yr)) = 0.0;
U_EG_dnm.fx(J_ET_u(erg,z,n,yr)) = 0.0;
U_EG_CCS.fx(J_ET_u(erg,z,n,yr)) = 0.0;
U_EG_dnm.up(J_ET_u(erg,z,n,yx)) = dcap_eg(erg);
U_EG_CCS.up(J_ET_u(erg,z,n,yx)) = rcap_eg(erg);

* For computing retrofitted capacities: GW，截至yr年改造的总容量
Positive variables U_EG_RO(er,z,yr);  
Equations eqU_EG_ROa, eqU_EG_ROb;
eqU_EG_ROa(J_ET_r('gcics',z,yr)) .. U_EG_RO('gcics',z,yr) =E= sum(J_ET_u('gcics',z,n(y),yr)$(ord(y) <= ord(yr)), U_EG_CCS('gtcc',z,n,yr));    // GW, ~1.0
eqU_EG_ROb(J_ET_r('coics',z,yr)) .. U_EG_RO('coics',z,yr) =E= sum(J_ET_u('coics',z,n(y),yr)$(ord(y) <= ord(yr)), U_EG_CCS('coal',z,n,yr));    // GW, ~1.0

* Record CCS retrofit capacities, yr年改造, 第yn年的容量
* 第yn年CCS的容量 = 第yr年改造的容量
* 第yn（yn > yr）年CCS的容量 = 第yr年改造的容量, 改造后保持同样容量至寿命结束
Positive variables U_EG_CCS_anom(er,z,n,yr,yn);
Equations eqU_EG_CCS_anoma, eqU_EG_CCS_anomb, eqU_EG_CCS_anomc, eqU_EG_CCS_anomd;

eqU_EG_CCS_anoma(J_ET_uo('gcics',z,n,yr,yn))$(ord(yr) = ord(yn)) .. U_EG_CCS_anom('gcics',z,n,yr,yn) =E= U_EG_CCS('gtcc',z,n,yr);              // GW, ~1.0
eqU_EG_CCS_anomb(J_ET_uo('gcics',z,n,yr,yn))$(ord(yn) < yem('gcics',z,n)) ..
                                                                    U_EG_CCS_anom('gcics',z,n,yr,yn+1) =E= U_EG_CCS_anom('gcics',z,n,yr,yn);    // GW, ~1.0

eqU_EG_CCS_anomc(J_ET_uo('coics',z,n,yr,yn))$(ord(yr) = ord(yn)) .. U_EG_CCS_anom('coics',z,n,yr,yn) =E= U_EG_CCS('coal',z,n,yr);              // GW, ~1.0
eqU_EG_CCS_anomd(J_ET_uo('coics',z,n,yr,yn))$(ord(yn) < yem('coics',z,n)) ..
                                                                    U_EG_CCS_anom('coics',z,n,yr,yn+1) =E= U_EG_CCS_anom('coics',z,n,yr,yn);   // GW, ~1.0

* For computing cumulative capacity, GW, 截至yr年技术总容量（包含改造）
Positive variables U_EG_acm(er,z,yr), U_PW_acm(epw,pz,pj,yr);
Equations eqU_EG_acma, eqU_EG_acmb, eqU_EG_acmc;
Equations eqU_PW_acm;
Equations eqU_EGPW_acm1, eqU_EGPW_acm2;

eqU_EG_acma(J_ET_r(eno,z,yr)) .. U_EG_acm(eno,z,yr) =E= sum(J_ET_u(eno,z,n(y),yr)$(ord(y)-1 <= ord(yr)), U_EG_anom(eno,z,n,yr));   // GW, ~1.0
eqU_EG_acmb(J_ET_r('gcics',z,yn)) .. U_EG_acm('gcics',z,yn) =E= sum(J_ET_uo('gcics',z,n,yr,yn), U_EG_CCS_anom('gcics',z,n,yr,yn));   // GW, ~1.0
eqU_EG_acmc(J_ET_r('coics',z,yn)) .. U_EG_acm('coics',z,yn) =E= sum(J_ET_uo('coics',z,n,yr,yn), U_EG_CCS_anom('coics',z,n,yr,yn));   // GW, ~1.0

eqU_PW_acm(J_PW_r(epw,pz,pj,yr)) .. U_PW_acm(epw,pz,pj,yr) =E= sum(J_PW_u(epw,pz,pj,n(y),yr)$(ord(y)-1 <= ord(yr)), U_PW_anom(epw,pz,pj,n,yr));

eqU_EGPW_acm1(z,yr) .. U_EG_acm('pv',z,yr) =E= sum(pj$cpv(z,pj), U_PW_acm('pv',z,pj,yr));
eqU_EGPW_acm2(z,yr) .. U_EG_acm('nwd',z,yr) =E= sum(pj$cwt(z,pj), U_PW_acm('nwd',z,pj,yr));

* ========= Operations: Power generation technologies
Sets cgmg(er)    / gtcc, coal /                              // Emission with no CCS
     ncsg(er)    / nu, bio, gtcc, coal /                     // Generation with no CCS, eta
     ncsgh(er)   / nu, bio, hydo, gtcc, coal /               // Generation with no CCS
     ccsg(er)    / gcics, gccs, coics, cocs, beccs /         // Generation with CCS
     ccsga(er)   / gcics, gccs, coics, cocs /
     ccsgb(er)   / beccs /
*    avbg(er)    / nu, bio, hydo, gtcc, gcics, gccs, coal, coics, cocs /     // availabiliy -- lm
     clng(er)    / nu, bio, beccs, hydo /                    // Capacity factor: clean generation with min/max generation -- cfn/cfm
     cngg(er)    / gtcc, gcics, gccs, coal, coics, cocs /    // Capacity factor: coal and natural gas with max generation -- cfm
     ccgg(er)    / gtcc, gcics, gccs, coal, coics, cocs, beccs /    // co2 emission caculation
     rmpg(er)    / nu, bio, hydo, gtcc, coal /               // Technology ramping
     ngfg(er)    / gtcc, gcics, gccs /                       // Compute NG consumpton
     cofg(er)    / coal, coics, cocs /                       // Compute coal consumption
     watg(er)    / coal, coics, cocs, gtcc, gcics, gccs, nu, bio, beccs /     // power generation cosuming water
     fmeg(er)    / nu, bio, beccs, hydo, gtcc, gcics, gccs,
                   coal, coics, cocs /;                      // Firm generation: resreve

Scalars c_Nu   / 2.392 /      // USD/MWh
        c_NG   / 31.86 /      // USD/MWh, k USD/GWh
        c_CO   / 10.45 /;     // USD/MWh

c_Nu = c_Nu / ths;     // M USD/GWh, ~ 0.002
c_NG = c_NG / ths;     // M USD/GWh, ~ 0.03
c_CO = c_CO / ths;     // M USD/GWh, ~ 0.17

* CCS technologies available in zone z year yr
J_CCS_v(z,yr)$(sum(J_ET_r(ccsg,z,yr), 1) >= 1) = yes;

$ontext //暂时不考虑燃料价格变化
Scalars cfr      / 0.03 /;      // fuel increase factor
Scalars c_Nu_0   / 2.392 /      // USD/MWh
        c_NG_0   / 31.86 /      // USD/MWh
        c_CO_0   / 10.45 /;     // USD/MWh

Parameters c_Nu(yr), c_NG(yr), c_CO(yr), c_H2(yr);
c_Nu(yr) = c_Nu_0 * (1 + cfr) ** (ord(yr) - 1) / ths;     // M USD/GWh, ~ 0.002
c_NG(yr) = c_NG_0 * (1 + cfr) ** (ord(yr) - 1) / ths;     // M USD/GWh, ~ 0.03
c_CO(yr) = c_CO_0 * (1 + cfr) ** (ord(yr) - 1) / ths;     // M USD/GWh, ~ 0.01
$offtext

Parameters rho_ccs(er)    / gcics 0.95, gccs 0.95, coics 0.95, cocs 0.95, beccs 0.9 /             // Capture ratio
           phi_ccs(er)    / gcics 0.387, gccs 0.387, coics 0.156, cocs 0.156, beccs 0.261 /;      // CO2 capture energy: GWh/kton

* 发电量、燃料、碳排放
Positive variables P_EG_gen(er,z,yr,h), F_EG_fcs(er,z,yr,h), EM_EG_CO2(er,z,yr,h);
Positive Variables P_PW_gen(epw,pz,pj,yr,h);

* Prefx Solar and WT generation: GWh, pv/nwd
Equations eqP_PV_pref, eqP_WT_pref;
eqP_PV_pref(J_PW_r('pv',pz,pj,yr),h) .. P_PW_gen('pv',pz,pj,yr,h) =E= PV_CF(pz,pj,yr,h) * U_PW_acm('pv',pz,pj,yr);
eqP_WT_pref(J_PW_r('nwd',pz,pj,yr),h) .. P_PW_gen('nwd',pz,pj,yr,h) =E= WT_CF(pz,pj,yr,h) * U_PW_acm('nwd',pz,pj,yr);

* Renewable generation: GWh, pv/nwd/fwd
Equations eqP_EG_pv, eqP_EG_nwd, eqP_EG_fwd;
eqP_EG_pv(J_RN_r('pv',pz,yr),h)   .. P_EG_gen('pv',pz,yr,h) =E= sum(pj$cpv(pz,pj), P_PW_gen('pv',pz,pj,yr,h));       // GW, ~0.05 - 0.9
eqP_EG_nwd(J_RN_r('nwd',pz,yr),h)  .. P_EG_gen('nwd',pz,yr,h) =E= sum(pj$cwt(pz,pj), P_PW_gen('nwd',pz,pj,yr,h));    // GW, ~0.05 - 0.9
eqP_EG_fwd(J_ET_r('fwd',z,yr), h) .. P_EG_gen('fwd',z,yr,h) =E= offshwd(z,yr,h) * U_EG_acm('fwd',z,yr);   // GW, ~0.05 - 0.9

* (1)发电量、碳排放计算
* Generation technologies with no CCS: GWh, nu, bio, gtcc, coal(eta)
Equations eqP_EG_ncsg, eqP_EG_ncsg_max, eqEM_EG_CO2_cgmg;

eqP_EG_ncsg(J_ET_r(ncsg,z,yr), h) .. P_EG_gen(ncsg,z,yr,h) =E= ET_Specs(ncsg,'eta') * F_EG_fcs(ncsg,z,yr,h);    // Power generation: GWh, ~ 0.3 - 0.7
eqP_EG_ncsg_max(J_ET_r(ncsgh,z,yr), h) .. P_EG_gen(ncsgh,z,yr,h) =L= ET_Specs(ncsgh,'lm') * U_EG_acm(ncsgh,z,yr);   // Power availability: GWh, ~ 0.9 
// CO2 emissions: gtcc and coal: kilo ton
eqEM_EG_CO2_cgmg(J_ET_r(cgmg,z,yr), h) .. EM_EG_CO2(cgmg,z,yr,h) =E= ET_Specs(cgmg,'epn') * F_EG_fcs(cgmg,z,yr,h);    // kilo ton, ~ 0.2

* Generation technologies with CCS: retrofit with CCS or new plants with CCS: gcics, gccs, coics, cocs, beccs
Positive variables P_EG_gen_ncs(er,z,yr,h), E_EG_CO2(er,z,yr,h);
Equations eqP_EG_gen_ncs, eqP_EG_gen_ncs_max, eqP_EG_gen_ccsg, eqE_EG_CO2_ccsga, eqE_EG_CO2_ccsgb, eqEM_EG_CO2_ccsga, eqEM_EG_CO2_ccsgb;

* Generation technologies: compute power and fuel with no CCS,先计算不包含ccs的部分，再扣除ccs的能耗以及碳排放
eqP_EG_gen_ncs(J_ET_r(ccsg,z,yr), h) .. P_EG_gen_ncs(ccsg,z,yr,h) =E= ET_Specs(ccsg,'eta') * F_EG_fcs(ccsg,z,yr,h);                  // Power with no CCS: GWh, ~0.4-0.5
eqP_EG_gen_ncs_max(J_ET_r(ccsg,z,yr), h)  .. P_EG_gen_ncs(ccsg,z,yr,h) =L= ET_Specs(ccsg,'lm') * U_EG_acm(ccsg,z,yr);                // Power availability: GWh, ~0.9
eqE_EG_CO2_ccsga(J_ET_r(ccsga,z,yr), h) .. E_EG_CO2(ccsga,z,yr,h) =L= rho_ccs(ccsga) * ET_Specs(ccsga,'epn') * F_EG_fcs(ccsga,z,yr,h);     // Captured CO2: kilo ton, 碳排放针对燃料测
eqE_EG_CO2_ccsgb(J_ET_r(ccsgb,z,yr), h) .. E_EG_CO2(ccsgb,z,yr,h) =L= rho_ccs(ccsgb) * ET_Specs(ccsgb,'epn') * P_EG_gen_ncs(ccsgb,z,yr,h); // Captured CO2: kilo ton, BECCS, 碳排放针对发电侧

* gcics, gccs, coics, cocs, beccs技术的最终发电量以及碳排放. beccs为负碳排放
eqP_EG_gen_ccsg(J_ET_r(ccsg,z,yr), h) .. P_EG_gen(ccsg,z,yr,h) =E= P_EG_gen_ncs(ccsg,z,yr,h) - phi_ccs(ccsg) * E_EG_CO2(ccsg,z,yr,h);         // Power with CCS: GWh, 0.2~0.3
eqEM_EG_CO2_ccsga(J_ET_r(ccsga,z,yr), h) .. EM_EG_CO2(ccsga,z,yr,h) =E= ET_Specs(ccsga,'epn') * F_EG_fcs(ccsga,z,yr,h) -  E_EG_CO2(ccsga,z,yr,h);   // Emission with CCS: kilo ton, ~0.17-0.3
eqEM_EG_CO2_ccsgb(J_ET_r(ccsgb,z,yr), h) .. EM_EG_CO2(ccsgb,z,yr,h) =E= 0 - E_EG_CO2(ccsgb,z,yr,h);    // Emission for BECCS, 不计入生物质中性碳排放，结果为负碳排放

* (2)最大、最小出力因子
* Generation capacity factors: Maximun and Minimun
Equations eqP_EG_CFm_clng, eqP_EG_CFn_clng, eqP_EG_CFm_cngg;

* Clean generation: capacity factors based on net output power: P_EG_gen -- nu/hydo/bio/beccs, min/max generation
eqP_EG_CFm_clng(J_ET_r(clng,z,yr)) .. sum(h, nds * P_EG_gen(clng,z,yr,h)) =L= nhys * ET_Specs(clng,'cfm') * ET_Specs(clng,'lm') * U_EG_acm(clng,z,yr);   // GW, ~1 - 8000
eqP_EG_CFn_clng(J_ET_r(clng,z,yr)) .. sum(h, nds * P_EG_gen(clng,z,yr,h)) =G= nhys * ET_Specs(clng,'cfn') * ET_Specs(clng,'lm') * U_EG_acm(clng,z,yr);   // GW, ~1 - 2400
* gcics, gccs, coics, and coccs: capacity factors based on net output power: P_EG_gen, /max generation
eqP_EG_CFm_cngg(J_ET_r(cngg,z,yr)) .. sum(h, nds * P_EG_gen(cngg,z,yr,h)) =L= nhys * ET_Specs(cngg,'cfm') * ET_Specs(cngg,'lm') * U_EG_acm(cngg,z,yr);   // GW, ~1 - 8000

* (3)机组爬坡约束
* Technology ramping with no CCS
Equations eqP_EG_rampa, eqP_EG_rampb, eqP_EG_rampc, eqP_EG_rampd;

* Ramping with no CCS
eqP_EG_rampa(J_ET_r(rmpg,z,yr), h)$(ord(h) > 1) .. P_EG_gen(rmpg,z,yr,h) - P_EG_gen(rmpg,z,yr,h-1) =L=  ET_Specs(rmpg,'ro') * U_EG_acm(rmpg,z,yr);   // GW, ~0.25-1
eqP_EG_rampb(J_ET_r(rmpg,z,yr), h)$(ord(h) > 1) .. P_EG_gen(rmpg,z,yr,h) - P_EG_gen(rmpg,z,yr,h-1) =G= -ET_Specs(rmpg,'ro') * U_EG_acm(rmpg,z,yr);   // GW, ~0.25-1
* Ramping with CCS: based on generation plants
eqP_EG_rampc(J_ET_r(ccsg,z,yr), h)$(ord(h) > 1) .. P_EG_gen_ncs(ccsg,z,yr,h) - P_EG_gen_ncs(ccsg,z,yr,h-1) =L=  ET_Specs(ccsg,'ro') * U_EG_acm(ccsg,z,yr);   // GW, ~0.25-1
eqP_EG_rampd(J_ET_r(ccsg,z,yr), h)$(ord(h) > 1) .. P_EG_gen_ncs(ccsg,z,yr,h) - P_EG_gen_ncs(ccsg,z,yr,h-1) =G= -ET_Specs(ccsg,'ro') * U_EG_acm(ccsg,z,yr);   // GW, ~0.25-1

* (4)备用容量
Positive variables R_EG_frm(er,z,yr,h);
Equations eqR_EG_frma, eqR_EG_frmb;

eqR_EG_frma(J_ET_r(fmeg,z,yr), h) .. R_EG_frm(fmeg,z,yr,h) =L= ET_Specs(fmeg,'lm') * U_EG_acm(fmeg,z,yr) - P_EG_gen(fmeg,z,yr,h);   // GW, 0.9  ~ 1.0
eqR_EG_frmb(J_ET_r(fmeg,z,yr), h) .. R_EG_frm(fmeg,z,yr,h) =L= ET_Specs(fmeg,'ro') * U_EG_acm(fmeg,z,yr);

* Fuel consumption: Nuclear, NG, Coal
Positive variables F_EG_Nu(z,yr), F_EG_NG(z,yr), F_EG_Coal(z,yr);
Equations eqF_EG_Nu, eqF_EG_NG, eqF_EG_Coal;

eqF_EG_Nu(cnu(z),yr) .. F_EG_Nu(z,yr) =E= sum((J_ET_r('nu',z,yr), h), nds * F_EG_fcs('nu',z,yr,h));       // GWh, 1 ~ 1
eqF_EG_NG(z,yr) .. F_EG_NG(z,yr) =E= sum((J_ET_r(ngfg,z,yr), h), nds * F_EG_fcs(ngfg,z,yr,h));            // GWh, 1 ~ 1
eqF_EG_Coal(z,yr) .. F_EG_Coal(z,yr) =E= sum((J_ET_r(cofg,z,yr), h), nds * F_EG_fcs(cofg,z,yr,h));        // GWh, 1 ~ 1

* Clean energy resource limition
Equation eqU_EG_CE_rLim_pv, eqU_EG_CE_rLim_nwd, eqU_EG_CE_rLim_fwd, eqU_EG_CE_rLim_nu, eqU_EG_CE_rLim_bio;

*eqU_EG_CE_rLim_pv(J_ET_r('pv',z,yr))  .. U_EG_acm('pv',z,yr) =L= CE_rLim('pv',z);
*eqU_EG_CE_rLim_nwd(J_ET_r('nwd',z,yr)) .. U_EG_acm('nwd',z,yr) =L= CE_rLim('nwd',z);
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

eqCaPx_EG(n)$(ord(n) > 1) .. CaPx_EG(n) =E= sum(J_ET_s(eno,z,n), dn(n) * ET_afr(eno) * ET_dsm(eno,n) * ET_uCaPx(eno,n) * U_EG_nom(eno,z,n)) +
                                            sum(J_PW_s(epw,pz,pj,n), dn(n) * ET_afr(epw) * ET_dsm(epw,n) * ET_uCaPx(epw,n) * U_PW_nom(epw,pz,pj,n));    // M USD, 投资成本-计算安装时的容量即可

eqCaPx_EG_RO(yx(yr))$(ord(yr) > 1) .. CaPx_EG_RO(yx) =E= sum(J_ET_u('gcics',z,n,yr),
                                                         dn(yr) * ET_afr('gcics') * ET_R_dsm('gcics',z,n,yr) * ET_uCaPx('gcics',yr) * U_EG_CCS('gtcc',z,n,yr)) +
                                                         sum(J_ET_u('coics',z,n,yr),
                                                         dn(yr) * ET_afr('coics') * ET_R_dsm('coics',z,n,yr) * ET_uCaPx('coics',yr) * U_EG_CCS('coal',z,n,yr));   // M USD, 400~600

eqFCS_EG(yr) .. FCS_EG(yr) =E= sum(cnu(z), dn(yr) * (c_Nu * F_EG_Nu(z,yr))) +           // M USD/GWh, ~0.002
                               sum(z,      dn(yr) * (c_NG * F_EG_NG(z,yr))) +           // M USD/GWh, ~0.03
                               sum(z,      dn(yr) * (c_CO * F_EG_Coal(z,yr)));          // M USD/GWh, ~0.01

eqFOM_EG(yr) .. FOM_EG(yr) =E= sum(J_ET_r(eno,z,yr), dn(yr) * ET_FOM(eno,'%scn%',yr) * U_EG_acm(eno,z,yr)) +
                               sum(J_PW_r(epw,pz,pj,yr), dn(yr) * ET_FOM(epw,'%scn%',yr) * U_PW_acm(epw,pz,pj,yr)) +
                               sum(J_ET_r(ecg,z,yr), dn(yr) * ET_FOM(ecg,'%scn%',yr) * U_EG_acm(ecg,z,yr));                  // M USD/GWh, ~0.01-0.15

eqVOM_EG(yr) .. VOM_EG(yr) =E= sum((J_ET_r(ncsgh,z,yr),h), nds * dn(yr) * ET_VOM(ncsgh,'%scn%',yr) * P_EG_gen(ncsgh,z,yr,h)) +
                               sum((J_ET_r(ccsg,z,yr),h), nds * dn(yr) * ET_VOM(ccsg,'%scn%',yr) * P_EG_gen(ccsg,z,yr,h));   // M USD/GWh, ~0.002-0.02

eqFCS_EG.scale(yr) = 0.001;
eqFOM_EG.scale(yr) = 0.01;
eqVOM_EG.scale(yr) = 0.01;


* ========================== Power storage technolgies ========================== *
* ========= Capacity sizing: Power storage technologies
Positive variables U_ES_nom(es,z,n);
Equations eqU_ES_nom, eqU_ES_bLim;

eqU_ES_nom(J_ET_s(es,z,n)) .. U_ES_nom(es,z,n) =L= U_ES_Max(es,z);                           // GW
eqU_ES_bLim(es,n)$(ord(n) > 1) .. sum(J_ET_s(es,z,n), U_ES_nom(es,z,n)) =L= U_ES_bLim(es) * invSpan(n);   // GW, 1.0 ~ 1.0

* Capacity continuation
Positive variables U_ES_anom(es,z,n,yr), U_ES_dnm(es,z,n,yr);
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

Positive variables U_ES_acm(es,z,yr), U_lib_acm_ys(es,yr);      // For computing cumulative capacity, GW
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

Positive variables En_ES(es,z,yr,t), C_ES(es,z,yr,h), D_ES(es,z,yr,h);   // t时刻储存的电量GWh、充放电功率GW
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
Positive variables R_ES_frm(es,z,yr,h);
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
Positive variables U_ELi_nom(m,z,zx,ni);   // GW
Equations eqU_ELi_nom, eqU_ELi_bLim;

eqU_ELi_nom(imz(m,z,zx),ni)$(ord(ni) > 1) .. U_ELi_nom(m,z,zx,ni) =L= U_ELi_Max(m,z,zx);     // installation cap. <= max. caps, GW
eqU_ELi_bLim(ni)$(ord(ni) > 1) .. sum(imz(m,z,zx), U_ELi_nom(m,z,zx,ni)) =L= U_ELi_bLim * invSpan(ni);     // Max. building rates

* Capacity continuation
Positive variables U_ELi_anom(m,z,zx,ni,yr), U_ELi_dnm(m,z,zx,ni,yr);
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
Positive variables U_ELi_acm(m,z,zx,yr);   // GW
Equations eqU_ELi_acm;

eqU_ELi_acm(J_ET_v(m,z,zx,yr)) .. U_ELi_acm(m,z,zx,yr) =E= sum(J_ET_m(m,z,zx,ni(y),yr)$(ord(y)-1 <= ord(yr)), U_ELi_anom(m,z,zx,ni,yr));   // accumulative caps


* ========= Operations
Parameters ELi_loss(m)   / ac 0.0001, dc 0.0001 /;   // Line loss: per km

Positive variables P_Eli(m,z,zx,yr,h);      // GWh
Equations eqP_Elia, eqP_ELib, eqP_ELic;

eqP_Elia(J_ET_v(m,z,zx,yr), h) .. P_Eli(m,z,zx,yr,h) * (1 - ETNS_dstn(z,zx) * ELi_loss(m)) =L= U_ELi_acm(m,z,zx,yr);   // Power flow <= caps: z to zx
eqP_ELib(J_ET_v(m,z,zx,yr), h) .. P_Eli(m,zx,z,yr,h) * (1 - ETNS_dstn(zx,z) * ELi_loss(m)) =L= U_ELi_acm(m,z,zx,yr);   // Power flow <= caps: zx to z
eqP_ELic(J_ET_v(m,z,zx,yr), h) .. (P_Eli(m,z,zx,yr,h) + P_Eli(m,zx,z,yr,h)) * (1 - ETNS_dstn(z,zx) * ELi_loss(m)) =L= U_ELi_acm(m,z,zx,yr);


* ========= Investment and operation costs
Positive variables CaPx_ELi(ni), FOM_ELi(yr), VOM_ELi(yr);
Equations eqCaPx_ELi, eqFOM_ELi;

eqCaPx_ELi(ni) .. CaPx_ELi(ni) =E= sum(imz(m,z,zx),
                   dn(ni) * ldn(ni) * ELi_afr(m) * ELi_dsm(m,ni) * ELi_CaPx(m) * ETNS_dstn(z,zx) * U_ELi_nom(m,z,zx,ni));               // M USD, ~30

eqFOM_ELi(yr) .. FOM_ELi(yr) =E= sum(J_ET_v(m,z,zx,yr), dn(yr) * ldn(yr) * ELi_FOM(m) * ETNS_dstn(z,zx) * U_ELi_acm(m,z,zx,yr));        // M USD, ~0.4

Equations eqVOM_ELi;
eqVOM_ELi(yr) .. VOM_ELi(yr) =E= sum((J_ET_v(m,z,zx,yr), h), nds * dn(yr) * ELi_VOM(m) * (P_Eli(m,z,zx,yr,h) + P_Eli(m,zx,z,yr,h)));    // M USD, ~0.002
eqVOM_ELi.scale(yr) = 0.01;


* ========================== Water constrains for power generation ========================== *
* Positive Variables Egen_water(z,yr), Water_sum(z,yr);
* Equations eqWater_lim;

* eqWater_lim(z,yr)  .. sum(J_ET_r(watg,z,yr), Water_csm(watg) * sum(h, nds * P_EG_gen(watg,z,yr,h))) =L= water_lim(z) * 1e5 * 2;  //water_lim单位亿吨，Water_csm单位kton/GWh
                      

* ========================== C_Network System Options ========================== *
* Model Specification (mflag): 1 => E_Net, 2 => E_Net + C_Net.
$ifthen "%mflag%" == "2"
$include %Cfolder%/C_Network_Tone.gms

$endif


* ========================== System balance and reserves ========================== *
Scalars E_rsm        reserve margin    / 0.05 /
        E_drs        dynamic reserve   / 0.1  /  
        Edem_Sc      scale factor      / 1.0  /;

Parameters Edem_sum(yr)   electricity demand in year yr;
Edem_sum(yr) = sum((z,h), nds * Edem(z,yr,h));        // Annual electricity demand

* E_Network
Positive variables Edem_dis(z,yr,h), Edis_Sum(z,yr);  // Load shedding

$ifthen "%mflag%" == "1"
Equations eqEbalance;
eqEbalance(z,yr,h) .. sum(J_RN_r(evg,z,yr), P_EG_gen(evg,z,yr,h)) +
                      sum(J_ET_r(ncsgh,z,yr), P_EG_gen(ncsgh,z,yr,h)) + sum(J_ET_r(ccsg,z,yr), P_EG_gen(ccsg,z,yr,h)) +
                      sum(J_ET_r(es,z,yr),  D_ES(es,z,yr,h) -  C_ES(es,z,yr,h)) +
                      sum(J_ET_vm(m,zx,z,yr), P_Eli(m,zx,z,yr,h) * (1 - ELi_loss(m) * ETNS_dstn(zx,z))) -
                      sum(J_ET_vm(m,z,zx,yr), P_Eli(m,z,zx,yr,h)) 
                      =E= Edem(z,yr,h) / ths * Edem_Sc - Edem_dis(z,yr,h);        // GW,  负荷Edem(z,yr,h)可考虑缩放因子

$elseif "%mflag%" == "2"
Equations eqEbalance;
eqEbalance(z,yr,h) .. sum(J_RN_r(evg,z,yr), P_EG_gen(evg,z,yr,h)) +
                      sum(J_ET_r(ncsgh,z,yr), P_EG_gen(ncsgh,z,yr,h)) + sum(J_ET_r(ccsg,z,yr), P_EG_gen(ccsg,z,yr,h)) +
                      sum(J_ET_r(es,z,yr),  D_ES(es,z,yr,h) -  C_ES(es,z,yr,h)) +
                      sum(J_ET_vm(m,zx,z,yr), P_Eli(m,zx,z,yr,h) * (1 - ELi_loss(m) * ETNS_dstn(zx,z))) -
                      sum(J_ET_vm(m,z,zx,yr), P_Eli(m,z,zx,yr,h)) 
                      - P_Cnet(z,yr,h)
                      =E= Edem(z,yr,h) / ths * Edem_Sc - Edem_dis(z,yr,h);  
$endif

Equations eqEdis_Sum;
eqEdis_Sum(z,yr) .. Edis_Sum(z,yr) =E= sum(h, nds * Edem_dis(z,yr,h));   // Annual discarded power demand

Equations eqERsv;
eqERsv(z,yr,h) .. sum(J_ET_r(fmeg,z,yr), R_EG_frm(fmeg,z,yr,h)) + sum(J_ET_r(es,z,yr), R_ES_frm(es,z,yr,h)) =G=
                  E_rsm * Edem(z,yr,h) / ths + E_drs * sum(J_RN_r(evg,z,yr), P_EG_gen(evg,z,yr,h));


* ================================ System Emissions ================================ *
* E_Network emissions
* Model Specification (mflag): 1 => E_Net, 2 => E_Net + C_Net.
* CO2 constraining methd (cflag): 1 => Carbon caps, 2 => Carbon tax.

* System emission caps
$ifthen "%mflag%" == "1"

Positive variables GHG_Enet(yr);
Equations eqCO2_Enet;
eqCO2_Enet(yr) .. GHG_Enet(yr) =E= sum((J_ET_r(ccgg,z,yr), h), nds * EM_EG_CO2(ccgg,z,yr,h));   // kton, 1~365

Positive variables GHG(yr);
Equations eqGHG;
eqGHG(yr) .. GHG(yr) =E= GHG_Enet(yr);

$ifthen "%cflag%" == "1"
Equations eqCO2_Lim;
eqCO2_Lim(yr) .. GHG(yr) =L= CBDyr('%dcs%', yr) * 100000;                      // kilo ton, 1~10^6
* eqGHGdown(yr) .. GHG(yr+1) =L= GHG(yr);

$else
Positive variables GHG_TAX(yr), GHG_STAX;
Equations eqGHG_TAX, eqGHG_STAX;
eqGHG_TAX(yr) .. GHG_TAX(yr) =E= dn(yr) * CO2_Tax(yr,'%ctx%') * GHG(yr);    // M USD, 1~10^6
eqGHG_STAX .. GHG_STAX =E= sum(yr, GHG_TAX(yr));                            // M USD
$endif


$elseif "%mflag%" == "2"

Positive variables GHG_Enet(yr);
Equations eqCO2_Enet;
eqCO2_Enet(yr) .. GHG_Enet(yr) =E= sum((J_ET_r(ccgg,z,yr), h), nds * EM_EG_CO2(ccgg,z,yr,h));   // kton, 1~365, CCS已经被计入
                               
Positive variables GHG(yr);
Equations eqGHG;
eqGHG(yr) .. GHG(yr) =E= GHG_Enet(yr) - CO2_DAC(yr);

$ifthen "%cflag%" == "1"
Equations eqCO2_Lim;
eqCO2_Lim(yr) .. GHG(yr) =L= CBDyr('%dcs%', yr) * 100000;                      // kilo ton, 1~10^6
* eqGHGdown(yr) .. GHG(yr+1) =L= GHG(yr);

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

*China_EC_Network.optfile = 1;


Solve China_EC_Network using lp minimizing TSC;

* Display optimization results
$include %Cfolder%/EC_Display.gms

* Save results into GDX files
$include %Cfolder%/EC_Results.gms