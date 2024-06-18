//
//  mpfir.c
//  Chalk
//
//  Created by Pierre Chatelier on 11/06/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#include "mpfir.h"

#include <math.h>

int mpfir_estimation_update(mpfir_ptr op)
{
  int result = 0;
  mpfir_revert_if_needed(op);
  result = mpfi_mid(&op->estimation, &op->interval);
  return result;
}
//end mpfir_estimation_update()

double mpfir_estimation_get_d(mpfir_srcptr op, mpfr_rnd_t rnd)
{
  double result = mpfr_get_d(&op->estimation, rnd);
  return result;
}
//end mpfir_estimation_get_d()

void mpfir_estimation_get_fr(mpfr_ptr rop, mpfir_srcptr op)
{
  mpfi_get_fr(rop, &op->interval);
}
//end mpfir_estimation_get_fr()

double mpfir_left_get_d(mpfir_srcptr op, mpfr_rnd_t rnd)
{
  double result = mpfr_get_d(&op->interval.left, rnd);
  return result;
}
//end mpfir_left_get_d()

void mpfir_left_get_fr(mpfr_ptr rop, mpfir_srcptr op)
{
  mpfi_get_left(rop, &op->interval);
}
//end mpfir_left_get_fr()

double mpfir_right_get_d(mpfir_srcptr op, mpfr_rnd_t rnd)
{
  double result = mpfr_get_d(&op->interval.right, rnd);
  return result;
}
//end mpfir_right_get_d()

void mpfir_right_get_fr(mpfr_ptr rop, mpfir_srcptr op)
{
  mpfi_get_right(rop, &op->interval);
}
//end mpfir_right_get_fr()

size_t mpfir_inp_str (mpfir_ptr op, FILE* file1, FILE* file2, FILE* file3, int base1, int base2, int base3, mpfr_rnd_t rnd1, mpfr_rnd_t rnd2, mpfr_rnd_t rnd3)
{
  size_t result = 0;
  result += mpfr_inp_str(&op->interval.left, file1, base1, rnd1);
  result += mpfr_inp_str(&op->interval.right, file2, base2, rnd2);
  result += mpfr_inp_str(&op->estimation, file3, base3, rnd3);
  return result;
}
//end mpfir_inp_str()

size_t mpfir_out_str (FILE* file1, FILE* file2, FILE* file3, int base1, int base2, int base3, size_t n1, size_t n2, size_t n3, mpfir_srcptr op, mpfr_rnd_t rnd1, mpfr_rnd_t rnd2, mpfr_rnd_t rnd3)
{
  size_t result = 0;
  result += mpfr_out_str(file1, base1, n1, &op->interval.left, rnd1);
  result += mpfr_out_str(file2, base2, n2, &op->interval.right, rnd2);
  result += mpfr_out_str(file3, base3, n3, &op->estimation, rnd3);
  return result;
}
//end mpfir_out_str()

int mpfir_fac_ui(mpfir_ptr rop, unsigned long op, mpfr_rnd_t rnd)
{
  int result = 0;
  mpfr_fac_ui(&rop->interval.left, op, MPFR_RNDZ);
  mpfr_fac_ui(&rop->interval.right, op, MPFR_RNDA);
  result = mpfr_fac_ui(&rop->estimation, op, rnd);
  return result;
}
//end mpfir_fac_ui()

int mpfir_round_prec(mpfir_ptr rop, mp_prec_t prec)
{
  int result = mpfi_round_prec(&rop->interval, prec);
  mpfr_prec_round(&rop->estimation, prec, MPFR_RNDN);
  return result;
}
//end mpfir_round_prec()

void mpfir_init(mpfir_ptr rop)
{
  mpfi_init(&rop->interval);
  mpfr_init(&rop->estimation);
}
//end mpfir_init()

void mpfir_init2(mpfir_ptr rop, mp_prec_t prec)
{
  mpfi_init2(&rop->interval, prec);
  mpfr_init2(&rop->estimation, prec);
}
//end mpfir_init2()

void mpfir_clear(mpfir_ptr rop)
{
  mpfi_clear(&rop->interval);
  mpfr_clear(&rop->estimation);
}
//end mpfir_clear()

mp_prec_t mpfir_get_prec(mpfir_srcptr op)
{
  mp_prec_t result = mpfi_get_prec(&op->interval);
  return result;
}
//end mpfir_get_prec()

void mpfir_set_prec(mpfir_ptr rop, mp_prec_t prec)
{
  mpfi_set_prec(&rop->interval, prec);
  mpfr_set_prec(&rop->estimation, prec);
}
//end mpfir_set_prec()

