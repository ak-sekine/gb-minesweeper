; DMG background layout uses tile coordinates, not pixel coordinates.
DEF BG_MAP            EQU $9800
DEF BG_MAP_WIDTH      EQU 32
DEF BG_MAP_HEIGHT     EQU 32

DEF BOARD_WIDTH       EQU 9
DEF BOARD_HEIGHT      EQU 9
DEF BOARD_BG_X        EQU 5
DEF BOARD_BG_Y        EQU 4

DEF STATUS_BG_X       EQU 1
DEF STATUS_BG_Y       EQU 0

; Game tiles 0-14 follow the order documented in PROJECT.md.
DEF TILE_CLOSED       EQU 0
DEF TILE_CURSOR       EQU 14
DEF TILE_BLANK        EQU 15
DEF TILE_DIGIT_0      EQU 16
DEF TILE_COLON        EQU 26
DEF TILE_LETTER_A     EQU 27

DEF TILE_BYTES        EQU 16
DEF FONT_UI_TILE_COUNT EQU 37
