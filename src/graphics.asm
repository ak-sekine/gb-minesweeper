INCLUDE "hardware.inc"
INCLUDE "graphics.inc"

SECTION "Graphics", ROM0

GraphicsInit::
    call DisableLCD
    call LoadTiles
    call ClearBGMap
    call DrawStatusBar
    call DrawClosedBoard

    xor a
    ldh [rSCX], a
    ldh [rSCY], a
    ld a, %11100100
    ldh [rBGP], a
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_BGON
    ldh [rLCDC], a
    ret

DisableLCD:
    ldh a, [rLCDC]
    bit 7, a
    ret z
.waitVBlank:
    ldh a, [rLY]
    cp 144
    jr c, .waitVBlank
    xor a
    ldh [rLCDC], a
    ret

LoadTiles:
    ld hl, Tiles
    ld de, $8000
    ld bc, TilesEnd - Tiles
    call CopyBytes

    ; Tile 15 is a blank background tile used to clear the tile map.
    xor a
    ld hl, $8000 + TILE_BLANK * TILE_BYTES
    ld b, TILE_BYTES
.clearBlankTile:
    ld [hli], a
    dec b
    jr nz, .clearBlankTile

    ; The first 37 font tiles are ordered as 0-9, colon, then A-Z.
    ld hl, FontTiles
    ld de, $8000 + TILE_DIGIT_0 * TILE_BYTES
    ld bc, FONT_UI_TILE_COUNT * TILE_BYTES
    jp CopyBytes

CopyBytes:
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, CopyBytes
    ret

ClearBGMap:
    ld hl, BG_MAP
    ld bc, BG_MAP_WIDTH * BG_MAP_HEIGHT
    ld a, TILE_BLANK
.loop:
    ld [hli], a
    dec bc
    ld d, a
    ld a, b
    or c
    ld a, d
    jr nz, .loop
    ret

DrawStatusBar:
    ld hl, StatusText
    ld de, BG_MAP + STATUS_BG_Y * BG_MAP_WIDTH + STATUS_BG_X
.loop:
    ld a, [hli]
    cp $FF
    ret z
    ld [de], a
    inc de
    jr .loop

DrawClosedBoard:
    ld hl, BG_MAP + BOARD_BG_Y * BG_MAP_WIDTH + BOARD_BG_X
    ld de, BG_MAP_WIDTH - BOARD_WIDTH
    ld b, BOARD_HEIGHT
    ld a, TILE_CLOSED
.row:
    ld c, BOARD_WIDTH
.column:
    ld [hli], a
    dec c
    jr nz, .column
    add hl, de
    dec b
    jr nz, .row
    ret

StatusText:
    db TILE_LETTER_A + 'M' - 'A', TILE_LETTER_A + 'I' - 'A'
    db TILE_LETTER_A + 'N' - 'A', TILE_LETTER_A + 'E' - 'A'
    db TILE_COLON, TILE_DIGIT_0 + 0, TILE_DIGIT_0 + 1, TILE_DIGIT_0 + 0
    db TILE_BLANK
    db TILE_LETTER_A + 'T' - 'A', TILE_LETTER_A + 'I' - 'A'
    db TILE_LETTER_A + 'M' - 'A', TILE_LETTER_A + 'E' - 'A'
    db TILE_COLON, TILE_DIGIT_0 + 0, TILE_DIGIT_0 + 0, TILE_DIGIT_0 + 0, $FF

SECTION "Graphics Data", ROM0

Tiles:
    INCBIN "obj/tiles.2bpp"
TilesEnd:

FontTiles:
    INCBIN "obj/font.2bpp"
