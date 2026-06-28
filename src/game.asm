INCLUDE "graphics.inc"
INCLUDE "input.inc"

DEF BOARD_CELL_COUNT EQU BOARD_WIDTH * BOARD_HEIGHT
DEF CELL_MINE_BIT    EQU 4
DEF CELL_OPENED_BIT  EQU 5
DEF CELL_FLAG_BIT    EQU 6
DEF GAME_OVER_TEXT_LEN EQU 9
DEF GAME_OVER_BG_X     EQU 5
DEF GAME_OVER_BG_Y     EQU 14

SECTION "Game WRAM", WRAM0

wGameDrawQueue::
    ds BOARD_CELL_COUNT
wGameDrawTileQueue::
    ds BOARD_CELL_COUNT
wGameDrawHead::
    ds 1
wGameDrawTail::
    ds 1
wOpenQueueX::
    ds BOARD_CELL_COUNT
wOpenQueueY::
    ds BOARD_CELL_COUNT
wOpenQueueHead::
    ds 1
wOpenQueueTail::
    ds 1
wGameWorkIndex::
    ds 1
wGameWorkCell::
    ds 1
wGameDrawTileValue::
    ds 1
wGameCenterX::
    ds 1
wGameCenterY::
    ds 1
wGameTriggeredMineIndex::
    ds 1
wGameOverMessageDrawIndex::
    ds 1
wGameOver::
    ds 1

SECTION "Game", ROM0

Game_Init::
    xor a
    ld [wGameDrawHead], a
    ld [wGameDrawTail], a
    ld [wGameOverMessageDrawIndex], a
    ld [wGameOver], a
    ret

Game_UpdateDisplay::
    ld a, [wGameDrawHead]
    ld b, a
    ld a, [wGameDrawTail]
    cp b
    jp z, Game_UpdateGameOverMessage

    ld a, b
    ld c, a
    ld b, 0
    ld hl, wGameDrawQueue
    add hl, bc
    ld a, [hl]
    ld [wGameWorkIndex], a
    ld hl, wGameDrawTileQueue
    add hl, bc
    ld a, [hl]
    ld [wGameWorkCell], a

    ld a, [wGameDrawHead]
    inc a
    ld [wGameDrawHead], a

    call Game_GetBGAddressForWorkIndex
    ld a, [wGameWorkCell]
    and a
    jr nz, .useQueuedTile
    push hl
    call Game_GetTileForWorkIndex
    pop hl
    jr .storeTile
.useQueuedTile:
    dec a
.storeTile:
    ld [hl], a
    ret

Game_UpdateGameOverMessage:
    ld a, [wGameOver]
    and a
    ret z

    ld a, [wGameOverMessageDrawIndex]
    cp GAME_OVER_TEXT_LEN
    ret nc

    ld c, a
    ld b, 0
    ld hl, GameOverText
    add hl, bc
    ld a, [hl]
    ld hl, BG_MAP + GAME_OVER_BG_Y * BG_MAP_WIDTH + GAME_OVER_BG_X
    add hl, bc
    ld [hl], a

    ld a, [wGameOverMessageDrawIndex]
    inc a
    ld [wGameOverMessageDrawIndex], a
    ret

Game_HandleInput::
    ld a, [wGameOver]
    and a
    ret nz

    ld a, [wJoyPressed]
    and PAD_A
    jr z, .checkFlag

    call Game_GetCursorIndex
    ld [wGameWorkIndex], a
    call Board_PlaceMinesIfNeeded
    call Game_OpenWorkIndex
    ret

.checkFlag:
    ld a, [wJoyPressed]
    and PAD_B
    ret z
    jp Game_ToggleCursorFlag

Game_OpenWorkIndex:
    call Game_GetCellAddressForWorkIndex
    bit CELL_OPENED_BIT, [hl]
    ret nz
    bit CELL_FLAG_BIT, [hl]
    ret nz

    set CELL_OPENED_BIT, [hl]
    ld a, [hl]
    ld [wGameWorkCell], a
    bit CELL_MINE_BIT, a
    jp nz, Game_TriggerGameOver

    call Game_EnqueueDrawWorkIndexAuto

    ld a, [wGameWorkCell]
    and $0F
    ret nz

    call Game_InitOpenQueue
    ld a, [wCursorX]
    ld e, a
    ld a, [wCursorY]
    ld d, a
    call Game_EnqueueOpenXY
    jp Game_ProcessOpenQueue

