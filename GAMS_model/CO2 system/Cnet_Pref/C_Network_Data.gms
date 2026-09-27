* ===========Read techno-economic data of carbon networks 
Parameters CNet_Specs(cn,csp), CNet_CaPx(cn,c,yr), CNet_FOM(cn,c,yr), CNet_VOM(cn,c,yr); 
$call csv2gdx  %Data_C_Net%/CNet_Specs.csv  id = CNet_Specs  index = 2  values = 3..lastcol  useheader = y
$gdxin CNet_Specs.gdx
$load CNet_Specs
$gdxin

$call csv2gdx  %Data_C_Net%/CNet_CAPEX.csv  id = CNet_CaPx  index = 2,3  values = 4..lastcol  useheader = y
$gdxin CNet_CAPEX.gdx
$load CNet_CaPx
$gdxin

$call csv2gdx  %Data_C_Net%/CNet_FOM.csv  id = CNet_FOM  index = 2,3  values = 4..lastcol  useheader = y
$gdxin CNet_FOM.gdx
$load CNet_FOM
$gdxin

$call csv2gdx  %Data_C_Net%/CNet_VOM.csv  id = CNet_VOM  index = 2,3  values = 4..lastcol  useheader = y
$gdxin CNet_VOM.gdx
$load CNet_VOM
$gdxin

CNet_CaPx(cn,c,yr) = CNet_CaPx(cn,c,yr) / mms;   // M USD
CNet_FOM(cn,c,yr)  = CNet_FOM(cn,c,yr);   // USD
CNet_VOM(cn,c,yr)  = CNet_VOM(cn,c,yr);   // USD

Display CNet_Specs, CNet_CaPx, CNet_FOM, CNet_VOM;


* ===========Read exisitng capacity for carbon networks
Parameters U_CN_exn(cn,z), Pv_Dstn(z,zx);
$call csv2gdx  %Data_C_Net%/CNet_Existing_Cap.csv  id = U_CN_exn  index = 2  values = 3..lastcol  useheader = y
$gdxin CNet_Existing_Cap.gdx
$load U_CN_exn
$gdxin

$call csv2gdx  %Data_C_Net%/Carbon_InterDstn.csv  id = Pv_Dstn  index = 2  values = 3..lastcol  useheader = y
$gdxin Carbon_InterDstn.gdx
$load Pv_Dstn
$gdxin

Pv_Dstn(zx,z)$(Pv_Dstn(z,zx)) = Pv_Dstn(z,zx);   // km: d(z,zx) = d(zx,z)

Display U_CN_exn, Pv_Dstn;


* ===========Read data for carbon storage potential
Parameters U_CS_rLim(cs,z,pj);
$call csv2gdx  %Data_C_Net%/CS_Potential_Pf_gdp.csv  id = U_CS_rLim  index = 1,2,3  values = 4  useheader = y
$gdxin CS_Potential_Pf_gdp.gdx
$load U_CS_rLim
$gdxin

Display U_CS_rLim;


* ===========Read data for carbon Network, 参考电网拓扑
Parameter ETNS_dstn(z,zx); 
$call csv2gdx %Data_C_Net%/ETNS_Dstn.csv  id = ETNS_dstn  index = 2  values = 3..lastcol  useheader = y 
$gdxIn ETNS_Dstn.gdx
$load ETNS_dstn
$gdxIn

ETNS_dstn(zx,z)$(ETNS_dstn(z,zx)) = ETNS_dstn(z,zx);   // km: d(z,zx) = d(zx,z)

Display ETNS_dstn;


