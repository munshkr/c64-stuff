; load PRG at $0801 to load "autostart routine"
.byte $01, $08
* = $0801

; BASIC autostart routine (aka "10 SYS 4096")
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $39, $31, $35, $32            ; 4096 = $1000
.byte $00, $00, $00

.dsb $2000 - *
* = $2000

.bin 0, 0, "sprites.raw"

.dsb $c000 - *
* = $c000

main:
    sei

    jsr init_screen   ; clear the screen
    jsr init_sprite   ; enable sprite

    ldy #$7f          ; $7f = %01111111
    sty $dc0d         ; turn off CIAs Timer interrupts ($7f = %01111111)
    sty $dd0d
    lda $dc0d         ; by reading $dc0d and $dd0d we cancel all CIA-IRQs
    lda $dd0d         ; in queue/unprocessed.

    lda #$01          ; set Interrupt Request Mask
    sta $d01a         ; we want IRQ by Rasterbeam (%00000001)

    lda #<irq         ; point IRQ Vector to our custom irq routine
    ldx #>irq
    sta $0314         ; store in $314/$315
    stx $0315

    lda #$00          ; trigger interrupt at row zero
    sta $d012

    cli
    jmp *


irq:
    dec $d019       ; acknowledge IRQ / clear register for next interrupt

    jsr update_sprite

    jmp $ea31       ; return to Kernel routine


init_screen:
    ldx #$00
    stx $d021     ; set background color
    stx $d020     ; set border color

clear:
    lda #$20      ; #$20 is the spacebar Screen Code
    sta $0400, x  ; fill four areas with 256 spacebar characters
    sta $0500, x
    sta $0600, x
    sta $06e8, x

    lda #$01      ; set foreground to black in Color RAM
    sta $d800, x
    sta $d900, x
    sta $da00, x
    sta $dae8, x

    inx
    bne clear
    rts


screen_width = 320
screen_height = 200
screen_right_border_width = 24
screen_top_border_height = 30
sprite_half_width = 6
sprite_half_height = 10

char_background_color = $00
char_multicolor_1 = $0b
char_multicolor_2 = $01
char_color = $0f

posx = ((screen_width / 2) + screen_right_border_width - sprite_half_width)
posy = ((screen_height / 2) + screen_top_border_height - sprite_half_height)

total_frames = 6
speed = 3

; TODO: Move these variables to zero page
cur_frame: .byte 0
cur_iter:  .byte speed


init_sprite:
    lda #%00000001  ; enable sprite #0
    sta $d015

    lda #%00000001  ; set multicolor mode for sprites
    sta $d01c

    lda #%00000000  ; all sprites have priority over background
    sta $d01b

    ; set shared colors
    lda #char_background_color
    sta $d021
    lda #char_multicolor_1
    sta $d025
    lda #char_multicolor_2
    sta $d026

    ; set sprite #0 color
    lda #char_color
    sta $d027

    lda #posx       ; set sprite#0 positions with x/y coords
    ldx #posy
    sta $d000       ; x-coord
    stx $d001       ; y-coord

    rts


update_sprite:
    dec cur_iter
    bne done
    lda #speed
    sta cur_iter

    ldx cur_frame
    inx
    txa
    cmp #total_frames
    bne render
    lda #0
render:
    sta cur_frame
    adc #$80
    sta $07f8
done:
    rts
