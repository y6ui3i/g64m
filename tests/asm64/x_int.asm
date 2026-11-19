; The packed integer instructions of SSE2 on XMM registers: arithmetic, comparisons, packing, unpacking, shifts.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    movdqu xmm11, [c0]
    movdqu xmm5, [c1]
    paddb xmm11, xmm5
    paddb xmm5, [c2]
    movdqu xmm8, [c3]
    movdqu xmm15, [c4]
    paddb xmm8, xmm15
    paddb xmm15, [c5]
    movdqu xmm1, [c6]
    movdqu xmm11, [c7]
    paddb xmm1, xmm11
    paddb xmm11, [c8]
    movdqu xmm11, [c9]
    movdqu xmm7, [c10]
    paddb xmm11, xmm7
    paddb xmm7, [c11]
    movdqu xmm5, [c12]
    paddb xmm5, xmm5
    movdqu xmm10, [c13]
    movdqu xmm9, [c14]
    psubb xmm10, xmm9
    psubb xmm9, [c15]
    movdqu xmm2, [c16]
    movdqu xmm1, [c17]
    psubb xmm2, xmm1
    psubb xmm1, [c18]
    movdqu xmm14, [c19]
    movdqu xmm11, [c20]
    psubb xmm14, xmm11
    psubb xmm11, [c21]
    movdqu xmm3, [c22]
    movdqu xmm5, [c23]
    psubb xmm3, xmm5
    psubb xmm5, [c24]
    movdqu xmm6, [c25]
    psubb xmm6, xmm6
    movdqu xmm9, [c26]
    movdqu xmm6, [c27]
    paddsb xmm9, xmm6
    paddsb xmm6, [c28]
    movdqu xmm3, [c29]
    movdqu xmm4, [c30]
    paddsb xmm3, xmm4
    paddsb xmm4, [c31]
    movdqu xmm3, [c32]
    movdqu xmm8, [c33]
    paddsb xmm3, xmm8
    paddsb xmm8, [c34]
    movdqu xmm11, [c35]
    movdqu xmm12, [c36]
    paddsb xmm11, xmm12
    paddsb xmm12, [c37]
    movdqu xmm2, [c38]
    paddsb xmm2, xmm2
    movdqu xmm9, [c39]
    movdqu xmm4, [c40]
    paddusb xmm9, xmm4
    paddusb xmm4, [c41]
    movdqu xmm3, [c42]
    movdqu xmm9, [c43]
    paddusb xmm3, xmm9
    paddusb xmm9, [c44]
    movdqu xmm1, [c45]
    movdqu xmm13, [c46]
    paddusb xmm1, xmm13
    paddusb xmm13, [c47]
    movdqu xmm7, [c48]
    movdqu xmm12, [c49]
    paddusb xmm7, xmm12
    paddusb xmm12, [c50]
    movdqu xmm10, [c51]
    paddusb xmm10, xmm10
    movdqu xmm9, [c52]
    movdqu xmm6, [c53]
    psubsb xmm9, xmm6
    psubsb xmm6, [c54]
    movdqu xmm6, [c55]
    movdqu xmm3, [c56]
    psubsb xmm6, xmm3
    psubsb xmm3, [c57]
    movdqu xmm3, [c58]
    movdqu xmm5, [c59]
    psubsb xmm3, xmm5
    psubsb xmm5, [c60]
    movdqu xmm1, [c61]
    movdqu xmm0, [c62]
    psubsb xmm1, xmm0
    psubsb xmm0, [c63]
    movdqu xmm0, [c64]
    psubsb xmm0, xmm0
    movdqu xmm9, [c65]
    movdqu xmm5, [c66]
    psubusb xmm9, xmm5
    psubusb xmm5, [c67]
    movdqu xmm3, [c68]
    movdqu xmm5, [c69]
    psubusb xmm3, xmm5
    psubusb xmm5, [c70]
    movdqu xmm6, [c71]
    movdqu xmm8, [c72]
    psubusb xmm6, xmm8
    psubusb xmm8, [c73]
    movdqu xmm2, [c74]
    movdqu xmm14, [c75]
    psubusb xmm2, xmm14
    psubusb xmm14, [c76]
    movdqu xmm3, [c77]
    psubusb xmm3, xmm3
    movdqu xmm4, [c78]
    movdqu xmm15, [c79]
    pcmpeqb xmm4, xmm15
    pcmpeqb xmm15, [c80]
    movdqu xmm14, [c81]
    movdqu xmm0, [c82]
    pcmpeqb xmm14, xmm0
    pcmpeqb xmm0, [c83]
    movdqu xmm9, [c84]
    movdqu xmm15, [c85]
    pcmpeqb xmm9, xmm15
    pcmpeqb xmm15, [c86]
    movdqu xmm8, [c87]
    movdqu xmm7, [c88]
    pcmpeqb xmm8, xmm7
    pcmpeqb xmm7, [c89]
    movdqu xmm8, [c90]
    pcmpeqb xmm8, xmm8
    movdqu xmm13, [c91]
    movdqu xmm9, [c92]
    pcmpgtb xmm13, xmm9
    pcmpgtb xmm9, [c93]
    movdqu xmm12, [c94]
    movdqu xmm13, [c95]
    pcmpgtb xmm12, xmm13
    pcmpgtb xmm13, [c96]
    movdqu xmm4, [c97]
    movdqu xmm11, [c98]
    pcmpgtb xmm4, xmm11
    pcmpgtb xmm11, [c99]
    movdqu xmm13, [c100]
    movdqu xmm8, [c101]
    pcmpgtb xmm13, xmm8
    pcmpgtb xmm8, [c102]
    movdqu xmm2, [c103]
    pcmpgtb xmm2, xmm2
    movdqu xmm8, [c104]
    movdqu xmm1, [c105]
    pavgb xmm8, xmm1
    pavgb xmm1, [c106]
    movdqu xmm0, [c107]
    movdqu xmm6, [c108]
    pavgb xmm0, xmm6
    pavgb xmm6, [c109]
    movdqu xmm11, [c110]
    movdqu xmm4, [c111]
    pavgb xmm11, xmm4
    pavgb xmm4, [c112]
    movdqu xmm12, [c113]
    movdqu xmm15, [c114]
    pavgb xmm12, xmm15
    pavgb xmm15, [c115]
    movdqu xmm5, [c116]
    pavgb xmm5, xmm5
    movdqu xmm12, [c117]
    movdqu xmm10, [c118]
    pminub xmm12, xmm10
    pminub xmm10, [c119]
    movdqu xmm8, [c120]
    movdqu xmm6, [c121]
    pminub xmm8, xmm6
    pminub xmm6, [c122]
    movdqu xmm5, [c123]
    movdqu xmm7, [c124]
    pminub xmm5, xmm7
    pminub xmm7, [c125]
    movdqu xmm6, [c126]
    movdqu xmm1, [c127]
    pminub xmm6, xmm1
    pminub xmm1, [c128]
    movdqu xmm5, [c129]
    pminub xmm5, xmm5
    movdqu xmm9, [c130]
    movdqu xmm10, [c131]
    pmaxub xmm9, xmm10
    pmaxub xmm10, [c132]
    movdqu xmm10, [c133]
    movdqu xmm0, [c134]
    pmaxub xmm10, xmm0
    pmaxub xmm0, [c135]
    movdqu xmm9, [c136]
    movdqu xmm14, [c137]
    pmaxub xmm9, xmm14
    pmaxub xmm14, [c138]
    movdqu xmm3, [c139]
    movdqu xmm2, [c140]
    pmaxub xmm3, xmm2
    pmaxub xmm2, [c141]
    movdqu xmm14, [c142]
    pmaxub xmm14, xmm14
    movdqu xmm11, [c143]
    movdqu xmm12, [c144]
    psadbw xmm11, xmm12
    psadbw xmm12, [c145]
    movdqu xmm4, [c146]
    movdqu xmm9, [c147]
    psadbw xmm4, xmm9
    psadbw xmm9, [c148]
    movdqu xmm13, [c149]
    movdqu xmm14, [c150]
    psadbw xmm13, xmm14
    psadbw xmm14, [c151]
    movdqu xmm7, [c152]
    movdqu xmm11, [c153]
    psadbw xmm7, xmm11
    psadbw xmm11, [c154]
    movdqu xmm6, [c155]
    psadbw xmm6, xmm6
    movdqu xmm0, [c156]
    movdqu xmm8, [c157]
    punpcklbw xmm0, xmm8
    punpcklbw xmm8, [c158]
    movdqu xmm14, [c159]
    movdqu xmm9, [c160]
    punpcklbw xmm14, xmm9
    punpcklbw xmm9, [c161]
    movdqu xmm2, [c162]
    movdqu xmm7, [c163]
    punpcklbw xmm2, xmm7
    punpcklbw xmm7, [c164]
    movdqu xmm15, [c165]
    movdqu xmm10, [c166]
    punpcklbw xmm15, xmm10
    punpcklbw xmm10, [c167]
    movdqu xmm2, [c168]
    punpcklbw xmm2, xmm2
    movdqu xmm1, [c169]
    movdqu xmm4, [c170]
    punpckhbw xmm1, xmm4
    punpckhbw xmm4, [c171]
    movdqu xmm15, [c172]
    movdqu xmm0, [c173]
    punpckhbw xmm15, xmm0
    punpckhbw xmm0, [c174]
    movdqu xmm4, [c175]
    movdqu xmm14, [c176]
    punpckhbw xmm4, xmm14
    punpckhbw xmm14, [c177]
    movdqu xmm5, [c178]
    movdqu xmm4, [c179]
    punpckhbw xmm5, xmm4
    punpckhbw xmm4, [c180]
    movdqu xmm14, [c181]
    punpckhbw xmm14, xmm14
    movdqu xmm11, [c182]
    movdqu xmm9, [c183]
    paddw xmm11, xmm9
    paddw xmm9, [c184]
    movdqu xmm7, [c185]
    movdqu xmm12, [c186]
    paddw xmm7, xmm12
    paddw xmm12, [c187]
    movdqu xmm2, [c188]
    movdqu xmm13, [c189]
    paddw xmm2, xmm13
    paddw xmm13, [c190]
    movdqu xmm3, [c191]
    movdqu xmm7, [c192]
    paddw xmm3, xmm7
    paddw xmm7, [c193]
    movdqu xmm2, [c194]
    paddw xmm2, xmm2
    movdqu xmm13, [c195]
    movdqu xmm8, [c196]
    psubw xmm13, xmm8
    psubw xmm8, [c197]
    movdqu xmm3, [c198]
    movdqu xmm8, [c199]
    psubw xmm3, xmm8
    psubw xmm8, [c200]
    movdqu xmm0, [c201]
    movdqu xmm11, [c202]
    psubw xmm0, xmm11
    psubw xmm11, [c203]
    movdqu xmm4, [c204]
    movdqu xmm7, [c205]
    psubw xmm4, xmm7
    psubw xmm7, [c206]
    movdqu xmm15, [c207]
    psubw xmm15, xmm15
    movdqu xmm5, [c208]
    movdqu xmm9, [c209]
    paddsw xmm5, xmm9
    paddsw xmm9, [c210]
    movdqu xmm7, [c211]
    movdqu xmm0, [c212]
    paddsw xmm7, xmm0
    paddsw xmm0, [c213]
    movdqu xmm9, [c214]
    movdqu xmm6, [c215]
    paddsw xmm9, xmm6
    paddsw xmm6, [c216]
    movdqu xmm1, [c217]
    movdqu xmm10, [c218]
    paddsw xmm1, xmm10
    paddsw xmm10, [c219]
    movdqu xmm5, [c220]
    paddsw xmm5, xmm5
    movdqu xmm7, [c221]
    movdqu xmm13, [c222]
    paddusw xmm7, xmm13
    paddusw xmm13, [c223]
    movdqu xmm7, [c224]
    movdqu xmm3, [c225]
    paddusw xmm7, xmm3
    paddusw xmm3, [c226]
    movdqu xmm7, [c227]
    movdqu xmm3, [c228]
    paddusw xmm7, xmm3
    paddusw xmm3, [c229]
    movdqu xmm5, [c230]
    movdqu xmm3, [c231]
    paddusw xmm5, xmm3
    paddusw xmm3, [c232]
    movdqu xmm4, [c233]
    paddusw xmm4, xmm4
    movdqu xmm15, [c234]
    movdqu xmm8, [c235]
    psubsw xmm15, xmm8
    psubsw xmm8, [c236]
    movdqu xmm0, [c237]
    movdqu xmm8, [c238]
    psubsw xmm0, xmm8
    psubsw xmm8, [c239]
    movdqu xmm7, [c240]
    movdqu xmm5, [c241]
    psubsw xmm7, xmm5
    psubsw xmm5, [c242]
    movdqu xmm12, [c243]
    movdqu xmm1, [c244]
    psubsw xmm12, xmm1
    psubsw xmm1, [c245]
    movdqu xmm5, [c246]
    psubsw xmm5, xmm5
    movdqu xmm2, [c247]
    movdqu xmm13, [c248]
    psubusw xmm2, xmm13
    psubusw xmm13, [c249]
    movdqu xmm7, [c250]
    movdqu xmm6, [c251]
    psubusw xmm7, xmm6
    psubusw xmm6, [c252]
    movdqu xmm14, [c253]
    movdqu xmm3, [c254]
    psubusw xmm14, xmm3
    psubusw xmm3, [c255]
    movdqu xmm11, [c256]
    movdqu xmm6, [c257]
    psubusw xmm11, xmm6
    psubusw xmm6, [c258]
    movdqu xmm15, [c259]
    psubusw xmm15, xmm15
    movdqu xmm4, [c260]
    movdqu xmm3, [c261]
    pcmpeqw xmm4, xmm3
    pcmpeqw xmm3, [c262]
    movdqu xmm9, [c263]
    movdqu xmm5, [c264]
    pcmpeqw xmm9, xmm5
    pcmpeqw xmm5, [c265]
    movdqu xmm9, [c266]
    movdqu xmm12, [c267]
    pcmpeqw xmm9, xmm12
    pcmpeqw xmm12, [c268]
    movdqu xmm6, [c269]
    movdqu xmm1, [c270]
    pcmpeqw xmm6, xmm1
    pcmpeqw xmm1, [c271]
    movdqu xmm14, [c272]
    pcmpeqw xmm14, xmm14
    movdqu xmm11, [c273]
    movdqu xmm13, [c274]
    pcmpgtw xmm11, xmm13
    pcmpgtw xmm13, [c275]
    movdqu xmm2, [c276]
    movdqu xmm8, [c277]
    pcmpgtw xmm2, xmm8
    pcmpgtw xmm8, [c278]
    movdqu xmm9, [c279]
    movdqu xmm14, [c280]
    pcmpgtw xmm9, xmm14
    pcmpgtw xmm14, [c281]
    movdqu xmm13, [c282]
    movdqu xmm12, [c283]
    pcmpgtw xmm13, xmm12
    pcmpgtw xmm12, [c284]
    movdqu xmm7, [c285]
    pcmpgtw xmm7, xmm7
    movdqu xmm1, [c286]
    movdqu xmm2, [c287]
    pavgw xmm1, xmm2
    pavgw xmm2, [c288]
    movdqu xmm1, [c289]
    movdqu xmm14, [c290]
    pavgw xmm1, xmm14
    pavgw xmm14, [c291]
    movdqu xmm1, [c292]
    movdqu xmm2, [c293]
    pavgw xmm1, xmm2
    pavgw xmm2, [c294]
    movdqu xmm6, [c295]
    movdqu xmm10, [c296]
    pavgw xmm6, xmm10
    pavgw xmm10, [c297]
    movdqu xmm7, [c298]
    pavgw xmm7, xmm7
    movdqu xmm11, [c299]
    movdqu xmm7, [c300]
    pminsw xmm11, xmm7
    pminsw xmm7, [c301]
    movdqu xmm12, [c302]
    movdqu xmm5, [c303]
    pminsw xmm12, xmm5
    pminsw xmm5, [c304]
    movdqu xmm7, [c305]
    movdqu xmm2, [c306]
    pminsw xmm7, xmm2
    pminsw xmm2, [c307]
    movdqu xmm3, [c308]
    movdqu xmm4, [c309]
    pminsw xmm3, xmm4
    pminsw xmm4, [c310]
    movdqu xmm8, [c311]
    pminsw xmm8, xmm8
    movdqu xmm1, [c312]
    movdqu xmm9, [c313]
    pmaxsw xmm1, xmm9
    pmaxsw xmm9, [c314]
    movdqu xmm4, [c315]
    movdqu xmm0, [c316]
    pmaxsw xmm4, xmm0
    pmaxsw xmm0, [c317]
    movdqu xmm6, [c318]
    movdqu xmm7, [c319]
    pmaxsw xmm6, xmm7
    pmaxsw xmm7, [c320]
    movdqu xmm4, [c321]
    movdqu xmm7, [c322]
    pmaxsw xmm4, xmm7
    pmaxsw xmm7, [c323]
    movdqu xmm9, [c324]
    pmaxsw xmm9, xmm9
    movdqu xmm2, [c325]
    movdqu xmm11, [c326]
    pmullw xmm2, xmm11
    pmullw xmm11, [c327]
    movdqu xmm9, [c328]
    movdqu xmm15, [c329]
    pmullw xmm9, xmm15
    pmullw xmm15, [c330]
    movdqu xmm10, [c331]
    movdqu xmm3, [c332]
    pmullw xmm10, xmm3
    pmullw xmm3, [c333]
    movdqu xmm1, [c334]
    movdqu xmm2, [c335]
    pmullw xmm1, xmm2
    pmullw xmm2, [c336]
    movdqu xmm5, [c337]
    pmullw xmm5, xmm5
    movdqu xmm2, [c338]
    movdqu xmm4, [c339]
    pmulhw xmm2, xmm4
    pmulhw xmm4, [c340]
    movdqu xmm3, [c341]
    movdqu xmm12, [c342]
    pmulhw xmm3, xmm12
    pmulhw xmm12, [c343]
    movdqu xmm8, [c344]
    movdqu xmm12, [c345]
    pmulhw xmm8, xmm12
    pmulhw xmm12, [c346]
    movdqu xmm9, [c347]
    movdqu xmm15, [c348]
    pmulhw xmm9, xmm15
    pmulhw xmm15, [c349]
    movdqu xmm11, [c350]
    pmulhw xmm11, xmm11
    movdqu xmm9, [c351]
    movdqu xmm12, [c352]
    pmulhuw xmm9, xmm12
    pmulhuw xmm12, [c353]
    movdqu xmm13, [c354]
    movdqu xmm7, [c355]
    pmulhuw xmm13, xmm7
    pmulhuw xmm7, [c356]
    movdqu xmm9, [c357]
    movdqu xmm10, [c358]
    pmulhuw xmm9, xmm10
    pmulhuw xmm10, [c359]
    movdqu xmm11, [c360]
    movdqu xmm3, [c361]
    pmulhuw xmm11, xmm3
    pmulhuw xmm3, [c362]
    movdqu xmm11, [c363]
    pmulhuw xmm11, xmm11
    movdqu xmm7, [c364]
    movdqu xmm15, [c365]
    pmaddwd xmm7, xmm15
    pmaddwd xmm15, [c366]
    movdqu xmm13, [c367]
    movdqu xmm7, [c368]
    pmaddwd xmm13, xmm7
    pmaddwd xmm7, [c369]
    movdqu xmm7, [c370]
    movdqu xmm12, [c371]
    pmaddwd xmm7, xmm12
    pmaddwd xmm12, [c372]
    movdqu xmm5, [c373]
    movdqu xmm15, [c374]
    pmaddwd xmm5, xmm15
    pmaddwd xmm15, [c375]
    movdqu xmm6, [c376]
    pmaddwd xmm6, xmm6
    movdqu xmm8, [c377]
    movdqu xmm11, [c378]
    punpcklwd xmm8, xmm11
    punpcklwd xmm11, [c379]
    movdqu xmm15, [c380]
    movdqu xmm6, [c381]
    punpcklwd xmm15, xmm6
    punpcklwd xmm6, [c382]
    movdqu xmm15, [c383]
    movdqu xmm0, [c384]
    punpcklwd xmm15, xmm0
    punpcklwd xmm0, [c385]
    movdqu xmm12, [c386]
    movdqu xmm13, [c387]
    punpcklwd xmm12, xmm13
    punpcklwd xmm13, [c388]
    movdqu xmm7, [c389]
    punpcklwd xmm7, xmm7
    movdqu xmm3, [c390]
    movdqu xmm13, [c391]
    punpckhwd xmm3, xmm13
    punpckhwd xmm13, [c392]
    movdqu xmm1, [c393]
    movdqu xmm5, [c394]
    punpckhwd xmm1, xmm5
    punpckhwd xmm5, [c395]
    movdqu xmm9, [c396]
    movdqu xmm12, [c397]
    punpckhwd xmm9, xmm12
    punpckhwd xmm12, [c398]
    movdqu xmm3, [c399]
    movdqu xmm0, [c400]
    punpckhwd xmm3, xmm0
    punpckhwd xmm0, [c401]
    movdqu xmm11, [c402]
    punpckhwd xmm11, xmm11
    movdqu xmm13, [c403]
    movdqu xmm5, [c404]
    packsswb xmm13, xmm5
    packsswb xmm5, [c405]
    movdqu xmm5, [c406]
    movdqu xmm0, [c407]
    packsswb xmm5, xmm0
    packsswb xmm0, [c408]
    movdqu xmm7, [c409]
    movdqu xmm11, [c410]
    packsswb xmm7, xmm11
    packsswb xmm11, [c411]
    movdqu xmm12, [c412]
    movdqu xmm9, [c413]
    packsswb xmm12, xmm9
    packsswb xmm9, [c414]
    movdqu xmm13, [c415]
    packsswb xmm13, xmm13
    movdqu xmm8, [c416]
    movdqu xmm7, [c417]
    packuswb xmm8, xmm7
    packuswb xmm7, [c418]
    movdqu xmm12, [c419]
    movdqu xmm11, [c420]
    packuswb xmm12, xmm11
    packuswb xmm11, [c421]
    movdqu xmm1, [c422]
    movdqu xmm12, [c423]
    packuswb xmm1, xmm12
    packuswb xmm12, [c424]
    movdqu xmm14, [c425]
    movdqu xmm4, [c426]
    packuswb xmm14, xmm4
    packuswb xmm4, [c427]
    movdqu xmm12, [c428]
    packuswb xmm12, xmm12
    movdqu xmm4, [c429]
    movdqu xmm2, [c430]
    paddd xmm4, xmm2
    paddd xmm2, [c431]
    movdqu xmm9, [c432]
    movdqu xmm11, [c433]
    paddd xmm9, xmm11
    paddd xmm11, [c434]
    movdqu xmm1, [c435]
    movdqu xmm14, [c436]
    paddd xmm1, xmm14
    paddd xmm14, [c437]
    movdqu xmm10, [c438]
    movdqu xmm4, [c439]
    paddd xmm10, xmm4
    paddd xmm4, [c440]
    movdqu xmm13, [c441]
    paddd xmm13, xmm13
    movdqu xmm11, [c442]
    movdqu xmm8, [c443]
    psubd xmm11, xmm8
    psubd xmm8, [c444]
    movdqu xmm13, [c445]
    movdqu xmm11, [c446]
    psubd xmm13, xmm11
    psubd xmm11, [c447]
    movdqu xmm0, [c448]
    movdqu xmm10, [c449]
    psubd xmm0, xmm10
    psubd xmm10, [c450]
    movdqu xmm12, [c451]
    movdqu xmm11, [c452]
    psubd xmm12, xmm11
    psubd xmm11, [c453]
    movdqu xmm15, [c454]
    psubd xmm15, xmm15
    movdqu xmm3, [c455]
    movdqu xmm2, [c456]
    pcmpeqd xmm3, xmm2
    pcmpeqd xmm2, [c457]
    movdqu xmm9, [c458]
    movdqu xmm10, [c459]
    pcmpeqd xmm9, xmm10
    pcmpeqd xmm10, [c460]
    movdqu xmm1, [c461]
    movdqu xmm6, [c462]
    pcmpeqd xmm1, xmm6
    pcmpeqd xmm6, [c463]
    movdqu xmm14, [c464]
    movdqu xmm1, [c465]
    pcmpeqd xmm14, xmm1
    pcmpeqd xmm1, [c466]
    movdqu xmm11, [c467]
    pcmpeqd xmm11, xmm11
    movdqu xmm2, [c468]
    movdqu xmm14, [c469]
    pcmpgtd xmm2, xmm14
    pcmpgtd xmm14, [c470]
    movdqu xmm11, [c471]
    movdqu xmm5, [c472]
    pcmpgtd xmm11, xmm5
    pcmpgtd xmm5, [c473]
    movdqu xmm9, [c474]
    movdqu xmm11, [c475]
    pcmpgtd xmm9, xmm11
    pcmpgtd xmm11, [c476]
    movdqu xmm14, [c477]
    movdqu xmm6, [c478]
    pcmpgtd xmm14, xmm6
    pcmpgtd xmm6, [c479]
    movdqu xmm11, [c480]
    pcmpgtd xmm11, xmm11
    movdqu xmm9, [c481]
    movdqu xmm2, [c482]
    pmuludq xmm9, xmm2
    pmuludq xmm2, [c483]
    movdqu xmm4, [c484]
    movdqu xmm8, [c485]
    pmuludq xmm4, xmm8
    pmuludq xmm8, [c486]
    movdqu xmm1, [c487]
    movdqu xmm4, [c488]
    pmuludq xmm1, xmm4
    pmuludq xmm4, [c489]
    movdqu xmm12, [c490]
    movdqu xmm8, [c491]
    pmuludq xmm12, xmm8
    pmuludq xmm8, [c492]
    movdqu xmm14, [c493]
    pmuludq xmm14, xmm14
    movdqu xmm15, [c494]
    movdqu xmm4, [c495]
    punpckldq xmm15, xmm4
    punpckldq xmm4, [c496]
    movdqu xmm11, [c497]
    movdqu xmm7, [c498]
    punpckldq xmm11, xmm7
    punpckldq xmm7, [c499]
    movdqu xmm15, [c500]
    movdqu xmm1, [c501]
    punpckldq xmm15, xmm1
    punpckldq xmm1, [c502]
    movdqu xmm2, [c503]
    movdqu xmm3, [c504]
    punpckldq xmm2, xmm3
    punpckldq xmm3, [c505]
    movdqu xmm10, [c506]
    punpckldq xmm10, xmm10
    movdqu xmm10, [c507]
    movdqu xmm3, [c508]
    punpckhdq xmm10, xmm3
    punpckhdq xmm3, [c509]
    movdqu xmm7, [c510]
    movdqu xmm4, [c511]
    punpckhdq xmm7, xmm4
    punpckhdq xmm4, [c512]
    movdqu xmm2, [c513]
    movdqu xmm9, [c514]
    punpckhdq xmm2, xmm9
    punpckhdq xmm9, [c515]
    movdqu xmm10, [c516]
    movdqu xmm14, [c517]
    punpckhdq xmm10, xmm14
    punpckhdq xmm14, [c518]
    movdqu xmm11, [c519]
    punpckhdq xmm11, xmm11
    movdqu xmm9, [c520]
    movdqu xmm2, [c521]
    packssdw xmm9, xmm2
    packssdw xmm2, [c522]
    movdqu xmm0, [c523]
    movdqu xmm8, [c524]
    packssdw xmm0, xmm8
    packssdw xmm8, [c525]
    movdqu xmm9, [c526]
    movdqu xmm6, [c527]
    packssdw xmm9, xmm6
    packssdw xmm6, [c528]
    movdqu xmm2, [c529]
    movdqu xmm14, [c530]
    packssdw xmm2, xmm14
    packssdw xmm14, [c531]
    movdqu xmm9, [c532]
    packssdw xmm9, xmm9
    movdqu xmm6, [c533]
    movdqu xmm5, [c534]
    paddq xmm6, xmm5
    paddq xmm5, [c535]
    movdqu xmm10, [c536]
    movdqu xmm1, [c537]
    paddq xmm10, xmm1
    paddq xmm1, [c538]
    movdqu xmm7, [c539]
    movdqu xmm14, [c540]
    paddq xmm7, xmm14
    paddq xmm14, [c541]
    movdqu xmm0, [c542]
    movdqu xmm7, [c543]
    paddq xmm0, xmm7
    paddq xmm7, [c544]
    movdqu xmm3, [c545]
    paddq xmm3, xmm3
    movdqu xmm14, [c546]
    movdqu xmm5, [c547]
    psubq xmm14, xmm5
    psubq xmm5, [c548]
    movdqu xmm3, [c549]
    movdqu xmm1, [c550]
    psubq xmm3, xmm1
    psubq xmm1, [c551]
    movdqu xmm0, [c552]
    movdqu xmm4, [c553]
    psubq xmm0, xmm4
    psubq xmm4, [c554]
    movdqu xmm2, [c555]
    movdqu xmm5, [c556]
    psubq xmm2, xmm5
    psubq xmm5, [c557]
    movdqu xmm13, [c558]
    psubq xmm13, xmm13
    movdqu xmm6, [c559]
    movdqu xmm0, [c560]
    pand xmm6, xmm0
    pand xmm0, [c561]
    movdqu xmm8, [c562]
    movdqu xmm7, [c563]
    pand xmm8, xmm7
    pand xmm7, [c564]
    movdqu xmm3, [c565]
    movdqu xmm10, [c566]
    pand xmm3, xmm10
    pand xmm10, [c567]
    movdqu xmm8, [c568]
    movdqu xmm3, [c569]
    pand xmm8, xmm3
    pand xmm3, [c570]
    movdqu xmm2, [c571]
    pand xmm2, xmm2
    movdqu xmm0, [c572]
    movdqu xmm11, [c573]
    pandn xmm0, xmm11
    pandn xmm11, [c574]
    movdqu xmm15, [c575]
    movdqu xmm3, [c576]
    pandn xmm15, xmm3
    pandn xmm3, [c577]
    movdqu xmm15, [c578]
    movdqu xmm10, [c579]
    pandn xmm15, xmm10
    pandn xmm10, [c580]
    movdqu xmm15, [c581]
    movdqu xmm14, [c582]
    pandn xmm15, xmm14
    pandn xmm14, [c583]
    movdqu xmm15, [c584]
    pandn xmm15, xmm15
    movdqu xmm11, [c585]
    movdqu xmm13, [c586]
    por xmm11, xmm13
    por xmm13, [c587]
    movdqu xmm13, [c588]
    movdqu xmm5, [c589]
    por xmm13, xmm5
    por xmm5, [c590]
    movdqu xmm0, [c591]
    movdqu xmm7, [c592]
    por xmm0, xmm7
    por xmm7, [c593]
    movdqu xmm9, [c594]
    movdqu xmm0, [c595]
    por xmm9, xmm0
    por xmm0, [c596]
    movdqu xmm10, [c597]
    por xmm10, xmm10
    movdqu xmm2, [c598]
    movdqu xmm6, [c599]
    pxor xmm2, xmm6
    pxor xmm6, [c600]
    movdqu xmm10, [c601]
    movdqu xmm7, [c602]
    pxor xmm10, xmm7
    pxor xmm7, [c603]
    movdqu xmm4, [c604]
    movdqu xmm5, [c605]
    pxor xmm4, xmm5
    pxor xmm5, [c606]
    movdqu xmm6, [c607]
    movdqu xmm12, [c608]
    pxor xmm6, xmm12
    pxor xmm12, [c609]
    movdqu xmm3, [c610]
    pxor xmm3, xmm3
    movdqu xmm1, [c611]
    movdqu xmm12, [c612]
    punpcklqdq xmm1, xmm12
    punpcklqdq xmm12, [c613]
    movdqu xmm5, [c614]
    movdqu xmm15, [c615]
    punpcklqdq xmm5, xmm15
    punpcklqdq xmm15, [c616]
    movdqu xmm12, [c617]
    movdqu xmm4, [c618]
    punpcklqdq xmm12, xmm4
    punpcklqdq xmm4, [c619]
    movdqu xmm14, [c620]
    movdqu xmm15, [c621]
    punpcklqdq xmm14, xmm15
    punpcklqdq xmm15, [c622]
    movdqu xmm3, [c623]
    punpcklqdq xmm3, xmm3
    movdqu xmm0, [c624]
    movdqu xmm3, [c625]
    punpckhqdq xmm0, xmm3
    punpckhqdq xmm3, [c626]
    movdqu xmm6, [c627]
    movdqu xmm12, [c628]
    punpckhqdq xmm6, xmm12
    punpckhqdq xmm12, [c629]
    movdqu xmm13, [c630]
    movdqu xmm4, [c631]
    punpckhqdq xmm13, xmm4
    punpckhqdq xmm4, [c632]
    movdqu xmm2, [c633]
    movdqu xmm7, [c634]
    punpckhqdq xmm2, xmm7
    punpckhqdq xmm7, [c635]
    movdqu xmm14, [c636]
    punpckhqdq xmm14, xmm14
    movdqu xmm9, [c637]
    psrlw xmm9, 0
    movdqu xmm9, [c638]
    movdqu xmm3, [c639]
    psrlw xmm9, xmm3
    movdqu xmm3, [c640]
    psrlw xmm3, 1
    movdqu xmm3, [c641]
    movdqu xmm13, [c642]
    psrlw xmm3, xmm13
    movdqu xmm13, [c643]
    psrlw xmm13, 3
    movdqu xmm13, [c644]
    movdqu xmm4, [c645]
    psrlw xmm13, xmm4
    movdqu xmm3, [c646]
    psrlw xmm3, 8
    movdqu xmm3, [c647]
    movdqu xmm12, [c648]
    psrlw xmm3, xmm12
    movdqu xmm7, [c649]
    psrlw xmm7, 15
    movdqu xmm7, [c650]
    movdqu xmm3, [c651]
    psrlw xmm7, xmm3
    movdqu xmm5, [c652]
    psrlw xmm5, 16
    movdqu xmm5, [c653]
    movdqu xmm1, [c654]
    psrlw xmm5, xmm1
    movdqu xmm10, [c655]
    psrlw xmm10, 17
    movdqu xmm10, [c656]
    movdqu xmm15, [c657]
    psrlw xmm10, xmm15
    movdqu xmm5, [c658]
    psrlw xmm5, 200
    movdqu xmm5, [c659]
    movdqu xmm14, [c660]
    psrlw xmm5, xmm14
    movdqu xmm7, [c661]
    movdqu xmm6, [c662]
    psrlw xmm7, xmm6
    psrlw xmm7, [c663]
    movdqu xmm9, [c664]
    psrld xmm9, 0
    movdqu xmm9, [c665]
    movdqu xmm8, [c666]
    psrld xmm9, xmm8
    movdqu xmm1, [c667]
    psrld xmm1, 1
    movdqu xmm1, [c668]
    movdqu xmm6, [c669]
    psrld xmm1, xmm6
    movdqu xmm2, [c670]
    psrld xmm2, 3
    movdqu xmm2, [c671]
    movdqu xmm12, [c672]
    psrld xmm2, xmm12
    movdqu xmm3, [c673]
    psrld xmm3, 16
    movdqu xmm3, [c674]
    movdqu xmm2, [c675]
    psrld xmm3, xmm2
    movdqu xmm8, [c676]
    psrld xmm8, 31
    movdqu xmm8, [c677]
    movdqu xmm13, [c678]
    psrld xmm8, xmm13
    movdqu xmm6, [c679]
    psrld xmm6, 32
    movdqu xmm6, [c680]
    movdqu xmm3, [c681]
    psrld xmm6, xmm3
    movdqu xmm0, [c682]
    psrld xmm0, 33
    movdqu xmm0, [c683]
    movdqu xmm13, [c684]
    psrld xmm0, xmm13
    movdqu xmm0, [c685]
    psrld xmm0, 200
    movdqu xmm0, [c686]
    movdqu xmm4, [c687]
    psrld xmm0, xmm4
    movdqu xmm6, [c688]
    movdqu xmm4, [c689]
    psrld xmm6, xmm4
    psrld xmm6, [c690]
    movdqu xmm12, [c691]
    psrlq xmm12, 0
    movdqu xmm12, [c692]
    movdqu xmm9, [c693]
    psrlq xmm12, xmm9
    movdqu xmm1, [c694]
    psrlq xmm1, 1
    movdqu xmm1, [c695]
    movdqu xmm8, [c696]
    psrlq xmm1, xmm8
    movdqu xmm15, [c697]
    psrlq xmm15, 3
    movdqu xmm15, [c698]
    movdqu xmm11, [c699]
    psrlq xmm15, xmm11
    movdqu xmm12, [c700]
    psrlq xmm12, 32
    movdqu xmm12, [c701]
    movdqu xmm11, [c702]
    psrlq xmm12, xmm11
    movdqu xmm1, [c703]
    psrlq xmm1, 63
    movdqu xmm1, [c704]
    movdqu xmm15, [c705]
    psrlq xmm1, xmm15
    movdqu xmm1, [c706]
    psrlq xmm1, 64
    movdqu xmm1, [c707]
    movdqu xmm14, [c708]
    psrlq xmm1, xmm14
    movdqu xmm10, [c709]
    psrlq xmm10, 65
    movdqu xmm10, [c710]
    movdqu xmm14, [c711]
    psrlq xmm10, xmm14
    movdqu xmm4, [c712]
    psrlq xmm4, 200
    movdqu xmm4, [c713]
    movdqu xmm9, [c714]
    psrlq xmm4, xmm9
    movdqu xmm1, [c715]
    movdqu xmm2, [c716]
    psrlq xmm1, xmm2
    psrlq xmm1, [c717]
    movdqu xmm2, [c718]
    psraw xmm2, 0
    movdqu xmm2, [c719]
    movdqu xmm12, [c720]
    psraw xmm2, xmm12
    movdqu xmm4, [c721]
    psraw xmm4, 1
    movdqu xmm4, [c722]
    movdqu xmm13, [c723]
    psraw xmm4, xmm13
    movdqu xmm3, [c724]
    psraw xmm3, 3
    movdqu xmm3, [c725]
    movdqu xmm10, [c726]
    psraw xmm3, xmm10
    movdqu xmm11, [c727]
    psraw xmm11, 8
    movdqu xmm11, [c728]
    movdqu xmm5, [c729]
    psraw xmm11, xmm5
    movdqu xmm10, [c730]
    psraw xmm10, 15
    movdqu xmm10, [c731]
    movdqu xmm15, [c732]
    psraw xmm10, xmm15
    movdqu xmm14, [c733]
    psraw xmm14, 16
    movdqu xmm14, [c734]
    movdqu xmm3, [c735]
    psraw xmm14, xmm3
    movdqu xmm5, [c736]
    psraw xmm5, 17
    movdqu xmm5, [c737]
    movdqu xmm0, [c738]
    psraw xmm5, xmm0
    movdqu xmm12, [c739]
    psraw xmm12, 200
    movdqu xmm12, [c740]
    movdqu xmm14, [c741]
    psraw xmm12, xmm14
    movdqu xmm10, [c742]
    movdqu xmm7, [c743]
    psraw xmm10, xmm7
    psraw xmm10, [c744]
    movdqu xmm9, [c745]
    psrad xmm9, 0
    movdqu xmm9, [c746]
    movdqu xmm2, [c747]
    psrad xmm9, xmm2
    movdqu xmm0, [c748]
    psrad xmm0, 1
    movdqu xmm0, [c749]
    movdqu xmm1, [c750]
    psrad xmm0, xmm1
    movdqu xmm5, [c751]
    psrad xmm5, 3
    movdqu xmm5, [c752]
    movdqu xmm4, [c753]
    psrad xmm5, xmm4
    movdqu xmm6, [c754]
    psrad xmm6, 16
    movdqu xmm6, [c755]
    movdqu xmm8, [c756]
    psrad xmm6, xmm8
    movdqu xmm1, [c757]
    psrad xmm1, 31
    movdqu xmm1, [c758]
    movdqu xmm12, [c759]
    psrad xmm1, xmm12
    movdqu xmm4, [c760]
    psrad xmm4, 32
    movdqu xmm4, [c761]
    movdqu xmm11, [c762]
    psrad xmm4, xmm11
    movdqu xmm6, [c763]
    psrad xmm6, 33
    movdqu xmm6, [c764]
    movdqu xmm3, [c765]
    psrad xmm6, xmm3
    movdqu xmm6, [c766]
    psrad xmm6, 200
    movdqu xmm6, [c767]
    movdqu xmm11, [c768]
    psrad xmm6, xmm11
    movdqu xmm1, [c769]
    movdqu xmm14, [c770]
    psrad xmm1, xmm14
    psrad xmm1, [c771]
    movdqu xmm15, [c772]
    psllw xmm15, 0
    movdqu xmm15, [c773]
    movdqu xmm4, [c774]
    psllw xmm15, xmm4
    movdqu xmm6, [c775]
    psllw xmm6, 1
    movdqu xmm6, [c776]
    movdqu xmm0, [c777]
    psllw xmm6, xmm0
    movdqu xmm6, [c778]
    psllw xmm6, 3
    movdqu xmm6, [c779]
    movdqu xmm3, [c780]
    psllw xmm6, xmm3
    movdqu xmm0, [c781]
    psllw xmm0, 8
    movdqu xmm0, [c782]
    movdqu xmm6, [c783]
    psllw xmm0, xmm6
    movdqu xmm15, [c784]
    psllw xmm15, 15
    movdqu xmm15, [c785]
    movdqu xmm8, [c786]
    psllw xmm15, xmm8
    movdqu xmm6, [c787]
    psllw xmm6, 16
    movdqu xmm6, [c788]
    movdqu xmm14, [c789]
    psllw xmm6, xmm14
    movdqu xmm7, [c790]
    psllw xmm7, 17
    movdqu xmm7, [c791]
    movdqu xmm10, [c792]
    psllw xmm7, xmm10
    movdqu xmm9, [c793]
    psllw xmm9, 200
    movdqu xmm9, [c794]
    movdqu xmm8, [c795]
    psllw xmm9, xmm8
    movdqu xmm6, [c796]
    movdqu xmm2, [c797]
    psllw xmm6, xmm2
    psllw xmm6, [c798]
    movdqu xmm1, [c799]
    pslld xmm1, 0
    movdqu xmm1, [c800]
    movdqu xmm9, [c801]
    pslld xmm1, xmm9
    movdqu xmm15, [c802]
    pslld xmm15, 1
    movdqu xmm15, [c803]
    movdqu xmm6, [c804]
    pslld xmm15, xmm6
    movdqu xmm0, [c805]
    pslld xmm0, 3
    movdqu xmm0, [c806]
    movdqu xmm13, [c807]
    pslld xmm0, xmm13
    movdqu xmm0, [c808]
    pslld xmm0, 16
    movdqu xmm0, [c809]
    movdqu xmm13, [c810]
    pslld xmm0, xmm13
    movdqu xmm2, [c811]
    pslld xmm2, 31
    movdqu xmm2, [c812]
    movdqu xmm4, [c813]
    pslld xmm2, xmm4
    movdqu xmm6, [c814]
    pslld xmm6, 32
    movdqu xmm6, [c815]
    movdqu xmm14, [c816]
    pslld xmm6, xmm14
    movdqu xmm0, [c817]
    pslld xmm0, 33
    movdqu xmm0, [c818]
    movdqu xmm1, [c819]
    pslld xmm0, xmm1
    movdqu xmm2, [c820]
    pslld xmm2, 200
    movdqu xmm2, [c821]
    movdqu xmm5, [c822]
    pslld xmm2, xmm5
    movdqu xmm6, [c823]
    movdqu xmm3, [c824]
    pslld xmm6, xmm3
    pslld xmm6, [c825]
    movdqu xmm3, [c826]
    psllq xmm3, 0
    movdqu xmm3, [c827]
    movdqu xmm12, [c828]
    psllq xmm3, xmm12
    movdqu xmm13, [c829]
    psllq xmm13, 1
    movdqu xmm13, [c830]
    movdqu xmm5, [c831]
    psllq xmm13, xmm5
    movdqu xmm9, [c832]
    psllq xmm9, 3
    movdqu xmm9, [c833]
    movdqu xmm15, [c834]
    psllq xmm9, xmm15
    movdqu xmm3, [c835]
    psllq xmm3, 32
    movdqu xmm3, [c836]
    movdqu xmm12, [c837]
    psllq xmm3, xmm12
    movdqu xmm14, [c838]
    psllq xmm14, 63
    movdqu xmm14, [c839]
    movdqu xmm9, [c840]
    psllq xmm14, xmm9
    movdqu xmm8, [c841]
    psllq xmm8, 64
    movdqu xmm8, [c842]
    movdqu xmm14, [c843]
    psllq xmm8, xmm14
    movdqu xmm11, [c844]
    psllq xmm11, 65
    movdqu xmm11, [c845]
    movdqu xmm0, [c846]
    psllq xmm11, xmm0
    movdqu xmm9, [c847]
    psllq xmm9, 200
    movdqu xmm9, [c848]
    movdqu xmm8, [c849]
    psllq xmm9, xmm8
    movdqu xmm15, [c850]
    movdqu xmm3, [c851]
    psllq xmm15, xmm3
    psllq xmm15, [c852]
    movdqu xmm11, [c853]
    psrldq xmm11, 0
    movdqu xmm3, [c854]
    psrldq xmm3, 1
    movdqu xmm1, [c855]
    psrldq xmm1, 3
    movdqu xmm11, [c856]
    psrldq xmm11, 7
    movdqu xmm2, [c857]
    psrldq xmm2, 8
    movdqu xmm15, [c858]
    psrldq xmm15, 9
    movdqu xmm11, [c859]
    psrldq xmm11, 15
    movdqu xmm11, [c860]
    psrldq xmm11, 16
    movdqu xmm13, [c861]
    psrldq xmm13, 200
    movdqu xmm13, [c862]
    pslldq xmm13, 0
    movdqu xmm5, [c863]
    pslldq xmm5, 1
    movdqu xmm1, [c864]
    pslldq xmm1, 3
    movdqu xmm3, [c865]
    pslldq xmm3, 7
    movdqu xmm1, [c866]
    pslldq xmm1, 8
    movdqu xmm14, [c867]
    pslldq xmm14, 9
    movdqu xmm4, [c868]
    pslldq xmm4, 15
    movdqu xmm6, [c869]
    pslldq xmm6, 16
    movdqu xmm4, [c870]
    pslldq xmm4, 200
    EXIT
    align 16
