.segment "HEADER"
.byte "NES",$1A             ;"NES", $1A
.byte $02                   ; 2x 16KB PRG code
.byte $01                   ; 1x  8KB CHR data
.byte %00000000,%00000000   ; mapper 0, horizontal mirroring

.segment "VECTORS"
.addr nmi
.addr reset
.addr 0 ;unused IRQ

.segment "STARTUP"

.segment "CODE"
.include "prg.s"

.segment "CHARS"
.incbin "tiles.chr"