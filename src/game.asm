INCLUDE "graphics.inc"
INCLUDE "input.inc"

DEF CELL_MINE_BIT   EQU 4
DEF CELL_OPENED_BIT EQU 5

SECTION "Game WRAM", WRAM0

wGameDrawPending::
    ds 1
wGameDrawTile::
    ds 1
wGameDrawBGAddress::
    ds 2

SECTION "Game", ROM0

Game_Init::
    xor a
    ld [wGameDrawPending], a
    ret

Game_UpdateDisplay::
    ld a, [wGameDrawPending]
    and a
    ret z
    ld a, [wGameDrawBGAddress]
    ld l, a
    ld a, [wGameDrawBGAddress + 1]
    ld h, a
    ld a, [wGameDrawTile]
    ld [hl], a
    xor a
    ld [wGameDrawPending], a
    ret

Game_HandleInput::
    ld a, [wJoyPressed]
    and PAD_A
    ret z

    call Board_PlaceMinesIfNeeded
    call Game_OpenCursorCell
    ret

Game_OpenCursorCell:
    call Game_GetCursorCellAddress
    bit CELL_OPENED_BIT, [hl]
    ret nz

    set CELL_OPENED_BIT, [hl]
    ld a, [hl]
    bit CELL_MINE_BIT, [hl]
    jr z, .numberTile
    ld a, TILE_MINE
    jr .draw

.numberTile:
    and $0F
    add TILE_OPEN_0

.draw:
    ld d, a
    call Game_GetCursorBGAddress
    ld a, d
    ld [wGameDrawTile], a
    ld a, l
    ld [wGameDrawBGAddress], a
    ld a, h
    ld [wGameDrawBGAddress + 1], a
    ld a, 1
    ld [wGameDrawPending], a
    ret

Game_GetCursorCellAddress:
    call Game_GetCursorIndex
    ld c, a
    ld b, 0
    ld hl, wBoard
    add hl, bc
    ret

Game_GetCursorIndex:
    ld a, [wCursorY]
    ld b, a
    add a
    add a
    add a
    add b
    ld b, a
    ld a, [wCursorX]
    add b
    ret

Game_GetCursorBGAddress:
    ld hl, BG_MAP + BOARD_BG_Y * BG_MAP_WIDTH + BOARD_BG_X
    ld a, [wCursorY]
    and a
    jr z, .addX
.addRow:
    ld bc, BG_MAP_WIDTH
    add hl, bc
    dec a
    jr nz, .addRow
.addX:
    ld a, [wCursorX]
    ld c, a
    ld b, 0
    add hl, bc
    ret