c0: dq 0x1A2405103012D01, 0x800000EEED04B940
c1: dq 0x7FAD407FAC01014B, 0x810084E09C190F3B
c2: dq 0xB3FFFF007F8128F4, 0x19B00E780017F25
c3: dq 0x8101FF530181407F, 0x2C48814D3C013D01
c4: dq 0x900134804B01EE34, 0xE0FFA9FFA2007A40
c5: dq 0xBB40367FCB6F7F40, 0x817F81807F00D3C8
c6: dq 0xC641967F111BFF80, 0x9B7C0001FFE18140
c7: dq 0x7F3E20100049147F, 0xFF0139FF7F49F73D
c8: dq 0x4091CF6E80114001, 0xFF64D60080187D80
c9: dq 0x7F817E400A294040, 0x81F700414002006F
c10: dq 0x400161FF79048140, 0x4940938155FF811F
c11: dq 0xB524FF8153289581, 0xFFC15881E3150081
c12: dq 0x3CCBC77D17F01FF, 0xF2A331FFBB817F8D
c13: dq 0xE9018052008100FF, 0x2CBFF1A8186007F
c14: dq 0x19106FF3CEF394A, 0x818B400143804080
c15: dq 0x1818229C8800001, 0x81D20180824E00FF
c16: dq 0x37F8FFF817A63, 0x1807380FF18B0ED
c17: dq 0x202B0002800280FF, 0xFF81727F40A8FF40
c18: dq 0xB9B4081FF00807F, 0xA7FF440000810080
c19: dq 0xF7F8100DC5359, 0x4080BD0181FFB181
c20: dq 0x81B440FF7D7F337F, 0x7C800000FFFF94A4
c21: dq 0x40808101810081CD, 0x898000B07F7F71FF
c22: dq 0x487C017C01810140, 0xFFFF0000814C405D
c23: dq 0xFF011801187FFF7F, 0xFFDA004040320043
c24: dq 0xFF010100C0017F80, 0xF5407F3200007600
c25: dq 0x8000803B400130B9, 0x40804053FF018101
c26: dq 0x800181E97F7F40, 0x7F817F7FFFB4E900
c27: dq 0xFFFF0E400153DAC7, 0xFF2C7FB68833819E
c28: dq 0xE27F9C807F0080EC, 0x81811C7F0040807F
c29: dq 0x81EA7F8181668101, 0x401A015B404045FF
c30: dq 0x8181800140FF117F, 0x3B8181FF80812801
c31: dq 0x7FCE168101400100, 0xFF47FFFF7F8101B7
c32: dq 0x507FE8FFDA30AE40, 0xFF80FF727F80507A
c33: dq 0xFF554095FF00FFCB, 0x7F0181019BCC401A
c34: dq 0x7F8181F9FD404880, 0x680012400040408B
c35: dq 0x1B30FFCADEFF4001, 0x7F01E84001AF8001
c36: dq 0x9AD98001FF1680, 0xE97FCF6EFF7F8101
c37: dq 0x42815D4500941881, 0xB09B530140B1018A
c38: dq 0x5B406800B10181D0, 0xFFC400FF018180AF
c39: dq 0x1810040808179FF, 0x3B8281FF5481F0E6
c40: dq 0x1840FFBF4040FF, 0x7147818001F5017F
c41: dq 0xC900827FFFFF167F, 0x80FF8101FF26FC7F
c42: dq 0x7F807F017F800174, 0x807FAA0081810FFF
c43: dq 0x280FF4001FF80E6, 0x2301802257405C7F
c44: dq 0x81DFDB006D5DDF81, 0x8D807F8198017F81
c45: dq 0x818BFF7FFF404080, 0xFF4B007F475500E1
c46: dq 0x807FFF07607F817F, 0x7F2F8000E8358011
c47: dq 0xD37F818081798024, 0xFF01017D814080E1
c48: dq 0x807F03CE01818000, 0xFF32403740010DFF
c49: dq 0xFFFFDE32F24040CD, 0x81812001DDFF00
c50: dq 0x786B8A01807FFF7F, 0x928109FF40014F1D
c51: dq 0x5FFF20BC40014040, 0x2BFF8137D27FB401
c52: dq 0x7F403B50BA7FFF60, 0x9740019A38017F6F
c53: dq 0x407F7F7F804D0001, 0x808000BAFB407F40
c54: dq 0xDF017FB8FFFF81A8, 0x7F7F804040013481
c55: dq 0xBC8100400100FF7F, 0x817FA0017D7F8181
c56: dq 0xFF7F019A7F408000, 0x7F2ECB808100A700
c57: dq 0x40A84013ED49FF40, 0x7F72FF3F4080FF94
c58: dq 0x8C6D00CB64FF0100, 0x5280FFFF553300
c59: dq 0x7B0A010093083DD2, 0xFF01DB84BFC4FF75
c60: dq 0x917F40FFC6FF8029, 0x611F0000354080
c61: dq 0x6B818040FF404081, 0x27C88B80409440
c62: dq 0x46E4406C3361FF40, 0xD2669F8100ECFF7F
c63: dq 0x8138CE4000818001, 0x10047F00CA802781
c64: dq 0x800000004081CC50, 0x140C580FF5781FF
c65: dq 0x7F81FFDCFF407F01, 0x81D5E440FF8100FF
c66: dq 0x8000817FFF954040, 0x81ED0140BE408000
c67: dq 0x310129A6000085D8, 0xFF1101464901AE70
c68: dq 0x80017F227F00803C, 0x19FFB95006E407F
c69: dq 0xC240409C4DD101FF, 0xFF0080813F4081B3
c70: dq 0x8081FF817F00D838, 0x7F809B7F81AF00
c71: dq 0x1FFFE0140008780, 0x43FF6F8100807F29
c72: dq 0x7FFFA826817F7454, 0x7F0100BEFA40803F
c73: dq 0x95188F0040407B00, 0x80F80001FF064040
c74: dq 0xFDD6808081FFA8CB, 0x7F7F81FFD96F01FF
c75: dq 0x81D1800000FF4062, 0x400140973601D001
c76: dq 0xFFD31E40B1FF257F, 0xD201E940407E5D0D
c77: dq 0xE164FF7F8101C69A, 0x40FF7F348145FF81
c78: dq 0xB77FFF814A8140, 0x801C40402E006B21
c79: dq 0xFDFF01007A2D0057, 0x14000A04FA00EA0
c80: dq 0x804071818180EA40, 0x8080017F7FB240B4
c81: dq 0xFF557FE8F480407F, 0xAA527F804FFF0081
c82: dq 0x7F61D84040389E40, 0x812BE87D0000811A
c83: dq 0x18EFF896A000001, 0xD585001B00E10B01
c84: dq 0x808103A600004071, 0x2DC680807FE79380
c85: dq 0xFF7F01807F2D8140, 0x817F7CD27FD5FF0F
c86: dq 0xFF0100000181F3A8, 0x8100810100D58101
c87: dq 0x4001E700FF950181, 0x7FA40140FF813D3E
c88: dq 0xFFFF009A0F81FB00, 0x7E80837F00800001
c89: dq 0x2F2F409F7F7F0FF1, 0x1B6361B8140017F
c90: dq 0x7ADE80A740F08062, 0xECFF068001D2FF01
c91: dq 0x1EFF40807F805DFF, 0x40017B00808140
c92: dq 0xA9407F0F40A08040, 0xDA8940810100FFB6
c93: dq 0x234001FC528049A9, 0xFF81FF4000D101A6
c94: dq 0x23833DC0FF800180, 0xA2F0818A0D4033FF
c95: dq 0x40633481D17F0081, 0x81FF01BDFF2580FF
c96: dq 0x8100A44BB7397F06, 0x6940D9807F804057
c97: dq 0x2C0040007F81DA12, 0x81409440DD0001
c98: dq 0x803FCE4001008077, 0x4001677527857F81
c99: dq 0x803CBCD10000CF81, 0xFF8136017AD381F5
c100: dq 0xFF047D808175402A, 0x6B3581A4816B9300
c101: dq 0x7F7F7F8586DA405D, 0x4057400100814001
c102: dq 0x8081800A808187FF, 0xFF7B00817F7F817F
c103: dq 0x58181F8047F61, 0x681D08013814081
c104: dq 0x1DA7F48FF8140, 0x1965C7FD3E28BB5
c105: dq 0x724B7F5000003F80, 0x2D0100DEFF79BF80
c106: dq 0xFF000000FF407981, 0xF00F81005600529C
c107: dq 0x7F0100F01540C14E, 0xFFFFD64040E58F00
c108: dq 0xFF80810080C30019, 0x807F4584805940EB
c109: dq 0xBEFFFFFFFF7F01B3, 0xF0004040A1FF8180
c110: dq 0x818080B37F4040B2, 0x40C08AFF9F807FBE
c111: dq 0xD1016DFF110001FF, 0x7FF59D00B000C400
c112: dq 0x7F01CAF8007F0181, 0xC15680010080B5
c113: dq 0x7F786EEA0140C819, 0x40D6B880004052E2
c114: dq 0x68AD01F5EB5E7F40, 0xFF8081015AFF407F
c115: dq 0x1FF8123F5000100, 0xF1A7FF40803A80DA
c116: dq 0x530140E140FF0142, 0xFF0101409CD47F01
c117: dq 0xFF407B41C3364040, 0x1CD7F8181FFF5
c118: dq 0x8905A801F280BF40, 0x7F80917F160040
c119: dq 0x681F00014301A480, 0x192810101F9FF08
c120: dq 0xFF408085011DA97F, 0x4E018081FA7F7F87
c121: dq 0x3581917F815101FF, 0x40818AE3FFD67C40
c122: dq 0x18080008CFF007F, 0x7F00817F0101BB01
c123: dq 0x6F555FFF40403600, 0x6D81427F007F19FF
c124: dq 0xFFC380407FB88B7F, 0x81FF4180FF7F8070
c125: dq 0xE22F019880408101, 0x8080001C007F437F
c126: dq 0x400180FFC600E1E4, 0x80FFAEFA4C810080
c127: dq 0x87D3677FF0FF817F, 0x811894813040977F
c128: dq 0x406C280023010101, 0xD05C9D6AE3FFD340
c129: dq 0x817F005E0D98FF80, 0x816E819A7F803F80
c130: dq 0x4C7F8040D0FF5201, 0x9518407FB533FF81
c131: dq 0x61C704ED81EF73, 0x1D44D80FF017F81
c132: dq 0x81FF01B9FF7F85A2, 0xFF403BA9C7817F01
c133: dq 0x1F8406280808040, 0xA286C7FF69018181
c134: dq 0x81408240CBFF00D0, 0x8181409181408E98
c135: dq 0x807F80FF01D5C180, 0x817F427F7FD001
c136: dq 0x40FF62152400F0FF, 0x7F005A7F270040C5
c137: dq 0x1B0802862BF8080, 0xB6138E9ACE7F7459
c138: dq 0x408101AB4095A301, 0x811701004075AD81
c139: dq 0x808180E68081FF, 0xC2AD47802DB17F81
c140: dq 0x11081BE807F8040, 0x4200060080A0BC80
c141: dq 0x81476F00FAF701B2, 0x8100FFFFD0FF7F
c142: dq 0x9245407F917F9A81, 0x6380400FFF80409C
c143: dq 0x409C01229F7F4001, 0xFF8C0132DA81FF5A
c144: dq 0x814047E3FF8100, 0x918021E4B63A619A
c145: dq 0x81FF80400000D900, 0x80407F318280A600
c146: dq 0x400000E440FF6A, 0xFBB50081D4C54081
c147: dq 0x74F001408113EFC1, 0x800101800001F800
c148: dq 0x81AA0B814062806A, 0x7FFA00AA404F807F
c149: dq 0x327281EAFF6E4040, 0xFF807FEF012E72
c150: dq 0x80FFDCFF00FFFF16, 0x7881F422FF5F177F
c151: dq 0x4481014042AD81C7, 0xC04037C180407F80
c152: dq 0x9E80839F80E20000, 0x1F004200818C8078
c153: dq 0xFFFF650000400180, 0x86D1FF3FFD810081
c154: dq 0x39009D01C0017F81, 0xB7818180FF81007F
c155: dq 0x81818081015236FF, 0x1401BA3D01444040
c156: dq 0xE066FF00D81F81FF, 0x31401DDA013F0180
c157: dq 0x81B1FF7AB401837F, 0x7F7F8080E80156FF
c158: dq 0x80FF1FFF7FA71781, 0x8EAB408140A0DA04
c159: dq 0xAC800180FFFF401F, 0x140DD7F00808BAF
c160: dq 0x5B810181A8405240, 0x7804680DCA2FF
c161: dq 0x30000101EFE600FF, 0x1F010080000000AA
c162: dq 0x61445082FF40FF, 0x747F80ED800100
c163: dq 0xFF08BA81010101, 0x1490081C4276018
c164: dq 0x8130400101B28123, 0x807FAE4000807F01
c165: dq 0x10C7405401A4FFFF, 0x1E03C2100E997
c166: dq 0x7F80400142001C80, 0x818E40FFDF400180
c167: dq 0x7F010108213E4094, 0x40588080F07F30
c168: dq 0x81BA0A807FB60100, 0x401780C460602001
c169: dq 0x170008140FF01FF, 0x987F718001019B
c170: dq 0x7F80008081A48080, 0x81FF807F404000A8
c171: dq 0xFF6400FF0083FF8E, 0xCAFB8100C0AB7F01
c172: dq 0x72802D7F7F258181, 0x807F5717401C81BD
c173: dq 0x78818168CA014040, 0x816B40D540FF4081
c174: dq 0xFFFFEF007F7F7F2C, 0x7F9301F90000005D
c175: dq 0xA986407F7A45904A, 0x804C400101808100
c176: dq 0xD02DAA007F010101, 0x407F004901677FAF
c177: dq 0x7FFF3B40FF814041, 0x3516498111808040
c178: dq 0x7680377FF301DE81, 0x10140FF00FF7F
c179: dq 0x1818200E42B7FFF, 0xACD9062297F0181
c180: dq 0xFF7F7F404F408126, 0x40FF80FF82F100A7
c181: dq 0xA100FF001C330139, 0x1020D0081FF3AE2
c182: dq 0x9C0F800000016CE2, 0x100FFFFFFFF2371
c183: dq 0x1858801000100, 0xAE458000930D00FF
c184: dq 0x8000A15800004D17, 0xC0BFADF263F75FDD
c185: dq 0x1007FFF800000FF, 0x1FFFF00007FFF
c186: dq 0x7FFF1ED00000, 0x17FFFFFFF8001
c187: dq 0x781C3EA900FF7B26, 0xFF8F6C01008000
c188: dq 0x800122D900016D4B, 0x100AE137FFF8000
c189: dq 0x1000100FFFF0000, 0xFFFF0001FFFF7B26
c190: dq 0x8001FFFF7FFF0000, 0x8000A8FD00010001
c191: dq 0x27FE8000FFFF, 0x6EEAFFFFFFFF9F7A
c192: dq 0x3D5F8000010016C6, 0x80000001FFFFBDC7
c193: dq 0x146AD1C2F3AC3, 0x3A677FFFFFFFFFFF
c194: dq 0x8001F2EEDE2100FF, 0xFF74CC5098
c195: dq 0x800180018000C3B6, 0x11C88000FFFF7FFF
c196: dq 0x8000800080010000, 0x3CE70CF1800103A9
c197: dq 0x80017FFFF6E79FFC, 0x800100FF02A40100
c198: dq 0xFF0329FBAD8001, 0x1001AAF7B430100
c199: dq 0x7FFF0100F95C, 0x7FFF800180000100
c200: dq 0x8759A0CA583546ED, 0xC354F87000FF06F1
c201: dq 0x80007FFF0100, 0x150960000FFFF
c202: dq 0xA078000FFFF, 0xFF01000100
c203: dq 0x100D84EC2F00000, 0x100EE49E1285215
c204: dq 0xFFFF00FF00000000, 0xAD552688001136E
c205: dq 0x7FFF3DB6D21408A4, 0xF1B0FFFF80008000
c206: dq 0xFFD833496D0000, 0xFF0001E9C7
c207: dq 0x1010000017FFF, 0x80017D3584378000
c208: dq 0x41A60000B68800FF, 0xFF1A9500FF0100
c209: dq 0x100FFFFFFFFFF, 0xDD64D0B4800020A8
c210: dq 0x8001FFFF00019CDE, 0xFFFF8000F121
c211: dq 0x87F700FF00004DFE, 0x7FFF0100C10C8000
c212: dq 0xFF817900FF, 0x4602000171F200FF
c213: dq 0xB7970100FFFF, 0xCFE5DDB3800000FF
c214: dq 0x38E500FFFFFF7FFF, 0x7FFFD3E9D1F39295
c215: dq 0x20ADB15707478000, 0xE6D65EB71E638001
c216: dq 0x2B7CD00D59CD7FFF, 0x17FFF7FFF
c217: dq 0x656BFFFF0C8C8001, 0x7FFF0001FFFFC1D4
c218: dq 0x277E7FFF55F70100, 0xFF00FFC59F0001
c219: dq 0x8001000000008001, 0xFFFFBE781C0F9E61
c220: dq 0xE2D3FFFF80018000, 0xFFFF3592A6F18B92
c221: dq 0xBB2F810B7FFF7FFF, 0x100000000017FFF
c222: dq 0xE632800095324B8C, 0xC64A00FFCD2819B3
c223: dq 0xFFFF7FFFFFFF7FFF, 0xB78520667FFF57D3
c224: dq 0xFFFF57C380018000, 0x800100FFFFFFFFFF
c225: dq 0x37F6EA9200007199, 0xFF010080018000
c226: dq 0x800000FF01003E16, 0x6DAD7FFFB8D2FFFF
c227: dq 0x8000FFFFFFFF2984, 0x75667FFF2E9900FF
c228: dq 0x1AD2FFFF74A55C09, 0x100FF60E98000
c229: dq 0x4DEE9DF754780001, 0xFFFF957C24151105
c230: dq 0xFFFF010000FF, 0x80005597535C
c231: dq 0x1D028000ED35FFFF, 0x1000F1704285310
c232: dq 0xD05D010000FFFFFF, 0x9B7C577D5B548001
c233: dq 0x1D9C0001990EFFFF, 0x7FFFDA2A00FF0100
c234: dq 0xFFFF5D687FFFA9F5, 0xFFFFFF7FFF0000
c235: dq 0x18000EA7000FF, 0x93D2F3AC80018001
c236: dq 0x95490000E4AB8000, 0x8001DB8A5C9F0C23
c237: dq 0xAC4A0100800100FF, 0xB10000FFFF0000
c238: dq 0x648700003BD3517B, 0x17C5EFFFFFFFF
c239: dq 0x100006B6F7FFF, 0xFFFF0100CBD30100
c240: dq 0x1000180008000, 0xE3B5EA9221B67FFF
c241: dq 0x800101007FFF9566, 0x10080006D7582A9
c242: dq 0x8001B85300008001, 0xFFFF000059388001
c243: dq 0x517A01003FCDEC8B, 0xC2C3564500018000
c244: dq 0x7FFF00FF64E57FFF, 0x40D77FFF7CC200FF
c245: dq 0xB00C7FFF80000000, 0xE6BB80007FFF44C9
c246: dq 0x7FFF000100016B9D, 0xF36580006DAFC9C6
c247: dq 0x1D1C10D8FFFF0000, 0x1000100FFFF7FFF
c248: dq 0xFF7FFF6E7C8000, 0x80010100700ED52A
c249: dq 0x1584DDB080015BBB, 0x263C94E248A93AB
c250: dq 0xB44D86A1644B7FFF, 0x72A6800080011C13
c251: dq 0xFFFF00FF7FFF0100, 0x80017FFFA9A20001
c252: dq 0x8001E2DF01008000, 0x100FFFF00018000
c253: dq 0x29C9B1941C4E7FFF, 0xB471FFFF800100FF
c254: dq 0x71587FFFE68200FF, 0xB777010012A400FF
c255: dq 0x6147FFFF4AD1CD1F, 0xFFFFC54FFFFF7430
c256: dq 0xD7A1800040088000, 0xAA650100FFFFFFFF
c257: dq 0xFFFF6E280100E9A9, 0x8001299BF78DA9E7
c258: dq 0x7FFF00FF0001, 0x1BE5C92780012D9E
c259: dq 0x50F6800100FF00B3, 0x8A81FFFF00017E0A
c260: dq 0x539AB3CFEB520001, 0x8000000180000001
c261: dq 0x800092A2354F95F9, 0xFFFF077100011979
c262: dq 0xFFFF7FFFFA157FFF, 0x17FFF7FFF47CE
c263: dq 0x3A520001110D723C, 0xFF000001000001
c264: dq 0x1010000018000, 0x80019A4B00018F8E
c265: dq 0x5529010000010001, 0xFFFF8ED601001E70
c266: dq 0x80018000FFFF282B, 0x4C8937870001AA4C
c267: dq 0x8000000000010000, 0x8000C07F00FF79A0
c268: dq 0x136B00017FFF0000, 0xC9D9045528C2FFFF
c269: dq 0x91A50526EB6FFFF, 0x1000100FFAABF
c270: dq 0xFFFF0100506000FF, 0x278CFFFF80004486
c271: dq 0x7FFF000100FF8B71, 0x39838000FD0B0100
c272: dq 0xE1255A00000EBC7, 0x3102ED5C25998000
c273: dq 0xD81100FFFFFFFFFF, 0x101CC01007FFF
c274: dq 0xB2E3C6AF01009E42, 0x402B7FFF
c275: dq 0x9D3E76FA00018001, 0x80005D5C01000001
c276: dq 0x800004BA0100B469, 0x6D574876C4A03F87
c277: dq 0x7FFF000100FF8000, 0x2C0200017DF07FFF
c278: dq 0x1D51625980018CAB, 0x80007EA400FF4FD7
c279: dq 0x7FFF7FFF80A2C909, 0xFFCE40FFFF0001
c280: dq 0xB85B8000B05F0000, 0x8001994BCF5500FF
c281: dq 0x80008000F7A39772, 0x126C301009666
c282: dq 0xFFFF8001010000FF, 0x1008001F5628000
c283: dq 0xA0C3FFFFC7D65DC0, 0xFFFF00FF4A6100FF
c284: dq 0x7FFF800100FFE58F, 0x1800000010100
c285: dq 0x80010000FFFF0000, 0x1980001FFFF0000
c286: dq 0xFED72E61A5A8EE71, 0x9AB21C528001B649
c287: dq 0x9BC01008001ED95, 0x21EC00018001
c288: dq 0x8001FFFF0001A6B3, 0x9373A8C56FEE0100
c289: dq 0x1004D05CC112140, 0xB2C300FFFFFF00FF
c290: dq 0x921C7FFF8001CA7F, 0xD637FFF00007FFF
c291: dq 0xE1DA80000001F0C8, 0x7FFF00002A5B0001
c292: dq 0x8A8500018000F1CA, 0xC4178DA901005C9C
c293: dq 0xFF000180010001, 0x4DBCA63E7FFF2ED0
c294: dq 0x100FFFF7FFF7FFF, 0xFFFF891300004F74
c295: dq 0x30BED7D7463A8000, 0x48C8001FFFF0001
c296: dq 0x7FFF9B76800000FF, 0x41ACFFFF8001329D
c297: dq 0x390C835A00FF0100, 0x100D0CE797E7FFF
c298: dq 0x271B80000001FFF7, 0xFF9EF9010000FF
c299: dq 0x7FFF800080010100, 0x42EBA95B01000100
c300: dq 0x7FFF00FF2BD2FFFF, 0x8000A23801007477
c301: dq 0xD368F6D00001740D, 0xFF4DCF54668000
c302: dq 0x59B4FFFFCB968001, 0x18301000001EDC5
c303: dq 0xFF00FF80007FFF, 0xFFF61E94B9A7B7
c304: dq 0x9AE87FFF55234016, 0xFFFF00013B036B1E
c305: dq 0x52828001FFA000FF, 0x6E558001F58470E5
c306: dq 0x1008001800000FF, 0x80013078FFFF8001
c307: dq 0xFF000174D09F71, 0x100FFC1440000
c308: dq 0xFFFFABFBC5C4DF86, 0x90AF01009DACA0DE
c309: dq 0x1800000FF531E, 0x8001FFFF0073A7F0
c310: dq 0xFFFF38B9FFFF7FFF, 0x10000010100FFFF
c311: dq 0x130BF00FFFFFF, 0xFFFFBAE0F0890100
c312: dq 0x616200000000A388, 0x100800001002C6C
c313: dq 0x100A70200002565, 0x10000007FFF0100
c314: dq 0x80010B9DFA717FFF, 0x800000007FFFD4AC
c315: dq 0xCA4F5419C6D9C4D5, 0x7FFF00FFD9AE00FF
c316: dq 0x37A2800100016284, 0xB86100FF0000FB40
c317: dq 0xAD7AFFFF15FA8001, 0x8000800080018001
c318: dq 0x1DFE500002AEC, 0x80010100FFFF
c319: dq 0x2BA34B39FFFF5BAC, 0x1CCE40000
c320: dq 0xFFFF000000FFE913, 0x849D00FFCBBBCE7E
c321: dq 0xF72AFFFF0100A800, 0xA5F280001B9F0100
c322: dq 0xC0CB8001800000FF, 0x800011130100FFFF
c323: dq 0x7FFFFFFF000042B8, 0x10080013C2D8001
c324: dq 0x1008001C6BCF6B2, 0x80006628FFFF8000
c325: dq 0x100516B7FFF7455, 0xB7660100E3179BA9
c326: dq 0x4128001BBE2, 0xA2060000C3818001
c327: dq 0x99B7F5FBE49500FF, 0xC1F4000080018000
c328: dq 0xB3EF1404342FCDD1, 0x53C2FD3A00018000
c329: dq 0x1827E6FED7FFF, 0xFFE50200FF66AE
c330: dq 0xC8E100FF00FF0100, 0x80011FD901008000
c331: dq 0x10001A846FFFF, 0x1FFFF1F17FFFF
c332: dq 0xB4D97917FFFD74F, 0x6CF6FFFF00010100
c333: dq 0xFFA2E4FFFF7F6E, 0xFFFF0000F9478000
c334: dq 0x666B00FF7FFF0001, 0xCB2500FFD2530000
c335: dq 0x2A207FFF800000FF, 0x5F3500FF00FF2F1C
c336: dq 0x7FFFF6747FFF00FF, 0x8AD587BD01007FFF
c337: dq 0x7FFF01007FFFFFFF, 0x987844A9FFFF1FA7
c338: dq 0xFFFF0000FB719BB4, 0x8001D17F01000001
c339: dq 0x4A1500FFFA9CB112, 0x7FFF00016F6D8000
c340: dq 0x7FFF123E00FF8000, 0x8001C3D87FFF
c341: dq 0xF51B8000CA5EFFFF, 0xFFFF211BFFFF5912
c342: dq 0x10000E1500000, 0x993C7FFF8000FFFF
c343: dq 0x8000F9C946570000, 0x7FFF4758FFFF0100
c344: dq 0x80007FFF8001, 0x1FFFF6A0C00FF
c345: dq 0xE825000055F32311, 0xDF3D913195F30100
c346: dq 0x7FFF0100000100FF, 0x8000800126729949
c347: dq 0x7FFF0F0C8000644C, 0xE01700FF80018001
c348: dq 0x73F5800000000001, 0xDD0BFFFFFFFF00FF
c349: dq 0xFFFF66A7FFFF85F6, 0x8001800180008001
c350: dq 0x1008001FFFF8001, 0x138E79DC4FFFF
c351: dq 0x17FFF000009AE, 0x8001D5320000006E
c352: dq 0x8001A10E00010001, 0xB05C8B334A4700FF
c353: dq 0x100B207FFFF7FFF, 0x68AA00017FFF00FF
c354: dq 0x514100FF8000, 0x8000FE4480000000
c355: dq 0x7FFFFFFF800100FF, 0x2D5500010001FFFF
c356: dq 0x7FFF01009908FED4, 0xA6377FFF00FFC00C
c357: dq 0x1B52475B2D0B00FF, 0xFF80019E378000
c358: dq 0xFFFFDA8FCF77247E, 0xFF7FFF80007FFF
c359: dq 0xFFFF00FF7FFF0000, 0x9A9C7FFF80000001
c360: dq 0x100DF1581DA0000, 0x80018001FFFF
c361: dq 0x8000530E80002037, 0x1048A80007FFF
c362: dq 0x17FFF00000100, 0xC76C8D1D572F7FFF
c363: dq 0xFFFF0001800100FF, 0x7FFF7FFF2E6E0100
c364: dq 0x100C9E00100B4A2, 0x19A22BE587661CB5
c365: dq 0xFF5080007E9F0100, 0x1882480010000
c366: dq 0x94121FB60001B657, 0x80007FFFDE9C0100
c367: dq 0x100865A038D0001, 0xFF493F9FBC0000
c368: dq 0x19ABC7FFF2761, 0xFFFF80002F1B0100
c369: dq 0x800180017FFFFFFF, 0xFF146300009E6A
c370: dq 0x80018001000000FF, 0xA6538BEB80000001
c371: dq 0x8000FFFFE4790001, 0x1008001010096A2
c372: dq 0x100BB64DCA78001, 0xBC090000C5250001
c373: dq 0xFFFFE87F7FFF6AA9, 0x1005958B1B07A36
c374: dq 0x8000B9A4800164AB, 0x7FFF800000000001
c375: dq 0x7FFF1651994B0100, 0x8000FE887FB98001
c376: dq 0xB4D70001D9B80100, 0xCD39D86D01008001
c377: dq 0x1F66A8001, 0xB4DE9B3A29768001
c378: dq 0x800101008000FFFF, 0xFFFF000000FF0001
c379: dq 0x80018000F5A8FFFF, 0x80010000FFFFB6E5
c380: dq 0xC130010035F08000, 0xB72E7FFF0C83A178
c381: dq 0x6868000100FF844B, 0x54BA0100C342DB3A
c382: dq 0xAC5BB18DF2268001, 0x800180006EB7
c383: dq 0x129E05ED80001A57, 0x1007FFF0C74
c384: dq 0x498E8000000000FF, 0xC03E8000488C
c385: dq 0x100000000007FFF, 0xE98200FF00FF0100
c386: dq 0xFFFF1FE92C07E633, 0xFF8000000049F3
c387: dq 0xE7B07FFFFFFF8001, 0x5BE71B6EF0CEEC26
c388: dq 0x100FFFFA13EFFFF, 0xFFFF95A700FF0100
c389: dq 0xFFFFE226EBF65270, 0xFFFF000000FF8000
c390: dq 0x80010EE880010D9B, 0xE2AC00FFFFFFFFFF
c391: dq 0xEC958E52FFFFE092, 0x46A6D70700FF7FFF
c392: dq 0x7FFF0000380ADD4F, 0x10000FF15320000
c393: dq 0xFFFF7FFF7FFFA439, 0x8001010000008001
c394: dq 0x1007FFF4C227FFF, 0x408D00008000
c395: dq 0xFFFF010031756FA3, 0x7FFF576FBB302CED
c396: dq 0x3B6000FF00FF0001, 0x1C0D72A70100FFFF
c397: dq 0xE8CC5CDD8001FFFF, 0xFF2BAE8EC80000
c398: dq 0x80008CEBFFFF0001, 0x871080010100FFFF
c399: dq 0x643384CC0000, 0xA2C600005C978000
c400: dq 0xFF7FFF0BFB00FF, 0x1F3300FF878DB453
c401: dq 0x6647E2D680007FFF, 0x1800000010000
c402: dq 0x3975753835BA81C3, 0x2D13800000008000
c403: dq 0xFFFF000101000100, 0xFFFF05BC0100F627
c404: dq 0x100E80145E2428B, 0x75042EF78001
c405: dq 0x80017FFF3306DBCB, 0xFF039A0001E0B3
c406: dq 0x18D5B00FF, 0xDFAD1FD6CE2300FF
c407: dq 0x40C5800001008001, 0x8001921779678001
c408: dq 0x80010100BC9A3958, 0xFFFF5F277FFF5EBA
c409: dq 0x90B800100000000, 0x750900010001
c410: dq 0x7FFF800100FF0100, 0xADE48000B1E800FF
c411: dq 0xFF2DEC01007FFF, 0xFF86709F3B0001
c412: dq 0x8001FFFFFFFF00FF, 0xFFCD14FFFF5E5D
c413: dq 0x7FFF0100FCFB0001, 0x80008BE2FFFFC5D0
c414: dq 0x8000F9180C8898D1, 0x800100008001FFFF
c415: dq 0x800001000000011D, 0x100010000010001
c416: dq 0x800100FF11B48000, 0x1FFFF00FF8DFE
c417: dq 0xFFFFFFFF743A, 0xB21E00018000B633
c418: dq 0x17010001C3FE8000, 0xFFFFFFFF8000
c419: dq 0x100988800018000, 0x8000000100FF00FF
c420: dq 0x8000FFFFDA9800FF, 0xFFFF6C37CF740001
c421: dq 0x87C1800000FF18FF, 0xFFFF0000FFCE922E
c422: dq 0x96BA80006B55FFFF, 0xE4A08A35FFFF7FFF
c423: dq 0x9C1100010000FFFF, 0xFF01003C6A53CB
c424: dq 0x7FFF800080AB00FF, 0x7FFFD8016195C721
c425: dq 0x47447FFFED957FFF, 0x8001FFFFEBF46CDD
c426: dq 0xFF929700FF4D2A, 0x1DCF2A37759D8
c427: dq 0x2822A79A79FC0100, 0x8000FC8A80010100
c428: dq 0x157045F13C46C, 0xFFDE1CB289
c429: dq 0x100007FFFFFFF, 0xFFFFFFFF7FFFFFFF
c430: dq 0xD64F4D2100000001, 0x10000FFFFFFFF
c431: dq 0x7FFFFFFF76B36396, 0xFFFFBF53D4C0
c432: dq 0x7FE5E78300000000, 0xFFFF00000000
c433: dq 0xFFFFFFFFD77C2053, 0x1000000000000
c434: dq 0x69D2C0D500010000, 0xEE00809A0000FFFF
c435: dq 0xBE42E1E5, 0x8CA009850C263137
c436: dq 0x100007D01F783, 0x3F4F55C080000000
c437: dq 0x100008D6320E9, 0xFFFF0E2C02FE
c438: dq 0xFFFFFFFFFFFF, 0xF3C2FA61D02D1014
c439: dq 0x10000DF883CA5, 0xAA4E9BB680000000
c440: dq 0xADA960DF981FD210, 0x1D08A9BD00010000
c441: dq 0x5EEB5518C71AB7C1, 0x100000000
c442: dq 0x6D98D10800000001, 0x89A91CECBC127730
c443: dq 0x895D569A80000000, 0x4FFDC5411189EF1A
c444: dq 0xC1E97585FFFFFFFF, 0xFFFFFFFF7E9F037B
c445: dq 0x5E7959C700000000, 0x1CA93752A
c446: dq 0x405180E87FFFFFFF, 0x10000FFFF
c447: dq 0x3FAD8C22, 0x8628950E80000000
c448: dq 0x1, 0x7FFFFFFF9DA35E9C
c449: dq 0xEBED3A8D00000001, 0x1000000010000
c450: dq 0x6BB1CBC9C9486C2, 0x7FFFFFFF0000FFFF
c451: dq 0xFA5AF49AEF8BE373, 0xFFFFFFFF65E45447
c452: dq 0x80000000A08FE991, 0x5B73E84D8508A97D
c453: dq 0xFF5415D62359BE62, 0x8000000000000000
c454: dq 0x7FFFFFFF1F354BC8, 0x7FFFFFFFFFFFFFFF
c455: dq 0xFFFF00010000, 0xBCA5E5777FFFFFFF
c456: dq 0x80000000FFFFFFFF, 0x7FFFFFFF0000FFFF
c457: dq 0xFFFF80000000, 0x7FFFFFFF
c458: dq 0xA2C736F56B3A8512, 0x1000000000001
c459: dq 0xFFFFE012C76B, 0x7C61A694FFFFFFFF
c460: dq 0xFFFFDCC08C61, 0xFFFFFFFF00010000
c461: dq 0xB9C2944B, 0xB359F05C69EF7BCD
c462: dq 0x180000000, 0x733B7EA4C81E4B21
c463: dq 0x6F2F974F626B35B3, 0x800000003D2917B9
c464: dq 0x800000000000FFFF, 0x63AE1A9380000000
c465: dq 0x12F6E2979, 0x64D696900000001
c466: dq 0x10000C758639F, 0xC7F7C3E87FFFFFFF
c467: dq 0x80000000FFFFFFFF, 0x20DFF52E00000001
c468: dq 0xFFFF0000FFFF, 0x180000000
c469: dq 0x8000000080000000, 0x96864A630000FFFF
c470: dq 0xED0F94AA50742643, 0x92C203560000FFFF
c471: dq 0x100000A8312FD, 0x17FFFFFFF
c472: dq 0x18BF4BCE2, 0xFFFFFFFF
c473: dq 0xBE9E3E0500000000, 0xD1B7EF318E8394B8
c474: dq 0x10000C47069DD, 0x9E0C58F7CE8E6685
c475: dq 0x10000FFFF, 0xFFFF0000FFFF
c476: dq 0xFFFFFFFF, 0x800000006BBA0758
c477: dq 0x1000000010000, 0xFFFF80000000
c478: dq 0x4FD41144, 0xFFFFFFFF
c479: dq 0x18655B5C5, 0x100010000
c480: dq 0x117977C480000000, 0x3974E6828840FB04
c481: dq 0x100000000FFFF, 0xF3C576A84E05741B
c482: dq 0xFFFFFFFF00000000, 0xA6049E5E00000000
c483: dq 0x49D859CE7FFFFFFF, 0x7FFFFFFF
c484: dq 0xD6F39B1C0000FFFF, 0x10000CDB67EC3
c485: dq 0x1000000000000, 0x8000000000010000
c486: dq 0x1000000000001, 0x2227866680000000
c487: dq 0x5BCFA98B657178FB, 0x7FFFFFFFA3959261
c488: dq 0x3A89BD780000FFFF, 0x60EE9009FFFFFFFF
c489: dq 0xD5D6E12F0000FFFF, 0xFFFFFFFFFFFF
c490: dq 0x7FFFFFFF00000001, 0x99B8606A0000FFFF
c491: dq 0xDC67841200010000, 0x1FFFFFFFF
c492: dq 0x80000000FFFFFFFF, 0x80000000
c493: dq 0xFFFFFFFF819E9B8F, 0xFFFFFFFF80000000
c494: dq 0x2E75363900000000, 0xFC2ACDE800344023
c495: dq 0xDF4A20B5428A2F7, 0x10000
c496: dq 0x10000, 0x1C9B11FEAAA6050C
c497: dq 0xC794894F, 0x5CC067C200000001
c498: dq 0x6F1D058300010000, 0x43F3CE25
c499: dq 0x4E51E1E380000000, 0x1000030FADAA3
c500: dq 0x1D90D2229, 0x318FAD8C2BEF4104
c501: dq 0xE126579900010000, 0xFFFF00010000
c502: dq 0x19F245C22, 0xFF93CB42
c503: dq 0xFFFFFFFF0CABBBD1, 0x3EA4065C80000000
c504: dq 0xFFFF00000000, 0x16EC9951D
c505: dq 0x2D93C3ED00000001, 0x5B9B02F3BBEA7B7F
c506: dq 0xE75D916F, 0xFFFFFFFF7FFFFFFF
c507: dq 0xC72168EDCE4381D3, 0x180000000
c508: dq 0x1C99F89C3, 0x2A6DC69800010000
c509: dq 0x7393928D00010000, 0x100000000FFFF
c510: dq 0x8000000042989D0D, 0xFEBA88902B4B7DE8
c511: dq 0xEA5218E97FFFFFFF, 0x512634D10000FFFF
c512: dq 0xFFFFFFFF7FFFFFFF, 0x10708F339
c513: dq 0x7FFFFFFFFFFFFFFF, 0x8293C110311A294B
c514: dq 0x18D4AB7380000000, 0xDBACA0A900010000
c515: dq 0x7FFFFFFF6ED1DE36, 0x830DBC40
c516: dq 0x306436CA7FFFFFFF, 0x593D6FE2
c517: dq 0x8000000000010000, 0x7FFFFFFFB583AB9B
c518: dq 0x7FFFFFFFF13D3F68, 0xFFFFFFFF8406ADC2
c519: dq 0xFFFF0000FFFF, 0x8000000080000000
c520: dq 0x3A34C8A700000001, 0x180000000
c521: dq 0xD1B4431D60234AE4, 0xD8F51534FFFFFFFF
c522: dq 0xFFFFFFFF00000000, 0x1BF609DC5088EDAA
c523: dq 0x7FFFFFFF44CB8658, 0x95708A8E59853ACF
c524: dq 0xFFFF8B27C24E, 0xFF330C26
c525: dq 0x5445847C, 0x88FE2E17
c526: dq 0x64B67A7A21B2BCCF, 0x7FFFFFFF79AA74F2
c527: dq 0x7C862CD200010000, 0x5261C4CEEFED6B49
c528: dq 0x80000000FFFFFFFF, 0x7B11AFFE4DAE7B29
c529: dq 0xFFFFFFFF00000001, 0x8E4A5052CA1DC390
c530: dq 0xFFFF00000000, 0x1000000000000
c531: dq 0x100000000FFFF, 0xCA4B3CBA80B50390
c532: dq 0x3A783A60F192B7F5, 0xE67DF53200010000
c533: dq 0x0, 0x41274B146765A93C
c534: dq 0x8000000000000000, 0x7FFFFFFFFFFFFFFF
c535: dq 0xFFFFFFFFFFFFFFFF, 0x1
c536: dq 0xC050F6EA29C20F37, 0xFFFFFFFFFFFFFFFF
c537: dq 0x8000000000000000, 0x0
c538: dq 0x0, 0xA6E50D33FA57B0B6
c539: dq 0x9ED0F6D2436B424E, 0x7FFFFFFFFFFFFFFF
c540: dq 0xF31BBC793AE44C4D, 0x10AC610E6F787507
c541: dq 0x0, 0x0
c542: dq 0x0, 0x1
c543: dq 0x7FFFFFFFFFFFFFFF, 0x1
c544: dq 0x8000000000000000, 0xE6B4ADB253A5AEEF
c545: dq 0x0, 0xA40180A2D38C5723
c546: dq 0x8000000000000000, 0x7FFFFFFFFFFFFFFF
c547: dq 0x7FFFFFFFFFFFFFFF, 0x0
c548: dq 0xEE26D987CAA4332, 0x5A03C84F73FD5FB1
c549: dq 0xFFFFFFFF, 0x8D78421E8281C8B9
c550: dq 0x0, 0x100000000
c551: dq 0x0, 0x1
c552: dq 0xE3284A3250D2464, 0x7FFFFFFFFFFFFFFF
c553: dq 0xFFFFFFFF, 0xFFFFFFFFFFFFFFFF
c554: dq 0x17AE0022C867FB13, 0x1
c555: dq 0xA3ED960651B18144, 0x7FFFFFFFFFFFFFFF
c556: dq 0xFFFFFFFF, 0x8000000000000000
c557: dq 0xA18FCD3A0CC9871F, 0x4853365E24A6AC8D
c558: dq 0x3D2BF072CE9C4D9C, 0x0
c559: dq 0xFFFFFFFF, 0xDA8A808D887E141B
c560: dq 0x7FFFFFFFFFFFFFFF, 0x3590CF8E358833FF
c561: dq 0x7FFFFFFFFFFFFFFF, 0x0
c562: dq 0xAD6466753ABF378F, 0xC0F41C0B17CF763
c563: dq 0x0, 0x7FFFFFFFFFFFFFFF
c564: dq 0x5FD2E85AEB45D319, 0xEA78021BF5A9206D
c565: dq 0x7FBFAD81AA3C906E, 0x0
c566: dq 0xFFFFFFFFFFFFFFFF, 0x35019BB039AC3676
c567: dq 0x5F237624652E23FA, 0x5278A75D0EDDB615
c568: dq 0xFFFFFFFFFFFFFFFF, 0x100000000
c569: dq 0x7FFFFFFFFFFFFFFF, 0x3DCCBAF5C2CA59EC
c570: dq 0x449DCAE69EB62DB0, 0x0
c571: dq 0x1, 0x9B48FCAC86AD32C
c572: dq 0xFFFFFFFFFFFFFFFF, 0x1
c573: dq 0x6B28CCA354F87D30, 0xFFFFFFFF
c574: dq 0x0, 0xF7A450F85D3B7CF
c575: dq 0xB14C20A18B6F9406, 0x7FFFFFFFFFFFFFFF
c576: dq 0x1207B4D4D7DDA3A2, 0x1
c577: dq 0xFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c578: dq 0x226444D0A5E52D46, 0x4598CB28B0E4E3B
c579: dq 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFF
c580: dq 0x6CA8111468E0DCC9, 0xBD02B43686BBBDDC
c581: dq 0xFFFFFFFF, 0xFFFFFFFF
c582: dq 0x7208A1811CF52FB8, 0x548E92ABEBC0C8C3
c583: dq 0x1, 0x7FFFFFFFFFFFFFFF
c584: dq 0x100000000, 0x100000000
c585: dq 0xFFFFFFFFFFFFFFFF, 0xDB7E2A9CB1A3194D
c586: dq 0xFFFFFFFF, 0x4403464766376494
c587: dq 0x1, 0x8000000000000000
c588: dq 0x100000000, 0x2C44057E3EDC3A70
c589: dq 0x8000000000000000, 0x8000000000000000
c590: dq 0x56AA1F178DFE7CEF, 0xFFFFFFFFFFFFFFFF
c591: dq 0x4D1E7E12E907EAD7, 0x8000000000000000
c592: dq 0x0, 0x7FFFFFFFFFFFFFFF
c593: dq 0xFFFFFFFFFFFFFFFF, 0x100000000
c594: dq 0x8000000000000000, 0x91CDF204F2FBF8D0
c595: dq 0x1, 0x1
c596: dq 0x12FD171ABF9F6E61, 0x5B09631ABD6C1E20
c597: dq 0xFFFFFFFFFFFFFFFF, 0x1
c598: dq 0x6A4024B1C62B9191, 0x1
c599: dq 0x100000000, 0x8000000000000000
c600: dq 0x100000000, 0x1
c601: dq 0x8000000000000000, 0xA2C96B45E84E49B8
c602: dq 0x0, 0xAC61D51B7C814A93
c603: dq 0x9636271DF22F18A9, 0x0
c604: dq 0x816E5EA33F7158F4, 0xD8B5602A6BF2D626
c605: dq 0x449AC2ECAF74F9A9, 0xBDA2859C41154504
c606: dq 0x412C5AC7FA0FAA6B, 0x7FFFFFFFFFFFFFFF
c607: dq 0x100000000, 0xA16FF851413653
c608: dq 0x0, 0x7FFFFFFFFFFFFFFF
c609: dq 0xB5D24E2E619E2787, 0x0
c610: dq 0x8B625C46692DE60F, 0xFFFFFFFF
c611: dq 0x7FFFFFFFFFFFFFFF, 0x5BFF9A16DCE8F98A
c612: dq 0x32211AA0841F6666, 0x100000000
c613: dq 0x1, 0x1
c614: dq 0x7EE2C63CED4069DE, 0x7FFFFFFFFFFFFFFF
c615: dq 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFF
c616: dq 0x8000000000000000, 0x60354E5240F797EF
c617: dq 0x17D4BA336158BB7E, 0x8000000000000000
c618: dq 0x977CEF93CF2CDD0C, 0x7FFFFFFFFFFFFFFF
c619: dq 0x206F80EF9E4626AF, 0xFFFFFFFFFFFFFFFF
c620: dq 0xA52B0A513D07E5F8, 0xFFFFFFFF
c621: dq 0x8D262E1AF1FA153B, 0xFFFFFFFFFFFFFFFF
c622: dq 0x48EBCD875EF89F6C, 0xE636468B3873000B
c623: dq 0x0, 0x100000000
c624: dq 0xF647479F49876562, 0x8000000000000000
c625: dq 0x1, 0xFFFFFFFF
c626: dq 0x7FFFFFFFFFFFFFFF, 0x6C844E0BAA55C936
c627: dq 0xFFFFFFFF, 0x100000000
c628: dq 0x0, 0x100000000
c629: dq 0x1, 0x822FC740E56D1953
c630: dq 0x30F7C25645E4AE36, 0x1
c631: dq 0x8000000000000000, 0x1
c632: dq 0x8D6548F20CD2FFF8, 0xFFFFFFFF
c633: dq 0xE91090E7F74EBD3C, 0xC4EA6CD3C05E33A4
c634: dq 0xFFFFFFFFFFFFFFFF, 0x8000000000000000
c635: dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c636: dq 0x7000CAE01F01EF55, 0xFFFFFFFFFFFFFFFF
c637: dq 0x547B2470FB42789F, 0xFFFF00FF47D80000
c638: dq 0xFFC755089FFFFF, 0x145180010001E9C5
c639: dq 0x0, 0xBAD28A5012924E44
c640: dq 0x8BC8000000013929, 0x100007FFF
c641: dq 0xAF17557C7FFF, 0x8001010000002E29
c642: dq 0x1, 0x64C5FFBCE4B87C13
c643: dq 0x302180000000FFFF, 0xAB9AA2E0DF79C4FB
c644: dq 0x911D7FFF3D107597, 0xE69F06E57FFF00FF
c645: dq 0x3, 0x5E62F102E8C67427
c646: dq 0xEF5000FF7BC07FFF, 0x2565800000000001
c647: dq 0x100A0288001, 0xFF8424FFFF5DB8
c648: dq 0x8, 0x7A78232EE04AAE6B
c649: dq 0x100130FFFFF3967, 0x8000308C5C1D
c650: dq 0x39A73349906D, 0xFFFF010000010001
c651: dq 0xF, 0x292C03D02378C327
c652: dq 0x800073E6FFFF00FF, 0x4729D66204D7
c653: dq 0xFF904EDA8EBBC0, 0x8001FFFF80003475
c654: dq 0x10, 0x8AEAF38DB7362BE7
c655: dq 0x47906F8E7FFF0000, 0x10100FFFFA126
c656: dq 0xFFFF72B200FF0000, 0x1556D7B2CFFFF
c657: dq 0x11, 0x3ED419AADFC17EE7
c658: dq 0xE784675A01006920, 0x1800080003388
c659: dq 0x8000000047117FFF, 0xFFFF5276E010
c660: dq 0xC8, 0x98297A4F198B8BAA
c661: dq 0x100010087ED, 0x384C4FF189A800FF
c662: dq 0x10000000000, 0x0
c663: dq 0x3, 0x0
c664: dq 0xEDE2130F00010000, 0xCB5F4D270000FFFF
c665: dq 0x3EE1E7CE0000FFFF, 0xFFFF0000FFFF
c666: dq 0x0, 0xFC1F73D49EFF68FA
c667: dq 0xFFFF0000FFFF, 0xFFFFFFFF7D493821
c668: dq 0x1000000010000, 0x1D38A2D6A
c669: dq 0x1, 0x50F359D213BF7238
c670: dq 0xFFFFFFFF00000001, 0x806931ECFFFFFFFF
c671: dq 0xB90BFB7277159FAF, 0x9B6AFF3E80000000
c672: dq 0x3, 0xCAF9D5CA81347E97
c673: dq 0x26BC6C3A80000000, 0x1D93FDB200000000
c674: dq 0xFFFF0000FFFF, 0x7FFFFFFFC308BDFE
c675: dq 0x10, 0xFC595738359BF457
c676: dq 0xFFFF9FC911CE, 0x7FFFFFFF3847A9AE
c677: dq 0x1CF68922A7842F4A, 0x1000061DA7A67
c678: dq 0x1F, 0xF0E482CCF535C1C7
c679: dq 0x100000001, 0x74FC184E19241CD5
c680: dq 0x25104EF67FFFFFFF, 0xA5A164B47FFFFFFF
c681: dq 0x20, 0x78B4396E8B13240A
c682: dq 0x7FFFFFFF00010000, 0xD7603E6B00010000
c683: dq 0x1971D9819, 0x8C01E45776970E31
c684: dq 0x21, 0x586CBD089BE6F76B
c685: dq 0x8C441BBDFFFFFFFF, 0x1000000010000
c686: dq 0x1000080000000, 0x10000262F639C
c687: dq 0xC8, 0x4303BF4574F4169D
c688: dq 0x887BB1C000000000, 0x2B2B3FF4C5ADBCC3
c689: dq 0x10000000000, 0x0
c690: dq 0x3, 0x0
c691: dq 0x98B242A5D8E61129, 0x7FFFFFFFFFFFFFFF
c692: dq 0xFFFFFFFF, 0x0
c693: dq 0x0, 0xC67D29B78A713F80
c694: dq 0xDE6A89D8F812288D, 0x1
c695: dq 0x11AACB1D55D3CAE0, 0x1
c696: dq 0x1, 0x2C3E028067C36587
c697: dq 0x66842825B46778C2, 0x100000000
c698: dq 0x8FA9E5B0D2586553, 0xD392BC7E4318DC3C
c699: dq 0x3, 0xE804874B346485FA
c700: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
c701: dq 0xFFFFFFFFFFFFFFFF, 0x8000000000000000
c702: dq 0x20, 0xD797C1F32AA3418D
c703: dq 0xAC2AC01CE928C55C, 0x58E31132F8FDD6B2
c704: dq 0xC593EA52C04A7D4B, 0x8000000000000000
c705: dq 0x3F, 0x1385695F2A47E73E
c706: dq 0x9963461FA73C8D0D, 0x0
c707: dq 0x27122878815A4C04, 0x100000000
c708: dq 0x40, 0x3EB37EF6DC209A2F
c709: dq 0xE591BD86396B7E90, 0xFFFFFFFFFFFFFFFF
c710: dq 0xAA43B2171D26114E, 0x7FFFFFFFFFFFFFFF
c711: dq 0x41, 0xC11DDB2CBA9EAFE1
c712: dq 0xA97B5304DF27648E, 0x0
c713: dq 0xFFFFFFFFFFFFFFFF, 0x1
c714: dq 0xC8, 0x55B3D6AAAAB6F4C9
c715: dq 0x0, 0x6610853C3AB2964B
c716: dq 0x10000000000, 0x0
c717: dq 0x3, 0x0
c718: dq 0x8001F82801007FFF, 0x548D998C00000001
c719: dq 0x737B0000010039FE, 0xFFFF7FFF889D0001
c720: dq 0x0, 0xF55C81FAA79C784
c721: dq 0x8001D79E00FFA9BA, 0x101007FFF0001
c722: dq 0x9F3C800180000001, 0x4FA37FFF80000001
c723: dq 0x1, 0x70BAABA797BEB0C6
c724: dq 0x100800000000100, 0x7FFFC3EEFFFF1E13
c725: dq 0xFF80014D1A7FFF, 0xFF7FFF7FFF533B
c726: dq 0x3, 0x684A6D42CBE95CCC
c727: dq 0x8000000180000100, 0x100944A0000316F
c728: dq 0x3E80800000FF0000, 0x1007FFF3FD57FFF
c729: dq 0x8, 0xC2937495D4863CA0
c730: dq 0x800080004BEC00FF, 0x18000FFFF7FFF
c731: dq 0xFF0001FFFF0000, 0x7FFF000080008000
c732: dq 0xF, 0x237E2E3F88ED50E5
c733: dq 0xBAD9800000000001, 0x100FFFF01000001
c734: dq 0xA2130D577FFF, 0x10000FF00FF0000
c735: dq 0x10, 0x855BB1BDA92C128D
c736: dq 0x15B9480010000, 0xA19A6EAC0000
c737: dq 0xFFFF0F8E8001CA82, 0x1000100508700FF
c738: dq 0x11, 0x5E57B41F56FA2BB1
c739: dq 0x7FFF80007FFFFFFF, 0x80010001B7E7FFFF
c740: dq 0x57307FFFC1C9FFFF, 0x114AA40AA49C9
c741: dq 0xC8, 0x5E5FCE9F18AAC443
c742: dq 0x7FFF9F3243957B87, 0x490C00FF80018000
c743: dq 0x10000000000, 0x0
c744: dq 0x3, 0x0
c745: dq 0x576947080000000, 0x1000035D6E12C
c746: dq 0x7FFFFFFF73814ABF, 0x10000D1520299
c747: dq 0x0, 0xA7C06698267CF333
c748: dq 0xFFFFFFFF083F03A3, 0x1BA994A400000001
c749: dq 0xC50A538DDE74F3D, 0xF54B69780000FFFF
c750: dq 0x1, 0x2D146A707D5BA0B7
c751: dq 0x2FAC287ADFCF086E, 0x64D762720000FFFF
c752: dq 0x5308FE9000000001, 0xC40DFE067FFFFFFF
c753: dq 0x3, 0x6EE789242177E9BB
c754: dq 0x10000, 0xE31D761EAA02A1C3
c755: dq 0x4D8121F700010000, 0xFFFFFFFF00000000
c756: dq 0x10, 0xC4CCBBBE0CF3C8D4
c757: dq 0x7F8B65F000000000, 0x1000000000000
c758: dq 0xFACCF8C900000001, 0x7FFFFFFF0000FFFF
c759: dq 0x1F, 0x88B86E59A029DA56
c760: dq 0x7FFFFFFF889FB685, 0x3F2BB58B7FFFFFFF
c761: dq 0x1DB2B1B44, 0x8CE307F80000FFFF
c762: dq 0x20, 0x75ED91952C9D9F9C
c763: dq 0xD1DED0897FFFFFFF, 0xCF9327F3A68C6B8B
c764: dq 0xFFFFFFFF0000FFFF, 0xFFFFFFFF00000000
c765: dq 0x21, 0x3807D26994B81B37
c766: dq 0x7FFFFFFF8BB0E705, 0x10000CA7FC02C
c767: dq 0x100007FFFFFFF, 0x16EFCD5D29C712C7
c768: dq 0xC8, 0xDDE81CDECC1542A1
c769: dq 0x16E36E1800000001, 0xFFFFFFFF193EE1AA
c770: dq 0x10000000000, 0x0
c771: dq 0x3, 0x0
c772: dq 0x7FFFFFFFFC4BA520, 0xEC9E010040B7ACD6
c773: dq 0x83D480009ED5B4C7, 0x1800100018000
c774: dq 0x0, 0xAB36D46F7779C0FF
c775: dq 0xA04880000001E476, 0x124BC00000000
c776: dq 0x8000000000FF00FF, 0xFF7FFFEC6A8001
c777: dq 0x1, 0x9E792A25D5A6D9F4
c778: dq 0x8000FFFF48BE4FE0, 0x7FFF7FFF0001FFFF
c779: dq 0x800100FFFD5F7FFF, 0xFFFFAC1D80018001
c780: dq 0x3, 0x84550B44063435CE
c781: dq 0x4681000000019782, 0x10000FF1630FFFF
c782: dq 0x7FFF26C2000099FC, 0xFFFF0E77EB6600FF
c783: dq 0x8, 0x456ECCBC0733B619
c784: dq 0x5643800100FF0100, 0x7FFF713C80010001
c785: dq 0x1007FFF8001F5D9, 0x18A5CA9EE5CAC
c786: dq 0xF, 0x4897D317023CD335
c787: dq 0x80018000E6860001, 0x100FFFF8000FFFF
c788: dq 0xBC73010000FF, 0x100FFFFA6D1D0E8
c789: dq 0x10, 0x6211D34794399EB
c790: dq 0x8001EA4B7C5F0000, 0xFFFF37CE432F8A74
c791: dq 0x5096010000FF0001, 0xFFFFC479FFFF0100
c792: dq 0x11, 0x7F7E81900B2409C3
c793: dq 0x8001B3F500FFFC0F, 0xFF8001000176E7
c794: dq 0xFD62D5C60A40001, 0x3A21A39D8000D707
c795: dq 0xC8, 0x92225F9A9799C215
c796: dq 0x8000C46480015BA5, 0x10080010000F50A
c797: dq 0x10000000000, 0x0
c798: dq 0x3, 0x0
c799: dq 0x8000000076D8B782, 0x83834FC97FFFFFFF
c800: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFF00010000
c801: dq 0x0, 0x4165CDFE13160A5C
c802: dq 0x7FFFFFFF004E9F0C, 0x8000000000000001
c803: dq 0xFC5352E300000000, 0x7FFFFFFF29547E23
c804: dq 0x1, 0x5937EEE18AACEFAC
c805: dq 0x800000000000FFFF, 0x80000000BA76B39F
c806: dq 0x7D42A8546EFE5E1C, 0xFFFF76CA7A62
c807: dq 0x3, 0x6CB1E0FDA26FDF6D
c808: dq 0xFFA16268A06AB892, 0xFFFFFFFF5E04E4C3
c809: dq 0x7FFFFFFF30747A92, 0xFFFFFFFF7FFFFFFF
c810: dq 0x10, 0xE0BA3AFEE29FE16A
c811: dq 0x100000001, 0x5CA1EB1BC5782D97
c812: dq 0x100000000FFFF, 0xF124023800000000
c813: dq 0x1F, 0x84ED491395D86C4B
c814: dq 0x80000000, 0x95AC7644D6AA546E
c815: dq 0x8000000080000000, 0xFFFFFFFFFFFF
c816: dq 0x20, 0x380F6B3DCAC7F54D
c817: dq 0x397EA46316898840, 0x100000000
c818: dq 0x30194BE200000000, 0xFFFFFFFFE8354487
c819: dq 0x21, 0xA1F07EDA106CDD
c820: dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFC5A6501C
c821: dq 0x1000000000000, 0xFFFFFFFFB05C9903
c822: dq 0xC8, 0x9807415EEB375D91
c823: dq 0xFFFFFFFFFFFF, 0x17FFFFFFF
c824: dq 0x10000000000, 0x0
c825: dq 0x3, 0x0
c826: dq 0x0, 0x1
c827: dq 0xFFFFFFFFFFFFFFFF, 0x7C2628E90DC8572D
c828: dq 0x0, 0xC6580DC29CCBB5D
c829: dq 0x100000000, 0xF472F1DB4E214FBA
c830: dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c831: dq 0x1, 0x3DCFC7A0B49201F2
c832: dq 0x0, 0xFFFFFFFF
c833: dq 0x100000000, 0x1
c834: dq 0x3, 0xE16BD1D614FAC970
c835: dq 0x910BB731B9E8DDD9, 0xC7884F1B82E54852
c836: dq 0x100000000, 0xF1F2A2961DCAADC9
c837: dq 0x20, 0x8F4DB09E95FFD37D
c838: dq 0x0, 0x7FFFFFFFFFFFFFFF
c839: dq 0x8000000000000000, 0x8000000000000000
c840: dq 0x3F, 0x29C22878A31CFBE8
c841: dq 0xC57288E451A4AB, 0x1
c842: dq 0xD0AE88007B2132FD, 0x7FFFFFFFFFFFFFFF
c843: dq 0x40, 0x8B938C38473AD83C
c844: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFF
c845: dq 0x11B888944F2604F2, 0x82AB16236370D9F3
c846: dq 0x41, 0xAA8C0585122374CF
c847: dq 0x0, 0xFFFFFFFF
c848: dq 0xFFFFFFFF, 0x100000000
c849: dq 0xC8, 0x7885968954372F82
c850: dq 0xDCC77267040A26CA, 0xFFFFFFFFFFFFFFFF
c851: dq 0x10000000000, 0x0
c852: dq 0x3, 0x0
c853: dq 0x1FBCF6879, 0x4388FFFF74750000
c854: dq 0x100000000, 0x100000000
c855: dq 0x7FFFFFFF80000000, 0x59D8D4D0
c856: dq 0x0, 0x0
c857: dq 0xFE8159EB7C674D81, 0x717F000063804040
c858: dq 0x800000006938BB9A, 0x8000000000000000
c859: dq 0x80FF814091FF8A00, 0x7F8102B2E7009E96
c860: dq 0x1008000B197D276, 0x5073010093808001
c861: dq 0xFFFFFFFF00000000, 0xFFFFC450A119
c862: dq 0x9400010000C8B906, 0x7F80819C402A81
c863: dq 0x8081801A7F6A8940, 0x6ABAFF8180E48081
c864: dq 0xDC7FFF00FF047F80, 0xFF00FF4080807FFF
c865: dq 0xF3C10E073A4C2F21, 0xD65147E789D9F100
c866: dq 0xB70ADCEBFF808140, 0x994001807FFF4040
c867: dq 0x7F0E406D81FF7FFF, 0x35001FAF8177019E
c868: dq 0xFFFF, 0x7FFFFFFF00000001
c869: dq 0xAD80011AB17F00E7, 0x3C5940A47F7F1B01
c870: dq 0x5A53C0E0B7CD5553, 0xFFFFFFFF
buf: times 64 dq 0x0123456789ABCDEF
file_end:
