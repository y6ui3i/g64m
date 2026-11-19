; The floating-point instructions of SSE and SSE2: arithmetic, comparisons, and the conversions, with numbers, zeros, infinities, denormals and NaNs.
; Written by tools/gen64_tests.py: change that, not this.
%include "elf.inc"
    movdqu xmm10, [c0]
    movdqu xmm3, [c1]
    addps xmm10, xmm3
    addps xmm3, [c2]
    movdqu xmm15, [c3]
    movdqu xmm13, [c4]
    addps xmm15, xmm13
    addps xmm13, [c5]
    movdqu xmm4, [c6]
    movdqu xmm8, [c7]
    addps xmm4, xmm8
    addps xmm8, [c8]
    movdqu xmm15, [c9]
    movdqu xmm8, [c10]
    addps xmm15, xmm8
    addps xmm8, [c11]
    movdqu xmm15, [c12]
    movdqu xmm12, [c13]
    addps xmm15, xmm12
    addps xmm12, [c14]
    movdqu xmm3, [c15]
    movdqu xmm11, [c16]
    addps xmm3, xmm11
    addps xmm11, [c17]
    movdqu xmm8, [c18]
    movdqu xmm2, [c19]
    addps xmm8, xmm2
    addps xmm2, [c20]
    movdqu xmm6, [c21]
    movdqu xmm3, [c22]
    addps xmm6, xmm3
    addps xmm3, [c23]
    movdqu xmm8, [c24]
    movdqu xmm11, [c25]
    addps xmm8, xmm11
    addps xmm11, [c26]
    movdqu xmm4, [c27]
    movdqu xmm10, [c28]
    addps xmm4, xmm10
    addps xmm10, [c29]
    movdqu xmm13, [c30]
    movdqu xmm2, [c31]
    addpd xmm13, xmm2
    addpd xmm2, [c32]
    movdqu xmm10, [c33]
    movdqu xmm3, [c34]
    addpd xmm10, xmm3
    addpd xmm3, [c35]
    movdqu xmm8, [c36]
    movdqu xmm4, [c37]
    addpd xmm8, xmm4
    addpd xmm4, [c38]
    movdqu xmm10, [c39]
    movdqu xmm12, [c40]
    addpd xmm10, xmm12
    addpd xmm12, [c41]
    movdqu xmm2, [c42]
    movdqu xmm10, [c43]
    addpd xmm2, xmm10
    addpd xmm10, [c44]
    movdqu xmm6, [c45]
    movdqu xmm15, [c46]
    addpd xmm6, xmm15
    addpd xmm15, [c47]
    movdqu xmm5, [c48]
    movdqu xmm10, [c49]
    addpd xmm5, xmm10
    addpd xmm10, [c50]
    movdqu xmm9, [c51]
    movdqu xmm8, [c52]
    addpd xmm9, xmm8
    addpd xmm8, [c53]
    movdqu xmm0, [c54]
    movdqu xmm15, [c55]
    addpd xmm0, xmm15
    addpd xmm15, [c56]
    movdqu xmm1, [c57]
    movdqu xmm4, [c58]
    addpd xmm1, xmm4
    addpd xmm4, [c59]
    movdqu xmm0, [c60]
    movdqu xmm8, [c61]
    addss xmm0, xmm8
    addss xmm8, dword [c62]
    movdqu xmm10, [c63]
    movdqu xmm8, [c64]
    addss xmm10, xmm8
    addss xmm8, dword [c65]
    movdqu xmm2, [c66]
    movdqu xmm14, [c67]
    addss xmm2, xmm14
    addss xmm14, dword [c68]
    movdqu xmm13, [c69]
    movdqu xmm15, [c70]
    addss xmm13, xmm15
    addss xmm15, dword [c71]
    movdqu xmm8, [c72]
    movdqu xmm9, [c73]
    addss xmm8, xmm9
    addss xmm9, dword [c74]
    movdqu xmm11, [c75]
    movdqu xmm4, [c76]
    addss xmm11, xmm4
    addss xmm4, dword [c77]
    movdqu xmm5, [c78]
    movdqu xmm0, [c79]
    addss xmm5, xmm0
    addss xmm0, dword [c80]
    movdqu xmm0, [c81]
    movdqu xmm1, [c82]
    addss xmm0, xmm1
    addss xmm1, dword [c83]
    movdqu xmm6, [c84]
    movdqu xmm7, [c85]
    addss xmm6, xmm7
    addss xmm7, dword [c86]
    movdqu xmm3, [c87]
    movdqu xmm7, [c88]
    addss xmm3, xmm7
    addss xmm7, dword [c89]
    movdqu xmm6, [c90]
    movdqu xmm15, [c91]
    addsd xmm6, xmm15
    addsd xmm15, qword [c92]
    movdqu xmm13, [c93]
    movdqu xmm10, [c94]
    addsd xmm13, xmm10
    addsd xmm10, qword [c95]
    movdqu xmm13, [c96]
    movdqu xmm3, [c97]
    addsd xmm13, xmm3
    addsd xmm3, qword [c98]
    movdqu xmm3, [c99]
    movdqu xmm0, [c100]
    addsd xmm3, xmm0
    addsd xmm0, qword [c101]
    movdqu xmm9, [c102]
    movdqu xmm12, [c103]
    addsd xmm9, xmm12
    addsd xmm12, qword [c104]
    movdqu xmm0, [c105]
    movdqu xmm1, [c106]
    addsd xmm0, xmm1
    addsd xmm1, qword [c107]
    movdqu xmm6, [c108]
    movdqu xmm13, [c109]
    addsd xmm6, xmm13
    addsd xmm13, qword [c110]
    movdqu xmm13, [c111]
    movdqu xmm8, [c112]
    addsd xmm13, xmm8
    addsd xmm8, qword [c113]
    movdqu xmm4, [c114]
    movdqu xmm0, [c115]
    addsd xmm4, xmm0
    addsd xmm0, qword [c116]
    movdqu xmm10, [c117]
    movdqu xmm13, [c118]
    addsd xmm10, xmm13
    addsd xmm13, qword [c119]
    movdqu xmm5, [c120]
    movdqu xmm2, [c121]
    subps xmm5, xmm2
    subps xmm2, [c122]
    movdqu xmm0, [c123]
    movdqu xmm6, [c124]
    subps xmm0, xmm6
    subps xmm6, [c125]
    movdqu xmm0, [c126]
    movdqu xmm4, [c127]
    subps xmm0, xmm4
    subps xmm4, [c128]
    movdqu xmm0, [c129]
    movdqu xmm10, [c130]
    subps xmm0, xmm10
    subps xmm10, [c131]
    movdqu xmm1, [c132]
    movdqu xmm14, [c133]
    subps xmm1, xmm14
    subps xmm14, [c134]
    movdqu xmm12, [c135]
    movdqu xmm3, [c136]
    subps xmm12, xmm3
    subps xmm3, [c137]
    movdqu xmm6, [c138]
    movdqu xmm5, [c139]
    subps xmm6, xmm5
    subps xmm5, [c140]
    movdqu xmm9, [c141]
    movdqu xmm0, [c142]
    subps xmm9, xmm0
    subps xmm0, [c143]
    movdqu xmm14, [c144]
    movdqu xmm7, [c145]
    subps xmm14, xmm7
    subps xmm7, [c146]
    movdqu xmm9, [c147]
    movdqu xmm2, [c148]
    subps xmm9, xmm2
    subps xmm2, [c149]
    movdqu xmm7, [c150]
    movdqu xmm6, [c151]
    subpd xmm7, xmm6
    subpd xmm6, [c152]
    movdqu xmm12, [c153]
    movdqu xmm13, [c154]
    subpd xmm12, xmm13
    subpd xmm13, [c155]
    movdqu xmm13, [c156]
    movdqu xmm0, [c157]
    subpd xmm13, xmm0
    subpd xmm0, [c158]
    movdqu xmm10, [c159]
    movdqu xmm8, [c160]
    subpd xmm10, xmm8
    subpd xmm8, [c161]
    movdqu xmm5, [c162]
    movdqu xmm13, [c163]
    subpd xmm5, xmm13
    subpd xmm13, [c164]
    movdqu xmm3, [c165]
    movdqu xmm15, [c166]
    subpd xmm3, xmm15
    subpd xmm15, [c167]
    movdqu xmm14, [c168]
    movdqu xmm11, [c169]
    subpd xmm14, xmm11
    subpd xmm11, [c170]
    movdqu xmm15, [c171]
    movdqu xmm4, [c172]
    subpd xmm15, xmm4
    subpd xmm4, [c173]
    movdqu xmm2, [c174]
    movdqu xmm14, [c175]
    subpd xmm2, xmm14
    subpd xmm14, [c176]
    movdqu xmm8, [c177]
    movdqu xmm13, [c178]
    subpd xmm8, xmm13
    subpd xmm13, [c179]
    movdqu xmm0, [c180]
    movdqu xmm2, [c181]
    subss xmm0, xmm2
    subss xmm2, dword [c182]
    movdqu xmm6, [c183]
    movdqu xmm11, [c184]
    subss xmm6, xmm11
    subss xmm11, dword [c185]
    movdqu xmm9, [c186]
    movdqu xmm8, [c187]
    subss xmm9, xmm8
    subss xmm8, dword [c188]
    movdqu xmm15, [c189]
    movdqu xmm8, [c190]
    subss xmm15, xmm8
    subss xmm8, dword [c191]
    movdqu xmm3, [c192]
    movdqu xmm10, [c193]
    subss xmm3, xmm10
    subss xmm10, dword [c194]
    movdqu xmm13, [c195]
    movdqu xmm14, [c196]
    subss xmm13, xmm14
    subss xmm14, dword [c197]
    movdqu xmm11, [c198]
    movdqu xmm8, [c199]
    subss xmm11, xmm8
    subss xmm8, dword [c200]
    movdqu xmm15, [c201]
    movdqu xmm13, [c202]
    subss xmm15, xmm13
    subss xmm13, dword [c203]
    movdqu xmm4, [c204]
    movdqu xmm6, [c205]
    subss xmm4, xmm6
    subss xmm6, dword [c206]
    movdqu xmm4, [c207]
    movdqu xmm8, [c208]
    subss xmm4, xmm8
    subss xmm8, dword [c209]
    movdqu xmm9, [c210]
    movdqu xmm5, [c211]
    subsd xmm9, xmm5
    subsd xmm5, qword [c212]
    movdqu xmm5, [c213]
    movdqu xmm0, [c214]
    subsd xmm5, xmm0
    subsd xmm0, qword [c215]
    movdqu xmm11, [c216]
    movdqu xmm10, [c217]
    subsd xmm11, xmm10
    subsd xmm10, qword [c218]
    movdqu xmm3, [c219]
    movdqu xmm13, [c220]
    subsd xmm3, xmm13
    subsd xmm13, qword [c221]
    movdqu xmm5, [c222]
    movdqu xmm6, [c223]
    subsd xmm5, xmm6
    subsd xmm6, qword [c224]
    movdqu xmm7, [c225]
    movdqu xmm6, [c226]
    subsd xmm7, xmm6
    subsd xmm6, qword [c227]
    movdqu xmm1, [c228]
    movdqu xmm9, [c229]
    subsd xmm1, xmm9
    subsd xmm9, qword [c230]
    movdqu xmm14, [c231]
    movdqu xmm13, [c232]
    subsd xmm14, xmm13
    subsd xmm13, qword [c233]
    movdqu xmm1, [c234]
    movdqu xmm4, [c235]
    subsd xmm1, xmm4
    subsd xmm4, qword [c236]
    movdqu xmm3, [c237]
    movdqu xmm13, [c238]
    subsd xmm3, xmm13
    subsd xmm13, qword [c239]
    movdqu xmm11, [c240]
    movdqu xmm1, [c241]
    mulps xmm11, xmm1
    mulps xmm1, [c242]
    movdqu xmm14, [c243]
    movdqu xmm8, [c244]
    mulps xmm14, xmm8
    mulps xmm8, [c245]
    movdqu xmm15, [c246]
    movdqu xmm9, [c247]
    mulps xmm15, xmm9
    mulps xmm9, [c248]
    movdqu xmm8, [c249]
    movdqu xmm1, [c250]
    mulps xmm8, xmm1
    mulps xmm1, [c251]
    movdqu xmm8, [c252]
    movdqu xmm5, [c253]
    mulps xmm8, xmm5
    mulps xmm5, [c254]
    movdqu xmm11, [c255]
    movdqu xmm2, [c256]
    mulps xmm11, xmm2
    mulps xmm2, [c257]
    movdqu xmm10, [c258]
    movdqu xmm5, [c259]
    mulps xmm10, xmm5
    mulps xmm5, [c260]
    movdqu xmm8, [c261]
    movdqu xmm6, [c262]
    mulps xmm8, xmm6
    mulps xmm6, [c263]
    movdqu xmm13, [c264]
    movdqu xmm15, [c265]
    mulps xmm13, xmm15
    mulps xmm15, [c266]
    movdqu xmm1, [c267]
    movdqu xmm5, [c268]
    mulps xmm1, xmm5
    mulps xmm5, [c269]
    movdqu xmm0, [c270]
    movdqu xmm7, [c271]
    mulpd xmm0, xmm7
    mulpd xmm7, [c272]
    movdqu xmm9, [c273]
    movdqu xmm12, [c274]
    mulpd xmm9, xmm12
    mulpd xmm12, [c275]
    movdqu xmm11, [c276]
    movdqu xmm12, [c277]
    mulpd xmm11, xmm12
    mulpd xmm12, [c278]
    movdqu xmm1, [c279]
    movdqu xmm4, [c280]
    mulpd xmm1, xmm4
    mulpd xmm4, [c281]
    movdqu xmm2, [c282]
    movdqu xmm3, [c283]
    mulpd xmm2, xmm3
    mulpd xmm3, [c284]
    movdqu xmm0, [c285]
    movdqu xmm15, [c286]
    mulpd xmm0, xmm15
    mulpd xmm15, [c287]
    movdqu xmm1, [c288]
    movdqu xmm2, [c289]
    mulpd xmm1, xmm2
    mulpd xmm2, [c290]
    movdqu xmm6, [c291]
    movdqu xmm11, [c292]
    mulpd xmm6, xmm11
    mulpd xmm11, [c293]
    movdqu xmm14, [c294]
    movdqu xmm10, [c295]
    mulpd xmm14, xmm10
    mulpd xmm10, [c296]
    movdqu xmm4, [c297]
    movdqu xmm14, [c298]
    mulpd xmm4, xmm14
    mulpd xmm14, [c299]
    movdqu xmm15, [c300]
    movdqu xmm4, [c301]
    mulss xmm15, xmm4
    mulss xmm4, dword [c302]
    movdqu xmm13, [c303]
    movdqu xmm8, [c304]
    mulss xmm13, xmm8
    mulss xmm8, dword [c305]
    movdqu xmm11, [c306]
    movdqu xmm5, [c307]
    mulss xmm11, xmm5
    mulss xmm5, dword [c308]
    movdqu xmm15, [c309]
    movdqu xmm7, [c310]
    mulss xmm15, xmm7
    mulss xmm7, dword [c311]
    movdqu xmm15, [c312]
    movdqu xmm9, [c313]
    mulss xmm15, xmm9
    mulss xmm9, dword [c314]
    movdqu xmm8, [c315]
    movdqu xmm12, [c316]
    mulss xmm8, xmm12
    mulss xmm12, dword [c317]
    movdqu xmm13, [c318]
    movdqu xmm9, [c319]
    mulss xmm13, xmm9
    mulss xmm9, dword [c320]
    movdqu xmm8, [c321]
    movdqu xmm15, [c322]
    mulss xmm8, xmm15
    mulss xmm15, dword [c323]
    movdqu xmm9, [c324]
    movdqu xmm0, [c325]
    mulss xmm9, xmm0
    mulss xmm0, dword [c326]
    movdqu xmm7, [c327]
    movdqu xmm10, [c328]
    mulss xmm7, xmm10
    mulss xmm10, dword [c329]
    movdqu xmm6, [c330]
    movdqu xmm8, [c331]
    mulsd xmm6, xmm8
    mulsd xmm8, qword [c332]
    movdqu xmm1, [c333]
    movdqu xmm4, [c334]
    mulsd xmm1, xmm4
    mulsd xmm4, qword [c335]
    movdqu xmm11, [c336]
    movdqu xmm8, [c337]
    mulsd xmm11, xmm8
    mulsd xmm8, qword [c338]
    movdqu xmm13, [c339]
    movdqu xmm2, [c340]
    mulsd xmm13, xmm2
    mulsd xmm2, qword [c341]
    movdqu xmm15, [c342]
    movdqu xmm9, [c343]
    mulsd xmm15, xmm9
    mulsd xmm9, qword [c344]
    movdqu xmm15, [c345]
    movdqu xmm1, [c346]
    mulsd xmm15, xmm1
    mulsd xmm1, qword [c347]
    movdqu xmm4, [c348]
    movdqu xmm13, [c349]
    mulsd xmm4, xmm13
    mulsd xmm13, qword [c350]
    movdqu xmm0, [c351]
    movdqu xmm15, [c352]
    mulsd xmm0, xmm15
    mulsd xmm15, qword [c353]
    movdqu xmm10, [c354]
    movdqu xmm0, [c355]
    mulsd xmm10, xmm0
    mulsd xmm0, qword [c356]
    movdqu xmm5, [c357]
    movdqu xmm15, [c358]
    mulsd xmm5, xmm15
    mulsd xmm15, qword [c359]
    movdqu xmm2, [c360]
    movdqu xmm12, [c361]
    divps xmm2, xmm12
    divps xmm12, [c362]
    movdqu xmm10, [c363]
    movdqu xmm2, [c364]
    divps xmm10, xmm2
    divps xmm2, [c365]
    movdqu xmm3, [c366]
    movdqu xmm9, [c367]
    divps xmm3, xmm9
    divps xmm9, [c368]
    movdqu xmm9, [c369]
    movdqu xmm5, [c370]
    divps xmm9, xmm5
    divps xmm5, [c371]
    movdqu xmm8, [c372]
    movdqu xmm11, [c373]
    divps xmm8, xmm11
    divps xmm11, [c374]
    movdqu xmm9, [c375]
    movdqu xmm15, [c376]
    divps xmm9, xmm15
    divps xmm15, [c377]
    movdqu xmm5, [c378]
    movdqu xmm3, [c379]
    divps xmm5, xmm3
    divps xmm3, [c380]
    movdqu xmm15, [c381]
    movdqu xmm10, [c382]
    divps xmm15, xmm10
    divps xmm10, [c383]
    movdqu xmm1, [c384]
    movdqu xmm15, [c385]
    divps xmm1, xmm15
    divps xmm15, [c386]
    movdqu xmm8, [c387]
    movdqu xmm7, [c388]
    divps xmm8, xmm7
    divps xmm7, [c389]
    movdqu xmm5, [c390]
    movdqu xmm8, [c391]
    divpd xmm5, xmm8
    divpd xmm8, [c392]
    movdqu xmm5, [c393]
    movdqu xmm12, [c394]
    divpd xmm5, xmm12
    divpd xmm12, [c395]
    movdqu xmm6, [c396]
    movdqu xmm11, [c397]
    divpd xmm6, xmm11
    divpd xmm11, [c398]
    movdqu xmm2, [c399]
    movdqu xmm15, [c400]
    divpd xmm2, xmm15
    divpd xmm15, [c401]
    movdqu xmm15, [c402]
    movdqu xmm9, [c403]
    divpd xmm15, xmm9
    divpd xmm9, [c404]
    movdqu xmm3, [c405]
    movdqu xmm5, [c406]
    divpd xmm3, xmm5
    divpd xmm5, [c407]
    movdqu xmm4, [c408]
    movdqu xmm14, [c409]
    divpd xmm4, xmm14
    divpd xmm14, [c410]
    movdqu xmm5, [c411]
    movdqu xmm6, [c412]
    divpd xmm5, xmm6
    divpd xmm6, [c413]
    movdqu xmm3, [c414]
    movdqu xmm13, [c415]
    divpd xmm3, xmm13
    divpd xmm13, [c416]
    movdqu xmm1, [c417]
    movdqu xmm10, [c418]
    divpd xmm1, xmm10
    divpd xmm10, [c419]
    movdqu xmm7, [c420]
    movdqu xmm4, [c421]
    divss xmm7, xmm4
    divss xmm4, dword [c422]
    movdqu xmm13, [c423]
    movdqu xmm8, [c424]
    divss xmm13, xmm8
    divss xmm8, dword [c425]
    movdqu xmm15, [c426]
    movdqu xmm4, [c427]
    divss xmm15, xmm4
    divss xmm4, dword [c428]
    movdqu xmm2, [c429]
    movdqu xmm7, [c430]
    divss xmm2, xmm7
    divss xmm7, dword [c431]
    movdqu xmm14, [c432]
    movdqu xmm13, [c433]
    divss xmm14, xmm13
    divss xmm13, dword [c434]
    movdqu xmm13, [c435]
    movdqu xmm7, [c436]
    divss xmm13, xmm7
    divss xmm7, dword [c437]
    movdqu xmm7, [c438]
    movdqu xmm11, [c439]
    divss xmm7, xmm11
    divss xmm11, dword [c440]
    movdqu xmm15, [c441]
    movdqu xmm14, [c442]
    divss xmm15, xmm14
    divss xmm14, dword [c443]
    movdqu xmm1, [c444]
    movdqu xmm7, [c445]
    divss xmm1, xmm7
    divss xmm7, dword [c446]
    movdqu xmm3, [c447]
    movdqu xmm13, [c448]
    divss xmm3, xmm13
    divss xmm13, dword [c449]
    movdqu xmm15, [c450]
    movdqu xmm7, [c451]
    divsd xmm15, xmm7
    divsd xmm7, qword [c452]
    movdqu xmm13, [c453]
    movdqu xmm0, [c454]
    divsd xmm13, xmm0
    divsd xmm0, qword [c455]
    movdqu xmm7, [c456]
    movdqu xmm5, [c457]
    divsd xmm7, xmm5
    divsd xmm5, qword [c458]
    movdqu xmm11, [c459]
    movdqu xmm9, [c460]
    divsd xmm11, xmm9
    divsd xmm9, qword [c461]
    movdqu xmm5, [c462]
    movdqu xmm13, [c463]
    divsd xmm5, xmm13
    divsd xmm13, qword [c464]
    movdqu xmm7, [c465]
    movdqu xmm3, [c466]
    divsd xmm7, xmm3
    divsd xmm3, qword [c467]
    movdqu xmm1, [c468]
    movdqu xmm11, [c469]
    divsd xmm1, xmm11
    divsd xmm11, qword [c470]
    movdqu xmm4, [c471]
    movdqu xmm14, [c472]
    divsd xmm4, xmm14
    divsd xmm14, qword [c473]
    movdqu xmm7, [c474]
    movdqu xmm3, [c475]
    divsd xmm7, xmm3
    divsd xmm3, qword [c476]
    movdqu xmm4, [c477]
    movdqu xmm13, [c478]
    divsd xmm4, xmm13
    divsd xmm13, qword [c479]
    movdqu xmm0, [c480]
    movdqu xmm7, [c481]
    minps xmm0, xmm7
    minps xmm7, [c482]
    movdqu xmm15, [c483]
    movdqu xmm14, [c484]
    minps xmm15, xmm14
    minps xmm14, [c485]
    movdqu xmm5, [c486]
    movdqu xmm0, [c487]
    minps xmm5, xmm0
    minps xmm0, [c488]
    movdqu xmm6, [c489]
    movdqu xmm8, [c490]
    minps xmm6, xmm8
    minps xmm8, [c491]
    movdqu xmm12, [c492]
    movdqu xmm1, [c493]
    minps xmm12, xmm1
    minps xmm1, [c494]
    movdqu xmm1, [c495]
    movdqu xmm5, [c496]
    minps xmm1, xmm5
    minps xmm5, [c497]
    movdqu xmm7, [c498]
    movdqu xmm11, [c499]
    minps xmm7, xmm11
    minps xmm11, [c500]
    movdqu xmm6, [c501]
    movdqu xmm14, [c502]
    minps xmm6, xmm14
    minps xmm14, [c503]
    movdqu xmm6, [c504]
    movdqu xmm10, [c505]
    minps xmm6, xmm10
    minps xmm10, [c506]
    movdqu xmm13, [c507]
    movdqu xmm4, [c508]
    minps xmm13, xmm4
    minps xmm4, [c509]
    movdqu xmm4, [c510]
    movdqu xmm5, [c511]
    minpd xmm4, xmm5
    minpd xmm5, [c512]
    movdqu xmm12, [c513]
    movdqu xmm15, [c514]
    minpd xmm12, xmm15
    minpd xmm15, [c515]
    movdqu xmm2, [c516]
    movdqu xmm7, [c517]
    minpd xmm2, xmm7
    minpd xmm7, [c518]
    movdqu xmm5, [c519]
    movdqu xmm3, [c520]
    minpd xmm5, xmm3
    minpd xmm3, [c521]
    movdqu xmm1, [c522]
    movdqu xmm0, [c523]
    minpd xmm1, xmm0
    minpd xmm0, [c524]
    movdqu xmm15, [c525]
    movdqu xmm3, [c526]
    minpd xmm15, xmm3
    minpd xmm3, [c527]
    movdqu xmm10, [c528]
    movdqu xmm1, [c529]
    minpd xmm10, xmm1
    minpd xmm1, [c530]
    movdqu xmm15, [c531]
    movdqu xmm4, [c532]
    minpd xmm15, xmm4
    minpd xmm4, [c533]
    movdqu xmm9, [c534]
    movdqu xmm5, [c535]
    minpd xmm9, xmm5
    minpd xmm5, [c536]
    movdqu xmm9, [c537]
    movdqu xmm15, [c538]
    minpd xmm9, xmm15
    minpd xmm15, [c539]
    movdqu xmm11, [c540]
    movdqu xmm13, [c541]
    minss xmm11, xmm13
    minss xmm13, dword [c542]
    movdqu xmm10, [c543]
    movdqu xmm12, [c544]
    minss xmm10, xmm12
    minss xmm12, dword [c545]
    movdqu xmm15, [c546]
    movdqu xmm6, [c547]
    minss xmm15, xmm6
    minss xmm6, dword [c548]
    movdqu xmm14, [c549]
    movdqu xmm4, [c550]
    minss xmm14, xmm4
    minss xmm4, dword [c551]
    movdqu xmm1, [c552]
    movdqu xmm11, [c553]
    minss xmm1, xmm11
    minss xmm11, dword [c554]
    movdqu xmm11, [c555]
    movdqu xmm10, [c556]
    minss xmm11, xmm10
    minss xmm10, dword [c557]
    movdqu xmm4, [c558]
    movdqu xmm2, [c559]
    minss xmm4, xmm2
    minss xmm2, dword [c560]
    movdqu xmm8, [c561]
    movdqu xmm7, [c562]
    minss xmm8, xmm7
    minss xmm7, dword [c563]
    movdqu xmm14, [c564]
    movdqu xmm15, [c565]
    minss xmm14, xmm15
    minss xmm15, dword [c566]
    movdqu xmm6, [c567]
    movdqu xmm8, [c568]
    minss xmm6, xmm8
    minss xmm8, dword [c569]
    movdqu xmm9, [c570]
    movdqu xmm0, [c571]
    minsd xmm9, xmm0
    minsd xmm0, qword [c572]
    movdqu xmm4, [c573]
    movdqu xmm2, [c574]
    minsd xmm4, xmm2
    minsd xmm2, qword [c575]
    movdqu xmm9, [c576]
    movdqu xmm2, [c577]
    minsd xmm9, xmm2
    minsd xmm2, qword [c578]
    movdqu xmm5, [c579]
    movdqu xmm7, [c580]
    minsd xmm5, xmm7
    minsd xmm7, qword [c581]
    movdqu xmm7, [c582]
    movdqu xmm8, [c583]
    minsd xmm7, xmm8
    minsd xmm8, qword [c584]
    movdqu xmm10, [c585]
    movdqu xmm8, [c586]
    minsd xmm10, xmm8
    minsd xmm8, qword [c587]
    movdqu xmm6, [c588]
    movdqu xmm11, [c589]
    minsd xmm6, xmm11
    minsd xmm11, qword [c590]
    movdqu xmm4, [c591]
    movdqu xmm0, [c592]
    minsd xmm4, xmm0
    minsd xmm0, qword [c593]
    movdqu xmm4, [c594]
    movdqu xmm3, [c595]
    minsd xmm4, xmm3
    minsd xmm3, qword [c596]
    movdqu xmm9, [c597]
    movdqu xmm2, [c598]
    minsd xmm9, xmm2
    minsd xmm2, qword [c599]
    movdqu xmm5, [c600]
    movdqu xmm9, [c601]
    maxps xmm5, xmm9
    maxps xmm9, [c602]
    movdqu xmm13, [c603]
    movdqu xmm14, [c604]
    maxps xmm13, xmm14
    maxps xmm14, [c605]
    movdqu xmm14, [c606]
    movdqu xmm2, [c607]
    maxps xmm14, xmm2
    maxps xmm2, [c608]
    movdqu xmm13, [c609]
    movdqu xmm2, [c610]
    maxps xmm13, xmm2
    maxps xmm2, [c611]
    movdqu xmm15, [c612]
    movdqu xmm10, [c613]
    maxps xmm15, xmm10
    maxps xmm10, [c614]
    movdqu xmm15, [c615]
    movdqu xmm7, [c616]
    maxps xmm15, xmm7
    maxps xmm7, [c617]
    movdqu xmm12, [c618]
    movdqu xmm4, [c619]
    maxps xmm12, xmm4
    maxps xmm4, [c620]
    movdqu xmm10, [c621]
    movdqu xmm2, [c622]
    maxps xmm10, xmm2
    maxps xmm2, [c623]
    movdqu xmm3, [c624]
    movdqu xmm2, [c625]
    maxps xmm3, xmm2
    maxps xmm2, [c626]
    movdqu xmm10, [c627]
    movdqu xmm1, [c628]
    maxps xmm10, xmm1
    maxps xmm1, [c629]
    movdqu xmm5, [c630]
    movdqu xmm4, [c631]
    maxpd xmm5, xmm4
    maxpd xmm4, [c632]
    movdqu xmm6, [c633]
    movdqu xmm3, [c634]
    maxpd xmm6, xmm3
    maxpd xmm3, [c635]
    movdqu xmm14, [c636]
    movdqu xmm10, [c637]
    maxpd xmm14, xmm10
    maxpd xmm10, [c638]
    movdqu xmm3, [c639]
    movdqu xmm8, [c640]
    maxpd xmm3, xmm8
    maxpd xmm8, [c641]
    movdqu xmm6, [c642]
    movdqu xmm2, [c643]
    maxpd xmm6, xmm2
    maxpd xmm2, [c644]
    movdqu xmm10, [c645]
    movdqu xmm5, [c646]
    maxpd xmm10, xmm5
    maxpd xmm5, [c647]
    movdqu xmm14, [c648]
    movdqu xmm0, [c649]
    maxpd xmm14, xmm0
    maxpd xmm0, [c650]
    movdqu xmm1, [c651]
    movdqu xmm4, [c652]
    maxpd xmm1, xmm4
    maxpd xmm4, [c653]
    movdqu xmm0, [c654]
    movdqu xmm8, [c655]
    maxpd xmm0, xmm8
    maxpd xmm8, [c656]
    movdqu xmm1, [c657]
    movdqu xmm9, [c658]
    maxpd xmm1, xmm9
    maxpd xmm9, [c659]
    movdqu xmm12, [c660]
    movdqu xmm1, [c661]
    maxss xmm12, xmm1
    maxss xmm1, dword [c662]
    movdqu xmm2, [c663]
    movdqu xmm7, [c664]
    maxss xmm2, xmm7
    maxss xmm7, dword [c665]
    movdqu xmm14, [c666]
    movdqu xmm11, [c667]
    maxss xmm14, xmm11
    maxss xmm11, dword [c668]
    movdqu xmm14, [c669]
    movdqu xmm2, [c670]
    maxss xmm14, xmm2
    maxss xmm2, dword [c671]
    movdqu xmm7, [c672]
    movdqu xmm2, [c673]
    maxss xmm7, xmm2
    maxss xmm2, dword [c674]
    movdqu xmm15, [c675]
    movdqu xmm14, [c676]
    maxss xmm15, xmm14
    maxss xmm14, dword [c677]
    movdqu xmm4, [c678]
    movdqu xmm8, [c679]
    maxss xmm4, xmm8
    maxss xmm8, dword [c680]
    movdqu xmm3, [c681]
    movdqu xmm15, [c682]
    maxss xmm3, xmm15
    maxss xmm15, dword [c683]
    movdqu xmm5, [c684]
    movdqu xmm14, [c685]
    maxss xmm5, xmm14
    maxss xmm14, dword [c686]
    movdqu xmm13, [c687]
    movdqu xmm8, [c688]
    maxss xmm13, xmm8
    maxss xmm8, dword [c689]
    movdqu xmm0, [c690]
    movdqu xmm13, [c691]
    maxsd xmm0, xmm13
    maxsd xmm13, qword [c692]
    movdqu xmm4, [c693]
    movdqu xmm11, [c694]
    maxsd xmm4, xmm11
    maxsd xmm11, qword [c695]
    movdqu xmm13, [c696]
    movdqu xmm14, [c697]
    maxsd xmm13, xmm14
    maxsd xmm14, qword [c698]
    movdqu xmm0, [c699]
    movdqu xmm15, [c700]
    maxsd xmm0, xmm15
    maxsd xmm15, qword [c701]
    movdqu xmm5, [c702]
    movdqu xmm10, [c703]
    maxsd xmm5, xmm10
    maxsd xmm10, qword [c704]
    movdqu xmm12, [c705]
    movdqu xmm9, [c706]
    maxsd xmm12, xmm9
    maxsd xmm9, qword [c707]
    movdqu xmm9, [c708]
    movdqu xmm1, [c709]
    maxsd xmm9, xmm1
    maxsd xmm1, qword [c710]
    movdqu xmm0, [c711]
    movdqu xmm11, [c712]
    maxsd xmm0, xmm11
    maxsd xmm11, qword [c713]
    movdqu xmm11, [c714]
    movdqu xmm4, [c715]
    maxsd xmm11, xmm4
    maxsd xmm4, qword [c716]
    movdqu xmm15, [c717]
    movdqu xmm7, [c718]
    maxsd xmm15, xmm7
    maxsd xmm7, qword [c719]
    movdqu xmm10, [c720]
    movdqu xmm6, [c721]
    sqrtps xmm10, xmm6
    sqrtps xmm6, [c722]
    movdqu xmm2, [c723]
    movdqu xmm10, [c724]
    sqrtps xmm2, xmm10
    sqrtps xmm10, [c725]
    movdqu xmm6, [c726]
    movdqu xmm11, [c727]
    sqrtps xmm6, xmm11
    sqrtps xmm11, [c728]
    movdqu xmm3, [c729]
    movdqu xmm14, [c730]
    sqrtps xmm3, xmm14
    sqrtps xmm14, [c731]
    movdqu xmm10, [c732]
    movdqu xmm1, [c733]
    sqrtps xmm10, xmm1
    sqrtps xmm1, [c734]
    movdqu xmm1, [c735]
    movdqu xmm3, [c736]
    sqrtps xmm1, xmm3
    sqrtps xmm3, [c737]
    movdqu xmm10, [c738]
    movdqu xmm5, [c739]
    sqrtps xmm10, xmm5
    sqrtps xmm5, [c740]
    movdqu xmm9, [c741]
    movdqu xmm0, [c742]
    sqrtps xmm9, xmm0
    sqrtps xmm0, [c743]
    movdqu xmm11, [c744]
    movdqu xmm1, [c745]
    sqrtps xmm11, xmm1
    sqrtps xmm1, [c746]
    movdqu xmm1, [c747]
    movdqu xmm5, [c748]
    sqrtps xmm1, xmm5
    sqrtps xmm5, [c749]
    movdqu xmm0, [c750]
    movdqu xmm7, [c751]
    sqrtpd xmm0, xmm7
    sqrtpd xmm7, [c752]
    movdqu xmm11, [c753]
    movdqu xmm12, [c754]
    sqrtpd xmm11, xmm12
    sqrtpd xmm12, [c755]
    movdqu xmm9, [c756]
    movdqu xmm6, [c757]
    sqrtpd xmm9, xmm6
    sqrtpd xmm6, [c758]
    movdqu xmm4, [c759]
    movdqu xmm12, [c760]
    sqrtpd xmm4, xmm12
    sqrtpd xmm12, [c761]
    movdqu xmm0, [c762]
    movdqu xmm5, [c763]
    sqrtpd xmm0, xmm5
    sqrtpd xmm5, [c764]
    movdqu xmm10, [c765]
    movdqu xmm5, [c766]
    sqrtpd xmm10, xmm5
    sqrtpd xmm5, [c767]
    movdqu xmm0, [c768]
    movdqu xmm11, [c769]
    sqrtpd xmm0, xmm11
    sqrtpd xmm11, [c770]
    movdqu xmm9, [c771]
    movdqu xmm7, [c772]
    sqrtpd xmm9, xmm7
    sqrtpd xmm7, [c773]
    movdqu xmm14, [c774]
    movdqu xmm1, [c775]
    sqrtpd xmm14, xmm1
    sqrtpd xmm1, [c776]
    movdqu xmm13, [c777]
    movdqu xmm3, [c778]
    sqrtpd xmm13, xmm3
    sqrtpd xmm3, [c779]
    movdqu xmm0, [c780]
    movdqu xmm2, [c781]
    sqrtss xmm0, xmm2
    sqrtss xmm2, dword [c782]
    movdqu xmm4, [c783]
    movdqu xmm6, [c784]
    sqrtss xmm4, xmm6
    sqrtss xmm6, dword [c785]
    movdqu xmm2, [c786]
    movdqu xmm9, [c787]
    sqrtss xmm2, xmm9
    sqrtss xmm9, dword [c788]
    movdqu xmm4, [c789]
    movdqu xmm10, [c790]
    sqrtss xmm4, xmm10
    sqrtss xmm10, dword [c791]
    movdqu xmm12, [c792]
    movdqu xmm2, [c793]
    sqrtss xmm12, xmm2
    sqrtss xmm2, dword [c794]
    movdqu xmm5, [c795]
    movdqu xmm6, [c796]
    sqrtss xmm5, xmm6
    sqrtss xmm6, dword [c797]
    movdqu xmm3, [c798]
    movdqu xmm13, [c799]
    sqrtss xmm3, xmm13
    sqrtss xmm13, dword [c800]
    movdqu xmm10, [c801]
    movdqu xmm9, [c802]
    sqrtss xmm10, xmm9
    sqrtss xmm9, dword [c803]
    movdqu xmm6, [c804]
    movdqu xmm1, [c805]
    sqrtss xmm6, xmm1
    sqrtss xmm1, dword [c806]
    movdqu xmm4, [c807]
    movdqu xmm9, [c808]
    sqrtss xmm4, xmm9
    sqrtss xmm9, dword [c809]
    movdqu xmm10, [c810]
    movdqu xmm11, [c811]
    sqrtsd xmm10, xmm11
    sqrtsd xmm11, qword [c812]
    movdqu xmm14, [c813]
    movdqu xmm3, [c814]
    sqrtsd xmm14, xmm3
    sqrtsd xmm3, qword [c815]
    movdqu xmm13, [c816]
    movdqu xmm7, [c817]
    sqrtsd xmm13, xmm7
    sqrtsd xmm7, qword [c818]
    movdqu xmm8, [c819]
    movdqu xmm14, [c820]
    sqrtsd xmm8, xmm14
    sqrtsd xmm14, qword [c821]
    movdqu xmm8, [c822]
    movdqu xmm11, [c823]
    sqrtsd xmm8, xmm11
    sqrtsd xmm11, qword [c824]
    movdqu xmm5, [c825]
    movdqu xmm15, [c826]
    sqrtsd xmm5, xmm15
    sqrtsd xmm15, qword [c827]
    movdqu xmm4, [c828]
    movdqu xmm15, [c829]
    sqrtsd xmm4, xmm15
    sqrtsd xmm15, qword [c830]
    movdqu xmm2, [c831]
    movdqu xmm13, [c832]
    sqrtsd xmm2, xmm13
    sqrtsd xmm13, qword [c833]
    movdqu xmm7, [c834]
    movdqu xmm1, [c835]
    sqrtsd xmm7, xmm1
    sqrtsd xmm1, qword [c836]
    movdqu xmm13, [c837]
    movdqu xmm5, [c838]
    sqrtsd xmm13, xmm5
    sqrtsd xmm5, qword [c839]
    movdqu xmm10, [c840]
    movdqu xmm6, [c841]
    andps xmm10, xmm6
    andps xmm6, [c842]
    movdqu xmm15, [c843]
    movdqu xmm5, [c844]
    andpd xmm15, xmm5
    andpd xmm5, [c845]
    movdqu xmm6, [c846]
    movdqu xmm2, [c847]
    andnps xmm6, xmm2
    andnps xmm2, [c848]
    movdqu xmm13, [c849]
    movdqu xmm8, [c850]
    andnpd xmm13, xmm8
    andnpd xmm8, [c851]
    movdqu xmm2, [c852]
    movdqu xmm12, [c853]
    orps xmm2, xmm12
    orps xmm12, [c854]
    movdqu xmm11, [c855]
    movdqu xmm7, [c856]
    orpd xmm11, xmm7
    orpd xmm7, [c857]
    movdqu xmm3, [c858]
    movdqu xmm6, [c859]
    xorps xmm3, xmm6
    xorps xmm6, [c860]
    movdqu xmm13, [c861]
    movdqu xmm12, [c862]
    xorpd xmm13, xmm12
    xorpd xmm12, [c863]
    movdqu xmm6, [c864]
    movdqu xmm15, [c865]
    cmpps xmm6, xmm15, 0
    movdqu xmm1, [c866]
    movdqu xmm14, [c867]
    cmpps xmm1, xmm14, 0
    movdqu xmm0, [c868]
    movdqu xmm6, [c869]
    cmpps xmm0, xmm6, 0
    movdqu xmm5, [c870]
    movdqu xmm3, [c871]
    cmpps xmm5, xmm3, 1
    movdqu xmm13, [c872]
    movdqu xmm5, [c873]
    cmpps xmm13, xmm5, 1
    movdqu xmm0, [c874]
    movdqu xmm4, [c875]
    cmpps xmm0, xmm4, 1
    movdqu xmm3, [c876]
    movdqu xmm15, [c877]
    cmpps xmm3, xmm15, 2
    movdqu xmm5, [c878]
    movdqu xmm9, [c879]
    cmpps xmm5, xmm9, 2
    movdqu xmm12, [c880]
    movdqu xmm7, [c881]
    cmpps xmm12, xmm7, 2
    movdqu xmm9, [c882]
    movdqu xmm12, [c883]
    cmpps xmm9, xmm12, 3
    movdqu xmm11, [c884]
    movdqu xmm14, [c885]
    cmpps xmm11, xmm14, 3
    movdqu xmm1, [c886]
    movdqu xmm12, [c887]
    cmpps xmm1, xmm12, 3
    movdqu xmm13, [c888]
    movdqu xmm8, [c889]
    cmpps xmm13, xmm8, 4
    movdqu xmm3, [c890]
    movdqu xmm4, [c891]
    cmpps xmm3, xmm4, 4
    movdqu xmm1, [c892]
    movdqu xmm6, [c893]
    cmpps xmm1, xmm6, 4
    movdqu xmm1, [c894]
    movdqu xmm15, [c895]
    cmpps xmm1, xmm15, 5
    movdqu xmm10, [c896]
    movdqu xmm0, [c897]
    cmpps xmm10, xmm0, 5
    movdqu xmm14, [c898]
    movdqu xmm2, [c899]
    cmpps xmm14, xmm2, 5
    movdqu xmm2, [c900]
    movdqu xmm5, [c901]
    cmpps xmm2, xmm5, 6
    movdqu xmm6, [c902]
    movdqu xmm7, [c903]
    cmpps xmm6, xmm7, 6
    movdqu xmm1, [c904]
    movdqu xmm13, [c905]
    cmpps xmm1, xmm13, 6
    movdqu xmm11, [c906]
    movdqu xmm10, [c907]
    cmpps xmm11, xmm10, 7
    movdqu xmm0, [c908]
    movdqu xmm2, [c909]
    cmpps xmm0, xmm2, 7
    movdqu xmm3, [c910]
    movdqu xmm0, [c911]
    cmpps xmm3, xmm0, 7
    movdqu xmm7, [c912]
    movdqu xmm0, [c913]
    cmppd xmm7, xmm0, 0
    movdqu xmm2, [c914]
    movdqu xmm14, [c915]
    cmppd xmm2, xmm14, 0
    movdqu xmm11, [c916]
    movdqu xmm2, [c917]
    cmppd xmm11, xmm2, 0
    movdqu xmm1, [c918]
    movdqu xmm11, [c919]
    cmppd xmm1, xmm11, 1
    movdqu xmm13, [c920]
    movdqu xmm6, [c921]
    cmppd xmm13, xmm6, 1
    movdqu xmm12, [c922]
    movdqu xmm3, [c923]
    cmppd xmm12, xmm3, 1
    movdqu xmm2, [c924]
    movdqu xmm14, [c925]
    cmppd xmm2, xmm14, 2
    movdqu xmm1, [c926]
    movdqu xmm13, [c927]
    cmppd xmm1, xmm13, 2
    movdqu xmm11, [c928]
    movdqu xmm10, [c929]
    cmppd xmm11, xmm10, 2
    movdqu xmm1, [c930]
    movdqu xmm2, [c931]
    cmppd xmm1, xmm2, 3
    movdqu xmm5, [c932]
    movdqu xmm9, [c933]
    cmppd xmm5, xmm9, 3
    movdqu xmm13, [c934]
    movdqu xmm8, [c935]
    cmppd xmm13, xmm8, 3
    movdqu xmm0, [c936]
    movdqu xmm3, [c937]
    cmppd xmm0, xmm3, 4
    movdqu xmm9, [c938]
    movdqu xmm7, [c939]
    cmppd xmm9, xmm7, 4
    movdqu xmm5, [c940]
    movdqu xmm1, [c941]
    cmppd xmm5, xmm1, 4
    movdqu xmm3, [c942]
    movdqu xmm6, [c943]
    cmppd xmm3, xmm6, 5
    movdqu xmm6, [c944]
    movdqu xmm4, [c945]
    cmppd xmm6, xmm4, 5
    movdqu xmm5, [c946]
    movdqu xmm0, [c947]
    cmppd xmm5, xmm0, 5
    movdqu xmm6, [c948]
    movdqu xmm2, [c949]
    cmppd xmm6, xmm2, 6
    movdqu xmm6, [c950]
    movdqu xmm13, [c951]
    cmppd xmm6, xmm13, 6
    movdqu xmm4, [c952]
    movdqu xmm1, [c953]
    cmppd xmm4, xmm1, 6
    movdqu xmm10, [c954]
    movdqu xmm4, [c955]
    cmppd xmm10, xmm4, 7
    movdqu xmm15, [c956]
    movdqu xmm1, [c957]
    cmppd xmm15, xmm1, 7
    movdqu xmm15, [c958]
    movdqu xmm11, [c959]
    cmppd xmm15, xmm11, 7
    movdqu xmm1, [c960]
    movdqu xmm4, [c961]
    cmpss xmm1, xmm4, 0
    movdqu xmm15, [c962]
    movdqu xmm1, [c963]
    cmpss xmm15, xmm1, 0
    movdqu xmm4, [c964]
    movdqu xmm13, [c965]
    cmpss xmm4, xmm13, 0
    movdqu xmm0, [c966]
    movdqu xmm15, [c967]
    cmpss xmm0, xmm15, 1
    movdqu xmm6, [c968]
    movdqu xmm8, [c969]
    cmpss xmm6, xmm8, 1
    movdqu xmm8, [c970]
    movdqu xmm7, [c971]
    cmpss xmm8, xmm7, 1
    movdqu xmm0, [c972]
    movdqu xmm7, [c973]
    cmpss xmm0, xmm7, 2
    movdqu xmm0, [c974]
    movdqu xmm14, [c975]
    cmpss xmm0, xmm14, 2
    movdqu xmm0, [c976]
    movdqu xmm10, [c977]
    cmpss xmm0, xmm10, 2
    movdqu xmm9, [c978]
    movdqu xmm13, [c979]
    cmpss xmm9, xmm13, 3
    movdqu xmm6, [c980]
    movdqu xmm2, [c981]
    cmpss xmm6, xmm2, 3
    movdqu xmm8, [c982]
    movdqu xmm6, [c983]
    cmpss xmm8, xmm6, 3
    movdqu xmm6, [c984]
    movdqu xmm11, [c985]
    cmpss xmm6, xmm11, 4
    movdqu xmm2, [c986]
    movdqu xmm14, [c987]
    cmpss xmm2, xmm14, 4
    movdqu xmm9, [c988]
    movdqu xmm12, [c989]
    cmpss xmm9, xmm12, 4
    movdqu xmm12, [c990]
    movdqu xmm5, [c991]
    cmpss xmm12, xmm5, 5
    movdqu xmm2, [c992]
    movdqu xmm8, [c993]
    cmpss xmm2, xmm8, 5
    movdqu xmm9, [c994]
    movdqu xmm7, [c995]
    cmpss xmm9, xmm7, 5
    movdqu xmm8, [c996]
    movdqu xmm12, [c997]
    cmpss xmm8, xmm12, 6
    movdqu xmm4, [c998]
    movdqu xmm12, [c999]
    cmpss xmm4, xmm12, 6
    movdqu xmm2, [c1000]
    movdqu xmm6, [c1001]
    cmpss xmm2, xmm6, 6
    movdqu xmm3, [c1002]
    movdqu xmm8, [c1003]
    cmpss xmm3, xmm8, 7
    movdqu xmm6, [c1004]
    movdqu xmm12, [c1005]
    cmpss xmm6, xmm12, 7
    movdqu xmm6, [c1006]
    movdqu xmm13, [c1007]
    cmpss xmm6, xmm13, 7
    movdqu xmm8, [c1008]
    movdqu xmm15, [c1009]
    cmpsd xmm8, xmm15, 0
    movdqu xmm6, [c1010]
    movdqu xmm15, [c1011]
    cmpsd xmm6, xmm15, 0
    movdqu xmm8, [c1012]
    movdqu xmm5, [c1013]
    cmpsd xmm8, xmm5, 0
    movdqu xmm4, [c1014]
    movdqu xmm7, [c1015]
    cmpsd xmm4, xmm7, 1
    movdqu xmm5, [c1016]
    movdqu xmm10, [c1017]
    cmpsd xmm5, xmm10, 1
    movdqu xmm1, [c1018]
    movdqu xmm13, [c1019]
    cmpsd xmm1, xmm13, 1
    movdqu xmm8, [c1020]
    movdqu xmm5, [c1021]
    cmpsd xmm8, xmm5, 2
    movdqu xmm11, [c1022]
    movdqu xmm6, [c1023]
    cmpsd xmm11, xmm6, 2
    movdqu xmm9, [c1024]
    movdqu xmm6, [c1025]
    cmpsd xmm9, xmm6, 2
    movdqu xmm0, [c1026]
    movdqu xmm2, [c1027]
    cmpsd xmm0, xmm2, 3
    movdqu xmm10, [c1028]
    movdqu xmm11, [c1029]
    cmpsd xmm10, xmm11, 3
    movdqu xmm6, [c1030]
    movdqu xmm9, [c1031]
    cmpsd xmm6, xmm9, 3
    movdqu xmm9, [c1032]
    movdqu xmm14, [c1033]
    cmpsd xmm9, xmm14, 4
    movdqu xmm13, [c1034]
    movdqu xmm0, [c1035]
    cmpsd xmm13, xmm0, 4
    movdqu xmm11, [c1036]
    movdqu xmm10, [c1037]
    cmpsd xmm11, xmm10, 4
    movdqu xmm6, [c1038]
    movdqu xmm4, [c1039]
    cmpsd xmm6, xmm4, 5
    movdqu xmm4, [c1040]
    movdqu xmm5, [c1041]
    cmpsd xmm4, xmm5, 5
    movdqu xmm15, [c1042]
    movdqu xmm10, [c1043]
    cmpsd xmm15, xmm10, 5
    movdqu xmm0, [c1044]
    movdqu xmm15, [c1045]
    cmpsd xmm0, xmm15, 6
    movdqu xmm13, [c1046]
    movdqu xmm6, [c1047]
    cmpsd xmm13, xmm6, 6
    movdqu xmm7, [c1048]
    movdqu xmm14, [c1049]
    cmpsd xmm7, xmm14, 6
    movdqu xmm1, [c1050]
    movdqu xmm14, [c1051]
    cmpsd xmm1, xmm14, 7
    movdqu xmm13, [c1052]
    movdqu xmm6, [c1053]
    cmpsd xmm13, xmm6, 7
    movdqu xmm2, [c1054]
    movdqu xmm11, [c1055]
    cmpsd xmm2, xmm11, 7
    movdqu xmm5, [c1056]
    movdqu xmm9, [c1057]
    FLAGS 0xA82
    comiss xmm5, xmm9
    FLAGS 0x212
    comiss xmm9, [c1058]
    movdqu xmm0, [c1059]
    movdqu xmm7, [c1060]
    FLAGS 0xAD7
    comiss xmm0, xmm7
    FLAGS 0x203
    comiss xmm7, [c1061]
    movdqu xmm2, [c1062]
    movdqu xmm15, [c1063]
    FLAGS 0x2D6
    comiss xmm2, xmm15
    FLAGS 0x202
    comiss xmm15, [c1064]
    movdqu xmm5, [c1065]
    movdqu xmm3, [c1066]
    FLAGS 0x297
    comiss xmm5, xmm3
    FLAGS 0x213
    comiss xmm3, [c1067]
    movdqu xmm8, [c1068]
    movdqu xmm13, [c1069]
    FLAGS 0xAD7
    comiss xmm8, xmm13
    FLAGS 0xA82
    comiss xmm13, [c1070]
    movdqu xmm6, [c1071]
    movdqu xmm7, [c1072]
    FLAGS 0xA43
    comiss xmm6, xmm7
    FLAGS 0xA02
    comiss xmm7, [c1073]
    movdqu xmm8, [c1074]
    movdqu xmm9, [c1075]
    FLAGS 0xAD7
    comiss xmm8, xmm9
    FLAGS 0x202
    comiss xmm9, [c1076]
    movdqu xmm11, [c1077]
    movdqu xmm3, [c1078]
    FLAGS 0x203
    comiss xmm11, xmm3
    FLAGS 0x202
    comiss xmm3, [c1079]
    movdqu xmm6, [c1080]
    movdqu xmm7, [c1081]
    FLAGS 0x202
    comiss xmm6, xmm7
    FLAGS 0x213
    comiss xmm7, [c1082]
    movdqu xmm4, [c1083]
    movdqu xmm10, [c1084]
    FLAGS 0x213
    comiss xmm4, xmm10
    FLAGS 0x213
    comiss xmm10, [c1085]
    movdqu xmm8, [c1086]
    movdqu xmm0, [c1087]
    FLAGS 0x202
    comiss xmm8, xmm0
    FLAGS 0x213
    comiss xmm0, [c1088]
    movdqu xmm5, [c1089]
    movdqu xmm8, [c1090]
    FLAGS 0x212
    comiss xmm5, xmm8
    FLAGS 0x212
    comiss xmm8, [c1091]
    movdqu xmm9, [c1092]
    movdqu xmm14, [c1093]
    FLAGS 0xA82
    comiss xmm9, xmm14
    FLAGS 0x246
    comiss xmm14, [c1094]
    movdqu xmm5, [c1095]
    movdqu xmm1, [c1096]
    FLAGS 0xA03
    comiss xmm5, xmm1
    FLAGS 0xA03
    comiss xmm1, [c1097]
    movdqu xmm3, [c1098]
    movdqu xmm13, [c1099]
    FLAGS 0x212
    comiss xmm3, xmm13
    FLAGS 0xA03
    comiss xmm13, [c1100]
    movdqu xmm3, [c1101]
    movdqu xmm13, [c1102]
    FLAGS 0x203
    comiss xmm3, xmm13
    FLAGS 0x297
    comiss xmm13, [c1103]
    movdqu xmm5, [c1104]
    movdqu xmm0, [c1105]
    FLAGS 0x2D6
    ucomiss xmm5, xmm0
    FLAGS 0xA82
    ucomiss xmm0, [c1106]
    movdqu xmm1, [c1107]
    movdqu xmm11, [c1108]
    FLAGS 0x246
    ucomiss xmm1, xmm11
    FLAGS 0x297
    ucomiss xmm11, [c1109]
    movdqu xmm11, [c1110]
    movdqu xmm14, [c1111]
    FLAGS 0x246
    ucomiss xmm11, xmm14
    FLAGS 0x213
    ucomiss xmm14, [c1112]
    movdqu xmm3, [c1113]
    movdqu xmm6, [c1114]
    FLAGS 0x213
    ucomiss xmm3, xmm6
    FLAGS 0x213
    ucomiss xmm6, [c1115]
    movdqu xmm9, [c1116]
    movdqu xmm10, [c1117]
    FLAGS 0xA82
    ucomiss xmm9, xmm10
    FLAGS 0x203
    ucomiss xmm10, [c1118]
    movdqu xmm7, [c1119]
    movdqu xmm11, [c1120]
    FLAGS 0x212
    ucomiss xmm7, xmm11
    FLAGS 0xAD7
    ucomiss xmm11, [c1121]
    movdqu xmm2, [c1122]
    movdqu xmm3, [c1123]
    FLAGS 0x297
    ucomiss xmm2, xmm3
    FLAGS 0xA03
    ucomiss xmm3, [c1124]
    movdqu xmm2, [c1125]
    movdqu xmm3, [c1126]
    FLAGS 0xAD7
    ucomiss xmm2, xmm3
    FLAGS 0x203
    ucomiss xmm3, [c1127]
    movdqu xmm6, [c1128]
    movdqu xmm3, [c1129]
    FLAGS 0x202
    ucomiss xmm6, xmm3
    FLAGS 0x212
    ucomiss xmm3, [c1130]
    movdqu xmm1, [c1131]
    movdqu xmm15, [c1132]
    FLAGS 0xA82
    ucomiss xmm1, xmm15
    FLAGS 0xA03
    ucomiss xmm15, [c1133]
    movdqu xmm2, [c1134]
    movdqu xmm8, [c1135]
    FLAGS 0xA03
    ucomiss xmm2, xmm8
    FLAGS 0xA03
    ucomiss xmm8, [c1136]
    movdqu xmm2, [c1137]
    movdqu xmm10, [c1138]
    FLAGS 0x203
    ucomiss xmm2, xmm10
    FLAGS 0xA82
    ucomiss xmm10, [c1139]
    movdqu xmm3, [c1140]
    movdqu xmm14, [c1141]
    FLAGS 0x213
    ucomiss xmm3, xmm14
    FLAGS 0x212
    ucomiss xmm14, [c1142]
    movdqu xmm9, [c1143]
    movdqu xmm10, [c1144]
    FLAGS 0x297
    ucomiss xmm9, xmm10
    FLAGS 0x202
    ucomiss xmm10, [c1145]
    movdqu xmm14, [c1146]
    movdqu xmm5, [c1147]
    FLAGS 0x2D6
    ucomiss xmm14, xmm5
    FLAGS 0x213
    ucomiss xmm5, [c1148]
    movdqu xmm13, [c1149]
    movdqu xmm10, [c1150]
    FLAGS 0x213
    ucomiss xmm13, xmm10
    FLAGS 0x202
    ucomiss xmm10, [c1151]
    movdqu xmm11, [c1152]
    movdqu xmm9, [c1153]
    FLAGS 0x202
    comisd xmm11, xmm9
    FLAGS 0x202
    comisd xmm9, [c1154]
    movdqu xmm6, [c1155]
    movdqu xmm11, [c1156]
    FLAGS 0x203
    comisd xmm6, xmm11
    FLAGS 0x203
    comisd xmm11, [c1157]
    movdqu xmm6, [c1158]
    movdqu xmm9, [c1159]
    FLAGS 0xAD7
    comisd xmm6, xmm9
    FLAGS 0xA43
    comisd xmm9, [c1160]
    movdqu xmm0, [c1161]
    movdqu xmm14, [c1162]
    FLAGS 0x2D6
    comisd xmm0, xmm14
    FLAGS 0x202
    comisd xmm14, [c1163]
    movdqu xmm14, [c1164]
    movdqu xmm7, [c1165]
    FLAGS 0xAD7
    comisd xmm14, xmm7
    FLAGS 0xAD7
    comisd xmm7, [c1166]
    movdqu xmm11, [c1167]
    movdqu xmm0, [c1168]
    FLAGS 0xA02
    comisd xmm11, xmm0
    FLAGS 0x246
    comisd xmm0, [c1169]
    movdqu xmm4, [c1170]
    movdqu xmm12, [c1171]
    FLAGS 0xA82
    comisd xmm4, xmm12
    FLAGS 0x246
    comisd xmm12, [c1172]
    movdqu xmm15, [c1173]
    movdqu xmm2, [c1174]
    FLAGS 0x202
    comisd xmm15, xmm2
    FLAGS 0xAD7
    comisd xmm2, [c1175]
    movdqu xmm0, [c1176]
    movdqu xmm3, [c1177]
    FLAGS 0x213
    comisd xmm0, xmm3
    FLAGS 0xA43
    comisd xmm3, [c1178]
    movdqu xmm13, [c1179]
    movdqu xmm9, [c1180]
    FLAGS 0xA02
    comisd xmm13, xmm9
    FLAGS 0x202
    comisd xmm9, [c1181]
    movdqu xmm13, [c1182]
    movdqu xmm15, [c1183]
    FLAGS 0x297
    comisd xmm13, xmm15
    FLAGS 0xA02
    comisd xmm15, [c1184]
    movdqu xmm8, [c1185]
    movdqu xmm1, [c1186]
    FLAGS 0x2D6
    comisd xmm8, xmm1
    FLAGS 0xA43
    comisd xmm1, [c1187]
    movdqu xmm15, [c1188]
    movdqu xmm7, [c1189]
    FLAGS 0x213
    comisd xmm15, xmm7
    FLAGS 0x297
    comisd xmm7, [c1190]
    movdqu xmm11, [c1191]
    movdqu xmm5, [c1192]
    FLAGS 0x202
    comisd xmm11, xmm5
    FLAGS 0x213
    comisd xmm5, [c1193]
    movdqu xmm11, [c1194]
    movdqu xmm0, [c1195]
    FLAGS 0xA02
    comisd xmm11, xmm0
    FLAGS 0x212
    comisd xmm0, [c1196]
    movdqu xmm13, [c1197]
    movdqu xmm12, [c1198]
    FLAGS 0x213
    comisd xmm13, xmm12
    FLAGS 0xA02
    comisd xmm12, [c1199]
    movdqu xmm4, [c1200]
    movdqu xmm9, [c1201]
    FLAGS 0xA82
    ucomisd xmm4, xmm9
    FLAGS 0x246
    ucomisd xmm9, [c1202]
    movdqu xmm7, [c1203]
    movdqu xmm8, [c1204]
    FLAGS 0xAD7
    ucomisd xmm7, xmm8
    FLAGS 0xA03
    ucomisd xmm8, [c1205]
    movdqu xmm7, [c1206]
    movdqu xmm11, [c1207]
    FLAGS 0xA43
    ucomisd xmm7, xmm11
    FLAGS 0x246
    ucomisd xmm11, [c1208]
    movdqu xmm3, [c1209]
    movdqu xmm4, [c1210]
    FLAGS 0xA03
    ucomisd xmm3, xmm4
    FLAGS 0x2D6
    ucomisd xmm4, [c1211]
    movdqu xmm12, [c1212]
    movdqu xmm7, [c1213]
    FLAGS 0x2D6
    ucomisd xmm12, xmm7
    FLAGS 0xA43
    ucomisd xmm7, [c1214]
    movdqu xmm4, [c1215]
    movdqu xmm14, [c1216]
    FLAGS 0x246
    ucomisd xmm4, xmm14
    FLAGS 0x297
    ucomisd xmm14, [c1217]
    movdqu xmm11, [c1218]
    movdqu xmm7, [c1219]
    FLAGS 0x212
    ucomisd xmm11, xmm7
    FLAGS 0xA03
    ucomisd xmm7, [c1220]
    movdqu xmm2, [c1221]
    movdqu xmm0, [c1222]
    FLAGS 0xAD7
    ucomisd xmm2, xmm0
    FLAGS 0x246
    ucomisd xmm0, [c1223]
    movdqu xmm0, [c1224]
    movdqu xmm11, [c1225]
    FLAGS 0xA43
    ucomisd xmm0, xmm11
    FLAGS 0xAD7
    ucomisd xmm11, [c1226]
    movdqu xmm2, [c1227]
    movdqu xmm1, [c1228]
    FLAGS 0xA82
    ucomisd xmm2, xmm1
    FLAGS 0xAD7
    ucomisd xmm1, [c1229]
    movdqu xmm0, [c1230]
    movdqu xmm3, [c1231]
    FLAGS 0xA02
    ucomisd xmm0, xmm3
    FLAGS 0xA03
    ucomisd xmm3, [c1232]
    movdqu xmm13, [c1233]
    movdqu xmm14, [c1234]
    FLAGS 0xAD7
    ucomisd xmm13, xmm14
    FLAGS 0xA43
    ucomisd xmm14, [c1235]
    movdqu xmm6, [c1236]
    movdqu xmm8, [c1237]
    FLAGS 0xAD7
    ucomisd xmm6, xmm8
    FLAGS 0x213
    ucomisd xmm8, [c1238]
    movdqu xmm15, [c1239]
    movdqu xmm4, [c1240]
    FLAGS 0x203
    ucomisd xmm15, xmm4
    FLAGS 0xA03
    ucomisd xmm4, [c1241]
    movdqu xmm14, [c1242]
    movdqu xmm15, [c1243]
    FLAGS 0x246
    ucomisd xmm14, xmm15
    FLAGS 0xA43
    ucomisd xmm15, [c1244]
    movdqu xmm4, [c1245]
    movdqu xmm8, [c1246]
    FLAGS 0x246
    ucomisd xmm4, xmm8
    FLAGS 0xAD7
    ucomisd xmm8, [c1247]
    mov dword [buf], 0x1F80
    ldmxcsr [buf]
    stmxcsr [buf + 4]
    mov eax, [buf + 4]
    movdqu xmm0, [c1248]
    movdqu xmm4, [c1249]
    cvtss2si r15d, xmm0
    cvtss2si r15, xmm0
    cvttss2si r15d, xmm0
    cvttss2si r15, xmm0
    cvtsd2si r15d, xmm4
    cvtsd2si r15, xmm4
    cvttsd2si r15d, xmm4
    cvttsd2si r15, xmm4
    cvtsd2si r15, qword [c1250]
    cvtss2si r15d, dword [c1251]
    movdqu xmm15, [c1252]
    movdqu xmm0, [c1253]
    cvtss2si r9d, xmm15
    cvtss2si r9, xmm15
    cvttss2si r9d, xmm15
    cvttss2si r9, xmm15
    cvtsd2si r9d, xmm0
    cvtsd2si r9, xmm0
    cvttsd2si r9d, xmm0
    cvttsd2si r9, xmm0
    cvtsd2si r9, qword [c1254]
    cvtss2si r9d, dword [c1255]
    movdqu xmm8, [c1256]
    movdqu xmm0, [c1257]
    cvtss2si edx, xmm8
    cvtss2si rdx, xmm8
    cvttss2si edx, xmm8
    cvttss2si rdx, xmm8
    cvtsd2si edx, xmm0
    cvtsd2si rdx, xmm0
    cvttsd2si edx, xmm0
    cvttsd2si rdx, xmm0
    cvtsd2si rdx, qword [c1258]
    cvtss2si edx, dword [c1259]
    movdqu xmm8, [c1260]
    movdqu xmm14, [c1261]
    cvtss2si r15d, xmm8
    cvtss2si r15, xmm8
    cvttss2si r15d, xmm8
    cvttss2si r15, xmm8
    cvtsd2si r15d, xmm14
    cvtsd2si r15, xmm14
    cvttsd2si r15d, xmm14
    cvttsd2si r15, xmm14
    cvtsd2si r15, qword [c1262]
    cvtss2si r15d, dword [c1263]
    movdqu xmm11, [c1264]
    movdqu xmm1, [c1265]
    cvtss2si r15d, xmm11
    cvtss2si r15, xmm11
    cvttss2si r15d, xmm11
    cvttss2si r15, xmm11
    cvtsd2si r15d, xmm1
    cvtsd2si r15, xmm1
    cvttsd2si r15d, xmm1
    cvttsd2si r15, xmm1
    cvtsd2si r15, qword [c1266]
    cvtss2si r15d, dword [c1267]
    movdqu xmm13, [c1268]
    movdqu xmm4, [c1269]
    cvtss2si eax, xmm13
    cvtss2si rax, xmm13
    cvttss2si eax, xmm13
    cvttss2si rax, xmm13
    cvtsd2si eax, xmm4
    cvtsd2si rax, xmm4
    cvttsd2si eax, xmm4
    cvttsd2si rax, xmm4
    cvtsd2si rax, qword [c1270]
    cvtss2si eax, dword [c1271]
    movdqu xmm0, [c1272]
    movdqu xmm15, [c1273]
    cvtss2si ebp, xmm0
    cvtss2si rbp, xmm0
    cvttss2si ebp, xmm0
    cvttss2si rbp, xmm0
    cvtsd2si ebp, xmm15
    cvtsd2si rbp, xmm15
    cvttsd2si ebp, xmm15
    cvttsd2si rbp, xmm15
    cvtsd2si rbp, qword [c1274]
    cvtss2si ebp, dword [c1275]
    movdqu xmm2, [c1276]
    movdqu xmm15, [c1277]
    cvtss2si r15d, xmm2
    cvtss2si r15, xmm2
    cvttss2si r15d, xmm2
    cvttss2si r15, xmm2
    cvtsd2si r15d, xmm15
    cvtsd2si r15, xmm15
    cvttsd2si r15d, xmm15
    cvttsd2si r15, xmm15
    cvtsd2si r15, qword [c1278]
    cvtss2si r15d, dword [c1279]
    movdqu xmm1, [c1280]
    movdqu xmm6, [c1281]
    cvtps2dq xmm6, xmm1
    cvtps2dq xmm1, [c1282]
    movdqu xmm0, [c1283]
    movdqu xmm4, [c1284]
    cvtps2dq xmm4, xmm0
    cvtps2dq xmm0, [c1285]
    movdqu xmm11, [c1286]
    movdqu xmm6, [c1287]
    cvtps2dq xmm6, xmm11
    cvtps2dq xmm11, [c1288]
    movdqu xmm11, [c1289]
    movdqu xmm12, [c1290]
    cvtps2dq xmm12, xmm11
    cvtps2dq xmm11, [c1291]
    movdqu xmm13, [c1292]
    movdqu xmm8, [c1293]
    cvtps2dq xmm8, xmm13
    cvtps2dq xmm13, [c1294]
    movdqu xmm11, [c1295]
    movdqu xmm2, [c1296]
    cvttps2dq xmm2, xmm11
    cvttps2dq xmm11, [c1297]
    movdqu xmm3, [c1298]
    movdqu xmm15, [c1299]
    cvttps2dq xmm15, xmm3
    cvttps2dq xmm3, [c1300]
    movdqu xmm7, [c1301]
    movdqu xmm5, [c1302]
    cvttps2dq xmm5, xmm7
    cvttps2dq xmm7, [c1303]
    movdqu xmm11, [c1304]
    movdqu xmm7, [c1305]
    cvttps2dq xmm7, xmm11
    cvttps2dq xmm11, [c1306]
    movdqu xmm7, [c1307]
    movdqu xmm4, [c1308]
    cvttps2dq xmm4, xmm7
    cvttps2dq xmm7, [c1309]
    movdqu xmm15, [c1310]
    movdqu xmm6, [c1311]
    cvtpd2dq xmm6, xmm15
    cvtpd2dq xmm15, [c1312]
    movdqu xmm0, [c1313]
    movdqu xmm7, [c1314]
    cvtpd2dq xmm7, xmm0
    cvtpd2dq xmm0, [c1315]
    movdqu xmm4, [c1316]
    movdqu xmm8, [c1317]
    cvtpd2dq xmm8, xmm4
    cvtpd2dq xmm4, [c1318]
    movdqu xmm5, [c1319]
    movdqu xmm2, [c1320]
    cvtpd2dq xmm2, xmm5
    cvtpd2dq xmm5, [c1321]
    movdqu xmm3, [c1322]
    movdqu xmm6, [c1323]
    cvtpd2dq xmm6, xmm3
    cvtpd2dq xmm3, [c1324]
    movdqu xmm1, [c1325]
    movdqu xmm0, [c1326]
    cvttpd2dq xmm0, xmm1
    cvttpd2dq xmm1, [c1327]
    movdqu xmm12, [c1328]
    movdqu xmm10, [c1329]
    cvttpd2dq xmm10, xmm12
    cvttpd2dq xmm12, [c1330]
    movdqu xmm15, [c1331]
    movdqu xmm4, [c1332]
    cvttpd2dq xmm4, xmm15
    cvttpd2dq xmm15, [c1333]
    movdqu xmm3, [c1334]
    movdqu xmm8, [c1335]
    cvttpd2dq xmm8, xmm3
    cvttpd2dq xmm3, [c1336]
    movdqu xmm0, [c1337]
    movdqu xmm14, [c1338]
    cvttpd2dq xmm14, xmm0
    cvttpd2dq xmm0, [c1339]
    mov dword [buf], 0x3F80
    ldmxcsr [buf]
    stmxcsr [buf + 4]
    mov eax, [buf + 4]
    movdqu xmm15, [c1340]
    movdqu xmm7, [c1341]
    cvtss2si r9d, xmm15
    cvtss2si r9, xmm15
    cvttss2si r9d, xmm15
    cvttss2si r9, xmm15
    cvtsd2si r9d, xmm7
    cvtsd2si r9, xmm7
    cvttsd2si r9d, xmm7
    cvttsd2si r9, xmm7
    cvtsd2si r9, qword [c1342]
    cvtss2si r9d, dword [c1343]
    movdqu xmm1, [c1344]
    movdqu xmm9, [c1345]
    cvtss2si r8d, xmm1
    cvtss2si r8, xmm1
    cvttss2si r8d, xmm1
    cvttss2si r8, xmm1
    cvtsd2si r8d, xmm9
    cvtsd2si r8, xmm9
    cvttsd2si r8d, xmm9
    cvttsd2si r8, xmm9
    cvtsd2si r8, qword [c1346]
    cvtss2si r8d, dword [c1347]
    movdqu xmm2, [c1348]
    movdqu xmm10, [c1349]
    cvtss2si r13d, xmm2
    cvtss2si r13, xmm2
    cvttss2si r13d, xmm2
    cvttss2si r13, xmm2
    cvtsd2si r13d, xmm10
    cvtsd2si r13, xmm10
    cvttsd2si r13d, xmm10
    cvttsd2si r13, xmm10
    cvtsd2si r13, qword [c1350]
    cvtss2si r13d, dword [c1351]
    movdqu xmm10, [c1352]
    movdqu xmm8, [c1353]
    cvtss2si r9d, xmm10
    cvtss2si r9, xmm10
    cvttss2si r9d, xmm10
    cvttss2si r9, xmm10
    cvtsd2si r9d, xmm8
    cvtsd2si r9, xmm8
    cvttsd2si r9d, xmm8
    cvttsd2si r9, xmm8
    cvtsd2si r9, qword [c1354]
    cvtss2si r9d, dword [c1355]
    movdqu xmm2, [c1356]
    movdqu xmm5, [c1357]
    cvtss2si ebp, xmm2
    cvtss2si rbp, xmm2
    cvttss2si ebp, xmm2
    cvttss2si rbp, xmm2
    cvtsd2si ebp, xmm5
    cvtsd2si rbp, xmm5
    cvttsd2si ebp, xmm5
    cvttsd2si rbp, xmm5
    cvtsd2si rbp, qword [c1358]
    cvtss2si ebp, dword [c1359]
    movdqu xmm8, [c1360]
    movdqu xmm7, [c1361]
    cvtss2si r15d, xmm8
    cvtss2si r15, xmm8
    cvttss2si r15d, xmm8
    cvttss2si r15, xmm8
    cvtsd2si r15d, xmm7
    cvtsd2si r15, xmm7
    cvttsd2si r15d, xmm7
    cvttsd2si r15, xmm7
    cvtsd2si r15, qword [c1362]
    cvtss2si r15d, dword [c1363]
    movdqu xmm12, [c1364]
    movdqu xmm11, [c1365]
    cvtss2si ebp, xmm12
    cvtss2si rbp, xmm12
    cvttss2si ebp, xmm12
    cvttss2si rbp, xmm12
    cvtsd2si ebp, xmm11
    cvtsd2si rbp, xmm11
    cvttsd2si ebp, xmm11
    cvttsd2si rbp, xmm11
    cvtsd2si rbp, qword [c1366]
    cvtss2si ebp, dword [c1367]
    movdqu xmm8, [c1368]
    movdqu xmm4, [c1369]
    cvtss2si ecx, xmm8
    cvtss2si rcx, xmm8
    cvttss2si ecx, xmm8
    cvttss2si rcx, xmm8
    cvtsd2si ecx, xmm4
    cvtsd2si rcx, xmm4
    cvttsd2si ecx, xmm4
    cvttsd2si rcx, xmm4
    cvtsd2si rcx, qword [c1370]
    cvtss2si ecx, dword [c1371]
    movdqu xmm14, [c1372]
    movdqu xmm1, [c1373]
    cvtps2dq xmm1, xmm14
    cvtps2dq xmm14, [c1374]
    movdqu xmm10, [c1375]
    movdqu xmm5, [c1376]
    cvtps2dq xmm5, xmm10
    cvtps2dq xmm10, [c1377]
    movdqu xmm12, [c1378]
    movdqu xmm0, [c1379]
    cvtps2dq xmm0, xmm12
    cvtps2dq xmm12, [c1380]
    movdqu xmm7, [c1381]
    movdqu xmm5, [c1382]
    cvtps2dq xmm5, xmm7
    cvtps2dq xmm7, [c1383]
    movdqu xmm4, [c1384]
    movdqu xmm13, [c1385]
    cvtps2dq xmm13, xmm4
    cvtps2dq xmm4, [c1386]
    movdqu xmm5, [c1387]
    movdqu xmm4, [c1388]
    cvttps2dq xmm4, xmm5
    cvttps2dq xmm5, [c1389]
    movdqu xmm2, [c1390]
    movdqu xmm13, [c1391]
    cvttps2dq xmm13, xmm2
    cvttps2dq xmm2, [c1392]
    movdqu xmm10, [c1393]
    movdqu xmm5, [c1394]
    cvttps2dq xmm5, xmm10
    cvttps2dq xmm10, [c1395]
    movdqu xmm15, [c1396]
    movdqu xmm9, [c1397]
    cvttps2dq xmm9, xmm15
    cvttps2dq xmm15, [c1398]
    movdqu xmm8, [c1399]
    movdqu xmm5, [c1400]
    cvttps2dq xmm5, xmm8
    cvttps2dq xmm8, [c1401]
    movdqu xmm9, [c1402]
    movdqu xmm3, [c1403]
    cvtpd2dq xmm3, xmm9
    cvtpd2dq xmm9, [c1404]
    movdqu xmm0, [c1405]
    movdqu xmm10, [c1406]
    cvtpd2dq xmm10, xmm0
    cvtpd2dq xmm0, [c1407]
    movdqu xmm11, [c1408]
    movdqu xmm12, [c1409]
    cvtpd2dq xmm12, xmm11
    cvtpd2dq xmm11, [c1410]
    movdqu xmm15, [c1411]
    movdqu xmm0, [c1412]
    cvtpd2dq xmm0, xmm15
    cvtpd2dq xmm15, [c1413]
    movdqu xmm14, [c1414]
    movdqu xmm13, [c1415]
    cvtpd2dq xmm13, xmm14
    cvtpd2dq xmm14, [c1416]
    movdqu xmm11, [c1417]
    movdqu xmm3, [c1418]
    cvttpd2dq xmm3, xmm11
    cvttpd2dq xmm11, [c1419]
    movdqu xmm9, [c1420]
    movdqu xmm7, [c1421]
    cvttpd2dq xmm7, xmm9
    cvttpd2dq xmm9, [c1422]
    movdqu xmm0, [c1423]
    movdqu xmm10, [c1424]
    cvttpd2dq xmm10, xmm0
    cvttpd2dq xmm0, [c1425]
    movdqu xmm11, [c1426]
    movdqu xmm5, [c1427]
    cvttpd2dq xmm5, xmm11
    cvttpd2dq xmm11, [c1428]
    movdqu xmm15, [c1429]
    movdqu xmm3, [c1430]
    cvttpd2dq xmm3, xmm15
    cvttpd2dq xmm15, [c1431]
    mov dword [buf], 0x5F80
    ldmxcsr [buf]
    stmxcsr [buf + 4]
    mov eax, [buf + 4]
    movdqu xmm4, [c1432]
    movdqu xmm15, [c1433]
    cvtss2si r10d, xmm4
    cvtss2si r10, xmm4
    cvttss2si r10d, xmm4
    cvttss2si r10, xmm4
    cvtsd2si r10d, xmm15
    cvtsd2si r10, xmm15
    cvttsd2si r10d, xmm15
    cvttsd2si r10, xmm15
    cvtsd2si r10, qword [c1434]
    cvtss2si r10d, dword [c1435]
    movdqu xmm0, [c1436]
    movdqu xmm15, [c1437]
    cvtss2si r8d, xmm0
    cvtss2si r8, xmm0
    cvttss2si r8d, xmm0
    cvttss2si r8, xmm0
    cvtsd2si r8d, xmm15
    cvtsd2si r8, xmm15
    cvttsd2si r8d, xmm15
    cvttsd2si r8, xmm15
    cvtsd2si r8, qword [c1438]
    cvtss2si r8d, dword [c1439]
    movdqu xmm3, [c1440]
    movdqu xmm8, [c1441]
    cvtss2si edx, xmm3
    cvtss2si rdx, xmm3
    cvttss2si edx, xmm3
    cvttss2si rdx, xmm3
    cvtsd2si edx, xmm8
    cvtsd2si rdx, xmm8
    cvttsd2si edx, xmm8
    cvttsd2si rdx, xmm8
    cvtsd2si rdx, qword [c1442]
    cvtss2si edx, dword [c1443]
    movdqu xmm12, [c1444]
    movdqu xmm14, [c1445]
    cvtss2si r11d, xmm12
    cvtss2si r11, xmm12
    cvttss2si r11d, xmm12
    cvttss2si r11, xmm12
    cvtsd2si r11d, xmm14
    cvtsd2si r11, xmm14
    cvttsd2si r11d, xmm14
    cvttsd2si r11, xmm14
    cvtsd2si r11, qword [c1446]
    cvtss2si r11d, dword [c1447]
    movdqu xmm15, [c1448]
    movdqu xmm14, [c1449]
    cvtss2si r11d, xmm15
    cvtss2si r11, xmm15
    cvttss2si r11d, xmm15
    cvttss2si r11, xmm15
    cvtsd2si r11d, xmm14
    cvtsd2si r11, xmm14
    cvttsd2si r11d, xmm14
    cvttsd2si r11, xmm14
    cvtsd2si r11, qword [c1450]
    cvtss2si r11d, dword [c1451]
    movdqu xmm11, [c1452]
    movdqu xmm3, [c1453]
    cvtss2si esi, xmm11
    cvtss2si rsi, xmm11
    cvttss2si esi, xmm11
    cvttss2si rsi, xmm11
    cvtsd2si esi, xmm3
    cvtsd2si rsi, xmm3
    cvttsd2si esi, xmm3
    cvttsd2si rsi, xmm3
    cvtsd2si rsi, qword [c1454]
    cvtss2si esi, dword [c1455]
    movdqu xmm7, [c1456]
    movdqu xmm11, [c1457]
    cvtss2si r8d, xmm7
    cvtss2si r8, xmm7
    cvttss2si r8d, xmm7
    cvttss2si r8, xmm7
    cvtsd2si r8d, xmm11
    cvtsd2si r8, xmm11
    cvttsd2si r8d, xmm11
    cvttsd2si r8, xmm11
    cvtsd2si r8, qword [c1458]
    cvtss2si r8d, dword [c1459]
    movdqu xmm0, [c1460]
    movdqu xmm8, [c1461]
    cvtss2si r9d, xmm0
    cvtss2si r9, xmm0
    cvttss2si r9d, xmm0
    cvttss2si r9, xmm0
    cvtsd2si r9d, xmm8
    cvtsd2si r9, xmm8
    cvttsd2si r9d, xmm8
    cvttsd2si r9, xmm8
    cvtsd2si r9, qword [c1462]
    cvtss2si r9d, dword [c1463]
    movdqu xmm1, [c1464]
    movdqu xmm11, [c1465]
    cvtps2dq xmm11, xmm1
    cvtps2dq xmm1, [c1466]
    movdqu xmm9, [c1467]
    movdqu xmm15, [c1468]
    cvtps2dq xmm15, xmm9
    cvtps2dq xmm9, [c1469]
    movdqu xmm0, [c1470]
    movdqu xmm12, [c1471]
    cvtps2dq xmm12, xmm0
    cvtps2dq xmm0, [c1472]
    movdqu xmm10, [c1473]
    movdqu xmm15, [c1474]
    cvtps2dq xmm15, xmm10
    cvtps2dq xmm10, [c1475]
    movdqu xmm11, [c1476]
    movdqu xmm1, [c1477]
    cvtps2dq xmm1, xmm11
    cvtps2dq xmm11, [c1478]
    movdqu xmm6, [c1479]
    movdqu xmm13, [c1480]
    cvttps2dq xmm13, xmm6
    cvttps2dq xmm6, [c1481]
    movdqu xmm1, [c1482]
    movdqu xmm14, [c1483]
    cvttps2dq xmm14, xmm1
    cvttps2dq xmm1, [c1484]
    movdqu xmm0, [c1485]
    movdqu xmm13, [c1486]
    cvttps2dq xmm13, xmm0
    cvttps2dq xmm0, [c1487]
    movdqu xmm8, [c1488]
    movdqu xmm9, [c1489]
    cvttps2dq xmm9, xmm8
    cvttps2dq xmm8, [c1490]
    movdqu xmm13, [c1491]
    movdqu xmm14, [c1492]
    cvttps2dq xmm14, xmm13
    cvttps2dq xmm13, [c1493]
    movdqu xmm1, [c1494]
    movdqu xmm3, [c1495]
    cvtpd2dq xmm3, xmm1
    cvtpd2dq xmm1, [c1496]
    movdqu xmm0, [c1497]
    movdqu xmm2, [c1498]
    cvtpd2dq xmm2, xmm0
    cvtpd2dq xmm0, [c1499]
    movdqu xmm15, [c1500]
    movdqu xmm5, [c1501]
    cvtpd2dq xmm5, xmm15
    cvtpd2dq xmm15, [c1502]
    movdqu xmm15, [c1503]
    movdqu xmm12, [c1504]
    cvtpd2dq xmm12, xmm15
    cvtpd2dq xmm15, [c1505]
    movdqu xmm7, [c1506]
    movdqu xmm3, [c1507]
    cvtpd2dq xmm3, xmm7
    cvtpd2dq xmm7, [c1508]
    movdqu xmm3, [c1509]
    movdqu xmm2, [c1510]
    cvttpd2dq xmm2, xmm3
    cvttpd2dq xmm3, [c1511]
    movdqu xmm14, [c1512]
    movdqu xmm11, [c1513]
    cvttpd2dq xmm11, xmm14
    cvttpd2dq xmm14, [c1514]
    movdqu xmm10, [c1515]
    movdqu xmm4, [c1516]
    cvttpd2dq xmm4, xmm10
    cvttpd2dq xmm10, [c1517]
    movdqu xmm4, [c1518]
    movdqu xmm10, [c1519]
    cvttpd2dq xmm10, xmm4
    cvttpd2dq xmm4, [c1520]
    movdqu xmm10, [c1521]
    movdqu xmm3, [c1522]
    cvttpd2dq xmm3, xmm10
    cvttpd2dq xmm10, [c1523]
    mov dword [buf], 0x7F80
    ldmxcsr [buf]
    stmxcsr [buf + 4]
    mov eax, [buf + 4]
    movdqu xmm6, [c1524]
    movdqu xmm0, [c1525]
    cvtss2si r14d, xmm6
    cvtss2si r14, xmm6
    cvttss2si r14d, xmm6
    cvttss2si r14, xmm6
    cvtsd2si r14d, xmm0
    cvtsd2si r14, xmm0
    cvttsd2si r14d, xmm0
    cvttsd2si r14, xmm0
    cvtsd2si r14, qword [c1526]
    cvtss2si r14d, dword [c1527]
    movdqu xmm13, [c1528]
    movdqu xmm15, [c1529]
    cvtss2si edx, xmm13
    cvtss2si rdx, xmm13
    cvttss2si edx, xmm13
    cvttss2si rdx, xmm13
    cvtsd2si edx, xmm15
    cvtsd2si rdx, xmm15
    cvttsd2si edx, xmm15
    cvttsd2si rdx, xmm15
    cvtsd2si rdx, qword [c1530]
    cvtss2si edx, dword [c1531]
    movdqu xmm8, [c1532]
    movdqu xmm12, [c1533]
    cvtss2si edi, xmm8
    cvtss2si rdi, xmm8
    cvttss2si edi, xmm8
    cvttss2si rdi, xmm8
    cvtsd2si edi, xmm12
    cvtsd2si rdi, xmm12
    cvttsd2si edi, xmm12
    cvttsd2si rdi, xmm12
    cvtsd2si rdi, qword [c1534]
    cvtss2si edi, dword [c1535]
    movdqu xmm8, [c1536]
    movdqu xmm9, [c1537]
    cvtss2si ebx, xmm8
    cvtss2si rbx, xmm8
    cvttss2si ebx, xmm8
    cvttss2si rbx, xmm8
    cvtsd2si ebx, xmm9
    cvtsd2si rbx, xmm9
    cvttsd2si ebx, xmm9
    cvttsd2si rbx, xmm9
    cvtsd2si rbx, qword [c1538]
    cvtss2si ebx, dword [c1539]
    movdqu xmm8, [c1540]
    movdqu xmm1, [c1541]
    cvtss2si r9d, xmm8
    cvtss2si r9, xmm8
    cvttss2si r9d, xmm8
    cvttss2si r9, xmm8
    cvtsd2si r9d, xmm1
    cvtsd2si r9, xmm1
    cvttsd2si r9d, xmm1
    cvttsd2si r9, xmm1
    cvtsd2si r9, qword [c1542]
    cvtss2si r9d, dword [c1543]
    movdqu xmm15, [c1544]
    movdqu xmm3, [c1545]
    cvtss2si r10d, xmm15
    cvtss2si r10, xmm15
    cvttss2si r10d, xmm15
    cvttss2si r10, xmm15
    cvtsd2si r10d, xmm3
    cvtsd2si r10, xmm3
    cvttsd2si r10d, xmm3
    cvttsd2si r10, xmm3
    cvtsd2si r10, qword [c1546]
    cvtss2si r10d, dword [c1547]
    movdqu xmm0, [c1548]
    movdqu xmm15, [c1549]
    cvtss2si r15d, xmm0
    cvtss2si r15, xmm0
    cvttss2si r15d, xmm0
    cvttss2si r15, xmm0
    cvtsd2si r15d, xmm15
    cvtsd2si r15, xmm15
    cvttsd2si r15d, xmm15
    cvttsd2si r15, xmm15
    cvtsd2si r15, qword [c1550]
    cvtss2si r15d, dword [c1551]
    movdqu xmm5, [c1552]
    movdqu xmm14, [c1553]
    cvtss2si ebp, xmm5
    cvtss2si rbp, xmm5
    cvttss2si ebp, xmm5
    cvttss2si rbp, xmm5
    cvtsd2si ebp, xmm14
    cvtsd2si rbp, xmm14
    cvttsd2si ebp, xmm14
    cvttsd2si rbp, xmm14
    cvtsd2si rbp, qword [c1554]
    cvtss2si ebp, dword [c1555]
    movdqu xmm2, [c1556]
    movdqu xmm13, [c1557]
    cvtps2dq xmm13, xmm2
    cvtps2dq xmm2, [c1558]
    movdqu xmm3, [c1559]
    movdqu xmm4, [c1560]
    cvtps2dq xmm4, xmm3
    cvtps2dq xmm3, [c1561]
    movdqu xmm4, [c1562]
    movdqu xmm10, [c1563]
    cvtps2dq xmm10, xmm4
    cvtps2dq xmm4, [c1564]
    movdqu xmm15, [c1565]
    movdqu xmm12, [c1566]
    cvtps2dq xmm12, xmm15
    cvtps2dq xmm15, [c1567]
    movdqu xmm3, [c1568]
    movdqu xmm11, [c1569]
    cvtps2dq xmm11, xmm3
    cvtps2dq xmm3, [c1570]
    movdqu xmm1, [c1571]
    movdqu xmm14, [c1572]
    cvttps2dq xmm14, xmm1
    cvttps2dq xmm1, [c1573]
    movdqu xmm13, [c1574]
    movdqu xmm15, [c1575]
    cvttps2dq xmm15, xmm13
    cvttps2dq xmm13, [c1576]
    movdqu xmm1, [c1577]
    movdqu xmm9, [c1578]
    cvttps2dq xmm9, xmm1
    cvttps2dq xmm1, [c1579]
    movdqu xmm6, [c1580]
    movdqu xmm8, [c1581]
    cvttps2dq xmm8, xmm6
    cvttps2dq xmm6, [c1582]
    movdqu xmm6, [c1583]
    movdqu xmm2, [c1584]
    cvttps2dq xmm2, xmm6
    cvttps2dq xmm6, [c1585]
    movdqu xmm1, [c1586]
    movdqu xmm0, [c1587]
    cvtpd2dq xmm0, xmm1
    cvtpd2dq xmm1, [c1588]
    movdqu xmm9, [c1589]
    movdqu xmm6, [c1590]
    cvtpd2dq xmm6, xmm9
    cvtpd2dq xmm9, [c1591]
    movdqu xmm14, [c1592]
    movdqu xmm13, [c1593]
    cvtpd2dq xmm13, xmm14
    cvtpd2dq xmm14, [c1594]
    movdqu xmm9, [c1595]
    movdqu xmm7, [c1596]
    cvtpd2dq xmm7, xmm9
    cvtpd2dq xmm9, [c1597]
    movdqu xmm1, [c1598]
    movdqu xmm5, [c1599]
    cvtpd2dq xmm5, xmm1
    cvtpd2dq xmm1, [c1600]
    movdqu xmm1, [c1601]
    movdqu xmm15, [c1602]
    cvttpd2dq xmm15, xmm1
    cvttpd2dq xmm1, [c1603]
    movdqu xmm2, [c1604]
    movdqu xmm15, [c1605]
    cvttpd2dq xmm15, xmm2
    cvttpd2dq xmm2, [c1606]
    movdqu xmm8, [c1607]
    movdqu xmm6, [c1608]
    cvttpd2dq xmm6, xmm8
    cvttpd2dq xmm8, [c1609]
    movdqu xmm6, [c1610]
    movdqu xmm7, [c1611]
    cvttpd2dq xmm7, xmm6
    cvttpd2dq xmm6, [c1612]
    movdqu xmm3, [c1613]
    movdqu xmm5, [c1614]
    cvttpd2dq xmm5, xmm3
    cvttpd2dq xmm3, [c1615]
    mov dword [buf], 0x1F80
    ldmxcsr [buf]
    movdqu xmm5, [c1616]
    mov r9, 0x9D343B696844F474
    cvtsi2ss xmm5, r9d
    cvtsi2sd xmm5, r9d
    movdqu xmm5, [c1617]
    cvtsi2ss xmm5, r9
    cvtsi2sd xmm5, r9
    mov [buf + 8], r9
    cvtsi2sd xmm5, qword [buf + 8]
    cvtsi2ss xmm5, dword [buf + 8]
    movdqu xmm5, [c1618]
    mov rax, 0xFFFFFFFFFFFFFFB4
    cvtsi2ss xmm5, eax
    cvtsi2sd xmm5, eax
    movdqu xmm5, [c1619]
    cvtsi2ss xmm5, rax
    cvtsi2sd xmm5, rax
    mov [buf + 8], rax
    cvtsi2sd xmm5, qword [buf + 8]
    cvtsi2ss xmm5, dword [buf + 8]
    movdqu xmm13, [c1620]
    mov r10, 0x1
    cvtsi2ss xmm13, r10d
    cvtsi2sd xmm13, r10d
    movdqu xmm13, [c1621]
    cvtsi2ss xmm13, r10
    cvtsi2sd xmm13, r10
    mov [buf + 8], r10
    cvtsi2sd xmm13, qword [buf + 8]
    cvtsi2ss xmm13, dword [buf + 8]
    movdqu xmm15, [c1622]
    mov r9, 0x79B2E39285271126
    cvtsi2ss xmm15, r9d
    cvtsi2sd xmm15, r9d
    movdqu xmm15, [c1623]
    cvtsi2ss xmm15, r9
    cvtsi2sd xmm15, r9
    mov [buf + 8], r9
    cvtsi2sd xmm15, qword [buf + 8]
    cvtsi2ss xmm15, dword [buf + 8]
    movdqu xmm7, [c1624]
    mov r11, 0x3A53FD366EEA67C7
    cvtsi2ss xmm7, r11d
    cvtsi2sd xmm7, r11d
    movdqu xmm7, [c1625]
    cvtsi2ss xmm7, r11
    cvtsi2sd xmm7, r11
    mov [buf + 8], r11
    cvtsi2sd xmm7, qword [buf + 8]
    cvtsi2ss xmm7, dword [buf + 8]
    movdqu xmm4, [c1626]
    mov r15, 0x80000000
    cvtsi2ss xmm4, r15d
    cvtsi2sd xmm4, r15d
    movdqu xmm4, [c1627]
    cvtsi2ss xmm4, r15
    cvtsi2sd xmm4, r15
    mov [buf + 8], r15
    cvtsi2sd xmm4, qword [buf + 8]
    cvtsi2ss xmm4, dword [buf + 8]
    movdqu xmm3, [c1628]
    mov r10, 0x0
    cvtsi2ss xmm3, r10d
    cvtsi2sd xmm3, r10d
    movdqu xmm3, [c1629]
    cvtsi2ss xmm3, r10
    cvtsi2sd xmm3, r10
    mov [buf + 8], r10
    cvtsi2sd xmm3, qword [buf + 8]
    cvtsi2ss xmm3, dword [buf + 8]
    movdqu xmm13, [c1630]
    mov rdi, 0xD9DE4B1C3F115F40
    cvtsi2ss xmm13, edi
    cvtsi2sd xmm13, edi
    movdqu xmm13, [c1631]
    cvtsi2ss xmm13, rdi
    cvtsi2sd xmm13, rdi
    mov [buf + 8], rdi
    cvtsi2sd xmm13, qword [buf + 8]
    cvtsi2ss xmm13, dword [buf + 8]
    movdqu xmm15, [c1632]
    mov rbx, 0xC115F7D0A029843F
    cvtsi2ss xmm15, ebx
    cvtsi2sd xmm15, ebx
    movdqu xmm15, [c1633]
    cvtsi2ss xmm15, rbx
    cvtsi2sd xmm15, rbx
    mov [buf + 8], rbx
    cvtsi2sd xmm15, qword [buf + 8]
    cvtsi2ss xmm15, dword [buf + 8]
    movdqu xmm2, [c1634]
    mov rcx, 0xFFFFFFFFFFFFFF6E
    cvtsi2ss xmm2, ecx
    cvtsi2sd xmm2, ecx
    movdqu xmm2, [c1635]
    cvtsi2ss xmm2, rcx
    cvtsi2sd xmm2, rcx
    mov [buf + 8], rcx
    cvtsi2sd xmm2, qword [buf + 8]
    cvtsi2ss xmm2, dword [buf + 8]
    movdqu xmm6, [c1636]
    mov rax, 0x9D5277AC2530A0BA
    cvtsi2ss xmm6, eax
    cvtsi2sd xmm6, eax
    movdqu xmm6, [c1637]
    cvtsi2ss xmm6, rax
    cvtsi2sd xmm6, rax
    mov [buf + 8], rax
    cvtsi2sd xmm6, qword [buf + 8]
    cvtsi2ss xmm6, dword [buf + 8]
    movdqu xmm14, [c1638]
    mov r10, 0x1254AE6D301E2AA1
    cvtsi2ss xmm14, r10d
    cvtsi2sd xmm14, r10d
    movdqu xmm14, [c1639]
    cvtsi2ss xmm14, r10
    cvtsi2sd xmm14, r10
    mov [buf + 8], r10
    cvtsi2sd xmm14, qword [buf + 8]
    cvtsi2ss xmm14, dword [buf + 8]
    mov rax, 0x1000001
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x1000003
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x7FFFFFFFFFFFFFFF
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x8000000000000001
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x20000040000001
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x20000040000000
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x200000C0000000
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0xFFFFFF7FFFFFFFFF
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x40000080000001
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x7FFFFFBFFFFFFFFF
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    mov rax, 0x7FFFFFC000000000
    cvtsi2ss xmm1, rax
    cvtsi2sd xmm2, rax
    neg rax
    cvtsi2ss xmm3, rax
    movdqu xmm0, [c1640]
    movdqu xmm12, [c1641]
    cvtss2sd xmm12, xmm0
    cvtss2sd xmm0, dword [c1642]
    movdqu xmm13, [c1643]
    movdqu xmm14, [c1644]
    cvtss2sd xmm14, xmm13
    cvtss2sd xmm13, dword [c1645]
    movdqu xmm11, [c1646]
    movdqu xmm9, [c1647]
    cvtss2sd xmm9, xmm11
    cvtss2sd xmm11, dword [c1648]
    movdqu xmm12, [c1649]
    movdqu xmm10, [c1650]
    cvtss2sd xmm10, xmm12
    cvtss2sd xmm12, dword [c1651]
    movdqu xmm13, [c1652]
    movdqu xmm4, [c1653]
    cvtss2sd xmm4, xmm13
    cvtss2sd xmm13, dword [c1654]
    movdqu xmm12, [c1655]
    movdqu xmm14, [c1656]
    cvtss2sd xmm14, xmm12
    cvtss2sd xmm12, dword [c1657]
    movdqu xmm5, [c1658]
    movdqu xmm15, [c1659]
    cvtss2sd xmm15, xmm5
    cvtss2sd xmm5, dword [c1660]
    movdqu xmm2, [c1661]
    movdqu xmm12, [c1662]
    cvtss2sd xmm12, xmm2
    cvtss2sd xmm2, dword [c1663]
    movdqu xmm12, [c1664]
    movdqu xmm8, [c1665]
    cvtss2sd xmm8, xmm12
    cvtss2sd xmm12, dword [c1666]
    movdqu xmm8, [c1667]
    movdqu xmm10, [c1668]
    cvtss2sd xmm10, xmm8
    cvtss2sd xmm8, dword [c1669]
    movdqu xmm3, [c1670]
    movdqu xmm7, [c1671]
    cvtsd2ss xmm7, xmm3
    cvtsd2ss xmm3, qword [c1672]
    movdqu xmm12, [c1673]
    movdqu xmm10, [c1674]
    cvtsd2ss xmm10, xmm12
    cvtsd2ss xmm12, qword [c1675]
    movdqu xmm2, [c1676]
    movdqu xmm12, [c1677]
    cvtsd2ss xmm12, xmm2
    cvtsd2ss xmm2, qword [c1678]
    movdqu xmm12, [c1679]
    movdqu xmm11, [c1680]
    cvtsd2ss xmm11, xmm12
    cvtsd2ss xmm12, qword [c1681]
    movdqu xmm2, [c1682]
    movdqu xmm13, [c1683]
    cvtsd2ss xmm13, xmm2
    cvtsd2ss xmm2, qword [c1684]
    movdqu xmm3, [c1685]
    movdqu xmm13, [c1686]
    cvtsd2ss xmm13, xmm3
    cvtsd2ss xmm3, qword [c1687]
    movdqu xmm13, [c1688]
    movdqu xmm6, [c1689]
    cvtsd2ss xmm6, xmm13
    cvtsd2ss xmm13, qword [c1690]
    movdqu xmm2, [c1691]
    movdqu xmm12, [c1692]
    cvtsd2ss xmm12, xmm2
    cvtsd2ss xmm2, qword [c1693]
    movdqu xmm5, [c1694]
    movdqu xmm1, [c1695]
    cvtsd2ss xmm1, xmm5
    cvtsd2ss xmm5, qword [c1696]
    movdqu xmm8, [c1697]
    movdqu xmm10, [c1698]
    cvtsd2ss xmm10, xmm8
    cvtsd2ss xmm8, qword [c1699]
    movdqu xmm1, [c1700]
    movdqu xmm7, [c1701]
    cvtps2pd xmm7, xmm1
    cvtps2pd xmm1, qword [c1702]
    movdqu xmm9, [c1703]
    movdqu xmm15, [c1704]
    cvtps2pd xmm15, xmm9
    cvtps2pd xmm9, qword [c1705]
    movdqu xmm6, [c1706]
    movdqu xmm10, [c1707]
    cvtps2pd xmm10, xmm6
    cvtps2pd xmm6, qword [c1708]
    movdqu xmm9, [c1709]
    movdqu xmm7, [c1710]
    cvtps2pd xmm7, xmm9
    cvtps2pd xmm9, qword [c1711]
    movdqu xmm3, [c1712]
    movdqu xmm2, [c1713]
    cvtps2pd xmm2, xmm3
    cvtps2pd xmm3, qword [c1714]
    movdqu xmm0, [c1715]
    movdqu xmm2, [c1716]
    cvtps2pd xmm2, xmm0
    cvtps2pd xmm0, qword [c1717]
    movdqu xmm4, [c1718]
    movdqu xmm13, [c1719]
    cvtps2pd xmm13, xmm4
    cvtps2pd xmm4, qword [c1720]
    movdqu xmm10, [c1721]
    movdqu xmm5, [c1722]
    cvtps2pd xmm5, xmm10
    cvtps2pd xmm10, qword [c1723]
    movdqu xmm11, [c1724]
    movdqu xmm10, [c1725]
    cvtps2pd xmm10, xmm11
    cvtps2pd xmm11, qword [c1726]
    movdqu xmm11, [c1727]
    movdqu xmm5, [c1728]
    cvtps2pd xmm5, xmm11
    cvtps2pd xmm11, qword [c1729]
    movdqu xmm7, [c1730]
    movdqu xmm4, [c1731]
    cvtpd2ps xmm4, xmm7
    cvtpd2ps xmm7, [c1732]
    movdqu xmm12, [c1733]
    movdqu xmm15, [c1734]
    cvtpd2ps xmm15, xmm12
    cvtpd2ps xmm12, [c1735]
    movdqu xmm5, [c1736]
    movdqu xmm14, [c1737]
    cvtpd2ps xmm14, xmm5
    cvtpd2ps xmm5, [c1738]
    movdqu xmm7, [c1739]
    movdqu xmm10, [c1740]
    cvtpd2ps xmm10, xmm7
    cvtpd2ps xmm7, [c1741]
    movdqu xmm6, [c1742]
    movdqu xmm13, [c1743]
    cvtpd2ps xmm13, xmm6
    cvtpd2ps xmm6, [c1744]
    movdqu xmm11, [c1745]
    movdqu xmm0, [c1746]
    cvtpd2ps xmm0, xmm11
    cvtpd2ps xmm11, [c1747]
    movdqu xmm8, [c1748]
    movdqu xmm14, [c1749]
    cvtpd2ps xmm14, xmm8
    cvtpd2ps xmm8, [c1750]
    movdqu xmm6, [c1751]
    movdqu xmm13, [c1752]
    cvtpd2ps xmm13, xmm6
    cvtpd2ps xmm6, [c1753]
    movdqu xmm2, [c1754]
    movdqu xmm10, [c1755]
    cvtpd2ps xmm10, xmm2
    cvtpd2ps xmm2, [c1756]
    movdqu xmm8, [c1757]
    movdqu xmm0, [c1758]
    cvtpd2ps xmm0, xmm8
    cvtpd2ps xmm8, [c1759]
    movdqu xmm2, [c1760]
    movdqu xmm9, [c1761]
    cvtdq2ps xmm9, xmm2
    cvtdq2ps xmm2, [c1762]
    movdqu xmm14, [c1763]
    movdqu xmm13, [c1764]
    cvtdq2ps xmm13, xmm14
    cvtdq2ps xmm14, [c1765]
    movdqu xmm14, [c1766]
    movdqu xmm4, [c1767]
    cvtdq2ps xmm4, xmm14
    cvtdq2ps xmm14, [c1768]
    movdqu xmm15, [c1769]
    movdqu xmm8, [c1770]
    cvtdq2ps xmm8, xmm15
    cvtdq2ps xmm15, [c1771]
    movdqu xmm10, [c1772]
    movdqu xmm7, [c1773]
    cvtdq2ps xmm7, xmm10
    cvtdq2ps xmm10, [c1774]
    movdqu xmm5, [c1775]
    movdqu xmm15, [c1776]
    cvtdq2ps xmm15, xmm5
    cvtdq2ps xmm5, [c1777]
    movdqu xmm12, [c1778]
    movdqu xmm13, [c1779]
    cvtdq2ps xmm13, xmm12
    cvtdq2ps xmm12, [c1780]
    movdqu xmm7, [c1781]
    movdqu xmm0, [c1782]
    cvtdq2ps xmm0, xmm7
    cvtdq2ps xmm7, [c1783]
    movdqu xmm7, [c1784]
    movdqu xmm3, [c1785]
    cvtdq2ps xmm3, xmm7
    cvtdq2ps xmm7, [c1786]
    movdqu xmm11, [c1787]
    movdqu xmm10, [c1788]
    cvtdq2ps xmm10, xmm11
    cvtdq2ps xmm11, [c1789]
    movdqu xmm9, [c1790]
    movdqu xmm4, [c1791]
    cvtdq2pd xmm4, xmm9
    cvtdq2pd xmm9, qword [c1792]
    movdqu xmm10, [c1793]
    movdqu xmm1, [c1794]
    cvtdq2pd xmm1, xmm10
    cvtdq2pd xmm10, qword [c1795]
    movdqu xmm8, [c1796]
    movdqu xmm3, [c1797]
    cvtdq2pd xmm3, xmm8
    cvtdq2pd xmm8, qword [c1798]
    movdqu xmm14, [c1799]
    movdqu xmm12, [c1800]
    cvtdq2pd xmm12, xmm14
    cvtdq2pd xmm14, qword [c1801]
    movdqu xmm1, [c1802]
    movdqu xmm6, [c1803]
    cvtdq2pd xmm6, xmm1
    cvtdq2pd xmm1, qword [c1804]
    movdqu xmm0, [c1805]
    movdqu xmm6, [c1806]
    cvtdq2pd xmm6, xmm0
    cvtdq2pd xmm0, qword [c1807]
    movdqu xmm6, [c1808]
    movdqu xmm8, [c1809]
    cvtdq2pd xmm8, xmm6
    cvtdq2pd xmm6, qword [c1810]
    movdqu xmm8, [c1811]
    movdqu xmm11, [c1812]
    cvtdq2pd xmm11, xmm8
    cvtdq2pd xmm8, qword [c1813]
    movdqu xmm1, [c1814]
    movdqu xmm8, [c1815]
    cvtdq2pd xmm8, xmm1
    cvtdq2pd xmm1, qword [c1816]
    movdqu xmm5, [c1817]
    movdqu xmm2, [c1818]
    cvtdq2pd xmm2, xmm5
    cvtdq2pd xmm5, qword [c1819]
    movdqu xmm1, [c1820]
    movdqu xmm9, [c1821]
    minpd xmm1, xmm9
    movdqu xmm1, [c1822]
    minsd xmm1, xmm9
    movdqu xmm1, [c1823]
    movdqu xmm9, [c1824]
    minpd xmm1, xmm9
    movdqu xmm1, [c1825]
    minsd xmm1, xmm9
    movdqu xmm1, [c1826]
    movdqu xmm9, [c1827]
    minpd xmm1, xmm9
    movdqu xmm1, [c1828]
    minsd xmm1, xmm9
    movdqu xmm2, [c1829]
    movdqu xmm10, [c1830]
    minps xmm2, xmm10
    movdqu xmm2, [c1831]
    minss xmm2, xmm10
    movdqu xmm2, [c1832]
    movdqu xmm10, [c1833]
    minps xmm2, xmm10
    movdqu xmm2, [c1834]
    minss xmm2, xmm10
    movdqu xmm2, [c1835]
    movdqu xmm10, [c1836]
    minps xmm2, xmm10
    movdqu xmm2, [c1837]
    minss xmm2, xmm10
    movdqu xmm1, [c1838]
    movdqu xmm9, [c1839]
    maxpd xmm1, xmm9
    movdqu xmm1, [c1840]
    maxsd xmm1, xmm9
    movdqu xmm1, [c1841]
    movdqu xmm9, [c1842]
    maxpd xmm1, xmm9
    movdqu xmm1, [c1843]
    maxsd xmm1, xmm9
    movdqu xmm1, [c1844]
    movdqu xmm9, [c1845]
    maxpd xmm1, xmm9
    movdqu xmm1, [c1846]
    maxsd xmm1, xmm9
    movdqu xmm2, [c1847]
    movdqu xmm10, [c1848]
    maxps xmm2, xmm10
    movdqu xmm2, [c1849]
    maxss xmm2, xmm10
    movdqu xmm2, [c1850]
    movdqu xmm10, [c1851]
    maxps xmm2, xmm10
    movdqu xmm2, [c1852]
    maxss xmm2, xmm10
    movdqu xmm2, [c1853]
    movdqu xmm10, [c1854]
    maxps xmm2, xmm10
    movdqu xmm2, [c1855]
    maxss xmm2, xmm10
    movdqu xmm3, [c1856]
    movdqu xmm11, [c1857]
    cmppd xmm3, xmm11, 0
    movdqu xmm3, [c1858]
    movdqu xmm11, [c1859]
    cmppd xmm3, xmm11, 0
    movdqu xmm3, [c1860]
    cmpsd xmm3, xmm11, 0
    movdqu xmm4, [c1861]
    movdqu xmm12, [c1862]
    cmpps xmm4, xmm12, 0
    movdqu xmm4, [c1863]
    movdqu xmm12, [c1864]
    cmpss xmm4, xmm12, 0
    movdqu xmm3, [c1865]
    movdqu xmm11, [c1866]
    cmppd xmm3, xmm11, 1
    movdqu xmm3, [c1867]
    movdqu xmm11, [c1868]
    cmppd xmm3, xmm11, 1
    movdqu xmm3, [c1869]
    cmpsd xmm3, xmm11, 1
    movdqu xmm4, [c1870]
    movdqu xmm12, [c1871]
    cmpps xmm4, xmm12, 1
    movdqu xmm4, [c1872]
    movdqu xmm12, [c1873]
    cmpss xmm4, xmm12, 1
    movdqu xmm3, [c1874]
    movdqu xmm11, [c1875]
    cmppd xmm3, xmm11, 2
    movdqu xmm3, [c1876]
    movdqu xmm11, [c1877]
    cmppd xmm3, xmm11, 2
    movdqu xmm3, [c1878]
    cmpsd xmm3, xmm11, 2
    movdqu xmm4, [c1879]
    movdqu xmm12, [c1880]
    cmpps xmm4, xmm12, 2
    movdqu xmm4, [c1881]
    movdqu xmm12, [c1882]
    cmpss xmm4, xmm12, 2
    movdqu xmm3, [c1883]
    movdqu xmm11, [c1884]
    cmppd xmm3, xmm11, 3
    movdqu xmm3, [c1885]
    movdqu xmm11, [c1886]
    cmppd xmm3, xmm11, 3
    movdqu xmm3, [c1887]
    cmpsd xmm3, xmm11, 3
    movdqu xmm4, [c1888]
    movdqu xmm12, [c1889]
    cmpps xmm4, xmm12, 3
    movdqu xmm4, [c1890]
    movdqu xmm12, [c1891]
    cmpss xmm4, xmm12, 3
    movdqu xmm3, [c1892]
    movdqu xmm11, [c1893]
    cmppd xmm3, xmm11, 4
    movdqu xmm3, [c1894]
    movdqu xmm11, [c1895]
    cmppd xmm3, xmm11, 4
    movdqu xmm3, [c1896]
    cmpsd xmm3, xmm11, 4
    movdqu xmm4, [c1897]
    movdqu xmm12, [c1898]
    cmpps xmm4, xmm12, 4
    movdqu xmm4, [c1899]
    movdqu xmm12, [c1900]
    cmpss xmm4, xmm12, 4
    movdqu xmm3, [c1901]
    movdqu xmm11, [c1902]
    cmppd xmm3, xmm11, 5
    movdqu xmm3, [c1903]
    movdqu xmm11, [c1904]
    cmppd xmm3, xmm11, 5
    movdqu xmm3, [c1905]
    cmpsd xmm3, xmm11, 5
    movdqu xmm4, [c1906]
    movdqu xmm12, [c1907]
    cmpps xmm4, xmm12, 5
    movdqu xmm4, [c1908]
    movdqu xmm12, [c1909]
    cmpss xmm4, xmm12, 5
    movdqu xmm3, [c1910]
    movdqu xmm11, [c1911]
    cmppd xmm3, xmm11, 6
    movdqu xmm3, [c1912]
    movdqu xmm11, [c1913]
    cmppd xmm3, xmm11, 6
    movdqu xmm3, [c1914]
    cmpsd xmm3, xmm11, 6
    movdqu xmm4, [c1915]
    movdqu xmm12, [c1916]
    cmpps xmm4, xmm12, 6
    movdqu xmm4, [c1917]
    movdqu xmm12, [c1918]
    cmpss xmm4, xmm12, 6
    movdqu xmm3, [c1919]
    movdqu xmm11, [c1920]
    cmppd xmm3, xmm11, 7
    movdqu xmm3, [c1921]
    movdqu xmm11, [c1922]
    cmppd xmm3, xmm11, 7
    movdqu xmm3, [c1923]
    cmpsd xmm3, xmm11, 7
    movdqu xmm4, [c1924]
    movdqu xmm12, [c1925]
    cmpps xmm4, xmm12, 7
    movdqu xmm4, [c1926]
    movdqu xmm12, [c1927]
    cmpss xmm4, xmm12, 7
    mov rax, 0x40000040000001
    cvtsi2ss xmm5, rax
    neg rax
    cvtsi2ss xmm6, rax
    mov rax, 0x40000040000000
    cvtsi2ss xmm5, rax
    neg rax
    cvtsi2ss xmm6, rax
    mov rax, 0x400000C0000001
    cvtsi2ss xmm5, rax
    neg rax
    cvtsi2ss xmm6, rax
    mov rax, 0x4000004000000400
    cvtsi2ss xmm5, rax
    neg rax
    cvtsi2ss xmm6, rax
    EXIT
    align 16
