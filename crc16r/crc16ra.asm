        title   crc16ra
;       page    80,132
;-----------------------------------------------------------------------;
;       crc16ra.asm     fast 16 bit crc bit reflected                   ;
;-----------------------------------------------------------------------;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Copyright(c) 2011-2015 Intel Corporation All rights reserved.
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

;-----------------------------------------------------------------------;
;       DATA                                                            ;
;-----------------------------------------------------------------------;
        .data

        align 16

rk01    dq      000000000000189aeh      ; (2^(32* 3) mod P(x))' << 1
rk02    dq      00000000000008e10h      ; (2^(32* 5) mod P(x))' << 1
rk03    dq      000000000000160beh      ; (2^(32*31) mod P(x))' << 1
rk04    dq      0000000000001bed8h      ; (2^(32*33) mod P(x))' << 1
rk05    dq      000000000000189aeh      ; (2^(32* 3) mod P(x))' << 1
rk06    dq      000000000000114aah      ; (2^(32* 2) mod P(x))' << 1
rk07    dq      0000000011c581911h      ; (floor(2^64/P(x)))'
rk08    dq      00000000000010811h      ; (P(x))'
rk09    dq      0000000000001ce5eh      ; (2^(32*27) mod P(x))' << 1
rk10    dq      0000000000001c584h      ; (2^(32*29) mod P(x))' << 1
rk11    dq      0000000000001db50h      ; (2^(32*23) mod P(x))' << 1
rk12    dq      0000000000000b8f2h      ; (2^(32*25) mod P(x))' << 1
rk13    dq      00000000000000842h      ; (2^(32*19) mod P(x))' << 1
rk14    dq      0000000000000b072h      ; (2^(32*21) mod P(x))' << 1
rk15    dq      00000000000014ff2h      ; (2^(32*15) mod P(x))' << 1
rk16    dq      00000000000019a3ch      ; (2^(32*17) mod P(x))' << 1
rk17    dq      00000000000000e3ah      ; (2^(32*11) mod P(x))' << 1
rk18    dq      00000000000004d7ah      ; (2^(32*13) mod P(x))' << 1
rk19    dq      00000000000005b44h      ; (2^(32* 7) mod P(x))' << 1
rk20    dq      00000000000007762h      ; (2^(32* 9) mod P(x))' << 1

mask1   dq 08080808080808080h, 08080808080808080h
mask2   dq 0FFFFFFFF00000000h, 0FFFFFFFFFFFFFFFFh

smask   dq 008090A0B0C0D0E0Fh, 00001020304050607h

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
        dq 00706050403020100h, 00f0e0d0c0b0a0908h
        dq 08786858483828180h, 08f8e8d8c8b8a8988h

;-----------------------------------------------------------------------;
;       code SEGMENT                                                    ;
;-----------------------------------------------------------------------;
        public  crc16r
        .code

        align 16
        ;       r8  = bfr size (in bytes)
        ;       rdx = ptr to bfr
        ;       rcx = initial crc 
crc16r  proc

        sub     rsp, STK_ALC
        ; push the xmm registers into the stack to maintain
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
        movd    xmm10, ecx      ; initial crc
;       pslldq  xmm10, 0

;       movdqa  xmm11, xmmword ptr smask ; byte reflect mask
        ; receive the initial 128B data, xor the initial crc value
        movdqu  xmm0, [rdx+16*0]
        movdqu  xmm1, [rdx+16*1]
        movdqu  xmm2, [rdx+16*2]
        movdqu  xmm3, [rdx+16*3]
        movdqu  xmm4, [rdx+16*4]
        movdqu  xmm5, [rdx+16*5]
        movdqu  xmm6, [rdx+16*6]
        movdqu  xmm7, [rdx+16*7]

;       pshufb  xmm0, xmm11
        ; XOR the initial_crc value
        pxor    xmm0, xmm10
;       pshufb  xmm1, xmm11
;       pshufb  xmm2, xmm11
;       pshufb  xmm3, xmm11
;       pshufb  xmm4, xmm11
;       pshufb  xmm5, xmm11
;       pshufb  xmm6, xmm11
;       pshufb  xmm7, xmm11

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

        movdqu  xmm9, [rdx+16*0]
        movdqu  xmm12, [rdx+16*1]
;       pshufb  xmm9, xmm11
;       pshufb  xmm12, xmm11
        movdqa  xmm8, xmm0
        movdqa  xmm13, xmm1
        pclmulqdq xmm0, xmm10, 001h
        pclmulqdq xmm8, xmm10 , 010h
        pclmulqdq xmm1, xmm10, 001h
        pclmulqdq xmm13, xmm10 , 010h
        pxor    xmm0, xmm9
        xorps   xmm0, xmm8
        pxor    xmm1, xmm12
        xorps   xmm1, xmm13

        movdqu  xmm9, [rdx+16*2]
        movdqu  xmm12, [rdx+16*3]
