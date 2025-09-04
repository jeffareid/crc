;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Copyright(c) 2011-2019 Intel Corporation All rights reserved.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
;    * Redistributions of source code must retain the above copyright
;      notice, this list of conditions and the following disclaimer.
;    * Redistributions in binary form must reproduce the above copyright
;      notice, this list of conditions and the following disclaimer in
;      the documentation and/or other materials provided with the
;      distribution.
;    * Neither the name of Intel Corporation nor the names of its
;      contributors may be used to endorse or promote products derived
;      from this software without specific prior written permission.
;
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Function API:
;       uint64_t crz64ra(
;               uint64_t init_crc, //initial CRC value, 64 bits
;               const unsigned char *buf, //buffer pointer to calculate CRC on
;               uint64_t len //buffer length in bytes (64-bit data)
;       );
;
%include "reg_sizes.asm"

%ifndef FUNCTION_NAME
%define FUNCTION_NAME crz64ra
%endif

%define fetch_dist      1024

[bits 64]
default rel

section .data
align 32

%if 1
;                                       ;crc64  iso, bits reversed
rk_1:   dq      0x45000000b0000000      ;2^((64*32)-1) mod P(x)
rk_2:   dq      0x6b700000f5000000      ;2^((64*33)-1) mod P(x)
rk01:   dq      0xf500000000000001      ;2^((64* 2)-1) mod P(x)
rk02:   dq      0x6b70000000000001      ;2^((64* 3)-1) mod P(x)
rk03:   dq      0xb001000000010000      ;2^((64*16)-1) mod P(x)
rk04:   dq      0xf501b0000001b000      ;2^((64*17)-1) mod P(x)
rk05:   dq      0xf500000000000001      ;2^((64* 2)-1) mod P(x)
rk06:   dq      0x0000000000000000      ;2^((64* 1)-1) mod P(x)
rk07:   dq      0xb000000000000001      ;floor((2^127)/(P(x))
rk08:   dq      0xb000000000000000      ;P(x) - 1
rk09:   dq      0xe014514514501501      ;2^((64*14)-1) mod P(x)
rk10    dq      0x771db6db6db71c71      ;2^((64*15)-1) mod P(x)
rk11    dq      0xa101101101110001      ;2^((64*12)-1) mod P(x)
rk12    dq      0x1ab1ab1ab1aab001      ;2^((64*13)-1) mod P(x)
rk13    dq      0xf445014445000001      ;2^((64*10)-1) mod P(x)
rk14    dq      0x6aab71daab700001      ;2^((64*11)-1) mod P(x)
rk15    dq      0xb100010100000001      ;2^((64* 8)-1) mod P(x)
rk16    dq      0x01b001b1b0000001      ;2^((64* 9)-1) mod P(x)
rk17    dq      0xe145150000000001      ;2^((64* 6)-1) mod P(x)
rk18    dq      0x76db6c7000000001      ;2^((64* 7)-1) mod P(x)
rk19    dq      0xa011000000000001      ;2^((64* 4)-1) mod P(x)
rk20    dq      0x1b1ab00000000001      ;2^((64* 5)-1) mod P(x)
        dq      0xf500000000000001      ;2^((64* 2)-1) mod P(x)
        dq      0x6b70000000000001      ;2^((64* 3)-1) mod P(x)
        dq      0x0000000000000000
        dq      0x0000000000000000
%else
;                                       ;crc64 ecma, bits reversed
rk_1:   dq      0xf31fd9271e228b79      ;2^((64*32)-1) mod P(x)
rk_2:   dq      0x8260adf2381ad81c      ;2^((64*33)-1) mod P(x)
rk01:   dq      0xdabe95afc7875f40      ;2^((64* 2)-1) mod P(x)
rk02:   dq      0xe05dd497ca393ae4      ;2^((64* 3)-1) mod P(x)
rk03:   dq      0xd7d86b2af73de740      ;2^((64*16)-1) mod P(x)
rk04:   dq      0x8757d71d4fcc1000      ;2^((64*17)-1) mod P(x)
rk05:   dq      0xdabe95afc7875f40      ;2^((64* 2)-1) mod P(x)
rk06:   dq      0x0000000000000000      ;2^((64* 1)-1) mod P(x)
rk07:   dq      0x9c3e466c172963d5      ;floor((2^127)/(P(x))
rk08:   dq      0x92d8af2baf0e1e84      ;P(x) - 1
rk09:   dq      0x947874de595052cb      ;2^((64*14)-1) mod P(x)
rk10:   dq      0x9e735cb59b4724da      ;2^((64*15)-1) mod P(x)
rk11:   dq      0xe4ce2cd55fea0037      ;2^((64*12)-1) mod P(x)
rk12:   dq      0x2fe3fd2920ce82ec      ;2^((64*13)-1) mod P(x)
rk13:   dq      0x0e31d519421a63a5      ;2^((64*10)-1) mod P(x)
rk14:   dq      0x2e30203212cac325      ;2^((64*11)-1) mod P(x)
rk15:   dq      0x081f6054a7842df4      ;2^((64* 8)-1) mod P(x)
rk16:   dq      0x6ae3efbb9dd441f3      ;2^((64* 9)-1) mod P(x)
rk17:   dq      0x69a35d91c3730254      ;2^((64* 6)-1) mod P(x)
rk18:   dq      0xb5ea1af9c013aca4      ;2^((64* 7)-1) mod P(x)
rk19:   dq      0x3be653a30fe1af51      ;2^((64* 4)-1) mod P(x)
rk20:   dq      0x60095b008a9efa44      ;2^((64* 5)-1) mod P(x)
        dq      0xdabe95afc7875f40      ;2^((64* 2)-1) mod P(x)
        dq      0xe05dd497ca393ae4      ;2^((64* 3)-1) mod P(x)
        dq      0x0000000000000000
        dq      0x0000000000000000
%endif

pshufb_shf_table:
; use these values for shift constants for the pshufb instruction
; different alignments result in values as shown:
;       dq 0x8887868584838281, 0x008f8e8d8c8b8a89 ; shl 15 (16-1) / shr1
;       dq 0x8988878685848382, 0x01008f8e8d8c8b8a ; shl 14 (16-3) / shr2
;       dq 0x8a89888786858483, 0x0201008f8e8d8c8b ; shl 13 (16-4) / shr3
;       dq 0x8b8a898887868584, 0x030201008f8e8d8c ; shl 12 (16-4) / shr4
;       dq 0x8c8b8a8988878685, 0x04030201008f8e8d ; shl 11 (16-5) / shr5
;       dq 0x8d8c8b8a89888786, 0x0504030201008f8e ; shl 10 (16-6) / shr6
;       dq 0x8e8d8c8b8a898887, 0x060504030201008f ; shl 9  (16-7) / shr7
;       dq 0x8f8e8d8c8b8a8988, 0x0706050403020100 ; shl 8  (16-8) / shr8
;       dq 0x008f8e8d8c8b8a89, 0x0807060504030201 ; shl 7  (16-9) / shr9
;       dq 0x01008f8e8d8c8b8a, 0x0908070605040302 ; shl 6  (16-10) / shr10
;       dq 0x0201008f8e8d8c8b, 0x0a09080706050403 ; shl 5  (16-11) / shr11
;       dq 0x030201008f8e8d8c, 0x0b0a090807060504 ; shl 4  (16-12) / shr12
;       dq 0x04030201008f8e8d, 0x0c0b0a0908070605 ; shl 3  (16-13) / shr13
;       dq 0x0504030201008f8e, 0x0d0c0b0a09080706 ; shl 2  (16-14) / shr14
;       dq 0x060504030201008f, 0x0e0d0c0b0a090807 ; shl 1  (16-15) / shr15
dq 0x8786858483828100, 0x8f8e8d8c8b8a8988
dq 0x0706050403020100, 0x000e0d0c0b0a0908

mask:  dq     0xFFFFFFFFFFFFFFFF, 0x0000000000000000
mask2: dq     0xFFFFFFFF00000000, 0xFFFFFFFFFFFFFFFF
mask3: dq     0x8080808080808080, 0x8080808080808080

section .text

%ifidn __OUTPUT_FORMAT__, win64
        %xdefine        arg1 rcx
        %xdefine        arg2 rdx
        %xdefine        arg3 r8
%else
        %xdefine        arg1 rdi
        %xdefine        arg2 rsi
        %xdefine        arg3 rdx
%endif

%define TMP 16*0
%ifidn __OUTPUT_FORMAT__, win64
        %define XMM_SAVE 16*2
        %define VARIABLE_OFFSET 16*12+8
%else
        %define VARIABLE_OFFSET 16*2+8
%endif

align 16
mk_global FUNCTION_NAME, function
FUNCTION_NAME:
        endbranch
;       not             arg1            ; caller does pre complement
        sub             rsp, VARIABLE_OFFSET

%ifidn __OUTPUT_FORMAT__, win64
        ; push the xmm registers into the stack to maintain
        vmovdqa         [rsp + XMM_SAVE + 16*0], xmm6
        vmovdqa         [rsp + XMM_SAVE + 16*1], xmm7
        vmovdqa         [rsp + XMM_SAVE + 16*2], xmm8
        vmovdqa         [rsp + XMM_SAVE + 16*3], xmm9
        vmovdqa         [rsp + XMM_SAVE + 16*4], xmm10
        vmovdqa         [rsp + XMM_SAVE + 16*5], xmm11
        vmovdqa         [rsp + XMM_SAVE + 16*6], xmm12
        vmovdqa         [rsp + XMM_SAVE + 16*7], xmm13
        vmovdqa         [rsp + XMM_SAVE + 16*8], xmm14
        vmovdqa         [rsp + XMM_SAVE + 16*9], xmm15
%endif

        cmp             arg3, 256
        jl              _less_than_256

        ; load the initial crc value
        vmovq           xmm10, arg1      ; initial crc

        ; receive the initial 128B data, xor the initial crc value
        vmovdqu8        zmm0, [arg2+16*0]
        vmovdqu8        zmm4, [arg2+16*4]
        vpxorq          zmm0, zmm10
        vbroadcasti32x4 zmm10, [rk03]   ;zmm10 has rk03 and rk04
                                        ;imm value of pclmulqdq instruction will determine which constant to use

        sub             arg3, 256
        cmp             arg3, 256
        jl              _fold_128_B_loop

        vmovdqu8        zmm7, [arg2+16*8]
        vmovdqu8        zmm8, [arg2+16*12]
        vbroadcasti32x4 zmm16, [rk_1]   ;zmm16 has rk-1 and rk-2
        sub             arg3, 256

_fold_256_B_loop:
        add             arg2, 256
        vpclmulqdq      zmm1, zmm0, zmm16, 0x10
        vpclmulqdq      zmm0, zmm0, zmm16, 0x01
        vpternlogq      zmm0, zmm1, [arg2+16*0], 0x96

        vpclmulqdq      zmm2, zmm4, zmm16, 0x10
        vpclmulqdq      zmm4, zmm4, zmm16, 0x01
        vpternlogq      zmm4, zmm2, [arg2+16*4], 0x96

        vpclmulqdq      zmm3, zmm7, zmm16, 0x10
        vpclmulqdq      zmm7, zmm7, zmm16, 0x01
        vpternlogq      zmm7, zmm3, [arg2+16*8], 0x96

        vpclmulqdq      zmm5, zmm8, zmm16, 0x10
        vpclmulqdq      zmm8, zmm8, zmm16, 0x01
        vpternlogq      zmm8, zmm5, [arg2+16*12], 0x96

        sub             arg3, 256
        jge             _fold_256_B_loop

        ;; Fold 256 into 128
        add             arg2, 256
        vpclmulqdq      zmm1, zmm0, zmm10, 0x01
        vpclmulqdq      zmm2, zmm0, zmm10, 0x10
        vpternlogq      zmm7, zmm1, zmm2, 0x96  ; xor ABC

        vpclmulqdq      zmm5, zmm4, zmm10, 0x01
        vpclmulqdq      zmm6, zmm4, zmm10, 0x10
        vpternlogq      zmm8, zmm5, zmm6, 0x96  ; xor ABC

        vmovdqa32       zmm0, zmm7
        vmovdqa32       zmm4, zmm8

        add             arg3, 128
        jmp             _fold_128_B_register

        ; fold 128B at a time. This section of the code folds 2 zmm registers in parallel
_fold_128_B_loop:
        add             arg2, 128       ; update the buffer pointer
        vpclmulqdq      zmm1, zmm0, zmm10, 0x10
        vpclmulqdq      zmm0, zmm0, zmm10, 0x01
        vpternlogq      zmm0, zmm1, [arg2+16*0], 0x96

        vpclmulqdq      zmm5, zmm4, zmm10, 0x10
        vpclmulqdq      zmm4, zmm4, zmm10, 0x01
        vpternlogq      zmm4, zmm5, [arg2+16*4], 0x96

        sub             arg3, 128
        jge             _fold_128_B_loop
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        add     arg2, 128
        ; at this point, the buffer pointer is pointing at the last y Bytes of the buffer, where 0 <= y < 128
        ; the 128B of folded data is in 2 zmm registers: zmm0, zmm4

_fold_128_B_register:
        ; fold the 8 128b parts into 1 xmm register with different constants
        vmovdqu8        zmm16, [rk09]           ; multiply by rk09-rk16
        vmovdqu8        zmm11, [rk17]           ; multiply by rk17-rk20, rk01,rk02, 0,0
        vpclmulqdq      zmm1, zmm0, zmm16, 0x01
        vpclmulqdq      zmm2, zmm0, zmm16, 0x10
        vextracti64x2   xmm7, zmm4, 3           ; save last that has no multiplicand

        vpclmulqdq      zmm5, zmm4, zmm11, 0x01
        vpclmulqdq      zmm6, zmm4, zmm11, 0x10
        vmovdqa         xmm10, [rk01]           ; Needed later in reduction loop
        vpternlogq      zmm1, zmm2, zmm5, 0x96  ; xor ABC
        vpternlogq      zmm1, zmm6, zmm7, 0x96  ; xor ABC

        vshufi64x2      zmm8, zmm1, zmm1, 0x4e ; Swap 1,0,3,2 - 01 00 11 10
        vpxorq          ymm8, ymm8, ymm1
        vextracti64x2   xmm5, ymm8, 1
        vpxorq          xmm7, xmm5, xmm8

        ; instead of 128, we add 128-16 to the loop counter to save 1 instruction from the loop
        ; instead of a cmp instruction, we use the negative flag with the jl instruction
        add             arg3, 128-16
        jl              _final_reduction_for_128

        ; now we have 16+y bytes left to reduce. 16 Bytes is in register xmm7 and the rest is in memory
        ; we can fold 16 bytes at a time if y>=16
        ; continue folding 16B at a time

_16B_reduction_loop:
        vmovdqa         xmm8, xmm7
        vpclmulqdq      xmm7, xmm10, 0x1
        vpclmulqdq      xmm8, xmm10, 0x10
        vpxor           xmm7, xmm8
        vmovdqu         xmm0, [arg2]
        vpxor           xmm7, xmm0
        add             arg2, 16
        sub             arg3, 16
        ; instead of a cmp instruction, we utilize the flags with the jge instruction
        ; equivalent of: cmp arg3, 16-16
        ; check if there is any more 16B in the buffer to be able to fold
        jge             _16B_reduction_loop

        ;now we have 16+z bytes left to reduce, where 0<= z < 16.
        ;first, we reduce the data in the xmm7 register


_final_reduction_for_128:
        add             arg3, 16
        je              _128_done
        ; here we are getting data that is less than 16 bytes.
        ; since we know that there was data before the pointer, we can offset
        ; the input pointer before the actual point, to receive exactly 16 bytes.
        ; after that the registers need to be adjusted.
_get_last_two_xmms:


        vmovdqa         xmm2, xmm7
        vmovdqu         xmm1, [arg2 - 16 + arg3]

        ; get rid of the extra data that was loaded before
        ; load the shift constant
        lea             rax, [pshufb_shf_table]
        add             rax, arg3
        vmovdqu         xmm0, [rax]


        vpshufb         xmm7, xmm0
        vpxor           xmm0, [mask3]
        vpshufb         xmm2, xmm0

        vpblendvb       xmm2, xmm2, xmm1, xmm0
        ;;;;;;;;;;
        vmovdqa         xmm8, xmm7
        vpclmulqdq      xmm7, xmm10, 0x1

        vpclmulqdq      xmm8, xmm10, 0x10
        vpxor           xmm7, xmm8
        vpxor           xmm7, xmm2

_128_done:
        ; compute crc of a 128-bit value
        vmovdqa         xmm10, [rk05]
        vmovdqa         xmm0, xmm7

        ;64b fold
        vpclmulqdq      xmm7, xmm10, 0
        vpsrldq         xmm0, 8
        vpxor           xmm7, xmm0

        ;barrett reduction
_barrett:
        vmovdqa         xmm1, xmm7
        vmovdqa         xmm10, [rk07]

        vpclmulqdq      xmm7, xmm10, 0
        vmovdqa         xmm2, xmm7
        vpclmulqdq      xmm7, xmm10, 0x10
        vpslldq         xmm2, 8
        vpxor           xmm7, xmm2
        vpxor           xmm7, xmm1
        vpextrq         rax, xmm7, 1

_cleanup:
;       not             rax             ; caller does post complement

%ifidn __OUTPUT_FORMAT__, win64
        vmovdqa         xmm6, [rsp + XMM_SAVE + 16*0]
        vmovdqa         xmm7, [rsp + XMM_SAVE + 16*1]
        vmovdqa         xmm8, [rsp + XMM_SAVE + 16*2]
        vmovdqa         xmm9, [rsp + XMM_SAVE + 16*3]
        vmovdqa         xmm10, [rsp + XMM_SAVE + 16*4]
        vmovdqa         xmm11, [rsp + XMM_SAVE + 16*5]
        vmovdqa         xmm12, [rsp + XMM_SAVE + 16*6]
        vmovdqa         xmm13, [rsp + XMM_SAVE + 16*7]
        vmovdqa         xmm14, [rsp + XMM_SAVE + 16*8]
        vmovdqa         xmm15, [rsp + XMM_SAVE + 16*9]
%endif
        add             rsp, VARIABLE_OFFSET
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 16
_less_than_256:

        ; check if there is enough buffer to be able to fold 16B at a time
        cmp     arg3, 32
        jl      _less_than_32

        ; if there is, load the constants
        vmovdqa xmm10, [rk01]   ; rk01 and rk02 in xmm10

        vmovq   xmm0, arg1      ; get the initial crc value
        vmovdqu xmm7, [arg2]    ; load the plaintext
        vpxor   xmm7, xmm0

        ; update the buffer pointer
        add     arg2, 16

        ; update the counter. subtract 32 instead of 16 to save one instruction from the loop
        sub     arg3, 32

        jmp     _16B_reduction_loop

align 16
_less_than_32:
        ; mov initial crc to the return value. this is necessary for zero-length buffers.
        mov     rax, arg1
        test    arg3, arg3
        je      _cleanup

        vmovq   xmm0, arg1      ; get the initial crc value

        cmp     arg3, 16
        je      _exact_16_left
        jl      _less_than_16_left

        vmovdqu xmm7, [arg2]    ; load the plaintext
        vpxor   xmm7, xmm0      ; xor the initial crc value
        add     arg2, 16
        sub     arg3, 16
        vmovdqa xmm10, [rk01]   ; rk01 and rk02 in xmm10
        jmp     _get_last_two_xmms


align 16
_less_than_16_left:
        ; use stack space to load data less than 16 bytes, zero-out the 16B in memory first.

        vpxor   xmm1, xmm1
        mov     r11, rsp
        vmovdqa [r11], xmm1

        ; backup the counter value
        mov     r9, arg3
        cmp     arg3, 8
        jl      _less_than_8_left

        ; load 8 Bytes
        mov     rax, [arg2]
        mov     [r11], rax
        add     r11, 8
        sub     arg3, 8
        add     arg2, 8
_less_than_8_left:

        cmp     arg3, 4
        jl      _less_than_4_left

        ; load 4 Bytes
        mov     eax, [arg2]
        mov     [r11], eax
        add     r11, 4
        sub     arg3, 4
        add     arg2, 4
_less_than_4_left:

        cmp     arg3, 2
        jl      _less_than_2_left

        ; load 2 Bytes
        mov     ax, [arg2]
        mov     [r11], ax
        add     r11, 2
        sub     arg3, 2
        add     arg2, 2
_less_than_2_left:
        cmp     arg3, 1
        jl      _zero_left

        ; load 1 Byte
        mov     al, [arg2]
        mov     [r11], al

_zero_left:
        vmovdqa xmm7, [rsp]
        vpxor   xmm7, xmm0      ; xor the initial crc value

        lea     rax,[pshufb_shf_table]

        cmp     r9, 8
        jl      _end_1to7

_end_8to15:
        vmovdqu xmm0, [rax + r9]
        vpshufb xmm7,xmm0
        jmp     _128_done

_end_1to7:
        ; Left shift (8-length) bytes in XMM
        vmovdqu xmm0, [rax + r9 + 8]
        vpshufb xmm7,xmm0

        jmp     _barrett

align 16
_exact_16_left:
        vmovdqu xmm7, [arg2]
        vpxor   xmm7, xmm0      ; xor the initial crc value

        jmp     _128_done