c0: dq 0x5F00000000000000, 0xC444303E3F800000
c1: dq 0x7FFFFF40200000, 0x7FC00000007FFFFF
c2: dq 0x7F7FFFFF40200000, 0x5F000000501502F9
c3: dq 0x80000001C40196A7, 0xC3C5725F442D816F
c4: dq 0x7F7FC99E00000000, 0xC3CD510700000001
c5: dq 0x439FF964C45B9A6F, 0x4F0000003F800000
c6: dq 0xC418FE054B800000, 0x7F80000080000001
c7: dq 0x501502F9501502F9, 0x3DCCCCCDDF000000
c8: dq 0x3F00000000800000, 0x402000004F800000
c9: dq 0x43AFBBEA006CE3EE, 0xFF80012300000001
c10: dq 0x6CE3EE, 0x7FFFFF7F800000
c11: dq 0x7F7FFFFFD01502F9, 0x43A85843C4644D83
c12: dq 0xC1A00C723DCCCCCD, 0x7F7FFFFF40F00000
c13: dq 0x4EFFFFFF7F7FFFFF, 0xC30B07F73F800000
c14: dq 0x80000047F12065, 0x402000003F800000
c15: dq 0xC02000005F000000, 0xC020000000000001
c16: dq 0x6CE3EE5F000000, 0xFFC000004F000000
c17: dq 0x3DCCCCCDFFC00000, 0xC35C02714EFFFFFF
c18: dq 0x7F7FC99E7F800000, 0xC44203BB4435C5E0
c19: dq 0x3F800000444B9B50, 0xBF8000003FC00000
c20: dq 0x47F12065DF000000, 0xC0F000007FA00001
c21: dq 0xC35EF63BDF000000, 0xFF800123C295ED18
c22: dq 0xBF80000040400000, 0x2EDBE6FF5F000000
c23: dq 0x4351F45DCF000000, 0xC45AA67CC2C60727
c24: dq 0x4B800000C0200000, 0x6CE3EEC13764F6
c25: dq 0x402000007FC12345, 0x3F000000C2BC5CB8
c26: dq 0xFFC000004304AAEE, 0xBF80000040400000
c27: dq 0x501502F9FFC00000, 0x42E21695007FFFFF
c28: dq 0xBF8000007FC12345, 0x7FA0000100000000
c29: dq 0xBF0000003F000000, 0x7F7FFFFF3F000000
c30: dq 0x41DFFFFFFFE00000, 0xC202A05F20000000
c31: dq 0x4088EA00DAC0B2AC, 0x1
c32: dq 0xC202A05F20000000, 0x40FE240C9FBE76C9
c33: dq 0x41DFFFFFFFE00000, 0x47EFFFFFF0000000
c34: dq 0x4004000000000000, 0x4008000000000000
c35: dq 0x7FF8000000000000, 0xFFF8000000000000
c36: dq 0xFFF0000000000123, 0x4340000000000000
c37: dq 0x7FF8000012345678, 0xC087DC89415C2F0E
c38: dq 0x401E000000000000, 0x3FDFFFFFFFFFFFFF
c39: dq 0x41F0000000000000, 0x47EFFFFFF0000000
c40: dq 0xC01E000000000000, 0x7FF8000012345678
c41: dq 0x3FB999999999999A, 0x4340000000000000
c42: dq 0x4004000000000000, 0xC0874F06319FF23C
c43: dq 0xC088039399C02A3C, 0x7FF0000000000000
c44: dq 0xC086ED2ABFC92184, 0x7FF0000000000000
c45: dq 0xC08298CBD5DC4ED1, 0x40806E990D26C2CC
c46: dq 0x41DFFFFFFFC00000, 0x7FEE42D130773B76
c47: dq 0x7FF4000000000001, 0x3FF0000000000000
c48: dq 0x366244CE242C5561, 0xC01E000000000000
c49: dq 0xC058F4D7A19F8340, 0x4038AD38179ED5C0
c50: dq 0x43E0000000000000, 0x3DDB7CDFD9D7BDBB
c51: dq 0xC01E000000000000, 0xBFF0000000000000
c52: dq 0x40FE240C9FBE76C9, 0x4004000000000000
c53: dq 0xFFF0000000000000, 0x4008000000000000
c54: dq 0x47EFFFFFF0000000, 0x40855BCD2105B682
c55: dq 0xC0703B93104DF024, 0xFFF0000000000000
c56: dq 0x407AEDC030DFC1C0, 0xFFFFFFFFFFFFF
c57: dq 0x3FE274A17345C800, 0xFFF0000000000123
c58: dq 0x4340000000000000, 0x4008000000000000
c59: dq 0x730D67819E8D2, 0xBFF0000000000000
c60: dq 0xBF800000C0F00000, 0x7FFFFFC3F0145B
c61: dq 0xD01502F940400000, 0x800000007FA00001
c62: dq 0x1, 0x437F651B43DCE5A9
c63: dq 0x4454D122C3E7573D, 0x7FA00001BF000000
c64: dq 0x6CE3EEFF800123, 0x6CE3EE438B5072
c65: dq 0x501502F9501502F9, 0x7FC1234542F140AF
c66: dq 0x3EFFFFFF7FC12345, 0xC4783098BF800000
c67: dq 0x3F8000004B800000, 0x7FA0000143A9882F
c68: dq 0xBF00000040F00000, 0x3EFFFFFF00800000
c69: dq 0x3DCCCCCD006CE3EE, 0x5F0000003FC00000
c70: dq 0x44706E7C80000000, 0x3EFFFFFFFF800123
c71: dq 0x4410006243F53455, 0xC45E557040400000
c72: dq 0x4378CCB2C0200000, 0x3EFFFFFFDF000000
c73: dq 0xD01502F9FFC00000, 0x5F000000DF000000
c74: dq 0xFF800123007FFFFF, 0x47F12065FF800123
c75: dq 0x3DCCCCCDC0200000, 0x800000006CE3EE
c76: dq 0xC36E45E6FF800123, 0x7FC123457F7FC99E
c77: dq 0xC43630C04418601C, 0xC0200000C38D5803
c78: dq 0x40400000434ABC6E, 0x4020000080000001
c79: dq 0x7FFFFF40400000, 0x4F800000C32F0181
c80: dq 0xFF8000007FC12345, 0x4EFFFFFFC0F00000
c81: dq 0x7F7FFFFF006CE3EE, 0xC0F00000501502F9
c82: dq 0xDF0000007F7FC99E, 0x8000000080000001
c83: dq 0xC4315CB947F12065, 0x80000001FF800123
c84: dq 0xFF800000C33F4DCE, 0x4EFFFFFF7FC00000
c85: dq 0x7FC1234543C7D802, 0x8000003FC00000
c86: dq 0x4EFFFFFF4433CA52, 0xCF0000004F800000
c87: dq 0x5F0000007F800000, 0xC0F000003F000000
c88: dq 0x43A89FDC4460A513, 0xC4598FE080000001
c89: dq 0x5F0000007FC00000, 0x7FA00001D01502F9
c90: dq 0x0, 0xC08A04E569AC4B21
c91: dq 0xFFF0000000000000, 0x7FF8000000000000
c92: dq 0x1, 0xBFE0000000000000
c93: dq 0xC01E000000000000, 0x41DFFFFFFFC00000
c94: dq 0x8000000000000000, 0x7FF0000000000000
c95: dq 0xC1E0000000100000, 0xC077AF0BE6FD97F4
c96: dq 0xC01E000000000000, 0x41DFFFFFFFE00000
c97: dq 0x8000000000000000, 0xC0640EA6C1A04F98
c98: dq 0xC07D87CA80BA3776, 0x3FB999999999999A
c99: dq 0x4004000000000000, 0x41DFFFFFFFC00000
c100: dq 0xC08575EE6F1A9F12, 0xBFF0000000000000
c101: dq 0x47EFFFFFF0000000, 0x43E0000000000000
c102: dq 0x1, 0xBFE0000000000000
c103: dq 0x3FF0000000000000, 0x41E0000000000000
c104: dq 0x7FF0000000000000, 0x730D67819E8D2
c105: dq 0x4340000000000000, 0xBFF0000000000000
c106: dq 0x4040F96FC9393300, 0x3DDB7CDFD9D7BDBB
c107: dq 0xBFE0000000000000, 0xC1E0000000000000
c108: dq 0xFFF0000000000123, 0x4076FF7DDFDFF110
c109: dq 0x3FF8000000000000, 0x3FB999999999999A
c110: dq 0x730D67819E8D2, 0xC202A05F20000000
c111: dq 0xC3E0000000000000, 0x4202A05F20000000
c112: dq 0x406AE90BA71033D0, 0x43E158E460913D00
c113: dq 0xC06FC3DCC4ADE534, 0x3FF0000000000000
c114: dq 0x7FF0000000000000, 0x406DF458D4FA1890
c115: dq 0x7FF4000000000001, 0xC063A07E4046628C
c116: dq 0xBFF0000000000000, 0x7FF4000000000001
c117: dq 0x43E0000000000000, 0x408A8F4939CA3B0C
c118: dq 0x408D3D006CE9AB18, 0x407E88E08A75EB9C
c119: dq 0x41DFFFFFFFC00000, 0x7FF0000000000000
c120: dq 0x501502F97FC00000, 0x4F00000040F00000
c121: dq 0xFF800000006CE3EE, 0x3F000000FF800123
c122: dq 0x4440AAAC, 0x3F0000004F800000
c123: dq 0xDF00000043D7479A, 0x7F7FC99EC3F7F9FD
c124: dq 0x80000001, 0x7F7FFFFF425BAB47
c125: dq 0x4F0000007FA00001, 0x6CE3EED01502F9
c126: dq 0x501502F97F7FFFFF, 0x43FC319BCF000000
c127: dq 0x8000000180000000, 0x7FC1234540200000
c128: dq 0x501502F95F000000, 0x800000DF000000
c129: dq 0x40200000C3A435EF, 0x40200000007FFFFF
c130: dq 0x7FC000004F800000, 0x40400000501502F9
c131: dq 0x40200000C40F4E11, 0xDF000000C387D8DC
c132: dq 0x4416479C, 0x3DCCCCCD43F5CB12
c133: dq 0xFFC000004381442C, 0x43EF80F47F7FC99E
c134: dq 0x7FC12345006CE3EE, 0xFF80000040400000
c135: dq 0x6CE3EE3F800000, 0xBF0000007F7FC99E
c136: dq 0x4EFFFFFFDF000000, 0xBF80000000000000
c137: dq 0x44527A6700000001, 0xFF8001237FC12345
c138: dq 0x7FA00001C42F9E0D, 0xFF8000004378812C
c139: dq 0xFF800000007FFFFF, 0xBF8000007FC12345
c140: dq 0xFFC000007F7FFFFF, 0x501502F93DCCCCCD
c141: dq 0xFFC000003FC00000, 0xC417E9B4C0200000
c142: dq 0x7FC12345D01502F9, 0x40F000003F000000
c143: dq 0x2EDBE6FFBF800000, 0x43A7E4073DCCCCCD
c144: dq 0x800000013DCCCCCD, 0xBF000000C0200000
c145: dq 0x3DCCCCCD5F000000, 0x7F7FC99E7FC12345
c146: dq 0x501502F947F12065, 0x40F00000501502F9
c147: dq 0x1C43818E6, 0x3DCCCCCDDF000000
c148: dq 0xC42ECEAAC1B5D068, 0x80000001501502F9
c149: dq 0x440405A64EFFFFFF, 0xFFC00000C4490DF1
c150: dq 0x407CFE74E5BD2BDC, 0x401E000000000000
c151: dq 0x43E158E460913D00, 0x7FEFFFFFFFFFFFFF
c152: dq 0x40853B650008F9DC, 0x3DDB7CDFD9D7BDBB
c153: dq 0xFFF8000000000000, 0x408A4236B2E0A976
c154: dq 0x730D67819E8D2, 0x40FE240C9FBE76C9
c155: dq 0x7FEE42D130773B76, 0x0
c156: dq 0x4202A05F20000000, 0xFFF0000000000123
c157: dq 0xFFF8000000000000, 0x41E0000000000000
c158: dq 0xFFF8000000000000, 0xC0730E8739C2D004
c159: dq 0x40629194268B5AA8, 0x7FEE42D130773B76
c160: dq 0xC07E85960E7F6D76, 0x7FF0000000000000
c161: dq 0x4081081BF6F7AE4C, 0xC3E0000000000000
c162: dq 0xFFFFFFFFFFFFF, 0x366244CE242C5561
c163: dq 0x41F0000000000000, 0x4202A05F20000000
c164: dq 0x730D67819E8D2, 0xC1E0000000000000
c165: dq 0xC202A05F20000000, 0xFFF0000000000000
c166: dq 0x366244CE242C5561, 0xC202A05F20000000
c167: dq 0x408ABD98A5FE67A2, 0x730D67819E8D2
c168: dq 0xC07187324ABE2DF0, 0x3FDFFFFFFFFFFFFF
c169: dq 0x41E0000000000000, 0xFFFFFFFFFFFFF
c170: dq 0xC1E0000000100000, 0xC1E0000000100000
c171: dq 0x408C50FB58CCD602, 0x4085D17079B981AE
c172: dq 0x3FF0000000000000, 0xC202A05F20000000
c173: dq 0x406D4C01A755B2B0, 0x4073CEC8114D8670
c174: dq 0x7FF0000000000000, 0x366244CE242C5561
c175: dq 0xC08F1195E20C4524, 0x4004000000000000
c176: dq 0x10000000000000, 0x408F2A6743C0C0A6
c177: dq 0x47EFFFFFF0000000, 0x41E0000000000000
c178: dq 0x408941772EDF2B6C, 0x40811F05F3D44FE6
c179: dq 0x47EFFFFFF0000000, 0x40FE240C9FBE76C9
c180: dq 0xC300C81BFFC00000, 0xC3CF1340
c181: dq 0x7F7FFFFFC46C2321, 0x3DCCCCCD4F800000
c182: dq 0x2EDBE6FFFFC00000, 0xC434FBF2C0F00000
c183: dq 0xFFC00000FFC00000, 0xBF80000040400000
c184: dq 0x438AD1B444259304, 0x3F800000
c185: dq 0x40200000FFC00000, 0x7FFFFFCF000000
c186: dq 0xC3BBDDA27FC00000, 0x14EFFFFFF
c187: dq 0x4B800000C0200000, 0x4B8000007FA00001
c188: dq 0xC2D3992EC3268261, 0xBF8000004F000000
c189: dq 0xFF800123DF000000, 0xC43BC5037FC00000
c190: dq 0x40200000C0200000, 0xFF800000440A9C53
c191: dq 0x47F120652EDBE6FF, 0xC42BFC74C19A344C
c192: dq 0x80000000C4416E64, 0x40200000C0F00000
c193: dq 0x8000003F800000, 0x40400000C0200000
c194: dq 0x44084413FFC00000, 0x3FC000003DCCCCCD
c195: dq 0xFF800000C2E265A9, 0x420BC98300000001
c196: dq 0x44356DBE, 0xD01502F900800000
c197: dq 0x43EBEDCA7F800000, 0x3F000000CF000000
c198: dq 0xFF80000040400000, 0x501502F980000000
c199: dq 0x4EFFFFFFDF000000, 0x4040000000000001
c200: dq 0x4B800000D01502F9, 0xDF0000003FC00000
c201: dq 0xDF0000007FA00001, 0x7FA000012EDBE6FF
c202: dq 0x4428E6194451AC0E, 0x2EDBE6FFBF800000
c203: dq 0xBF800000C3A49748, 0xCF000000C37789CB
c204: dq 0x8000000040F00000, 0xC33135663DCCCCCD
c205: dq 0x3EFFFFFFBF800000, 0xFF80000047F12065
c206: dq 0x47F120657FA00001, 0x4441C62E437BDB5D
c207: dq 0x3F800000C35B9CFC, 0x3F80000044387B47
c208: dq 0x1501502F9, 0x446A89134F800000
c209: dq 0x3EFFFFFFDF000000, 0x3EFFFFFFC3A397F5
c210: dq 0x4340000000000000, 0x7FF0000000000000
c211: dq 0xC07B60137A174AB0, 0xC06F9014C6705190
c212: dq 0x730D67819E8D2, 0xC1E0000000000000
c213: dq 0x7FF4000000000001, 0x43E0000000000000
c214: dq 0xBFF0000000000000, 0x7FF4000000000001
c215: dq 0x407AACE9ABB59050, 0x43E158E460913D00
c216: dq 0x4008000000000000, 0x41DFFFFFFFE00000
c217: dq 0x4086853B881A826E, 0xC202A05F20000000
c218: dq 0x43E0000000000000, 0xC1E0000000000000
c219: dq 0x406CBD5C90A15F78, 0x43E0000000000000
c220: dq 0x3FE0000000000000, 0xFFF8000000000000
c221: dq 0xFFF0000000000000, 0x7FF0000000000000
c222: dq 0xC08753BA00B41D90, 0x10000000000000
c223: dq 0xC084D15D8FC71430, 0x1
c224: dq 0x7FEFFFFFFFFFFFFF, 0xC3E0000000000000
c225: dq 0x40885E55D7CF550A, 0x407F46329B84E1E0
c226: dq 0x43E0000000000000, 0x7FEE42D130773B76
c227: dq 0xC004000000000000, 0xC202A05F20000000
c228: dq 0x3FB999999999999A, 0x7FEFFFFFFFFFFFFF
c229: dq 0xC3E0000000000000, 0xBFF0000000000000
c230: dq 0x43E158E460913D00, 0xFFF0000000000123
c231: dq 0x43E158E460913D00, 0x4004000000000000
c232: dq 0xFFF0000000000123, 0xFFFFFFFFFFFFF
c233: dq 0x3FE0000000000000, 0x7FF8000012345678
c234: dq 0x3FF8000000000000, 0x43E0000000000000
c235: dq 0xFFF8000000000000, 0x3FB999999999999A
c236: dq 0xC1E0000000100000, 0xC051CF39FD055170
c237: dq 0x730D67819E8D2, 0x41DFFFFFFFC00000
c238: dq 0xFFF0000000000000, 0x10000000000000
c239: dq 0x7FEE42D130773B76, 0x47EFFFFFF0000000
c240: dq 0x7FC0000000000000, 0xC40FF1873FC00000
c241: dq 0x7FFFFFBF800000, 0x3EFFFFFF47F12065
c242: dq 0x3FC0000042E05D54, 0x7FFFFF80000001
c243: dq 0xD01502F93DCCCCCD, 0xC4476B385F000000
c244: dq 0xC02000007FC12345, 0x501502F97F800000
c245: dq 0x4B8000007FA00001, 0x4EFFFFFFBF800000
c246: dq 0x6CE3EE4F800000, 0x80000001006CE3EE
c247: dq 0x3FC000004264A04D, 0xD01502F93F000000
c248: dq 0x4B800000C0F00000, 0x40400000D01502F9
c249: dq 0x7FA00001C414252C, 0x501502F9C41586BD
c250: dq 0x8000007F800000, 0x4F000000C0F00000
c251: dq 0x800000FFC00000, 0xD01502F940F00000
c252: dq 0xC0F000007FC12345, 0x3F000000DF000000
c253: dq 0x4F000000501502F9, 0xBF8000004F800000
c254: dq 0xC3AD117D44550A7C, 0x3F8000004F800000
c255: dq 0x3DCCCCCD3DCCCCCD, 0xDF000000CF000000
c256: dq 0x3DCCCCCD00800000, 0x3FC0000040F00000
c257: dq 0x6CE3EE446B0338, 0x4EFFFFFF2EDBE6FF
c258: dq 0x7FA000014B800000, 0x4F000000442982BC
c259: dq 0x40F00000007FFFFF, 0xFFC000004F800000
c260: dq 0x4F000000CF000000, 0xC3C73ED2D01502F9
c261: dq 0xC4720DDA4F000000, 0x40F000005F000000
c262: dq 0xFFC0000040F00000, 0x3EFFFFFFC3B4730E
c263: dq 0x7FFFFFFF800000, 0x3DCCCCCD7FC00000
c264: dq 0x4B80000000800000, 0x410D329D4B800000
c265: dq 0x7F7FFFFF00800000, 0x4EFFFFFF
c266: dq 0x43C96BD900800000, 0x43A9F1AC47F12065
c267: dq 0x47F120657FC00000, 0xC405DF6AC0200000
c268: dq 0x5F0000002EDBE6FF, 0xCF0000004416C2B0
c269: dq 0xC0200000C3A2CACA, 0x800000FFC00000
c270: dq 0x4008000000000000, 0x4004000000000000
c271: dq 0x1, 0x1
c272: dq 0x408440B34677CD04, 0xBFF0000000000000
c273: dq 0x1, 0x4008000000000000
c274: dq 0x7FEFFFFFFFFFFFFF, 0xC066BFF26EB473AC
c275: dq 0xC3E0000000000000, 0x366244CE242C5561
c276: dq 0x3FB999999999999A, 0xC1E0000000100000
c277: dq 0x7FEFFFFFFFFFFFFF, 0xC06D4B2F80551508
c278: dq 0x40789FAA8EE6477C, 0xC004000000000000
c279: dq 0x43E158E460913D00, 0xC08792F3196709F9
c280: dq 0x4008000000000000, 0x3FDFFFFFFFFFFFFF
c281: dq 0x0, 0x4340000000000000
c282: dq 0x408F167BD2B24D28, 0x3DDB7CDFD9D7BDBB
c283: dq 0x4086B435A99F6F8C, 0x3DDB7CDFD9D7BDBB
c284: dq 0xFFF0000000000000, 0x3FF0000000000000
c285: dq 0xC01E000000000000, 0x47EFFFFFF0000000
c286: dq 0x3FB999999999999A, 0x401E000000000000
c287: dq 0x4080AF8D8CF7397E, 0xC0812924FDF368E1
c288: dq 0x41E0000000000000, 0xFFF0000000000123
c289: dq 0xFFF8000000000000, 0x40696F7EDE82B7C8
c290: dq 0x408C596E6A04C8E4, 0x40808382A32F9F98
c291: dq 0xFFF8000000000000, 0x47EFFFFFF0000000
c292: dq 0x7FF8000012345678, 0xC004000000000000
c293: dq 0x41F0000000000000, 0x3FF0000000000000
c294: dq 0xC004000000000000, 0xC1E0000000100000
c295: dq 0xFFF0000000000123, 0x40611B8A24806680
c296: dq 0x4340000000000000, 0xC07A5C8E720BC7F8
c297: dq 0x406D63E132AB1030, 0xC0801B546DE61D7E
c298: dq 0xC05E29C7E61EA8C0, 0x3FE0000000000000
c299: dq 0x41DFFFFFFFE00000, 0x1
c300: dq 0xFF800000C43E219B, 0xBF8000003EFFFFFF
c301: dq 0x40F000004226B1D7, 0xCF000000C4430360
c302: dq 0x4020000040200000, 0x7FFFFF444BEAFC
c303: dq 0x445BE36743E5D1B7, 0x6CE3EE5F000000
c304: dq 0x47F1206580000000, 0x4F8000007F7FC99E
c305: dq 0xC4404ECCDF000000, 0xBF000000D01502F9
c306: dq 0x3DCCCCCD7FC00000, 0xD01502F9FF800000
c307: dq 0x3FC00000C3CED11E, 0xD01502F980000001
c308: dq 0xC0F0000044163406, 0xC4070A9F80000001
c309: dq 0x5F0000003EFFFFFF, 0x3FC0000080000000
c310: dq 0x40F00000DF000000, 0x40200000C2D4707F
c311: dq 0x7F7FC99EC42092E3, 0xCF00000040F00000
c312: dq 0x47F12065443E1684, 0x6CE3EE40200000
c313: dq 0x800000441FDBF1, 0x7F7FC99EBF000000
c314: dq 0x4415F955436E3293, 0x17FC00000
c315: dq 0x438B54F4D01502F9, 0x7F7FFFFF80000000
c316: dq 0x7FA0000100800000, 0x800000007FC00000
c317: dq 0x43D2CBB747F12065, 0x7FA00001BF800000
c318: dq 0x7FC12345CF000000, 0x40F00000441A83D8
c319: dq 0xC02000007F7FFFFF, 0xC0F00000D01502F9
c320: dq 0x40F00000C0200000, 0x4380A66FDF000000
c321: dq 0xCF000000DF000000, 0x17FC12345
c322: dq 0x40F000007F800000, 0x17FC00000
c323: dq 0x40400000BF000000, 0x7F7FFFFF7FC00000
c324: dq 0x7FFFFF7FC00000, 0x6CE3EE441DC559
c325: dq 0x800000DF000000, 0x800000017FA00001
c326: dq 0x4F00000040C9570C, 0x442358F45F000000
c327: dq 0x4F0000004B800000, 0x7FA000013EFFFFFF
c328: dq 0x3F0000004459D1A9, 0x4F80000000000001
c329: dq 0x40F0000040400000, 0xC46720662EDBE6FF
c330: dq 0x40779F419E8C4AC8, 0xFFFFFFFFFFFFF
c331: dq 0x4077567570F87AE0, 0x3FE0000000000000
c332: dq 0x47EFFFFFF0000000, 0x4202A05F20000000
c333: dq 0x401E000000000000, 0x4004000000000000
c334: dq 0x7FF8000012345678, 0x7FF8000000000000
c335: dq 0x41F0000000000000, 0x4202A05F20000000
c336: dq 0xC202A05F20000000, 0xC082A2BC672FC6BC
c337: dq 0x43E158E460913D00, 0xC202A05F20000000
c338: dq 0x7FF4000000000001, 0x3FB999999999999A
c339: dq 0xC01E000000000000, 0x730D67819E8D2
c340: dq 0x7FEFFFFFFFFFFFFF, 0xC3E0000000000000
c341: dq 0x43E0000000000000, 0x0
c342: dq 0x7FEFFFFFFFFFFFFF, 0x4034E9D2A4960640
c343: dq 0xC202A05F20000000, 0x4202A05F20000000
c344: dq 0x730D67819E8D2, 0xC07D9CD40258CE94
c345: dq 0xBFF0000000000000, 0xC062299FB7E52F10
c346: dq 0xC01E000000000000, 0x7FF4000000000001
c347: dq 0xC1E0000000100000, 0x7FF0000000000000
c348: dq 0xFFF0000000000123, 0x3FF8000000000000
c349: dq 0x4202A05F20000000, 0x40FE240C9FBE76C9
c350: dq 0x10000000000000, 0x7FEE42D130773B76
c351: dq 0x3FF0000000000000, 0x41DFFFFFFFC00000
c352: dq 0x730D67819E8D2, 0x41E0000000000000
c353: dq 0x41DFFFFFFFE00000, 0x7FF8000012345678
c354: dq 0xC08A2CA9203B6D5E, 0xC06EB2B01D5166BC
c355: dq 0x7FF0000000000000, 0x41DFFFFFFFC00000
c356: dq 0x40820F03DA80B602, 0x3FE0000000000000
c357: dq 0x43E0000000000000, 0x1
c358: dq 0x4004000000000000, 0x41F0000000000000
c359: dq 0x40FE240C9FBE76C9, 0x0
c360: dq 0xC4374F1B3FC00000, 0x4B800000DF000000
c361: dq 0x440925897FC12345, 0x4B800000FF800123
c362: dq 0x7F8000003DCCCCCD, 0x7FC1234500800000
c363: dq 0x3F000000C4009C95, 0x501502F9FF800123
c364: dq 0x47F120654B800000, 0x8000000000000000
c365: dq 0x4020000000000001, 0x6CE3EE42DE17DC
c366: dq 0xFF800000C3C38D4C, 0x2EDBE6FFFF800123
c367: dq 0x444A19A3DF000000, 0x2EDBE6FF4B800000
c368: dq 0x8000002EDBE6FF, 0x4224E1A600000000
c369: dq 0x3FC00000C0F00000, 0x4B80000043E5B4F7
c370: dq 0x2EDBE6FF5F000000, 0x47F12065FF800123
c371: dq 0x14EFFFFFF, 0x44598426C2DCA436
c372: dq 0x80000000FF800123, 0x7F7FC99E00800000
c373: dq 0x4F8000007F7FC99E, 0x7FC12345FF800123
c374: dq 0x4B8000007FC00000, 0x5F0000007F7FFFFF
c375: dq 0x40F00000BF000000, 0x5F000000C460965F
c376: dq 0xC45033DBC22209C1, 0x4B800000
c377: dq 0x800000007FC12345, 0x17FA00001
c378: dq 0x501502F93EFFFFFF, 0xDF0000004425BBD0
c379: dq 0x80000001, 0x7F7FFFFF40200000
c380: dq 0x3DCCCCCD2EDBE6FF, 0x3DCCCCCD40400000
c381: dq 0x3F800000C400E51A, 0x44022286C0200000
c382: dq 0x4020000040200000, 0x43E817504EFFFFFF
c383: dq 0x4F80000040400000, 0x1BF000000
c384: dq 0x7FC123454F800000, 0x3DCCCCCD501502F9
c385: dq 0xC0F000007FC00000, 0x4EFFFFFF47F12065
c386: dq 0xBF00000080000001, 0x4020000040200000
c387: dq 0x3F8000004F800000, 0x3FC000007F7FC99E
c388: dq 0xC02000004EFFFFFF, 0x2EDBE6FFC1DFA2AD
c389: dq 0xFF800123DF000000, 0x402000003F000000
c390: dq 0x3FDFFFFFFFFFFFFF, 0xC0889B79E78CCFF4
c391: dq 0x41F0000000000000, 0xC07EBEAC1EDAF7F8
c392: dq 0x3FE0000000000000, 0xC07B3A6C0455FC00
c393: dq 0xC04E586171F82640, 0x3FF8000000000000
c394: dq 0xC01E000000000000, 0x3FDFFFFFFFFFFFFF
c395: dq 0x3FDFFFFFFFFFFFFF, 0x3FF8000000000000
c396: dq 0x3FB999999999999A, 0x1
c397: dq 0xC004000000000000, 0x41F0000000000000
c398: dq 0x366244CE242C5561, 0x7FF8000000000000
c399: dq 0x3FF8000000000000, 0x41E0000000000000
c400: dq 0x408DAB20AF246A38, 0xC06C577A7E60893C
c401: dq 0x0, 0xFFF0000000000123
c402: dq 0x3FDFFFFFFFFFFFFF, 0xC01E000000000000
c403: dq 0x41DFFFFFFFC00000, 0x7FF0000000000000
c404: dq 0x7FF8000000000000, 0x4202A05F20000000
c405: dq 0x407F5AD0A962F6E0, 0x401E000000000000
c406: dq 0xC1E0000000100000, 0xC080F199615F55F4
c407: dq 0x7FF8000012345678, 0xC202A05F20000000
c408: dq 0x4340000000000000, 0x407050D39FB503DC
c409: dq 0x41E0000000000000, 0x7FF8000012345678
c410: dq 0x43E0000000000000, 0x3FE0000000000000
c411: dq 0xFFFFFFFFFFFFF, 0x730D67819E8D2
c412: dq 0x4077F559C44D2128, 0xC3E0000000000000
c413: dq 0x730D67819E8D2, 0x3DDB7CDFD9D7BDBB
c414: dq 0x43E158E460913D00, 0x408BEEB70C0F55DC
c415: dq 0xFFF8000000000000, 0x4060A73E7978BFC8
c416: dq 0x7FEE42D130773B76, 0xC202A05F20000000
c417: dq 0x41DFFFFFFFE00000, 0xFFF0000000000123
c418: dq 0xC1E0000000000000, 0x7FF0000000000000
c419: dq 0x3FDFFFFFFFFFFFFF, 0x10000000000000
c420: dq 0x4409FB7440200000, 0xBF000000CF000000
c421: dq 0x40F0000043C5F1D8, 0xCF0000007FC12345
c422: dq 0x100800000, 0xBF000000C448780C
c423: dq 0x7FC123457FA00001, 0xBF800000C0044869
c424: dq 0x4F8000004F800000, 0x7F7FFFFF40200000
c425: dq 0x7F7FFFFFC42F041A, 0x2EDBE6FF44482584
c426: dq 0x2EDBE6FF, 0x7F7FC99E4B800000
c427: dq 0x80000001007FFFFF, 0x3EFFFFFFBF800000
c428: dq 0x3F8000007F7FC99E, 0x7F800000BDF194CF
c429: dq 0x40F000003DCCCCCD, 0x4F0000003DCCCCCD
c430: dq 0x3EFFFFFF43FAFDB8, 0x501502F97F7FC99E
c431: dq 0xD01502F944502BEC, 0x7F7FFFFF47F12065
c432: dq 0x42D22A5E40F00000, 0x800000013F800000
c433: dq 0x3F00000000000000, 0xC02000005F000000
c434: dq 0x7FFFFFC417DF81, 0x4F8000003F000000
c435: dq 0x7F800000C3AC2D2A, 0xD01502F9C3301628
c436: dq 0xC44D3C7BC42186C0, 0xC3E468B44428324B
c437: dq 0xC31817BB7F7FFFFF, 0x431A41CA7FA00001
c438: dq 0x7FC12345DF000000, 0x143974A84
c439: dq 0x501502F9C4510A56, 0x7FC1234540400000
c440: dq 0x4446EA6800800000, 0x4B80000040200000
c441: dq 0x4B80000000800000, 0x80000001FF800123
c442: dq 0x43AE37D600800000, 0xC0200000C12CCB1A
c443: dq 0x7F8000003EFFFFFF, 0x4EFFFFFF3F800000
c444: dq 0x7FA0000140400000, 0x7F7FC99E7F7FC99E
c445: dq 0x7FA000015F000000, 0x3FC0000000000001
c446: dq 0x7FC0000040200000, 0xC020000044432FA8
c447: dq 0x402000004B800000, 0x2EDBE6FF4F800000
c448: dq 0x3F00000080000000, 0xC3BE17377FA00001
c449: dq 0x3EFFFFFF006CE3EE, 0x7FC00000431C21E5
c450: dq 0xC08D9693B54ED6B9, 0x4076E43FF167CFD0
c451: dq 0xC082E7B9CFF15072, 0x40FE240C9FBE76C9
c452: dq 0x41DFFFFFFFC00000, 0x4008000000000000
c453: dq 0x7FF8000012345678, 0xFFF8000000000000
c454: dq 0x4086ED4BC2640902, 0x408B6C7D8B0695BA
c455: dq 0xFFF0000000000123, 0x3FE0000000000000
c456: dq 0x41E0000000000000, 0x47EFFFFFF0000000
c457: dq 0x7FEE42D130773B76, 0xBFF0000000000000
c458: dq 0xC3E0000000000000, 0xC0845FE26678AC51
c459: dq 0xC202A05F20000000, 0x41DFFFFFFFC00000
c460: dq 0x3FB999999999999A, 0xBFF0000000000000
c461: dq 0xC0710BC201E4EF98, 0x4008000000000000
c462: dq 0x4340000000000000, 0x4078329900ACC3D8
c463: dq 0x3FF0000000000000, 0xC3E0000000000000
c464: dq 0x41E0000000000000, 0x407A467E28BB9658
c465: dq 0x1, 0x41DFFFFFFFE00000
c466: dq 0x43E158E460913D00, 0xC202A05F20000000
c467: dq 0xC1E0000000100000, 0x47EFFFFFF0000000
c468: dq 0x43E158E460913D00, 0x406DC32C1B6DA5B8
c469: dq 0xBFF0000000000000, 0x406FFFFBB2CF0DB8
c470: dq 0x3FB999999999999A, 0xC3E0000000000000
c471: dq 0xBFE0000000000000, 0xC004000000000000
c472: dq 0x10000000000000, 0x3FF8000000000000
c473: dq 0xFFF8000000000000, 0x4202A05F20000000
c474: dq 0x41F0000000000000, 0xC01E000000000000
c475: dq 0xC01E000000000000, 0x3FE0000000000000
c476: dq 0x43E0000000000000, 0x3DDB7CDFD9D7BDBB
c477: dq 0x40878F64388B7748, 0xFFF8000000000000
c478: dq 0x3FE0000000000000, 0xC078B40A7CDA0454
c479: dq 0x4340000000000000, 0x0
c480: dq 0x3F800000C3E6B344, 0x402000007FC00000
c481: dq 0x7F8000007F800000, 0x6CE3EEC4692ED0
c482: dq 0x4EFFFFFF, 0x7FC123453DCCCCCD
c483: dq 0xC394B156443578E7, 0xBF0000007FC12345
c484: dq 0xCF000000C35044B8, 0xC3813DA27FC00000
c485: dq 0x6CE3EEFFC00000, 0x47F12065
c486: dq 0x442620F740400000, 0xBF000000DF000000
c487: dq 0x40F00000FF800123, 0x3DCCCCCD3FC00000
c488: dq 0xBF0000004EFFFFFF, 0xFFC0000080000000
c489: dq 0xCF0000005F000000, 0x140F00000
c490: dq 0xC4646855006CE3EE, 0xC466A611D01502F9
c491: dq 0x7F7FC99E3F800000, 0x4EFFFFFFDF000000
c492: dq 0x40400000006CE3EE, 0x5F00000041CA5683
c493: dq 0x2EDBE6FF44746B01, 0x47F12065FF800123
c494: dq 0x7F7FFFFF80000000, 0xC17CF0F47FA00001
c495: dq 0xFF8001235F000000, 0x4EFFFFFF7F7FC99E
c496: dq 0x2EDBE6FF446FE8EE, 0x4F00000040400000
c497: dq 0x43E4D4977F7FC99E, 0xCF000000CF000000
c498: dq 0x40400000007FFFFF, 0x800000C0200000
c499: dq 0x4B80000040F00000, 0xC0F00000FF800000
c500: dq 0xBF66EE9FDF000000, 0xC42E8C4E00000000
c501: dq 0x3FC00000C0F00000, 0x3DCCCCCD7FC12345
c502: dq 0x2EDBE6FFBF000000, 0x4433F377C0200000
c503: dq 0x8000007FC00000, 0xC34BEEF0C36842B6
c504: dq 0x4F0000003F800000, 0xC445BECE4F000000
c505: dq 0xFF80012340200000, 0xC0F00000DF000000
c506: dq 0x1FF800000, 0xFF80000000000000
c507: dq 0x2EDBE6FF7F800000, 0xBF0000004384DF3F
c508: dq 0xBF80000080000000, 0x6CE3EE4F800000
c509: dq 0x444D065600000001, 0x40F0000000800000
c510: dq 0xFFF0000000000123, 0x3FDFFFFFFFFFFFFF
c511: dq 0x3FF0000000000000, 0x4340000000000000
c512: dq 0x10000000000000, 0xC08A689E35BA2B56
c513: dq 0x7FEE42D130773B76, 0x404F3D2152D2BC80
c514: dq 0x41E0000000000000, 0xC1E0000000100000
c515: dq 0xC1E0000000000000, 0xC076AA8EB8135EDE
c516: dq 0xC202A05F20000000, 0xBFF0000000000000
c517: dq 0xFFF0000000000123, 0xC1E0000000000000
c518: dq 0xC004000000000000, 0x41E0000000000000
c519: dq 0x40790F84BF59A9E8, 0xC07321256EE25C3C
c520: dq 0x0, 0x3FB999999999999A
c521: dq 0x7FF4000000000001, 0x41E0000000000000
c522: dq 0x4004000000000000, 0xC066CF3F8AA8A23C
c523: dq 0x43E158E460913D00, 0x43E0000000000000
c524: dq 0x4202A05F20000000, 0x3FF0000000000000
c525: dq 0x7FF8000012345678, 0x43E0000000000000
c526: dq 0x730D67819E8D2, 0xBFE0000000000000
c527: dq 0x43E158E460913D00, 0x4077481C8FC0E968
c528: dq 0xC01E000000000000, 0x3FDFFFFFFFFFFFFF
c529: dq 0x1, 0x401E000000000000
c530: dq 0xC075328325EE0A2C, 0xC202A05F20000000
c531: dq 0x730D67819E8D2, 0x408AA418377FD0D2
c532: dq 0x41DFFFFFFFC00000, 0x401E000000000000
c533: dq 0x4008000000000000, 0x1
c534: dq 0x43E158E460913D00, 0x3FDFFFFFFFFFFFFF
c535: dq 0x3FDFFFFFFFFFFFFF, 0xC01E000000000000
c536: dq 0x407920C09C717D8C, 0x47EFFFFFF0000000
c537: dq 0xC076DC8FFF517C46, 0xBFF0000000000000
c538: dq 0xC1E0000000000000, 0xC202A05F20000000
c539: dq 0xC1E0000000100000, 0xC069F86E6C7294BC
c540: dq 0xCF00000040400000, 0x3EFFFFFF7FC12345
c541: dq 0x4EFFFFFFC31A4CC5, 0x43C1F3A93DCCCCCD
c542: dq 0x4F800000C0F00000, 0xBF0000004F000000
c543: dq 0x443F5196C304A19E, 0x40200000C0200000
c544: dq 0x40F00000BF000000, 0x3DCCCCCD442E1B28
c545: dq 0xC4467E724F000000, 0x404000007F800000
c546: dq 0x3DCCCCCD4EFFFFFF, 0x44014CD67F7FFFFF
c547: dq 0x4F00000043CD27C5, 0x800000004F800000
c548: dq 0xC4289FE9BF000000, 0x2EDBE6FFBF000000
c549: dq 0xC464642A7F800000, 0x7FC12345DF000000
c550: dq 0x3F00000044167EA7, 0x4F000000DF000000
c551: dq 0xD01502F9007FFFFF, 0xC4225E6C00000001
c552: dq 0x40F000002EDBE6FF, 0x5F0000007FC00000
c553: dq 0x44103FA4441BA9EF, 0x4F80000040200000
c554: dq 0x7FFFFF501502F9, 0xC3A78D8947F12065
c555: dq 0xC45D55FDCF000000, 0x1501502F9
c556: dq 0x447704117F7FFFFF, 0x43B8D827
c557: dq 0xFF8001234F800000, 0x501502F940400000
c558: dq 0x5F0000002EDBE6FF, 0x44214A614EFFFFFF
c559: dq 0x8000000000000000, 0x40F00000C41B3D29
c560: dq 0x42F553CDC44F66C0, 0x7F7FFFFFBF800000
c561: dq 0x7FA00001C45C27BF, 0x42462988006CE3EE
c562: dq 0xDF00000047F12065, 0x3F00000080000000
c563: dq 0x800000013F800000, 0xC3214AB8FF800123
c564: dq 0xBF00000080000001, 0xDF00000040200000
c565: dq 0x6CE3EEBF800000, 0x40F00000D01502F9
c566: dq 0xC4680C7CFF800123, 0xC0F0000000800000
c567: dq 0x7FA000014F000000, 0x8000000144174F8D
c568: dq 0x8000000080000000, 0xCF0000004EFFFFFF
c569: dq 0xFF8000004F800000, 0x7F7FC99EC3D9B55D
c570: dq 0x41E0000000000000, 0x40747F44A9274D3C
c571: dq 0xC1E0000000000000, 0x7FF4000000000001
c572: dq 0x7FF8000012345678, 0xBFE0000000000000
c573: dq 0x3FF8000000000000, 0xC0875EF217A8485B
c574: dq 0x7FF0000000000000, 0xC068D6E84EC6F234
c575: dq 0xC08401F931681964, 0x0
c576: dq 0x4071CFFFF4826AA8, 0x4004000000000000
c577: dq 0x43E0000000000000, 0xC06358D528E29520
c578: dq 0x0, 0x401E000000000000
c579: dq 0xC01E000000000000, 0xC01E000000000000
c580: dq 0x40767CF4F22D7A6C, 0xC07ED48553931DDA
c581: dq 0x41F0000000000000, 0x41E0000000000000
c582: dq 0x7FF8000000000000, 0x47EFFFFFF0000000
c583: dq 0x7FEFFFFFFFFFFFFF, 0x0
c584: dq 0xFFF8000000000000, 0x3FF8000000000000
c585: dq 0xC202A05F20000000, 0x8000000000000000
c586: dq 0x407AA172510951C4, 0xC1E0000000000000
c587: dq 0xC046A2C782E82860, 0x3FF8000000000000
c588: dq 0x43E0000000000000, 0xC202A05F20000000
c589: dq 0xC07D7704692EE464, 0x41DFFFFFFFE00000
c590: dq 0x7FEFFFFFFFFFFFFF, 0x7FF8000000000000
c591: dq 0x4089DE142DE27DEA, 0xFFF8000000000000
c592: dq 0x41E0000000000000, 0x10000000000000
c593: dq 0x10000000000000, 0x401E000000000000
c594: dq 0x43E0000000000000, 0x3FDFFFFFFFFFFFFF
c595: dq 0x1, 0x10000000000000
c596: dq 0x7FF0000000000000, 0x7FEFFFFFFFFFFFFF
c597: dq 0x43E0000000000000, 0x43E158E460913D00
c598: dq 0xC08D059F0DDF5192, 0xC004000000000000
c599: dq 0x7FF0000000000000, 0x41E0000000000000
c600: dq 0xFFC00000C0F00000, 0xC456801F7FC00000
c601: dq 0x8000000100800000, 0xC020000040F00000
c602: dq 0xC3B4E1953F800000, 0x402000003F800000
c603: dq 0x800000007FA00001, 0xBF800000C41D45E7
c604: dq 0x4420ABBE3F800000, 0x80000001C0200000
c605: dq 0x4F80000000000001, 0xC23B8972BF000000
c606: dq 0x7FC00000BF800000, 0xDF0000007F7FC99E
c607: dq 0xBF00000000000000, 0xC439CB9FCF000000
c608: dq 0x7F800000501502F9, 0xFF80000042FB5659
c609: dq 0x800000007FA00001, 0xC0F0000040400000
c610: dq 0x800000413155C8, 0x80000000C3252BB8
c611: dq 0x7FC00000C3FA110D, 0xFF80012340400000
c612: dq 0x3EFFFFFF4B800000, 0x501502F97F800000
c613: dq 0x80000000C0F00000, 0xC02000005F000000
c614: dq 0xFF80000080000000, 0xC450FDAA47F12065
c615: dq 0x501502F9BF000000, 0x800000015F000000
c616: dq 0x6CE3EE501502F9, 0xBF8000007FC12345
c617: dq 0x800000DF000000, 0x3EFFFFFF007FFFFF
c618: dq 0xC430F56EFFC00000, 0xD01502F9006CE3EE
c619: dq 0x800000DF000000, 0x501502F9BF000000
c620: dq 0xFFC000003FC00000, 0x7F7FC99E00000000
c621: dq 0xBF00000080000001, 0x4425C9D2FFC00000
c622: dq 0x3FC00000446CBC11, 0xFFC00000FF800123
c623: dq 0x7FFFFFC44CA2FE, 0x444358D04B800000
c624: dq 0xBF000000DF000000, 0x4F00000043E18A30
c625: dq 0x7F7FFFFF7FC00000, 0x439E5D9A4F800000
c626: dq 0x8000000147F12065, 0x7FC12345C0F00000
c627: dq 0xBF000000501502F9, 0xC42916CD7F7FC99E
c628: dq 0x17F7FFFFF, 0x40200000DF000000
c629: dq 0x40F000003EFFFFFF, 0x501502F9BF800000
c630: dq 0x4004000000000000, 0xFFF0000000000123
c631: dq 0xC1E0000000000000, 0xFFF8000000000000
c632: dq 0x7FEE42D130773B76, 0x4202A05F20000000
c633: dq 0x730D67819E8D2, 0xBFE0000000000000
c634: dq 0xC087BA5AB7FAE2F7, 0xBFF0000000000000
c635: dq 0xC0770AA9245E9682, 0x4008000000000000
c636: dq 0xC08D8E9EBE90DEC6, 0x41F0000000000000
c637: dq 0xC089A3381A53AFEA, 0x7FEFFFFFFFFFFFFF
c638: dq 0x8000000000000000, 0x4008000000000000
c639: dq 0x0, 0x8000000000000000
c640: dq 0x3FE0000000000000, 0x7FEFFFFFFFFFFFFF
c641: dq 0x4340000000000000, 0x4340000000000000
c642: dq 0x3FF8000000000000, 0x7FF8000000000000
c643: dq 0x41DFFFFFFFC00000, 0x47EFFFFFF0000000
c644: dq 0x7FEE42D130773B76, 0xBFF0000000000000
c645: dq 0xC3E0000000000000, 0x3FB999999999999A
c646: dq 0xFFFFFFFFFFFFF, 0xC202A05F20000000
c647: dq 0x8000000000000000, 0xFFF0000000000000
c648: dq 0x407B9B0D671095C4, 0x4083EAC88817ADC4
c649: dq 0x4004000000000000, 0x366244CE242C5561
c650: dq 0x7FEFFFFFFFFFFFFF, 0x4084A75DBF25FD82
c651: dq 0x4087BA7609932384, 0xC1E0000000100000
c652: dq 0x43E0000000000000, 0xC004000000000000
c653: dq 0x41DFFFFFFFE00000, 0x41F0000000000000
c654: dq 0x40727E769E1FB634, 0xBFF0000000000000
c655: dq 0xC054328CD8564570, 0x401E000000000000
c656: dq 0x43E158E460913D00, 0x7FEE42D130773B76
c657: dq 0x7FEE42D130773B76, 0x10000000000000
c658: dq 0xC07279F47950E3DE, 0x3FF0000000000000
c659: dq 0xC08DDCBD6A20D9B9, 0xC0677B306C814440
c660: dq 0xC3267ECC2EDBE6FF, 0xD01502F97FA00001
c661: dq 0x7FC00000C0F00000, 0xC31F5B37501502F9
c662: dq 0x404000007F7FFFFF, 0x140F00000
c663: dq 0xC42E398A7F800000, 0x7FA00001C1C0E28B
c664: dq 0xC3300230007FFFFF, 0x441F2470C2E4EDAA
c665: dq 0xBF800000FF800000, 0xFF80000080000000
c666: dq 0x40F00000C0F00000, 0xC46B943780000000
c667: dq 0x44718A04, 0x3EFFFFFF80000001
c668: dq 0x4040000000000001, 0xBF0000007F7FFFFF
c669: dq 0xC02000004F000000, 0x7FFFFF40200000
c670: dq 0xFF80012340200000, 0xFFC0000000000000
c671: dq 0x4B8000007F7FC99E, 0xFF8001237FA00001
c672: dq 0x443F5F7FFF800000, 0x7FA00001D01502F9
c673: dq 0x3DCCCCCDC23EC769, 0x40200000C0200000
c674: dq 0x501502F940400000, 0xC3D66CD3443573DC
c675: dq 0xBF0000007F800000, 0xFF8001233F800000
c676: dq 0xCF000000443CB816, 0x5F00000044174347
c677: dq 0xBF00000040200000, 0x44209E86FF800123
c678: dq 0x47F12065BF800000, 0x7FC123457F7FFFFF
c679: dq 0xCF000000BF800000, 0xC439B69C5F000000
c680: dq 0xC3DD15DD5F000000, 0x7F800000C3194540
c681: dq 0xBF80000043C44B0E, 0x8000004EFFFFFF
c682: dq 0xFF80012380000000, 0x5F0000007FA00001
c683: dq 0x7F7FFFFF00800000, 0xC020000080000000
c684: dq 0x80000001C0200000, 0xC45FF5B340F00000
c685: dq 0x4B800000C3F5577F, 0x43F5BF503F000000
c686: dq 0xC0F0000080000001, 0x6CE3EE501502F9
c687: dq 0xC412D179DF000000, 0x7FA00001C46CDE25
c688: dq 0xBF000000C3959084, 0x3DCCCCCD00800000
c689: dq 0xC35591BEBF800000, 0x44678FDCFF800123
c690: dq 0xC07A0D871A089F98, 0x40714F42153A6AD4
c691: dq 0x43E158E460913D00, 0xC004000000000000
c692: dq 0x4340000000000000, 0x8000000000000000
c693: dq 0x0, 0x3DDB7CDFD9D7BDBB
c694: dq 0xC1E0000000100000, 0xC088EA5E1FDC5E6F
c695: dq 0x0, 0xC08C8D55EE76AEE3
c696: dq 0x7FEE42D130773B76, 0xC202A05F20000000
c697: dq 0xC08B27D579C90BE9, 0x7FF0000000000000
c698: dq 0xFFFFFFFFFFFFF, 0x408986F9F7F52B26
c699: dq 0x7FF0000000000000, 0xBFF0000000000000
c700: dq 0x401E000000000000, 0x3DDB7CDFD9D7BDBB
c701: dq 0x7FEE42D130773B76, 0x3FDFFFFFFFFFFFFF
c702: dq 0x3FE0000000000000, 0x3FE0000000000000
c703: dq 0xBFE0000000000000, 0x401E000000000000
c704: dq 0xC08339FD0D495CA4, 0x1
c705: dq 0x41E0000000000000, 0xC1E0000000100000
c706: dq 0x7FF4000000000001, 0x3FDFFFFFFFFFFFFF
c707: dq 0xC202A05F20000000, 0x7FEE42D130773B76
c708: dq 0x41F0000000000000, 0x3FE0000000000000
c709: dq 0x1, 0x7FF8000000000000
c710: dq 0x0, 0x0
c711: dq 0x7FF4000000000001, 0xC1E0000000000000
c712: dq 0xC086EE00A1A78824, 0xFFF8000000000000
c713: dq 0x3FDFFFFFFFFFFFFF, 0xFFF8000000000000
c714: dq 0x366244CE242C5561, 0x8000000000000000
c715: dq 0xC3E0000000000000, 0xC3E0000000000000
c716: dq 0x3FF0000000000000, 0xC08150969D062D46
c717: dq 0x408872EA7BA9DD76, 0x3FB999999999999A
c718: dq 0xC07C2483A07A2BBA, 0x41F0000000000000
c719: dq 0x3FF0000000000000, 0x7FF8000012345678
c720: dq 0x402000007FA00001, 0x3F00000044766825
c721: dq 0x4F800000501502F9, 0x7F7FC99E3FC00000
c722: dq 0x4EFFFFFFDF000000, 0xC3AE440FC2549F8A
c723: dq 0x80000001FFC00000, 0x800000004B800000
c724: dq 0xFF8000005F000000, 0xC0F0000044376F39
c725: dq 0xDF0000003DCCCCCD, 0x442392EEC3A8B6EF
c726: dq 0xD01502F9501502F9, 0x4F8000003EFFFFFF
c727: dq 0x7FA000017F7FC99E, 0xBF00000000800000
c728: dq 0x7F800000C43E449C, 0x4EFFFFFFBF000000
c729: dq 0x404000007FC00000, 0x501502F943CDCF4D
c730: dq 0x43D44B8C7F7FC99E, 0xC390445D7F800000
c731: dq 0x7FC1234540200000, 0xC0F00000C0F00000
c732: dq 0xBF80000080000000, 0x4334E803C44F6F9F
c733: dq 0x4EFFFFFF3F800000, 0x43B9B17FCF000000
c734: dq 0xC461EACAC42827FD, 0xC0200000BF800000
c735: dq 0x1FF800123, 0xFF800123BF000000
c736: dq 0x5F000000C45D9ACC, 0xCF0000007F7FC99E
c737: dq 0x2EDBE6FF3F800000, 0x47F1206547F12065
c738: dq 0xCF0000004F800000, 0x7FC12345C44C8977
c739: dq 0x6CE3EEC3FA9724, 0x4F800000FF800123
c740: dq 0xCF000000006CE3EE, 0x4F800000006CE3EE
c741: dq 0x3F800000501502F9, 0x7FFFFF443192EC
c742: dq 0xBF800000FF800123, 0xD01502F97F7FFFFF
c743: dq 0xC39718DA006CE3EE, 0xBF000000BF800000
c744: dq 0xC444E0C600000001, 0x2EDBE6FF7F800000
c745: dq 0x43C8CFF03F800000, 0x7FC123453FC00000
c746: dq 0x7F7FC99EC0F00000, 0x3EFFFFFF44011765
c747: dq 0xC396DF7C00000001, 0x7FA0000180000000
c748: dq 0x4F000000CF000000, 0x4B800000006CE3EE
c749: dq 0x7FC12345006CE3EE, 0x40F00000BF000000
c750: dq 0x8000000000000000, 0x3FF8000000000000
c751: dq 0xFFF0000000000123, 0x3DDB7CDFD9D7BDBB
c752: dq 0xBFE0000000000000, 0x366244CE242C5561
c753: dq 0x407697C2DFB57448, 0x4202A05F20000000
c754: dq 0xC08B695A47209543, 0x406B26F814C6EC78
c755: dq 0xC1E0000000000000, 0xC3E0000000000000
c756: dq 0x407C6FA452A5FD48, 0xFFFFFFFFFFFFF
c757: dq 0x40775D4422AEA210, 0xC1E0000000000000
c758: dq 0x41DFFFFFFFE00000, 0x4340000000000000
c759: dq 0x4008000000000000, 0x3FE0000000000000
c760: dq 0x1, 0x4004000000000000
c761: dq 0x7FF8000012345678, 0xC202A05F20000000
c762: dq 0x3DDB7CDFD9D7BDBB, 0xC07567BEC76291E4
c763: dq 0x4087902A5DC9926A, 0xFFF8000000000000
c764: dq 0xC3E0000000000000, 0x408297223BD4121E
c765: dq 0x41E0000000000000, 0xC05EB47767FA3278
c766: dq 0x3FF8000000000000, 0xC202A05F20000000
c767: dq 0xFFFFFFFFFFFFF, 0x8000000000000000
c768: dq 0x3FDFFFFFFFFFFFFF, 0x3FF0000000000000
c769: dq 0x4032F1FA762950E0, 0xFFF8000000000000
c770: dq 0xC084B2A509DF0564, 0x41DFFFFFFFE00000
c771: dq 0x3FF8000000000000, 0x3FDFFFFFFFFFFFFF
c772: dq 0x10000000000000, 0x4008000000000000
c773: dq 0x41DFFFFFFFE00000, 0x407E9535BE51BFC8
c774: dq 0xC0688B6E269FAB44, 0x7FEE42D130773B76
c775: dq 0xC01E000000000000, 0x41DFFFFFFFE00000
c776: dq 0xFFFFFFFFFFFFF, 0x3FB999999999999A
c777: dq 0x7FF0000000000000, 0x10000000000000
c778: dq 0x43E158E460913D00, 0x7FF4000000000001
c779: dq 0x41DFFFFFFFE00000, 0xC0656869EE3866C0
c780: dq 0xC304E4754314C1C4, 0x1C45020CE
c781: dq 0xBF000000C372C80A, 0xC479D9622EDBE6FF
c782: dq 0x80000043C45673, 0x7FA00001006CE3EE
c783: dq 0xBF0000007F7FFFFF, 0x4B8000004342CAF9
c784: dq 0x4F000000BF000000, 0x2EDBE6FF4B800000
c785: dq 0x441B1AADCF000000, 0xC40509E1
c786: dq 0x402000004456F028, 0xFF8001235F000000
c787: dq 0xC46822F3C0200000, 0xC2F7A5043FC00000
c788: dq 0xCF0000007FA00001, 0x80000001FF800000
c789: dq 0x7F7FC99E00000001, 0x7FC12345006CE3EE
c790: dq 0x7F7FFFFF7FA00001, 0xC0F000003FC00000
c791: dq 0x3EFFFFFFD01502F9, 0x2EDBE6FF40400000
c792: dq 0xC42B720AC0F00000, 0xFF8000003DCCCCCD
c793: dq 0x800000BF000000, 0xD01502F900800000
c794: dq 0xD01502F93FC00000, 0x7F7FC99EC0200000
c795: dq 0xC0F0000044288A6C, 0x47F120653F000000
c796: dq 0x5F0000004F800000, 0xFFC000005F000000
c797: dq 0x3EFFFFFF4F000000, 0x43BC6EAF441AD429
c798: dq 0x800000014EFFFFFF, 0x6CE3EE
c799: dq 0x2EDBE6FF4EFFFFFF, 0x3EFFFFFFC3C900BB
c800: dq 0x47F12065C4464ECE, 0x3FC000003F000000
c801: dq 0xFF8001237F800000, 0xC33752C3C38912CB
c802: dq 0xCF00000040400000, 0x5F0000004B800000
c803: dq 0xDF0000007FC12345, 0xDF000000007FFFFF
c804: dq 0xCF00000042D48C97, 0x47F12065C0200000
c805: dq 0x3EFFFFFF4432DBEB, 0x4EFFFFFFFF800123
c806: dq 0xC440132ED01502F9, 0x144284DB8
c807: dq 0x4455F7B73F000000, 0x4F800000437BF07A
c808: dq 0x3EFFFFFFC29AD9DD, 0x4F00000043DF9D8E
c809: dq 0xFF8001233F000000, 0x3F00000080000001
c810: dq 0xFFF8000000000000, 0xC01E000000000000
c811: dq 0x3FF0000000000000, 0xFFF8000000000000
c812: dq 0x3FF0000000000000, 0x3DDB7CDFD9D7BDBB
c813: dq 0x41F0000000000000, 0xC0854EBC56E4230F
c814: dq 0xC08A98F59D5BB8CA, 0x43E0000000000000
c815: dq 0x4008000000000000, 0xC3E0000000000000
c816: dq 0x1, 0x41DFFFFFFFE00000
c817: dq 0xC1E0000000100000, 0x405289A5E27054D0
c818: dq 0xC3E0000000000000, 0x3FF0000000000000
c819: dq 0x0, 0x4004000000000000
c820: dq 0xFFF8000000000000, 0xC202A05F20000000
c821: dq 0x7FF8000000000000, 0x40FE240C9FBE76C9
c822: dq 0xFFF8000000000000, 0x3FF8000000000000
c823: dq 0x43E0000000000000, 0x41E0000000000000
c824: dq 0x401E000000000000, 0x4008000000000000
c825: dq 0xC004000000000000, 0xC202A05F20000000
c826: dq 0x41DFFFFFFFE00000, 0x3DDB7CDFD9D7BDBB
c827: dq 0x366244CE242C5561, 0xC04E91D2DA6F30F0
c828: dq 0x366244CE242C5561, 0x40FE240C9FBE76C9
c829: dq 0xC3E0000000000000, 0x47EFFFFFF0000000
c830: dq 0xC3E0000000000000, 0x7FEE42D130773B76
c831: dq 0xBFE0000000000000, 0x41DFFFFFFFC00000
c832: dq 0xBFF0000000000000, 0xC08D81B9FBCEB0F2
c833: dq 0x41E0000000000000, 0x41E0000000000000
c834: dq 0x41DFFFFFFFE00000, 0x4340000000000000
c835: dq 0x4008000000000000, 0x8000000000000000
c836: dq 0x4086A60C17FA0726, 0x7FF0000000000000
c837: dq 0xC1E0000000100000, 0x408850B96DDBD360
c838: dq 0x7FF8000000000000, 0xC06D7DBA98B9A548
c839: dq 0x3FE0000000000000, 0x7FF8000012345678
c840: dq 0xF35B7A40407F01FF, 0x810106409A8F4B81
c841: dq 0x140EF70007F2374, 0xFFA0FF013CF6207F
c842: dq 0x47768F796A91CC67, 0x1
c843: dq 0x8000000000010000, 0x10000B4ECC8AA
c844: dq 0x1677F523745F9E66, 0x403946BB3BB9D551
c845: dq 0x1007FFF8001, 0x7A869A000FF7FFF
c846: dq 0xFFFFFFFF, 0x901581734E1B8BDA
c847: dq 0xFFFFAA5106278000, 0x110A800FF8000
c848: dq 0x7FFFFFFFB3D48B49, 0xFFFF2AA990F3
c849: dq 0xD180802901B18040, 0x81EE404086C2AC7F
c850: dq 0x8000000000000000, 0xF1934CE8C40A7B47
c851: dq 0xFF8101807F0D7F90, 0x19C4080021080FF
c852: dq 0x1, 0x1
c853: dq 0x7FFFFFFFFFFFFFFF, 0x96AAB619F2E8DE60
c854: dq 0xFFFFFF00FF0001, 0xFFFF7C154F48FFFF
c855: dq 0x7FDEE980B0FFFA40, 0x8040C86CFF807400
c856: dq 0xA0AA01000001, 0x7FFFFFFF2BC7
c857: dq 0x8000000000000000, 0xFFFFFFFF
c858: dq 0xB7C7FFFFFFFF00FF, 0xFFFFB859188100FF
c859: dq 0xFE9C46A800010000, 0x8000000080000000
c860: dq 0x845EEAE70000FFFF, 0x191AF3C800010000
c861: dq 0x4276E67800010000, 0xFFFFFFFFFFFF
c862: dq 0x1191D9CD640BC343, 0x1000000000000
c863: dq 0x10000, 0x1BADD3FB7
c864: dq 0x441D57FEBF800000, 0xC21AC17C4F000000
c865: dq 0x441D57FEBF800000, 0xC21AC17C4F000000
c866: dq 0x4F000000006CE3EE, 0x7FA00001
c867: dq 0xBF000000FF800000, 0x4B800000C41E229E
c868: dq 0x7F80000080000000, 0x402000004EFFFFFF
c869: dq 0x40400000FF800000, 0xC020000040400000
c870: dq 0x40F000003F000000, 0x4417313F4B800000
c871: dq 0x5F0000003FC00000, 0x800000013F800000
c872: dq 0x4EFFFFFF4B800000, 0xC0200000501502F9
c873: dq 0x3F0000004383ACDE, 0x4F000000437116FE
c874: dq 0xFF80012300800000, 0x4F00000043280BF0
c875: dq 0xC4068A0FFFC00000, 0x4F00000080000000
c876: dq 0xC0F00000501502F9, 0x8000007F7FC99E
c877: dq 0x2EDBE6FF445C3600, 0x4EFFFFFFD01502F9
c878: dq 0xC020000044029955, 0x3DCCCCCD3EFFFFFF
c879: dq 0x7FA000014EFFFFFF, 0xC02000004EFFFFFF
c880: dq 0xBF8000007F7FFFFF, 0xFFC000003EFFFFFF
c881: dq 0xBF8000007F7FFFFF, 0xFFC000003EFFFFFF
c882: dq 0x3DCCCCCD2EDBE6FF, 0x4426D45DC0200000
c883: dq 0x3DCCCCCD2EDBE6FF, 0x4426D45DC0200000
c884: dq 0x4020000000000000, 0xC0F00000C479B5D9
c885: dq 0x445C30913FC00000, 0x446362C5FFC00000
c886: dq 0x4B800000, 0x5F0000007FC00000
c887: dq 0x40F000003F800000, 0x3DCCCCCD3FC00000
c888: dq 0x443320D9BF000000, 0x444725EB
c889: dq 0xC4016158C43BCD7B, 0xC02000007F7FFFFF
c890: dq 0x404000005F000000, 0xC0F000003F800000
c891: dq 0x1FF800000, 0x7F7FFFFF006CE3EE
c892: dq 0xDF000000007FFFFF, 0x6CE3EE00000000
c893: dq 0x446682364F800000, 0x4422AEFFFF800000
c894: dq 0xC0200000BF000000, 0xFF8001233DCCCCCD
c895: dq 0xC0200000BF000000, 0xFF8001233DCCCCCD
c896: dq 0x40F0000040200000, 0x47F120654F000000
c897: dq 0x3F00000040200000, 0xD01502F9CF000000
c898: dq 0x7FC00000BF000000, 0x7F7FFFFF42FAAAE1
c899: dq 0x7FC00000BF000000, 0x7F7FFFFF42FAAAE1
c900: dq 0x43F68501D01502F9, 0x42FD0E74BF000000
c901: dq 0xC0F00000C2DCE7F7, 0xC0F000007FC00000
c902: dq 0x1CF000000, 0xC415A09E2EDBE6FF
c903: dq 0x4EFFFFFFC40156B0, 0xC02000004EFFFFFF
c904: dq 0x47F12065FF800000, 0x7F80000000800000
c905: dq 0x47F12065FF800000, 0x7F80000000800000
c906: dq 0x436C658200000001, 0x4F000000FF800123
c907: dq 0x4EFFFFFF007FFFFF, 0x47F120654B800000
c908: dq 0x7F7FC99E4F000000, 0x44410CC644194148
c909: dq 0x4F0000007F7FFFFF, 0x40F0000043DE09E1
c910: dq 0x5F000000C0F00000, 0xFF8001234EFFFFFF
c911: dq 0x445408E600000001, 0x4F00000040400000
c912: dq 0xFFF8000000000000, 0xC1E0000000000000
c913: dq 0x7FEFFFFFFFFFFFFF, 0x43E158E460913D00
c914: dq 0xC01E000000000000, 0x4088D1D631D6D678
c915: dq 0xBFE0000000000000, 0x7FF8000012345678
c916: dq 0xFFF8000000000000, 0xFFFFFFFFFFFFF
c917: dq 0xBFE0000000000000, 0x401E000000000000
c918: dq 0x4008000000000000, 0x4004000000000000
c919: dq 0x4340000000000000, 0xC1E0000000000000
c920: dq 0x366244CE242C5561, 0x4071000A669F4E80
c921: dq 0x3FDFFFFFFFFFFFFF, 0x730D67819E8D2
c922: dq 0x366244CE242C5561, 0xC082A805D4CC6674
c923: dq 0x4086FC33BD78F94C, 0x8000000000000000
c924: dq 0x40FE240C9FBE76C9, 0xC079EF482E8BFE5E
c925: dq 0x40FE240C9FBE76C9, 0xC079EF482E8BFE5E
c926: dq 0x4004000000000000, 0x41DFFFFFFFC00000
c927: dq 0x4004000000000000, 0x41DFFFFFFFC00000
c928: dq 0x41DFFFFFFFC00000, 0x4004000000000000
c929: dq 0x366244CE242C5561, 0x3DDB7CDFD9D7BDBB
c930: dq 0xC1E0000000100000, 0xC01E000000000000
c931: dq 0xC1E0000000100000, 0xC01E000000000000
c932: dq 0xC202A05F20000000, 0x3FB999999999999A
c933: dq 0x401E000000000000, 0xFFFFFFFFFFFFF
c934: dq 0x3FB999999999999A, 0x7FF8000012345678
c935: dq 0x1, 0xFFF8000000000000
c936: dq 0x43E0000000000000, 0x4089BE6F15AEA6FA
c937: dq 0xFFF0000000000000, 0x0
c938: dq 0x3FE0000000000000, 0x4084F3DE53D76F64
c939: dq 0x3FE0000000000000, 0x4084F3DE53D76F64
c940: dq 0x0, 0x408411663EB5010E
c941: dq 0x41DFFFFFFFE00000, 0x3FB999999999999A
c942: dq 0xFFF0000000000123, 0xC06B80D507378524
c943: dq 0xC202A05F20000000, 0xC202A05F20000000
c944: dq 0xC3E0000000000000, 0xC202A05F20000000
c945: dq 0x4004000000000000, 0x41DFFFFFFFC00000
c946: dq 0x40870AACCF42BAB8, 0x4202A05F20000000
c947: dq 0x7FEE42D130773B76, 0x4004000000000000
c948: dq 0x3FDFFFFFFFFFFFFF, 0xFFFFFFFFFFFFF
c949: dq 0x408DAF0326D17D00, 0xC034B3E3F5679840
c950: dq 0x408A3CC8FE991E42, 0xC0802BD73628C350
c951: dq 0x408A3CC8FE991E42, 0xC0802BD73628C350
c952: dq 0x47EFFFFFF0000000, 0x3FF8000000000000
c953: dq 0x3FB999999999999A, 0x7FEE42D130773B76
c954: dq 0x43E158E460913D00, 0x3FDFFFFFFFFFFFFF
c955: dq 0x3FB999999999999A, 0xBFE0000000000000
c956: dq 0xFFFFFFFFFFFFF, 0xC0621E6EB61B4CA0
c957: dq 0xFFFFFFFFFFFFF, 0xC0621E6EB61B4CA0
c958: dq 0xFFF0000000000123, 0xFFF0000000000000
c959: dq 0xC05B519F85F83A30, 0xC0617F60DF943048
c960: dq 0x3F800000, 0x5F00000047F12065
c961: dq 0x426E6C894B800000, 0xD01502F943AE2F6C
c962: dq 0x3F0000003DCCCCCD, 0xC3C139A8BF800000
c963: dq 0x402000007F800000, 0xC3A9E112C35CF408
c964: dq 0xDF0000004F000000, 0x4EFFFFFF3F000000
c965: dq 0x6CE3EEFF800123, 0x3DCCCCCD80000001
c966: dq 0x5F00000040200000, 0xC3E0DC15FF800000
c967: dq 0x47F12065C3FF32CA, 0x7FA0000100000001
c968: dq 0x4EFFFFFFD01502F9, 0xFFC00000
c969: dq 0x4EFFFFFFD01502F9, 0xFFC00000
c970: dq 0x4F800000FFC00000, 0x43E04131501502F9
c971: dq 0x4F800000FFC00000, 0x43E04131501502F9
c972: dq 0x2EDBE6FF7F7FC99E, 0x7F7FFFFF4EFFFFFF
c973: dq 0x4B800000440A4D32, 0x3F000000501502F9
c974: dq 0x443B2EB9501502F9, 0x5F000000DF000000
c975: dq 0x446970AE3EFFFFFF, 0x444F28FF47F12065
c976: dq 0x3EFFFFFF2EDBE6FF, 0x80000000
c977: dq 0x80000000CF000000, 0x80000040F00000
c978: dq 0x7FFFFF7F800000, 0xC419E5D143A21613
c979: dq 0xDF000000501502F9, 0x7F800000
c980: dq 0xDF000000FF800000, 0xCF00000043BCF218
c981: dq 0x7FA0000100000000, 0x180000001
c982: dq 0x4EFFFFFF7F7FC99E, 0x40F000004F000000
c983: dq 0x4429D4DA7F800000, 0x4419DE7480000000
c984: dq 0x4F0000007F7FFFFF, 0x7FC000007FC12345
c985: dq 0x442800A9D01502F9, 0x40F0000000800000
c986: dq 0x7FC123454B800000, 0x7F80000080000000
c987: dq 0x47F12065, 0x5F0000007FC12345
c988: dq 0x44241DAC4B800000, 0x3EFFFFFF7F7FC99E
c989: dq 0x2EDBE6FF3DCCCCCD, 0x4EFFFFFF7F7FFFFF
c990: dq 0xDF0000007F7FC99E, 0x3FC000007F7FFFFF
c991: dq 0x4EFFFFFFC28C6D5C, 0x80000080000001
c992: dq 0x80000000006CE3EE, 0x445BC9D240200000
c993: dq 0x80000000006CE3EE, 0x445BC9D240200000
c994: dq 0x6CE3EECF000000, 0xC32C1CDCBF000000
c995: dq 0xC0F000005F000000, 0x3EFFFFFF435C7948
c996: dq 0xFF8001234B800000, 0x4403B1F8C36A0218
c997: dq 0x7F8000003EFFFFFF, 0x5F000000501502F9
c998: dq 0x3F800000007FFFFF, 0x4B80000042A1652B
c999: dq 0x3F800000007FFFFF, 0x4B80000042A1652B
c1000: dq 0x7FC123454F000000, 0x7F7FC99E7FC12345
c1001: dq 0xBF80000043B7FE4F, 0x7F7FFFFF4EFFFFFF
c1002: dq 0x2EDBE6FF, 0x3DCCCCCDC455A2E2
c1003: dq 0x3F0000005F000000, 0xFF80012380000001
c1004: dq 0x43FF27AFC46C3FBF, 0x40200000
c1005: dq 0xBF800000C0F00000, 0x5F000000C360C26B
c1006: dq 0x40F00000FF800123, 0x6CE3EE007FFFFF
c1007: dq 0x47F12065442DCE8A, 0xFF80000043ED0F8B
c1008: dq 0xC3E0000000000000, 0x43E158E460913D00
c1009: dq 0x40FE240C9FBE76C9, 0x3FF0000000000000
c1010: dq 0x41F0000000000000, 0x4008000000000000
c1011: dq 0x4008000000000000, 0x1
c1012: dq 0x4072597BA71FAE1C, 0x3FF8000000000000
c1013: dq 0x7FEFFFFFFFFFFFFF, 0x1
c1014: dq 0xC01E000000000000, 0xC0768258616C2D80
c1015: dq 0xC0891B8B216EB930, 0x4084E103FFAFBDBC
c1016: dq 0xBFE0000000000000, 0xC08F0716F2DDF3D0
c1017: dq 0x3FF0000000000000, 0x366244CE242C5561
c1018: dq 0x43E0000000000000, 0x47EFFFFFF0000000
c1019: dq 0x43E0000000000000, 0x47EFFFFFF0000000
c1020: dq 0x41E0000000000000, 0xC0788AE1EEE93200
c1021: dq 0x41E0000000000000, 0xC0788AE1EEE93200
c1022: dq 0x4004000000000000, 0xC1E0000000000000
c1023: dq 0x4004000000000000, 0xC1E0000000000000
c1024: dq 0x0, 0x3FDFFFFFFFFFFFFF
c1025: dq 0xC01E000000000000, 0x401E000000000000
c1026: dq 0x3FF0000000000000, 0x0
c1027: dq 0x40FE240C9FBE76C9, 0x1
c1028: dq 0xBFE0000000000000, 0xC01E000000000000
c1029: dq 0x10000000000000, 0xC03D369BAE32DEA0
c1030: dq 0x10000000000000, 0xC07E8769CE698425
c1031: dq 0x408673AE48599C30, 0x401E000000000000
c1032: dq 0x10000000000000, 0x3FB999999999999A
c1033: dq 0xBFE0000000000000, 0x8000000000000000
c1034: dq 0xC004000000000000, 0x4088F1670690432C
c1035: dq 0xC1E0000000100000, 0xC1E0000000000000
c1036: dq 0x3FDFFFFFFFFFFFFF, 0xC1E0000000100000
c1037: dq 0x408BE3786A169710, 0xC1E0000000100000
c1038: dq 0x41F0000000000000, 0x7FF4000000000001
c1039: dq 0xC1E0000000100000, 0x4008000000000000
c1040: dq 0xC3E0000000000000, 0x366244CE242C5561
c1041: dq 0x408A277E6A2FC4A4, 0xC3E0000000000000
c1042: dq 0x407D670B79D9E6D0, 0x40FE240C9FBE76C9
c1043: dq 0x4008000000000000, 0x41DFFFFFFFE00000
c1044: dq 0x7FF8000000000000, 0x3FB999999999999A
c1045: dq 0xC1E0000000000000, 0xFFF0000000000000
c1046: dq 0x4202A05F20000000, 0x3FE0000000000000
c1047: dq 0x7FEE42D130773B76, 0x3FF8000000000000
c1048: dq 0xC07EA7CC26A7CD2E, 0x408CCE2789EEE9C2
c1049: dq 0xC07EA7CC26A7CD2E, 0x408CCE2789EEE9C2
c1050: dq 0x3FB999999999999A, 0x8000000000000000
c1051: dq 0x3FB999999999999A, 0x8000000000000000
c1052: dq 0x41DFFFFFFFE00000, 0xC08C1967815F16BB
c1053: dq 0xC08E445C68FAACFE, 0x40841B3E1126D16E
c1054: dq 0x7FF4000000000001, 0xFFF0000000000123
c1055: dq 0x406FBE8E5C768EC0, 0x7FEE42D130773B76
c1056: dq 0x3FC000005F000000, 0xC409FF0E3F800000
c1057: dq 0x3FC000005F000000, 0xC409FF0E3F800000
c1058: dq 0x3FC00000C33678C3, 0x3F000000C0200000
c1059: dq 0x47F1206500000000, 0x7FFFFF7F800000
c1060: dq 0x5F00000080000001, 0x3F0000004B800000
c1061: dq 0x7F800000C3C00A6B, 0x3F800000C2D272C3
c1062: dq 0xBF800000444684FF, 0x501502F9501502F9
c1063: dq 0x2EDBE6FF7F7FFFFF, 0xC3F11A237FC00000
c1064: dq 0x147F12065, 0x3F0000003DCCCCCD
c1065: dq 0xBF8000004F000000, 0x44374C9C4F800000
c1066: dq 0x7FA000017F7FFFFF, 0x4F00000040200000
c1067: dq 0x4EFFFFFF00800000, 0x4F8000005F000000
c1068: dq 0xC2D2DD6D7FC12345, 0x4EFFFFFF7FC12345
c1069: dq 0xBF8000004454898F, 0x404000007F7FC99E
c1070: dq 0xC0F000007FC00000, 0x5F000000443515A6
c1071: dq 0x4EFFFFFF2EDBE6FF, 0x44313BC84EFFFFFF
c1072: dq 0x7F7FC99EC3E5160C, 0x47F12065C192A9FA
c1073: dq 0xC3B6094C5F000000, 0x7F7FC99ECF000000
c1074: dq 0x4F0000004F000000, 0x3FC00000C0F00000
c1075: dq 0x7FA00001006CE3EE, 0x439CF32D44036C58
c1076: dq 0x4415A08A00000000, 0xBF0000004F800000
c1077: dq 0x43BB28873F800000, 0xC0200000DF000000
c1078: dq 0x3FC0000000800000, 0x501502F97F7FFFFF
c1079: dq 0x6CE3EE, 0xC45584AD00000001
c1080: dq 0x43A68E85C0F00000, 0x40F00000FF800123
c1081: dq 0x43A68E85C0F00000, 0x40F00000FF800123
c1082: dq 0x7FC123454440BBBB, 0x7FA000014395E8FE
c1083: dq 0x501502F9CF000000, 0xD01502F9441FCFD1
c1084: dq 0x42CC79C37F7FC99E, 0x7FC00000501502F9
c1085: dq 0x402000007F800000, 0x800000003F800000
c1086: dq 0x40F000005F000000, 0x402000003F000000
c1087: dq 0x7FC00000FF800000, 0xFF80012343DEEC3B
c1088: dq 0x43DA39A7429F9CB7, 0x2EDBE6FF5F000000
c1089: dq 0x501502F9BF800000, 0x43A3CA6540F00000
c1090: dq 0x4F0000007FC12345, 0x7FC00000007FFFFF
c1091: dq 0x2EDBE6FF5F000000, 0xC46070037F7FFFFF
c1092: dq 0x43E224D700000000, 0x2EDBE6FF006CE3EE
c1093: dq 0x3FC000005F000000, 0x40F000003EFFFFFF
c1094: dq 0x800000C3B8A19C, 0x3FC000007FC00000
c1095: dq 0x80000047F12065, 0x4F80000000000000
c1096: dq 0x80000047F12065, 0x4F80000000000000
c1097: dq 0xC2A5777CC4151C41, 0x3F80000080000000
c1098: dq 0x80000000430E1F65, 0x7F7FFFFFDF000000
c1099: dq 0x43BC5D5D5F000000, 0x501502F92EDBE6FF
c1100: dq 0x4EFFFFFFDF000000, 0x7FC000003EFFFFFF
c1101: dq 0xC45D7D6A40200000, 0x8000003EFFFFFF
c1102: dq 0x6CE3EE7FC12345, 0x7FC0000000000001
c1103: dq 0x4020000044261BE2, 0x80000000006CE3EE
c1104: dq 0x47F12065CF000000, 0xC3F802CBC4597961
c1105: dq 0x7F7FFFFF47F12065, 0x3F00000000000001
c1106: dq 0x8000004F000000, 0x2EDBE6FFC2979EFF
c1107: dq 0x40F000004F800000, 0xC3C7617800000001
c1108: dq 0x431F7BF03DCCCCCD, 0xC424CBDADF000000
c1109: dq 0x501502F9FF800000, 0x7FC00000CF000000
c1110: dq 0xC3856B8F7F800000, 0x501502F9436F555A
c1111: dq 0x7FA000013FC00000, 0x4F000000C46ADE3A
c1112: dq 0x4F00000040400000, 0x440D877FFFC00000
c1113: dq 0x4436F38A4F000000, 0xBF000000006CE3EE
c1114: dq 0x4EFFFFFF7FC00000, 0xCF00000080000001
c1115: dq 0x7F7FFFFF5F000000, 0x6CE3EEFFC00000
c1116: dq 0x7FC0000000000000, 0xD01502F9BF000000
c1117: dq 0xC3AB932740400000, 0x4EFFFFFFFF800000
c1118: dq 0x42BDF34980000000, 0x4B80000040200000
c1119: dq 0x433B25CE3EFFFFFF, 0x4EFFFFFF40400000
c1120: dq 0xFFC000003DCCCCCD, 0x8000000143F5DC15
c1121: dq 0x47F12065DF000000, 0x1444ED7A6
c1122: dq 0x3DCCCCCD80000001, 0xDF00000080000001
c1123: dq 0x5F00000080000001, 0x3FC000003F800000
c1124: dq 0x800000017FA00001, 0x501502F9FF800000
c1125: dq 0x40F00000C0F00000, 0x4F000000443F33D8
c1126: dq 0x7F7FFFFF43F7C4FD, 0xBF800000C46E4500
c1127: dq 0x443190863FC00000, 0x47F12065C0200000
c1128: dq 0x43E3775B4F000000, 0x404000003F800000
c1129: dq 0x4B8000003DCCCCCD, 0xBF8000007F800000
c1130: dq 0xFFC000007FC12345, 0x4F800000501502F9
c1131: dq 0xC0F00000, 0xC4700472006CE3EE
c1132: dq 0xCF00000080000000, 0x47F1206540F00000
c1133: dq 0x44353744C32AD407, 0x3F8000007FA00001
c1134: dq 0x8000000140200000, 0xBF00000040400000
c1135: dq 0xC22DF30B00000001, 0x40F00000BF800000
c1136: dq 0x47F120657F800000, 0x7F80000043963F00
c1137: dq 0x3FC000007FC12345, 0x7FA0000140400000
c1138: dq 0x47F12065FF800123, 0x4EFFFFFF438EFD09
c1139: dq 0x7FC12345C448F7D4, 0xC3BD5BCF4F000000
c1140: dq 0xFF80000080000000, 0x80000001FF800000
c1141: dq 0xFFC000007F7FFFFF, 0x7F7FC99EFF800123
c1142: dq 0xD01502F95F000000, 0x7FFFFFC3FC0476
c1143: dq 0x3EFFFFFF4F000000, 0x44353CB740F00000
c1144: dq 0xC29C7CDC5F000000, 0xBF000000BF000000
c1145: dq 0xFF800000FF800000, 0x7F800000BF800000
c1146: dq 0x434B1B193DCCCCCD, 0x4F0000007FA00001
c1147: dq 0x434B1B193DCCCCCD, 0x4F0000007FA00001
c1148: dq 0xBF00000080000001, 0x43EE2E09443E5DA3
c1149: dq 0xFF800123DF000000, 0xC0F000004F800000
c1150: dq 0x80000001FF800123, 0x7F7FC99E
c1151: dq 0xCF0000004B800000, 0x4F0000004F000000
c1152: dq 0xFFF8000000000000, 0x407E1843CE3821EC
c1153: dq 0x366244CE242C5561, 0x4070452B9087C634
c1154: dq 0xFFFFFFFFFFFFF, 0x3FF0000000000000
c1155: dq 0x4004000000000000, 0x405A540F08227EC0
c1156: dq 0x43E158E460913D00, 0x41F0000000000000
c1157: dq 0x4004000000000000, 0x4340000000000000
c1158: dq 0x4202A05F20000000, 0x41E0000000000000
c1159: dq 0x7FF8000000000000, 0x0
c1160: dq 0x7FF8000012345678, 0x4008000000000000
c1161: dq 0x7FEFFFFFFFFFFFFF, 0x43E158E460913D00
c1162: dq 0x7FF8000000000000, 0x3FB999999999999A
c1163: dq 0x41DFFFFFFFC00000, 0x40636268FB340858
c1164: dq 0xC089D209489D2BF6, 0x401E000000000000
c1165: dq 0xC089D209489D2BF6, 0x401E000000000000
c1166: dq 0x4202A05F20000000, 0xBFE0000000000000
c1167: dq 0x730D67819E8D2, 0x3FF0000000000000
c1168: dq 0xC004000000000000, 0x47EFFFFFF0000000
c1169: dq 0x7FEE42D130773B76, 0x3FF8000000000000
c1170: dq 0xBFE0000000000000, 0x3FB999999999999A
c1171: dq 0x3FF0000000000000, 0x3FDFFFFFFFFFFFFF
c1172: dq 0xC087AC19FC9FE6AE, 0x3DDB7CDFD9D7BDBB
c1173: dq 0x43E0000000000000, 0x4202A05F20000000
c1174: dq 0xC06BB71DBBB3E484, 0x40FE240C9FBE76C9
c1175: dq 0xC202A05F20000000, 0x406AD938C3A993D0
c1176: dq 0xBFF0000000000000, 0xBFF0000000000000
c1177: dq 0x3FE0000000000000, 0x3FF0000000000000
c1178: dq 0xBFE0000000000000, 0x3FF8000000000000
c1179: dq 0xC036726B3BEF8360, 0x4340000000000000
c1180: dq 0x3FF8000000000000, 0xC04762ED2826A0D0
c1181: dq 0x401E000000000000, 0x8000000000000000
c1182: dq 0xC1E0000000100000, 0x7FF8000000000000
c1183: dq 0xC004000000000000, 0x730D67819E8D2
c1184: dq 0xC0628B3E72C06ED8, 0x3FE0000000000000
c1185: dq 0x47EFFFFFF0000000, 0x40FE240C9FBE76C9
c1186: dq 0x47EFFFFFF0000000, 0xBFE0000000000000
c1187: dq 0x3FE0000000000000, 0x405CA6686FD45360
c1188: dq 0x3FDFFFFFFFFFFFFF, 0x41F0000000000000
c1189: dq 0xC004000000000000, 0x8000000000000000
c1190: dq 0x3FF0000000000000, 0x41F0000000000000
c1191: dq 0x408E28DC3638AF92, 0x7FF4000000000001
c1192: dq 0x4340000000000000, 0xC085B6051990500A
c1193: dq 0x43E158E460913D00, 0x7FF8000000000000
c1194: dq 0x7FF8000012345678, 0x7FEFFFFFFFFFFFFF
c1195: dq 0x7FF8000012345678, 0x7FEFFFFFFFFFFFFF
c1196: dq 0x41F0000000000000, 0x41DFFFFFFFE00000
c1197: dq 0x730D67819E8D2, 0xFFF0000000000123
c1198: dq 0xC1E0000000100000, 0x4004000000000000
c1199: dq 0xC1E0000000000000, 0x41E0000000000000
c1200: dq 0xC089B50F75FE0520, 0x407210A08DA48ED0
c1201: dq 0xC089B50F75FE0520, 0x407210A08DA48ED0
c1202: dq 0xC202A05F20000000, 0x4004000000000000
c1203: dq 0xC1E0000000100000, 0xC3E0000000000000
c1204: dq 0x0, 0x41DFFFFFFFE00000
c1205: dq 0x3FB999999999999A, 0xBFF0000000000000
c1206: dq 0xC004000000000000, 0xC07E0D7C5334F242
c1207: dq 0xC1E0000000100000, 0xFFF8000000000000
c1208: dq 0xBFE0000000000000, 0xFFF0000000000123
c1209: dq 0xBFF0000000000000, 0xC1E0000000000000
c1210: dq 0xC1E0000000100000, 0x408656AB3FE2B2D4
c1211: dq 0xC067D55617095A7C, 0x47EFFFFFF0000000
c1212: dq 0x3FDFFFFFFFFFFFFF, 0x3DDB7CDFD9D7BDBB
c1213: dq 0x3FDFFFFFFFFFFFFF, 0x3DDB7CDFD9D7BDBB
c1214: dq 0x7FF0000000000000, 0x7FF0000000000000
c1215: dq 0xBFF0000000000000, 0xC07301A57EB7E068
c1216: dq 0xC1E0000000100000, 0x1
c1217: dq 0xC01E000000000000, 0xC07B468C1BE6DF04
c1218: dq 0x8000000000000000, 0x41DFFFFFFFC00000
c1219: dq 0xFFF0000000000000, 0x406912943F072BC0
c1220: dq 0x3FB999999999999A, 0x366244CE242C5561
c1221: dq 0x3FF0000000000000, 0x4004000000000000
c1222: dq 0x40FE240C9FBE76C9, 0x7FEE42D130773B76
c1223: dq 0x4088F47B69669BC0, 0x43E0000000000000
c1224: dq 0x47EFFFFFF0000000, 0x401E000000000000
c1225: dq 0x4076225FFB15E784, 0x4008000000000000
c1226: dq 0x4340000000000000, 0x4340000000000000
c1227: dq 0x366244CE242C5561, 0x730D67819E8D2
c1228: dq 0x408D915BBB51D9A4, 0x401E000000000000
c1229: dq 0x7FF0000000000000, 0xC3E0000000000000
c1230: dq 0x3FF0000000000000, 0xC1E0000000100000
c1231: dq 0x3FF0000000000000, 0xC1E0000000100000
c1232: dq 0x10000000000000, 0x10000000000000
c1233: dq 0x43E158E460913D00, 0xFFF0000000000123
c1234: dq 0x366244CE242C5561, 0x4063CFE7A7E820C0
c1235: dq 0x40869460D8973CB2, 0x408C6314E5ED7200
c1236: dq 0x10000000000000, 0xFFF0000000000123
c1237: dq 0xC004000000000000, 0xC01E000000000000
c1238: dq 0x3FDFFFFFFFFFFFFF, 0x8000000000000000
c1239: dq 0x7FF4000000000001, 0xC3E0000000000000
c1240: dq 0xC004000000000000, 0xC1E0000000000000
c1241: dq 0xFFFFFFFFFFFFF, 0x730D67819E8D2
c1242: dq 0xBFE0000000000000, 0x7FF8000012345678
c1243: dq 0xBFE0000000000000, 0x7FF8000012345678
c1244: dq 0xBFE0000000000000, 0xC04E837060451850
c1245: dq 0xC05C72F1D4A0A5F0, 0xBFE0000000000000
c1246: dq 0xC05C72F1D4A0A5F0, 0xBFE0000000000000
c1247: dq 0x3FF8000000000000, 0x4084DC09D116A462
c1248: dq 0xFF8001233EFFFFFF, 0x4EFFFFFF7F800000
c1249: dq 0x43E158E460913D00, 0x7FF8000012345678
c1250: dq 0xFFF8000000000000, 0x4008000000000000
c1251: dq 0xFFC000003FC00000, 0x3EFFFFFF3DCCCCCD
c1252: dq 0xFF800000501502F9, 0x4B80000040200000
c1253: dq 0x40FE240C9FBE76C9, 0x7FF8000000000000
c1254: dq 0xC08E576C3930193C, 0x4340000000000000
c1255: dq 0xDF000000DF000000, 0x43B9F15E7F7FFFFF
c1256: dq 0x4F80000047F12065, 0x7FC123453F000000
c1257: dq 0x7FF8000000000000, 0x401E000000000000
c1258: dq 0xC06032EBCCD7C190, 0x4081B27335168112
c1259: dq 0x43E8EAB2501502F9, 0xC0200000CF000000
c1260: dq 0x7F7FC99EC45300E6, 0xBF000000C2FA86F9
c1261: dq 0xFFFFFFFFFFFFF, 0x41E0000000000000
c1262: dq 0x408D313D00A32432, 0x4083198CC5E07FD6
c1263: dq 0xC42169D6C44358B2, 0x8000000180000000
c1264: dq 0x7F800000C0F00000, 0x7FC000003DCCCCCD
c1265: dq 0x7FEFFFFFFFFFFFFF, 0x41DFFFFFFFE00000
c1266: dq 0xC07C3932617BDF46, 0x7FF0000000000000
c1267: dq 0x6CE3EE4F800000, 0xFF800123C0F00000
c1268: dq 0x7FA000017FC12345, 0x4EFFFFFF7F800000
c1269: dq 0x1, 0x40776D5D2FD0051C
c1270: dq 0x7FF0000000000000, 0x4202A05F20000000
c1271: dq 0x3FC000007F7FFFFF, 0x80000001006CE3EE
c1272: dq 0x7F800000FF800000, 0xD01502F94437A3FE
c1273: dq 0x0, 0xC1E0000000000000
c1274: dq 0x3DDB7CDFD9D7BDBB, 0xFFF8000000000000
c1275: dq 0xBF80000080000000, 0x40200000FFC00000
c1276: dq 0xC3AAC44DBF800000, 0xFF8000003F800000
c1277: dq 0x3FF0000000000000, 0x4340000000000000
c1278: dq 0x408750A1EB9E5880, 0x8000000000000000
c1279: dq 0x43CD10A347F12065, 0x7F800000DF000000
c1280: dq 0xCF0000003EFFFFFF, 0x140200000
c1281: dq 0xE2105424FFB30044, 0xFFFFFFFF
c1282: dq 0xC0200000C46E84D5, 0x80000000FF800123
c1283: dq 0x7F7FFFFFDF000000, 0x7FFFFF40400000
c1284: dq 0x8000BC547FFF2FB1, 0xFFFF2442AC8E7DF3
c1285: dq 0x402000002EDBE6FF, 0x3DCCCCCD442AA064
c1286: dq 0x800000446C0E6E, 0x42BF18DA7F7FFFFF
c1287: dq 0x1257A12580000000, 0xCAC48B52FC4133BE
c1288: dq 0x43E582D12EDBE6FF, 0x40400000C0200000
c1289: dq 0xC02000004461EFD6, 0x7F8000003DCCCCCD
c1290: dq 0x57ED80D1FF421A01, 0x4C004094FF29FFFF
c1291: dq 0x43C5E4A44443E120, 0x3F000000FF800000
c1292: dq 0x7F7FC99E7F800000, 0x2EDBE6FF006CE3EE
c1293: dq 0xD9CB5A71DF699EB3, 0x1
c1294: dq 0xC02000007FC00000, 0x4B80000000800000
c1295: dq 0x7FC12345C0F00000, 0x40200000BF800000
c1296: dq 0xC4E740A4007F80C1, 0x7F81FFC201011881
c1297: dq 0x800000003F800000, 0xC0200000DF000000
c1298: dq 0x444962DBFF800123, 0xFF800123D01502F9
c1299: dq 0xFFFF, 0x7FFFFFFF00000001
c1300: dq 0x4EFFFFFFC4474564, 0x432868B3D01502F9
c1301: dq 0xBF00000040400000, 0x4469972EC3B11B2A
c1302: dq 0x100000000, 0xD53FFFE90000FFFF
c1303: dq 0xD01502F9, 0x1C0200000
c1304: dq 0x7F7FC99E4EFFFFFF, 0x3F000000BF800000
c1305: dq 0x6FAD0C97FFFFFFFF, 0xFFFFFFFF80000000
c1306: dq 0x7FFFFF3EFFFFFF, 0x4F800000C2D5B155
c1307: dq 0x2EDBE6FFBF000000, 0x4F800000501502F9
c1308: dq 0xFF800080007FFF, 0xFEA3FFFF7FFF8000
c1309: dq 0x4EFFFFFFD01502F9, 0xC42E8BE500000000
c1310: dq 0x40762ACDE795914C, 0x4340000000000000
c1311: dq 0x623E557EFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c1312: dq 0x3FF0000000000000, 0x40845CFEDEA80B8E
c1313: dq 0x1, 0x7FEFFFFFFFFFFFFF
c1314: dq 0x67AE0100F79DBF0B, 0x7FFF5F7A571BCA57
c1315: dq 0x7FEFFFFFFFFFFFFF, 0x47EFFFFFF0000000
c1316: dq 0xFFF0000000000123, 0xC0605136CF8701B4
c1317: dq 0x1000080000000, 0xA8E27B42261DD0B1
c1318: dq 0x406EBFC895B55B48, 0x43E158E460913D00
c1319: dq 0x3DDB7CDFD9D7BDBB, 0xC1E0000000000000
c1320: dq 0x408100018101A001, 0x80816D70B9C00017
c1321: dq 0xC088FABED98C37A8, 0x7FEE42D130773B76
c1322: dq 0x7FF0000000000000, 0xBFF0000000000000
c1323: dq 0x800017590001D8D9, 0x1344B0001F512
c1324: dq 0xBFF0000000000000, 0x43E0000000000000
c1325: dq 0x4004000000000000, 0xC047C48A1A0AA8B0
c1326: dq 0x65801501FF808080, 0xFF83845F7F181F7F
c1327: dq 0x3FE0000000000000, 0xC0879BBF74D5E439
c1328: dq 0x730D67819E8D2, 0x4081E42AB705683A
c1329: dq 0x1000000FFFF0DA7, 0xFFFFFF41930000
c1330: dq 0xC08A74E0218D26E5, 0x1
c1331: dq 0x7FF4000000000001, 0x7FF4000000000001
c1332: dq 0xD7800101400B7F80, 0x81401980807F9DA8
c1333: dq 0x7FEFFFFFFFFFFFFF, 0xC202A05F20000000
c1334: dq 0x43E158E460913D00, 0x3FF0000000000000
c1335: dq 0x800100010001, 0xFF1F3D0AE50000
c1336: dq 0x401E000000000000, 0x3FF8000000000000
c1337: dq 0x40FE240C9FBE76C9, 0xFFF8000000000000
c1338: dq 0xFE47EBAAB5931025, 0x37C408BF456EC3D6
c1339: dq 0xC069610E65A151DC, 0xC01E000000000000
c1340: dq 0x44753072DF000000, 0x4417C6CB80000001
c1341: dq 0x4340000000000000, 0x4008000000000000
c1342: dq 0xC07D50606716CF26, 0xC03D8F32C6E0ED80
c1343: dq 0x800000002EDBE6FF, 0x4B800000C4034AE0
c1344: dq 0x43AB6599C42ABBE7, 0x3F000000D01502F9
c1345: dq 0x40814960739DDA6C, 0x7FF4000000000001
c1346: dq 0xC058282FEE0FDD70, 0xC004000000000000
c1347: dq 0xFFC000004B800000, 0x4F80000000000000
c1348: dq 0x40F000004B800000, 0xDF00000040F00000
c1349: dq 0x366244CE242C5561, 0x7FF8000012345678
c1350: dq 0xFFFFFFFFFFFFF, 0xC1E0000000000000
c1351: dq 0xC4355E36434BD9A6, 0x4040000000000000
c1352: dq 0xC0F000004EFFFFFF, 0xBF0000007FC00000
c1353: dq 0x7FEE42D130773B76, 0x3DDB7CDFD9D7BDBB
c1354: dq 0x7FEE42D130773B76, 0x408A5A73E496C910
c1355: dq 0xFFC000007FC12345, 0x3F00000000000001
c1356: dq 0xC459F692CF000000, 0x3FC0000047F12065
c1357: dq 0x4008000000000000, 0x43E0000000000000
c1358: dq 0x10000000000000, 0x4074BEFAA4066BF4
c1359: dq 0x40F0000000000001, 0xC0200000FF800123
c1360: dq 0x501502F93FC00000, 0x4F8000004F000000
c1361: dq 0x7FF8000000000000, 0x405747D3EC9646F0
c1362: dq 0xFFF8000000000000, 0xFFF0000000000000
c1363: dq 0x5F00000040F00000, 0x2EDBE6FFC0200000
c1364: dq 0x47F120652EDBE6FF, 0x7FFFFFBF000000
c1365: dq 0x366244CE242C5561, 0x730D67819E8D2
c1366: dq 0x401E000000000000, 0x41DFFFFFFFC00000
c1367: dq 0xCF000000BF000000, 0x40F00000C4072E02
c1368: dq 0x3F000000C42942C6, 0x4406937280000001
c1369: dq 0x7FF0000000000000, 0xC3E0000000000000
c1370: dq 0x3FB999999999999A, 0xBFE0000000000000
c1371: dq 0x40400000BF800000, 0x443807DC4F000000
c1372: dq 0xC4619882D01502F9, 0x5F0000007FC00000
c1373: dq 0x23B6CB7400010000, 0x7FFF80000000FFFF
c1374: dq 0x402000003F800000, 0x44278F73006CE3EE
c1375: dq 0x7FC12345C2B7B3BF, 0xC41FC7EF7FC00000
c1376: dq 0xFF0001AAA37FFF, 0x800001000000B24B
c1377: dq 0x430D13B4, 0x3EFFFFFFC41C64E8
c1378: dq 0x4F8000004F000000, 0x800000014F800000
c1379: dq 0x18000AF1D837E, 0x1371977CAEEEB
c1380: dq 0xD01502F940F00000, 0x4420D0792EDBE6FF
c1381: dq 0xC4050442BF800000, 0xD01502F9006CE3EE
c1382: dq 0xCC4FF98A69387023, 0x100000000
c1383: dq 0x3DCCCCCD3FC00000, 0x13F000000
c1384: dq 0x4F8000004F800000, 0xDF0000003FC00000
c1385: dq 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
c1386: dq 0x3F800000CF000000, 0x40F00000BF000000
c1387: dq 0xFF800123FF800000, 0x404000004321C149
c1388: dq 0x108181B8B4678181, 0xFFD84040E0349480
c1389: dq 0x1FFC00000, 0x7FC0000047F12065
c1390: dq 0xC40000B05F000000, 0x5F000000C469733B
c1391: dq 0x817F4F81009640FF, 0x26401B008C3F49FF
c1392: dq 0x2EDBE6FFFF800123, 0x7F7FC99E3F000000
c1393: dq 0xC4513CC74F800000, 0x3F000000BF000000
c1394: dq 0x818F0101FF01EDFF, 0x80C240400001FF29
c1395: dq 0x7F7FC99EC0200000, 0x3F8000004F800000
c1396: dq 0x4F80000080000000, 0x7F7FC99E7FC12345
c1397: dq 0x1E1AEC787F496803, 0xFFFFFFFF
c1398: dq 0x402000007FA00001, 0x4F0000004F000000
c1399: dq 0x445ABFB400000000, 0xFF800123C0F00000
c1400: dq 0x40A000407F40F48E, 0x7F811C01C77F0181
c1401: dq 0x3DCCCCCDC0200000, 0x43330ADD47F12065
c1402: dq 0x40FE240C9FBE76C9, 0xC0713F3E476A3E0A
c1403: dq 0xB979007F7F0785C5, 0x81497FBF961D8125
c1404: dq 0x43E158E460913D00, 0x366244CE242C5561
c1405: dq 0x407F3A8275F65B0C, 0xC04B950AADFBCA60
c1406: dq 0xC275800100018000, 0x7FFF06AC80009393
c1407: dq 0x4008000000000000, 0x43E0000000000000
c1408: dq 0x408CAA89188C5F1A, 0x41F0000000000000
c1409: dq 0x7FFF8203FFFF0100, 0xFFFFFF80010000
c1410: dq 0xFFF8000000000000, 0xFFF0000000000123
c1411: dq 0x7FEE42D130773B76, 0x0
c1412: dq 0xC1E8F99FF38FF9D, 0x80CDA1FF81008040
c1413: dq 0x10000000000000, 0xBFE0000000000000
c1414: dq 0x4081D9422CE5275A, 0x8000000000000000
c1415: dq 0xFF7301FFBC8081CF, 0xFF8081BB8081C7FD
c1416: dq 0x40FE240C9FBE76C9, 0x43E0000000000000
c1417: dq 0x43E158E460913D00, 0x3FE0000000000000
c1418: dq 0xFF4080FF7F235740, 0x7FB7007F2E69388C
c1419: dq 0x10000000000000, 0x3FDFFFFFFFFFFFFF
c1420: dq 0xFFF0000000000000, 0x3FE0000000000000
c1421: dq 0x5E5810181970181, 0xD9FF004F01FF0175
c1422: dq 0x3FB999999999999A, 0xFFFFFFFFFFFFF
c1423: dq 0xC05309B1B7F74368, 0xC004000000000000
c1424: dq 0x3EC2425, 0x100001C271A9B
c1425: dq 0x41F0000000000000, 0x7FF8000000000000
c1426: dq 0x41E0000000000000, 0xC3E0000000000000
c1427: dq 0x100000000, 0x0
c1428: dq 0xFFF0000000000000, 0x41F0000000000000
c1429: dq 0x40FE240C9FBE76C9, 0x7FF0000000000000
c1430: dq 0x178173A00FF0A7F, 0x2A01CE010180BAD2
c1431: dq 0x4008000000000000, 0xC08C5EFC4D346936
c1432: dq 0xC41753F0DF000000, 0xC46E663D4123759E
c1433: dq 0x7FEE42D130773B76, 0x1
c1434: dq 0x40FE240C9FBE76C9, 0x3FB999999999999A
c1435: dq 0x43AAB10BCF000000, 0x501502F9C3F93E47
c1436: dq 0x80000040F00000, 0x7F7FC99EC3C2E204
c1437: dq 0x3FF8000000000000, 0x366244CE242C5561
c1438: dq 0x401E000000000000, 0xC06511DD8D1211A8
c1439: dq 0x7FA00001C213E7A6, 0x2EDBE6FF4EFFFFFF
c1440: dq 0x6CE3EE40F00000, 0xCF0000003F800000
c1441: dq 0x3DDB7CDFD9D7BDBB, 0x7FF8000012345678
c1442: dq 0xC0710A3461DF2D28, 0x4004000000000000
c1443: dq 0xC0F000004F000000, 0x7FA0000100800000
c1444: dq 0x7FFFFFC4095D5A, 0x446A4774CF000000
c1445: dq 0xC1E0000000000000, 0xC202A05F20000000
c1446: dq 0x10000000000000, 0x47EFFFFFF0000000
c1447: dq 0x4F8000005F000000, 0xFF800000FF800123
c1448: dq 0x40F000007FC00000, 0x4418BCD4CF000000
c1449: dq 0x3FB999999999999A, 0x41DFFFFFFFC00000
c1450: dq 0x7FF8000000000000, 0x4008000000000000
c1451: dq 0xFFC00000CF000000, 0x800000002EDBE6FF
c1452: dq 0x40F0000044184A99, 0x17FA00001
c1453: dq 0x7FEE42D130773B76, 0x7FF0000000000000
c1454: dq 0x406B8BC87FA50B30, 0x3FE0000000000000
c1455: dq 0x7F7FFFFF7F7FFFFF, 0x800000C326C4D7
c1456: dq 0xCF000000C36939A6, 0xC41F3F91
c1457: dq 0x366244CE242C5561, 0x3FF0000000000000
c1458: dq 0x41DFFFFFFFE00000, 0x401E000000000000
c1459: dq 0x47F12065BF000000, 0x42C59689FF800000
c1460: dq 0xC0F0000040400000, 0x40200000FFC00000
c1461: dq 0xC004000000000000, 0x7FF8000012345678
c1462: dq 0xC08EEFF4BC7132D7, 0x41E0000000000000
c1463: dq 0x443307FE3F000000, 0x4B80000000800000
c1464: dq 0xBF000000DF000000, 0xC3AB2C3540200000
c1465: dq 0x81FF664040A88040, 0xFF80F0427FDF8100
c1466: dq 0xC3D5A12880000001, 0x4F80000043F5D504
c1467: dq 0x8000000080000001, 0x4040000000000001
c1468: dq 0xFFFFFFFFD29B88CA, 0xC4564D0309485C0D
c1469: dq 0xD01502F9C3F53F55, 0xCF000000007FFFFF
c1470: dq 0x40400000CF000000, 0xC46DCF47C43829D6
c1471: dq 0x65D5817A8FFF80, 0x1A81FFFF40027F81
c1472: dq 0x3DCCCCCD3DCCCCCD, 0xBF000000007FFFFF
c1473: dq 0x4EFFFFFF3EFFFFFF, 0xC1886B74CF000000
c1474: dq 0xF23FF078C12EFBF3, 0xFFFFFFFFFFFFFFFF
c1475: dq 0x43F7B68EFF800000, 0x442F039E2EDBE6FF
c1476: dq 0xC37A8AF83F000000, 0x4B800000007FFFFF
c1477: dq 0x3C81FF00018AA1E5, 0xA7014040D940BD5F
c1478: dq 0x40F000004307FE68, 0x4B80000040F00000
c1479: dq 0x4F00000047F12065, 0x7FA00001FFC00000
c1480: dq 0x7FFFFFFFE13E1C1B, 0x1
c1481: dq 0x442D15F8C0200000, 0x3F000000BF800000
c1482: dq 0xC2BAA71DCF000000, 0xC42D414F4F000000
c1483: dq 0x92FF7FCD818100FF, 0xB5407F017C058180
c1484: dq 0x3F00000041BAD164, 0xC28A1F3A7FC12345
c1485: dq 0x441F39C640F00000, 0xBF800000501502F9
c1486: dq 0x80000000FFFFFFFF, 0xE5D7226D0000FFFF
c1487: dq 0x4F8000004424353C, 0xCF0000005F000000
c1488: dq 0xC0F000003F800000, 0x4B800000437A5240
c1489: dq 0xEBDD521A8000171E, 0x1B3E01000100F8E2
c1490: dq 0xD01502F9BF800000, 0xD01502F940200000
c1491: dq 0x4F8000004439AB2A, 0x439E25BBCF000000
c1492: dq 0x18C25E562D1A85D4, 0xFFFF7FFFFFFF
c1493: dq 0x441894E3C473EE45, 0xC40AA74C5F000000
c1494: dq 0x3FE0000000000000, 0x3DDB7CDFD9D7BDBB
c1495: dq 0xCAF9800000018000, 0x83AF00FF00014992
c1496: dq 0xC0862354BEF8FBAA, 0x4060F15E76EAFE50
c1497: dq 0x3FB999999999999A, 0x10000000000000
c1498: dq 0xFFFF00FFC37D0100, 0xE5B80001D7370001
c1499: dq 0xFFF8000000000000, 0x4008000000000000
c1500: dq 0x3DDB7CDFD9D7BDBB, 0xC08CF81DEE5EA4E4
c1501: dq 0x800000007FFFFFFF, 0x100000000
c1502: dq 0x4008000000000000, 0x4008000000000000
c1503: dq 0x3FDFFFFFFFFFFFFF, 0x47EFFFFFF0000000
c1504: dq 0x17FFF8000A7BA, 0x180008001FFFF
c1505: dq 0x40761304C9239210, 0xC1E0000000000000
c1506: dq 0xBFE0000000000000, 0xBFE0000000000000
c1507: dq 0x800100FF00FF0000, 0x7FFF0BD4A46E
c1508: dq 0x408A8847370CEBF2, 0x7FF8000012345678
c1509: dq 0x4004000000000000, 0xC066656E6D65C774
c1510: dq 0xFFFF0000FFFF, 0x7FFFFFFF
c1511: dq 0xC202A05F20000000, 0x3DDB7CDFD9D7BDBB
c1512: dq 0x8000000000000000, 0xC1E0000000100000
c1513: dq 0xC60064B7417FAF2A, 0x100402040818133
c1514: dq 0x408B35675C8E34DA, 0xFFF0000000000123
c1515: dq 0x408E29A6A306F72A, 0x40FE240C9FBE76C9
c1516: dq 0x180FF010127378C, 0xFF80FF038F866705
c1517: dq 0xC004000000000000, 0x41F0000000000000
c1518: dq 0x43E0000000000000, 0x730D67819E8D2
c1519: dq 0x408180816E004040, 0x9AD301018040007F
c1520: dq 0x43E158E460913D00, 0xC07E1228F24DA57E
c1521: dq 0x366244CE242C5561, 0x41DFFFFFFFE00000
c1522: dq 0xFFFFA288D492, 0x7FFFFFFF00000000
c1523: dq 0x7FEFFFFFFFFFFFFF, 0xBFE0000000000000
c1524: dq 0x3F800000FF800123, 0x4EFFFFFF3DCCCCCD
c1525: dq 0x3FF0000000000000, 0x3FDFFFFFFFFFFFFF
c1526: dq 0xC087D70804B57EA4, 0x730D67819E8D2
c1527: dq 0x43801DDEC4038924, 0x6CE3EE44129EDA
c1528: dq 0x40F0000000000001, 0xD01502F9C4126C41
c1529: dq 0xC1E0000000000000, 0x3FB999999999999A
c1530: dq 0x40FE240C9FBE76C9, 0xC004000000000000
c1531: dq 0xD01502F94EFFFFFF, 0xC0F000004F000000
c1532: dq 0x3EFFFFFF440B7624, 0x3FC000003F800000
c1533: dq 0xC01E000000000000, 0x0
c1534: dq 0xC01E000000000000, 0x4004000000000000
c1535: dq 0x3DCCCCCD00000001, 0x402000003F000000
c1536: dq 0x4F800000006CE3EE, 0x40400000446F3085
c1537: dq 0x7FF4000000000001, 0x3FB999999999999A
c1538: dq 0x407692DDDD59A8F0, 0x730D67819E8D2
c1539: dq 0xC0200000FF800000, 0xD01502F97F800000
c1540: dq 0xDF000000C3821EB1, 0x3F000000FF800123
c1541: dq 0xC07E3F03D49255E0, 0x730D67819E8D2
c1542: dq 0xFFF8000000000000, 0xC08E79497B61F9C6
c1543: dq 0xC020000044785AA9, 0x3EFFFFFF00800000
c1544: dq 0xFF8001234EFFFFFF, 0x47F12065007FFFFF
c1545: dq 0x3FB999999999999A, 0x7FEFFFFFFFFFFFFF
c1546: dq 0x1, 0x401E000000000000
c1547: dq 0x7F800000CF000000, 0xC26C0C2D007FFFFF
c1548: dq 0x3F800000501502F9, 0x4F8000004424BDCC
c1549: dq 0x10000000000000, 0x7FEFFFFFFFFFFFFF
c1550: dq 0xC01E000000000000, 0x4084195C1C63A51A
c1551: dq 0x80000001FFC00000, 0x4F0000004B800000
c1552: dq 0xD01502F9D01502F9, 0x40F000007F7FFFFF
c1553: dq 0x1, 0xC202A05F20000000
c1554: dq 0xC086778C45566AA6, 0xC202A05F20000000
c1555: dq 0x3F00000080000001, 0x7F8000003DCCCCCD
c1556: dq 0x4020000043AA2A69, 0x446811FCC0F00000
c1557: dq 0xC6DD6BFA, 0x8000000000010000
c1558: dq 0xC0200000501502F9, 0x40F000003EFFFFFF
c1559: dq 0xCF00000040F00000, 0xC44BD61243930C23
c1560: dq 0x100000000, 0x7FFFFFFFFFFFFFFF
c1561: dq 0x800000013DCCCCCD, 0x3F800000C3E18FB6
c1562: dq 0x442370667F7FFFFF, 0x43B159CF3DCCCCCD
c1563: dq 0xEA017F87004081A0, 0x7FFF4040128033
c1564: dq 0x5F00000047F12065, 0x40F00000C39FD9C7
c1565: dq 0x4F80000043D3EAB0, 0x8000004F800000
c1566: dq 0x42014001BD015201, 0x17F81809400FF
c1567: dq 0x47F120653F800000, 0x4F8000002EDBE6FF
c1568: dq 0x4EFFFFFF4B800000, 0x7FA00001FFC00000
c1569: dq 0xFF404C2101F040EA, 0x800140BBAC510180
c1570: dq 0x7FA0000100000001, 0x7FC0000040200000
c1571: dq 0x4B8000004F000000, 0x7F7FFFFF4F000000
c1572: dq 0x562C0A8BE384B5BF, 0x49ECE9AFFFFFFFFF
c1573: dq 0x7FA000012EDBE6FF, 0x5F00000040400000
c1574: dq 0x402000002EDBE6FF, 0xC020000040F00000
c1575: dq 0xF0A5AE9F73CA0400, 0xADE40ACD1B63214E
c1576: dq 0x3F8000004EFFFFFF, 0x40F00000441119D3
c1577: dq 0xC44272A400000000, 0xBF000000444C0A2E
c1578: dq 0x1DA400008000FFFF, 0x6DD000FFFFFF8001
c1579: dq 0x8000000080000001, 0x3FC0000040F00000
c1580: dq 0xBF800000C3DFBAA9, 0x2EDBE6FF7F7FFFFF
c1581: dq 0x135480000001C2BA, 0xFFFF918680009AA7
c1582: dq 0x800000007FA00001, 0x80000000
c1583: dq 0xC3924B523DCCCCCD, 0xC0200000D01502F9
c1584: dq 0x7ADD800100000001, 0xF663157AFFFF00FF
c1585: dq 0x3F000000DF000000, 0x437CB5B700000001
c1586: dq 0xC3E0000000000000, 0x4052E1FBE878CD00
c1587: dq 0x1000000010000, 0x7FFFFFFF
c1588: dq 0x3FB999999999999A, 0xC07026597DD8D1AA
c1589: dq 0x401E000000000000, 0x47EFFFFFF0000000
c1590: dq 0x957FF801A5827C19, 0x1FF5E9A81FF307F
c1591: dq 0xC3E0000000000000, 0x40606C287A4249F8
c1592: dq 0x7FF8000000000000, 0x41DFFFFFFFE00000
c1593: dq 0x17F7F4B7F12819C, 0xFF001200FF81018D
c1594: dq 0xBFE0000000000000, 0xFFF8000000000000
c1595: dq 0x3DDB7CDFD9D7BDBB, 0xC088881B31A86907
c1596: dq 0x1FFFF814F8001, 0x278C0000010052DA
c1597: dq 0x4004000000000000, 0xC0802B0628C51B8C
c1598: dq 0x4008000000000000, 0xC086D9A8FEEA9890
c1599: dq 0x101F87F3E817FA5, 0xC57F4A81CB814000
c1600: dq 0x47EFFFFFF0000000, 0xFFF0000000000123
c1601: dq 0x7FEE42D130773B76, 0xBFF0000000000000
c1602: dq 0x7FFFFFFFFFFFFFFF, 0x8000000000000000
c1603: dq 0xC3E0000000000000, 0x41E0000000000000
c1604: dq 0xC0603B0F9D21AC84, 0x41F0000000000000
c1605: dq 0xD9CAFA3D00000001, 0xF3B81F1EFFFFFFFF
c1606: dq 0xC08291DDF08E8A4A, 0xC06E9051548E6F84
c1607: dq 0x406E55828EA7CA30, 0x7FF4000000000001
c1608: dq 0xFFFFFFFFA406B01F, 0x1BCC7733850D4E63
c1609: dq 0xC06986E6747C7474, 0xFFF0000000000000
c1610: dq 0xC01E000000000000, 0x730D67819E8D2
c1611: dq 0xD280FD3AFF409D00, 0x7F014000DC80D9FF
c1612: dq 0xBFF0000000000000, 0x7FF8000000000000
c1613: dq 0x7FEFFFFFFFFFFFFF, 0x366244CE242C5561
c1614: dq 0x8000000000000000, 0x41EC4CEA00000001
c1615: dq 0x730D67819E8D2, 0x0
c1616: dq 0xFFFFFFFFFFFFFFFF, 0x928660ADB052F72E
c1617: dq 0x7FFFFFFFAD55589D, 0xF01326B4FFFFFFFF
c1618: dq 0x1817F40FF12007F, 0x6681FF0A26808181
c1619: dq 0x7F7F65016680FF00, 0xF833CD3401B2FF40
c1620: dq 0xFFFFFFFFE9879D62, 0x1000000010000
c1621: dq 0x800000000000FFFF, 0x61294F6200000001
c1622: dq 0xF4371E6F7FFF0100, 0xFF2E8E7BCF
c1623: dq 0xFFFFFFFFFFFFFFFF, 0x0
c1624: dq 0x7FFFFFFF, 0x53F9E32C0000FFFF
c1625: dq 0x80408019BF81847F, 0xA781400001B16C
c1626: dq 0x81CE817F816B817F, 0x17FFF017F7F5C3E
c1627: dq 0xFFFFFFFFFFFFFFFF, 0x4D5FE1D051DF0660
c1628: dq 0x53AADE0FBC4FD2B2, 0xAF13310D5C176E60
c1629: dq 0x1C8B52277, 0x3B19071F
c1630: dq 0xFFFFFFFFFFFF, 0xFFFFFFFFFFFF
c1631: dq 0x45F980005800C8E4, 0xFF7FFF8000FFFF
c1632: dq 0x1, 0xE66162822F97DF57
c1633: dq 0x7D1B34D900000000, 0xA395A3BA7FFFFFFF
c1634: dq 0x77958312DF4E968C, 0x100000000
c1635: dq 0xD5EE8900D21F0D9E, 0x1
c1636: dq 0x10000C2C81A2D, 0x61A8B6DA
c1637: dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFF638A0A37
c1638: dq 0xFF000001000001, 0x7FFFC7A700000000
c1639: dq 0x29FF4070804080D8, 0xAEFFFF00007FA3FC
c1640: dq 0xC3BF4E5200800000, 0x3DCCCCCD00000001
c1641: dq 0x1004B76C46D8000, 0x800180010100989C
c1642: dq 0x44177609FF800000, 0x4EFFFFFF006CE3EE
c1643: dq 0x5F0000003EFFFFFF, 0x4EFFFFFF501502F9
c1644: dq 0x3D9C8000BEDB7957, 0xBF5E80017FFF7FFF
c1645: dq 0x7FA000017FA00001, 0x7F8000007FC12345
c1646: dq 0x404000003EFFFFFF, 0x443F88E7501502F9
c1647: dq 0x3B818B0A0000FFFF, 0xFFFF0000FFFF
c1648: dq 0x7FFFFFDF000000, 0x800000CF000000
c1649: dq 0xBF0000002EDBE6FF, 0x5F0000007FC00000
c1650: dq 0xFFFF63199B82, 0x290783B300FF207B
c1651: dq 0x4F0000004B800000, 0xD01502F9C3DA9C13
c1652: dq 0x3EFFFFFFFF800123, 0x4EFFFFFFC35421FC
c1653: dq 0xFFFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c1654: dq 0xC020000080000001, 0xC412FF09007FFFFF
c1655: dq 0xC445A8EE00800000, 0xC47442F800000001
c1656: dq 0xA1080012A332C49, 0xFFFFFFFFC5B97FFF
c1657: dq 0x5F000000007FFFFF, 0xC0F00000C457EB69
c1658: dq 0xC091F14A40200000, 0x440E131ECF000000
c1659: dq 0x80000000000053F6, 0x8A70C8008000EF16
c1660: dq 0xFF800123C41404C1, 0xCF000000C287D5AE
c1661: dq 0x4115DA8D00000001, 0x41B4186D43804843
c1662: dq 0x7FFFBEB380010A14, 0x100800010D50C80
c1663: dq 0x7FC000003EFFFFFF, 0x800000007FC12345
c1664: dq 0x3F800000501502F9, 0xC365EEA5C355EF7B
c1665: dq 0x8000CA8CFFFF86E5, 0xFFFF809F3E420100
c1666: dq 0x40200000FF800000, 0xC357D82D3DCCCCCD
c1667: dq 0x47F12065FF800000, 0x800000014EFFFFFF
c1668: dq 0x100000000, 0xBD4826186284C067
c1669: dq 0xFF80000044049438, 0x7F7FFFFF00000000
c1670: dq 0x4008000000000000, 0x3FF0000000000000
c1671: dq 0x100010000, 0x8000000000010000
c1672: dq 0xFFFFFFFFFFFFF, 0x405CBC351890ABB0
c1673: dq 0x41DFFFFFFFE00000, 0xC037F2646087BDA0
c1674: dq 0x1A07F071C40FF31, 0x2B00818161FF63D6
c1675: dq 0x1, 0x3FF0000000000000
c1676: dq 0x3FDFFFFFFFFFFFFF, 0x3FB999999999999A
c1677: dq 0x1, 0xFFFFFFFFFFFFFFFF
c1678: dq 0xC086A242D1BFC8BA, 0x4084AFC75032A302
c1679: dq 0x7FF0000000000000, 0xC07E5341F6988FF6
c1680: dq 0xABFFFFFE8080F37F, 0x7F007F404081AB01
c1681: dq 0xC004000000000000, 0x401E000000000000
c1682: dq 0x0, 0xFFF0000000000123
c1683: dq 0x1E32B8748DF761E6, 0x699EDB29
c1684: dq 0x7FF8000012345678, 0x3DDB7CDFD9D7BDBB
c1685: dq 0xFFFFFFFFFFFFF, 0x730D67819E8D2
c1686: dq 0x443DBB3A, 0x1EADE8278
c1687: dq 0x41DFFFFFFFE00000, 0x366244CE242C5561
c1688: dq 0xC1E0000000000000, 0x3DDB7CDFD9D7BDBB
c1689: dq 0x1000028EA66E0, 0xFFFFFFFFB6F11D73
c1690: dq 0x366244CE242C5561, 0x7FF0000000000000
c1691: dq 0x730D67819E8D2, 0xC01E000000000000
c1692: dq 0x397F81017F05FF7F, 0x40FF2916947F80
c1693: dq 0x43E0000000000000, 0x401E000000000000
c1694: dq 0x406519354E9B7A98, 0x3FB999999999999A
c1695: dq 0xFED9A44680000000, 0xEE17B34A0F5AC20E
c1696: dq 0x7FF0000000000000, 0xC202A05F20000000
c1697: dq 0xC004000000000000, 0x401E000000000000
c1698: dq 0x124E1D8E, 0x8000000008748413
c1699: dq 0x8000000000000000, 0x7FF8000012345678
c1700: dq 0xFF800000C3EC8CBD, 0x404000002EDBE6FF
c1701: dq 0xFFFF800080017FFF, 0x50C14911FFFFAEC2
c1702: dq 0xC42DD8C041B0B838, 0x7FC00000BF000000
c1703: dq 0xC407EB2CFF800000, 0x41ACFCDC7F7FFFFF
c1704: dq 0x7F3240FF00018C80, 0xFF7FFF81407F01DB
c1705: dq 0x3FC0000000000001, 0x7F800000007FFFFF
c1706: dq 0x80000001BF000000, 0xC020000044389C9D
c1707: dq 0xF83496B200FFFFFF, 0xFFE9FF00FF4D78
c1708: dq 0x7FA0000140200000, 0xC416EA04440B9F07
c1709: dq 0x439FA29B7F7FC99E, 0xD01502F900000001
c1710: dq 0x100000000, 0xCAE848D31868BDE6
c1711: dq 0x440A99D843FAA840, 0xBF8000005F000000
c1712: dq 0x2EDBE6FFC2EFDABA, 0xC36033E800800000
c1713: dq 0x8000000000000000, 0xD543E3BD9665FB06
c1714: dq 0x800000C451424C, 0xC020000040200000
c1715: dq 0x43F057D34F800000, 0xC418C416C0F00000
c1716: dq 0x7FFFFFFFFFFFFFFF, 0x10A41F97927F841D
c1717: dq 0x3F8000003DCCCCCD, 0xCF000000D01502F9
c1718: dq 0xCF000000C2D79281, 0x7FC00000DF000000
c1719: dq 0x101804A018081FF, 0x2980EF77F1BFF00
c1720: dq 0x43BD36FBC46906CE, 0x7FC00000FF800000
c1721: dq 0x3EFFFFFF501502F9, 0xFF8000007FC00000
c1722: dq 0x7DC17FFF0144FF40, 0xFFFFCB40D40189B8
c1723: dq 0xCF000000C109B7B5, 0x80000001C46C68E3
c1724: dq 0x3EFFFFFFC37E1E56, 0x80000001C47389F5
c1725: dq 0xFFFFFFFFFFFFFFFF, 0x100000000
c1726: dq 0xC4327CEED01502F9, 0x440262393EFFFFFF
c1727: dq 0x17F7FFFFF, 0xBF800000C4138FFB
c1728: dq 0x980AB52D460CB3DC, 0x37B07FFF41F07FFF
c1729: dq 0x3FC000007F800000, 0xDF000000006CE3EE
c1730: dq 0x41DFFFFFFFC00000, 0xFFF8000000000000
c1731: dq 0x7FFFFFFFFFFFFFFF, 0xFFFFFFFF
c1732: dq 0xC1E0000000000000, 0xFFF8000000000000
c1733: dq 0x7FEFFFFFFFFFFFFF, 0x41DFFFFFFFE00000
c1734: dq 0x941E0E501EC6EFD5, 0x8F284CF97FFFFFFF
c1735: dq 0x7FF8000000000000, 0x41DFFFFFFFE00000
c1736: dq 0x4340000000000000, 0xC038EE0AD7916BC0
c1737: dq 0xB7C37FFFEFAF24F5, 0x8001B3D5000049C9
c1738: dq 0x4077D30F1DF50F00, 0xC07AE291163AB6A2
c1739: dq 0x0, 0x1
c1740: dq 0x1800080005F27, 0x4036FFFF00FF00FF
c1741: dq 0xC08D9CBF6E77EAE3, 0x406C12B9FABD8870
c1742: dq 0xC08BEC87B7FE42A7, 0x4084B91EAEEA617E
c1743: dq 0xFFF6CF06817D80FF, 0xB6777F40A8008040
c1744: dq 0x43E158E460913D00, 0xFFF0000000000000
c1745: dq 0x3FDFFFFFFFFFFFFF, 0xC083ED7592D8974E
c1746: dq 0x523788FA80000000, 0x1000080000000
c1747: dq 0xC08702F32F5C4232, 0xC0685FDFB43A7854
c1748: dq 0x41DFFFFFFFE00000, 0x7FEFFFFFFFFFFFFF
c1749: dq 0x80000000708FF7E3, 0x80000000DD1D97CA
c1750: dq 0x41F0000000000000, 0x4340000000000000
c1751: dq 0x408D7CC62BEEF0DA, 0xBFF0000000000000
c1752: dq 0x408001FF40FF7FCE, 0x8023804001DD89
c1753: dq 0x0, 0x401E000000000000
c1754: dq 0x730D67819E8D2, 0x0
c1755: dq 0x7FFFFFFF7FFFFFFF, 0x87B0905980000000
c1756: dq 0x7FF8000000000000, 0x366244CE242C5561
c1757: dq 0xFFFFFFFFFFFFF, 0x401E000000000000
c1758: dq 0x800040FF63FF2D81, 0x817F01BA4A400000
c1759: dq 0xC1E0000000000000, 0x7FF8000012345678
c1760: dq 0xFFFF0000FFFF, 0xFFFF7FFFFFFF
c1761: dq 0xFFFFFFFFFFFFFFFF, 0xDC08A78031844DD1
c1762: dq 0x800000001562E24C, 0x0
c1763: dq 0xFFFF00000001, 0xFFFFFFFFFFFF
c1764: dq 0xFFFFFFFF19E50EDC, 0x6B449FDA8015AB2A
c1765: dq 0x9BA95E4C390D0A47, 0x8000000000000000
c1766: dq 0x100000000FFFF, 0xB219CF6BC3A4E401
c1767: dq 0x27F07FFF40408140, 0x7F992C2E01FB7781
c1768: dq 0x833834CB2022B6CC, 0x800000000000FFFF
c1769: dq 0xD4A2297, 0x80000000FFFFFFFF
c1770: dq 0x81009633FF40277A, 0x406480810181FF81
c1771: dq 0xFFFF4E27E51B, 0x100007FFFFFFF
c1772: dq 0x180000000, 0x1000000000001
c1773: dq 0xFF010E81404001FD, 0x181B80000BED940
c1774: dq 0x34CCE2395467BE67, 0xF36A62C900000001
c1775: dq 0xFFFF91A40E7D, 0xFFFF1A6C85C3
c1776: dq 0x54ABBF3B7FFF0100, 0x6AFE68B0FFFF00FF
c1777: dq 0x7F6F7200000001, 0x10000FFFF
c1778: dq 0xD8EDF189FFFFFFFF, 0xFFFFFFFF00010000
c1779: dq 0xBCE20BE74DC130CD, 0xFFFFFFFF3A7E1BA5
c1780: dq 0x1825A7B45, 0x80000000B6D96BFB
c1781: dq 0x8000000000000001, 0x7FFFFFFF0000FFFF
c1782: dq 0xFFA73C7AE000FF, 0xEE8CB27A00FF8000
c1783: dq 0xED65B39200000001, 0xB2B2E8B1862539A1
c1784: dq 0x80000000FFFFFFFF, 0xAF50AD41FFFFFFFF
c1785: dq 0x17FEAF75C, 0xFE2FC305135717C0
c1786: dq 0x973CAE7E3DD30629, 0x1975D8A7FFFFFFFF
c1787: dq 0xC47F6B1800000000, 0xE033109DFFFFFFFF
c1788: dq 0x6653000180018000, 0x146A692999DC6A51
c1789: dq 0x1943DBCD00000000, 0xA7B79F9B3DCE000A
c1790: dq 0x10000956A717B, 0x929109F380000000
c1791: dq 0xF18B00FF01005F29, 0x2A34A8C5F69D00FF
c1792: dq 0xF897266A00000000, 0xE0ADD26E00000001
c1793: dq 0x10000FFFF, 0xFFFFFFFF80000000
c1794: dq 0x7F5D878650A7FF, 0xFA00E839B37F13B8
c1795: dq 0x6FBC057400000001, 0xFFFFFFFF80000000
c1796: dq 0x0, 0x88AEE986906B74BA
c1797: dq 0x1000080000000, 0x7FFFFFFFFFFFFFFF
c1798: dq 0x7FFFFFFF00000000, 0xFFFFFFFF9700901D
c1799: dq 0x6B21A29E00000000, 0xBF00B0F0BB57CE5
c1800: dq 0x24D7EF06E5278001, 0x7FFF00FF034D0100
c1801: dq 0xB4548C16, 0x100000000FFFF
c1802: dq 0x800000007FFFFFFF, 0x7FFFFFFFFDA6767D
c1803: dq 0x76DFEB27FFFFFFFF, 0x80000000ED60F8B9
c1804: dq 0xA27A4C41FFFFFFFF, 0xFFFF
c1805: dq 0xD552F117FFFFFFF, 0x8000000000010000
c1806: dq 0xD47F40018043007F, 0xB102814C196D3642
c1807: dq 0x100008B4CADE4, 0x2094BD097FFFFFFF
c1808: dq 0x1000000000000, 0x65E9210E80000000
c1809: dq 0x408136D26D21357F, 0x81FF810080FF0F40
c1810: dq 0xFFFFFFFF7FFFFFFF, 0xB6C1626400000001
c1811: dq 0x234EA1C677B21FDD, 0x3F505B6E
c1812: dq 0xD41A6F1F0ACB0516, 0x8000000000000000
c1813: dq 0x9AB73B1D9F3F7B24, 0x6EAE3C4476ED21BD
c1814: dq 0xF4B651A50000FFFF, 0xDC59A8DB
c1815: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
c1816: dq 0x7FFFFFFF80000000, 0x74F9EDE100010000
c1817: dq 0x1E5F9B3800000001, 0xFFFF00010000
c1818: dq 0xFFFFFFFF, 0x7FFFFFFFFFFFFFFF
c1819: dq 0x7FFFFFFF80000000, 0xFFFFFFFFFFFFFFFF
c1820: dq 0x0, 0x8000000000000000
c1821: dq 0x8000000000000000, 0x0
c1822: dq 0x0, 0x8000000000000000
c1823: dq 0x8000000000000000, 0x0
c1824: dq 0x0, 0x8000000000000000
c1825: dq 0x8000000000000000, 0x0
c1826: dq 0x3FF0000000000000, 0x3FF0000000000000
c1827: dq 0x3FF0000000000000, 0x3FF0000000000000
c1828: dq 0x3FF0000000000000, 0x3FF0000000000000
c1829: dq 0x8000000000000000, 0x80000000
c1830: dq 0x80000000, 0x8000000000000000
c1831: dq 0x8000000000000000, 0x80000000
c1832: dq 0x80000000, 0x8000000000000000
c1833: dq 0x8000000000000000, 0x80000000
c1834: dq 0x80000000, 0x8000000000000000
c1835: dq 0x3F8000003F800000, 0x3F8000003F800000
c1836: dq 0x3F8000003F800000, 0x3F8000003F800000
c1837: dq 0x3F8000003F800000, 0x3F8000003F800000
c1838: dq 0x0, 0x8000000000000000
c1839: dq 0x8000000000000000, 0x0
c1840: dq 0x0, 0x8000000000000000
c1841: dq 0x8000000000000000, 0x0
c1842: dq 0x0, 0x8000000000000000
c1843: dq 0x8000000000000000, 0x0
c1844: dq 0x3FF0000000000000, 0x3FF0000000000000
c1845: dq 0x3FF0000000000000, 0x3FF0000000000000
c1846: dq 0x3FF0000000000000, 0x3FF0000000000000
c1847: dq 0x8000000000000000, 0x80000000
c1848: dq 0x80000000, 0x8000000000000000
c1849: dq 0x8000000000000000, 0x80000000
c1850: dq 0x80000000, 0x8000000000000000
c1851: dq 0x8000000000000000, 0x80000000
c1852: dq 0x80000000, 0x8000000000000000
c1853: dq 0x3F8000003F800000, 0x3F8000003F800000
c1854: dq 0x3F8000003F800000, 0x3F8000003F800000
c1855: dq 0x3F8000003F800000, 0x3F8000003F800000
c1856: dq 0x7FF8000000000000, 0x3FF0000000000000
c1857: dq 0x3FF0000000000000, 0x7FF8000000000000
c1858: dq 0x3FF0000000000000, 0x4000000000000000
c1859: dq 0x3FF0000000000000, 0x3FF0000000000000
c1860: dq 0x7FF8000000000000, 0x0
c1861: dq 0x3F8000007FC00000, 0x400000003F800000
c1862: dq 0x7FC000003F800000, 0x3F8000003F800000
c1863: dq 0x3F800000, 0x0
c1864: dq 0x7FC00000, 0x0
c1865: dq 0x7FF8000000000000, 0x3FF0000000000000
c1866: dq 0x3FF0000000000000, 0x7FF8000000000000
c1867: dq 0x3FF0000000000000, 0x4000000000000000
c1868: dq 0x3FF0000000000000, 0x3FF0000000000000
c1869: dq 0x7FF8000000000000, 0x0
c1870: dq 0x3F8000007FC00000, 0x400000003F800000
c1871: dq 0x7FC000003F800000, 0x3F8000003F800000
c1872: dq 0x3F800000, 0x0
c1873: dq 0x7FC00000, 0x0
c1874: dq 0x7FF8000000000000, 0x3FF0000000000000
c1875: dq 0x3FF0000000000000, 0x7FF8000000000000
c1876: dq 0x3FF0000000000000, 0x4000000000000000
c1877: dq 0x3FF0000000000000, 0x3FF0000000000000
c1878: dq 0x7FF8000000000000, 0x0
c1879: dq 0x3F8000007FC00000, 0x400000003F800000
c1880: dq 0x7FC000003F800000, 0x3F8000003F800000
c1881: dq 0x3F800000, 0x0
c1882: dq 0x7FC00000, 0x0
c1883: dq 0x7FF8000000000000, 0x3FF0000000000000
c1884: dq 0x3FF0000000000000, 0x7FF8000000000000
c1885: dq 0x3FF0000000000000, 0x4000000000000000
c1886: dq 0x3FF0000000000000, 0x3FF0000000000000
c1887: dq 0x7FF8000000000000, 0x0
c1888: dq 0x3F8000007FC00000, 0x400000003F800000
c1889: dq 0x7FC000003F800000, 0x3F8000003F800000
c1890: dq 0x3F800000, 0x0
c1891: dq 0x7FC00000, 0x0
c1892: dq 0x7FF8000000000000, 0x3FF0000000000000
c1893: dq 0x3FF0000000000000, 0x7FF8000000000000
c1894: dq 0x3FF0000000000000, 0x4000000000000000
c1895: dq 0x3FF0000000000000, 0x3FF0000000000000
c1896: dq 0x7FF8000000000000, 0x0
c1897: dq 0x3F8000007FC00000, 0x400000003F800000
c1898: dq 0x7FC000003F800000, 0x3F8000003F800000
c1899: dq 0x3F800000, 0x0
c1900: dq 0x7FC00000, 0x0
c1901: dq 0x7FF8000000000000, 0x3FF0000000000000
c1902: dq 0x3FF0000000000000, 0x7FF8000000000000
c1903: dq 0x3FF0000000000000, 0x4000000000000000
c1904: dq 0x3FF0000000000000, 0x3FF0000000000000
c1905: dq 0x7FF8000000000000, 0x0
c1906: dq 0x3F8000007FC00000, 0x400000003F800000
c1907: dq 0x7FC000003F800000, 0x3F8000003F800000
c1908: dq 0x3F800000, 0x0
c1909: dq 0x7FC00000, 0x0
c1910: dq 0x7FF8000000000000, 0x3FF0000000000000
c1911: dq 0x3FF0000000000000, 0x7FF8000000000000
c1912: dq 0x3FF0000000000000, 0x4000000000000000
c1913: dq 0x3FF0000000000000, 0x3FF0000000000000
c1914: dq 0x7FF8000000000000, 0x0
c1915: dq 0x3F8000007FC00000, 0x400000003F800000
c1916: dq 0x7FC000003F800000, 0x3F8000003F800000
c1917: dq 0x3F800000, 0x0
c1918: dq 0x7FC00000, 0x0
c1919: dq 0x7FF8000000000000, 0x3FF0000000000000
c1920: dq 0x3FF0000000000000, 0x7FF8000000000000
c1921: dq 0x3FF0000000000000, 0x4000000000000000
c1922: dq 0x3FF0000000000000, 0x3FF0000000000000
c1923: dq 0x7FF8000000000000, 0x0
c1924: dq 0x3F8000007FC00000, 0x400000003F800000
c1925: dq 0x7FC000003F800000, 0x3F8000003F800000
c1926: dq 0x3F800000, 0x0
c1927: dq 0x7FC00000, 0x0
buf: times 64 dq 0x0123456789ABCDEF
file_end:
