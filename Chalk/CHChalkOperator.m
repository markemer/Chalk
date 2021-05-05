//
//  CHChalkOperator.m
//  Chalk
//
//  Created by Pierre Chatelier on 08/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkOperator.h"

@implementation CHChalkOperator

@synthesize operatorIdentifier;
@synthesize operatorPosition;
@synthesize symbol;
@synthesize symbolAsText;
@synthesize symbolAsTeX;

+(instancetype) plusOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_PLUS operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"+" symbolAsText:@"+" symbolAsTeX:@"+"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end plusOperator

+(instancetype) plus2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_PLUS2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"+?" symbolAsText:@"+?" symbolAsTeX:@"+?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end plusOperator

+(instancetype) minusOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_MINUS operatorPosition:CHALK_OPERATOR_POSITION_INFIX|CHALK_OPERATOR_POSITION_PREFIX
                                                      symbol:@"-" symbolAsText:@"-" symbolAsTeX:@"-"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end minusOperator

+(instancetype) minus2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_MINUS2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                      symbol:@"-?" symbolAsText:@"-?" symbolAsTeX:@"-?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end minus2Operator

+(instancetype) timesOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_TIMES operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"*" symbolAsText:@"*" symbolAsTeX:@"\\times{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end timesOperator

+(instancetype) times2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_TIMES2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"*?" symbolAsText:@"*?" symbolAsTeX:@"\\times{}?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end times2Operator

+(instancetype) divideOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_DIVIDE operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"/" symbolAsText:@"/" symbolAsTeX:@"\\frac{%@}{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end divideOperator

+(instancetype) divide2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_DIVIDE2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"/?" symbolAsText:@"/?" symbolAsTeX:@"/?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end divide2Operator

+(instancetype) powOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_POW operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"^" symbolAsText:@"^" symbolAsTeX:@"{%@}^{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end powOperator

+(instancetype) pow2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_POW2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"^?" symbolAsText:@"^?" symbolAsTeX:@"{%@}^{?{%@}}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end pow2Operator

+(instancetype) sqrtOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_SQRT operatorPosition:CHALK_OPERATOR_POSITION_PREFIX
                                                     symbol:@"\u221A" symbolAsText:@"\u221A" symbolAsTeX:@"\\sqrt{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sqrtOperator

+(instancetype) sqrt2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_SQRT2 operatorPosition:CHALK_OPERATOR_POSITION_PREFIX
                                                     symbol:@"\u221A?" symbolAsText:@"\u221A?" symbolAsTeX:@"\\sqrt{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sqrt2Operator

+(instancetype) cbrtOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_CBRT operatorPosition:CHALK_OPERATOR_POSITION_PREFIX
                                                     symbol:@"\u221B" symbolAsText:@"\u221B" symbolAsTeX:@"\\sqrt[3]{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end cbrtOperator

+(instancetype) cbrt2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_CBRT2 operatorPosition:CHALK_OPERATOR_POSITION_PREFIX
                                                     symbol:@"\u221B?" symbolAsText:@"\u221B?" symbolAsTeX:@"\\sqrt[3]{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end cbrt2Operator

+(instancetype) mulSqrtOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_MUL_SQRT operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"\u221A" symbolAsText:@"\u221A" symbolAsTeX:@"{%@}\\sqrt{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end mulSqrtOperator

+(instancetype) mulSqrt2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_MUL_SQRT2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"\u221A?" symbolAsText:@"\u221A?" symbolAsTeX:@"{%@}\\sqrt{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end mulSqrt2Operator

+(instancetype) mulCbrtOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_MUL_CBRT operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"\u221B" symbolAsText:@"\u221B" symbolAsTeX:@"{%@}\\sqrt[3]{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end mulCbrtOperator

+(instancetype) mulCbrt2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_MUL_CBRT2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"\u221B?" symbolAsText:@"\u221B?" symbolAsTeX:@"{%@}\\sqrt[3]{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end mulCbrt2Operator

+(instancetype) degreeOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_DEGREE operatorPosition:CHALK_OPERATOR_POSITION_POSTFIX
                                                     symbol:@"°" symbolAsText:@"°" symbolAsTeX:@"°"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end degreeOperator

+(instancetype) degree2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_DEGREE2 operatorPosition:CHALK_OPERATOR_POSITION_POSTFIX
                                                     symbol:@"°?" symbolAsText:@"°?" symbolAsTeX:@"°?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end degree2Operator

+(instancetype) factorialOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_FACTORIAL operatorPosition:CHALK_OPERATOR_POSITION_POSTFIX
                                                     symbol:@"!" symbolAsText:@"!" symbolAsTeX:@"!"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end factorialOperator

+(instancetype) factorial2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_FACTORIAL2 operatorPosition:CHALK_OPERATOR_POSITION_POSTFIX
                                                     symbol:@"!?" symbolAsText:@"!?" symbolAsTeX:@"!?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end factorial2Operator

+(instancetype) uncertaintyOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_UNCERTAINTY operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:NSSTRING_PLUSMINUS symbolAsText:NSSTRING_PLUSMINUS symbolAsTeX:@"{%@}\\pm{%@}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end uncertaintyOperator

