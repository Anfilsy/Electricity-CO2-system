* ================================ City Data ================================ *
Sets pk(*)    province
     pj(*)    Prefecture;
     
Alias (z,pz);
   
$call csv2gdx %Data_PRF%/Province.csv  id = pk  index = 1  useHeader = y 
$gdxIn Province.gdx
$load pk
$gdxin

$call csv2gdx %Data_PRF%/Prefecture.csv  id = pj  index = 1  useHeader = y 
$gdxIn Prefecture.gdx
$load pj
$gdxIn

Parameter pref_mt(pz,pj); 
$call csv2gdx %Data_PRF%/pref_match.csv  id = pref_mt  index = 1,2  values = 3..lastCol  useHeader = y 
$gdxIn pref_match.gdx
$load pref_mt
$gdxIn

display pk, pj, pz, pref_mt;


* ================================ PV and Wind Data (only onshore) ================================ *
Parameters PV_Cap(pz,pj), WT_Cap(pz,pj);     
$call csv2gdx %Data_PRF%/PV_Cap.csv  id = PV_Cap  index = 1,2  values = 3..lastCol  useHeader = y
$gdxIn PV_Cap.gdx
$load PV_Cap
$gdxin

$call csv2gdx %Data_PRF%/WT_Cap.csv  id = WT_Cap  index = 1,2  values = 3..lastCol  useHeader = y
$gdxIn WT_Cap.gdx
$load WT_Cap
$gdxin

display PV_Cap, WT_Cap;     //GW


Parameters PV_CF(pz,pj,yr,h), WT_CF(pz,pj,yr,h);
$call csv2gdx %Data_PRF%/Pref_PV_CF_4TD.csv  id = PV_CF   index = 1,2,3  values = 4..lastCol  useHeader = y
$gdxIn Pref_PV_CF_4TD.gdx
$load PV_CF
$gdxin

$call csv2gdx %Data_PRF%/Pref_WT_CF_4TD.csv  id = WT_CF   index = 1,2,3  values = 4..lastCol  useHeader = y
$gdxIn Pref_WT_CF_4TD.gdx
$load WT_CF
$gdxin

PV_CF(pz,pj,yr,h)$(PV_CF(pz,pj,yr,h) < 0.05) = 0.0;

display PV_CF, WT_CF;


Parameters PV_Excap(pz,pj), WT_Excap(pz,pj);  
$call csv2gdx %Data_PRF%/Exst_PV_Cap.csv  id = PV_Excap   index = 1,2  values = 3..lastCol  useHeader = y
$gdxIn Exst_PV_Cap.gdx
$load PV_Excap
$gdxin

$call csv2gdx %Data_PRF%/Exst_WT_Cap.csv  id = WT_Excap   index = 1,2  values = 3..lastCol  useHeader = y
$gdxIn Exst_WT_Cap.gdx
$load WT_Excap
$gdxin

display PV_Excap, WT_Excap;   // GW


* ================================ Coal and Gas data ================================ *
Parameters coal_Excap(pz,pj), gtcc_Excap(pz,pj);  
$call csv2gdx %Data_PRF%/Exst_Coal_Cap.csv  id = coal_Excap   index = 1,2  values = 3..lastCol  useHeader = y
$gdxIn Exst_Coal_Cap.gdx
$load coal_Excap
$gdxin

$call csv2gdx %Data_PRF%/Exst_Gas_Cap.csv  id = gtcc_Excap   index = 1,2  values = 3..lastCol  useHeader = y
$gdxIn Exst_Gas_Cap.gdx
$load gtcc_Excap
$gdxin

display coal_Excap, gtcc_Excap;   // GW






