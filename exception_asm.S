/*
	mini - a Free Software replacement for the Nintendo/BroadOn IOS.
	exception handling

Copyright (C) 2008, 2009	Hector Martin "marcan" <marcan@marcansoft.com>

# This code is licensed to you under the terms of the GNU GPL, version 2;
# see file COPYING or http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
*/

.arm

.globl v_undf
.type v_undf, %function
.globl v_swi
.type v_swi, %function
.globl v_instr_abrt
.type v_instr_abrt, %function
.globl v_data_abrt
.type v_data_abrt, %function
.globl v_reserved
.type v_reserved, %function
.globl v_fiq
.type v_fiq, %function

.globl exc_setup_stack
.type exc_setup_stack, %function
.extern __excstack_addr
.extern exc_handler

exc_setup_stack:
	mrs	r0, cpsr

	@ Switch to FIQ mode
	msr cpsr_c, #0xd1
	@ Setup exception stack
	ldr	sp, =__excstack_addr

	@ Switch to SVC mode
	msr cpsr_c, #0xd3
	@ Setup exception stack
	ldr	sp, =__excstack_addr

	@ Switch to ABORT mode
	msr cpsr_c, #0xd7
	@ Setup exception stack
	ldr	sp, =__excstack_addr

	@ Switch to UNDF mode
	msr cpsr_c, #0xdb
	@ Setup exception stack
	ldr	sp, =__excstack_addr

	@ Restore mode
	msr cpsr_c, r0
	bx	lr
.size exc_setup_stack, . - exc_setup_stack

.pool

v_undf:
	stmfd	sp!, {lr}
	stmfd	sp, {r0-lr}^
	sub		sp, sp, #0x3c
	mov		r2, sp
	mrs		r1, spsr
	mov		r0, #1

	blx		exc_handler

	ldmfd	sp!, {r0-r12}
	add		sp, sp, #8
	ldmfd	sp!, {lr}
	movs	pc, lr
.size v_undf, . - v_undf

v_swi:
	stmfd	sp!, {lr}
	stmfd	sp, {r0-lr}^
	sub		sp, sp, #0x3c
	mov		r2, sp
	mrs		r1, spsr
	mov		r0, #2

	blx		exc_handler

	ldmfd	sp!, {r0-r12}
	add		sp, sp, #8
	ldmfd	sp!, {lr}
	movs	pc, lr
.size v_swi, . - v_swi

v_instr_abrt:
	stmfd	sp!, {lr}
	stmfd	sp, {r0-lr}^
	sub		sp, sp, #0x3c
	mov		r2, sp
	mrs		r1, spsr
	mov		r0, #3

	blx		exc_handler

	ldmfd	sp!, {r0-r12}
	add		sp, sp, #8
	ldmfd	sp!, {lr}
	subs	pc, lr, #4
.size v_instr_abrt, . - v_instr_abrt

v_data_abrt:
	stmfd	sp!, {lr}
	stmfd	sp, {r0-lr}^
	sub		sp, sp, #0x3c
	mov		r2, sp
	mrs		r1, spsr
	mov		r0, #4

	blx		exc_handler

	ldmfd	sp!, {r0-r12}
	add		sp, sp, #8
	ldmfd	sp!, {lr}
	subs	pc, lr, #8
.size v_data_abrt, . - v_data_abrt

v_reserved:
	stmfd	sp!, {lr}
	stmfd	sp, {r0-lr}^
	sub		sp, sp, #0x3c
	mov		r2, sp
	mrs		r1, spsr
	mov		r0, #5

	blx		exc_handler

	ldmfd	sp!, {r0-r12}
	add		sp, sp, #8
	ldmfd	sp!, {lr}
	movs	pc, lr
.size v_reserved, . - v_reserved

v_fiq:
	stmfd	sp!, {lr}
	stmfd	sp, {r0-lr}^
	sub		sp, sp, #0x3c
	mov		r2, sp
	mrs		r1, spsr
	mov		r0, #7

	blx		exc_handler

	ldmfd	sp!, {r0-r12}
	add		sp, sp, #8
	ldmfd	sp!, {lr}
	subs	pc, lr, #4
.size v_fiq, . - v_fiq