int mpfir_set(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_set(&rop->interval, &op->interval);
  mpfr_set(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_set()

int mpfir_set_si(mpfir_ptr rop, const long op)
{
  int result = mpfi_set_si(&rop->interval, op);
  mpfr_set_si(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_set_si()

int mpfir_set_ui(mpfir_ptr rop, const unsigned long op)
{
  int result = mpfi_set_ui(&rop->interval, op);
  mpfr_set_ui(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_set_ui()

int mpfir_set_d(mpfir_ptr rop, const double op)
{
  int result = mpfi_set_d(&rop->interval, op);
  mpfr_set_d(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_set_d()

int mpfir_set_z(mpfir_ptr rop, mpz_srcptr op)
{
  int result = mpfi_set_z(&rop->interval, op);
  mpfr_set_z(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_set_z()

int mpfir_set_q(mpfir_ptr rop, mpq_srcptr op)
{
  int result = mpfi_set_q(&rop->interval, op);
  mpfr_set_q(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_set_q()

int mpfir_set_fr(mpfir_ptr rop, mpfr_srcptr op)
{
  int result = mpfi_set_fr(&rop->interval, op);
  mpfr_set(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_set_fr()

int mpfir_set_fi(mpfir_ptr rop, mpfi_srcptr op)
{
  int result = mpfi_set(&rop->interval, op);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_set_fi()

int mpfir_set_str(mpfir_ptr rop, const char* buffer, int base)
{
  int result = mpfi_set_str(&rop->interval, buffer, base);
  #pragma warning for some reason, mpfr_set_str will not return the same as mpfi_get_fr(). Bug or mpfi ?
  mpfr_set_str(&rop->estimation, buffer, base, MPFR_RNDN);
  return result;
}
//end mpfir_set_str()

int mpfir_init_set(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_init_set(&rop->interval, &op->interval);
  mpfr_init_set(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_init_set()

int mpfir_init_set_si(mpfir_ptr rop, const long op)
{
  int result = mpfi_init_set_si(&rop->interval, op);
  mpfr_init_set_si(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_init_set_si()

int mpfir_init_set_ui(mpfir_ptr rop, const unsigned long op)
{
  int result = mpfi_init_set_ui(&rop->interval, op);
  mpfr_init_set_ui(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_init_set_ui()

int mpfir_init_set_d(mpfir_ptr rop, const double op)
{
  int result = mpfi_init_set_d(&rop->interval, op);
  mpfr_init_set_d(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_init_set_d()

int mpfir_init_set_z(mpfir_ptr rop, mpz_srcptr op)
{
  int result = mpfi_init_set_z(&rop->interval, op);
  mpfr_init_set_z(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_init_set_z()

int mpfir_init_set_q(mpfir_ptr rop, mpq_srcptr op)
{
  int result = mpfi_init_set_q(&rop->interval, op);
  mpfr_init_set_q(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_init_set_q()

int mpfir_init_set_fr(mpfir_ptr rop, mpfr_srcptr op)
{
  int result = mpfi_init_set_fr(&rop->interval, op);
  mpfr_init_set(&rop->estimation, op, MPFR_RNDN);
  return result;
}
//end mpfir_init_set_fr()

int mpfir_init_set_str(mpfir_ptr rop, const char* buffer, int base)
{
  int result = mpfi_init_set_str(&rop->interval, buffer, base);
  #pragma warning for some reason, mpfr_set_str will not return the same as mpfi_get_fr(). Bug or mpfi ?
  mpfr_init_set_str(&rop->estimation, buffer, base, MPFR_RNDN);
  return result;
}
//end mpfir_init_set_str()

void mpfir_swap(mpfir_ptr rop1, mpfir_ptr rop2)
{
  mpfi_swap(&rop1->interval, &rop2->interval);
  mpfr_swap(&rop1->estimation, &rop2->estimation);
}
//end mpfir_swap()

int mpfir_diam_abs(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_diam_abs(rop, &op->interval);
  return result;
}
//end mpfir_diam_abs()

int mpfir_diam_rel(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_diam_rel(rop, &op->interval);
  return result;
}
//end mpfir_diam_rel()

int mpfir_diam(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_diam(rop, &op->interval);
  return result;
}
//end mpfir_diam()

int mpfir_mag(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_mag(rop, &op->interval);
  return result;
}
//end mpfir_mag()

int mpfir_mig(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_mig(rop, &op->interval);
  return result;
}
//end mpfir_mig()

int mpfir_mid(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_mid(rop, &op->interval);
  return result;
}
//end mpfir_mid()

void mpfir_alea(mpfr_ptr rop, mpfir_srcptr op)
{
  mpfi_alea(rop, &op->interval);
}
//end mpfir_alea()

void mpfir_urandom(mpfr_ptr rop, mpfir_srcptr op, gmp_randstate_t state)
{
  mpfi_urandom(rop, &op->interval, state);
}
//end mpfir_urandom()

double mpfir_get_d(mpfir_srcptr op)
{
  double result = mpfi_get_d(&op->interval);
  return result;
}
//end mpfir_get_d()

void mpfir_get_fr(mpfr_ptr rop, mpfir_srcptr op)
{
  mpfi_get_fr(rop, &op->interval);
}
//end mpfir_get_fr()

int mpfir_add(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_add(&rop->interval, &op1->interval, &op2->interval);
  mpfr_add(&rop->estimation, &op1->estimation, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_add()

int mpfir_sub(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_sub(&rop->interval, &op1->interval, &op2->interval);
  mpfr_sub(&rop->estimation, &op1->estimation, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_sub()

int mpfir_mul(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_mul(&rop->interval, &op1->interval, &op2->interval);
  mpfr_mul(&rop->estimation, &op1->estimation, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_mul()

int mpfir_div(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_div(&rop->interval, &op1->interval, &op2->interval);
  mpfr_div(&rop->estimation, &op1->estimation, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_div()

int mpfir_add_d(mpfir_ptr rop, mpfir_srcptr op1, const double op2)
{
  int result = mpfi_add_d(&rop->interval, &op1->interval, op2);
  mpfr_add_d(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_add_d()

int mpfir_sub_d(mpfir_ptr rop, mpfir_srcptr op1, const double op2)
{
  int result = mpfi_sub_d(&rop->interval, &op1->interval, op2);
  mpfr_sub_d(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_sub_d()

int mpfir_d_sub(mpfir_ptr rop, const double op1, mpfir_srcptr op2)
{
  int result = mpfi_d_sub(&rop->interval, op1, &op2->interval);
  mpfr_d_sub(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_d_sub()

int mpfir_mul_d(mpfir_ptr rop, mpfir_srcptr op1, const double op2)
{
  int result = mpfi_mul_d(&rop->interval, &op1->interval, op2);
  mpfr_mul_d(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_d()

int mpfir_div_d(mpfir_ptr rop, mpfir_srcptr op1, const double op2)
{
  int result = mpfi_div_d(&rop->interval, &op1->interval, op2);
  mpfr_div_d(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_d()

int mpfir_d_div(mpfir_ptr rop, const double op1, mpfir_srcptr op2)
{
  int result = mpfi_d_div(&rop->interval, op1, &op2->interval);
  mpfr_d_div(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_d_div()

int mpfir_add_ui(mpfir_ptr rop, mpfir_srcptr op1, const unsigned long op2)
{
  int result = mpfi_add_ui(&rop->interval, &op1->interval, op2);
  mpfr_add_ui(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_add_ui()

int mpfir_sub_ui(mpfir_ptr rop, mpfir_srcptr op1, const unsigned long op2)
{
  int result = mpfi_sub_ui(&rop->interval, &op1->interval, op2);
  mpfr_sub_ui(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_sub_ui()

int mpfir_ui_sub(mpfir_ptr rop, const unsigned long op1, mpfir_srcptr op2)
{
  int result = mpfi_ui_sub(&rop->interval, op1, &op2->interval);
  mpfr_ui_sub(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_ui_sub()

int mpfir_mul_ui(mpfir_ptr rop, mpfir_srcptr op1, const unsigned long op2)
{
  int result = mpfi_mul_ui(&rop->interval, &op1->interval, op2);
  mpfr_mul_ui(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_ui()

int mpfir_div_ui(mpfir_ptr rop, mpfir_srcptr op1, const unsigned long op2)
{
  int result = mpfi_div_ui(&rop->interval, &op1->interval, op2);
  mpfr_div_ui(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_ui()

int mpfir_ui_div(mpfir_ptr rop, const unsigned long op1, mpfir_srcptr op2)
{
  int result = mpfi_ui_div(&rop->interval, op1, &op2->interval);
  mpfr_ui_div(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_ui_div()

int mpfir_add_si(mpfir_ptr rop, mpfir_srcptr op1, const long op2)
{
  int result = mpfi_add_si(&rop->interval, &op1->interval, op2);
  mpfr_add_si(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_add_si()

int mpfir_sub_si(mpfir_ptr rop, mpfir_srcptr op1, const long op2)
{
  int result = mpfi_sub_si(&rop->interval, &op1->interval, op2);
  mpfr_sub_si(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_sub_si()

int mpfir_si_sub(mpfir_ptr rop, const long op1, mpfir_srcptr op2)
{
  int result = mpfi_si_sub(&rop->interval, op1, &op2->interval);
  mpfr_si_sub(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_si_sub()

int mpfir_mul_si(mpfir_ptr rop, mpfir_srcptr op1, const long op2)
{
  int result = mpfi_mul_si(&rop->interval, &op1->interval, op2);
  mpfr_mul_si(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_si()

int mpfir_div_si(mpfir_ptr rop, mpfir_srcptr op1, const long op2)
{
  int result = mpfi_div_si(&rop->interval, &op1->interval, op2);
  mpfr_div_si(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_si()

int mpfir_si_div(mpfir_ptr rop, const long op1, mpfir_srcptr op2)
{
  int result = mpfi_si_div(&rop->interval, op1, &op2->interval);
  mpfr_si_div(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_si_div()

int mpfir_add_z(mpfir_ptr rop, mpfir_srcptr op1, mpz_srcptr op2)
{
  int result = mpfi_add_z(&rop->interval, &op1->interval, op2);
  mpfr_add_z(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_add_z()

int mpfir_sub_z(mpfir_ptr rop, mpfir_srcptr op1, mpz_srcptr op2)
{
  int result = mpfi_sub_z(&rop->interval, &op1->interval, op2);
  mpfr_sub_z(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_sub_z()

int mpfir_z_sub(mpfir_ptr rop, mpz_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_z_sub(&rop->interval, op1, &op2->interval);
  mpfr_z_sub(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_z_sub()

int mpfir_mul_z(mpfir_ptr rop, mpfir_srcptr op1, mpz_srcptr op2)
{
  int result = mpfi_mul_z(&rop->interval, &op1->interval, op2);
  mpfr_mul_z(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_z()

int mpfir_div_z(mpfir_ptr rop, mpfir_srcptr op1, mpz_srcptr op2)
{
  int result = mpfi_div_z(&rop->interval, &op1->interval, op2);
  mpfr_div_z(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_z()

int mpfir_z_div(mpfir_ptr rop, mpz_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_z_div(&rop->interval, op1, &op2->interval);
  mpfr_div_z(&rop->estimation, &op2->estimation, op1, MPFR_RNDN);
  mpfr_ui_div(&rop->estimation, 1, &rop->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_z_div()

int mpfir_add_q(mpfir_ptr rop, mpfir_srcptr op1, mpq_srcptr op2)
{
  int result = mpfi_add_q(&rop->interval, &op1->interval, op2);
  mpfr_add_q(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_add_q()

int mpfir_sub_q(mpfir_ptr rop, mpfir_srcptr op1, mpq_srcptr op2)
{
  int result = mpfi_sub_q(&rop->interval, &op1->interval, op2);
  mpfr_sub_q(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_sub_q()

int mpfir_q_sub(mpfir_ptr rop, mpq_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_q_sub(&rop->interval, op1, &op2->interval);
  mpfr_sub_q(&rop->estimation, &op2->estimation, op1, MPFR_RNDN);
  mpfr_neg(&rop->estimation, &rop->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_q_sub()

int mpfir_mul_q(mpfir_ptr rop, mpfir_srcptr op1, mpq_srcptr op2)
{
  int result = mpfi_mul_q(&rop->interval, &op1->interval, op2);
  mpfr_mul_q(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_q()

int mpfir_div_q(mpfir_ptr rop, mpfir_srcptr op1, mpq_srcptr op2)
{
  int result = mpfi_div_q(&rop->interval, &op1->interval, op2);
  mpfr_div_q(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_q()

int mpfir_q_div(mpfir_ptr rop, mpq_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_q_div(&rop->interval, op1, &op2->interval);
  mpfr_div_q(&rop->estimation, &op2->estimation, op1, MPFR_RNDN);
  mpfr_ui_div(&rop->estimation, 1, &rop->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_q_div()

int mpfir_add_fr(mpfir_ptr rop, mpfir_srcptr op1, mpfr_srcptr op2)
{
  int result = mpfi_add_fr(&rop->interval, &op1->interval, op2);
  mpfr_add(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_add_fr()

int mpfir_sub_fr(mpfir_ptr rop, mpfir_srcptr op1, mpfr_srcptr op2)
{
  int result = mpfi_sub_fr(&rop->interval, &op1->interval, op2);
  mpfr_sub(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_sub_fr()

int mpfir_fr_sub(mpfir_ptr rop, mpfr_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_fr_sub(&rop->interval, op1, &op2->interval);
  mpfr_sub(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_fr_sub()

int mpfir_mul_fr(mpfir_ptr rop, mpfir_srcptr op1, mpfr_srcptr op2)
{
  int result = mpfi_mul_fr(&rop->interval, &op1->interval, op2);
  mpfr_mul(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_fr()

int mpfir_div_fr(mpfir_ptr rop, mpfir_srcptr op1, mpfr_srcptr op2)
{
  int result = mpfi_div_fr(&rop->interval, &op1->interval, op2);
  mpfr_div(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_fr()

int mpfir_fr_div(mpfir_ptr rop, mpfr_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_fr_div(&rop->interval, op1, &op2->interval);
  mpfr_div(&rop->estimation, op1, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_fr_div()

int mpfir_neg(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_neg(&rop->interval, &op->interval);
  mpfr_neg(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_neg()

int mpfir_sqr(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_sqr(&rop->interval, &op->interval);
  mpfr_sqr(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_sqr()

int mpfir_floor(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = 0;
  mpfr_flags_t oldFlags = mpfr_flags_save();
  mpfr_clear_flags();
  mpfr_floor(&rop->interval.left, &rop->interval.left);
  bool isLeftExact = !mpfr_inexflag_p();
  mpfr_clear_flags();
  mpfr_floor(&rop->interval.right, &rop->interval.right);
  bool isRightExact = !mpfr_inexflag_p();
  mpfr_clear_flags();
  mpfr_floor(&rop->estimation, &op->estimation);
  mpfr_flags_restore(oldFlags, MPFR_FLAGS_ALL);
  result =
    (!isLeftExact ? MPFI_FLAGS_LEFT_ENDPOINT_INEXACT : 0) |
    (!isRightExact ? MPFI_FLAGS_RIGHT_ENDPOINT_INEXACT : 0);
  return result;
}
//end mpfir_floor()

int mpfir_ceil(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = 0;
  mpfr_flags_t oldFlags = mpfr_flags_save();
  mpfr_clear_flags();
  mpfr_ceil(&rop->interval.left, &rop->interval.left);
  bool isLeftExact = !mpfr_inexflag_p();
  mpfr_clear_flags();
  mpfr_ceil(&rop->interval.right, &rop->interval.right);
  bool isRightExact = !mpfr_inexflag_p();
  mpfr_clear_flags();
  mpfr_ceil(&rop->estimation, &op->estimation);
  mpfr_flags_restore(oldFlags, MPFR_FLAGS_ALL);
  result =
    (!isLeftExact ? MPFI_FLAGS_LEFT_ENDPOINT_INEXACT : 0) |
    (!isRightExact ? MPFI_FLAGS_RIGHT_ENDPOINT_INEXACT : 0);
  return result;
}
//end mpfir_ceil()

int mpfir_inv(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_inv(&rop->interval, &op->interval);
  mpfr_ui_div(&rop->estimation, 1, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_inv()

int mpfir_sqrt(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_sqrt(&rop->interval, &op->interval);
  mpfr_sqrt(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_sqrt()

int mpfir_cbrt(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_cbrt(&rop->interval, &op->interval);
  mpfr_cbrt(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_cbrt()

int mpfir_abs(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_abs(&rop->interval, &op->interval);
  mpfr_abs(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_abs()

int mpfir_mul_2exp(mpfir_ptr rop, mpfir_srcptr op1, unsigned long op2)
{
  int result = mpfi_mul_2exp(&rop->interval, &op1->interval, op2);
  mpfr_mul_2exp(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_2exp()

int mpfir_mul_2ui(mpfir_ptr rop, mpfir_srcptr op1, unsigned long op2)
{
  int result = mpfi_mul_2ui(&rop->interval, &op1->interval, op2);
  mpfr_mul_2ui(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_2ui()

int mpfir_mul_2si(mpfir_ptr rop, mpfir_srcptr op1, long op2)
{
  int result = mpfi_mul_2si(&rop->interval, &op1->interval, op2);
  mpfr_mul_2si(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_mul_2si()

int mpfir_div_2exp(mpfir_ptr rop, mpfir_srcptr op1, unsigned long op2)
{
  int result = mpfi_div_2exp(&rop->interval, &op1->interval, op2);
  mpfr_div_2exp(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_2exp()

int mpfir_div_2ui(mpfir_ptr rop, mpfir_srcptr op1, unsigned long op2)
{
  int result = mpfi_div_2ui(&rop->interval, &op1->interval, op2);
  mpfr_div_2ui(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_2ui()

int mpfir_div_2si(mpfir_ptr rop, mpfir_srcptr op1, long op2)
{
  int result = mpfi_div_2si(&rop->interval, &op1->interval, op2);
  mpfr_div_2si(&rop->estimation, &op1->estimation, op2, MPFR_RNDN);
  return result;
}
//end mpfir_div_2si()

int mpfir_log(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_log(&rop->interval, &op->interval);
  mpfr_log(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_log()

int mpfir_exp(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_exp(&rop->interval, &op->interval);
  mpfr_exp(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_exp()

int mpfir_exp2(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_exp2(&rop->interval, &op->interval);
  mpfr_exp2(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_exp2()

int mpfir_cos(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = 0;
  int isLargerThanTwoPi = 0;
  mpfr_exp_t e1 = mpfr_get_exp(&op->interval.left);
  mpfr_exp_t e2 = mpfr_get_exp(&op->interval.right);
  int fastTestExponents = ((e1 > 0) && (e2 > 0) && ((e2-e1) > 4)) ? 1 : 0;
  if (fastTestExponents)
    isLargerThanTwoPi = 1;
  else//if (!fastTestExponents)
  {
    double rightU = mpfr_get_d(&op->interval.right, MPFR_RNDU);
    double rightD = mpfr_get_d(&op->interval.right, MPFR_RNDD);
    double leftU = mpfr_get_d(&op->interval.left, MPFR_RNDU);
    double leftD = mpfr_get_d(&op->interval.left, MPFR_RNDD);
    double evaluatedDiam_sup = rightU-leftD;
    double evaluatedDiam_inf = rightD-leftU;
    int canFastEvaluate = !isnan(evaluatedDiam_sup) && !isinf(evaluatedDiam_sup) &&
                          !isnan(evaluatedDiam_inf) && !isinf(evaluatedDiam_inf);
    double epsilon = 1e-34;
    if (canFastEvaluate && (evaluatedDiam_inf > 2*M_PI+epsilon))
      isLargerThanTwoPi = 1;
    else if (canFastEvaluate && (evaluatedDiam_sup < 2*M_PI-epsilon))
      isLargerThanTwoPi = 0;
    else//if (evaluatedDiam < 2*M_PI)
    {
      mpfr_t diam, pi;
      mpfr_init2(diam, mpfir_get_prec(op));
      mpfr_init2(pi, mpfir_get_prec(op));
      mpfi_diam_abs(diam, &op->interval);
      mpfr_const_pi(pi, MPFR_RNDZ);
      mpfr_sub(diam, diam, pi, MPFR_RNDZ);
      mpfr_sub(diam, diam, pi, MPFR_RNDZ);
      isLargerThanTwoPi = (MPFR_SIGN(diam)>0);
      mpfr_clear(diam);
      mpfr_clear(pi);
    }//end if (evaluatedDiam < 2*M_PI)
  }//end if (!fastTestExponents)
  if (!isLargerThanTwoPi)
  {
    result = mpfi_cos(&rop->interval, &op->interval);
    mpfr_cos(&rop->estimation, &op->estimation, MPFR_RNDN);
  }//end if (!isLargerThanTwoPi)
  else//if (isLargerThanTwoPi)
  {
    mpfr_set_d(&rop->interval.left, -1, MPFR_RNDN);
    mpfr_set_d(&rop->estimation, 0, MPFR_RNDN);
    mpfr_prec_round(&rop->estimation, MPFR_PREC_MIN, MPFR_RNDN);
    mpfr_set_d(&rop->interval.right, 1, MPFR_RNDN);
    result = MPFI_FLAGS_BOTH_ENDPOINTS_EXACT;
    mpfr_set_inexflag();
  }//end if (isLargerThanTwoPi)
  return result;
}
//end mpfir_cos()

int mpfir_sin(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = 0;
  int isLargerThanTwoPi = 0;
  mpfr_exp_t e1 = mpfr_get_exp(&op->interval.left);
  mpfr_exp_t e2 = mpfr_get_exp(&op->interval.right);
  int fastTestExponents = ((e1 > 0) && (e2 > 0) && ((e2-e1) > 4)) ? 1 : 0;
  if (fastTestExponents)
    isLargerThanTwoPi = 1;
  else//if (!fastTestExponents)
  {
    double rightU = mpfr_get_d(&op->interval.right, MPFR_RNDU);
    double rightD = mpfr_get_d(&op->interval.right, MPFR_RNDD);
    double leftU = mpfr_get_d(&op->interval.left, MPFR_RNDU);
    double leftD = mpfr_get_d(&op->interval.left, MPFR_RNDD);
    double evaluatedDiam_sup = rightU-leftD;
    double evaluatedDiam_inf = rightD-leftU;
    int canFastEvaluate = !isnan(evaluatedDiam_sup) && !isinf(evaluatedDiam_sup) &&
                          !isnan(evaluatedDiam_inf) && !isinf(evaluatedDiam_inf);
    double epsilon = 1e-34;
    if (canFastEvaluate && (evaluatedDiam_inf > 2*M_PI+epsilon))
      isLargerThanTwoPi = 1;
    else if (canFastEvaluate && (evaluatedDiam_sup < 2*M_PI-epsilon))
      isLargerThanTwoPi = 0;
    else//if (evaluatedDiam < 2*M_PI)
    {
      mpfr_t diam, pi;
      mpfr_init2(diam, mpfir_get_prec(op));
      mpfr_init2(pi, mpfir_get_prec(op));
      mpfi_diam_abs(diam, &op->interval);
      mpfr_const_pi(pi, MPFR_RNDZ);
      mpfr_sub(diam, diam, pi, MPFR_RNDZ);
      mpfr_sub(diam, diam, pi, MPFR_RNDZ);
      isLargerThanTwoPi = (MPFR_SIGN(diam)>0);
      mpfr_clear(diam);
      mpfr_clear(pi);
    }//end if (evaluatedDiam < 2*M_PI)
  }//end if (!fastTestExponents)
  if (!isLargerThanTwoPi)
  {
    result = mpfi_sin(&rop->interval, &op->interval);
    mpfr_sin(&rop->estimation, &op->estimation, MPFR_RNDN);
  }//end if (!isLargerThanTwoPi)
  else//if (isLargerThanTwoPi)
  {
    mpfr_set_d(&rop->interval.left, -1, MPFR_RNDN);
    mpfr_set_d(&rop->estimation, 0, MPFR_RNDN);
    mpfr_prec_round(&rop->estimation, MPFR_PREC_MIN, MPFR_RNDN);
    mpfr_set_d(&rop->interval.right, 1, MPFR_RNDN);
    result = MPFI_FLAGS_BOTH_ENDPOINTS_EXACT;
    mpfr_set_inexflag();
  }//end if (isLargerThanTwoPi)
  return result;
}
//end mpfir_sin()

int mpfir_tan(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = 0;
  int isLargerThanTwoPi = 0;
  mpfr_exp_t e1 = mpfr_get_exp(&op->interval.left);
  mpfr_exp_t e2 = mpfr_get_exp(&op->interval.right);
  int fastTestExponents = ((e1 > 0) && (e2 > 0) && ((e2-e1) > 4)) ? 1 : 0;
  if (fastTestExponents)
    isLargerThanTwoPi = 1;
  else//if (!fastTestExponents)
  {
    double rightU = mpfr_get_d(&op->interval.right, MPFR_RNDU);
    double rightD = mpfr_get_d(&op->interval.right, MPFR_RNDD);
    double leftU = mpfr_get_d(&op->interval.left, MPFR_RNDU);
    double leftD = mpfr_get_d(&op->interval.left, MPFR_RNDD);
    double evaluatedDiam_sup = rightU-leftD;
    double evaluatedDiam_inf = rightD-leftU;
    int canFastEvaluate = !isnan(evaluatedDiam_sup) && !isinf(evaluatedDiam_sup) &&
                          !isnan(evaluatedDiam_inf) && !isinf(evaluatedDiam_inf);
    double epsilon = 1e-34;
    if (canFastEvaluate && (evaluatedDiam_inf > 2*M_PI+epsilon))
      isLargerThanTwoPi = 1;
    else if (canFastEvaluate && (evaluatedDiam_sup < 2*M_PI-epsilon))
      isLargerThanTwoPi = 0;
    else//if (evaluatedDiam < 2*M_PI)
    {
      mpfr_t diam, pi;
      mpfr_init2(diam, mpfir_get_prec(op));
      mpfr_init2(pi, mpfir_get_prec(op));
      mpfi_diam_abs(diam, &op->interval);
      mpfr_const_pi(pi, MPFR_RNDZ);
      mpfr_sub(diam, diam, pi, MPFR_RNDZ);
      mpfr_sub(diam, diam, pi, MPFR_RNDZ);
      isLargerThanTwoPi = (MPFR_SIGN(diam)>0);
      mpfr_clear(diam);
      mpfr_clear(pi);
    }//end if (evaluatedDiam < 2*M_PI)
  }//end if (!fastTestExponents)
  if (!isLargerThanTwoPi)
  {
    result = mpfi_tan(&rop->interval, &op->interval);
    mpfr_tan(&rop->estimation, &op->estimation, MPFR_RNDN);
  }//end if (!isLargerThanTwoPi)
  else//if (isLargerThanTwoPi)
  {
    mpfr_set_inf(&rop->interval.left, -1);
    mpfr_set_d(&rop->estimation, 0, MPFR_RNDN);
    mpfr_prec_round(&rop->estimation, MPFR_PREC_MIN, MPFR_RNDN);
    mpfr_set_inf(&rop->interval.right, 1);
    result = MPFI_FLAGS_BOTH_ENDPOINTS_INEXACT;
    mpfr_set_inexflag();
    mpfr_set_erangeflag();
  }//end if (isLargerThanTwoPi)
  return result;
}
//end mpfir_tan()

int mpfir_acos(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_acos(&rop->interval, &op->interval);
  mpfr_acos(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_acos()

int mpfir_asin(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_asin(&rop->interval, &op->interval);
  mpfr_asin(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_asin()

int mpfir_atan(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_atan(&rop->interval, &op->interval);
  mpfr_atan(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_atan()

int mpfir_atan2(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_atan2(&rop->interval, &op1->interval, &op2->interval);
  mpfr_atan2(&rop->estimation, &op1->estimation, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_atan2()

int mpfir_sec(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_sec(&rop->interval, &op->interval);
  mpfr_sec(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_sec()

int mpfir_csc(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_csc(&rop->interval, &op->interval);
  mpfr_csc(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_csc()

int mpfir_cot(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_cot(&rop->interval, &op->interval);
  mpfr_cot(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_cot()

int mpfir_cosh(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_cosh(&rop->interval, &op->interval);
  mpfr_cosh(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_cosh()

int mpfir_sinh(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_sinh(&rop->interval, &op->interval);
  mpfr_sinh(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_sinh()

int mpfir_tanh(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_tanh(&rop->interval, &op->interval);
  mpfr_tanh(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_tanh()

int mpfir_acosh(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_acosh(&rop->interval, &op->interval);
  mpfr_acosh(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_acosh()

int mpfir_asinh(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_asinh(&rop->interval, &op->interval);
  mpfr_asinh(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_asinh()

int mpfir_atanh(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_atanh(&rop->interval, &op->interval);
  mpfr_atanh(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_atanh()

int mpfir_sech(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_sech(&rop->interval, &op->interval);
  mpfr_sech(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_sech()

int mpfir_csch(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_csch(&rop->interval, &op->interval);
  mpfr_csch(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_csch()

int mpfir_coth(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_coth(&rop->interval, &op->interval);
  mpfr_coth(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_coth()

int mpfir_log1p(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_log1p(&rop->interval, &op->interval);
  mpfr_log1p(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_log1p()

int mpfir_expm1(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_expm1(&rop->interval, &op->interval);
  mpfr_expm1(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_expm1()

int mpfir_log2(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_log2(&rop->interval, &op->interval);
  mpfr_log2(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_log2()

int mpfir_log10(mpfir_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_log10(&rop->interval, &op->interval);
  mpfr_log10(&rop->estimation, &op->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_log10()

int mpfir_hypot(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_hypot(&rop->interval, &op1->interval, &op2->interval);
  mpfr_hypot(&rop->estimation, &op1->estimation, &op2->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_hypot()

int mpfir_const_log2(mpfir_ptr rop)
{
  int result = mpfi_const_log2(&rop->interval);
  mpfr_const_log2(&rop->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_const_log2()

int mpfir_const_pi(mpfir_ptr rop)
{
  int result = mpfi_const_pi(&rop->interval);
  mpfr_const_pi(&rop->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_const_pi()

int mpfir_const_euler(mpfir_ptr rop)
{
  int result = mpfi_const_euler(&rop->interval);
  mpfr_const_euler(&rop->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_const_euler()

int mpfir_const_catalan(mpfir_ptr rop)
{
  int result = mpfi_const_catalan(&rop->interval);
  mpfr_const_catalan(&rop->estimation, MPFR_RNDN);
  return result;
}
//end mpfir_const_catalan()

int mpfir_cmp_default(mpfir_srcptr op1, mpfir_srcptr op2) {return mpfi_cmp(&op1->interval, &op2->interval);}
int (*mpfir_cmp) (mpfir_srcptr, mpfir_srcptr) = &mpfir_cmp_default;

int mpfir_cmp_d_default(mpfir_srcptr op1, const double op2) {return mpfi_cmp_d(&op1->interval, op2);}
int (*mpfir_cmp_d) (mpfir_srcptr, const double) = &mpfir_cmp_d_default;

int mpfir_cmp_ui_default(mpfir_srcptr op1, const unsigned long op2) {return mpfi_cmp_ui(&op1->interval, op2);}
int (*mpfir_cmp_ui)(mpfir_srcptr, const unsigned long) = &mpfir_cmp_ui_default;

int mpfir_cmp_si_default(mpfir_srcptr op1, const long op2) {return mpfi_cmp_si(&op1->interval, op2);}
int (*mpfir_cmp_si)(mpfir_srcptr, const long) = &mpfir_cmp_si_default;

int mpfir_cmp_z_default(mpfir_srcptr op1, mpz_srcptr op2) {return mpfi_cmp_z(&op1->interval, op2);}
int (*mpfir_cmp_z)(mpfir_srcptr, mpz_srcptr) = &mpfir_cmp_z_default;

int mpfir_cmp_q_default(mpfir_srcptr op1, mpq_srcptr op2) {return mpfi_cmp_q(&op1->interval, op2);}
int (*mpfir_cmp_q)(mpfir_srcptr, mpq_srcptr) = &mpfir_cmp_q_default;

int mpfir_cmp_fr_default(mpfir_srcptr op1, mpfr_srcptr op2) {return mpfi_cmp_fr(&op1->interval, op2);}
int (*mpfir_cmp_fr)(mpfir_srcptr, mpfr_srcptr) = &mpfir_cmp_fr_default;

int mpfir_is_pos_default(mpfir_srcptr op) {return mpfi_is_pos(&op->interval);}
int (*mpfir_is_pos)(mpfir_srcptr) = &mpfir_is_pos_default;

int mpfir_is_nonneg_default(mpfir_srcptr op) {return mpfi_is_nonneg(&op->interval);}
int (*mpfir_is_nonneg)(mpfir_srcptr) = &mpfir_is_nonneg_default;

int mpfir_is_neg_default(mpfir_srcptr op) {return mpfi_is_neg(&op->interval);}
int (*mpfir_is_neg)(mpfir_srcptr) = &mpfir_is_neg_default;

int mpfir_is_nonpos_default(mpfir_srcptr op) {return mpfi_is_nonpos(&op->interval);}
int (*mpfir_is_nonpos)(mpfir_srcptr) = &mpfir_is_nonpos_default;

int mpfir_is_zero_default(mpfir_srcptr op) {return mpfi_is_zero(&op->interval);}
int (*mpfir_is_zero)(mpfir_srcptr) = &mpfir_is_zero_default;

int mpfir_is_strictly_pos_default(mpfir_srcptr op) {return mpfi_is_strictly_pos(&op->interval);}
int (*mpfir_is_strictly_pos)(mpfir_srcptr) = &mpfir_is_strictly_pos_default;

int mpfir_is_strictly_neg_default(mpfir_srcptr op) {return mpfi_is_strictly_neg(&op->interval);}
int (*mpfir_is_strictly_neg)(mpfir_srcptr) = &mpfir_is_strictly_neg_default;

int mpfir_has_zero(mpfir_srcptr op)
{
  int result = mpfi_has_zero(&op->interval);
  return result;
}
//end mpfir_has_zero()

int mpfir_nan_p(mpfir_srcptr op)
{
  int result = mpfi_nan_p(&op->interval);
  return result;
}
//end mpfir_nan_p()

int mpfir_inf_p(mpfir_srcptr op)
{
  int result = mpfi_inf_p(&op->interval);
  return result;
}
//end mpfir_inf_p()

int mpfir_bounded_p(mpfir_srcptr op)
{
  int result = mpfi_bounded_p(&op->interval);
  return result;
}
//end mpfir_bounded_p()

int mpfir_get_left(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_get_left(rop, &op->interval);
  return result;
}
//end mpfir_get_left()

int mpfir_get_right(mpfr_ptr rop, mpfir_srcptr op)
{
  int result = mpfi_get_right(rop, &op->interval);
  return result;
}
//end mpfir_get_right()

int mpfir_revert_if_needed(mpfir_ptr rop)
{
  int result = mpfi_revert_if_needed(&rop->interval);
  return result;
}
//end mpfir_revert_if_needed()

int mpfir_interv_d(mpfir_ptr rop, const double op1, const double op2)
{
  int result = mpfi_interv_d(&rop->interval, op1, op2);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_interv_d()

int mpfir_interv_si(mpfir_ptr rop, const long op1, const long op2)
{
  int result = mpfi_interv_si(&rop->interval, op1, op2);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_interv_si()

int mpfir_interv_ui(mpfir_ptr rop, const unsigned long op1, const unsigned long op2)
{
  int result = mpfi_interv_ui(&rop->interval, op1, op2);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_interv_ui()

int mpfir_interv_z(mpfir_ptr rop, mpz_srcptr op1, mpz_srcptr op2)
{
  int result = mpfi_interv_z(&rop->interval, op1, op2);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_interv_z()

int mpfir_interv_q(mpfir_ptr rop, mpq_srcptr op1, mpq_srcptr op2)
{
  int result = mpfi_interv_q(&rop->interval, op1, op2);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_interv_q()

int mpfir_interv_fr(mpfir_ptr rop, mpfr_srcptr op1, mpfr_srcptr op2)
{
  int result = mpfi_interv_fr(&rop->interval, op1, op2);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_interv_fr()

int mpfir_is_strictly_inside(mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_is_strictly_inside(&op1->interval, &op2->interval);
  return result;
}
//end mpfir_is_strictly_inside()

int mpfir_is_inside(mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_is_inside(&op1->interval, &op2->interval);
  return result;
}
//end mpfir_is_inside()

int mpfir_is_inside_d(const double op1, mpfir_srcptr op2)
{
  int result = mpfi_is_inside_d(op1, &op2->interval);
  return result;
}
//end mpfir_is_inside_d()

int mpfir_is_inside_ui(const unsigned long op1, mpfir_srcptr op2)
{
  int result = mpfi_is_inside_ui(op1, &op2->interval);
  return result;
}
//end mpfir_is_inside_ui()

int mpfir_is_inside_si(const long op1, mpfir_srcptr op2)
{
  int result = mpfi_is_inside_si(op1, &op2->interval);
  return result;
}
//end mpfir_is_inside_si()

int mpfir_is_inside_z(mpz_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_is_inside_z(op1, &op2->interval);
  return result;
}
//end mpfir_is_inside_z()

int mpfir_is_inside_q(mpq_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_is_inside_q(op1, &op2->interval);
  return result;
}
//end mpfir_is_inside_q()

int mpfir_is_inside_fr(mpfr_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_is_inside_fr(op1, &op2->interval);
  return result;
}
//end mpfir_is_inside_fr()

int mpfir_is_empty(mpfir_srcptr op)
{
  int result = mpfi_is_empty(&op->interval);
  return result;
}
//end mpfir_is_empty()

int mpfir_intersect(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_intersect(&rop->interval, &op1->interval, &op2->interval);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_intersect()

int mpfir_union(mpfir_ptr rop, mpfir_srcptr op1, mpfir_srcptr op2)
{
  int result = mpfi_union(&rop->interval, &op1->interval, &op2->interval);
  mpfi_get_fr(&rop->estimation, &rop->interval);
  return result;
}
//end mpfir_union()

int mpfir_increase(mpfir_ptr rop, mpfr_srcptr op)
{
  int result = mpfi_increase(&rop->interval, op);
  return result;
}
//end mpfir_increase()

int mpfir_blow(mpfir_ptr rop, mpfir_srcptr op1, double op2)
{
  int result = mpfi_blow(&rop->interval, &op1->interval, op2);
  return result;
}
//end mpfir_blow()

int mpfir_bisect(mpfir_ptr rop1, mpfir_ptr rop2, mpfir_srcptr op)
{
  int result = mpfi_bisect(&rop1->interval, &rop2->interval, &op->interval);
  mpfi_get_fr(&rop1->estimation, &rop1->interval);
  mpfi_get_fr(&rop2->estimation, &rop2->interval);
  return result;
}
//end mpfir_bisect()

