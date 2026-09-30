//参数待定
* =====================================================================
* Power generation and storage: GW
Parameters U_EG_Max(eg,z), U_EG_bLim(eg);         

U_EG_Max(eg,z) = 40;
U_EG_Max('pv',z)  = 80;      // 17.83 GW, 20
U_EG_Max('nwd',z) = 70;      // 9.76 GW, 10
U_EG_Max('fwd',z) = 60;      // 9.76 GW, 10
U_EG_Max('gtcc',z) = 30;     // 4.11 GW, 5
U_EG_Max('gccs',z) = 30;
U_EG_Max('coal',z) = 30;     // 4.86 GW, 5   
U_EG_Max('cocs',z) = 30;
U_EG_max('bio',z) = 30;        // 4.75 GW, 5
U_EG_max('nu',z) = 15;        // 4.75 GW, 5
U_EG_max('hydo',z) = 5;

* Building rates: GW
U_EG_bLim(eg) = 500;          // 1.2 * 5
U_EG_bLim('pv') = 800;       // 1.2 * 5, 150
U_EG_bLim('nwd') = 600;      // 1.2 * 5, 80
U_EG_bLim('fwd') = 500;      // 1.2 * 5, 80

U_EG_bLim('bio') = 100;        // 1.2 * 5, 30
U_EG_bLim('nu') = 200;        // 1.2 * 5, 30
U_EG_bLim('gtcc') = 300;     // 1.5 * 5
U_EG_bLim('gccs') = 300;     // 1.5 * 5
U_EG_bLim('coal') = 300;     // 1.5 * 5
U_EG_bLim('cocs') = 300;     // 1.5 * 5
U_EG_bLim('hydo') = 30;


* Power storage technologies: GW
Parameters U_ES_Max(es,z), U_ES_bLim(es), U_ES_rLim(es);  
U_ES_max('phs',z)  = 12;      // 17.8 GW, 20
U_ES_max('lib4',z) = 18;

U_ES_bLim(es)    = 50;
U_ES_bLim('phs') = 50;       // 1 * 5
U_ES_bLim('lib4') = 100;      // 100

* Transmission line buiding rate constraints: GW
Parameters U_ELi_Max(m,z,zx), U_ELi_bLim;

U_ELi_Max(m,z,zx) = 8;      // 0.8 * 10
U_ELi_bLim        = 60;  


* =====================================================================
* Coal and NG supply abilities
Scalars LHV_NG          NG LHV    GWh per billion m^3
        LHV_CO          Coal LHV  GWh per million ton;

Scalars V_NG_max        NG supply ability    billion m^3      / 80  /
        T_Coal_max      Coal supply ability  million ton      / 645 /;

LHV_NG = 10.167 * 1000;     // GWh/billion m^3, 36600 kJ/m^3 => 36600 / 3600 / 1000 * 1000 * 1000 * 1000 MWh/billion m^3
LHV_CO = 8.136 * 1000;      // GWh/million ton  7000 kcal/kg => 8.136 MWh/ton, 8.136 * 1000 * 1000 MWh/million ton



* =====================================================================
* Water constrains
Parameters Water_csm(er);    // m3/ton per MWh

Water_csm('coal') = 3.82;
Water_csm('cocs') = 5.02;
Water_csm('coics') = 5.02;
Water_csm('gtcc') = 0.97;
Water_csm('gccs') = 1.4;
Water_csm('gcics') = 1.4;
Water_csm('nu') = 4.167;
Water_csm('bio') = 3.32;
Water_csm('beccs') = 4.007;