Game_ProcessOpenQueue:
    ld a, [wOpenQueueHead]
    ld b, a
    ld a, [wOpenQueueTail]
    cp b
    ret z

    call Game_DequeueOpenXY
    call Game_OpenNeighborsOfCenter
    jr Game_ProcessOpenQueue

Game_OpenNeighborsOfCenter:
    ld a, [wGameCenterY]
    and a
    jr z, .sameRow
    dec a
    ld d, a
    call Game_OpenNeighborRow

.sameRow:
    ld a, [wGameCenterY]
    ld d, a
    call Game_OpenSideNeighbors

    ld a, [wGameCenterY]
    cp BOARD_HEIGHT - 1
    ret z
    inc a
    ld d, a
    jp Game_OpenNeighborRow

Game_OpenNeighborRow:
    ld a, [wGameCenterX]
    and a
    jr z, .center
    dec a
    ld e, a
    push de
    call Game_TryOpenNeighbor
    pop de
.center:
    ld a, [wGameCenterX]
    ld e, a
    push de
    call Game_TryOpenNeighbor
    pop de
    ld a, [wGameCenterX]
    cp BOARD_WIDTH - 1
    ret z
    inc a
    ld e, a
    jp Game_TryOpenNeighbor

Game_OpenSideNeighbors:
    ld a, [wGameCenterX]
    and a
    jr z, .right
    dec a
    ld e, a
    push de
    call Game_TryOpenNeighbor
    pop de
.right:
    ld a, [wGameCenterX]
    cp BOARD_WIDTH - 1
    ret z
    inc a
    ld e, a
    jp Game_TryOpenNeighbor

Game_TryOpenNeighbor:
    call Game_XYToIndex
    ld [wGameWorkIndex], a
    call Game_GetCellAddressForWorkIndex
    bit CELL_OPENED_BIT, [hl]
    ret nz
    bit CELL_FLAG_BIT, [hl]
    ret nz
    bit CELL_MINE_BIT, [hl]
    ret nz

    set CELL_OPENED_BIT, [hl]
    ld a, [hl]
    ld [wGameWorkCell], a
    call Game_EnqueueDrawWorkIndexAuto

    ld a, [wGameWorkCell]
    and $0F
    ret nz
    jp Game_EnqueueOpenXY

Game_ToggleCursorFlag:
    call Game_GetCursorIndex
    ld [wGameWorkIndex], a
    call Game_GetCellAddressForWorkIndex
    bit CELL_OPENED_BIT, [hl]
    ret nz
    bit CELL_FLAG_BIT, [hl]
    jr nz, .clearFlag

    set CELL_FLAG_BIT, [hl]
    ld a, TILE_FLAG
    jr .draw

.clearFlag:
    res CELL_FLAG_BIT, [hl]
    ld a, TILE_CLOSED

.draw:
    ld [wGameWorkCell], a
    jp Game_EnqueueDrawWorkIndexWithTile

Game_TriggerGameOver:
    ld a, 1
    ld [wGameOver], a

    xor a
    ld [wGameDrawHead], a
    ld [wGameDrawTail], a
    ld [wGameOverMessageDrawIndex], a

    ld a, [wGameWorkIndex]
    ld [wGameTriggeredMineIndex], a
    xor a
    ld [wGameWorkIndex], a

.revealLoop:
    call Game_GetCellAddressForWorkIndex
    bit CELL_MINE_BIT, [hl]
    jr nz, .mineCell
    bit CELL_FLAG_BIT, [hl]
    jr nz, .wrongFlagCell
    jr .nextRevealCell

.mineCell:
    ld a, [wGameWorkIndex]
    ld b, a
    ld a, [wGameTriggeredMineIndex]
    cp b
    ld a, TILE_MINE
    jr nz, .enqueueRevealTile
    ld a, TILE_EXPLODED_MINE
    jr .enqueueRevealTile

.wrongFlagCell:
    ld a, TILE_WRONG_FLAG

.enqueueRevealTile:
    ld [wGameWorkCell], a
    call Game_EnqueueDrawWorkIndexWithTile

.nextRevealCell:
    ld a, [wGameWorkIndex]
    inc a
    ld [wGameWorkIndex], a
    cp BOARD_CELL_COUNT
    jr c, .revealLoop
    ret

