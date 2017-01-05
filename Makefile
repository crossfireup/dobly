# 
#
#
GCC = gcc
CFLAGS = -ffreestanding -O2 -m32 -g -W -Wall -nostdinc -fno-builtin -fno-stack-protector -fomit-frame-pointer

LD = ld
#LDFLAGS = -Ttext 0x1000 --oformat binary -m elf_i386 -nostdlib 
LDFLAGS = -m elf_i386 -nostdlib

AS = nasm
ASFLAGS = -f bin -g

SRCS := boot_sect.asm

MAIN = boot_sect.bin

DRIVERS = $(addprefix drivers/, common.o screen.o)

all : os.img

$(MAIN): $(SRCS)
	$(AS) $(ASFLAGS) $^ -o $@

os.img : $(MAIN) kernel.bin
	cat $^ > $@

$(DRIVERS):
	@make -C drivers

run: os.img
	qemu-system-i386 -drive format=raw,file=$< -display sdl -monitor stdio

qemu: os.img
	qemu-system-i386 -drive format=raw,file=$< -display sdl -s -S -monitor stdio

bochs: os.img
	bochs -f bochsrc

kernel.bin: kernel.o $(DRIVERS)
	$(LD) $(LDFLAGS) -T kernel.ld $^ -o $@
	#$(LD) $(LDFLAGS) $^ -o $@

disasm: kernel.bin
	objdump -mi386 -M i386,intel -b binary -D $<
	ndisasm -b 32 -o1000h -a $<

print_string.o: print_string.asm
	$(AS) -f elf -F dwarf $^ -o $@

print_string: print_string.o
	ld -m elf_i386 $^ -o $@

gdb: print_string
	gdb -x gdbsrc $^

debug: 
	gdb -x script.gdb
	
*.o:*.c
	$(GCC) $(CFLAGS) -c $< -o $@	

.PHONY: clean

clean:
	$(RM) *.o *.bin os.img $(MAIN) .*.swp *.log
	@make -C drivers clean
