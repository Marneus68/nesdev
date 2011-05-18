; bg-ophis.asm - Avik Das
;
; A very simple demo, based on the NES101 tutorial by Michael Martin.
; This demo can be assembled using Ophis 1.0, and runs on FCEUX.
; 
; This demo serves two purposes. Firstly, my goal is to learn NES
; development, which I can only achieve by creating a program.
; Secondly, the entirety of the program will be in one file, in order
; to show at a glance all the different parts of the program.

  ; iNES header

  ; iNES identifier
  .byte "NES",$1A

  .byte $01 ; 1 PRG-ROM page
  .byte $01 ; 1 CHR-ROM page

  .byte $00, $00 ; horizontal mirroring, mapper #0
  .byte $00,$00,$00,$00,$00,$00,$00,$00 ; reserved/filler

  ; PRG-ROM

  .alias sprite $200   ; use page 2 for sprite data
  .alias player sprite ; the first sprite is the player

  .text zp ; zero page
  .org $0000

  ; XXX Global variables go here
  ; .space name size ; documentation

  ; Actual program code. We only have one PRG-ROM chip here, so the
  ; origin is $C000.
  ; Mapper #0, mirrors the 16KiB code from $8000-$bffff and $c000-$fffff.
  .text
  .org $8000

reset:
  sei ; disable interrupts
  cld ; ensure binary mode

  ; wait two VBlanks
* lda $2002
  bpl -
* lda $2002
  bpl -

  ; clear out the RAM
  lda #$00
  ldx #$00
* sta $000,x
  sta $100,x
  sta $200,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne -

  ; reset the stack pointer
  ldx #$FF
  txs

  lda #$00
  sta $2000
  sta $2001

  jsr init_graphics
  jsr init_sound
  jsr init_variables

  ; set PPU registers
  lda #%10001000 ; enable NMI on VBlank
                 ; 8x8 sprites
                 ; background pattern table at $0000
                 ;     sprite pattern table at $1000
                 ; name table at $2000
  sta $2000
  lda #%00011110 ; unmodified color intensity
                 ; sprites and backgrounds visible
                 ; sprites and backgrounds not clipped
                 ; color display
  sta $2001

  cli ; enable interrupts

loop: jmp loop ; transfer control to VBlank routines

init_graphics:
  jsr init_sprites
  jsr load_palette
  jsr load_name_tables
  rts

init_sprites:
  ; clear page 2, used to hold sprite data
  lda #$00
  ldx #$00
* sta sprite,x
  inx
  bne -

  ; initialize sprite 0
  lda #$70
  sta player   ; Y coordinate
  lda #$00
  sta player+2 ; no flip, in front, first palette
  sta player+3 ; X coordinate
  lda #$01
  sta player+1 ; tile index

  ; Due to the clearing of page 2, all the other sprites will be
  ; positioned at (0,0), with all flags set to 0. In particular, the
  ; tile index will be 0, so if it's easier to work with sprites where
  ; the tile index is 0-indexed, then the rest of page 2 needs to be set
  ; so that all other tiles at (0,0) are transparent.

  rts

load_palette:
  lda #$3F  ; write the address $3F00 to PPU address port
  sta $2006 ; write the high byte
  lda #$00
  sta $2006 ; write the low byte

  ldx #$00
* lda palette, x ; load data from address (palette_data + x)
  sta $2007      ; write data to PPU
  inx
  cpx #$20       ; loop if x != $20
  bne -

  rts

load_name_tables:
  ; load 1KB of data into the first name table
  ; $2000 and $2400 mirrored, so we can fill $2400 and $2800
  ldy #$00
  ldx #$04
  lda #<bg
  sta $10
  lda #>bg
  sta $11
  lda #$24
  sta $2006
  lda #$00
  sta $2006
* lda ($10),y
  sta $2007
  iny
  bne -
  inc $11
  dex
  bne -

  ; clear out $2800
  ; we're already at $2800
  ldy #$00
  ldx #$04
  lda #$00
* sta $2007
  iny
  bne -
  dex
  bne -

  rts

