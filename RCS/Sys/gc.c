/*
 * Ephemeral garbage collector (for Scheme).
 * Documentation is in the files "gc.txt" and "gcinterface.txt".
 *
 * $Id: gc.c,v 1.3 91/06/20 22:14:50 lth Exp Locker: lth $
 *
 * IMPLEMENTATION
 * We use "old" C; this has the virtue of letting us use 'lint' on the code.
 *
 * ASSUMPTIONS
 * - We assume a representation with 32 bits; the code will work for
 *   other word sizes if the #definition of BIT_MASK is changed
 *   correctly. 
 * - The number of bytes in a word is assumed to be 4 in a number of places.
 *   This should probably be fixed. I don't think we assume that a byte has
 *   8 bits.
 * - We *must* have sizeof( unsigned long ) >= sizeof( unsigned long * ).
 * - No 2's complement is assumed; all values are unsigned.
 * - UNIX-style malloc() and memcpy() must be provided.
 *
 * BUGS
 * - Does not detect overflow of tenured space during collection.
 * - Does not remove transactions with no pointers into the ephemeral space
 *   from the transaction list.
 */

#ifdef __STDC__
  #include <stdlib.h>                  /* for malloc() */
  #include <memory.h>                  /* for memcpy() */
#else
  extern char *malloc();
  extern char *memcpy();
#endif
#include "gc.h"
#include "gcinterface.h"

/* this is the usual one */
#define NULL                0

/* Type tags. Not all of these are used by the collector. */
#define FIX1_TAG            0x0
#define FIX2_TAG            0x4
#define IMM1_TAG            0x2
#define IMM2_TAG            0x6
#define PAIR_TAG            0x1
#define VEC_TAG             0x3
#define BVEC_TAG            0x5
#define PROC_TAG            0x7

/* Header tags. Not all of these are used by the collector. */
#define RES_HDR             0x82
#define VEC_HDR             0xA2
#define BV_HDR              0xC2
#define PROC_HDR            0xFE

/* Various masks. Change BIT_MASK if your word is bigger than 32 bits. */
#define TAG_MASK            0x00000007     /* extract bits 2, 1, and 0 */
#define ISHDR_MASK          0x00000083     /* extract bits 7, 1, and 0 */
#define HDR_SIGN            0x00000082     /* header signature */
#define HDR_MASK            0x000000E3     /* Mask to extract header info */
#define BIT_MASK            0x80000000     /* Mask for 'traced' bit */

/* Given tagged pointer, return tag */
#define tagof( w )          ((word)(w) & TAG_MASK)

/* Given tagged pointer, return pointer */
#define ptrof( w )          (word *) ((word)(w) & ~TAG_MASK)

/* Given pointer and tag, return tagged pointer */
#define tagptr( w, tag )    (word *)((word)(w) | (tag))

/* Manipulating 'traced' bit in vector headers */
#define get_bit( w )        ((w) & BIT_MASK)
#define set_bit( w )        ((w) |= BIT_MASK)
#define reset_bit( w )      ((w) &= ~BIT_MASK)

/* extract header tag from a header word */
#define header( w )         ((word) (w) & HDR_MASK)

/* a word is a pointer if the low bit is set */
#define isptr( w )          ((word) (w) & 0x01)

/* a word is a header if it has a header mask layout */
#define ishdr( w )          (((word) (w) & ISHDR_MASK) == HDR_SIGN)

/* extract size field from a header word, accounting for a set hi bit */
#define sizefield( w )      ((((word) (w)) & ~BIT_MASK) >> 8)

/* Is a word a pointer into a particular space? */
#define pointsto( p,lo,hi ) (isptr(p) && ptrof(p) >= (lo) && ptrof(p) <= (hi))

/* miscellaneous */
#define max( a, b )         ((a) > (b) ? (a) : (b))
#define min( a, b )         ((a) < (b) ? (a) : (b))
#define roundup4( a )       (((a) + 3) & ~0x03)
#define roundup8( a )       (((a) + 7) & ~0x07)

/* Private globals */
static unsigned long ecollections, tcollections;
static unsigned long words_collected, words_allocated;
static word *e_base, *e_max, *e_top, *e_mark;
static word *e_new_base, *e_new_max, *e_new_mark;
static word *t_base, *t_max, *t_top, *t_trans;
static word *t_new_base, *t_new_max;
static word *s_base, *s_max;
static word *stk_base, *stk_max;

static word forward();
static unsigned words_used();
static ephemeral_collection(),
       tenuring_collection();

