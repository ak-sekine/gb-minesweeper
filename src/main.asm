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
.loop:
    jr .loop
