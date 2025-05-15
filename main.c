/*
	mini - a Free Software replacement for the Nintendo/BroadOn IOS.

Copyright (C) 2008, 2009	Haxx Enterprises <bushing@gmail.com>
Copyright (C) 2008, 2009	Sven Peter <svenpeter@gmail.com>
Copyright (C) 2008, 2009	Hector Martin "marcan" <marcan@marcansoft.com>
Copyright (C) 2009			Andre Heider "dhewg" <dhewg@wiibrew.org>
Copyright (C) 2009		John Kelley <wiidev@kelley.ca>

# This code is licensed to you under the terms of the GNU GPL, version 2;
# see file COPYING or http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
*/

#include "types.h"
#include "utils.h"
#include "start.h"
#include "hollywood.h"
#include "sdhc.h"
#include "string.h"
#include "memory.h"
#include "gecko.h"
#include "ff.h"
#include "panic.h"
#include "powerpc_elf.h"
#include "irq.h"
#include "ipc.h"
#include "exception.h"
#include "crypto.h"
#include "nand.h"
#include "boot2.h"
#include "git_version.h"

// (1st choice, neagix's PPC-side boot menu)
#define GUMBOOT_ELF_FILE     "/gumboot/gumboot.elf"
// (2nd choice, BootMii GUI (neagix's default path))
#define BOOTMII_GUI_ELF_FILE "/bootmii/gui.elf"
// (3rd choice, BootMii GUI (official BootMii path))
#define PPCBOOT_ELF_FILE     "/bootmii/ppcboot.elf"

// 'MBTM' - Memory BooT Magic
#define MEMBOOT_MAGIC 0x4D42544D

// pointer to magic
#define MEMBOOT_MAGIC_PTR  (*(u32 *)0xFFFFF0)

// size, set by Broadway on load
#define MEMBOOT_SIZE_PTR   (*(u32 *)0xFFFFF4)

// reserved params
#define MEMBOOT_RSRVD1_PTR (*(u32 *)0xFFFFF8)
#define MEMBOOT_RSRVD2_PTR (*(u32 *)0xFFFFFC)

// static pointer to where the ELF should live, *could* make this configurable,
// but the RAM size is so small anyways that it's not like there's really much of a
// choice on where it could go in the first place...
#define MEMBOOT_ELF_ADDR   ((u8 *)0x1000000)


FATFS fatfs;

u32 _main(void *base)
{
	FRESULT fres;
	int res;
	u32 vector;
	(void)base;

	gecko_init();
	gecko_printf("mini %s loading\n", git_version);

	gecko_printf("Initializing exceptions...\n");
	exception_initialize();
	gecko_printf("Configuring caches and MMU...\n");
	mem_initialize();

	gecko_printf("IOSflags: %08x %08x %08x\n",
		read32(0xffffff00), read32(0xffffff04), read32(0xffffff08));
	gecko_printf("          %08x %08x %08x\n",
		read32(0xffffff0c), read32(0xffffff10), read32(0xffffff14));

	irq_initialize();
//	irq_enable(IRQ_GPIO1B);
	irq_enable(IRQ_GPIO1);
	irq_enable(IRQ_RESET);
	irq_enable(IRQ_TIMER);
	irq_set_alarm(20, 1);
	gecko_printf("Interrupts initialized\n");

	crypto_initialize();
	gecko_printf("crypto support initialized\n");

	nand_initialize();
	gecko_printf("NAND initialized.\n");

	boot2_init();

	gecko_printf("Initializing IPC...\n");
	ipc_initialize();

	if (read32(0x0d800190) & 2) {
		gecko_printf("GameCube compatibility mode detected...\n");
		vector = boot2_run(1, 0x101);
		goto shutdown;
	}

	if (MEMBOOT_MAGIC_PTR == MEMBOOT_MAGIC) {
		gecko_printf("Detected memboot magic, skipping SD init\n");
		goto memboot;
	}

	gecko_printf("Initializing SDHC...\n");
	sdhc_init();

	gecko_printf("Mounting SD...\n");
	fres = f_mount(0, &fatfs);

	if(fres != FR_OK) {
		gecko_printf("Error %d while trying to mount SD\n", fres);
		panic2(0, PANIC_MOUNT);
	}

	gecko_printf("Trying to boot: " GUMBOOT_ELF_FILE "\n");
	res = powerpc_boot_file(GUMBOOT_ELF_FILE);
	if (!res)
		goto success;

	gecko_printf("Failed to boot PPC " GUMBOOT_ELF_FILE ": %d\n", res);
	gecko_printf("Trying to boot: " BOOTMII_GUI_ELF_FILE "\n");
	res = powerpc_boot_file(BOOTMII_GUI_ELF_FILE);
	if (!res)
		goto success;

	gecko_printf("Failed to boot PPC " BOOTMII_GUI_ELF_FILE ": %d\n", res);
	gecko_printf("Trying to boot: " PPCBOOT_ELF_FILE "\n");
	res = powerpc_boot_file(PPCBOOT_ELF_FILE);
	if (!res)
		goto success;

	gecko_printf("Failed to boot PPC " PPCBOOT_ELF_FILE ": %d\n", res);

memboot:
	// try to memboot, even we don't have the magic, just in case
	// (it almost certainly won't work, but never know...)
	gecko_printf("Trying to memboot: %p (%d bytes)\n", MEMBOOT_ELF_ADDR, MEMBOOT_SIZE_PTR);
	res = powerpc_boot_mem(MEMBOOT_ELF_ADDR, MEMBOOT_SIZE_PTR);
	if (!res)
		goto success;

	// last resort
	gecko_printf("All boot options failed... booting System Menu\n");
	vector = boot2_run(1, 2);
	goto shutdown;

success:
	gecko_printf("Boot success - going into IPC mainloop...\n");
	vector = ipc_process_slow();
	gecko_printf("IPC mainloop done!\n");
	gecko_printf("Shutting down IPC...\n");
	ipc_shutdown();

shutdown:
	gecko_printf("Shutting down interrupts...\n");
	irq_shutdown();
	gecko_printf("Shutting down caches and MMU...\n");
	mem_shutdown();

	gecko_printf("Vectoring to 0x%08x...\n", vector);
	return vector;
}