+(instancetype) absOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_ABS operatorPosition:CHALK_OPERATOR_POSITION_PREFIX|CHALK_OPERATOR_POSITION_POSTFIX
                                                     symbol:@"|" symbolAsText:@"|" symbolAsTeX:@"|"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end absOperator

+(instancetype) notOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_NOT operatorPosition:CHALK_OPERATOR_POSITION_PREFIX
                                                     symbol:@"~" symbolAsText:@"~" symbolAsTeX:@"\\sim{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end notOperator

+(instancetype) not2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_NOT2 operatorPosition:CHALK_OPERATOR_POSITION_PREFIX
                                                     symbol:@"~?" symbolAsText:@"~?" symbolAsTeX:@"\\sim{}?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end not2Operator

+(instancetype) geqOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_GEQ operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@">=" symbolAsText:@">=" symbolAsTeX:@"\\geq{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end geqOperator

+(instancetype) geq2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_GEQ2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@">=?" symbolAsText:@">=?" symbolAsTeX:@"\\geq{}?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end geq2Operator

+(instancetype) leqOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_LEQ operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"<=" symbolAsText:@"<=" symbolAsTeX:@"\\leq{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end leqOperator

+(instancetype) leq2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_LEQ2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"<=?" symbolAsText:@"<=?" symbolAsTeX:@"\\leq{}?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end leq2Operator

+(instancetype) greOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_GRE operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@">" symbolAsText:@">" symbolAsTeX:@">"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end greOperator

+(instancetype) gre2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_GRE2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@">?" symbolAsText:@">?" symbolAsTeX:@">?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end gre3Operator

+(instancetype) lowOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_LOW operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"<" symbolAsText:@"<" symbolAsTeX:@"<"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end lowOperator

+(instancetype) low2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_LOW2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"<?" symbolAsText:@"<?" symbolAsTeX:@"<?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end low2Operator

+(instancetype) equOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_EQU operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"==" symbolAsText:@"==" symbolAsTeX:@"=="];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end equOperator

+(instancetype) equ2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_EQU2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"==?" symbolAsText:@"==?" symbolAsTeX:@"==?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end equ2Operator

+(instancetype) neqOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_NEQ operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"!=" symbolAsText:@"!=" symbolAsTeX:@"\\neq{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end neqOperator

+(instancetype) neq2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_NEQ2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"!=?" symbolAsText:@"!=?" symbolAsTeX:@"\\neq{}?"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end neq2Operator

+(instancetype) andOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_AND operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"AND" symbolAsText:@"AND" symbolAsTeX:@"~\\textrm{AND}~"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end andOperator

+(instancetype) and2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_AND2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"AND?" symbolAsText:@"AND?" symbolAsTeX:@"~\\textrm{AND?}~"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end and2Operator

+(instancetype) orOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_OR operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"OR" symbolAsText:@"OR" symbolAsTeX:@"~\\textrm{OR}~"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end orOperator

+(instancetype) or2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_OR2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"OR?" symbolAsText:@"OR?" symbolAsTeX:@"~\\textrm{OR?}~"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end or2Operator

+(instancetype) xorOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_XOR operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"XOR" symbolAsText:@"XOR" symbolAsTeX:@"~\\textrm{XOR}~"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end xorOperator

+(instancetype) xor2Operator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_XOR2 operatorPosition:CHALK_OPERATOR_POSITION_INFIX
                                                     symbol:@"XOR?" symbolAsText:@"XOR?" symbolAsTeX:@"~\\textrm{XOR?}~"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end xor2Operator

+(instancetype) subscriptOperator
{
  static CHChalkOperator* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[self class] alloc] initWithIdentifier:CHALK_OPERATOR_SUBSCRIPT operatorPosition:CHALK_OPERATOR_POSITION_POSTFIX
                                                     symbol:@"%@%@" symbolAsText:@"%@%@" symbolAsTeX:@"%@%@"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end subscriptOperator

#pragma mark custom

-(instancetype) initWithIdentifier:(chalk_operator_t)aOperatorIdentifier operatorPosition:(chalk_operator_position_t)aOperatorPosition
                            symbol:(NSString*)aSymbol symbolAsText:(NSString*)aSymbolAsText symbolAsTeX:(NSString*)aSymbolAsTeX
{
  if (!((self = [super init])))
    return nil;
  self->operatorIdentifier = aOperatorIdentifier;
  self->operatorPosition = aOperatorPosition;
  self->symbol = [aSymbol copy];
  self->symbolAsText = [aSymbolAsText copy];
  self->symbolAsTeX = [aSymbolAsTeX copy];
  return self;
}
//end initWithName:caseSensitive:tokens:symbol:symbolAstext:symbolAsTeX:

-(void) dealloc
{
  [self->symbol release];
  [self->symbolAsText release];
  [self->symbolAsTeX release];
  [super dealloc];
}//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkOperator* result = [[[self class] allocWithZone:zone] init];
  if (result)
  {
    result->operatorIdentifier = self->operatorIdentifier;
    result->operatorPosition = self->operatorPosition;
    result.symbol = self.symbol;
    result.symbolAsText = self.symbolAsText;
    result.symbolAsTeX = self.symbolAsTeX;
  }//end if (result)
  return result;
}
//end copyWithZone:

@end
