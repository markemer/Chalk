//
//  CHPreferencesController.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/07/13.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHPreferencesController.h"

#import "CHChalkUtils.h"
#import "CHComputationConfiguration.h"
#import "CHPresentationConfiguration.h"
#import "NSColorExtended.h"
#import "NSFontExtended.h"
#import "NSObjectExtended.h"
#import "NSUserDefaultsControllerExtended.h"
#import "NSUserDefaultsExtended.h"

NSString* CHSoftIntegerMaxBitsKey                      = @"CHSoftIntegerMaxBits";
NSString* CHSoftIntegerMaxBitsDigitsBaseKey            = @"CHSoftIntegerMaxBitsDigitsBase";
NSString* CHSoftIntegerDenominatorMaxBitsKey           = @"CHSoftIntegerDenominatorMaxBits";
NSString* CHSoftIntegerDenominatorMaxBitsDigitsBaseKey = @"CHSoftIntegerDenominatorMaxBitsDigitsBase";
NSString* CHSoftFloatSignificandBitsKey                = @"CHSoftFloatSignificandBits";
NSString* CHSoftFloatSignificandBitsDigitsBaseKey      = @"CHSoftFloatSignificandBitsDigitsBase";
NSString* CHSoftFloatDisplayBitsKey                    = @"CHSoftFloatDisplayBits";
NSString* CHSoftFloatDisplayBitsDigitsBaseKey          = @"CHSoftFloatDisplayBitsDigitsBase";
NSString* CHSoftMaxExponentKey                         = @"CHSoftMaxExponent";
NSString* CHSoftMaxPrettyPrintNegativeExponentKey      = @"CHSoftMaxPrettyPrintNegativeExponent";
NSString* CHSoftMaxPrettyPrintPositiveExponentKey      = @"CHSoftMaxPrettyPrintPositiveExponent";
NSString* CHComputeModeKey                             = @"CHComputeMode";
NSString* CHComputeBaseKey                             = @"CHComputeBase";
NSString* CHPropagateNaNKey                            = @"CHPropagateNaN";
NSString* CHBaseUseLowercaseKey                        = @"CHBaseUseLowercase";
NSString* CHBaseUseDecimalExponentKey                  = @"CHBaseUseDecimalExponent";
NSString* CHBaseBaseKey                                = @"CHBaseBase";
NSString* CHBasePrefixesKey                            = @"CHBasePrefixes";
NSString* CHBaseSuffixesKey                            = @"CHBaseSuffixes";
NSString* CHBasePrefixesSuffixesKey                    = @"CHBasePrefixesSuffixes";
NSString* CHIntegerGroupSizeKey                        = @"CHIntegerGroupSize";
NSString* CHParseModeKey                               = @"parseMode";
NSString* CHBitInterpretationSignColorKey              = @"bitInterpretationSignColor";
NSString* CHBitInterpretationSignColorDarkModeKey      = @"bitInterpretationSignColorDarkMode";
NSString* CHBitInterpretationExponentColorKey          = @"bitInterpretationExponentColor";
NSString* CHBitInterpretationExponentColorDarkModeKey  = @"bitInterpretationExponentColorDarkMode";
NSString* CHBitInterpretationSignificandColorKey       = @"bitInterpretationSignificandColor";
NSString* CHBitInterpretationSignificandColorDarkModeKey = @"bitInterpretationSignificandColorDarkMode";
NSString* CHExportInputColorKey                        = @"exportInputColor";
NSString* CHExportOutputColorKey                       = @"exportOutputColor";
NSString* CHNextInputModeKey                           = @"nextInputMode";

static NSString* CHLastEasterEggsDatesKey = @"chlee_opaque_DatesKey";

@implementation CHPreferencesController

@synthesize  exportFormatCurrentSession;

@dynamic computationConfigurationDefault;
@dynamic computationConfigurationCurrent;
@dynamic presentationConfigurationDefault;
@dynamic presentationConfigurationCurrent;

@dynamic softIntegerMaxBits;
@dynamic softIntegerMaxBitsDigitsBase;
@dynamic softIntegerDenominatorMaxBits;
@dynamic softIntegerDenominatorMaxBitsDigitsBase;
@dynamic softFloatSignificandBits;
@dynamic softFloatSignificandBitsDigitsBase;
@dynamic softFloatDisplayBits;
@dynamic softFloatDisplayBitsDigitsBase;
@dynamic softMaxExponent;
@dynamic softMaxPrettyPrintNegativeExponent;
@dynamic softMaxPrettyPrintPositiveExponent;
@dynamic computeMode;
@dynamic computeBase;
@dynamic propagateNaN;
@dynamic baseUseLowercase;
@dynamic baseUseDecimalExponent;
@dynamic basePrefixesSuffixesController;
@dynamic integerGroupSize;
@dynamic parseMode;
@dynamic bitInterpretationSignColor;
@dynamic bitInterpretationExponentColor;
@dynamic bitInterpretationSignificandColor;
@dynamic exportInputColor;
@dynamic exportOutputColor;
@dynamic nextInputMode;

@dynamic shouldEasterEgg;

+(CHPreferencesController*) sharedPreferencesController
{
  static CHPreferencesController* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      instance = [[CHPreferencesController alloc] init];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sharedPreferencesController

static NSUInteger CHSoftIntegerMaxBits_default = 256;
static NSUInteger CHSoftIntegerMaxBitsDigitsBase_default = 10;
static NSUInteger CHSoftIntegerDenominatorMaxBits_default = 256;
static NSUInteger CHSoftIntegerDenominatorMaxBitsDigits_default = 10;
static NSUInteger CHSoftFloatSignificandBits_default = 128;
static NSUInteger CHSoftFloatSignificandBitsDigitsBase_default = 10;
static NSUInteger CHSoftFloatDisplayBits_default = 53;
static NSUInteger CHSoftFloatDisplayBitsDigitsBase_default = 10;
static NSUInteger CHSoftMaxPrettyPrintNegativeExponent_default = 4;
static NSUInteger CHSoftMaxPrettyPrintPositiveExponent_default = 6;
static chalk_compute_mode_t CHComputeMode_default = CHALK_COMPUTE_MODE_EXACT;
static BOOL CHPropagateNaN_default = YES;
static int CHComputeBase_default = 10;
static BOOL CHBaseUseLowercase_default = NO;
static BOOL CHBaseUseDecimalExponent_default = NO;
static NSInteger CHIntegerGroupSize_default = 0;
static chalk_parse_mode_t CHParseMode_default = CHALK_PARSE_MODE_INFIX;
static chalk_nextinput_mode_t CHNextInputMode_default = CHALK_NEXTINPUT_MODE_FUNCTION_OUTPUT;

+(NSDictionary*) defaults
{
  NSDictionary* result = nil;
  NSMutableDictionary* basePrefixesSuffixes = [NSMutableDictionary dictionary];
  for(NSInteger i = GMP_BASE_MIN ; i<=GMP_BASE_MAX ; ++i)
    [basePrefixesSuffixes setObject:@{CHBaseBaseKey:@(i), CHBasePrefixesKey:@"", CHBaseSuffixesKey:@[]} forKey:@(i)];
  [basePrefixesSuffixes setObject:@{CHBaseBaseKey:@(2), CHBasePrefixesKey:@[@"0b",@"0B"], CHBaseSuffixesKey:@[]} forKey:@(2)];
  [basePrefixesSuffixes setObject:@{CHBaseBaseKey:@(8), CHBasePrefixesKey:@[@"0o",@"0O"],  CHBaseSuffixesKey:@[]} forKey:@(8)];
  [basePrefixesSuffixes setObject:@{CHBaseBaseKey:@(16), CHBasePrefixesKey:@[@"0x",@"0X"], CHBaseSuffixesKey:@[]} forKey:@(16)];
  result =
    @{
      CHSoftIntegerMaxBitsKey:@(CHSoftIntegerMaxBits_default),
      CHSoftIntegerMaxBitsDigitsBaseKey:@(CHSoftIntegerMaxBitsDigitsBase_default),
      CHSoftIntegerDenominatorMaxBitsKey:@(CHSoftIntegerDenominatorMaxBits_default),
      CHSoftIntegerDenominatorMaxBitsDigitsBaseKey:@(CHSoftIntegerDenominatorMaxBitsDigits_default),
      CHSoftFloatSignificandBitsKey:@(CHSoftFloatSignificandBits_default),
      CHSoftFloatSignificandBitsDigitsBaseKey:@(CHSoftFloatSignificandBitsDigitsBase_default),
      CHSoftFloatDisplayBitsKey:@(CHSoftFloatDisplayBits_default),
      CHSoftFloatDisplayBitsDigitsBaseKey:@(CHSoftFloatDisplayBitsDigitsBase_default),
      CHSoftMaxExponentKey:@(mpfr_get_emax()),
      CHSoftMaxPrettyPrintNegativeExponentKey:@(CHSoftMaxPrettyPrintNegativeExponent_default),
      CHSoftMaxPrettyPrintPositiveExponentKey:@(CHSoftMaxPrettyPrintPositiveExponent_default),
      CHComputeModeKey:@(CHComputeMode_default),
      CHComputeBaseKey:@(CHComputeBase_default),
      CHPropagateNaNKey:@(CHPropagateNaN_default),
      CHBaseUseLowercaseKey:@(CHBaseUseLowercase_default),
      CHBaseUseDecimalExponentKey:@(CHBaseUseDecimalExponent_default),
      CHBasePrefixesSuffixesKey:[[basePrefixesSuffixes allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:CHBaseBaseKey ascending:YES]]],
      CHIntegerGroupSizeKey:@(CHIntegerGroupSize_default),
      CHParseModeKey:@(CHParseMode_default),
      CHBitInterpretationSignColorKey:[[NSColor colorWithCalibratedRed:255/255. green:255/255. blue:196/255. alpha:1.] colorAsData],
      CHBitInterpretationSignColorDarkModeKey:[[NSColor colorWithCalibratedRed:128/255. green:128/255. blue:98/255. alpha:1.] colorAsData],
      CHBitInterpretationExponentColorKey:[[NSColor colorWithCalibratedRed:196/255. green:255/255. blue:255/255. alpha:1.] colorAsData],
      CHBitInterpretationExponentColorDarkModeKey:[[NSColor colorWithCalibratedRed:98/255. green:128/255. blue:128/255. alpha:1.] colorAsData],
      CHBitInterpretationSignificandColorKey:[[NSColor colorWithCalibratedRed:255/255. green:196/255. blue:255/255. alpha:1.] colorAsData],
      CHBitInterpretationSignificandColorDarkModeKey:[[NSColor colorWithCalibratedRed:128/255. green:98/255. blue:128/255. alpha:1.] colorAsData],
      CHExportInputColorKey:[[NSColor blackColor] colorAsData],
      CHExportOutputColorKey:[[NSColor blackColor] colorAsData],
      CHNextInputModeKey:@(CHNextInputMode_default)
    };
  return result;
}
//end defaults

