/*
	mini - a Free Software replacement for the Nintendo/BroadOn IOS.
	memory management, MMU, caches, and flushing

Copyright (C) 2008, 2009	Hector Martin "marcan" <marcan@marcansoft.com>

# This code is licensed to you under the terms of the GNU GPL, version 2;
# see file COPYING or http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
*/

.arm

.globl _dc_inval_entries
.type _dc_inval_entries, %function
.globl _dc_flush_entries
.type _dc_flush_entries, %function
.globl _dc_flush
.type _dc_flush, %function
.globl _dc_inval
.type _dc_inval, %function
.globl _ic_inval
.type _ic_inval, %function
.globl _drain_write_buffer
.type _drain_write_buffer, %function
.globl _tlb_inval
.type _tlb_inval, %function

.text

_dc_inval_entries:
	mcr		p15, 0, r0, c7, c6, 1
	add		r0, #0x20
	subs	r1, #1
	bne		_dc_inval_entries
	bx		lr
.size _dc_inval_entries, . - _dc_inval_entries

_dc_flush_entries:
	mcr		p15, 0, r0, c7, c10, 1
	add		r0, #0x20
	subs	r1, #1
	bne		_dc_flush_entries
	bx		lr
.size _dc_flush_entries, . - _dc_flush_entries

_dc_flush:
	mrc		p15, 0, pc, c7, c10, 3
	bne		_dc_flush
	bx		lr
.size _dc_flush, . - _dc_flush

_dc_inval:
	mov		r0, #0
	mcr		p15, 0, r0, c7, c6, 0
	bx		lr
.size _dc_inval, . - _dc_inval

_ic_inval:
	mov		r0, #0
	mcr		p15, 0, r0, c7, c5, 0
	bx		lr
.size _ic_inval, . - _ic_inval

_drain_write_buffer:
	mov		r0, #0
	mcr		p15, 0, r0, c7, c10, 4
	bx		lr
.size _drain_write_buffer, . - _drain_write_buffer

_tlb_inval:
	mov		r0, #0
	mcr		p15, 0, r0, c8, c7
	bx		lr
.size _tlb_inval, . - _tlb_inval

