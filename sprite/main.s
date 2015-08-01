.import __MAIN_CODE_LOAD__

.include "c64.inc"  ; C64 constants

SCREEN_WIDTH = 320
SCREEN_HEIGHT = 200
SCREEN_RIGHT_BORDER_WIDTH = 24
SCREEN_TOP_BORDER_HEIGHT = 30
SPRITE_HALF_WIDTH = 6
SPRITE_HALF_HEIGHT = 10

CHAR_BACKGROUND_COLOR = $00
CHAR_MULTICOLOR_1 = $0B
CHAR_MULTICOLOR_2 = $01
CHAR_COLOR = $0F

CENTER_X = ((SCREEN_WIDTH / 2) + SCREEN_RIGHT_BORDER_WIDTH - SPRITE_HALF_WIDTH)
CENTER_Y = ((SCREEN_HEIGHT / 2) + SCREEN_TOP_BORDER_HEIGHT - SPRITE_HALF_HEIGHT)

TOTAL_FRAMES = 6
SPEED = 3
NUM_SPRITES = 3


.segment "DATA"
    cur_frame: .byte 0
    cur_iter:  .byte SPEED
    pos_x:     .byte CENTER_X - 10, CENTER_X + 20, CENTER_X
    pos_y:     .byte CENTER_Y - 5,  CENTER_Y + 10, CENTER_Y
    pos_x_h:   .byte 0
    speed_x:   .byte $01, $ff, $01
    speed_y:   .byte $ff, $01, $01

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

    lda #$00          ; trigger interrupt at row zero
    sta VIC_HLINE

    cli
    jmp *

irq:
    dec VIC_IRR       ; acknowledge IRQ / clear register for next interrupt

    jsr move_sprites
    jsr update_sprite_positions
    jsr animate_sprites

    jmp $ea31       ; return to Kernel routine

init_screen:
    ldx #$00
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
    lda #%00000111  ; enable sprite #0
    sta VIC_SPR_ENA

    lda #%00000111  ; set multicolor mode for sprites
    sta VIC_SPR_MCOLOR

    lda #%00000000  ; all sprites have priority over background
    sta VIC_SPR_BG_PRIO

    ; set shared colors
    lda #CHAR_BACKGROUND_COLOR
    sta VIC_BG_COLOR0
    lda #CHAR_MULTICOLOR_1
    sta VIC_SPR_MCOLOR0
    lda #CHAR_MULTICOLOR_2
    sta VIC_SPR_MCOLOR1

    ; set sprite #0 color
    lda #CHAR_COLOR
    sta VIC_SPR0_COLOR
    sta VIC_SPR1_COLOR
    sta VIC_SPR2_COLOR

    rts

move_sprites:
    clc
    lda pos_y
    adc speed_y
    sta pos_y
check_y:
    ; TODO: Use constants
    cmp #48             ; check hit at top
    beq invert_speed_y
    ; TODO: Use constants
    cmp #230            ; check hit at bottom
    bne done_y
invert_speed_y:
    lda speed_y
    eor #$ff            ; invert(n)+1 = neg(n)  (two's complement)
    clc
    adc #1
    sta speed_y
done_y:

    clc
    lda pos_x
    adc speed_x
    sta pos_x
    bne check_left_x
    lda pos_x_h
    eor #%00000001
    sta pos_x_h
check_left_x:
    ; TODO: Use constants
    cmp #24             ; check hit at left
    bne check_right_x
    lda pos_x_h
    beq invert_speed_x
check_right_x:
    ; TODO: Use constants
    cmp #$40            ; check hit at right
    bne done_x
    lda pos_x_h
    beq done_x
invert_speed_x:
    lda speed_x
    eor #$ff
    clc
    adc #1
    sta speed_x
done_x:
    rts

update_sprite_positions:
    ldx #0
@loop:
    txa
    asl
    tay
    lda pos_x, x
    sta VIC_SPR0_X, y
    lda pos_y, x
    sta VIC_SPR0_Y, y
    inx
    cpx #NUM_SPRITES
    bne @loop
    lda pos_x_h          ; update bit#8 of x-coordinate of all sprites
    sta VIC_SPR_HI_X
    rts

animate_sprites:
    dec cur_iter
    bne @done
    lda #SPEED
    sta cur_iter

    ldx cur_frame
    inx
    txa
    cmp #TOTAL_FRAMES
    bne @render
    lda #0
@render:
    sta cur_frame
    ; TODO: Use constants
    adc #$80
    sta $07f8
@done:
    rts


.segment "SPRITES"
  .incbin "sprites.raw"