;       pshufb  xmm9, xmm11
;       pshufb  xmm12, xmm11
        movdqa  xmm8, xmm2
        movdqa  xmm13, xmm3
        pclmulqdq xmm2, xmm10, 001h
        pclmulqdq xmm8, xmm10 , 010h
        pclmulqdq xmm3, xmm10, 001h
        pclmulqdq xmm13, xmm10 , 010h
        pxor    xmm2, xmm9
        xorps   xmm2, xmm8
        pxor    xmm3, xmm12
        xorps   xmm3, xmm13

        movdqu  xmm9, [rdx+16*4]
        movdqu  xmm12, [rdx+16*5]
;       pshufb  xmm9, xmm11
;       pshufb  xmm12, xmm11
        movdqa  xmm8, xmm4
        movdqa  xmm13, xmm5
        pclmulqdq xmm4, xmm10, 001h
        pclmulqdq xmm8, xmm10 , 010h
        pclmulqdq xmm5, xmm10, 001h
        pclmulqdq xmm13, xmm10 , 010h
        pxor    xmm4, xmm9
        xorps   xmm4, xmm8
        pxor    xmm5, xmm12
        xorps   xmm5, xmm13

        movdqu  xmm9, [rdx+16*6]
        movdqu  xmm12, [rdx+16*7]
;       pshufb  xmm9, xmm11
;       pshufb  xmm12, xmm11
        movdqa  xmm8, xmm6
        movdqa  xmm13, xmm7
        pclmulqdq xmm6, xmm10, 001h
        pclmulqdq xmm8, xmm10 , 010h
        pclmulqdq xmm7, xmm10, 001h
        pclmulqdq xmm13, xmm10 , 010h
        pxor    xmm6, xmm9
        xorps   xmm6, xmm8
        pxor    xmm7, xmm12
        xorps   xmm7, xmm13

        sub     r8, 128

        ; check if there is another 128B in the buffer to be able to fold
        jge     _fold_128_B_loop
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        add     rdx, 128
        ; at this point, the buffer pointer is pointing at the last y Bytes of the buffer
        ; fold the 8 xmm registers to 1 xmm register with different constants

        movdqa  xmm10, xmmword ptr rk09
        movdqa  xmm8, xmm0
        pclmulqdq xmm0, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        xorps   xmm7, xmm0

        movdqa  xmm10, xmmword ptr rk11
        movdqa  xmm8, xmm1
        pclmulqdq xmm1, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        xorps   xmm7, xmm1

        movdqa  xmm10, xmmword ptr rk13
        movdqa  xmm8, xmm2
        pclmulqdq xmm2, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        pxor    xmm7, xmm2

        movdqa  xmm10, xmmword ptr rk15
        movdqa  xmm8, xmm3
        pclmulqdq xmm3, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        xorps   xmm7, xmm3

        movdqa  xmm10, xmmword ptr rk17
        movdqa  xmm8, xmm4
        pclmulqdq xmm4, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        pxor    xmm7, xmm4

        movdqa  xmm10, xmmword ptr rk19
        movdqa  xmm8, xmm5
        pclmulqdq xmm5, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        xorps   xmm7, xmm5

        movdqa  xmm10, xmmword ptr rk01
        movdqa  xmm8, xmm6
        pclmulqdq xmm6, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        pxor    xmm7, xmm6

        ; instead of 128, we add 112 to the loop counter to save 1 instruction from the loop
        ; instead of a cmp instruction, we use the negative flag with the jl instruction
        add     r8, 128-16
        jl      _final_reduction_for_128

        ; now we have 16+y bytes left to reduce. 16 Bytes is in register xmm7 and the rest is in memory
        ; we can fold 16 bytes at a time if y>=16
        ; continue folding 16B at a time

_16B_reduction_loop:
        movdqa  xmm8, xmm7
        pclmulqdq xmm7, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        movdqu  xmm0, [rdx]
;       pshufb  xmm0, xmm11
        pxor    xmm7, xmm0
        add     rdx, 16
        sub     r8, 16
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
        ; since we know that there was data before the pointer, we can offset the input pointer before the actual point, to receive exactly 16 bytes.
        ; after that the registers need to be adjusted.
_get_last_two_xmms:
        movdqa  xmm2, xmm7

        movdqu  xmm1, xmmword ptr [rdx - 16 + r8]
;       pshufb  xmm1, xmm11

        ; get rid of the extra data that was loaded before
        ; load the shift constant
        lea     rax, [pshufb_shf_table]
;       add     rax,r8
        movdqu  xmm0, xmmword ptr [rax + r8]

        ; shift xmm2 to the right by r8 bytes
        pshufb  xmm2, xmm0

        ; shift xmm7 to the left by 16-r8 bytes
        pxor    xmm0, xmmword ptr [mask1]
        pshufb  xmm7, xmm0             
        pblendvb xmm1, xmm2, xmm0

        ; fold 16 Bytes
        movdqa  xmm2, xmm1
        movdqa  xmm8, xmm7
        pclmulqdq xmm7, xmm10, 010h
        pclmulqdq xmm8, xmm10, 001h
        pxor    xmm7, xmm8
        pxor    xmm7, xmm2

