#ifndef __MPFIR_H__
#define __MPFIR_H__

#include <mpfi.h>

typedef struct {
  __mpfi_struct interval;
  __mpfr_struct estimation;
}__mpfir_struct;

typedef __mpfir_struct mpfir_t[1];
typedef __mpfir_struct *mpfir_ptr;
typedef const __mpfir_struct *mpfir_srcptr;

#ifdef __cplusplus
extern "C" {
#endif

int mpfir_estimation_update(mpfir_ptr op);
double mpfir_estimation_get_d(mpfir_srcptr op, mpfr_rnd_t rnd);
void mpfir_estimation_get_fr(mpfr_ptr rop, mpfir_srcptr op);
double mpfir_left_get_d(mpfir_srcptr op, mpfr_rnd_t rnd);
void mpfir_left_get_fr(mpfr_ptr rop, mpfir_srcptr op);
double mpfir_right_get_d(mpfir_srcptr op, mpfr_rnd_t rnd);
void mpfir_right_get_fr(mpfr_ptr rop, mpfir_srcptr op);

size_t mpfir_inp_str (mpfir_ptr op, FILE* file1, FILE* file2, FILE* file3, int base1, int base2, int base3, mpfr_rnd_t rnd1, mpfr_rnd_t rnd2, mpfr_rnd_t rnd3);
size_t mpfir_out_str (FILE* file1, FILE* file2, FILE* file3, int base1, int base2, int base3, size_t n1, size_t n2, size_t n3, mpfir_srcptr op, mpfr_rnd_t rnd1, mpfr_rnd_t rnd2, mpfr_rnd_t rnd3);

int mpfir_fac_ui(mpfir_ptr rop, unsigned long op, mpfr_rnd_t);

/* Rounding                                     */
int     mpfir_round_prec (mpfir_ptr, mp_prec_t prec);


/* Initialization, destruction and assignment   */

/* initializations */
void    mpfir_init       (mpfir_ptr);
void    mpfir_init2      (mpfir_ptr, mp_prec_t);

void    mpfir_clear      (mpfir_ptr);

/* mpfi bounds have the same precision */
mp_prec_t mpfir_get_prec (mpfir_srcptr);
void    mpfir_set_prec   (mpfir_ptr, mp_prec_t);


/* assignment functions                         */
int     mpfir_set        (mpfir_ptr, mpfir_srcptr);
int     mpfir_set_si     (mpfir_ptr, const long);
int     mpfir_set_ui     (mpfir_ptr, const unsigned long);
int     mpfir_set_d      (mpfir_ptr, const double);
int     mpfir_set_z      (mpfir_ptr, mpz_srcptr);
int     mpfir_set_q      (mpfir_ptr, mpq_srcptr);
int     mpfir_set_fr     (mpfir_ptr, mpfr_srcptr);
int     mpfir_set_fi     (mpfir_ptr, mpfi_srcptr);
int     mpfir_set_str    (mpfir_ptr, const char *, int);

/* combined initialization and assignment functions */
int     mpfir_init_set       (mpfir_ptr, mpfir_srcptr);
int     mpfir_init_set_si    (mpfir_ptr, const long);
int     mpfir_init_set_ui    (mpfir_ptr, const unsigned long);
int     mpfir_init_set_d     (mpfir_ptr, const double);
int     mpfir_init_set_z     (mpfir_ptr, mpz_srcptr);
int     mpfir_init_set_q     (mpfir_ptr, mpq_srcptr);
int     mpfir_init_set_fr    (mpfir_ptr, mpfr_srcptr);
int     mpfir_init_set_str   (mpfir_ptr, const char *, int);

/* swapping two intervals */
void    mpfir_swap (mpfir_ptr, mpfir_ptr);


/* Various useful interval functions            */
/* with scalar or interval results              */

/* absolute diameter                            */
int     mpfir_diam_abs   (mpfr_ptr, mpfir_srcptr);
/* relative diameter                            */
int     mpfir_diam_rel   (mpfr_ptr, mpfir_srcptr);
/* diameter: relative if the interval does not contain 0 */
/* absolute otherwise                                    */
int     mpfir_diam       (mpfr_ptr, mpfir_srcptr);
/* magnitude: the largest absolute value of any element */
int     mpfir_mag        (mpfr_ptr, mpfir_srcptr);
/* mignitude: the smallest absolute value of any element */
int     mpfir_mig        (mpfr_ptr, mpfir_srcptr);
/* middle of y                                           */
int     mpfir_mid        (mpfr_ptr, mpfir_srcptr);
/* picks randomly a point m in y */
void    mpfir_alea       (mpfr_ptr, mpfir_srcptr);
void    mpfir_urandom    (mpfr_ptr, mpfir_srcptr, gmp_randstate_t);


/* Conversions                                  */

double  mpfir_get_d      (mpfir_srcptr);
void    mpfir_get_fr     (mpfr_ptr, mpfir_srcptr);


/* Basic arithmetic operations                  */

/* arithmetic operations between two interval operands */
int     mpfir_add        (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);
int     mpfir_sub        (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);
int     mpfir_mul        (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);
int     mpfir_div        (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);

/* arithmetic operations between an interval operand and a double prec. floating-point */
int     mpfir_add_d      (mpfir_ptr, mpfir_srcptr, const double);
int     mpfir_sub_d      (mpfir_ptr, mpfir_srcptr, const double);
int     mpfir_d_sub      (mpfir_ptr, const double, mpfir_srcptr);
int     mpfir_mul_d      (mpfir_ptr, mpfir_srcptr, const double);
int     mpfir_div_d      (mpfir_ptr, mpfir_srcptr, const double);
int     mpfir_d_div      (mpfir_ptr, const double, mpfir_srcptr);

/* arithmetic operations between an interval operand and an unsigned long integer */
int     mpfir_add_ui     (mpfir_ptr, mpfir_srcptr, const unsigned long);
int     mpfir_sub_ui     (mpfir_ptr, mpfir_srcptr, const unsigned long);
int     mpfir_ui_sub     (mpfir_ptr, const unsigned long, mpfir_srcptr);
int     mpfir_mul_ui     (mpfir_ptr, mpfir_srcptr, const unsigned long);
int     mpfir_div_ui     (mpfir_ptr, mpfir_srcptr, const unsigned long);
int     mpfir_ui_div     (mpfir_ptr, const unsigned long, mpfir_srcptr);

/* arithmetic operations between an interval operand and a long integer */
int     mpfir_add_si     (mpfir_ptr, mpfir_srcptr, const long);
int     mpfir_sub_si     (mpfir_ptr, mpfir_srcptr, const long);
int     mpfir_si_sub     (mpfir_ptr, const long, mpfir_srcptr);
int     mpfir_mul_si     (mpfir_ptr, mpfir_srcptr, const long);
int     mpfir_div_si     (mpfir_ptr, mpfir_srcptr, const long);
int     mpfir_si_div     (mpfir_ptr, const long, mpfir_srcptr);

/* arithmetic operations between an interval operand and a multiple prec. integer */
int     mpfir_add_z      (mpfir_ptr, mpfir_srcptr, mpz_srcptr);
int     mpfir_sub_z      (mpfir_ptr, mpfir_srcptr, mpz_srcptr);
int     mpfir_z_sub      (mpfir_ptr, mpz_srcptr, mpfir_srcptr);
int     mpfir_mul_z      (mpfir_ptr, mpfir_srcptr, mpz_srcptr);
int     mpfir_div_z      (mpfir_ptr, mpfir_srcptr, mpz_srcptr);
int     mpfir_z_div      (mpfir_ptr, mpz_srcptr, mpfir_srcptr);

/* arithmetic operations between an interval operand and a multiple prec. rational */
int     mpfir_add_q      (mpfir_ptr, mpfir_srcptr, mpq_srcptr);
int     mpfir_sub_q      (mpfir_ptr, mpfir_srcptr, mpq_srcptr);
int     mpfir_q_sub      (mpfir_ptr, mpq_srcptr, mpfir_srcptr);
int     mpfir_mul_q      (mpfir_ptr, mpfir_srcptr, mpq_srcptr);
int     mpfir_div_q      (mpfir_ptr, mpfir_srcptr, mpq_srcptr);
int     mpfir_q_div      (mpfir_ptr, mpq_srcptr, mpfir_srcptr);

/* arithmetic operations between an interval operand and a mult. prec. floating-pt nb */
int     mpfir_add_fr     (mpfir_ptr, mpfir_srcptr, mpfr_srcptr);
int     mpfir_sub_fr     (mpfir_ptr, mpfir_srcptr, mpfr_srcptr);
int     mpfir_fr_sub     (mpfir_ptr, mpfr_srcptr, mpfir_srcptr);
int     mpfir_mul_fr     (mpfir_ptr, mpfir_srcptr, mpfr_srcptr);
int     mpfir_div_fr     (mpfir_ptr, mpfir_srcptr, mpfr_srcptr);
int     mpfir_fr_div     (mpfir_ptr, mpfr_srcptr, mpfir_srcptr);

/* arithmetic operations taking a single interval operand */
int     mpfir_neg        (mpfir_ptr, mpfir_srcptr);
int     mpfir_sqr        (mpfir_ptr, mpfir_srcptr);
/* the inv function generates the whole real interval
   if 0 is in the interval defining the divisor */
int     mpfir_inv        (mpfir_ptr, mpfir_srcptr);
/* the sqrt of a (partially) negative interval is a NaN */
int     mpfir_sqrt       (mpfir_ptr, mpfir_srcptr);
int     mpfir_cbrt       (mpfir_ptr, mpfir_srcptr);
/* the first interval contains the absolute values of */
/* every element of the second interval */
int     mpfir_abs        (mpfir_ptr, mpfir_srcptr);

/* various operations */
int     mpfir_mul_2exp   (mpfir_ptr, mpfir_srcptr, unsigned long);
int     mpfir_mul_2ui    (mpfir_ptr, mpfir_srcptr, unsigned long);
int     mpfir_mul_2si    (mpfir_ptr, mpfir_srcptr, long);
int     mpfir_div_2exp   (mpfir_ptr, mpfir_srcptr, unsigned long);
int     mpfir_div_2ui    (mpfir_ptr, mpfir_srcptr, unsigned long);
int     mpfir_div_2si    (mpfir_ptr, mpfir_srcptr, long);

/* Special functions                                        */
int     mpfir_log        (mpfir_ptr, mpfir_srcptr);
int     mpfir_exp        (mpfir_ptr, mpfir_srcptr);
int     mpfir_exp2       (mpfir_ptr, mpfir_srcptr);

int     mpfir_cos        (mpfir_ptr, mpfir_srcptr);
int     mpfir_sin        (mpfir_ptr, mpfir_srcptr);
int     mpfir_tan        (mpfir_ptr, mpfir_srcptr);
int     mpfir_acos       (mpfir_ptr, mpfir_srcptr);
int     mpfir_asin       (mpfir_ptr, mpfir_srcptr);
int     mpfir_atan       (mpfir_ptr, mpfir_srcptr);
int     mpfir_atan2      (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);

int     mpfir_sec        (mpfir_ptr, mpfir_srcptr);
int     mpfir_csc        (mpfir_ptr, mpfir_srcptr);
int     mpfir_cot        (mpfir_ptr, mpfir_srcptr);

int     mpfir_cosh       (mpfir_ptr, mpfir_srcptr);
int     mpfir_sinh       (mpfir_ptr, mpfir_srcptr);
int     mpfir_tanh       (mpfir_ptr, mpfir_srcptr);
int     mpfir_acosh      (mpfir_ptr, mpfir_srcptr);
int     mpfir_asinh      (mpfir_ptr, mpfir_srcptr);
int     mpfir_atanh      (mpfir_ptr, mpfir_srcptr);

int     mpfir_sech       (mpfir_ptr, mpfir_srcptr);
int     mpfir_csch       (mpfir_ptr, mpfir_srcptr);
int     mpfir_coth       (mpfir_ptr, mpfir_srcptr);

int     mpfir_log1p      (mpfir_ptr, mpfir_srcptr);
int     mpfir_expm1      (mpfir_ptr, mpfir_srcptr);

int     mpfir_log2       (mpfir_ptr, mpfir_srcptr);
int     mpfir_log10      (mpfir_ptr, mpfir_srcptr);

int     mpfir_hypot      (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);

int     mpfir_const_log2         (mpfir_ptr);
int     mpfir_const_pi           (mpfir_ptr);
int     mpfir_const_euler        (mpfir_ptr);
int     mpfir_const_catalan      (mpfir_ptr);

extern int    (*mpfir_cmp)       (mpfir_srcptr, mpfir_srcptr);

extern int    (*mpfir_cmp_d)     (mpfir_srcptr, const double);
extern int    (*mpfir_cmp_ui)    (mpfir_srcptr, const unsigned long);
extern int    (*mpfir_cmp_si)    (mpfir_srcptr, const long);
extern int    (*mpfir_cmp_z)     (mpfir_srcptr, mpz_srcptr);
extern int    (*mpfir_cmp_q)     (mpfir_srcptr, mpq_srcptr);
extern int    (*mpfir_cmp_fr)    (mpfir_srcptr, mpfr_srcptr);

extern int    (*mpfir_is_pos)    (mpfir_srcptr);
extern int    (*mpfir_is_nonneg) (mpfir_srcptr);
extern int    (*mpfir_is_neg)    (mpfir_srcptr);
extern int    (*mpfir_is_nonpos) (mpfir_srcptr);
extern int    (*mpfir_is_zero)   (mpfir_srcptr);
extern int    (*mpfir_is_strictly_pos) (mpfir_srcptr);
extern int    (*mpfir_is_strictly_neg) (mpfir_srcptr);

int     mpfir_has_zero   (mpfir_srcptr);

int     mpfir_nan_p      (mpfir_srcptr);
int     mpfir_inf_p      (mpfir_srcptr);
int     mpfir_bounded_p  (mpfir_srcptr);

/* Interval manipulation */

/* operations related to the internal representation by endpoints */

/* get left or right bound of the interval defined by the
   second argument and put the result in the first one */
int     mpfir_get_left   (mpfr_ptr, mpfir_srcptr);
int     mpfir_get_right  (mpfr_ptr, mpfir_srcptr);

int     mpfir_revert_if_needed  (mpfir_ptr);

/* Set operations on intervals */
/* "Convex hulls" */
/* extends the interval defined by the first argument
   so that it contains the second one */


/* builds an interval whose left bound is the lower (round -infty)
   than the second argument and the right bound is greater
   (round +infty) than the third one */

int     mpfir_interv_d   (mpfir_ptr, const double, const double);
int     mpfir_interv_si  (mpfir_ptr, const long, const long);
int     mpfir_interv_ui  (mpfir_ptr, const unsigned long, const unsigned long);
int     mpfir_interv_z   (mpfir_ptr, mpz_srcptr, mpz_srcptr);
int     mpfir_interv_q   (mpfir_ptr, mpq_srcptr, mpq_srcptr);
int     mpfir_interv_fr  (mpfir_ptr, mpfr_srcptr, mpfr_srcptr);

/* Inclusion tests */
/* tests if the first argument is inside the interval
   defined by the second one */
int     mpfir_is_strictly_inside (mpfir_srcptr, mpfir_srcptr);
int     mpfir_is_inside        	(mpfir_srcptr, mpfir_srcptr);
int     mpfir_is_inside_d      	(const double, mpfir_srcptr);
int     mpfir_is_inside_ui     	(const unsigned long, mpfir_srcptr);
int     mpfir_is_inside_si     	(const long, mpfir_srcptr);
int     mpfir_is_inside_z      	(mpz_srcptr, mpfir_srcptr);
int     mpfir_is_inside_q      	(mpq_srcptr, mpfir_srcptr);
int     mpfir_is_inside_fr   	(mpfr_srcptr, mpfir_srcptr);

/* set operations */
int     mpfir_is_empty   (mpfir_srcptr);
int     mpfir_intersect  (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);
int     mpfir_union      (mpfir_ptr, mpfir_srcptr, mpfir_srcptr);

/* complement... : to do later */


/* Miscellaneous */

/* adds the second argument to the right bound of the first one
   and subtracts the second argument to the left bound of
   the first one */
int     mpfir_increase   (mpfir_ptr, mpfr_srcptr);
/* keeps the same center and multiply the radius by 2*(1+fact) */
int     mpfir_blow       (mpfir_ptr, mpfir_srcptr, double);
/* splits the interval into 2 halves */
int     mpfir_bisect     (mpfir_ptr, mpfir_ptr, mpfir_srcptr);

#ifdef __cplusplus
}
#endif

#endif /* __MPFIR_H__ */
