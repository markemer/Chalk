//
//  CHGraphContext.m
//  Chalk
//
//  Created by Pierre Chatelier on 10/01/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGraphContext.h"

#import "CHChalkContext.h"
#import "CHGmpPool.h"
#import "CHGraphAxis.h"

@implementation CHGraphContext

@synthesize axisHorizontal1;
@synthesize axisHorizontal2;
@synthesize axisVertical1;
@synthesize axisVertical2;
@synthesize chalkContext;
@synthesize axisPrec;

-(instancetype) init
{
  return [self initWithAxisPrec:mpfr_get_default_prec() gmpPool:nil];
}
//end init

-(instancetype) initWithAxisPrec:(mpfr_prec_t)aAxisPrec gmpPool:(CHGmpPool*)aGmpPool
{
  if (!((self = [super init])))
    return nil;
  self->axisPrec = aAxisPrec;
  self->gmpPool = [aGmpPool retain];
  self->chalkContext = [[CHChalkContext alloc] initWithGmpPool:self->gmpPool];
  self->axisHorizontal1 = [[CHGraphAxis alloc] initWithPrec:self->axisPrec gmpPool:self->gmpPool];
  self->axisVertical1   = [[CHGraphAxis alloc] initWithPrec:self->axisPrec gmpPool:self->gmpPool];
  return self;
}
//end initWithAxisPrec:gmpPool:

-(void) dealloc
{
  [self->axisHorizontal1 release];
  [self->axisHorizontal2 release];
  [self->axisVertical1 release];
  [self->axisVertical2 release];
  [self->chalkContext release];
  [self->gmpPool release];
  [super dealloc];
}
//end dealloc

-(void) setAxisPrec:(mpfr_prec_t)value
{
  if (value != self->axisPrec)
  {
    self->axisPrec = value;
    self->axisHorizontal1.prec = self->axisPrec;
    self->axisHorizontal2.prec = self->axisPrec;
    self->axisVertical1.prec = self->axisPrec;
    self->axisVertical2.prec = self->axisPrec;
  }//end if (value != self->axisPrec)
}
//end setAxisPrec

@end