_128_done:
        ; compute crc of a 128-bit value
        movdqa  xmm10, xmmword ptr rk05 ; rk05 and rk06 in xmm10
        movdqa  xmm0, xmm7

        ;64b fold
        pclmulqdq xmm7, xmm10, 000h
        psrldq  xmm0, 8
        pxor    xmm7, xmm0

        ;32b fold
        movdqa  xmm0, xmm7
        pand    xmm0, xmmword ptr mask2

        pslldq  xmm7, 12
        pclmulqdq xmm7, xmm10, 011h
        pxor    xmm7, xmm0

        ;barrett reduction
_barrett:
        movdqa  xmm10, xmmword ptr rk07 ; rk07 and rk08 in xmm10
        movdqa  xmm0, xmm7
        pclmulqdq xmm7, xmm10, 000h
;       pslldq  xmm7,0
        pclmulqdq xmm7, xmm10, 010h
;       pslldq  xmm7,0
        pxor    xmm7, xmm0
        pextrd  eax, xmm7,2

_cleanup:
        movdqa  xmm6, [rsp+16*2]
        movdqa  xmm7, [rsp+16*3]
        movdqa  xmm8, [rsp+16*4]
        movdqa  xmm9, [rsp+16*5]
        movdqa  xmm10, [rsp+16*6]
        movdqa  xmm11, [rsp+16*7]
        movdqa  xmm12, [rsp+16*8]
        movdqa  xmm13, [rsp+16*9]
        add     rsp, STK_ALC
        ret     0

        align 16
_less_than_256:

        ; check if there is enough buffer to be able to fold 16B at a time
        cmp     r8, 32
        jl      _less_than_32
        movdqa xmm11, xmmword ptr smask

        ; if there is, load the constants
        movdqa  xmm10, xmmword ptr rk01 ; rk01 and rk02 in xmm10

        movd    xmm0, ecx       ; get the initial crc value
;       pslldq  xmm0, 0
        movdqu  xmm7, [rdx]     ; load the plaintext
;       pshufb  xmm7, xmm11
        pxor    xmm7, xmm0

        ; update the buffer pointer
        add     rdx, 16

        ; update the counter. subtract 32 instead of 16 to save one instruction from the loop
        sub     r8, 32
        jmp     _16B_reduction_loop

        align 16
_less_than_32:
        ; mov initial crc to the return value. this is necessary for zero-length buffers.
        mov     eax, ecx
        test    r8, r8
        je      _cleanup

        movdqa xmm11, xmmword ptr smask

        movd    xmm0, ecx       ; get the initial crc value
;       pslldq  xmm0, 0

        cmp     r8, 16
        je      _exact_16_left
        jl      _less_than_16_left

        movdqu  xmm7, [rdx]     ; load the plaintext
;       pshufb  xmm7, xmm11
        pxor    xmm7, xmm0      ; xor the initial crc value
        add     rdx, 16
        sub     r8, 16
        movdqa  xmm10, xmmword ptr rk01 ; rk01 and rk02 in xmm10
        jmp     _get_last_two_xmms

        align 16
_less_than_16_left:
        ; use stack space to load data less than 16 bytes, zero-out the 16B in memory first.
        pxor    xmm1, xmm1      ; zero 16 byte block at [rsp]
        movdqa  [rsp], xmm1
        lea     r11,[rsp+16]    ; copy data into data block
        xor     r9,r9
        sub     r11,r8
_copy0: mov     al,[rdx+r9]
        mov     [r11+r9],al
        inc     r9
        cmp     r9,r8
        jnz     _copy0
        movdqa  xmm7,[rsp]      ; load xmm7 from data block
        lea     rax, [pshufb_shf_table]
        cmp     r8,4            ; br if less than 4 bytes
        jb      _less_than_4
        ; shift xmm0 to the left by 16-r8 bytes
        movdqu  xmm1, xmmword ptr [rax + r8]
        pxor    xmm1, xmmword ptr [mask1]
        pshufb  xmm0, xmm1
        pxor    xmm7, xmm0      ; xor the initial crc value
        jmp     _128_done       ; do 16 byte fold

_less_than_4:
        psrldq  xmm7,8          ; shift xmm7 right 8 bytes
        ; shift xmm0 to the left by 8-r8 bytes
        movdqu  xmm1, xmmword ptr [rax + r8 + 8]
        pxor    xmm1, xmmword ptr [mask1]
        pshufb  xmm0, xmm1
        pxor    xmm7,xmm0       ; xor the initial crc value
        jmp     _barrett        ; do barret reduction

        align 16
_exact_16_left:
        movdqu  xmm7, [rdx]
;       pshufb  xmm7, xmm11
        pxor    xmm7, xmm0      ; xor the initial crc value

        jmp     _128_done

crc16r  endp
        end
