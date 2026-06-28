INCLUDE "graphics.inc"
INCLUDE "input.inc"

DEF BOARD_CELL_COUNT EQU BOARD_WIDTH * BOARD_HEIGHT
DEF MINE_COUNT       EQU 10
DEF CELL_MINE_BIT    EQU 4
DEF CELL_OPENED_BIT  EQU 5
DEF CELL_FLAG_BIT    EQU 6
DEF GAME_OVER_TEXT_LEN EQU 9
DEF GAME_OVER_BG_X     EQU 5
DEF GAME_OVER_BG_Y     EQU 14
DEF CLEAR_TEXT_LEN     EQU 5
DEF CLEAR_BG_X         EQU 7
DEF CLEAR_BG_Y         EQU GAME_OVER_BG_Y
DEF STATUS_MINE_DIGITS_X EQU STATUS_BG_X + 5
DEF PAUSE_MENU_X       EQU 1
DEF PAUSE_MENU_Y       EQU 6
DEF PAUSE_MENU_WIDTH   EQU 19
DEF PAUSE_MENU_HEIGHT  EQU 7
DEF PAUSE_MENU_RESUME  EQU 0
DEF PAUSE_MENU_RESTART EQU 1
DEF PAUSE_MENU_TITLE   EQU 2

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
wGameMessageDrawIndex::
    ds 1
wGameOver::
    ds 1
wGameClear::
    ds 1
wGameRestartDrawPending::
    ds 1
wGameTitleDrawPending::
    ds 1
wGamePauseDrawPending::
    ds 1
wGamePauseCursorDrawPending::
    ds 1
wGameResumeDrawPending::
    ds 1
wGameFlagCount::
    ds 1
wGameMineDrawPending::
    ds 1
wGameTitle::
    ds 1
wGamePaused::
    ds 1
wGamePauseSelection::
    ds 1
wGamePreviousPauseSelection::
    ds 1

SECTION "Game", ROM0

Game_InitTitle::
    xor a
    ld [wGameDrawHead], a
    ld [wGameDrawTail], a
    ld [wOpenQueueHead], a
    ld [wOpenQueueTail], a
    ld [wGameMessageDrawIndex], a
    ld [wGameOver], a
    ld [wGameClear], a
    ld [wGameRestartDrawPending], a
    ld [wGameTitleDrawPending], a
    ld [wGamePauseDrawPending], a
    ld [wGamePauseCursorDrawPending], a
    ld [wGameResumeDrawPending], a
    ld [wGameFlagCount], a
    ld [wGameMineDrawPending], a
    ld [wGamePaused], a
    ld [wGamePauseSelection], a
    ld [wGamePreviousPauseSelection], a
    inc a
    ld [wGameTitle], a
    ret

Game_Init::
    xor a
    ld [wGameDrawHead], a
    ld [wGameDrawTail], a
    ld [wOpenQueueHead], a
    ld [wOpenQueueTail], a
    ld [wGameMessageDrawIndex], a
    ld [wGameOver], a
    ld [wGameClear], a
    ld [wGameRestartDrawPending], a
    ld [wGameTitleDrawPending], a
    ld [wGamePauseDrawPending], a
    ld [wGamePauseCursorDrawPending], a
    ld [wGameResumeDrawPending], a
    ld [wGameFlagCount], a
    ld [wGameMineDrawPending], a
    ld [wGameTitle], a
    ld [wGamePaused], a
    ld [wGamePauseSelection], a
    ld [wGamePreviousPauseSelection], a
    ret

Game_UpdateDisplay::
    ld a, [wGameTitleDrawPending]
    and a
    jr z, .checkRestartDraw

    xor a
    ld [wGameTitleDrawPending], a
    jp Graphics_DrawTitleScreen

.checkRestartDraw:
    ld a, [wGameResumeDrawPending]
    and a
    jr z, .checkPauseDraw

    xor a
    ld [wGameResumeDrawPending], a
    call Game_ClearPauseMenu
    jp Game_EnqueueFullBoardRedraw

.checkPauseDraw:
    ld a, [wGamePauseDrawPending]
    and a
    jr z, .checkRestartDrawPending

    xor a
    ld [wGamePauseDrawPending], a
    call Graphics_DisableLCD
    call Graphics_ClearOAM
    call Game_DrawPauseMenu
    jp Graphics_EnableLCD

