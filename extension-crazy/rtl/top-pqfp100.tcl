# Find myself
# ==========================
variable myDir [file dirname [file normalize [info script]]]

# Toplevel entity
# ==========================
set_global_assignment -name VERILOG_FILE [file join $myDir top.v ]
set_global_assignment -name TOP_LEVEL_ENTITY top

# Pin & Location Assignments
# ==========================
set_location_assignment PIN_1 -to GAH[7]
set_location_assignment PIN_2 -to GBUS[3]
set_location_assignment PIN_3 -to GBUS[4]
set_location_assignment PIN_4 -to GBUS[2]
set_location_assignment PIN_7 -to GBUS[5]
set_location_assignment PIN_8 -to GBUS[1]
set_location_assignment PIN_9 -to GBUS[6]
set_location_assignment PIN_10 -to GBUS[0]
set_location_assignment PIN_11 -to GBUS[7]
set_location_assignment PIN_12 -to GAH[2]
set_location_assignment PIN_14 -to GAH[3]
set_location_assignment PIN_15 -to GAH[0]
set_location_assignment PIN_16 -to GAH[6]
set_location_assignment PIN_18 -to GAH[4]
set_location_assignment PIN_19 -to GAH[1]
set_location_assignment PIN_21 -to GAH[5]
set_location_assignment PIN_22 -to nGWE
set_location_assignment PIN_23 -to nAE
set_location_assignment PIN_24 -to MISO[2]
set_location_assignment PIN_25 -to IO25
set_location_assignment PIN_99 -to MISO[0]
set_location_assignment PIN_27 -to nADEV[0]
set_location_assignment PIN_26 -to nADEV[1]
set_location_assignment PIN_29 -to nACTRL
set_location_assignment PIN_34 -to nROE
set_location_assignment PIN_35 -to RD[7]
set_location_assignment PIN_37 -to RD[6]
set_location_assignment PIN_38 -to RD[5]
set_location_assignment PIN_39 -to RD[4]
set_location_assignment PIN_30 -to RAH[10]
set_location_assignment PIN_31 -to RAH[9]
set_location_assignment PIN_32 -to RAH[8]
set_location_assignment PIN_33 -to RAH[7]
set_location_assignment PIN_42 -to RAH[6]
set_location_assignment PIN_43 -to RAH[5]
set_location_assignment PIN_44 -to RAH[4]
set_location_assignment PIN_47 -to RAH[2]
set_location_assignment PIN_46 -to RAH[3]
set_location_assignment PIN_48 -to RAL[0]
set_location_assignment PIN_49 -to RAL[1]
set_location_assignment PIN_50 -to RAL[2]
set_location_assignment PIN_51 -to RAL[3]
set_location_assignment PIN_52 -to RAL[4]
set_location_assignment PIN_54 -to RD[0]
set_location_assignment PIN_55 -to RD[1]
set_location_assignment PIN_56 -to RD[2]
set_location_assignment PIN_57 -to RD[3]
set_location_assignment PIN_58 -to nRWE
set_location_assignment PIN_59 -to RAL[5]
set_location_assignment PIN_60 -to RAL[6]
set_location_assignment PIN_62 -to RAL[7]
set_location_assignment PIN_63 -to RAH[0]
set_location_assignment PIN_65 -to RAH[1]
set_location_assignment PIN_66 -to nOL
set_location_assignment PIN_67 -to OUT[7]
set_location_assignment PIN_69 -to OUT[0]
set_location_assignment PIN_70 -to ALU[7]
set_location_assignment PIN_71 -to ALU[0]
set_location_assignment PIN_72 -to ALU[6]
set_location_assignment PIN_73 -to ALU[1]
set_location_assignment PIN_74 -to OUT[6]
set_location_assignment PIN_77 -to OUT[1]
set_location_assignment PIN_78 -to OUT[5]
set_location_assignment PIN_79 -to OUT[2]
set_location_assignment PIN_80 -to ALU[5]
set_location_assignment PIN_81 -to ALU[2]
set_location_assignment PIN_82 -to ALU[4]
set_location_assignment PIN_83 -to ALU[3]
set_location_assignment PIN_85 -to OUT[4]
set_location_assignment PIN_86 -to OUT[3]
set_location_assignment PIN_87 -to CLK
set_location_assignment PIN_89 -to CLKx2
set_location_assignment PIN_90 -to nGOE
set_location_assignment PIN_91 -to OEINH
set_location_assignment PIN_92 -to CLKx4
set_location_assignment PIN_94 -to nSS[1]
set_location_assignment PIN_95 -to nSS[0]
set_location_assignment PIN_96 -to SCK
set_location_assignment PIN_98 -to MOSI
set_location_assignment PIN_100 -to MISO[1]


