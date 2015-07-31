.import __MAIN_CODE_LOAD__

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


.segment "DATA"
    cur_frame: .byte 0
    cur_iter:  .byte SPEED
    pos_x_h:   .byte 0
    pos_x:     .byte CENTER_X
    pos_y:     .byte CENTER_Y
    speed_x:   .byte 1
    speed_y:   .byte 1

.segment "CODE"
    jmp __MAIN_CODE_LOAD__

.segment "MAIN_CODE"
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

    jsr move_sprites
    jsr update_sprite_positions
    jsr animate_sprites

    jmp $ea31       ; return to Kernel routine

init_screen:
    ldx #$00
    stx $d021     ; set background color
    stx $d020     ; set border color
@loop:
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
    bne @loop
    rts

init_sprite:
    lda #%00000001  ; enable sprite #0
    sta $d015

    lda #%00000001  ; set multicolor mode for sprites
    sta $d01c

    lda #%00000000  ; all sprites have priority over background
    sta $d01b

    ; set shared colors
    lda #CHAR_BACKGROUND_COLOR
    sta $d021
    lda #CHAR_MULTICOLOR_1
    sta $d025
    lda #CHAR_MULTICOLOR_2
    sta $d026

    ; set sprite #0 color
    lda #CHAR_COLOR
    sta $d027

    rts

move_sprites:
    clc
    lda pos_y
    adc speed_y
    sta pos_y
check_y:
    cmp #46             ; check hit at top
    beq invert_speed_y
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
    cmp #24             ; check hit at left
    bne check_right_x
    lda pos_x_h
    beq invert_speed_x
check_right_x:
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
    lda pos_x
    sta $d000
    lda pos_y
    sta $d001
    lda pos_x_h
    sta $d010
    rts

animate_sprites:
    dec cur_iter
    bne done_animation
    lda #SPEED
    sta cur_iter

    ldx cur_frame
    inx
    txa
    cmp #TOTAL_FRAMES
    bne render
    lda #0
render:
    sta cur_frame
    adc #$80
    sta $07f8
done_animation:
    rts


.segment "SPRITES"
  .incbin "sprites.raw"
