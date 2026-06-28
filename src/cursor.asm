INCLUDE "graphics.inc"
INCLUDE "input.inc"
INCLUDE "hardware.inc"

SECTION "Cursor WRAM", WRAM0

wCursorX::
    ds 1
wCursorY::
    ds 1

SECTION "Cursor", ROM0

DEF CURSOR_FRAME_OFFSET EQU 4
DEF CURSOR_SPRITE_BYTES EQU 4

; Initializes the grid cursor at the top-left cell and updates Sprites 0-3.
; Call during VBlank when the LCD is enabled.
Cursor_Init::
    xor a
    ld [wCursorX], a
    ld [wCursorY], a
    jp Cursor_UpdateSprite

Cursor_ResetPosition::
    xor a
    ld [wCursorX], a
    ld [wCursorY], a
    ret

; Moves at most one cell per axis for newly pressed directional buttons.
; Opposing buttons use Right and Down as their respective priorities.
; Clobbers: AF, B, C
Cursor_Update::
    call Game_IsTitle
    ret nz

    call Game_IsPaused
    ret nz

    call Game_IsEnded
    ret nz

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
    ret z
    inc a
    ld [wCursorY], a
    ret

.checkUp:
    ld a, b
    and PAD_UP
    ret z
    ld a, [wCursorY]
    and a
    ret z
    dec a
    ld [wCursorY], a
    ret

; Converts grid coordinates to Game Boy OAM coordinates and writes Sprites 0-3.
; The 16x16 frame is offset 4 pixels up-left from the selected 8x8 cell.
; OAM X is screen X + 8, and OAM Y is screen Y + 16.
; Call only while OAM is accessible, normally during VBlank.
Cursor_UpdateSprite::
    call Game_IsTitle
    jp nz, Cursor_HideSprite

    call Game_IsPaused
    jp nz, Cursor_HideSprite

    call Game_IsEnded
    jp nz, Cursor_HideSprite

    ld a, [wCursorY]
    add a
    add a
    add a
    add BOARD_BG_Y * 8 + 16 - CURSOR_FRAME_OFFSET
    ld b, a

    ld a, [wCursorX]
    add a
    add a
    add a
    add BOARD_BG_X * 8 + 8 - CURSOR_FRAME_OFFSET
    ld c, a

    ; Sprite 0: top-left
    ld a, b
    ld [OAM_BASE], a
    ld a, c
    ld [OAM_BASE + 1], a
    ld a, TILE_CURSOR_TL
    ld [OAM_BASE + 2], a
    xor a
    ld [OAM_BASE + 3], a

    ; Sprite 1: top-right
    ld a, b
    ld [OAM_BASE + CURSOR_SPRITE_BYTES], a
    ld a, c
    add 8
    ld [OAM_BASE + CURSOR_SPRITE_BYTES + 1], a
    ld a, TILE_CURSOR_TR
    ld [OAM_BASE + CURSOR_SPRITE_BYTES + 2], a
    xor a
    ld [OAM_BASE + CURSOR_SPRITE_BYTES + 3], a

    ; Sprite 2: bottom-left
    ld a, b
    add 8
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 2], a
    ld a, c
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 2 + 1], a
    ld a, TILE_CURSOR_BL
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 2 + 2], a
    xor a
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 2 + 3], a

    ; Sprite 3: bottom-right
    ld a, b
    add 8
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 3], a
    ld a, c
    add 8
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 3 + 1], a
    ld a, TILE_CURSOR_BR
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 3 + 2], a
    xor a
    ld [OAM_BASE + CURSOR_SPRITE_BYTES * 3 + 3], a
    ret

Cursor_HideSprite:
    xor a
    ld hl, OAM_BASE
    ld b, CURSOR_SPRITE_BYTES * 4
.loop:
    ld [hli], a
    dec b
    jr nz, .loop
    ret
