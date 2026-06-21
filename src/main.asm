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
    call WaitVBlank
    call Cursor_Init
.loop:
    call WaitVBlank
    call Input_Update
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