/*
 * Procedure to intialize garbage collector.
 *
 * This procedure should be called once and once only, before any memory 
 * allocation is performed by the Scheme code. This code uses malloc() and 
 * hence peacefully coexists with other code that uses malloc().
 *
 * Arguments:
 * - 's_size' is the requested size of the static area, in bytes.
 * - 't_size' is the requested size of the tenured area, in bytes.
 * - 'e_size' is the requested size of the ephemeral area, in bytes.
 * - 'e_lim' is the requested watermark of the ephemeral area, measured
 *   in bytes from the bottom of the area.
 * - 'stk_size' is the requested size of the stack cache area, in bytes.
 *
 * First, all sizes and marks are adjusted for proper alignment and for
 * compliance with the constraints set forth in "gc.h".
 * Then, space is allocated and partitioned up. 
 * Finally, the global pointers are set up.
 *
 * If the initialization succeeded, a nonzero value is returned. Otherwise,
 * 0 is returned.
 */
init_collector( s_size, t_size, e_size, e_lim, stack_size )
unsigned int s_size, t_size, e_size, e_lim, stack_size;
{
  word *p;
  word lomem, himem;

  /* 
   * The size of a space must be divisible by the size of a doubleword,
   * which is 8. It must be larger than the minimum size specified in "gc.h".
   */
  s_size = max( MIN_S_SIZE, roundup8( s_size ) );
  t_size = max( MIN_T_SIZE, roundup8( t_size ) );
  e_size = max( MIN_E_SIZE, roundup8( e_size ) );
  stack_size = max( MIN_STK_SIZE, roundup8( stack_size ) );

  /*
   * There are no limits on the ephemeral watermark, as a bad limit will
   * simply cause poor memory behavior. Makes no sense to have it bigger
   * than the ephemeral area, though.
   */
  e_lim = min( roundup8( e_lim ), e_size );

  /* 
   * Allocate memory for all the spaces.
   * The extra "+ 7" is for a little leeway in adjusting the alignment on
   * machines that do not have alignment restrictions. 
   * (For example, malloc() under Utek will align on a word boundary.)
   */
  p = (word *) malloc( s_size + t_size*2 + e_size*2 + stack_size + 7 );

  if (p == NULL)
    return 0;

  p = (word *) roundup8( (word) p );    /* adjust to doubleword ptr */

  lomem = (word) p;

  /* The stack cache goes at the bottom of memory. */
  stk_base = p;                                 /* lowest word */
  stk_max = p + stack_size / 4 - 1;               /* highest word */
  p += stack_size / 4;

  /* The epehemral areas are the lowest of the heap spaces */
  e_base = e_top = p;
  e_max = p + e_size / 4 - 1;
  e_mark = e_base + e_lim / 4 - 1;
  p += e_size / 4;

  e_new_base = p;
  e_new_max = p + e_size / 4 - 1;
  e_new_mark = e_new_base + e_lim / 4 - 1;
  p += e_size / 4;

  /* The static area goes in the middle */
  s_base = p;
  s_max = p + s_size / 4 - 1;
  p += s_size / 4;

  /* The tenured areas go on the top */
  t_base = t_top = p;
  t_max = p + t_size / 4 - 1;
  t_trans = t_max;
  p += t_size / 4;
  
  t_new_base = p;
  t_new_max = p + t_size / 4 - 1;
  p += t_size / 4;

  himem = (word) p;

  globals[ E_BASE_OFFSET ] = (word) e_base;
  globals[ E_TOP_OFFSET ] = (word) e_top;
  globals[ E_MARK_OFFSET ] = (word) e_mark;
  globals[ E_MAX_OFFSET ] = (word) e_max;

  globals[ T_BASE_OFFSET ] = (word) t_base;
  globals[ T_TOP_OFFSET ] = (word) t_top;
  globals[ T_MAX_OFFSET ] = (word) t_max;
  globals[ T_TRANS_OFFSET ] = (word) t_trans;

  globals[ S_BASE_OFFSET ] = (word) s_base;
  globals[ S_MAX_OFFSET ] = (word) s_max;

  globals[ STK_BASE_OFFSET ] = (word) stk_base;
  globals[ STK_MAX_OFFSET ] = (word) stk_max;

  globals[ LOMEM_OFFSET ] = lomem;
  globals[ HIMEM_OFFSET ] = himem;

  return 1;
}


/*
 * Garbage collector trap entry point. In later versions, when we trap on
 * a memory overflow, we will attempt to allocate more space.
 */