.checkRestartDrawPending:
    ld a, [wGamePauseCursorDrawPending]
    and a
    jr z, .checkRestartDrawPendingFlag

    xor a
    ld [wGamePauseCursorDrawPending], a
    jp Game_UpdatePauseMenuCursor

.checkRestartDrawPendingFlag:
    ld a, [wGameRestartDrawPending]
    and a
    jr z, .updateQueuedCell

    ld a, [wGamePaused]
    and a
    ret nz

    xor a
    ld [wGameRestartDrawPending], a
    jp Graphics_ResetPlayfield

.updateQueuedCell:
    ld a, [wGamePaused]
    and a
    ret nz

    ld a, [wGameMineDrawPending]
    and a
    jr z, .checkDrawQueue

    xor a
    ld [wGameMineDrawPending], a
    jp Game_UpdateMineDisplay

.checkDrawQueue:
    ld a, [wGameDrawHead]
    ld b, a
    ld a, [wGameDrawTail]
    cp b
    jp z, Game_UpdateEndMessage

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

Game_UpdateEndMessage:
    ld a, [wGameOver]
    and a
    jr z, .checkClear

    ld a, [wGameMessageDrawIndex]
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

    ld a, [wGameMessageDrawIndex]
    inc a
    ld [wGameMessageDrawIndex], a
    ret

.checkClear:
    ld a, [wGameClear]
    and a
    ret z

    ld a, [wGameMessageDrawIndex]
    cp CLEAR_TEXT_LEN
    ret nc

    ld c, a
    ld b, 0
    ld hl, ClearText
    add hl, bc
    ld a, [hl]
    ld hl, BG_MAP + CLEAR_BG_Y * BG_MAP_WIDTH + CLEAR_BG_X
    add hl, bc
    ld [hl], a

    ld a, [wGameMessageDrawIndex]
    inc a
    ld [wGameMessageDrawIndex], a
    ret

Game_HandleInput::
    ld a, [wGameTitle]
    and a
    jr z, .checkEnded

    ld a, [wJoyPressed]
    and PAD_START
    ret z
    jp Game_StartFromTitle

.checkEnded:
    call Game_IsEnded
    jr z, .handlePlaying

    ld a, [wJoyPressed]
    and PAD_START
    ret z
    jp Game_ReturnToTitleAfterEnd

.handlePlaying:
    ld a, [wGamePaused]
    and a
    jp nz, Game_HandlePauseInput

    ld a, [wJoyPressed]
    and PAD_START
    jr z, .checkOpen
    jp Game_OpenPauseMenu

.checkOpen:
    ld a, [wJoyPressed]
    and PAD_A
    jr z, .checkFlag

    call Game_GetCursorIndex
    ld [wGameWorkIndex], a
    call Board_PlaceMinesIfNeeded
    call Game_OpenWorkIndex
    call Game_IsEnded
    ret nz
    call Game_CheckClear
    ret

.checkFlag:
    ld a, [wJoyPressed]
    and PAD_B
    ret z
    jp Game_ToggleCursorFlag

Game_OpenPauseMenu:
    xor a
    ld [wGameDrawHead], a
    ld [wGameDrawTail], a
    ld [wOpenQueueHead], a
    ld [wOpenQueueTail], a
    ld [wGamePauseSelection], a
    ld [wGamePreviousPauseSelection], a
    inc a
    ld [wGamePaused], a
    ld [wGamePauseDrawPending], a
    ret

Game_HandlePauseInput:
    ld a, [wJoyPressed]
    and PAD_B
    jp nz, Game_ResumeFromPause

    ld a, [wJoyPressed]
    and PAD_UP
    jr z, .checkDown
    ld a, [wGamePauseSelection]
    and a
    ret z
    ld [wGamePreviousPauseSelection], a
    dec a
    ld [wGamePauseSelection], a
    ld a, 1
    ld [wGamePauseCursorDrawPending], a
    ret

.checkDown:
    ld a, [wJoyPressed]
    and PAD_DOWN
    jr z, .checkConfirm
    ld a, [wGamePauseSelection]
    cp PAUSE_MENU_TITLE
    ret nc
    ld [wGamePreviousPauseSelection], a
    inc a
    ld [wGamePauseSelection], a
    ld a, 1
    ld [wGamePauseCursorDrawPending], a
    ret