Game_IsOver::
    ld a, [wGameOver]
    and a
    ret

GameOverText:
    db TILE_LETTER_A + 'G' - 'A'
    db TILE_LETTER_A + 'A' - 'A'
    db TILE_LETTER_A + 'M' - 'A'
    db TILE_LETTER_A + 'E' - 'A'
    db TILE_BLANK
    db TILE_LETTER_A + 'O' - 'A'
    db TILE_LETTER_A + 'V' - 'A'
    db TILE_LETTER_A + 'E' - 'A'
    db TILE_LETTER_A + 'R' - 'A'

Game_InitOpenQueue:
    xor a
    ld [wOpenQueueHead], a
    ld [wOpenQueueTail], a
    ret

Game_EnqueueOpenXY:
    ld a, [wOpenQueueTail]
    cp BOARD_CELL_COUNT
    ret nc
    ld c, a
    ld b, 0
    ld hl, wOpenQueueX
    add hl, bc
    ld [hl], e
    ld hl, wOpenQueueY
    add hl, bc
    ld [hl], d
    ld a, [wOpenQueueTail]
    inc a
    ld [wOpenQueueTail], a
    ret

Game_DequeueOpenXY:
    ld a, [wOpenQueueHead]
    ld c, a
    ld b, 0
    ld hl, wOpenQueueX
    add hl, bc
    ld a, [hl]
    ld [wGameCenterX], a
    ld hl, wOpenQueueY
    add hl, bc
    ld a, [hl]
    ld [wGameCenterY], a
    ld a, [wOpenQueueHead]
    inc a
    ld [wOpenQueueHead], a
    ret

Game_EnqueueDrawWorkIndexAuto:
    xor a
    ld [wGameDrawTileValue], a
    jr Game_EnqueueDrawWorkIndex

Game_EnqueueDrawWorkIndexWithTile:
    ld a, [wGameWorkCell]
    inc a
    ld [wGameDrawTileValue], a

Game_EnqueueDrawWorkIndex:
    ld a, [wGameDrawHead]
    ld b, a
    ld a, [wGameDrawTail]
    cp b
    jr nz, .enqueue
    xor a
    ld [wGameDrawHead], a
    ld [wGameDrawTail], a
.enqueue:
    ld a, [wGameDrawTail]
    cp BOARD_CELL_COUNT
    ret nc
    ld c, a
    ld b, 0
    ld hl, wGameDrawQueue
    add hl, bc
    ld a, [wGameWorkIndex]
    ld [hl], a
    ld hl, wGameDrawTileQueue
    add hl, bc
    ld a, [wGameDrawTileValue]
    ld [hl], a
    ld a, [wGameDrawTail]
    inc a
    ld [wGameDrawTail], a
    ret

Game_GetCellAddressForWorkIndex:
    ld a, [wGameWorkIndex]
    ld c, a
    ld b, 0
    ld hl, wBoard
    add hl, bc
    ret

Game_GetTileForWorkIndex:
    call Game_GetCellAddressForWorkIndex
    ld a, [hl]
    bit CELL_MINE_BIT, [hl]
    jr z, .numberTile
    ld a, TILE_MINE
    ret
.numberTile:
    and $0F
    add TILE_OPEN_0
    ret

Game_GetCursorIndex:
    ld a, [wCursorY]
    ld d, a
    ld a, [wCursorX]
    ld e, a
    jp Game_XYToIndex

Game_XYToIndex:
    ld a, d
    ld b, a
    add a
    add a
    add a
    add b
    ld b, a
    ld a, e
    add b
    ret

Game_GetBGAddressForWorkIndex:
    ld a, [wGameWorkIndex]
    ld d, 0
.rowLoop:
    cp BOARD_WIDTH
    jr c, .gotXY
    sub BOARD_WIDTH
    inc d
    jr .rowLoop
.gotXY:
    ld e, a
    ld hl, BG_MAP + BOARD_BG_Y * BG_MAP_WIDTH + BOARD_BG_X
    ld a, d
    and a
    jr z, .addX
.addRow:
    ld bc, BG_MAP_WIDTH
    add hl, bc
    dec a
    jr nz, .addRow
.addX:
    ld c, e
    ld b, 0
    add hl, bc
    ret
