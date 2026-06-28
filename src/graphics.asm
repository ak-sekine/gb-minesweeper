INCLUDE "hardware.inc"
INCLUDE "graphics.inc"

SECTION "Graphics", ROM0

GraphicsInit::
    call DisableLCD
    call LoadTiles
    call DrawTitleScreen
    call ClearOAM

    xor a
    ldh [rSCX], a
    ldh [rSCY], a
    ; BG palette: color numbers 0-3 map from lightest to darkest.
    ld a, %11100100
    ldh [rBGP], a
    ; Cursor Sprite palette: color 0 is transparent, color 1 is lightest.
    ld a, %11100001
    ldh [rOBP0], a
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_BG9800 | LCDCF_BGON
    ldh [rLCDC], a
    ret

Graphics_ResetPlayfield::
    call DisableLCD
    call LoadGameTiles
    call ClearOAM
    call ClearBGMap
    call DrawStatusBar
    call DrawClosedBoard
    call ClearEndMessageRow
    jp EnableLCD

Graphics_DrawTitleScreen::
    call DisableLCD
    call LoadTiles
    call ClearOAM
    call DrawTitleScreen
    jp EnableLCD

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
    call LoadGameTiles

    ld hl, TitleTiles
    ld de, $8000 + TILE_TITLE_BASE * TILE_BYTES
    ld bc, TitleTilesEnd - TitleTiles
    call CopyBytes

    ret

LoadGameTiles:
    ld hl, Tiles
    ld de, $8000
    ld bc, TilesEnd - Tiles
    call CopyBytes

    ; TILE_BLANK is a generated blank background tile used to clear the tile map.
    xor a
    ld hl, $8000 + TILE_BLANK * TILE_BYTES
    ld b, TILE_BYTES
.clearBlankTile:
    ld [hli], a
    dec b
    jr nz, .clearBlankTile

    ; Font tiles are ordered as 0-9, colon, A-Z, then project symbols.
    ld hl, FontTiles
    ld de, $8000 + TILE_DIGIT_0 * TILE_BYTES
    ld bc, FONT_UI_TILE_COUNT * TILE_BYTES
    call CopyBytes

    ; Cursor Sprite tiles are stored separately from BG tiles at VRAM tiles 52-55.
    ld hl, CursorTiles
    ld de, $8000 + TILE_CURSOR_TL * TILE_BYTES
    ld bc, CURSOR_TILE_COUNT * TILE_BYTES
    jp CopyBytes

EnableLCD:
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_BG9800 | LCDCF_BGON
    ldh [rLCDC], a
    ret

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

ClearOAM:
    xor a
    ld hl, OAM_BASE
    ld b, OAM_SIZE
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

DrawTitleScreen:
    call ClearBGMap
    call DrawTitleLogo
    call DrawPressStartText
    jp DrawCopyrightText

DrawTitleLogo:
    ld hl, TitleMap
    ld de, BG_MAP + TITLE_LOGO_BG_Y * BG_MAP_WIDTH + TITLE_LOGO_BG_X
    ld b, TITLE_LOGO_HEIGHT
.row:
    ld c, TITLE_LOGO_WIDTH
.column:
    ld a, [hli]
    add TILE_TITLE_BASE
    ld [de], a
    inc de
    dec c
    jr nz, .column
    ld a, e
    add BG_MAP_WIDTH - TITLE_LOGO_WIDTH
    ld e, a
    jr nc, .nextRow
    inc d
.nextRow:
    dec b
    jr nz, .row
    ret

DrawPressStartText:
    ld hl, PressStartText
    ld de, BG_MAP + TITLE_PRESS_START_Y * BG_MAP_WIDTH + TITLE_PRESS_START_X
    jp DrawText

DrawCopyrightText:
    ld hl, CopyrightText
    ld de, BG_MAP + TITLE_COPYRIGHT_Y * BG_MAP_WIDTH + TITLE_COPYRIGHT_X
    jp DrawText

DrawText:
    ld a, [hli]
    cp $FF
    ret z
    ld [de], a
    inc de
    jr DrawText

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

