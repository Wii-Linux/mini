ifeq ($(strip $(WIIDEV)),)
$(error "Set WIIDEV in your environment.")
endif

ARM_TOOLCHAIN_PREFIX ?= armeb-eabi-
override PREFIX = $(WIIDEV)/bin/$(ARM_TOOLCHAIN_PREFIX)

CFLAGS = -mbig-endian -mcpu=arm926ej-s
CFLAGS += -fomit-frame-pointer -ffunction-sections
CFLAGS += -Wall -Wextra -Os -pipe -I . -isystem . -std=gnu99
ASFLAGS =
LDFLAGS = -mbig-endian -n -nostartfiles -nodefaultlibs -Wl,-gc-sections

