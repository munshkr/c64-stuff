; Load PRG at $0801 to load "autostart routine"
.byte $01, $08
* = $0801

; Autostart routine (aka "10 SYS 4096")
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $30, $39, $36            ; 4096 = $1000
.byte $00, $00, $00

.dsb $1000 - * ; Pad with zeroes from PC to $1000
* = $1000

main:
    inc $d020    ; Flashy border!
    jmp main