-(id) init
{
  if (!(self = [super init]))
    return nil;
  [[NSUserDefaults standardUserDefaults] registerDefaults:[[self class] defaults]];
  return self;
}
//end init

-(void) dealloc
{
  [self->basePrefixesSuffixesController release];
  [super dealloc];
}
//end dealloc

-(NSDictionary*) defaults
{
  NSDictionary* result = [[self class] defaults];
  return result;
}
//end defaults

-(CHComputationConfiguration*) computationConfigurationDefault
{
  CHComputationConfiguration* result = [[[CHComputationConfiguration alloc] init] autorelease];
  result.softIntegerMaxBits = CHSoftIntegerMaxBits_default;
  result.softIntegerDenominatorMaxBits = CHSoftIntegerDenominatorMaxBits_default;
  result.softFloatSignificandBits = CHSoftFloatSignificandBits_default;
  result.softMaxExponent = mpfr_get_emax();
  result.computeMode = CHComputeMode_default;
  result.propagateNaN = CHPropagateNaN_default;
  result.baseDefault = CHComputeBase_default;
  return result;
}
//end computationConfigurationDefault

-(CHComputationConfiguration*) computationConfigurationCurrent
{
  CHComputationConfiguration* result = [[[CHComputationConfiguration alloc] init] autorelease];
  result.softIntegerMaxBits = self.softIntegerMaxBits;
  result.softIntegerDenominatorMaxBits = self.softIntegerDenominatorMaxBits;
  result.softFloatSignificandBits = self.softFloatSignificandBits;
  result.softMaxExponent = self.softMaxExponent;
  result.computeMode = self.computeMode;
  result.propagateNaN = self.propagateNaN;
  result.baseDefault = self.computeBase;
  return result;
}
//end computationConfigurationCurrent