.checkConfirm:
    ld a, [wJoyPressed]
    and PAD_A | PAD_START
    ret z

    ld a, [wGamePauseSelection]
    cp PAUSE_MENU_RESTART
    jp z, Game_RestartFromPause
    cp PAUSE_MENU_TITLE
    jp z, Game_ReturnToTitleFromPause
    jp Game_ResumeFromPause

Game_ResumeFromPause:
    xor a
    ld [wGamePaused], a
    inc a
    ld [wGameResumeDrawPending], a
    ret

Game_RestartFromPause:
    call Board_Init
    call Cursor_ResetPosition
    call Game_Init
    ld a, 1
    ld [wGameRestartDrawPending], a
    ret

Game_ReturnToTitleFromPause:
    call Game_InitTitle
    ld a, 1
    ld [wGameTitleDrawPending], a
    ret

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
    ld a, [wGameFlagCount]
    cp MINE_COUNT
    ret nc

    set CELL_FLAG_BIT, [hl]
    ld a, [wGameFlagCount]
    inc a
    ld [wGameFlagCount], a
    ld a, 1
    ld [wGameMineDrawPending], a
    ld a, TILE_FLAG
    jr .draw

.clearFlag:
    res CELL_FLAG_BIT, [hl]
    ld a, [wGameFlagCount]
    and a
    jr z, .skipDecrementFlagCount
    dec a
    ld [wGameFlagCount], a
.skipDecrementFlagCount:
    ld a, 1
    ld [wGameMineDrawPending], a
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
    ld [wGameMessageDrawIndex], a

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

Game_IsEnded::
    ld a, [wGameOver]
    ld b, a
    ld a, [wGameClear]
    or b
    ld b, a
    ld a, [wGameRestartDrawPending]
    or b
    ret

Game_IsTitle::
    ld a, [wGameTitle]
    and a
    ret

Game_IsPaused::
    ld a, [wGamePaused]
    and a
    ret

Game_CheckClear:
    ld hl, wBoard
    ld b, BOARD_CELL_COUNT
.checkCell:
    bit CELL_MINE_BIT, [hl]
    jr nz, .nextCell
    bit CELL_OPENED_BIT, [hl]
    ret z
.nextCell:
    inc hl
    dec b
    jr nz, .checkCell
    jp Game_TriggerClear

Game_TriggerClear:
    ld a, 1
    ld [wGameClear], a

    xor a
    ld [wGameMessageDrawIndex], a
    ret

Game_RestartAfterEnd:
    call Board_Init
    call Cursor_ResetPosition
    call Game_Init
    ld a, 1
    ld [wGameRestartDrawPending], a
    ret

Game_ReturnToTitleAfterEnd:
    call Game_InitTitle
    ld a, 1
    ld [wGameTitleDrawPending], a
    ret

Game_StartFromTitle:
    call Board_Init
    call Cursor_ResetPosition
    call Game_Init
    ld a, 1
    ld [wGameRestartDrawPending], a
    ret

Game_UpdateMineDisplay:
    ld hl, BG_MAP + STATUS_BG_Y * BG_MAP_WIDTH + STATUS_MINE_DIGITS_X
    ld a, TILE_DIGIT_0
    ld [hli], a

    ld a, MINE_COUNT
    ld b, a
    ld a, [wGameFlagCount]
    ld c, a
    ld a, b
    sub c
    ld b, 0
    cp 10
    jr c, .storeDigits
    sub 10
    ld b, 1
.storeDigits:
    ld c, a
    ld a, TILE_DIGIT_0
    add b
    ld [hli], a
    ld a, TILE_DIGIT_0
    add c
    ld [hl], a
    ret

