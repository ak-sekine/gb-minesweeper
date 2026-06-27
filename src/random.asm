SECTION "Random WRAM", WRAM0

wFrameCounter::
    ds 1
wRandomSeed::
    ds 1

SECTION "Random", ROM0

Random_Init::
    xor a
    ld [wFrameCounter], a
    ld [wRandomSeed], a
    ret

Random_UpdateFrameCounter::
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    ret

Random_SeedFromFrameCounter::
    ld a, [wFrameCounter]
    and a
    jr nz, .store
    inc a
.store:
    ld [wRandomSeed], a
    ret

; Returns an 8-bit pseudo-random value in A.
; Uses a minimal LCG: seed = seed * 5 + 1.
; Clobbers: AF, B
Random_Next::
    ld a, [wRandomSeed]
    ld b, a
    add a
    add a
    add b
    inc a
    ld [wRandomSeed], a
    ret
