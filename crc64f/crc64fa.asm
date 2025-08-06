        title   crc32fa
;       page    80,132
;-----------------------------------------------------------------------;
;       crc64fa.asm     fast 64 bit crc                                 ;
;-----------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Copyright(c) 2011-2016 Intel Corporation All rights reserved.
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

STK_ALC equ     168             ; stack alloc size (rsp -= STK_ALC)
fetch_dist equ  1024            ; for prefecth

;-----------------------------------------------------------------------;
;       DATA                                                            ;
;-----------------------------------------------------------------------;
        .data

        align 16
        if 0
;                                       ;crc64 iso
rk01    dq 00000000000000145h           ;2^(64* 2) mod P(x)
rk02    dq 00000000000001db7h           ;2^(64* 3) mod P(x)
rk03    dq 0000100000001001ah           ;2^(64*16) mod P(x)
rk04    dq 0001b0000001b015eh           ;2^(64*17) mod P(x)
rk05    dq 00000000000000145h           ;2^(64* 2) mod P(x)
rk06    dq 00000000000000000h           ;2^(64* 1) mod P(x)
rk07    dq 0000000000000001bh           ;floor(2^128/P(x)) - 2^64
rk08    dq 0000000000000001bh           ;P(x) - 2^64
rk09    dq 00150145145145015h           ;2^(64*14) mod P(x)
rk10    dq 01c71db6db6db71c7h           ;2^(64*15) mod P(x)
rk11    dq 00001110110110111h           ;2^(64*12) mod P(x)
rk12    dq 0001aab1ab1ab1aabh           ;2^(64*13) mod P(x)
rk13    dq 00000014445014445h           ;2^(64*10) mod P(x)
rk14    dq 000001daab71daab7h           ;2^(64*11) mod P(x)
rk15    dq 00000000101000101h           ;2^(64* 8) mod P(x)
rk16    dq 00000001b1b001b1bh           ;2^(64* 9) mod P(x)
rk17    dq 00000000001514515h           ;2^(64* 6) mod P(x)
rk18    dq 0000000001c6db6c7h           ;2^(64* 7) mod P(x)
rk19    dq 00000000000011011h           ;2^(64* 4) mod P(x)
rk20    dq 000000000001ab1abh           ;2^(64* 5) mod P(x)

        else
;                                       ;crc64 ecma
rk01    dq 005f5c3c7eb52fab6h           ;2^(64* 2) mod P(x)
rk02    dq 04eb938a7d257740eh           ;2^(64* 3) mod P(x)
rk03    dq 005cf79dea9ac37d6h           ;2^(64*16) mod P(x)
rk04    dq 0001067e571d7d5c2h           ;2^(64*17) mod P(x)
rk05    dq 005f5c3c7eb52fab6h           ;2^(64* 2) mod P(x)
rk06    dq 00000000000000000h           ;2^(64* 1) mod P(x)
rk07    dq 0578d29d06cc4f872h           ;floor(2^128/P(x)) - 2^64
rk08    dq 042f0e1eba9ea3693h           ;P(x) - 2^64
rk09    dq 0e464f4df5fb60ac1h           ;2^(64*14) mod P(x)
rk10    dq 0b649c5b35a759cf2h           ;2^(64*15) mod P(x)
rk11    dq 09af04e1eff82d0ddh           ;2^(64*12) mod P(x)
rk12    dq 06e82e609297f8fe8h           ;2^(64*13) mod P(x)
rk13    dq 0097c516e98bd2e73h           ;2^(64*10) mod P(x)
rk14    dq 00b76477b31e22e7bh           ;2^(64*11) mod P(x)
rk15    dq 05f6843ca540df020h           ;2^(64* 8) mod P(x)
rk16    dq 0ddf4b6981205b83fh           ;2^(64* 9) mod P(x)
rk17    dq 054819d8713758b2ch           ;2^(64* 6) mod P(x)
rk18    dq 04a6b90073eb0af5ah           ;2^(64* 7) mod P(x)
rk19    dq 0571bee0a227ef92bh           ;2^(64* 4) mod P(x)
rk20    dq 044bef2a201b5200ch           ;2^(64* 5) mod P(x)

        endif

