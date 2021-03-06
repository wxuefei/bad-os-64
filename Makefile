CFLAGS=-Os -nostdlib -nostdinc -fno-builtin -fno-stack-protector -std=gnu99  -MMD -MP -g -Werror -mno-red-zone -I src -fno-asynchronous-unwind-tables
TEST_CFLAGS=-std=gnu99 -Werror -MMD -MP -I src -g -fno-builtin

DISPLAY_LIBRARY ?= sdl

C_FILES=$(shell find src -name '*.c')
ASM_FILES=$(shell find src -name '*.asm')
TEST_SRC=$(shell find test -path test/tinytest -prune -o -name '*.c' -print)

OBJS=$(patsubst src/%.asm, out/%.o, $(ASM_FILES)) $(patsubst src/%.c, out/%.o, $(C_FILES))
TEST_OBJS=$(patsubst test/%.c, out/test/%.o, $(TEST_SRC))

default: disk.img

test: bin/alltests
	bin/alltests

.PHONY : test

bin/alltests: $(TEST_OBJS) $(filter-out out/entry.o out/panic.o out/main.o out/interrupt.o out/keyboard.o, $(OBJS))
	-mkdir -p bin/
	$(CC) -o $@ $^

run_nonet: disk.img fat32.img
	IMAGE=disk.img DISPLAY_LIBRARY=$(DISPLAY_LIBRARY) CYL=128 LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libXpm.so.4 bochs -q -f etc/bochsrc_nn

run: disk.img fat32.img
	sudo IMAGE=disk.img DISPLAY_LIBRARY=$(DISPLAY_LIBRARY) CYL=128 LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libXpm.so.4 bochs -q -f etc/bochsrc

out/%.o: src/%.c
	-mkdir -p $(dir $@)
	$(CC) -c $(CFLAGS) -o $@ $<

out/%.o: src/%.asm
	@mkdir -p $(dir $@)
	nasm $< -felf64 -o $@

out/test/%.o: test/%.c
	mkdir -p $(dir $@)
	$(CC) -c $(TEST_CFLAGS) -o $@ $<

kernel.sys: $(OBJS) Pure64/pure64.sys
	ld -Map=kernel.sym -Tsrc/kernel.ld -o /tmp/kernel.elf $(OBJS)
	objcopy --change-start 0x100000 -O binary /tmp/kernel.elf /tmp/kernel.bin
	cat Pure64/pure64.sys /tmp/kernel.bin > kernel.sys

Pure64/bmfs_mbr.sys Pure64/pure64.sys:
	cd Pure64 && ./build.sh

disk.img: Pure64/bmfs_mbr.sys kernel.sys
	./createimage.sh disk.img 1 Pure64/bmfs_mbr.sys kernel.sys

fat32.img: image/*
	rm -f $@
	$(eval TMP := $(shell mktemp -d))
	mkfs.fat -F 32 -n HELLO -C $@ $$(( 64 * 1024 ))
	sudo mount $@ $(TMP)
	sudo cp -r image/* $(TMP)
	sudo umount $(TMP)
	rm -r $(TMP)

.DELETE_ON_ERROR: fat32.img

clean:
	rm -rf disk.img fat32.img entry.sys kernel.sys out/* bin/*

-include out/*.d

.PHONY: run clean default test
