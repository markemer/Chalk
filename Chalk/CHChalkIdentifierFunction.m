//
//  CHChalkIdentifierFunction.m
//  Chalk
//
//  Created by Pierre Chatelier on 08/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkIdentifierFunction.h"

@implementation CHChalkIdentifierFunction

@synthesize argsPossibleCount;
@synthesize argumentNames;
@synthesize definition;

-(void) dealloc
{
  self.argumentNames = nil;
  self.definition = nil;
  [super dealloc];
}
//end dealloc

+(instancetype) intervalIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"interval" caseSensitive:NO tokens:@[@"interval"] symbol:@"interval" symbolAsText:@"interval" symbolAsTeX:@"interval" argsPossibleCount:NSMakeRange(2, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end intervalIdentifier

+(instancetype) absIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"abs" caseSensitive:NO tokens:@[@"abs",@"modulus"] symbol:@"abs" symbolAsText:@"abs" symbolAsTeX:@"|{%@}|" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end absIdentifier

+(instancetype) angleIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"angle" caseSensitive:NO tokens:@[@"angle",@"arg"] symbol:@"angle" symbolAsText:@"angle" symbolAsTeX:@"angle\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end angleIdentifier

+(instancetype) anglesIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"angles" caseSensitive:NO tokens:@[@"angles"] symbol:@"angles" symbolAsText:@"angles" symbolAsTeX:@"angles\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end anglesIdentifier

+(instancetype) floorIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"floor" caseSensitive:NO tokens:@[@"floor"] symbol:@"floor" symbolAsText:@"floor" symbolAsTeX:@"\\lfloor{%@}\\rfloor" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end floorIdentifier

+(instancetype) ceilIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"ceil" caseSensitive:NO tokens:@[@"ceil"] symbol:@"ceil" symbolAsText:@"ceil" symbolAsTeX:@"\\lceil{%@}\\rceil" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end ceilIdentifier

+(instancetype) invIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"invert" caseSensitive:NO tokens:@[@"invert"] symbol:@"invert" symbolAsText:@"invert" symbolAsTeX:@"{%@}^{-1}" argsPossibleCount:NSMakeRange(1, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end invIdentifier

+(instancetype) powIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"pow" caseSensitive:NO tokens:@[@"pow"] symbol:@"pow" symbolAsText:@"pow" symbolAsTeX:@"{%@}^{%@}" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end powIdentifier

+(instancetype) sqrtIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"sqrt" caseSensitive:NO tokens:@[@"sqrt", @"\u221A"] symbol:@"sqrt" symbolAsText:@"sqrt" symbolAsTeX:@"\\sqrt{%@}" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sqrtIdentifier

+(instancetype) cbrtIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"cbrt" caseSensitive:NO tokens:@[@"cbrt", @"\u221B"] symbol:@"cbrt" symbolAsText:@"cbrt" symbolAsTeX:@"\\sqrt[3]{%@}" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end cbrtIdentifier

+(instancetype) rootIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"root" caseSensitive:NO tokens:@[@"root"] symbol:@"root" symbolAsText:@"root" symbolAsTeX:@"\\sqrt[%1@]{%0@}" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end rootIdentifier

+(instancetype) expIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"exp" caseSensitive:NO tokens:@[@"exp"] symbol:@"exp" symbolAsText:@"exp" symbolAsTeX:@"e^{%@}" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end expIdentifier

+(instancetype) lnIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"ln" caseSensitive:NO tokens:@[@"ln"] symbol:@"ln" symbolAsText:@"ln" symbolAsTeX:@"\\ln\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end lnIdentifier

+(instancetype) log10Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"log10" caseSensitive:NO tokens:@[@"log10"] symbol:@"log10" symbolAsText:@"log10" symbolAsTeX:@"\\log_{10}\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end log10Identifier

+(instancetype) sinIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"sin" caseSensitive:NO tokens:@[@"sin"] symbol:@"sin" symbolAsText:@"sin" symbolAsTeX:@"\\sin\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sinIdentifier

+(instancetype) cosIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"cos" caseSensitive:NO tokens:@[@"cos"] symbol:@"cos" symbolAsText:@"cos" symbolAsTeX:@"\\cos\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end cosIdentifier

+(instancetype) tanIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"tan" caseSensitive:NO tokens:@[@"tan"] symbol:@"tan" symbolAsText:@"tan" symbolAsTeX:@"\\tan\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end tanIdentifier

+(instancetype) asinIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"asin" caseSensitive:NO tokens:@[@"asin", @"arcsin"] symbol:@"asin" symbolAsText:@"asin" symbolAsTeX:@"\\arcsin\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end asinIdentifier

+(instancetype) acosIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"acos" caseSensitive:NO tokens:@[@"acos", @"arccos"] symbol:@"acos" symbolAsText:@"acos" symbolAsTeX:@"\\arccos\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end acosIdentifier

+(instancetype) atanIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"atan" caseSensitive:NO tokens:@[@"atan", @"arctan"] symbol:@"atan" symbolAsText:@"atan" symbolAsTeX:@"\\arctan\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end atanIdentifier

+(instancetype) atan2Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"atan2" caseSensitive:NO tokens:@[@"atan2", @"arctan2"] symbol:@"atan2" symbolAsText:@"atan2" symbolAsTeX:@"\\arctan\\!2\\left({%@,%@}\\right)" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end atan2Identifier

+(instancetype) sinhIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"sinh" caseSensitive:NO tokens:@[@"sinh"] symbol:@"sinh" symbolAsText:@"sinh" symbolAsTeX:@"\\sinh\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sinhIdentifier

+(instancetype) coshIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"cosh" caseSensitive:NO tokens:@[@"cosh"] symbol:@"cosh" symbolAsText:@"cosh" symbolAsTeX:@"\\cosh\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end coshIdentifier

+(instancetype) tanhIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"tanh" caseSensitive:NO tokens:@[@"tanh"] symbol:@"tanh" symbolAsText:@"tanh" symbolAsTeX:@"\\tanh\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end tanhIdentifier

+(instancetype) asinhIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"asinh" caseSensitive:NO tokens:@[@"asinh", @"arcsinh"] symbol:@"asinh" symbolAsText:@"asinh" symbolAsTeX:@"arcsinh\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sinhIdentifier

+(instancetype) acoshIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"acosh" caseSensitive:NO tokens:@[@"acosh", @"arccosh"] symbol:@"acosh" symbolAsText:@"acosh" symbolAsTeX:@"arccosh\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end acoshIdentifier

+(instancetype) atanhIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"atanh" caseSensitive:NO tokens:@[@"atanh", @"arctanh"] symbol:@"atanh" symbolAsText:@"atanh" symbolAsTeX:@"arctanh\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end atanhIdentifier

+(instancetype) gammaIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"gamma" caseSensitive:NO tokens:@[@"gamma"] symbol:@"gamma" symbolAsText:@"gamma" symbolAsTeX:@"\\Gamma\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end gammaIdentifier

+(instancetype) zetaIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"zeta" caseSensitive:NO tokens:@[@"zeta"] symbol:@"zeta" symbolAsText:@"zeta" symbolAsTeX:@"\\zeta\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end zetaIdentifier

+(instancetype) conjIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"conj" caseSensitive:NO tokens:@[@"conj", @"conjugate"] symbol:@"conj" symbolAsText:@"conj" symbolAsTeX:@"\\overline{%@}" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end conjIdentifier

+(instancetype) matrixIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"matrix" caseSensitive:NO tokens:@[@"matrix"] symbol:@"matrix" symbolAsText:@"matrix" symbolAsTeX:@"matrix" argsPossibleCount:NSMakeRange(2, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end matrixIdentifier

+(instancetype) identityIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"identity" caseSensitive:NO tokens:@[@"identity"] symbol:@"identity" symbolAsText:@"identity" symbolAsTeX:@"identity\\left({%@}\\right)" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end identityIdentifier

+(instancetype) transposeIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"transpose" caseSensitive:NO tokens:@[@"transpose"] symbol:@"transpose" symbolAsText:@"transpose" symbolAsTeX:@"{%@}^{T}" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end transposeIdentifier

+(instancetype) traceIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"trace" caseSensitive:NO tokens:@[@"trace"] symbol:@"trace" symbolAsText:@"trace" symbolAsTeX:@"Tr{%@}" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end traceIdentifier

+(instancetype) detIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"det" caseSensitive:NO tokens:@[@"det"] symbol:@"det" symbolAsText:@"det" symbolAsTeX:@"det{%@}" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end detIdentifier

+(instancetype) isPrimeIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"isPrime" caseSensitive:NO tokens:@[@"isPrime"] symbol:@"isPrime" symbolAsText:@"isPrime" symbolAsTeX:@"isPrime" argsPossibleCount:NSMakeRange(1, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end isPrimeIdentifier

+(instancetype) nextPrimeIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"nextPrime" caseSensitive:NO tokens:@[@"nextPrime"] symbol:@"nextPrime" symbolAsText:@"nextPrime" symbolAsTeX:@"nextPrime" argsPossibleCount:NSMakeRange(1, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end nextPrimeIdentifier


+(instancetype) nthPrimeIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"nthPrime" caseSensitive:NO tokens:@[@"nthPrime"] symbol:@"nthPrime" symbolAsText:@"nthPrime" symbolAsTeX:@"nthPrime" argsPossibleCount:NSMakeRange(1, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end nthPrimeIdentifier

+(instancetype) primesIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"primes" caseSensitive:NO tokens:@[@"primes"] symbol:@"primes" symbolAsText:@"primes" symbolAsTeX:@"primes" argsPossibleCount:NSMakeRange(1, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end primesIdentifier

+(instancetype) gcdIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"gcd" caseSensitive:NO tokens:@[@"gcd", @"pgcd"] symbol:@"gcd" symbolAsText:@"gcd" symbolAsTeX:@"gcd" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end gcdIdentifier

+(instancetype) lcmIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"lcm" caseSensitive:NO tokens:@[@"lcm", @"ppcm"] symbol:@"lcm" symbolAsText:@"lcm" symbolAsTeX:@"lcm" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end lcmIdentifier

+(instancetype) modIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"mod" caseSensitive:NO tokens:@[@"mod"] symbol:@"mod" symbolAsText:@"mod" symbolAsTeX:@"mod" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end modIdentifier

+(instancetype) binomialIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"binomial" caseSensitive:NO tokens:@[@"binomial"] symbol:@"binomial" symbolAsText:@"binomial" symbolAsTeX:@"\\binom{%@}{%@}" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end binomialIdentifier

+(instancetype) primorialIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"primorial" caseSensitive:NO tokens:@[@"primorial"] symbol:@"primorial" symbolAsText:@"primorial" symbolAsTeX:@"primorial" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end primorialIdentifier

+(instancetype) fibonacciIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fibonacci" caseSensitive:NO tokens:@[@"fibonacci"] symbol:@"fibonacci" symbolAsText:@"fibonacci" symbolAsTeX:@"fibonacci" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fibonacciIdentifier

+(instancetype) jacobiIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"jacobi" caseSensitive:NO tokens:@[@"jacobi"] symbol:@"jacobi" symbolAsText:@"jacobi" symbolAsTeX:@"jacobi" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end jacobiIdentifier

+(instancetype) inputIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"input" caseSensitive:NO tokens:@[@"input"] symbol:@"input" symbolAsText:@"input" symbolAsTeX:@"input" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end inputIdentifier

+(instancetype) outputIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"output" caseSensitive:NO tokens:@[@"output"] symbol:@"output" symbolAsText:@"output" symbolAsTeX:@"output" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end outputIdentifier

+(instancetype) output2Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"output2" caseSensitive:NO tokens:@[@"output2"] symbol:@"output2" symbolAsText:@"output2" symbolAsTeX:@"output2" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end output2Identifier

+(instancetype) fromBaseIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromBase" caseSensitive:NO tokens:@[@"fromBase"] symbol:@"fromBase" symbolAsText:@"fromBase" symbolAsTeX:@"fromBase" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromBaseIdentifier

+(instancetype) inFileIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"infile" caseSensitive:NO tokens:@[@"infile"] symbol:@"infile" symbolAsText:@"infile" symbolAsTeX:@"infile" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end inFileIdentifier

+(instancetype) outFileIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"outfile" caseSensitive:NO tokens:@[@"outfile"] symbol:@"outfile" symbolAsText:@"outfile" symbolAsTeX:@"outfile" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end outFileIdentifier

+(instancetype) toU8Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toU8" caseSensitive:NO tokens:@[@"toU8"] symbol:@"toU8" symbolAsText:@"toU8" symbolAsTeX:@"toU8" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toU8Identifier

+(instancetype) toS8Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toS8" caseSensitive:NO tokens:@[@"toS8"] symbol:@"toS8" symbolAsText:@"toS8" symbolAsTeX:@"toS8" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toS8Identifier

+(instancetype) toU16Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toU16" caseSensitive:NO tokens:@[@"toU16"] symbol:@"toU16" symbolAsText:@"toU16" symbolAsTeX:@"toU16" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toU16Identifier

+(instancetype) toS16Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toS16" caseSensitive:NO tokens:@[@"toS16"] symbol:@"toS16" symbolAsText:@"toS16" symbolAsTeX:@"toS16" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toS16Identifier

+(instancetype) toU32Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toU32" caseSensitive:NO tokens:@[@"toU32"] symbol:@"toU32" symbolAsText:@"toU32" symbolAsTeX:@"toU32" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toU32Identifier

+(instancetype) toS32Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toS32" caseSensitive:NO tokens:@[@"toS32"] symbol:@"toS32" symbolAsText:@"toS32" symbolAsTeX:@"toS32" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toS32Identifier

+(instancetype) toU64Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toU64" caseSensitive:NO tokens:@[@"toU64"] symbol:@"toU64" symbolAsText:@"toU64" symbolAsTeX:@"toU64" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toU64Identifier

+(instancetype) toS64Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toS64" caseSensitive:NO tokens:@[@"toS64"] symbol:@"toS64" symbolAsText:@"toS64" symbolAsTeX:@"toS64" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toS64Identifier

+(instancetype) toU128Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toU128" caseSensitive:NO tokens:@[@"toU128"] symbol:@"toU128" symbolAsText:@"toU128" symbolAsTeX:@"toU128" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toU128Identifier

+(instancetype) toS128Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toS128" caseSensitive:NO tokens:@[@"toS128"] symbol:@"toS128" symbolAsText:@"toS128" symbolAsTeX:@"toS128" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toS128Identifier

+(instancetype) toU256Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toU256" caseSensitive:NO tokens:@[@"toU256"] symbol:@"toU256" symbolAsText:@"toU256" symbolAsTeX:@"toU256" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toU256Identifier

+(instancetype) toS256Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toS256" caseSensitive:NO tokens:@[@"toS256"] symbol:@"toS256" symbolAsText:@"toS256" symbolAsTeX:@"toS256" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toS256Identifier

+(instancetype) toUCustomIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toUCustom" caseSensitive:NO tokens:@[@"toUCustom"] symbol:@"toUCustom" symbolAsText:@"toUCustom" symbolAsTeX:@"toUCustom" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toUCustomIdentifier

+(instancetype) toSCustomIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toSCustom" caseSensitive:NO tokens:@[@"toSCustom"] symbol:@"toSCustom" symbolAsText:@"toSCustom" symbolAsTeX:@"toSCustom" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toSCustomIdentifier

+(instancetype) toChalkIntegerIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toChalkInteger" caseSensitive:NO tokens:@[@"toChalkInteger"] symbol:@"toChalkInteger" symbolAsText:@"toChalkInteger" symbolAsTeX:@"toChalkInteger" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toChalkIntegerIdentifier

+(instancetype) toF16Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toF16" caseSensitive:NO tokens:@[@"toF16"] symbol:@"toF16" symbolAsText:@"toF16" symbolAsTeX:@"toF16" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toF16Identifier

+(instancetype) toF32Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toF32" caseSensitive:NO tokens:@[@"toF32"] symbol:@"toF32" symbolAsText:@"toF32" symbolAsTeX:@"toF32" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toF32Identifier


+(instancetype) toF64Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toF64" caseSensitive:NO tokens:@[@"toF64"] symbol:@"toF64" symbolAsText:@"toF64" symbolAsTeX:@"toF64" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toF64Identifier

+(instancetype) toF128Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toF128" caseSensitive:NO tokens:@[@"toF128"] symbol:@"toF128" symbolAsText:@"toF128" symbolAsTeX:@"toF128" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toF128Identifier

+(instancetype) toF256Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toF256" caseSensitive:NO tokens:@[@"toF256"] symbol:@"toF256" symbolAsText:@"toF256" symbolAsTeX:@"toF256" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toF256Identifier

+(instancetype) toChalkFloatIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"toChalkFloat" caseSensitive:NO tokens:@[@"toChalkFloat"] symbol:@"toChalkFloat" symbolAsText:@"toChalkFloat" symbolAsTeX:@"toChalkFloat" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end toChalkFloatIdentifier

+(instancetype) fromU8Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromU8" caseSensitive:NO tokens:@[@"fromU8"] symbol:@"fromU8" symbolAsText:@"fromU8" symbolAsTeX:@"fromU8" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromU8Identifier

+(instancetype) fromS8Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromS8" caseSensitive:NO tokens:@[@"fromS8"] symbol:@"fromS8" symbolAsText:@"fromS8" symbolAsTeX:@"fromS8" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromS8Identifier

+(instancetype) fromU16Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromU16" caseSensitive:NO tokens:@[@"fromU16"] symbol:@"fromU16" symbolAsText:@"fromU16" symbolAsTeX:@"fromU16" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromU16Identifier

+(instancetype) fromS16Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromS16" caseSensitive:NO tokens:@[@"fromS16"] symbol:@"fromS16" symbolAsText:@"fromS16" symbolAsTeX:@"fromS16" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromS16Identifier

+(instancetype) fromU32Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromU32" caseSensitive:NO tokens:@[@"fromU32"] symbol:@"fromU32" symbolAsText:@"fromU32" symbolAsTeX:@"fromU32" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromU32Identifier

+(instancetype) fromS32Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromS32" caseSensitive:NO tokens:@[@"fromS32"] symbol:@"fromS32" symbolAsText:@"fromS32" symbolAsTeX:@"fromS32" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromS32Identifier

+(instancetype) fromU64Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromU64" caseSensitive:NO tokens:@[@"fromU64"] symbol:@"fromU64" symbolAsText:@"fromU64" symbolAsTeX:@"fromU64" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromU64Identifier

+(instancetype) fromS64Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromS64" caseSensitive:NO tokens:@[@"fromS64"] symbol:@"fromS64" symbolAsText:@"fromS64" symbolAsTeX:@"fromS64" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromS64Identifier

+(instancetype) fromU128Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromU128" caseSensitive:NO tokens:@[@"fromU128"] symbol:@"fromU128" symbolAsText:@"fromU128" symbolAsTeX:@"fromU128" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromU128Identifier

+(instancetype) fromS128Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromS128" caseSensitive:NO tokens:@[@"fromS128"] symbol:@"fromS128" symbolAsText:@"fromS128" symbolAsTeX:@"fromS128" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromS128Identifier

+(instancetype) fromU256Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromU256" caseSensitive:NO tokens:@[@"fromU256"] symbol:@"fromU256" symbolAsText:@"fromU256" symbolAsTeX:@"fromU256" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromU256Identifier

+(instancetype) fromS256Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromS256" caseSensitive:NO tokens:@[@"fromS256"] symbol:@"fromS256" symbolAsText:@"fromS256" symbolAsTeX:@"fromS256" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromS256Identifier

+(instancetype) fromUCustomIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromUCustom" caseSensitive:NO tokens:@[@"fromUCustom"] symbol:@"fromUCustom" symbolAsText:@"fromUCustom" symbolAsTeX:@"fromUCustom" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromUCustomIdentifier

+(instancetype) fromSCustomIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromSCustom" caseSensitive:NO tokens:@[@"fromSCustom"] symbol:@"fromSCustom" symbolAsText:@"fromSCustom" symbolAsTeX:@"fromSCustom" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromSCustomIdentifier

+(instancetype) fromChalkIntegerIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromChalkInteger" caseSensitive:NO tokens:@[@"fromChalkInteger"] symbol:@"fromChalkInteger" symbolAsText:@"fromChalkInteger" symbolAsTeX:@"fromChalkInteger" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromChalkIntegerIdentifier

+(instancetype) fromF16Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromF16" caseSensitive:NO tokens:@[@"fromF16"] symbol:@"fromF16" symbolAsText:@"fromF16" symbolAsTeX:@"fromF16" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromF16Identifier

+(instancetype) fromF32Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromF32" caseSensitive:NO tokens:@[@"fromF32"] symbol:@"fromF32" symbolAsText:@"fromF32" symbolAsTeX:@"fromF32" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromF32Identifier


+(instancetype) fromF64Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromF64" caseSensitive:NO tokens:@[@"fromF64"] symbol:@"fromF64" symbolAsText:@"fromF64" symbolAsTeX:@"fromF64" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromF64Identifier

+(instancetype) fromF128Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromF128" caseSensitive:NO tokens:@[@"fromF128"] symbol:@"fromF128" symbolAsText:@"fromF128" symbolAsTeX:@"fromF128" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromF128Identifier

+(instancetype) fromF256Identifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromF256" caseSensitive:NO tokens:@[@"fromF256"] symbol:@"fromF256" symbolAsText:@"fromF256" symbolAsTeX:@"fromF256" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromF256Identifier

+(instancetype) fromChalkFloatIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"fromChalkFloat" caseSensitive:NO tokens:@[@"fromChalkFloat"] symbol:@"fromChalkFloat" symbolAsText:@"fromChalkFloat" symbolAsTeX:@"fromChalkFloat" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end fromChalkFloatIdentifier

+(instancetype) shiftIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"shift" caseSensitive:NO tokens:@[@"shift"] symbol:@"shift" symbolAsText:@"shift" symbolAsTeX:@"shift" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end shiftIdentifier

+(instancetype) rollIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"roll" caseSensitive:NO tokens:@[@"roll"] symbol:@"roll" symbolAsText:@"roll" symbolAsTeX:@"roll" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end rollIdentifier

+(instancetype) bitsSwapIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"swap" caseSensitive:NO tokens:@[@"swap"] symbol:@"swap" symbolAsText:@"swap" symbolAsTeX:@"swap" argsPossibleCount:NSMakeRange(2, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end bitsSwapIdentifier

+(instancetype) bitsReverseIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"bits_reverse" caseSensitive:NO tokens:@[@"bits_reverse"] symbol:@"\\textrm{bits_reverse}" symbolAsText:@"bits_reverse" symbolAsTeX:@"bits_reverse" argsPossibleCount:NSMakeRange(1, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end bitsReverseIdentifier

+(instancetype) bitsConcatLEIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"bits_concat_le" caseSensitive:NO tokens:@[@"bits_concat_le"] symbol:@"bits_concat_le" symbolAsText:@"bits_concat_le" symbolAsTeX:@"\\textrm{bits_concat_le}" argsPossibleCount:NSMakeRange(1, NSUIntegerMax-1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end bitsConcatLEIdentifier

+(instancetype) bitsConcatBEIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"bits_concat_be" caseSensitive:NO tokens:@[@"bits_concat_be"] symbol:@"bits_concat_le" symbolAsText:@"bits_concat_be" symbolAsTeX:@"\\textrm{bits_concat_be}" argsPossibleCount:NSMakeRange(1, NSUIntegerMax-1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end bitsConcatBEIdentifier

+(instancetype) golombRiceDecodeIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"golomb_rice_decode" caseSensitive:NO tokens:@[@"golomb_rice_decode"] symbol:@"golomb_rice_decode" symbolAsText:@"golomb_rice_decode" symbolAsTeX:@"\\textrm{golomb_rice_decode}" argsPossibleCount:NSMakeRange(1, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end golombRiceDecodeIdentifier

+(instancetype) golombRiceEncodeIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"golomb_rice_encode" caseSensitive:NO tokens:@[@"golomb_rice_encode"] symbol:@"golomb_rice_encode" symbolAsText:@"golomb_rice_encode" symbolAsTeX:@"\\textrm{golomb_rice_encode}" argsPossibleCount:NSMakeRange(1, 2)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end golombRiceEncodeIdentifier

+(instancetype) hConcatIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"hConcat" caseSensitive:NO tokens:@[@"hConcat"] symbol:@"hConcat" symbolAsText:@"hConcat" symbolAsTeX:@"\\textrm{hConcat}" argsPossibleCount:NSMakeRange(1, NSUIntegerMax-1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end hConcatIdentifier

+(instancetype) vConcatIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"vConcat" caseSensitive:NO tokens:@[@"vConcat"] symbol:@"vConcat" symbolAsText:@"vConcat" symbolAsTeX:@"\\textrm{vConcat}" argsPossibleCount:NSMakeRange(1, NSUIntegerMax-1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end vConcatIdentifier

+(instancetype) sumIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"sum" caseSensitive:NO tokens:@[@"sum"] symbol:@"sum" symbolAsText:@"sum" symbolAsTeX:@"\\sum_{%1@=%2@}^{%3@}{%0@}" argsPossibleCount:NSMakeRange(4, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sumIdentifier

+(instancetype) productIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"product" caseSensitive:NO tokens:@[@"product"] symbol:@"product" symbolAsText:@"product" symbolAsTeX:@"\\prod_{%1@=%2@}^{%3@}{%0@}" argsPossibleCount:NSMakeRange(4, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end productIdentifier

+(instancetype) integralIdentifier
{
  static CHChalkIdentifierFunction* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithName:@"integral" caseSensitive:NO tokens:@[@"integral"] symbol:@"integral" symbolAsText:@"integral" symbolAsTeX:@"\\int_{%2@}^{%3@}{%0@}.d{%1@}" argsPossibleCount:NSMakeRange(5, 1)];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end integralIdentifier

#pragma mark custom

-(instancetype) initWithName:(NSString*)aName caseSensitive:(BOOL)aCaseSensitive tokens:(NSArray*)aTokens symbol:(NSString*)aSymbol symbolAsText:(NSString*)aSymbolAsText symbolAsTeX:(NSString*)aSymbolAsTeX
{
  return [self initWithName:aName caseSensitive:aCaseSensitive tokens:aTokens symbol:aSymbol symbolAsText:aSymbolAsText symbolAsTeX:aSymbolAsTeX
          argsPossibleCount:NSMakeRange(1, 1)];
}

-(instancetype) initWithName:(NSString*)aName caseSensitive:(BOOL)aCaseSensitive tokens:(NSArray*)aTokens symbol:(NSString*)aSymbol symbolAsText:(NSString*)aSymbolAsText symbolAsTeX:(NSString*)aSymbolAsTeX argsPossibleCount:(NSRange)aArgsPossibleCount;
{
  if (!((self = [super initWithName:aName caseSensitive:aCaseSensitive tokens:aTokens symbol:aSymbol symbolAsText:aSymbolAsText symbolAsTeX:aSymbolAsTeX])))
    return nil;
  self->argsPossibleCount = aArgsPossibleCount;
  return self;
}
//end initWithName:caseSensitive:tokens:symbol:symbolAstext:symbolAsTeX:argsPossibleCount:

-(id) initWithCoder:(NSCoder*)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self)
  {
    self->argsPossibleCount = NSRangeFromString((NSString*)[aDecoder decodeObjectOfClass:[NSString class] forKey:@"argsPossibleCount"]);
    self->argumentNames = (NSArray*)[aDecoder decodeObjectOfClass:[NSArray class] forKey:@"argumentNames"];
    self->definition = (NSString*)[aDecoder decodeObjectOfClass:[NSString class] forKey:@"definition"];
  }//end if (self)
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:NSStringFromRange(self->argsPossibleCount) forKey:@"argsPossibleCount"];
  [aCoder encodeObject:self->argumentNames forKey:@"argumentNames"];
  [aCoder encodeObject:self->definition forKey:@"definition"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkIdentifierFunction* result = [super copyWithZone:zone];
  if (result)
  {
    result->argsPossibleCount = self->argsPossibleCount;
    [result->argumentNames release];
    result->argumentNames = [self->argumentNames copyWithZone:zone];
    [result->definition release];
    result->definition = [self->definition copyWithZone:zone];
  }//end if (result)
  return result;
}
//end copyWithZone:

-(NSString*) description
{
  return [self->tokens description];
}
//end description

@end