mask1   dq 08080808080808080h, 08080808080808080h
mask2   dq 0ffffffffffffffffh, 000000000ffffffffh
mask3   dq 00000000000000000h, 0ffffffffffffffffh

smask   dq 008090a0b0c0d0e0fh, 00001020304050607h

psbtbl  dq 08786858483828100h, 08f8e8d8c8b8a8988h
        dq 00706050403020100h, 00f0e0d0c0b0a0908h
        dq 08080808080808080h, 00f0e0d0c0b0a0908h
        dq 08080808080808080h, 08080808080808080h

;-----------------------------------------------------------------------;
;       code SEGMENT                                                    ;
;-----------------------------------------------------------------------;
        PUBLIC  crc64f
        .code
        align 16
        ;       r8  = bfr size (in bytes)
        ;       rdx = ptr to bfr
        ;       rcx = initial crc 

crc64f  proc

        sub     rsp, STK_ALC
        ; push the xmm registers into the stack
        movdqa [rsp+16*2],xmm6
        movdqa [rsp+16*3],xmm7
        movdqa [rsp+16*4],xmm8
        movdqa [rsp+16*5],xmm9
        movdqa [rsp+16*6],xmm10
        movdqa [rsp+16*7],xmm11
        movdqa [rsp+16*8],xmm12
        movdqa [rsp+16*9],xmm13

        ; check if smaller than 256
        cmp     r8, 256

        ; for sizes less than 256, we can't fold 128B at a time...
        jl      _less_than_256

        ; load the initial crc value
        movd    xmm10, rcx      ; (ML translates to movq) initial crc

        ; crc value does not need to be byte-reflected, but it needs to be moved to the high part of the register.
        ; because data will be byte-reflected and will align with initial crc at correct place.
        pslldq  xmm10, 8

        movdqa xmm11, xmmword ptr smask
        ; receive the initial 128B data, xor the initial crc value
        movdqu  xmm0, [rdx+16*0]
        movdqu  xmm1, [rdx+16*1]
        movdqu  xmm2, [rdx+16*2]
        movdqu  xmm3, [rdx+16*3]
        movdqu  xmm4, [rdx+16*4]
        movdqu  xmm5, [rdx+16*5]
        movdqu  xmm6, [rdx+16*6]
        movdqu  xmm7, [rdx+16*7]

        pshufb  xmm0, xmm11
        ; XOR the initial_crc value
        pxor    xmm0, xmm10
        pshufb  xmm1, xmm11
        pshufb  xmm2, xmm11
        pshufb  xmm3, xmm11
        pshufb  xmm4, xmm11
        pshufb  xmm5, xmm11
        pshufb  xmm6, xmm11
        pshufb  xmm7, xmm11

        movdqa  xmm10, xmmword ptr rk03 ;xmm10 has rk03 and rk04
                                ;imm value of pclmulqdq instruction will determine which constant to use
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; we subtract 256 instead of 128 to save one instruction from the loop
        sub     r8, 256

        ; at this section of the code, there is 128*x+y (0<=y<128) bytes of buffer. The _fold_128_B_loop
        ; loop will fold 128B at a time until we have 128+y Bytes of buffer


        ; fold 128B at a time. This section of the code folds 8 xmm registers in parallel