-(void) setComputationConfigurationCurrent:(CHComputationConfiguration*)value
{
  value = !value ? self.computationConfigurationDefault : [[value copy] autorelease];
  self.softIntegerMaxBits = value.softIntegerMaxBits;
  self.softIntegerDenominatorMaxBits = value.softIntegerDenominatorMaxBits;
  self.softFloatSignificandBits = value.softFloatSignificandBits;
  self.softMaxExponent = value.softMaxExponent;
  self.computeMode = value.computeMode;
  self.propagateNaN = value.propagateNaN;
  self.computeBase = value.baseDefault;
}
//end computationConfigurationCurrent

-(CHPresentationConfiguration*) presentationConfigurationDefault
{
  CHPresentationConfiguration* result = [[[CHPresentationConfiguration alloc] init] autorelease];
  result.softFloatDisplayBits = CHSoftFloatDisplayBits_default;
  result.softMaxPrettyPrintNegativeExponent = CHSoftMaxPrettyPrintNegativeExponent_default;
  result.softMaxPrettyPrintPositiveExponent = CHSoftMaxPrettyPrintPositiveExponent_default;
  result.base = CHComputeBase_default;
  result.baseUseLowercase = CHBaseUseLowercase_default;
  result.baseUseDecimalExponent = CHBaseUseDecimalExponent_default;
  result.integerGroupSize = CHIntegerGroupSize_default;
  result.description = CHALK_VALUE_DESCRIPTION_STRING;
  result.printOptions = CHALK_VALUE_PRINT_OPTION_NONE;
  return result;
}
//end presentationConfigurationDefault

-(CHPresentationConfiguration*) presentationConfigurationCurrent
{
  CHPresentationConfiguration* result = [[[CHPresentationConfiguration alloc] init] autorelease];
  result.softFloatDisplayBits = self.softFloatDisplayBits;
  result.softMaxPrettyPrintNegativeExponent = self.softMaxPrettyPrintNegativeExponent;
  result.softMaxPrettyPrintPositiveExponent = self.softMaxPrettyPrintPositiveExponent;
  result.base = self.computeBase;
  result.baseUseLowercase = self.baseUseLowercase;
  result.baseUseDecimalExponent = self.baseUseDecimalExponent;
  result.integerGroupSize = self.integerGroupSize;
  result.description = CHALK_VALUE_DESCRIPTION_STRING;
  result.printOptions = CHALK_VALUE_PRINT_OPTION_NONE;
  return result;
}
//end presentationConfigurationCurrent

-(void) setPresentationConfigurationCurrent:(CHPresentationConfiguration*)value
{
  value = !value ? self.presentationConfigurationDefault : [[value copy] autorelease];
  self.softFloatDisplayBits = value.softFloatDisplayBits;
  self.softMaxPrettyPrintNegativeExponent = value.softMaxPrettyPrintNegativeExponent;
  self.softMaxPrettyPrintPositiveExponent = value.softMaxPrettyPrintPositiveExponent;
  self.computeBase = value.base;
  self.baseUseLowercase = value.baseUseLowercase;
  self.baseUseDecimalExponent = value.baseUseDecimalExponent;
  self.integerGroupSize = value.integerGroupSize;
}
//end setPresentationConfigurationCurrent:

-(NSUInteger) softIntegerMaxBits
{
  NSUInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftIntegerMaxBitsKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result = MAX(2U, result);
  return result;
}
//end softIntegerMaxBits

-(void) setSoftIntegerMaxBits:(NSUInteger)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  value = MAX(2U, value);
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHSoftIntegerMaxBitsKey];
  self.softIntegerDenominatorMaxBits = MIN(self.softIntegerMaxBits, self.softIntegerDenominatorMaxBits);
}
//end setSoftIntegerMaxBits:

-(int) softIntegerMaxBitsDigitsBase
{
  int result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftIntegerMaxBitsDigitsBaseKey] dynamicCastToClass:[NSNumber class]] intValue];
  result = chalkGmpBaseMakeValid(result);
  return result;
}
//end softIntegerMaxBitsDigitsBase

-(void) setSoftIntegerMaxBitsDigitsBase:(int)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  value = chalkGmpBaseMakeValid(value);
  [userDefaults setObject:[NSNumber numberWithInteger:value] forKey:CHSoftIntegerMaxBitsDigitsBaseKey];
}
//end setSoftIntegerMaxBitsDigitsBase:

-(NSUInteger) softIntegerDenominatorMaxBits
{
  NSUInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftIntegerDenominatorMaxBitsKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result = MAX(2U, result);
  return result;
}
//end softIntegerDenominatorMaxBits

-(void) setSoftIntegerDenominatorMaxBits:(NSUInteger)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  value = MAX(2U, value);
  value = MIN(value, self.softIntegerMaxBits);
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHSoftIntegerDenominatorMaxBitsKey];
}
//end setSoftIntegerDenominatorMaxBits:

-(int) softIntegerDenominatorMaxBitsDigitsBase
{
  int result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftIntegerDenominatorMaxBitsDigitsBaseKey] dynamicCastToClass:[NSNumber class]] intValue];
  result = chalkGmpBaseMakeValid(result);
  return result;
}
//end softIntegerDenominatorMaxBitsDigitsBase

-(void) setSoftIntegerDenominatorMaxBitsDigitsBase:(int)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  value = chalkGmpBaseMakeValid(value);
  [userDefaults setObject:[NSNumber numberWithInteger:value] forKey:CHSoftIntegerDenominatorMaxBitsDigitsBaseKey];
}
//end setSoftIntegerDenominatorMaxBitsDigitsBase:

-(NSUInteger) softFloatSignificandBits
{
  NSUInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftFloatSignificandBitsKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result = MAX(2U, result);
  return result;
}
//end softFloatSignificandBits

-(void) setSoftFloatSignificandBits:(NSUInteger)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  value = MAX(2U, value);
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHSoftFloatSignificandBitsKey];
  self.softFloatDisplayBits = MIN(self.softFloatDisplayBits, self.softFloatSignificandBits);
}
//end setSoftFloatSignificandBits:

-(int) softFloatSignificandBitsDigitsBase
{
  int result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftFloatSignificandBitsDigitsBaseKey] dynamicCastToClass:[NSNumber class]] intValue];
  result = chalkGmpBaseMakeValid(result);
  return result;
}
//end softFloatSignificandBitsDigitsBase

-(void) setSoftFloatSignificandBitsDigitsBase:(int)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  value = chalkGmpBaseMakeValid(value);
  [userDefaults setObject:[NSNumber numberWithInteger:value] forKey:CHSoftFloatSignificandBitsDigitsBaseKey];
}
//end setSoftFloatSignificandBitsDigitsBase:

-(NSUInteger) softFloatDisplayBits
{
  NSUInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftFloatDisplayBitsKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  result = MAX(2U, result);
  return result;
}
//end softFloatDisplayBits

-(void) setSoftFloatDisplayBits:(NSUInteger)value
{
  value = MAX(2U, value);
  value = MIN(value, self.softFloatSignificandBits);
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHSoftFloatDisplayBitsKey];
}
//end setSoftFloatDisplayBits:

-(int) softFloatDisplayBitsDigitsBase
{
  int result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftFloatDisplayBitsDigitsBaseKey] dynamicCastToClass:[NSNumber class]] intValue];
  result = chalkGmpBaseMakeValid(result);
  return result;
}
//end softFloatDisplayBitsDigitsBase

-(void) setSoftDisplayMaxBitsDigitsBase:(int)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  value = chalkGmpBaseMakeValid(value);
  [userDefaults setObject:[NSNumber numberWithInteger:value] forKey:CHSoftFloatDisplayBitsDigitsBaseKey];
}
//end setSoftDisplayMaxBitsDigitsBase:

