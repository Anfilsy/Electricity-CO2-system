* System Results
$ifthen "%mflag%" == "2"
Execute_unload "%Rfolder%/E_4TD_cn50.gdx", U_EG_nom.l, U_PW_nom.l,  U_ES_nom.l, U_ET_acm_z, U_ET_acm_ys,
                                                   U_ET_dnm_ys, U_ET_dnm_ys_sum, U_ET_dnm_sum, 
                                                   U_ET_CCS_ys, U_ET_CCS_ys_sum, U_ET_CCS_sum,
                                                   U_EG_RO.l, U_ET_RO_ys_sum, U_ET_RO_sum,
                                                   U_ELi_acm_ys, U_ELi_acm_ys_sum,
                                                   P_EG_gen.l, C_ES.l, D_ES.l, En_ES.l, P_ELi_H, P_Eli_M,
                                                   P_EG_gen_ys, ECap_EG_CO2, GHG_Enet_M, GHG_M,
                                                   F_EG_NG_M, F_EG_Coal_M, Edem, PS_MC,
                                                   U_DAC_nom.l, U_DAC_acm_ys, U_DAC_acm_ys_sum, CO2_DAC_M, CO2_CCS_M, CO2_TT_M,
                                                   CC_DAC_zyr.l, CC_CCS_zyr.l, CC_Sum_zyr.l,
                                                   CaPx_ET_PW, RO_EG_PW, FOM_ET_PW, VOM_ET_PW, FCS_Nu_PW, FCS_EG_PW,
                                                   CaPx_Cnet.l, FCS_Cnet.l, FOM_Cnet.l, TSC_Cnet.l,
                                                   CaPx_ELi_PW, FOM_ELi_PW, VOM_ELi_PW, TSC_Enet.l, TSC.l;

Parameters DAC_zyr(z,yr), DAC_yr(yr), DAC_h(z,yr,h);
Parameters CCS_zyr(z,yr), CCS_yr(yr), CCS_h(z,yr,h);
Parameters CCsum_zyr(z,yr), CCsum_yr(yr), CCsum_h(z,yr,h);

DAC_zyr(z,yr) = CC_DAC_zyr.l(z,yr);
DAC_yr(yr) = CO2_DAC.l(yr);
DAC_h(z,yr,h) = CC_DAC_h.l(z,yr,h);

CCS_zyr(z,yr) = CC_CCS_zyr.l(z,yr);
CCS_yr(yr) = CC_CCS_yr.l(yr);
CCS_h(z,yr,h) = CC_CCS_h.l(z,yr,h);

CCsum_zyr(z,yr) = CC_Sum_zyr.l(z,yr);
CCsum_yr(yr) = CC_Sum_yr.l(yr);
CCsum_h(z,yr,h) = CC_Sum_h.l(z,yr,h);

Execute_unload "%Rfolder%/CC_4TD_cn50.gdx", DAC_zyr, DAC_yr, DAC_h, CCS_zyr, CCS_yr, CCS_h, CCsum_zyr, CCsum_yr, CCsum_h,
                                           U_DAC_nom_czy, U_DAC_acm_czy, U_DAC_acm_zyr, U_DAC_acm_ys, U_DAC_acm_ys_sum;


* Stage 1: Province Results
Execute_unload "%Rfolder%/Electricity-CO2 system.gdx", U_EG_nom.l, U_PW_nom.l, U_EG_anom.l, U_EG_dnm.l, U_PW_anom.l, U_EG_acm.l, U_PW_acm.l, P_EG_gen.l, F_EG_fcs.l,
                                             EM_EG_CO2.l, P_EG_gen_ncs.l, E_EG_CO2.l, P_PW_gen.l, R_EG_frm.l, F_EG_Nu.l, F_EG_NG.l, F_EG_Coal.l,
                                             U_ES_nom.l, U_ES_anom.l, U_ES_dnm.l, U_ES_acm.l, U_lib_acm_ys.l, En_ES.l, C_ES.l, D_ES.l, R_ES_frm.l, CaPx_ES.l,
                                             FOM_ES.l, VOM_ES.l, U_ELi_nom.l, U_ELi_anom.l, U_ELi_dnm.l, U_ELi_acm.l, P_Eli.l, CaPx_ELi.l, FOM_ELi.l, VOM_ELi.l,
                                             Edem_dis.l, Edis_Sum.l, GHG_Enet.l, GHG.l, U_DAC_nom.l, U_DAC_anom.l, U_DAC_dnm.l, U_DAC_acm.l, M_CO2_DAC.l, P_CO2_DAC.l, Q_CO2_DAC.l,
                                             P_DAC.l, CO2_DAC.l, Q_DAC_NG.l, CaPx_DAC.l, FCS_DAC.l, FOM_DAC.l, P_Cnet.l, CaPx_Cnet.l, FCS_Cnet.l, FOM_Cnet.l, TSC_Cnet.l;


                                                   
$elseif "%mflag%" == "1"
Execute_unload "%Rfolder%/Results_ENet.gdx", U_EG_nom.l, U_ES_nom.l, U_ET_acm_z, U_ET_acm_ys,
                                                   U_ET_dnm_ys, U_ET_dnm_ys_sum, U_ET_dnm_sum, 
                                                   U_ET_CCS_ys, U_ET_CCS_ys_sum, U_ET_CCS_sum,
                                                   U_EG_RO.l, U_ET_RO_ys_sum, U_ET_RO_sum,
                                                   U_ELi_acm_ys, U_ELi_acm_ys_sum,
                                                   P_EG_gen.l, C_ES.l, D_ES.l, En_ES.l, P_ELi_H, P_Eli_M,
                                                   P_EG_gen_ys, ECap_EG_CO2, GHG_Enet_M,
                                                   F_EG_NG_M, F_EG_Coal_M, Edem, PS_MC,
                                                   CaPx_ET_PW, RO_EG_PW, FOM_ET_PW, VOM_ET_PW, FCS_Nu_PW, FCS_EG_PW,
                                                   CaPx_ELi_PW, FOM_ELi_PW, VOM_ELi_PW, TSC_Enet.l, TSC.l;
                                                   
$endif
$endif