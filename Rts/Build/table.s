! DO NOT EDIT THIS FILE. Edit the config file and rerun "config".
#include "asmmacro.h"
	.seg	"data"
	.global	EXTNAME(globals)
	.align 8
EXTNAME(globals):
	.word	0	! G_RESULT
	.word	0	! G_ARGREG2
	.word	0	! G_ARGREG3
	.word	0	! G_REG0
	.word	0	! G_REG1
	.word	0	! G_REG2
	.word	0	! G_REG3
	.word	0	! G_REG4
	.word	0	! G_REG5
	.word	0	! G_REG6
	.word	0	! G_REG7
	.word	0	! G_REG8
	.word	0	! G_REG9
	.word	0	! G_REG10
	.word	0	! G_REG11
	.word	0	! G_REG12
	.word	0	! G_REG13
	.word	0	! G_REG14
	.word	0	! G_REG15
	.word	0	! G_REG16
	.word	0	! G_REG17
	.word	0	! G_REG18
	.word	0	! G_REG19
	.word	0	! G_REG20
	.word	0	! G_REG21
	.word	0	! G_REG22
	.word	0	! G_REG23
	.word	0	! G_REG24
	.word	0	! G_REG25
	.word	0	! G_REG26
	.word	0	! G_REG27
	.word	0	! G_REG28
	.word	0	! G_REG29
	.word	0	! G_REG30
	.word	0	! G_REG31
	.word	0	! G_CONT
	.word	0	! G_STARTUP
	.word	0	! G_CALLOUTS
	.word	0	! G_SCHCALL_ARG4
	.word	0	! G_ALLOCI_TMP
	.word	0	! G_RETADDR
	.word	0	! G_TIMER
	.word	0	! G_GENERIC_NRTMP1
	.word	0	! G_GENERIC_NRTMP2
	.word	0	! G_GENERIC_NRTMP3
	.word	0	! G_STKBOT
	.word	0	! G_STKP
	.word	0	! G_EBOT
	.word	0	! G_ETOP
	.word	0	! G_ELIM
	.word	0	! G_TBOT
	.word	0	! G_TTOP
	.word	0	! G_TLIM
	.word	0	! G_TBRK
	.word	0	! G_SSBBOT
	.word	0	! G_SSBTOP
	.word	0	! G_SSBLIM
	.word	0	! G_ESPACE1_BOT
	.word	0	! G_ESPACE1_LIM
	.word	0	! G_ESPACE2_BOT
	.word	0	! G_ESPACE2_LIM
	.word	0	! G_TSPACE1_BOT
	.word	0	! G_TSPACE1_LIM
	.word	0	! G_TSPACE2_BOT
	.word	0	! G_TSPACE2_LIM
	.word	0	! G_REMSET_POOLBOT
	.word	0	! G_REMSET_POOLTOP
	.word	0	! G_REMSET_POOLLIM
	.word	0	! G_REMSET_TBLBOT
	.word	0	! G_REMSET_TBLLIM
	.word	0	! G_STATIC_BOT
	.word	0	! G_STATIC_TOP
	.word	0	! G_STATIC_LIM
	.word	0	! G_EWATERMARK
	.word	0	! G_THIWATERMARK
	.word	0	! G_TLOWATERMARK
	.word	0	! G_RWATERMARK
	.word	0	! G_GC_MUST_TENURE
	.word	0	! G_SINGLESTEP_ENABLE
	.word	0	! G_BREAKPT_ENABLE
	.word	0	! G_TIMER_ENABLE
	.word	0	! G_SCHCALL_PROCIDX
	.word	0	! G_SCHCALL_ARGC
	.word	0	! G_PUSHTMP
	.word	0	! G_CALLOUT_TMP0
	.word	0	! G_CALLOUT_TMP1
	.word	0	! G_CALLOUT_TMP2
	.word	0	! G_CACHE_FLUSH
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	.word	0	! padding
	b	EXTNAME(mem_alloc)
	nop
	b	EXTNAME(mem_alloci)
	nop
	b	EXTNAME(mem_garbage_collect)
	nop
	b	EXTNAME(mem_addtrans)
	nop
	b	EXTNAME(mem_stkoflow)
	nop
	b	EXTNAME(mem_internal_stkoflow)
	nop
	b	EXTNAME(mem_stkuflow)
	nop
	b	EXTNAME(mem_capture_continuation)
	nop
	b	EXTNAME(mem_restore_continuation)
	nop
	b	EXTNAME(m_generic_add)
	nop
	b	EXTNAME(m_generic_sub)
	nop
	b	EXTNAME(m_generic_mul)
	nop
	b	EXTNAME(m_generic_quo)
	nop
	b	EXTNAME(m_generic_rem)
	nop
	b	EXTNAME(m_generic_div)
	nop
	b	EXTNAME(m_generic_mod)
	nop
	b	EXTNAME(m_generic_neg)
	nop
	b	EXTNAME(m_generic_equalp)
	nop
	b	EXTNAME(m_generic_lessp)
	nop
	b	EXTNAME(m_generic_less_or_equalp)
	nop
	b	EXTNAME(m_generic_greaterp)
	nop
	b	EXTNAME(m_generic_greater_or_equalp)
	nop
	b	EXTNAME(m_generic_zerop)
	nop
	b	EXTNAME(m_generic_complexp)
	nop
	b	EXTNAME(m_generic_realp)
	nop
	b	EXTNAME(m_generic_rationalp)
	nop
	b	EXTNAME(m_generic_integerp)
	nop
	b	EXTNAME(m_generic_exactp)
	nop
	b	EXTNAME(m_generic_inexactp)
	nop
	b	EXTNAME(m_generic_exact2inexact)
	nop
	b	EXTNAME(m_generic_inexact2exact)
	nop
	b	EXTNAME(m_generic_make_rectangular)
	nop
	b	EXTNAME(m_generic_real_part)
	nop
	b	EXTNAME(m_generic_imag_part)
	nop
	b	EXTNAME(m_generic_sqrt)
	nop
	b	EXTNAME(m_generic_round)
	nop
	b	EXTNAME(m_generic_truncate)
	nop
	b	EXTNAME(m_apply)
	nop
	b	EXTNAME(m_varargs)
	nop
	b	EXTNAME(m_typetag)
	nop
	b	EXTNAME(m_typetag_set)
	nop
	b	EXTNAME(m_break)
	nop
	b	EXTNAME(m_eqv)
	nop
	b	EXTNAME(m_partial_list2vector)
	nop
	b	EXTNAME(m_timer_exception)
	nop
	b	EXTNAME(m_exception)
	nop
	b	EXTNAME(m_singlestep)
	nop
	b	EXTNAME(m_syscall)
	nop
	b	EXTNAME(m_bvlcmp)
	nop
	b	EXTNAME(m_enable_interrupts)
	nop
	b	EXTNAME(m_disable_interrupts)
	nop