_fold_128_B_loop:

        ; update the buffer pointer
        add     rdx, 128                ;    buf += 128;

        prefetchnta [rdx+fetch_dist+0]
        movdqu  xmm9,  [rdx+16*0]
        movdqu  xmm12, [rdx+16*1]
        pshufb  xmm9,   xmm11
        pshufb  xmm12,  xmm11
        movdqa  xmm8,   xmm0
        movdqa  xmm13,  xmm1
        pclmulqdq xmm0, xmm10, 000h
        pclmulqdq xmm8, xmm10, 011h
        pclmulqdq xmm1, xmm10, 000h
        pclmulqdq xmm13,xmm10, 011h
        pxor    xmm0,   xmm9
        xorps   xmm0,   xmm8
        pxor    xmm1,   xmm12
        xorps   xmm1,   xmm13

        prefetchnta     [rdx+fetch_dist+32]
        movdqu  xmm9,   [rdx+16*2]
        movdqu  xmm12,  [rdx+16*3]
        pshufb  xmm9,   xmm11
        pshufb  xmm12,  xmm11
        movdqa  xmm8,   xmm2
        movdqa  xmm13,  xmm3
        pclmulqdq xmm2, xmm10, 000h
        pclmulqdq xmm8, xmm10, 011h
        pclmulqdq xmm3, xmm10, 000h
        pclmulqdq xmm13,xmm10, 011h
        pxor    xmm2,   xmm9
        xorps   xmm2,   xmm8
        pxor    xmm3,   xmm12
        xorps   xmm3,   xmm13

        prefetchnta     [rdx+fetch_dist+64]
        movdqu  xmm9,   [rdx+16*4]
        movdqu  xmm12,  [rdx+16*5]
        pshufb  xmm9,   xmm11
        pshufb  xmm12,  xmm11
        movdqa  xmm8,   xmm4
        movdqa  xmm13,  xmm5
        pclmulqdq xmm4, xmm10, 000h
        pclmulqdq xmm8, xmm10, 011h
        pclmulqdq xmm5, xmm10, 000h
        pclmulqdq xmm13,xmm10, 011h
        pxor    xmm4,   xmm9
        xorps   xmm4,   xmm8
        pxor    xmm5,   xmm12
        xorps   xmm5,   xmm13

        prefetchnta     [rdx+fetch_dist+96]
        movdqu  xmm9,   [rdx+16*6]
        movdqu  xmm12,  [rdx+16*7]
        pshufb  xmm9,   xmm11
        pshufb  xmm12,  xmm11
        movdqa  xmm8,   xmm6
        movdqa  xmm13,  xmm7
        pclmulqdq xmm6, xmm10, 000h
        pclmulqdq xmm8, xmm10, 011h
        pclmulqdq xmm7, xmm10, 000h
        pclmulqdq xmm13,xmm10, 011h
        pxor    xmm6,   xmm9
        xorps   xmm6,   xmm8
        pxor    xmm7,   xmm12
        xorps   xmm7,   xmm13

        sub     r8, 128

        ; check if there is another 128B in the buffer to be able to fold
        jge     _fold_128_B_loop
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        add     rdx, 128
        ; at this point, the buffer pointer is pointing at the last y Bytes of the buffer, where 0 <= y < 128
        ; the 128B of folded data is in 8 of the xmm registers: xmm0, xmm1, xmm2, xmm3, xmm4, xmm5, xmm6, xmm7


        ; fold the 8 xmm registers to 1 xmm register with different constants

        movdqa  xmm10,  xmmword ptr rk09
        movdqa  xmm8,   xmm0
        pclmulqdq xmm0, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        xorps   xmm7,   xmm0

        movdqa  xmm10,  xmmword ptr rk11
        movdqa  xmm8,   xmm1
        pclmulqdq xmm1, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        xorps   xmm7,   xmm1

        movdqa  xmm10,  xmmword ptr rk13
        movdqa  xmm8,   xmm2
        pclmulqdq xmm2, xmm10, 011h
        pclmulqdq       xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        pxor    xmm7,   xmm2

        movdqa  xmm10,  xmmword ptr rk15
        movdqa  xmm8,   xmm3
        pclmulqdq xmm3, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        xorps   xmm7,   xmm3

        movdqa  xmm10,  xmmword ptr rk17
        movdqa  xmm8,   xmm4
        pclmulqdq xmm4, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        pxor    xmm7,   xmm4

        movdqa  xmm10,  xmmword ptr rk19
        movdqa  xmm8,   xmm5
        pclmulqdq xmm5, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        xorps   xmm7,   xmm5

        movdqa  xmm10, xmmword ptr rk01 ;xmm10 has rk01 and rk02

        movdqa  xmm8,   xmm6
        pclmulqdq xmm6, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        pxor    xmm7,   xmm6

        ; instead of 128, we add 112 to the loop counter to save 1 instruction from the loop
        ; instead of a cmp instruction, we use the negative flag with the jl instruction
        add     r8, 128-16
        jl      _final_reduction_for_128

        ; now we have 16+y bytes left to reduce. 16 Bytes is in register xmm7 and the rest is in memory
        ; we can fold 16 bytes at a time if y>=16
        ; continue folding 16B at a time

