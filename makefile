all: BootLoader Kernel32 Kernel64 Disk.img

BootLoader:
	@echo
	@echo ============== Build Boot Loader ==============
	@echo
	make -C 00.BootLoader
	@echo
	@echo ============== Build Complete ==============
	@echo

Kernel32:
	@echo
	@echo ============== Build 32bit Kernel ==============
	@echo
	make -C 01.Kernel32
	@echo
	@echo ============== Build Complete ==============
	@echo

Kernel64:
	@echo
	@echo ============== Build 64bit Kernel ==============
	@echo
	make -C 02.Kernel64
	@echo
	@echo ============== Build Complete ==============
	@echo

# Explicit File Rules to ensure dependencies are built
00.BootLoader/BootLoader.bin:
	make -C 00.BootLoader

01.Kernel32/Kernel32.bin:
	make -C 01.Kernel32

02.Kernel64/Kernel64.bin:
	make -C 02.Kernel64

04.Utility/00.ImageMaker/ImageMaker.exe:
	make -C 04.Utility/00.ImageMaker

Disk.img: 00.BootLoader/BootLoader.bin 01.Kernel32/Kernel32.bin 02.Kernel64/Kernel64.bin 04.Utility/00.ImageMaker/ImageMaker.exe
	@echo
	@echo ============== Disk Image Build Start ==============
	@echo
	./04.Utility/00.ImageMaker/ImageMaker.exe 00.BootLoader/BootLoader.bin 01.Kernel32/Kernel32.bin 02.Kernel64/Kernel64.bin
	@echo
	@echo ============== All Build Complete ==============
	@echo

clean:
	make -C 00.BootLoader clean
	make -C 01.Kernel32 clean
	make -C 02.Kernel64 clean
	make -C 04.Utility/00.ImageMaker clean
	rm -f Disk.img