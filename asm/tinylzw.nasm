; Tiny LZW decompressor in x86 16 bit assembly (NASM format)
;
; Copyright (C) by Matthias Waldhauer a.k.a. Dresdenboy^Citavia (m.waldhauer@gmx.de)
;
; This code is licensed under a MIT License.
;
; Since this is work in progress, the code might still contain errors in some paths.
;
; Useable in this form in DOS COM files. In the shortest form the beginning of the PSP
; (containing the code to end the program) will be overwritten.
;
; Inputs:
; si: compressed data
; di: destination for decompressed data
; sp: fffeh
; flags: DF=0
;
; Data format:
;
; For testing purposes a simple 16b data format is being used. Any variant of bitstream
; encoding could be placed at the "iterate" label. A simple 9 bit decoder is included.
; On Z80, 6502, or also x86 a combined bitstream (for MSB) and byte stream (for LSB) could
; be used.
;
; The data should be created with a standard LZW compression, with literals spanning
; the 00..ffh range and any dictionary reference using values from 100h onward. Depending
; on the instructions after the IMUL the decompression ends when receiving a specific
; code, in this case 100h.
;
; Optimization variants:
; - start the table at SP=0000, overwriting a small part of the PSP with the first C[x-1]
; - exit the loop based on specific codes, e.g. 100h or 101h (seldomly used as reference)
; - limit the bitstream to 9 bit values (no adaption code to bigger codes needed)
; - limit the bitstream to the amount of bits used in the destination pointer
; - use typical COM reg init values as bitstream pointers, indices etc.
;
; The stack based variant stores values in a table containing 2 values per row:
; - V[x] - the previous code, which could also be a literal
; - C[x] - the corresponding literal following the code in V[x]

%define TEST_LZW 0
%define SF_ZF_SET_BY_IMUL 1       ; i.e. IMUL affects ZF, SF, too
%define UNSAFE 1        ; use unsafe tricks like overwriting a part of the PSP (0000h) to reduce code size

use16
org 100h

start:

%if UNSAFE
     pop cx             ; 1 clear CX and set stack pointer to 0000 ;)
%else ; UNSAFE == 0
     push bx            ; 1 align stack/table base to 0fffch
	 xor cx, cx         ; 2 prepare CX for loop
%endif
%if TEST_LZW == 1
     mov bp, data
.iterate:
     mov ax, [bp]
     inc bp
     inc bp
%else ; TEST_LZW == 0
     xor bp, bp
.iterate:
.readbits:
     mov ax, 80h        ; 3
     bt [bitdata], bp   ; 4
     inc bp             ; 1
     adc ax, ax         ; 2
     jnc .readbits      ; 2 (12 B, simple decoder)
%endif

     mov bx, ax         ; 2 store code for later
.next:
     inc cx             ; 1 output count
     dec ah             ; 2 adjust range and is it a lit code?
     js .lit            ; 2 turned negative -> lit
%if !UNSAFE
     inc ax             ; 1 adjust pointer for correct stack address in case of starting at 0fffch
%endif
     imul si,ax,-4      ; 3 get index on stack, starting -4 relative
%if !SF_ZF_SET_BY_IMUL
  %if UNSAFE
     or ax, ax          ; 2 test for 0 (code 100h after dec ah->0), variant: cmp al, <unused val>
  %else ; UNSAFE == 0
     dec ax             ; 1 revert increment to test for zero
  %endif
%endif
     jz exit           ; 2 done: 100h -> exit code, doesn't map to some stack entry anyway
                        ;   -> doesn't work for DOSBox (only from P4 according to qkumba)
%if SF_ZF_SET_BY_IMUL
     sahf               ; 1 set flags from AH, which is always in a [0..small n] range in this path
%endif
     lodsw              ; 1 C[x]
.lit:
     xchg dx, ax        ; 1 save code/lit
     push dx            ; 1 push for output
     lodsw              ; 1 V[x] read next code (might be obsolete)
     jns .next          ; 2 still set from lit test if not changed by an IMUL
.out:
     pop ax             ; 1 get output char
     stosb              ; 1 store last
     loop .out          ; 2
     pop si             ; 1 go to C[X] pos on stack
     push dx            ; 1 C[x] (previous)
     push bx            ; 1 code from above -> V[x+1]
     push dx            ; 1 C[x+1] next
     jmp .iterate       ; 2 (27 B)
exit:

%if TEST_LZW
data:
        ; dw "A", "B", "A", "C", 100h, 102h, "E"
        dw "A", "A", 101h, 102h, "E"
%else
bitdata:
        dw 0E281h, 045C8h, 05C34h, 0
%endif
