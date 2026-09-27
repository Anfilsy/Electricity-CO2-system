* ================================== Carbon network results ==================================
* CS results
Parameters CS_Prov(z,yr), CS_Pref(z,pj,yr);

CS_Pref(z,pj,yr) = sum(J_CN_r(cs,z,pj,yr), En_CS.l(cs,z,pj,yr));

CS_Prov(z,yr) = sum(pj, CS_Pref(z,pj,yr));

* ===================== Cost Analysis 
Parameters CaPx_CP_ys, CaPx_CS_ys, CaPx_CT_ys;
Parameters FOM_CP_ys, FOM_CS_ys, FOM_CT_ys;

CaPx_CP_ys = sum(n$(ord(n) > 1), CaPx_CP.l(n));
CaPx_CS_ys = sum(n$(ord(n) > 1), CaPx_CS.l(n));
CaPx_CT_ys = sum(ni$(ord(ni) > 1), CaPx_CT.l(ni));

FOM_CP_ys = sum(yr, FOM_CP.l(yr));
FOM_CS_ys = sum(yr, FOM_CS.l(yr));
FOM_CT_ys = sum(yr, FOM_CT.l(yr));
