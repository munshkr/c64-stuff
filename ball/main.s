.import __MAIN_CODE_LOAD__

.include "c64.inc"  ; C64 constants

SCREEN_WIDTH = 320
SCREEN_HEIGHT = 200
SCREEN_RIGHT_BORDER_WIDTH = 24
SCREEN_TOP_BORDER_HEIGHT = 30
SPRITE_HALF_WIDTH = 6
SPRITE_HALF_HEIGHT = 10
CENTER_X = ((SCREEN_WIDTH / 2) + SCREEN_RIGHT_BORDER_WIDTH - SPRITE_HALF_WIDTH)
CENTER_Y = ((SCREEN_HEIGHT / 2) + SCREEN_TOP_BORDER_HEIGHT - SPRITE_HALF_HEIGHT)

CHAR_BACKGROUND_COLOR = $00
CHAR_COLOR = $01


.segment "DATA"
    pos_x:   .word CENTER_X << 8
    pos_y:   .word CENTER_Y << 8
    pos_x_h: .byte 0

    vel_x:   .word $10
    vel_y:   .word 0
    accel_x: .word $10
    accel_y: .word 0

.segment "CODE"
    jmp __MAIN_CODE_LOAD__

.segment "MAIN_CODE"
    sei

    jsr init_screen   ; clear the screen
    jsr init_sprite   ; enable sprite

    lda #%01111111
    sta CIA1_ICR      ; turn off CIAs Timer interrupts
    sta CIA2_ICR
    lda CIA1_ICR      ; by reading $dc0d and $dd0d we cancel all CIA-IRQs
    lda CIA2_ICR      ; in queue/unprocessed.

    lda #$01          ; set Interrupt Request Mask
    sta VIC_IMR       ; we want IRQ by Rasterbeam (%00000001)

    lda #<irq         ; point IRQ Vector to our custom irq routine
    ldx #>irq
    sta IRQVec        ; store in $314/$315
    stx IRQVec+1

    lda #0            ; trigger interrupt at row zero
    sta VIC_HLINE

    cli
    jmp *

irq:
    dec VIC_IRR       ; acknowledge IRQ / clear register for next interrupt

    jsr update_velocity
    jsr update_positions
    jsr update_sprites

    jmp $ea31       ; return to Kernel routine

init_screen:
    ldx #0
    stx VIC_BG_COLOR0     ; set background color
    stx VIC_BORDERCOLOR   ; set border color
@loop:
    lda #$20      ; #$20 is the spacebar Screen Code
    ; TODO: Use constant SCREEN_RAM + offset
    sta $0400, x  ; fill four areas with 256 spacebar characters
    sta $0500, x
    sta $0600, x
    sta $06e8, x

    lda #$01      ; set foreground to black in Color RAM
    ; TODO: Use constant SCREEN_RAM + offset
    sta $d800, x
    sta $d900, x
    sta $da00, x
    sta $dae8, x

    inx
    bne @loop
    rts

init_sprite:
    lda #%00000001  ; enable sprite #0
    sta VIC_SPR_ENA

    lda #0          ; clear multicolor mode for all sprites
    sta VIC_SPR_MCOLOR

    lda #0          ; all sprites have priority over background
    sta VIC_SPR_BG_PRIO

    ; set shared colors
    lda #CHAR_BACKGROUND_COLOR
    sta VIC_BG_COLOR0

    ; set sprite #0 color
    lda #CHAR_COLOR
    sta VIC_SPR0_COLOR

    ; set sprite #0 image
    lda #$80
    sta $07f8

    rts

.proc update_velocity
    clc
    lda accel_x
    adc vel_x
    sta vel_x
    lda accel_x+1
    adc vel_x+1
    sta vel_x+1

    clc
    lda accel_y
    adc vel_y
    sta vel_y
    lda accel_y+1
    adc vel_y+1
    sta vel_y+1
    rts
.endproc

.proc update_positions
    clc
    lda vel_y
    adc pos_y
    sta pos_y
    lda vel_y+1
    adc pos_y+1
    sta pos_y+1

    clc
    lda vel_x
    adc pos_x
    sta pos_x
    lda vel_x+1
    bpl @pos
@neg:
    adc pos_x+1
    sta pos_x+1
    bcs @done
    beq @toggle_pos_x_h
@pos:
    adc pos_x+1
    sta pos_x+1
    bcc @done
@toggle_pos_x_h:
    lda pos_x_h
    eor #%00000001
    sta pos_x_h
@done:
    rts
.endproc

.proc update_sprites
    lda pos_x+1
    sta VIC_SPR0_X
    lda pos_y+1
    sta VIC_SPR0_Y
    lda pos_x_h          ; update bit#8 of x-coordinate of all sprites
    sta VIC_SPR_HI_X
    rts
.endproc


.segment "SPRITES"
    .incbin "ball.raw"
