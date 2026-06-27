INCLUDE "graphics.inc"
INCLUDE "input.inc"

; Development-only mine placement check. Set to 0 before final release.
DEF DEBUG_SHOW_MINES EQU 0

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
wDebugDrawRow::
    ds 1
ENDC
wBoardGenX::
    ds 1
wBoardGenY::
    ds 1

SECTION "Board", ROM0

Board_Init::
    xor a
    ld [wMinesPlaced], a
IF DEBUG_SHOW_MINES
    ld [wDebugMinesDrawPending], a
    ld [wDebugDrawRow], a
ENDC
    ld hl, wBoard
    ld b, BOARD_CELL_COUNT
.clear:
    ld [hli], a
    dec b
    jr nz, .clear
    ret

Board_UpdateDebugDisplay::
IF DEBUG_SHOW_MINES
    ld a, [wDebugMinesDrawPending]
    and a
    ret z
    call Board_DebugDrawNextRow
    ld a, [wDebugDrawRow]
    cp BOARD_HEIGHT
    ret c
    xor a
    ld [wDebugMinesDrawPending], a
    ld [wDebugDrawRow], a
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

    call Board_GenerateNumbers

    ld a, 1
    ld [wMinesPlaced], a
IF DEBUG_SHOW_MINES
    ld [wDebugMinesDrawPending], a
    xor a
    ld [wDebugDrawRow], a
ENDC
    ret

Board_GenerateNumbers:
    ld hl, wBoard
    ld b, BOARD_CELL_COUNT
.clearNumbers:
    ld a, [hl]
    and $F0
    ld [hli], a
    dec b
    jr nz, .clearNumbers

    ld hl, wBoard
    xor a
    ld [wBoardGenY], a
.row:
    xor a
    ld [wBoardGenX], a
.column:
    bit CELL_MINE_BIT, [hl]
    jr z, .nextCell
    push hl
    call Board_IncrementMineNeighbors
    pop hl
.nextCell:
    inc hl
    ld a, [wBoardGenX]
    inc a
    ld [wBoardGenX], a
    cp BOARD_WIDTH
    jr c, .column
    ld a, [wBoardGenY]
    inc a
    ld [wBoardGenY], a
    cp BOARD_HEIGHT
    jr c, .row
    ret

Board_IncrementMineNeighbors:
    ld a, [wBoardGenY]
    and a
    jr z, .sameRow
    dec a
    call Board_IncrementNeighborRow

.sameRow:
    ld a, [wBoardGenY]
    call Board_IncrementSideNeighbors

    ld a, [wBoardGenY]
    cp BOARD_HEIGHT - 1
    ret z
    inc a
    call Board_IncrementNeighborRow
    ret

Board_IncrementNeighborRow:
    ld d, a
    ld a, [wBoardGenX]
    and a
    jr z, .center
    dec a
    ld e, a
    push de
    call Board_IncrementCellAtXY
    pop de
.center:
    ld a, [wBoardGenX]
    ld e, a
    push de
    call Board_IncrementCellAtXY
    pop de
    ld a, [wBoardGenX]
    cp BOARD_WIDTH - 1
    ret z
    inc a
    ld e, a
    jp Board_IncrementCellAtXY

Board_IncrementSideNeighbors:
    ld d, a
    ld a, [wBoardGenX]
    and a
    jr z, .right
    dec a
    ld e, a
    push de
    call Board_IncrementCellAtXY
    pop de
.right:
    ld a, [wBoardGenX]
    cp BOARD_WIDTH - 1
    ret z
    inc a
    ld e, a
    jp Board_IncrementCellAtXY

; Increments the low-nibble number at (E, D) unless that cell is a mine.
; Clobbers: AF, BC, HL
Board_IncrementCellAtXY:
    ld a, d
    ld b, a
    add a
    add a
    add a
    add b
    add e
    ld c, a
    ld b, 0
    ld hl, wBoard
    add hl, bc
    bit CELL_MINE_BIT, [hl]
    ret nz
    inc [hl]
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
; Debug-only: reveal one row per VBlank so VRAM writes stay bounded.
Board_DebugDrawNextRow:
    ld a, [wDebugDrawRow]
    ld b, a
    add a
    add a
    add a
    add b
    ld c, a
    ld b, 0
    ld hl, wBoard
    add hl, bc

    ld de, BG_MAP + BOARD_BG_Y * BG_MAP_WIDTH + BOARD_BG_X
    ld a, [wDebugDrawRow]
    ld b, a
    and a
    jr z, .draw
.advanceBgRow:
    ld a, e
    add BG_MAP_WIDTH
    ld e, a
    jr nc, .nextBgRow
    inc d
.nextBgRow:
    dec b
    jr nz, .advanceBgRow
.draw:
    ld c, BOARD_WIDTH
.column:
    ld a, [hl]
    bit CELL_MINE_BIT, [hl]
    jr z, .drawNumber
    ld a, TILE_MINE
    jr .store
.drawNumber:
    and $0F
    add TILE_OPEN_0
.store:
    ld [de], a
    inc hl
    inc de
    dec c
    jr nz, .column
    ld a, [wDebugDrawRow]
    inc a
    ld [wDebugDrawRow], a
    ret
ENDC