gc_trap( type )
unsigned int type;
{
  if (type == 0)
    panic( "GC: Memory overflow in ephemeral area." );
  else if (type == 1)
    panic( "GC: Memory overflow in tenured area." );
  else
    panic( "GC: Invalid trap." );
}


/*
 * We invoke different collections based on the effect of the last collection
 * and depending on the parameter given: 0 = ephemeral, 1 = tenuring.
 * The internal state overrides the parameter.
 */
collect( type )
unsigned int type;
{
  static unsigned int must_tenure = 0;     /* 1 if we need to do a major gc */
  static unsigned words2;                  /* # words in use after last gc */
  unsigned words1;                         /* # words in use before this gc */

  e_top = (word *) globals[ E_TOP_OFFSET ];
  t_top = (word *) globals[ T_TOP_OFFSET ];     /* enables heap loading */
  t_trans = (word *) globals[ T_TRANS_OFFSET ];

  if (type == 1) 
    ecollections++;
  else
    tcollections++;

  words1 = words_used();
  words_allocated += words2 - words1;

  if (must_tenure || type != 1) {
    tenuring_collection();
    must_tenure = 0;
  }
  else {
    ephemeral_collection();
    must_tenure = e_top > e_mark;
  }

  words2 = words_used();
  words_collected += words1 - words2;

  globals[ E_BASE_OFFSET ] = (word) e_base;
  globals[ E_TOP_OFFSET ] = (word) e_top;
  globals[ E_MARK_OFFSET ] = (word) e_mark;
  globals[ E_MAX_OFFSET ] = (word) e_max;

  globals[ T_BASE_OFFSET ] = (word) t_base;
  globals[ T_TOP_OFFSET ] = (word) t_top;
  globals[ T_MAX_OFFSET ] = (word) t_max;
  globals[ T_TRANS_OFFSET ] = (word) t_trans;

  globals[ WCOLLECTED_OFFSET ] = words_collected;
  globals[ WALLOCATED_OFFSET ] = words_allocated;
  globals[ TCOLLECTIONS_OFFSET ] = tcollections;
  globals[ ECOLLECTIONS_OFFSET ] = ecollections;
}


/*
 * Calculate how much memory we're using in the tenured and ephemeral areas.
 * Is there any reason why/why not the static area should be included?
 */
static unsigned words_used()
{
  return (e_top - e_base) + (t_top - t_base) + (t_max - t_trans);
}


/*
 * The ephemeral collection copies all reachable objects in the ephemeral 
 * area into the new ephemeral area. An object is reachable if
 *  - it is reachable from the set of root pointers in `roots', or
 *  - it is reachable from the transaction list, or
 *  - it is reacable from a reachable object.
 */
static ephemeral_collection()
{
  word *dest, *tmp, *ptr, *head, *tail;
  unsigned int i, tag, size;

  /* 
   * 'dest' is the pointer into newspace at which location the next copied
   * object will go.
   */
  dest = e_new_base;

  /*
   * Do roots. All roots are in an array somewhere, and the first root is
   * pointed to by 'roots'. 'rootcnt' is the number of roots. They must all
   * be consecutive.
   */
  for (i = FIRST_ROOT ; i <= LAST_ROOT ; i++ )
    globals[ i ] = forward( globals[ i ], e_base, e_max, &dest );

  /*
   * Do entry list. The entry list is in the tenured area between t_max
   * and t_trans (including the former but not the latter.)
   */
  for ( tail = head = t_max ; head > t_trans ; head-- ) {
    tag = tagof( *head );
    ptr = ptrof( *head );
    if (tag == VEC_TAG || tag == PROC_TAG) {
      if (get_bit( *ptr ) == 0) {        /* haven't done this structure yet */
	set_bit( *ptr );
	size = sizefield( *ptr ) >> 2;
	for (i = 0, ++ptr ; i < size ; i++, ptr++ )
	  *ptr = forward( *ptr, e_base, e_max, &dest );
	*tail-- = *head;
      }
    }
    else if (tag == PAIR_TAG) {
      /* have done pair if either word is pointer into neswpace! */
      if (pointsto( *ptr, e_new_base, e_new_max )
       || pointsto( *(ptr+1), e_new_base, e_new_max ))
	;
      else {
	*ptr = forward( *ptr, e_base, e_max, &dest );
	*(ptr+1) = forward( *(ptr+1), e_base, e_max, &dest );
	*tail-- = *head;
      }
    }
    else
      panic( "Failed invariant in ephemeral_collection().\n" );
  }
  t_trans = tail;

  /*
   * Clear the header bits in the tenured area.
   */
  for (head = t_max ; head > t_trans ; head-- ) {
    tag = tagof( *head );
    if (tag == VEC_TAG || tag == PROC_TAG)
      reset_bit( *ptrof( *head ) );
  }

  /*
   * Now do all the copied objects in newspace, until all are done.
   */
  ptr = e_new_base;
  while (ptr < dest) {
    if (ishdr( *ptr ) && header( *ptr ) == BV_HDR) {
      size = (sizefield( *ptr ) + 3) >> 2;
      ptr += size + 1;
    }
    else {
      *ptr = forward( *ptr, e_base, e_max, &dest );
      ptr++;
    }
  }

  /* 
   * Flip the spaces.
   */
  tmp = e_base; e_base = e_new_base; e_new_base = tmp;
  tmp = e_max; e_max = e_new_max; e_new_max = tmp;
  tmp = e_mark; e_mark = e_new_mark; e_new_mark = tmp;
  e_top = dest;
}