Game_DrawPauseMenu:
    call Game_ClearPauseMenu
    call Game_DrawPauseFrame

    ld de, BG_MAP + (PAUSE_MENU_Y + 1) * BG_MAP_WIDTH + PAUSE_MENU_X + 2
    ld hl, PauseResumeText
    ld c, PAUSE_MENU_RESUME
    call Game_DrawPauseMenuItem

    ld de, BG_MAP + (PAUSE_MENU_Y + 3) * BG_MAP_WIDTH + PAUSE_MENU_X + 2
    ld hl, PauseRestartText
    ld c, PAUSE_MENU_RESTART
    call Game_DrawPauseMenuItem

    ld de, BG_MAP + (PAUSE_MENU_Y + 5) * BG_MAP_WIDTH + PAUSE_MENU_X + 2
    ld hl, PauseBackToTitleText
    ld c, PAUSE_MENU_TITLE
    jp Game_DrawPauseMenuItem

Game_DrawPauseFrame:
    ld hl, BG_MAP + PAUSE_MENU_Y * BG_MAP_WIDTH + PAUSE_MENU_X
    ld a, TILE_PAUSE_TOP_LEFT
    ld [hli], a
    ld b, PAUSE_MENU_WIDTH - 2
    ld a, TILE_PAUSE_HORIZONTAL
.topRow:
    ld [hli], a
    dec b
    jr nz, .topRow
    ld a, TILE_PAUSE_TOP_RIGHT
    ld [hl], a

    ld hl, BG_MAP + (PAUSE_MENU_Y + 1) * BG_MAP_WIDTH + PAUSE_MENU_X
    call Game_DrawPauseFrameMiddleRow
    ld hl, BG_MAP + (PAUSE_MENU_Y + 2) * BG_MAP_WIDTH + PAUSE_MENU_X
    call Game_DrawPauseFrameMiddleRow
    ld hl, BG_MAP + (PAUSE_MENU_Y + 3) * BG_MAP_WIDTH + PAUSE_MENU_X
    call Game_DrawPauseFrameMiddleRow
    ld hl, BG_MAP + (PAUSE_MENU_Y + 4) * BG_MAP_WIDTH + PAUSE_MENU_X
    call Game_DrawPauseFrameMiddleRow
    ld hl, BG_MAP + (PAUSE_MENU_Y + 5) * BG_MAP_WIDTH + PAUSE_MENU_X
    call Game_DrawPauseFrameMiddleRow

    ld hl, BG_MAP + (PAUSE_MENU_Y + PAUSE_MENU_HEIGHT - 1) * BG_MAP_WIDTH + PAUSE_MENU_X
    ld a, TILE_PAUSE_BOTTOM_LEFT
    ld [hli], a
    ld b, PAUSE_MENU_WIDTH - 2
    ld a, TILE_PAUSE_HORIZONTAL
.bottomRow:
    ld [hli], a
    dec b
    jr nz, .bottomRow
    ld a, TILE_PAUSE_BOTTOM_RIGHT
    ld [hl], a
    ret

Game_DrawPauseFrameMiddleRow:
    ld a, TILE_PAUSE_VERTICAL
    ld [hli], a
    ld b, PAUSE_MENU_WIDTH - 2
    ld a, TILE_BLANK
.middleFill:
    ld [hli], a
    dec b
    jr nz, .middleFill
    ld a, TILE_PAUSE_VERTICAL
    ld [hl], a
    ret

Game_DrawPauseMenuItem:
    ld a, [wGamePauseSelection]
    cp c
    ld a, TILE_BLANK
    jr nz, .storeMarker
    ld a, TILE_BLACK_RIGHT_TRIANGLE
.storeMarker:
    ld [de], a
    inc de
    ld a, TILE_BLANK
    ld [de], a
    inc de
.textLoop:
    ld a, [hli]
    cp $FF
    ret z
    ld [de], a
    inc de
    jr .textLoop

Game_UpdatePauseMenuCursor:
    ld a, [wGamePreviousPauseSelection]
    call Game_GetPauseMenuCursorAddress
    ld a, TILE_BLANK
    ld [hl], a

    ld a, [wGamePauseSelection]
    call Game_GetPauseMenuCursorAddress
    ld a, TILE_BLACK_RIGHT_TRIANGLE
    ld [hl], a
    ret

Game_GetPauseMenuCursorAddress:
    cp PAUSE_MENU_RESTART
    jr z, .restart
    cp PAUSE_MENU_TITLE
    jr z, .title
    ld hl, BG_MAP + (PAUSE_MENU_Y + 1) * BG_MAP_WIDTH + PAUSE_MENU_X + 2
    ret
