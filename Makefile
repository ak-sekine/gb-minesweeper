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

RGBASM ?= rgbasm
RGBLINK ?= rgblink
RGBFIX ?= rgbfix
EMULATOR ?= sameboy

RGBASMFLAGS ?= -I $(INCLUDE_DIR)/
RGBLINKFLAGS ?= -m $(MAP) -n $(SYM)
RGBFIXFLAGS ?= -v -p 0xFF -t "GB MINESWEEPER" -m ROM -r 0x00

.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

.PHONY: all clean run

all: $(ROM)

$(ROM): $(OBJECTS) | $(BUILD_DIR) $(OBJ_DIR)
	$(RGBLINK) $(RGBLINKFLAGS) -o $@ $(OBJECTS)
	$(RGBFIX) $(RGBFIXFLAGS) $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm | $(OBJ_DIR)
	$(RGBASM) $(RGBASMFLAGS) -o $@ $<

$(OBJ_DIR) $(BUILD_DIR):
	mkdir -p $@

run: $(ROM)
	"$(EMULATOR)" "$(ROM)"

clean:
	rm -rf $(OBJ_DIR) $(BUILD_DIR)
