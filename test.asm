        .inesprg 1              ;1x 16KB PRG code
        .ineschr 1              ;1x 8KB CHR data
        .inesmap 0              ;mapper 0 = NROM, no bank swapping
        .inesmir 1              ;background mirroring

        .bank 0
        .org $C000
RESET:
        SEI                     ;disable IRQs
        CLD                     ;NES doesn't support decimals, disable
        LDX #$40
        STX $4017
        LDX #$FF
        TXS                     ;setup stack (transferring FF value to stack reg)
        INX                     ;due to carry reg, x reverts back to 0
        STX $2000               ;disable NMI
        STX $2001               ;disable rendering
        STX $4010               ;disable DMC IRQs

vblankwait1:                    ;wait for vblank to check PPU readiness
        BIT $2002               ;reading PPU status reg
        BPL vblankwait1

clrmem:                         ;clearing memory (setting accumulator to 00, then storing it to all memory addresses)
        LDA #$00
        STA $0000, x
        STA $0100, x
	STA $0200, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0300, x
	INX
	BNE clrmem

vblankwait2:                    ;second vblank wait, PPU should be ready
        BIT $2002
        BPL vblankwait2

LoadPalette:
        LDA $2002               ;read PPU status to reset high/low latch
        LDA #$3F               
        STA $2006               ;write high byte of $3F00 address 
        LDA #$00
        STA $2006               ;write low byte of $3F00 address
        LDX #$00                ;start at 0
LoadBackgroundPaletteLoop:
        LDA background_palette,x ;load data from address (palette + value in x)
        STA $2007                ;write palette data to PPU
        INX                      ;incrementing X
        CPX #$10                 ;checking if X is 10
        BNE LoadBackgroundPaletteLoop     ;will continue loop if compare isnt equal to zero
        LDX #$00

LoadSpritePaletteLoop:
        LDA sprite_palette,x    ;loading palette byte
        STA $2007               ;write to PPU
        INX                     ;increment X to cycle to next byte
        CPX #$10
        BNE LoadSpritePaletteLoop ;same as above, will continue loop as long as the compare isnt equal to zero

        LDA #%1000000           ;setting PPU control registers. this one sets the PPU to generate an NMI at the start of the vblank interval (enables NMI)
        STA $2000
        LDA #%0001000           ;and this one sets the PPU to show sprites
        STA $2001
        
        
Foreverloop:
        JMP Foreverloop         ;infinite loop

NMI:
        LDA #$00
        STA $2003               ;set high byte of the ram address 0200
        LDA #$02
        STA $4014               ;set low byte, start transfer

DrawSprite:                     ;main sprite drawing subroutine
        LDA #$08                ;top of the screen
        STA $0200               ;setting sprite y position to top
        LDA #$3A                ;top left section of mario
        STA $0201               ;sprite tile number
        LDA #$00                ;no attributes
        STA $0202               ;sprite attributes
        LDA #$08                ;left of screen
        STA $0203               ;sprite y position

        
        RTI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        .bank 1                 ;setting bank 1
        .org $E000              ;start vector for palettes
background_palette:
        .db $22,$29,$1A,$0F     ;background palette 1
        .db $22,$36,$17,$0F	;background palette 2
        .db $22,$30,$21,$0F	;background palette 3
        .db $22,$27,$17,$0F	;background palette 4
sprite_palette:
        .db $22,$16,$27,$18	;sprite palette 1
        .db $22,$1A,$30,$27	;sprite palette 2
        .db $22,$16,$30,$27	;sprite palette 3
        .db $22,$0F,$36,$17     ;sprite palette 4

        .org $FFFA              ;first vector starts here
        .dw NMI                 ;when the processor jumps to the NMI, it will go to the NMI label
        .dw RESET               ;same as NMI, but jumps to RESET every reset
        .dw 0    

        
        .bank 2
        .org $0000
        .incbin "mario.chr"     ;8KB graphics file from SMB1, just for testing
