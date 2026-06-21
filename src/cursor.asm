INCLUDE "graphics.inc"
INCLUDE "input.inc"
INCLUDE "hardware.inc"

SECTION "Cursor WRAM", WRAM0

wCursorX::
    ds 1
wCursorY::
    ds 1

SECTION "Cursor", ROM0

; Initializes the grid cursor at the top-left cell and updates Sprite 0.
; Call during VBlank when the LCD is enabled.
Cursor_Init::
    xor a
    ld [wCursorX], a
    ld [wCursorY], a
    jp Cursor_UpdateSprite

; Moves at most one cell per axis for newly pressed directional buttons.
; Opposing buttons use Right and Down as their respective priorities.
; Clobbers: AF, B
Cursor_Update::
    ld a, [wJoyPressed]
    ld b, a

    and PAD_RIGHT
    jr z, .checkLeft
    ld a, [wCursorX]
    cp BOARD_WIDTH - 1
    jr z, .updateVertical
    inc a
    ld [wCursorX], a
    jr .updateVertical

.checkLeft:
    ld a, b
    and PAD_LEFT
    jr z, .updateVertical
    ld a, [wCursorX]
    and a
    jr z, .updateVertical
    dec a
    ld [wCursorX], a

.updateVertical:
    ld a, b
    and PAD_DOWN
    jr z, .checkUp
    ld a, [wCursorY]
    cp BOARD_HEIGHT - 1
    jr z, Cursor_UpdateSprite
    inc a
    ld [wCursorY], a
    jr Cursor_UpdateSprite

.checkUp:
    ld a, b
    and PAD_UP
    jr z, Cursor_UpdateSprite
    ld a, [wCursorY]
    and a
    jr z, Cursor_UpdateSprite
    dec a
    ld [wCursorY], a

; Converts grid coordinates to Game Boy OAM coordinates and writes Sprite 0.
; OAM X is screen X + 8, and OAM Y is screen Y + 16.
; Call only while OAM is accessible, normally during VBlank.
Cursor_UpdateSprite::
    ld a, [wCursorY]
    add a
    add a
    add a
    add BOARD_BG_Y * 8 + 16
    ld [OAM_BASE], a

    ld a, [wCursorX]
    add a
    add a
    add a
    add BOARD_BG_X * 8 + 8
    ld [OAM_BASE + 1], a

    ld a, TILE_CURSOR
    ld [OAM_BASE + 2], a
    xor a
    ld [OAM_BASE + 3], a
    ret
