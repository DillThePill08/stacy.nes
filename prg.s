.include "defines.s"


;init
reset:
    sei        ; ignore IRQs
    cld        ; disable decimal mode
    ldx #$40
    stx APUFRAME  ; disable APU frame IRQ
    ldx #$ff
    txs        ; Set up stack
    inx        ; now X = 0
    stx PPUCTRL  ; disable NMI
    stx PPUMASK  ; disable rendering
    stx DMC_FREQ  ; disable DMC IRQs

@vblankwait1:
    bit PPUSTATUS
    bpl @vblankwait1

    ;init mem while waiting for ppu
    txa
@clrmem:
    sta $000,x
    sta $100,x
    sta $200,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx
    bne @clrmem

@vblankwait2:
    bit PPUSTATUS
    bpl @vblankwait2

;load palettes
    ;set PPUADDR to VRAM palettes
    lda PPUSTATUS ;clear write toggle
    lda #$3F 
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ;load palettes into VRAM
    ldx #$00
@loadPalettes:
    lda palettes,x
    sta PPUDATA
    inx
    cpx #$14 ;size of palettes
    bne @loadPalettes
    
;go to attribute table in VRAM
    lda PPUSTATUS ;PPUADDR = $23C0
    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR
;load the attributes into vram
    ldx #$00
@loadAttributes:
    lda attributes,x
    sta PPUDATA
    inx
    cpx #$40
    bne @loadAttributes

;store nametable addr to zp to indirectly index
    lda #.LOBYTE(nametable)
    sta $00
    lda #.HIBYTE(nametable)
    sta $01
;store vram nametable addr to zp to indirectly index
    lda #$40
    sta $02
    lda #$20
    sta $03

;enable rendering
    lda #%00011010
    sta PPUMASK 
;enable NMI and 8x16 sprites
    lda #%10100000
    sta PPUCTRL
;reset scrolling
    lda #$00
    sta PPUSCROLL
    sta PPUSCROLL
;vblank counter
    ldx #$00
hang:
    jmp hang



loopsPerVBlank = $80
vblankCount = $07

nmi: ;this is the shit
;if loops done, skip nametable loading and load OAM
    lda $05
    bne @load_oam

;go to nametable in VRAM
    lda PPUSTATUS
    lda $03
    sta PPUADDR
    lda $02
    sta PPUADDR
;load values into nametable
    ldy #$00
 @loadNametable:
    lda ($00),y
    sta PPUDATA
    iny
    cpy #loopsPerVBlank
    bne @loadNametable
;increment indirect addr
    lda $00
    clc
    adc #loopsPerVBlank
    sta $00
    bcc :+
    inc $01
;increment nametable addr
:   lda $02
    clc
    adc #loopsPerVBlank
    sta $02
    bcc :+
    inc $03
;inc loop count
:   inx
    cpx #vblankCount
    bne end
;mark end of nametable loading and begin oam loop next vblank
    lda #$01
    sta $05
    jmp end

@load_oam:
    ldx #$00
    stx OAMADDR
:   lda oam,x
    sta OAMDATA
    inx
    cpx #$08 ;size of out oam data
    bne :-

    ldx #$00
    stx OAMADDR

;load controller data, to change her eyes lol
    buttons = $06 ;i dont know how any of this works
    lda #01
    sta JOY1
    sta buttons
    lsr a
    sta JOY1
:   lda JOY1
    lsr a
    rol buttons
    bcc :-

    bit buttons
    bpl @normalPalette
    bvc @normalPalette ;if a and b are held
@evilPalette:
    ldx #$05 ;red
    jmp :+
@normalPalette:
    ldx #$11 ;blue

;set palette eye color
:   lda PPUSTATUS
    lda #$3F
    sta PPUADDR
    ldy #$02
    sty PPUADDR
    stx PPUDATA ;first blue

    ldy PPUSTATUS
    sta PPUADDR
    ldy #$09
    sty PPUADDR
    stx PPUDATA
end:
;reset ppuaddr and scrolling
    lda #$00
    sta PPUADDR
    sta PPUADDR
    sta PPUSCROLL
    sta PPUSCROLL
    rti

palettes:
    ;bg
    .byte $0F, $20, $11, $2A ;white, blue, green
    .byte $0F, $2A, $15, $01 ;green, hot pink, navy
    .byte $0F, $11, $25, $20 ;blue, pink, white
    .byte $0F, $20, $01, $2A ;white, navy, green

    ;sprite palettes
    .byte $0F, $2A, $15, $01 ;green, hot pink, navy
    ;i dont need the rest lol

oam:
.byte $2F,$EC,$00,$20
.byte $2F,$EE,$00,$28

attributes:
.include "attributes.s"

nametable:
.include "nametable.s"