ClearEndMessageRow:
    ld hl, BG_MAP + 14 * BG_MAP_WIDTH
    ld b, 20
    ld a, TILE_BLANK
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

ClearTitleScreenAreas:
    call ClearTitleLogoArea
    call ClearPressStartRow
    jp ClearCopyrightRow

ClearTitleLogoArea:
    ld hl, BG_MAP + TITLE_LOGO_BG_Y * BG_MAP_WIDTH + TITLE_LOGO_BG_X
    ld b, TITLE_LOGO_HEIGHT
.row:
    ld c, TITLE_LOGO_WIDTH
    ld a, TILE_BLANK
.column:
    ld [hli], a
    dec c
    jr nz, .column
    ld de, BG_MAP_WIDTH - TITLE_LOGO_WIDTH
    add hl, de
    dec b
    jr nz, .row
    ret

ClearPressStartRow:
    ld hl, BG_MAP + TITLE_PRESS_START_Y * BG_MAP_WIDTH
    jr ClearTitleTextRow

ClearCopyrightRow:
    ld hl, BG_MAP + TITLE_COPYRIGHT_Y * BG_MAP_WIDTH

ClearTitleTextRow:
    ld b, TITLE_TEXT_ROW_WIDTH
    ld a, TILE_BLANK
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret

StatusText:
    db TILE_LETTER_A + 'M' - 'A', TILE_LETTER_A + 'I' - 'A'
    db TILE_LETTER_A + 'N' - 'A', TILE_LETTER_A + 'E' - 'A'
    db TILE_COLON, TILE_DIGIT_0 + 0, TILE_DIGIT_0 + 1, TILE_DIGIT_0 + 0
    db TILE_BLANK
    db TILE_LETTER_A + 'T' - 'A', TILE_LETTER_A + 'I' - 'A'
    db TILE_LETTER_A + 'M' - 'A', TILE_LETTER_A + 'E' - 'A'
    db TILE_COLON, TILE_DIGIT_0 + 0, TILE_DIGIT_0 + 0, TILE_DIGIT_0 + 0, $FF

PressStartText:
    db TILE_LETTER_A + 'P' - 'A', TILE_LETTER_A + 'R' - 'A'
    db TILE_LETTER_A + 'E' - 'A', TILE_LETTER_A + 'S' - 'A'
    db TILE_LETTER_A + 'S' - 'A', TILE_BLANK
    db TILE_LETTER_A + 'S' - 'A', TILE_LETTER_A + 'T' - 'A'
    db TILE_LETTER_A + 'A' - 'A', TILE_LETTER_A + 'R' - 'A'
    db TILE_LETTER_A + 'T' - 'A', $FF

CopyrightText:
    db TILE_COPYRIGHT
    db TILE_DIGIT_0 + 2, TILE_DIGIT_0 + 0, TILE_DIGIT_0 + 2, TILE_DIGIT_0 + 6
    db TILE_BLANK
    db TILE_LETTER_A + 'A' - 'A', TILE_LETTER_A + 'K' - 'A'
    db TILE_LETTER_A + 'I' - 'A', TILE_LETTER_A + 'H' - 'A'
    db TILE_LETTER_A + 'I' - 'A', TILE_LETTER_A + 'R' - 'A'
    db TILE_LETTER_A + 'O' - 'A', TILE_BLANK
    db TILE_LETTER_A + 'S' - 'A', TILE_LETTER_A + 'E' - 'A'
    db TILE_LETTER_A + 'K' - 'A', TILE_LETTER_A + 'I' - 'A'
    db TILE_LETTER_A + 'N' - 'A', TILE_LETTER_A + 'E' - 'A', $FF

SECTION "Graphics Data", ROM0

Tiles:
    INCBIN "obj/tiles.2bpp"
TilesEnd:

FontTiles:
    INCBIN "obj/font.2bpp"

CursorTiles:
    INCBIN "obj/cursor.2bpp"

TitleTiles:
    INCBIN "obj/title_tiles.2bpp"
TitleTilesEnd:

TitleMap:
    INCBIN "obj/title_map.bin"