/*
 * A tenuring collection copies all reachable objects into the tenured area
 * and leaves the ephemeral area empty.
 */
static tenuring_collection()
{
  word *p, *dest, *tmp;
  unsigned int i, size;

  /*
   * 'Dest' is a pointer into newspace, at which point to place the object
   * being copied.
   */
  dest = t_new_base;

  /*
   * Do the roots. Scan twice to get both spaces.
   */
  for (i = FIRST_ROOT ; i <= LAST_ROOT ; i++ )
    globals[ i ] = forward( globals[ i ], t_base, t_max, &dest );

  for (i = FIRST_ROOT ; i <= LAST_ROOT ; i++ )
    globals[ i ] = forward( globals[ i ], e_base, e_max, &dest );

  /*
   * Do the copied objects until there are no more.
   */
  p = t_new_base;
  while (p < dest) {
    if (ishdr( *p ) && header( *p ) == BV_HDR) {
      size = (sizefield( *p ) + 3) >> 2;
      p += size + 1;
    }
    else {
      if (isptr( *p )) {
	if (ptrof( *p ) <= e_max)
	  *p = forward( *p, e_base, e_max, &dest );
	else
	  *p = forward( *p, t_base, t_max, &dest );
      }
      p++;
    }
  }

  /*
   * Flip.
   */
  tmp = t_base; t_base = t_new_base; t_new_base = tmp;
  tmp = t_max; t_max = t_new_max; t_new_max = tmp;
  t_top = dest;
  t_trans = t_max;
  e_top = e_base;
}


/*
 * "Forward" takes a word "w", the limits "base" and "max" of oldspace,
 * and a pointer to a pointer into newspace, "dest". It returns the forwarding
 * value of w, which is:
 *  - w if w is a literal (header or fixnum)
 *  - w if w is a pointer not into oldspace
 *  - a pointer into newspace at which location the object that the old w
 *    pointed to (in oldspace).
 * When an object is copied from oldspace to newspace, a forwarding pointer
 * is left behind in oldspace. In case 3 above, if the object pointed to
 * by w is a pointer not into oldspace, then that pointer is returned. A
 * forwarding pointer is indistinguishable from a pointer which is to a space
 * different from oldspace. 
 *
 * [Implementation note: can we do better than memcpy() here because we know
 *  that the structure is aligned?]
 */
static word forward( w, base, limit, dest )
word w, *base, *limit, **dest;
{
  word tag, q, forw;
  word *ptr, *ptr2, *newptr;
  unsigned size;

  if (!isptr( w )) return w;

  ptr = ptrof( w );
  if (ptr < base || ptr > limit) return w;

  q = *ptr;
  if (isptr( q )) {
    ptr2 = ptrof( q );
    if (ptr2 < base || ptr2 > limit)   /* "forwarding" */
      return q;
  }

  /*
   * At this point we know that w is a pointer into oldspace. We must copy
   * the structure into newspace and then pad out the structure if necessary.
   */
  tag = tagof( w );
  newptr = *dest;
  if (tag == PAIR_TAG) {
    *((*dest)++) = *ptr++;
    *((*dest)++) = *ptr++;
  }
  else {                     /* vector-like (bytevector, vector, procedure) */
    size = roundup4( sizefield( q ) + 4 );
    memcpy( (char *) *dest, (char *) ptr, size );
    *dest += size / 4;
    if (size % 8 != 0)         /* need to pad out to doubleword? */
      *((*dest)++) = (word) 0;
  }

  forw = (word) tagptr( newptr, tag );
  *ptrof( w ) = forw;                   /* leave forwarding pointer */
  return forw;
}