.restart:
    ld hl, BG_MAP + (PAUSE_MENU_Y + 3) * BG_MAP_WIDTH + PAUSE_MENU_X + 2
    ret
.title:
    ld hl, BG_MAP + (PAUSE_MENU_Y + 5) * BG_MAP_WIDTH + PAUSE_MENU_X + 2
    ret

Game_ClearPauseMenu:
    ld hl, BG_MAP + PAUSE_MENU_Y * BG_MAP_WIDTH + PAUSE_MENU_X
    ld b, PAUSE_MENU_HEIGHT
.row:
    ld c, PAUSE_MENU_WIDTH
    ld a, TILE_BLANK
.column:
    ld [hli], a
    dec c
    jr nz, .column
    ld de, BG_MAP_WIDTH - PAUSE_MENU_WIDTH
    add hl, de
    dec b
    jr nz, .row
    ret

Game_EnqueueFullBoardRedraw:
    xor a
    ld [wGameDrawHead], a
    ld [wGameDrawTail], a
    ld [wGameWorkIndex], a
.loop:
    call Game_GetVisibleTileForWorkIndex
    ld [wGameWorkCell], a
    call Game_EnqueueDrawWorkIndexWithTile
    ld a, [wGameWorkIndex]
    inc a
    ld [wGameWorkIndex], a
    cp BOARD_CELL_COUNT
    jr c, .loop
    ret

Game_GetVisibleTileForWorkIndex:
    call Game_GetCellAddressForWorkIndex
    bit CELL_FLAG_BIT, [hl]
    jr nz, .flag
    bit CELL_OPENED_BIT, [hl]
    jr z, .closed
    bit CELL_MINE_BIT, [hl]
    jr nz, .mine
    ld a, [hl]
    and $0F
    add TILE_OPEN_0
    ret
.flag:
    ld a, TILE_FLAG
    ret
.closed:
    ld a, TILE_CLOSED
    ret
.mine:
    ld a, TILE_MINE
    ret

GameOverText:
    db TILE_LETTER_A + 'G' - 'A'
    db TILE_LETTER_A + 'A' - 'A'
    db TILE_LETTER_A + 'M' - 'A'
    db TILE_LETTER_A + 'E' - 'A'
    db TILE_BLANK
    db TILE_LETTER_A + 'O' - 'A'
    db TILE_LETTER_V
    db TILE_LETTER_A + 'E' - 'A'
    db TILE_LETTER_A + 'R' - 'A'

ClearText:
    db TILE_LETTER_A + 'C' - 'A'
    db TILE_LETTER_A + 'L' - 'A'
    db TILE_LETTER_A + 'E' - 'A'
    db TILE_LETTER_A + 'A' - 'A'
    db TILE_LETTER_A + 'R' - 'A'

PauseResumeText:
    db TILE_LETTER_A + 'R' - 'A', TILE_LETTER_A + 'E' - 'A'
    db TILE_LETTER_A + 'S' - 'A', TILE_LETTER_U
    db TILE_LETTER_A + 'M' - 'A', TILE_LETTER_A + 'E' - 'A', $FF

PauseRestartText:
    db TILE_LETTER_A + 'R' - 'A', TILE_LETTER_A + 'E' - 'A'
    db TILE_LETTER_A + 'S' - 'A', TILE_LETTER_A + 'T' - 'A'
    db TILE_LETTER_A + 'A' - 'A', TILE_LETTER_A + 'R' - 'A'
    db TILE_LETTER_A + 'T' - 'A', $FF

PauseBackToTitleText:
    db TILE_LETTER_A + 'B' - 'A', TILE_LETTER_A + 'A' - 'A'
    db TILE_LETTER_A + 'C' - 'A', TILE_LETTER_A + 'K' - 'A'
    db TILE_BLANK
    db TILE_LETTER_A + 'T' - 'A', TILE_LETTER_A + 'O' - 'A'
    db TILE_BLANK
    db TILE_LETTER_A + 'T' - 'A', TILE_LETTER_A + 'I' - 'A'
    db TILE_LETTER_A + 'T' - 'A', TILE_LETTER_A + 'L' - 'A'
    db TILE_LETTER_A + 'E' - 'A', $FF

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
