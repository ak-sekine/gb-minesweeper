PROJECT := gb-minesweeper

SRC_DIR := src
INCLUDE_DIR := include
OBJ_DIR := obj
BUILD_DIR := build

SOURCES := $(wildcard $(SRC_DIR)/*.asm)
OBJECTS := $(patsubst $(SRC_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SOURCES))

ROM := $(BUILD_DIR)/$(PROJECT).gb
MAP := $(OBJ_DIR)/$(PROJECT).map
SYM := $(OBJ_DIR)/$(PROJECT).sym

GRAPHICS := $(OBJ_DIR)/tiles.2bpp $(OBJ_DIR)/cursor.2bpp $(OBJ_DIR)/font.2bpp

RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
RGBGFX ?= rgbgfx
EMULATOR ?= sameboy

RGBASMFLAGS ?= -I $(INCLUDE_DIR)/
RGBLINKFLAGS ?= -m $(MAP) -n $(SYM)
RGBFIXFLAGS ?= -v -p 0xFF -t "GB MINESWEEPER" -m ROM -r 0x00
RGBGFX_BG_COLORS := \#E0F8D0,\#88C070,\#346856,\#081820
RGBGFX_CURSOR_COLORS := \#88C070,\#E0F8D0,\#346856,\#081820

.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

.PHONY: all clean run

all: $(ROM)

$(ROM): $(OBJECTS) | $(BUILD_DIR) $(OBJ_DIR)
	$(RGBLINK) $(RGBLINKFLAGS) -o $@ $(OBJECTS)
	$(RGBFIX) $(RGBFIXFLAGS) $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm | $(OBJ_DIR)
	$(RGBASM) $(RGBASMFLAGS) -o $@ $<

$(OBJ_DIR)/graphics.o: $(GRAPHICS) $(INCLUDE_DIR)/graphics.inc $(INCLUDE_DIR)/hardware.inc
$(OBJ_DIR)/input.o: $(INCLUDE_DIR)/input.inc $(INCLUDE_DIR)/hardware.inc
$(OBJ_DIR)/main.o: $(INCLUDE_DIR)/hardware.inc
$(OBJ_DIR)/cursor.o: $(INCLUDE_DIR)/graphics.inc $(INCLUDE_DIR)/input.inc $(INCLUDE_DIR)/hardware.inc
$(OBJ_DIR)/board.o: $(INCLUDE_DIR)/graphics.inc $(INCLUDE_DIR)/input.inc

$(OBJ_DIR)/font.2bpp: assets/font.png | $(OBJ_DIR)
	$(RGBGFX) -c "$(RGBGFX_BG_COLORS)" -L 0,0:16,3 -o $@ $<

$(OBJ_DIR)/tiles.2bpp: assets/tiles.png | $(OBJ_DIR)
	$(RGBGFX) -c "$(RGBGFX_BG_COLORS)" -o $@ $<

$(OBJ_DIR)/cursor.2bpp: assets/cursor.png | $(OBJ_DIR)
	$(RGBGFX) -c "$(RGBGFX_CURSOR_COLORS)" -o $@ $<

$(OBJ_DIR) $(BUILD_DIR):
	mkdir -p $@

run: $(ROM)
	"$(EMULATOR)" "$(ROM)"

clean:
	rm -rf $(OBJ_DIR) $(BUILD_DIR)
