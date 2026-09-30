* CT: Carbon transmission pipelines
Parameters U_CT_Max(z,zx), U_CT_bLim;        

U_CT_Max(z,zx) = 3652;         // ton/hr, 3200万吨/yr
U_CT_bLim      = 205479;       // 74657     // ton/hr,18亿吨/yr


* CS: Carbon storage technologies
Parameters U_CS_Max(cs,z), U_CS_bLim(cs);

U_CS_Max(cs,z) = 20547;          // 占比最大省份取20%
U_CS_bLim(cs)  = 102739;         //  9亿吨/年，2050