_16B_reduction_loop:
        movdqa  xmm8,   xmm7
        pclmulqdq xmm7, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        movdqu  xmm0,   [rdx]
        pshufb  xmm0,   xmm11
        pxor    xmm7,   xmm0
        add     rdx,    16
        sub     r8,     16
        ; instead of a cmp instruction, we utilize the flags with the jge instruction
        ; equivalent of: cmp r8, 16-16
        ; check if there is any more 16B in the buffer to be able to fold
        jge     _16B_reduction_loop

        ;now we have 16+z bytes left to reduce, where 0<= z < 16.
        ;first, we reduce the data in the xmm7 register


_final_reduction_for_128:
        ; check if any more data to fold. If not, compute the CRC of the final 128 bits
        add     r8, 16
        je      _128_done

        ; here we are getting data that is less than 16 bytes.
        ; since we know that there was data before the pointer, we can offset
        ; the input pointer before the actual point, to receive exactly 16 bytes.
        ; after that the registers need to be adjusted.
_get_last_two_xmms:
        movdqa  xmm2, xmm7

        movdqu  xmm1, xmmword ptr [rdx - 16 + r8]
        pshufb  xmm1, xmm11

        ; get rid of the extra data that was loaded before
        ; load the shift constant
        lea     rax, xmmword ptr [psbtbl + 16]
        sub     rax, r8
        movdqu  xmm0, [rax]

        ; shift xmm2 to the left by r8 bytes
        pshufb  xmm2, xmm0

        ; shift xmm7 to the right by 16-r8 bytes
        pxor    xmm0,   xmmword ptr mask1
        pshufb  xmm7,   xmm0
        pblendvb xmm1,  xmm2, xmm0

        ; fold 16 Bytes
        movdqa  xmm2,   xmm1
        movdqa  xmm8,   xmm7
        pclmulqdq xmm7, xmm10, 011h
        pclmulqdq xmm8, xmm10, 000h
        pxor    xmm7,   xmm8
        pxor    xmm7,   xmm2

_128_done:
        ; xmm7 = 128 bit value * 2^64
        movdqa  xmm10,  xmmword ptr rk05    ; rk05 and rk06 in xmm10
        movdqa  xmm0,   xmm7

        ;64 bit fold to 128 bit value
        pclmulqdq xmm7, xmm10, 001h
        pslldq  xmm0,   8
        pxor    xmm7,   xmm0

        ; barrett reduction: compute crc of 128 bit value
_barrett:
        movdqa  xmm10,  xmmword ptr rk07    ; rk07 and rk08 in xmm10
        movdqa  xmm0,   xmm7

        ; value    = v = aaaaaaaa:bbbbbbbb
        ; quotient = q = aaaaaaaa*(2^64 + rk07)
        movdqa  xmm1,   xmm7                ; xmm1 = aaaaaaaa * 2^64
        pand    xmm1,   xmmword ptr mask3
        pclmulqdq xmm7, xmm10, 001h         ; xmm7 upr = aaaaaaaa*rk07
        pxor    xmm7,   xmm1                ; xmm7 upr = q

;       crc = v - q*(2^64 + rk08)
;       since crc is mod 2^64, the 3 xmm1 instructions are optional
        movdqa  xmm1,   xmm7                ; xmm1 = q * 2^64         (optional)
        pand    xmm1,   xmmword ptr mask3   ;                         (optional)
        pclmulqdq xmm7, xmm10, 011h         ; xmm7 = q * rk08
        pxor    xmm7,   xmm1                ; xmm7 = q * (2^64 + rk08) (optional)
        pxor    xmm7,   xmm0                ; xmm7 = v - q*(2^64 + rk08) = crc
        pextrq  rax,    xmm7, 0

