INCLUDE "hardware.inc"

SECTION "ROM Header", ROM0[$0100]

EntryPoint::
    nop
    jp Main
    ds $0150 - @, 0

SECTION "Main", ROM0[$0150]

Main::
    di
    ld sp, $DFFF
    call GraphicsInit
    call Input_Init
    call Random_Init
    call Board_Init
    call Game_InitTitle
    call WaitVBlank
    call Cursor_Init
.loop:
    call WaitVBlank
    ; Keep VRAM/OAM writes at the start of VBlank. Game logic may run longer.
    call Board_UpdateDebugDisplay
    call Game_UpdateDisplay
    call Cursor_UpdateSprite
    call Random_UpdateFrameCounter
    call Input_Update
    call Game_HandleInput
    call Cursor_Update
    jr .loop

; Wait for a new VBlank edge so the game loop runs exactly once per frame.
WaitVBlank:
.waitVisible:
    ldh a, [rLY]
    cp 144
    jr nc, .waitVisible
.waitVBlank:
    ldh a, [rLY]
    cp 144
    jr c, .waitVBlank
    ret
