; s_invlpg again on pages whose numbers do not fit in eight bits (E090): 370000h and the two
; after it. The TLB finds an entry by the page number's low bits, and INVLPG and a write
; of CR3 have to look where the entry is.
%define TPAGE 0x370
%include "s_invlpg.asm"
