* ================================================================ *
* Read electricity demands
Parameters Edem(z,yr,h);      // MWh: 20 ~ 200, Correct!
$call csv2gdx  %Data_DEM%/%Ele_Dem%.csv  id = Edem  index = 2,3  values = 4..lastcol  useheader = y
$gdxin %Ele_Dem%.gdx
$load Edem
$gdxin

* Read carbon emission budgets
Parameters CBDyr(ces,yr);      // Million/year: Correct! ~ 10,000
$call csv2gdx  %Dfolder%/CO2_Emissions.csv  id = CBDyr  index = 1  values = 2..lastcol  useheader = y
$gdxin CO2_Emissions.gdx
$load CBDyr
$gdxin

Display Edem, CBDyr;


* Read techno-economic data of energy technologies
Parameters ET_Specs(er,esp), ET_CaPx(er,c,yr), ET_FOM(er,c,yr), ET_VOM(er,c,yr);
$call csv2gdx  %Data_E_Net%/Egen_Specs.csv  id = ET_Specs  index = 2  values = 3..lastcol  useheader = y
$gdxin Egen_Specs.gdx
$load ET_Specs
$gdxin

$call csv2gdx  %Data_E_Net%/Egen_CAPEX.csv  id = ET_CaPx  index = 2,3  values = 4..lastcol  useheader = y
$gdxin Egen_CAPEX.gdx
$load ET_CaPx
$gdxin

$call csv2gdx  %Data_E_Net%/Egen_FOM.csv  id = ET_FOM  index = 2,3  values = 4..lastcol  useheader = y
$gdxin Egen_FOM.gdx
$load ET_FOM
$gdxin

$call csv2gdx  %Data_E_Net%/Egen_VOM.csv  id = ET_VOM  index = 2,3  values = 4..lastcol  useheader = y
$gdxin Egen_VOM.gdx
$load ET_VOM
$gdxin

ET_CaPx(er,c,yr) = ET_CaPx(er,c,yr) / 1;      // USD/kW    -> M USD/GW
ET_FOM(er,c,yr) = ET_FOM(er,c,yr) / 1;        // USD/kW/yr -> M USD/GW/yr
ET_VOM(er,c,yr) = ET_VOM(er,c,yr) / ths;      // USD/MWh   -> M USD/GWh

Display ET_Specs, ET_CaPx, ET_FOM, ET_VOM;   // M USD

* Read exisitng capacity for power generation and storage technologies and transmission lines
Parameters ETNS_dstn(z,zx);   // km
$call csv2gdx  %Data_E_Net%/ETNS_Dstn.csv  id = ETNS_dstn  index = 2  values = 3..lastcol  useheader = y
$gdxin ETNS_Dstn.gdx
$load ETNS_dstn
$gdxin

ETNS_dstn(zx,z)$(ETNS_dstn(z,zx)) = ETNS_dstn(z,zx);   // km: d(z,zx) = d(zx,z)


Parameters U_ET_exn(er,z), U_ET_iln(m,z,zx);   // GW
$call csv2gdx  %Data_E_Net%/Egen_Existing_Cap.csv  id = U_ET_exn  index = 2  values = 3..lastcol  useheader = y
$gdxin Egen_Existing_Cap.gdx
$load U_ET_exn
$gdxin

$call csv2gdx  %Data_E_Net%/ETNS_ACDC.csv  id = U_ET_iln  index = 2,3  values = 4..lastcol  useheader = y
$gdxin ETNS_ACDC.gdx
$load U_ET_iln
$gdxin

Display U_ET_exn, ETNS_dstn, U_ET_iln;


* Read water resources limitation
Parameters water_lim(z);

$call csv2gdx  %Data_E_Net%/Water_lim.csv  id = Water_lim  index = 2  values = 3  useheader = y
$gdxin Water_lim.gdx
$load water_lim
$gdxin

water_lim(z) = water_lim(z);        //亿吨

Display water_lim;


* Read renewable time series capacity factors
Parameters solar(z,yr,h), onshwd(z,yr,h), offshwd(z,yr,h);   // 0.05 ~ 1.0

$call csv2gdx  %Data_VRE%/Solar.csv  id = solar  index = 1,2  values = 3..lastcol  useheader = y
$gdxin Solar.gdx
$load solar
$gdxin

$call csv2gdx  %Data_VRE%/Onshwd.csv  id = onshwd  index = 1,2  values = 3..lastcol  useheader = y
$gdxin Onshwd.gdx
$load onshwd
$gdxin

$call csv2gdx  %Data_VRE%/Offshwd.csv  id = offshwd  index = 1,2  values = 3..lastcol  useheader = y
$gdxin Offshwd.gdx
$load offshwd
$gdxin

solar(z,yr,h)$(solar(z,yr,h) < 0.05) = 0;
onshwd(z,yr,h)$(onshwd(z,yr,h) < 0.05) = 0;
offshwd(z,yr,h)$(offshwd(z,yr,h) < 0.05) = 0;

Display solar, onshwd, offshwd;

* Clean energy potentials
Sets ce(er)   / pv, nwd, fwd, bio, nu, phs /;
Parameters CE_rLim(er,z);         // GW, 20 ~ 300
$call csv2gdx  %Dfolder%/Tech_Potentials.csv  id = CE_rLim  index = 2  values = 3..lastcol  useheader = y
$gdxin Tech_Potentials.gdx
$load CE_rLim
$gdxin

Parameters CO2_Tax(cxs,yr);
$call csv2gdx  %Dfolder%/CO2_Tax.csv  id = CO2_Tax  index = 1  values = 2..lastcol  useheader = y
$gdxin CO2_Tax.gdx
$load CO2_Tax
$gdxin

CO2_Tax(cxs,yr) = CO2_Tax(cxs,yr) / ths;   // M USD/ktonne

Display CE_rLim, CO2_Tax;

