Parameters Fix_U_Prv_nom(z,zx,ni);
Parameters Fix_F_CT(z,zx,yr,h);
Fix_U_Prv_nom(z,zx,ni) = U_Prv_nom.l(z,zx,ni);
Fix_F_CT(z,zx,yr,h) = F_CT.l(z,zx,yr,h);

Execute_unload "%Rfolder%/CO2 system.gdx",   Fix_U_Prv_nom, Fix_F_CT, U_Prv_nom.l, U_CT_acm_ys, U_CT_acm_ys_sum, U_CS_acm_ys, U_CS_acm.l, U_CP_acm.l, U_CS_nom.l, U_CP_acm_ys, U_CP_nom.l,
                                                   CaPx_CS.l, CaPx_CP.l, CaPx_CT.l,
                                                   FOM_CP.l, FOM_CS.l, FOM_CT.l,
                                                   CaPx_CP_ys, CaPx_CS_ys, CaPx_CT_ys, FOM_CP_ys, FOM_CS_ys, FOM_CT_ys,
                                                   CaPx_Cnet.l, FOM_Cnet.l, TSC_Cnet.l,
                                                   En_CS.l;
                                                  