-(NSUInteger) softMaxExponent
{
  NSUInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftMaxExponentKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end softMaxExponent

-(void) setSoftMaxExponent:(NSUInteger)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHSoftMaxExponentKey];
}
//end setSoftMaxExponent:

-(NSUInteger) softMaxPrettyPrintNegativeExponent
{
  NSUInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftMaxPrettyPrintNegativeExponentKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end softMaxPrettyPrintNegativeExponent

-(void) setSoftMaxPrettyPrintNegativeExponent:(NSUInteger)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHSoftMaxPrettyPrintNegativeExponentKey];
}
//end setSoftMaxPrettyPrintNegativeExponent:

-(NSUInteger) softMaxPrettyPrintPositiveExponent
{
  NSUInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHSoftMaxPrettyPrintPositiveExponentKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end softMaxPrettyPrintPositiveExponent

-(void) setSoftMaxPrettyPrintPositiveExponent:(NSUInteger)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHSoftMaxPrettyPrintPositiveExponentKey];
}
//end setSoftMaxPrettyPrintPositiveExponent:

-(chalk_compute_mode_t) computeMode
{
  chalk_compute_mode_t result = CHALK_COMPUTE_MODE_UNDEFINED;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = (chalk_compute_mode_t)[[[userDefaults objectForKey:CHComputeModeKey] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  return result;
}
//end computeMode

-(void) setComputeMode:(chalk_compute_mode_t)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithUnsignedInteger:value] forKey:CHComputeModeKey];
}
//end setComputeMode:

-(int) computeBase
{
  int result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHComputeBaseKey] dynamicCastToClass:[NSNumber class]] intValue];
  return result;
}
//end computeBase

-(void) setComputeBase:(int)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithInt:value] forKey:CHComputeBaseKey];
}
//end setComputeBase:

-(BOOL) propagateNaN
{
  BOOL result = NO;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHPropagateNaNKey] dynamicCastToClass:[NSNumber class]] boolValue];
  return result;
}
//end propagateNaN

-(void) setPropagateNaN:(BOOL)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithBool:value] forKey:CHPropagateNaNKey];
}
//end setPropagateNaN:

-(BOOL) baseUseLowercase
{
  BOOL result = NO;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHBaseUseLowercaseKey] dynamicCastToClass:[NSNumber class]] boolValue];
  return result;
}
//end baseUseLowercase

-(void) setBaseUseLowercase:(BOOL)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithBool:value] forKey:CHBaseUseLowercaseKey];
}
//end setBaseUseLowercase:

-(BOOL) baseUseDecimalExponent
{
  BOOL result = NO;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHBaseUseDecimalExponentKey] dynamicCastToClass:[NSNumber class]] boolValue];
  return result;
}
//end baseUseDecimalExponent

-(void) setBaseUseDecimalExponent:(BOOL)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithBool:value] forKey:CHBaseUseDecimalExponentKey];
}
//end setBaseUseDecimalExponent:

-(NSArray*) basePrefixesSuffixes
{
  NSArray* result = nil;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[userDefaults objectForKey:CHBasePrefixesSuffixesKey] dynamicCastToClass:[NSArray class]];
  return result;
}
//end basePrefixesSuffixes

-(void) setBasePrefixesSuffixes:(NSArray*)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:value forKey:CHBasePrefixesSuffixesKey];
}
//end setBasePrefixesSuffixes:

-(NSArrayController*) basePrefixesSuffixesController
{
  NSArrayController* result = [self lazyBasePrefixesSuffixesControllerControllerWithCreationIfNeeded:YES];
  return result;
}
//end basePrefixesSuffixesController