_cleanup:
        movdqa  xmm6,  [rsp+16*2]
        movdqa  xmm7,  [rsp+16*3]
        movdqa  xmm8,  [rsp+16*4]
        movdqa  xmm9,  [rsp+16*5]
        movdqa  xmm10, [rsp+16*6]
        movdqa  xmm11, [rsp+16*7]
        movdqa  xmm12, [rsp+16*8]
        movdqa  xmm13, [rsp+16*9]
        add     rsp, STK_ALC
        ret

        align 16
_less_than_256:

        ; check if there is enough buffer to be able to fold 16B at a time
        cmp     r8, 32
        jl      _less_than_32
        movdqa xmm11, xmmword ptr smask

        ; if there is, load the constants
        movdqa  xmm10, xmmword ptr rk01 ; rk01 and rk02 in xmm10

        movd    xmm0, rcx       ; (ML translates to movq) initial crc
        pslldq  xmm0, 8         ; align it to its correct place
        movdqu  xmm7, [rdx]     ; load the plaintext
        pshufb  xmm7, xmm11     ; byte-reflect the plaintext
        pxor    xmm7, xmm0

        ; update the buffer pointer
        add     rdx, 16

        ; update the counter. subtract 32 instead of 16 to save one instruction from the loop
        sub     r8, 32
        jmp     _16B_reduction_loop

        align 16
_less_than_32:
        ; mov initial crc to the return value. this is necessary for zero-length buffers.
        mov     rax, rcx
        test    r8, r8
        je      _cleanup

        movdqa xmm11, xmmword ptr smask

        movd    xmm0, rcx       ; (ML translates to movq) initial crc
        pslldq  xmm0, 8         ; align it to its correct place

        cmp     r8, 16
        je      _exact_16_left
        jl      _less_than_16_left

        movdqu  xmm7, [rdx]     ; load the plaintext
        pshufb  xmm7, xmm11     ; byte-reflect the plaintext
        pxor    xmm7, xmm0      ; xor the initial crc value
        add     rdx, 16
        sub     r8, 16
        movdqa  xmm10, xmmword ptr rk01 ; rk01 and rk02 in xmm10
        jmp     _get_last_two_xmms

        align 16
_less_than_16_left:
        ; use stack space to load data less than 16 bytes, zero-out the 16B in memory first.
        pxor    xmm1, xmm1
        mov     r11, rsp
        movdqa  [r11], xmm1

        ;       backup the counter value
        mov     r9, r8
        cmp     r8, 8
        jl      _less_than_8_left

        ; load 8 Bytes
        mov     rax, [rdx]
        mov     [r11], rax
        add     r11, 8
        sub     r8, 8
        add     rdx, 8
_less_than_8_left:

        cmp     r8, 4
        jl      _less_than_4_left

        ; load 4 Bytes
        mov     eax, [rdx]
        mov     [r11], eax
        add     r11, 4
        sub     r8, 4
        add     rdx, 4
_less_than_4_left:

        cmp     r8, 2
        jl      _less_than_2_left

        ; load 2 Bytes
        mov     ax, [rdx]
        mov     [r11], ax
        add     r11, 2
        sub     r8, 2
        add     rdx, 2
_less_than_2_left:
        cmp     r8, 1
        jl      _zero_left

        ; load 1 Byte
        mov     al, [rdx]
        mov     [r11], al
_zero_left:
        movdqa  xmm7, [rsp]
        pshufb  xmm7, xmm11
        pxor    xmm7, xmm0      ; xor the initial crc value

        ; shl r9, 4
        lea     rax, [psbtbl + 16]
        sub     rax, r9

        cmp     r9, 8
        jl      _end_1to7

_end_8to15:
        movdqu  xmm0, [rax]
        pxor    xmm0, xmmword ptr mask1

        pshufb  xmm7, xmm0
        jmp     _128_done

_end_1to7:
        ; Right shift (8-length) bytes in XMM
        add     rax, 8
        movdqu  xmm0, [rax]
        pshufb  xmm7,xmm0

        jmp     _barrett
        align 16
_exact_16_left:
        movdqu  xmm7, [rdx]
        pshufb  xmm7, xmm11
        pxor    xmm7, xmm0      ; xor the initial crc value

        jmp     _128_done
crc64f  endp
        end

