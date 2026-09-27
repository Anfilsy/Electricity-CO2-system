* Read techno-economic data of carbon networks 
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


* Read exisitng capacity for carbon networks
Parameters U_CN_exn(cn,z), U_CT_iln(ct,z,zx), CTNS_dstn(z,zx);
$call csv2gdx  %Data_C_Net%/CNet_Existing_Cap.csv  id = U_CN_exn  index = 2  values = 3..lastcol  useheader = y
$gdxin CNet_Existing_Cap.gdx
$load U_CN_exn
$gdxin

$call csv2gdx  %Data_C_Net%/Carbon_PipeLines.csv  id = U_CT_iln  index = 2,3  values = 4..lastcol  useheader = y
$gdxin Carbon_PipeLines.gdx
$load U_CT_iln
$gdxin

$call csv2gdx  %Data_C_Net%/Carbon_InterDstn.csv  id = CTNS_dstn  index = 2  values = 3..lastcol  useheader = y
$gdxin Carbon_InterDstn.gdx
$load CTNS_dstn
$gdxin

CTNS_dstn(zx,z)$(CTNS_dstn(z,zx)) = CTNS_dstn(z,zx);   // km: d(z,zx) = d(zx,z)

Display U_CN_exn, U_CT_iln, CTNS_dstn;