-(NSArrayController*) lazyBasePrefixesSuffixesControllerControllerWithCreationIfNeeded:(BOOL)creationOptionIfNeeded
{
  NSArrayController* result = self->basePrefixesSuffixesController;
  if (!self->basePrefixesSuffixesController && creationOptionIfNeeded)
  {
    self->basePrefixesSuffixesController = [[NSArrayController alloc] initWithContent:nil];
    [self->basePrefixesSuffixesController bind:NSContentArrayBinding toObject:[NSUserDefaultsController sharedUserDefaultsController]
      withKeyPath:[NSUserDefaultsController adaptedKeyPath:CHBasePrefixesSuffixesKey]
          options:@{NSHandlesContentAsCompoundValueBindingOption:@YES}];
    [self->basePrefixesSuffixesController setAutomaticallyPreparesContent:NO];
    [self->basePrefixesSuffixesController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:CHBaseBaseKey ascending:YES]]];
    result = self->basePrefixesSuffixesController;
  }//end if (!self->basePrefixesSuffixesController && creationOptionIfNeeded)
  return result;
}
//end lazyBasePrefixesSuffixesControllerControllerWithCreationIfNeeded:

-(NSInteger) integerGroupSize
{
  NSInteger result = 0;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [[[userDefaults objectForKey:CHIntegerGroupSizeKey] dynamicCastToClass:[NSNumber class]] integerValue];
  return result;
}
//end integerGroupSize

-(void) setIntegerGroupSize:(NSInteger)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithInteger:value] forKey:CHIntegerGroupSizeKey];
}
//end setIntegerGroupSize:

-(chalk_parse_mode_t) parseMode
{
  chalk_parse_mode_t result = CHALK_PARSE_MODE_UNDEFINED;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSUInteger value = [userDefaults unsignedIntegerForKey:CHParseModeKey];
  switch((chalk_parse_mode_t)value)
  {
    case CHALK_PARSE_MODE_INFIX:
    case CHALK_PARSE_MODE_RPN:
      result = (chalk_parse_mode_t)value;
      break;
    default:
      result = CHALK_PARSE_MODE_INFIX;
      break;
  }//end switch()
  return result;
}
//end parseMode

-(void) setParseMode:(chalk_parse_mode_t)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setUnsignedInteger:(NSUInteger)value forKey:CHParseModeKey];
}
//end setParseMode:

-(NSColor*) bitInterpretationSignColor
{
  NSColor* result = nil;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSString* key = [NSApp isDarkMode] ? CHBitInterpretationSignColorDarkModeKey : CHBitInterpretationSignColorKey;
  result = [NSColor colorWithData:[[userDefaults dataForKey:key] dynamicCastToClass:[NSData class]]];
  return result;
}
//end bitInterpretationSignColor

-(void) setBitInterpretationSignColor:(NSColor*)bitInterpretationSignColor
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSString* key = [NSApp isDarkMode] ? CHBitInterpretationSignColorDarkModeKey : CHBitInterpretationSignColorKey;
  [userDefaults setObject:[bitInterpretationSignColor colorAsData] forKey:key];
}
//end setBitInterpretationSignColor:

-(NSColor*) bitInterpretationExponentColor
{
  NSColor* result = nil;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSString* key = [NSApp isDarkMode] ? CHBitInterpretationExponentColorDarkModeKey : CHBitInterpretationExponentColorKey;
  result = [NSColor colorWithData:[[userDefaults dataForKey:key] dynamicCastToClass:[NSData class]]];
  return result;
}
//end bitInterpretationExponentColor

-(void) setBitInterpretationExponentColor:(NSColor*)bitInterpretationExponentColor
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSString* key = [NSApp isDarkMode] ? CHBitInterpretationExponentColorDarkModeKey : CHBitInterpretationExponentColorKey;
  [userDefaults setObject:[bitInterpretationExponentColor colorAsData] forKey:key];
}
//end setBitInterpretationExponentColor:

-(NSColor*) bitInterpretationSignificandColor
{
  NSColor* result = nil;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSString* key = [NSApp isDarkMode] ? CHBitInterpretationSignificandColorDarkModeKey : CHBitInterpretationSignificandColorKey;
  result = [NSColor colorWithData:[[userDefaults dataForKey:key] dynamicCastToClass:[NSData class]]];
  return result;
}
//end bitInterpretationSignificandColor