init_sound:
  lda #%00000011 ; length ctr not enabled
                 ; no delta modulation
                 ; no noise
                 ; no triangle
                 ; yes pulse #2
                 ; yes pulse #1
  sta $4015
  lda #0         ; sweep not enabled
                 ; period = 0
                 ; not negative
                 ; no shift
  sta $4001
  sta $4005
  lda #%01000000 ; 4-frame cycle
                 ; disable frame interrupt
  sta $4017
  rts

init_variables:
  ; XXX initialize global variables here, usually to 0
  rts

react_to_input:
  ; reset joypads
  lda #$01
  ldx #$00
  sta $4016
  stx $4016

  ; XXX the key to the entire project. Implement this!

  lda $4016 ; ignore A
  lda $4016 ; ignore B
  lda $4016 ; ignore SELECT
  lda $4016 ; ignore START
  lda $4016 ; ignore UP
  lda $4016 ; ignore DOWN
  lda $4016 ; ignore LEFT
  lda $4016 ; ignore RIGHT

  rts

snd_low_c:
  pha
  lda #%10000100 ; duty = 2
                 ; loop env/disable length = 0
                 ; env not disabled
                 ; vol/env period = 4
  sta $4000
                 ; middle C has a frequency of about 523 Hz, so the square
                 ; wave needed has a frequency of 261.5 Hz, which
                 ; corresponds to $1AA
  lda #%10101010 ; upper two nibbles of $1AA
  sta $4002
  lda #%00001001 ; length index = 0b00001, corresponds to 127 frames
                 ; upper three bits of $1AA
  sta $4003
  pla
  rts

snd_high_c:
  pha
  lda #%10000110 ; duty = 2
                 ; loop env/disable length = 0
                 ; env not disabled
                 ; vol/env period = 6
  sta $4004
                 ; high C has a frequency of about 2092 Hz, so the square
                 ; wave needed has a frequency of 1046 Hz, which
                 ; corresponds to $06A
  lda #%01101010 ; upper two nibbles of $06A
  sta $4006
  lda #%00001000 ; length index = 0b00001, corresponds to 127 frames
                 ; upper three bits of $06A
  sta $4007
  pla
  rts

vblank:
  jsr react_to_input

  ldx #$00  ; Reset VRAM
  stx $2006
  stx $2006

  lda #$00
  sta $2005 ; Write 0 for Horiz. Scroll value
  sta $2005 ; Write 0 for  Vert. Scroll value

  lda #>sprite
  sta $4014 ; move page $200-$2FF into SPR-RAM via DMA

irq   : rti ; vblank falls through to here

  ; Palettes
palette:
  ; Background palette, a wide variety of colors
  .byte $0F,$10,$00,$30 ; grays
  .byte $2D,$15,$2A,$22 ; slightly lighter
  .byte $00,$35,$39,$32 ; even lighter
  .byte $30,$30,$30,$30 ; whites
  ; Sprite palette, background is dark blue
  .byte $0F,$31,$1C,$0F ; top of ghost, normal
  .byte $0F,$31,$1C,$16 ; bottom of ghost, normal
  .byte $0F,$26,$08,$30 ; top of ghost, inverted
  .byte $0F,$26,$08,$2C ; bottom of ghost, inverted

bg:
  ; 32x30
  .advance bg+960

  ; attribute table
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .advance $FFFA
  .word vblank, reset, irq

  ; CHR-ROM

  ; This is a Mapper #0 cartridge, so the CHR-ROM is an 8K block of
  ; data mapped directly into the first $2000 bytes of the PPU's
  ; address space. Correspondingly, we begin by setting the origin to
  ; $0000.
  .org $0000

  ; Pattern Table #0: Background

  ; A single, transparent 8x8 tile
  .byte $00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00

  .advance $1000 ; The rest of Pattern Table #0 is blank

  ; Pattern Table #1: Sprites

  ; A single, transparent 8x8 tile
  .byte $00,$00,$00,$00,$00,$00,$00,$00
  .byte $00,$00,$00,$00,$00,$00,$00,$00

  .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  .byte $00,$00,$00,$00,$00,$00,$00,$00
  
  .advance $2000 ; The rest of Pattern Table #1 is blank