INCLUDE "graphics.inc"
INCLUDE "input.inc"

; Development-only mine placement check. Set to 0 before final release.
DEF DEBUG_SHOW_MINES EQU 1

DEF BOARD_CELL_COUNT EQU BOARD_WIDTH * BOARD_HEIGHT
DEF MINE_COUNT       EQU 10
DEF CELL_MINE_BIT    EQU 4

SECTION "Board WRAM", WRAM0

wBoard::
    ds BOARD_CELL_COUNT
wMinesPlaced::
    ds 1
IF DEBUG_SHOW_MINES
wDebugMinesDrawPending::
    ds 1
ENDC

SECTION "Board", ROM0

Board_Init::
    xor a
    ld [wMinesPlaced], a
IF DEBUG_SHOW_MINES
    ld [wDebugMinesDrawPending], a
ENDC
    ld hl, wBoard
    ld b, BOARD_CELL_COUNT
.clear:
    ld [hli], a
    dec b
    jr nz, .clear
    ret

Board_HandleInput::
    ld a, [wJoyPressed]
    and PAD_A
    ret z
    jp Board_PlaceMinesIfNeeded

Board_UpdateDebugDisplay::
IF DEBUG_SHOW_MINES
    ld a, [wDebugMinesDrawPending]
    and a
    ret z
    call Board_DebugDrawMines
    xor a
    ld [wDebugMinesDrawPending], a
ENDC
    ret

Board_PlaceMinesIfNeeded::
    ld a, [wMinesPlaced]
    and a
    ret nz

    call Random_SeedFromFrameCounter
    call Board_GetCursorIndex
    ld e, a
    ld d, MINE_COUNT

.placeNext:
    call Board_RandomCellIndex
    cp e
    jr z, .placeNext

    ld c, a
    ld b, 0
    ld hl, wBoard
    add hl, bc
    bit CELL_MINE_BIT, [hl]
    jr nz, .placeNext

    set CELL_MINE_BIT, [hl]
    dec d
    jr nz, .placeNext

    ld a, 1
    ld [wMinesPlaced], a
IF DEBUG_SHOW_MINES
    ld [wDebugMinesDrawPending], a
ENDC
    ret

; Returns the current cursor cell index in A.
; Clobbers: AF, B
Board_GetCursorIndex:
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

; Returns a random board cell index 0-80 in A.
; Rejection keeps the distribution simple and bounded for valid cells.
Board_RandomCellIndex:
    call Random_Next
    and $7F
    cp BOARD_CELL_COUNT
    jr nc, Board_RandomCellIndex
    ret

IF DEBUG_SHOW_MINES
; Debug-only: reveal placed mines on the BG map for placement verification.
; Called from the next VBlank after placement so VRAM writes are reliable.
; Non-mine cells are left untouched.
Board_DebugDrawMines:
    ld hl, wBoard
    ld de, BG_MAP + BOARD_BG_Y * BG_MAP_WIDTH + BOARD_BG_X
    ld b, BOARD_HEIGHT
.row:
    ld c, BOARD_WIDTH
.column:
    bit CELL_MINE_BIT, [hl]
    jr z, .nextCell
    ld a, TILE_MINE
    ld [de], a
.nextCell:
    inc hl
    inc de
    dec c
    jr nz, .column
    ld a, BG_MAP_WIDTH - BOARD_WIDTH
    add e
    ld e, a
    jr nc, .nextRow
    inc d
.nextRow:
    dec b
    jr nz, .row
    ret
ENDC