-(void) setBitInterpretationSignificandColor:(NSColor*)bitInterpretationSignificandColor
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSString* key = [NSApp isDarkMode] ? CHBitInterpretationSignificandColorDarkModeKey : CHBitInterpretationSignificandColorKey;
  [userDefaults setObject:[bitInterpretationSignificandColor colorAsData] forKey:key];
}
//end setBitInterpretationSignificandColor:

-(NSColor*) exportInputColor
{
  NSColor* result = nil;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [NSColor colorWithData:[[userDefaults dataForKey:CHExportInputColorKey] dynamicCastToClass:[NSData class]]];
  return result;
}
//end exportInputColor

-(void) setExportInputColor:(NSColor*)exportInputColor
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[exportInputColor colorAsData] forKey:CHExportInputColorKey];
}
//end setExportInputColor:

-(NSColor*) exportOutputColor
{
  NSColor* result = nil;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  result = [NSColor colorWithData:[[userDefaults dataForKey:CHExportOutputColorKey] dynamicCastToClass:[NSData class]]];
  return result;
}
//end exportOutputColor

-(void) setExportOutputColor:(NSColor*)exportOutputColor
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[exportOutputColor colorAsData] forKey:CHExportOutputColorKey];
}
//end setExportOutputColor:

-(chalk_nextinput_mode_t) nextInputMode
{
  chalk_nextinput_mode_t result = CHALK_NEXTINPUT_MODE_UNDEFINED;
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSUInteger value = [userDefaults unsignedIntegerForKey:CHNextInputModeKey];
  switch((chalk_nextinput_mode_t)value)
  {
    case CHALK_NEXTINPUT_MODE_BLANK:
    case CHALK_NEXTINPUT_MODE_PREVIOUS_INPUT:
    case CHALK_NEXTINPUT_MODE_FUNCTION_OUTPUT:
    case CHALK_NEXTINPUT_MODE_FUNCTION_OUTPUT_SMART:
      result = (chalk_nextinput_mode_t)value;
      break;
    default:
      result = CHALK_NEXTINPUT_MODE_BLANK;
      break;
  }//end switch()
  return result;
}
//end nextInputMode

-(void) setNextInputMode:(chalk_nextinput_mode_t)value
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setUnsignedInteger:(NSUInteger)value forKey:CHNextInputModeKey];
}
//end setNextInputMode:

-(BOOL) shouldEasterEgg
{
  BOOL result = NO;
  @synchronized(self)
  {
    NSCalendarDate* now = [NSCalendarDate date];
    NSCalendarDate* date1stApril = [[[NSCalendarDate alloc] initWithYear:now.yearOfCommonEra month:4 day:1 hour:0 minute:0 second:0 timeZone:nil] autorelease];
    BOOL forceEasterEggForDebugging = NO;
    if (forceEasterEggForDebugging)
      date1stApril = now;
    BOOL isEasterEggDate =
      (now.monthOfYear == date1stApril.monthOfYear) && (now.dayOfMonth == date1stApril.dayOfMonth);
    if (isEasterEggDate)
    {
      NSString* easterEggStringKey = @"1stApril";
      NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
      NSData* dataFromUserDefaults = [userDefaults dataForKey:CHLastEasterEggsDatesKey];
      NSMutableDictionary* easterEggLastDates = dataFromUserDefaults ?
        [NSMutableDictionary dictionaryWithDictionary:[NSUnarchiver unarchiveObjectWithData:dataFromUserDefaults]] :
        [NSMutableDictionary dictionary];
      if (!easterEggLastDates)
        easterEggLastDates = [NSMutableDictionary dictionary];
      NSCalendarDate* easterEggLastDate = [easterEggLastDates objectForKey:easterEggStringKey];
      if ((!easterEggLastDate) || [now isLessThan:easterEggLastDate] ||
          ([now yearOfCommonEra] != [easterEggLastDate yearOfCommonEra]))
      {
        [easterEggLastDates setObject:[NSCalendarDate date] forKey:easterEggStringKey];
        result = YES;
      }
      [userDefaults setObject:[NSArchiver archivedDataWithRootObject:easterEggLastDates] forKey:CHLastEasterEggsDatesKey];
    }//end if (isEasterEggDate)
  }//end @synchronized(self)
  return result;
}
//end shouldEasterEgg

@end
