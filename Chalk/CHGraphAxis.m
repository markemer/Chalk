//
//  CHGraphAxis.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/01/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGraphAxis.h"

#import "CHGraphScale.h"
#import "CHChalkUtils.h"

@implementation CHGraphAxis

@synthesize scale;
@synthesize majorStepAuto;
@dynamic    majorStep;
@synthesize minorDivisions;
@synthesize prec;

-(instancetype) init
{
  return [self initWithPrec:mpfr_get_default_prec() gmpPool:nil];
}
//end init

-(instancetype) initWithPrec:(mpfr_prec_t)aPrec gmpPool:(CHGmpPool*)aGmpPool
{
  if (!((self = [super init])))
    return nil;
  self->prec = aPrec;
  self->gmpPool = [aGmpPool retain];
  self->scale = [[CHGraphScale alloc] initWithPrec:prec gmpPool:gmpPool];
  mpfrDepool(self->majorStep, self->prec, self->gmpPool);
  mpfr_set_d(self->majorStep, 10, MPFR_RNDN);
  self->minorDivisions = 10;
  return self;
}
//end initWithPool:

-(void) dealloc
{
  mpfrRepool(self->majorStep, self->gmpPool);
  [self->scale release];
  [self->gmpPool release];
  [super dealloc];
}
//end dealloc

-(mpfr_ptr) majorStep
{
  mpfr_ptr result = self->majorStep;
  return result;
}
//end majorStep

-(void) setPrec:(mpfr_prec_t)value
{
  if (value != self->prec)
  {
    self->prec = value;
    mpfr_set_prec(self->majorStep, self->prec);
    self->scale.prec = self->prec;
  }//end if (value != self->prec)
}
//end setPrec:

@end
