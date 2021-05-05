//
//  CHBitInterpretationControl.m
//  Chalk
//
//  Created by Pierre Chatelier on 28/04/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHBitInterpretationControl.h"

#import "CHComputationConfiguration.h"
#import "CHNumberFormatter.h"
#import "CHPreferencesController.h"
#import "NSViewExtended.h"

NSString* CHBitInterpretationBinding = @"bitInterpretation";
NSString* CHBitInterpretationSignColorBinding = @"signColor";
NSString* CHBitInterpretationExponentColorBinding = @"exponentColor";
NSString* CHBitInterpretationSignificandColorBinding = @"significandColor";
static NSString* CHBitInterpretationMinorPartSelected = @"minorPartSelected";


@interface CHBitInterpretationControl ()

@property(nonatomic) chalk_number_part_minor_type_t minorPartSelected;
-(void) adaptToValueType;
-(void) adaptBitInterpretation;
-(void) updateControls;
-(void) userDefaultsDidChange:(NSNotification*)notification;
-(void) updateGuiForPreferences;
@end

@implementation CHBitInterpretationControl

@synthesize computationConfiguration;
@dynamic    bitInterpretation;
@synthesize signColor;
@synthesize exponentColor;
@synthesize significandColor;
@dynamic    isFixedBitInterpretation;

+(void) initialize
{
  [self exposeBinding:CHBitInterpretationBinding];
  [self exposeBinding:CHBitInterpretationSignColorBinding];
  [self exposeBinding:CHBitInterpretationExponentColorBinding];
  [self exposeBinding:CHBitInterpretationSignificandColorBinding];
}
//end initialize:

+(NSSet*) keyPathsForValuesAffectingSignColor {return [NSSet setWithArray:@[CHBitInterpretationMinorPartSelected]];}
+(NSSet*) keyPathsForValuesAffectingExponentColor {return [NSSet setWithArray:@[CHBitInterpretationMinorPartSelected]];}
+(NSSet*) keyPathsForValuesAffectingSignificandColor {return [NSSet setWithArray:@[CHBitInterpretationMinorPartSelected]];}

-(void) awakeFromNib
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  self->_bitsCountFormatter.positiveSuffix = [NSString stringWithFormat:@" %@", NSLocalizedString(@"bits", "")];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
  self->signColor = [preferencesController.bitInterpretationSignColor copy];
  self->exponentColor = [preferencesController.bitInterpretationExponentColor copy];
  self->significandColor = [preferencesController.bitInterpretationSignificandColor copy];
  self->_minorPartColorWellButton.delegate = self;
  [self updateGuiForPreferences];
  [self adaptToValueType];
}
//end awakeFromNib

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->computationConfiguration release];
  [self->signColor release];
  [self->exponentColor release];
  [self->significandColor release];
  [super dealloc];
}
//end dealloc

-(chalk_number_part_minor_type_t) minorPartSelected
{
  chalk_number_part_minor_type_t result = (chalk_number_part_minor_type_t)self->_bitsMinorPartPopUpButton.selectedTag;
  return result;
}
//end minorPartSelected

-(void) adaptBitInterpretation
{
  if (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM)
  {
    chalk_number_encoding_t equivalentGmpStandardEncoding = {
      CHALK_NUMBER_ENCODING_GMP_STANDARD,
      (chalk_number_encoding_gmp_standard_variant_t)self->bitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding};
    NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(equivalentGmpStandardEncoding);
    for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(equivalentGmpStandardEncoding, i);
      if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
        self->bitInterpretation.signCustomBitsCount = getSignBitsCountForEncoding(equivalentGmpStandardEncoding);
      else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
        self->bitInterpretation.exponentCustomBitsCount = getExponentBitsCountForEncoding(equivalentGmpStandardEncoding);
      else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
        self->bitInterpretation.significandCustomBitsCount =
          (equivalentGmpStandardEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z) ? self->computationConfiguration.softIntegerMaxBits :
          (equivalentGmpStandardEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR) ? self->computationConfiguration.softFloatSignificandBits :
          0;
    }//end for each minorPart
  }//end if (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM)
}
//end adaptBitInterpretation

-(void) adaptToValueType
{
  [self->_bitsEncodingPopUpButton removeAllItems];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"chalk integer", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_GMP_CUSTOM|(CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"chalk real", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_GMP_CUSTOM|(CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"IEEE 754 half (16)", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_IEEE754_STANDARD|(CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_HALF<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"IEEE 754 single (32)", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_IEEE754_STANDARD|(CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_SINGLE<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"IEEE 754 double (64)", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_IEEE754_STANDARD|(CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_DOUBLE<<32)];
  //[self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"IEEE 754 x86 extended precision (80)", @"")];
  //[self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_IEEE754_STANDARD|(CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_X86_EXTENDED_PRECISION<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"IEEE 754 quadruple (128)", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_IEEE754_STANDARD|(CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_QUADRUPLE<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"IEEE 754 octuple (256)", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_IEEE754_STANDARD|(CHALK_NUMBER_ENCODING_IEEE754_STANDARD_VARIANT_OCTUPLE<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"signed int8", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8S<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"unsigned int8", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_8U<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"signed int16", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16S<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"unsigned int16", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_16U<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"signed int32", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32S<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"unsigned int32", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_32U<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"signed int64", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64S<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"unsigned int64", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_64U<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"signed int128", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128S<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"unsigned int128", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_128U<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"signed int256", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256S<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"unsigned int256", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_STANDARD|(CHALK_NUMBER_ENCODING_INTEGER_STANDARD_VARIANT_256U<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"custom signed integer", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_CUSTOM|(CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED<<32)];
  [self->_bitsEncodingPopUpButton addItemWithTitle:NSLocalizedString(@"custom unsigned integer", @"")];
  [self->_bitsEncodingPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_ENCODING_INTEGER_CUSTOM|(CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED<<32)];
  [self->_bitsEncodingPopUpButton sizeToFit];
  [self->_bitsEncodingPopUpButton centerInParentHorizontally:NO vertically:YES];
  
  [self->_bitsMinorPartPopUpButton removeAllItems];
  [self->_bitsMinorPartPopUpButton addItemWithTitle:NSLocalizedString(@"sign", @"")];
  [self->_bitsMinorPartPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_PART_MINOR_SIGN];
  [self->_bitsMinorPartPopUpButton addItemWithTitle:NSLocalizedString(@"exponent", @"")];
  [self->_bitsMinorPartPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_PART_MINOR_EXPONENT];
  [self->_bitsMinorPartPopUpButton addItemWithTitle:NSLocalizedString(@"significand", @"")];
  [self->_bitsMinorPartPopUpButton.itemArray.lastObject setTag:CHALK_NUMBER_PART_MINOR_SIGNIFICAND];
  [self->_bitsMinorPartPopUpButton sizeToFit];
  [self->_bitsMinorPartPopUpButton centerInParentHorizontally:NO vertically:YES];
  [self->_bitsMinorPartPopUpButton selectItemWithTag:CHALK_NUMBER_PART_MINOR_SIGNIFICAND];

  [self->_bitsCountTextField centerInParentHorizontally:NO vertically:YES];
  [self->_bitsCountStepper centerInParentHorizontally:NO vertically:YES];
  
  [self->_bitsMinorPartPopUpButton setFrameOrigin:NSMakePoint(
    CGRectGetMaxX(NSRectToCGRect(self->_bitsEncodingPopUpButton.frame))+0,
    self->_bitsMinorPartPopUpButton.frame.origin.y)];

  [self->_bitsCountTextField setFrameOrigin:NSMakePoint(
    CGRectGetMaxX(NSRectToCGRect(self->_bitsMinorPartPopUpButton.frame))+0,
    self->_bitsCountTextField.frame.origin.y)];
  
  [self->_bitsCountStepper setFrameOrigin:NSMakePoint(
    CGRectGetMaxX(NSRectToCGRect(self->_bitsCountTextField.frame))-2,
    self->_bitsCountStepper.frame.origin.y)];

  [self->_minorPartColorWell setFrameOrigin:NSMakePoint(
    CGRectGetMaxX(NSRectToCGRect(self->_bitsCountStepper.frame))+2,
    self->_minorPartColorWell.frame.origin.y)];
  self->_minorPartColorWellButton.frame = self->_minorPartColorWell.frame;

  NSRect frame = self.view.frame;
  frame.size.width = CGRectGetMaxX(NSRectToCGRect(self->_minorPartColorWell.frame));
  self.view.frame = frame;
  
  chalk_bit_interpretation_t newBitInterpretation = self->bitInterpretation;
  if (newBitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED)
  {
    newBitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_GMP_CUSTOM;
    newBitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding =
      (self->valueType == CHALK_VALUE_TYPE_INTEGER) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z :
      (self->valueType == CHALK_VALUE_TYPE_FRACTION) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z :
      (self->valueType == CHALK_VALUE_TYPE_REAL_EXACT) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR :
      (self->valueType == CHALK_VALUE_TYPE_REAL_APPROX) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR :
      CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_UNDEFINED;
  }//end if (newBitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED)
  self->bitInterpretation = newBitInterpretation;
  [self adaptBitInterpretation];
  [self updateControls];
}
//end adaptToValueType

-(const chalk_bit_interpretation_t*) bitInterpretation
{
  return &self->bitInterpretation;
}
//end bitInterpretation

-(void) setBitInterpretation:(const chalk_bit_interpretation_t*)value
{
  if (value && !bitInterpretationEquals(value, &self->bitInterpretation))
  {
    [self willChangeValueForKey:CHBitInterpretationBinding];
    self->bitInterpretation = *value;
    [self adaptBitInterpretation];
    [self updateControls];
    [self didChangeValueForKey:CHBitInterpretationBinding];
  }//end if (value !bitInterpretationEquals(&value, &self->bitInterpretation))
}
//end setBitInterpretation:

-(void) setValueType:(chalk_value_gmp_type_t)aValueType computationConfiguration:(CHComputationConfiguration*)aComputationConfiguration
{
  memset(&self->fixedInterpretation, 0, sizeof(self->fixedInterpretation));
  if ((aValueType != self->valueType) || (aComputationConfiguration != self->computationConfiguration))
  {
    self->valueType = aValueType;
    [self->computationConfiguration release];
    self->computationConfiguration = [aComputationConfiguration copy];
    if (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_UNDEFINED)
      self->bitInterpretation.numberEncoding.encodingType = CHALK_NUMBER_ENCODING_GMP_CUSTOM;
    if (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_STANDARD)
      self->bitInterpretation.numberEncoding.encodingVariant.gmpStandardVariantEncoding =
        (self->valueType == CHALK_VALUE_TYPE_INTEGER) ? CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z :
        (self->valueType == CHALK_VALUE_TYPE_FRACTION) ? CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z :
        (self->valueType == CHALK_VALUE_TYPE_REAL_EXACT) ? CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR :
        (self->valueType == CHALK_VALUE_TYPE_REAL_APPROX) ? CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR :
        CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_UNDEFINED;
    if (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_GMP_CUSTOM)
      self->bitInterpretation.numberEncoding.encodingVariant.gmpCustomVariantEncoding =
        (self->valueType == CHALK_VALUE_TYPE_INTEGER) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z :
        (self->valueType == CHALK_VALUE_TYPE_FRACTION) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_Z :
        (self->valueType == CHALK_VALUE_TYPE_REAL_EXACT) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR :
        (self->valueType == CHALK_VALUE_TYPE_REAL_APPROX) ? CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_FR :
        CHALK_NUMBER_ENCODING_GMP_CUSTOM_VARIANT_UNDEFINED;
    if ((self->valueType == CHALK_VALUE_TYPE_FRACTION) &&
        (self->bitInterpretation.major == CHALK_NUMBER_PART_MAJOR_UNDEFINED))
      self->bitInterpretation.major = CHALK_NUMBER_PART_MAJOR_NUMERATOR;
    if ((self->valueType == CHALK_VALUE_TYPE_REAL_APPROX) &&
        (self->computationConfiguration.computeMode != CHALK_COMPUTE_MODE_APPROX_BEST) &&
        (self->bitInterpretation.major == CHALK_NUMBER_PART_MAJOR_UNDEFINED))
      self->bitInterpretation.major = CHALK_NUMBER_PART_MAJOR_BEST_VALUE;
    [self adaptToValueType];
  }//end if ((aValueType != self->valueType) || (aComputationConfiguration != self->computationConfiguration))
}
//end setBitInterpretation:

-(void) setFixedBitInterpretation:(const chalk_bit_interpretation_t*)aFixedInterpretation
{
  self->valueType = CHALK_VALUE_TYPE_UNDEFINED;
  if (aFixedInterpretation && (memcmp(&self->fixedInterpretation, aFixedInterpretation, sizeof(chalk_bit_interpretation_t)) != 0))
  {
    self->fixedInterpretation = *aFixedInterpretation;
    self->bitInterpretation = self->fixedInterpretation;
    [self adaptToValueType];
  }//end if (memcmp(&self->fixedInterpretation, &aFixedInterpretation, sizeof(chalk_bit_interpretation_t)) != 0)
}
//end setFixedBitInterpretation

-(BOOL) isFixedBitInterpretation
{
  BOOL result = (self->valueType == CHALK_VALUE_TYPE_UNDEFINED) &&
    (self->fixedInterpretation.numberEncoding.encodingType != CHALK_NUMBER_ENCODING_UNDEFINED);
  return result;
}
//end isFixedBitInterpretation

-(IBAction) changeColor:(id)sender
{
  [self changeParameter:sender];
}
//end changeColor:

-(IBAction) changeParameter:(id)sender
{
  if (sender == self->_bitsEncodingPopUpButton)
  {
    chalk_bit_interpretation_t newBitInterpretation = *self.bitInterpretation;
    NSInteger tag = self->_bitsEncodingPopUpButton.selectedTag;
    newBitInterpretation.numberEncoding.encodingType = (tag & 0xFFFFFFFFULL);
    newBitInterpretation.numberEncoding.encodingVariant.genericVariantEncoding = ((tag>>32ULL) & 0xFFFFFFFFULL);

    NSUInteger minorPartsOrdered = getMinorPartOrderedCountForEncoding(newBitInterpretation.numberEncoding);
    for(NSUInteger i = 0 ; i<minorPartsOrdered ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForEncoding(newBitInterpretation.numberEncoding, i);
      if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      {
        newBitInterpretation.signCustomBitsCount =
          getEncodingIsStandard(newBitInterpretation.numberEncoding) ? getSignBitsCountForEncoding(newBitInterpretation.numberEncoding) :
        newBitInterpretation.signCustomBitsCount;
        if (newBitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM)
          newBitInterpretation.signCustomBitsCount =
            (newBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED) ? 0 :
            (newBitInterpretation.numberEncoding.encodingVariant.integerCustomVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_SIGNED) ? MAX(1, newBitInterpretation.signCustomBitsCount) :
            newBitInterpretation.signCustomBitsCount;
      }//end if (minorPart == CHALK_NUMBER_PART_MINOR_SIGN)
      else if (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT)
        newBitInterpretation.exponentCustomBitsCount =
          getEncodingIsStandard(newBitInterpretation.numberEncoding) ? getExponentBitsCountForEncoding(newBitInterpretation.numberEncoding) :
          newBitInterpretation.exponentCustomBitsCount;
      else if (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
        newBitInterpretation.significandCustomBitsCount =
          getEncodingIsStandard(newBitInterpretation.numberEncoding) ? getSignificandBitsCountForEncoding(newBitInterpretation.numberEncoding, NO) :
          newBitInterpretation.significandCustomBitsCount;
    }//end for each minorPart
    self.bitInterpretation = &newBitInterpretation;
  }//end if (sender == self->_bitEncodingPopUpButton)
  else if (sender == self->_bitsMinorPartPopUpButton)
  {
    [self willChangeValueForKey:CHBitInterpretationMinorPartSelected];
    [self updateControls];
    [self didChangeValueForKey:CHBitInterpretationMinorPartSelected];
  }//end if (sender == self->_bitsMinorPartPopUpButton)
  else if ((sender == self->_bitsCountTextField) || (sender == self->_bitsCountStepper))
  {
    chalk_bit_interpretation_t newBitInterpretation = *self.bitInterpretation;
    NSInteger tag = self->_bitsMinorPartPopUpButton.selectedTag;
    mp_bitcnt_t* pBitsCount =
      (tag == CHALK_NUMBER_PART_MINOR_SIGN) ? &newBitInterpretation.signCustomBitsCount :
      (tag == CHALK_NUMBER_PART_MINOR_EXPONENT) ? &newBitInterpretation.exponentCustomBitsCount :
      (tag == CHALK_NUMBER_PART_MINOR_SIGNIFICAND) ? &newBitInterpretation.significandCustomBitsCount :
      0;
    if (pBitsCount)
      *pBitsCount =
        (sender == self->_bitsCountTextField) ? self->_bitsCountTextField.integerValue :
        (sender == self->_bitsCountStepper)   ? self->_bitsCountStepper.integerValue :
        *pBitsCount;
    self.bitInterpretation = &newBitInterpretation;
  }//end if ((sender == self->_bitsCountTextField) || (sender == self->_bitsCountStepper))
  else if ((sender == self->_minorPartColorWell) || (sender == self->_minorPartColorWellButton))
  {
    NSInteger tag = self->_bitsMinorPartPopUpButton.selectedTag;
    CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
    if (tag == CHALK_NUMBER_PART_MINOR_SIGN)
    {
      self.signColor = self->_minorPartColorWell.color;
      preferencesController.bitInterpretationSignColor = self.signColor;
    }//end if (tag == CHALK_NUMBER_PART_MINOR_SIGN)
    else if (tag == CHALK_NUMBER_PART_MINOR_EXPONENT)
    {
      self.exponentColor = self->_minorPartColorWell.color;
      preferencesController.bitInterpretationExponentColor = self.exponentColor;
    }//end if (tag == CHALK_NUMBER_PART_MINOR_EXPONENT)
    else if (tag == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
    {
      self.significandColor = self->_minorPartColorWell.color;
      preferencesController.bitInterpretationSignificandColor = self.significandColor;
    }//end if (tag == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
  }//end if ((sender == self->_minorPartColorWell) || (sender == self->_minorPartColorWellButton))
}
//end changeParameter:

-(void) updateControls
{
  BOOL hasNumber = (self->valueType != CHALK_VALUE_TYPE_UNDEFINED);
  BOOL isFixedInterpretation = self.isFixedBitInterpretation;
  NSArray* numberPartMinorItemsSelect = nil;
  NSArray* numberPartMinorItemsSS = @[
        @{NSTitleBinding:NSLocalizedString(@"sign", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGN)},
        @{NSTitleBinding:NSLocalizedString(@"significand", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGNIFICAND)}
      ];
  NSArray* numberPartMinorItemsSES = @[
        @{NSTitleBinding:NSLocalizedString(@"sign", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGN)},
        @{NSTitleBinding:NSLocalizedString(@"exponent", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_EXPONENT)},
        @{NSTitleBinding:NSLocalizedString(@"significand", @""), NSTagBinding:@(CHALK_NUMBER_PART_MINOR_SIGNIFICAND)}
      ];

  switch(self->bitInterpretation.numberEncoding.encodingType)
  {
    case CHALK_NUMBER_ENCODING_GMP_STANDARD:
    case CHALK_NUMBER_ENCODING_GMP_CUSTOM:
      numberPartMinorItemsSelect =
        (self->bitInterpretation.numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_FR) ?
          numberPartMinorItemsSES :
        (self->bitInterpretation.numberEncoding.encodingVariant.gmpStandardVariantEncoding == CHALK_NUMBER_ENCODING_GMP_STANDARD_VARIANT_Z) ?
          numberPartMinorItemsSS :
        nil;
      break;
    case CHALK_NUMBER_ENCODING_IEEE754_STANDARD:
      numberPartMinorItemsSelect = numberPartMinorItemsSES;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_STANDARD:
      numberPartMinorItemsSelect = numberPartMinorItemsSS;
      break;
    case CHALK_NUMBER_ENCODING_INTEGER_CUSTOM:
      numberPartMinorItemsSelect = numberPartMinorItemsSS;
      break;
    case CHALK_NUMBER_ENCODING_UNDEFINED:
      break;
  }//end switch(self.bitInterpretation.numberEncoding.encodingType)
  
  self->_bitsEncodingPopUpButton.enabled = hasNumber;
  [self->_bitsEncodingPopUpButton selectItemWithTag:
    (self->bitInterpretation.numberEncoding.encodingType & 0xFFFFFFFFULL) |
    ((self->bitInterpretation.numberEncoding.encodingVariant.genericVariantEncoding & 0xFFFFFFFFULL) << 32ULL)];
  
  NSUInteger tag = self->_bitsMinorPartPopUpButton.selectedTag;
  self->_bitsMinorPartPopUpButton.enabled =
    isFixedInterpretation ||
    (hasNumber && (numberPartMinorItemsSelect.count != 0));
  [self->_bitsMinorPartPopUpButton removeAllItems];
  for(NSDictionary* dict in numberPartMinorItemsSelect)
  {
    NSString* title = dict[NSTitleBinding];
    NSNumber* tag = dict[NSTagBinding];
    [self->_bitsMinorPartPopUpButton addItemWithTitle:title];
    [[[self->_bitsMinorPartPopUpButton itemArray] lastObject] setTag:tag.integerValue];
  }//end for each numberPartMinorItemsSelect
  if ((chalk_number_part_minor_type_t)self->_bitsMinorPartPopUpButton.selectedTag == CHALK_NUMBER_PART_MINOR_UNDEFINED)
    [self->_bitsMinorPartPopUpButton selectItemWithTag:(NSInteger)CHALK_NUMBER_PART_MINOR_SIGNIFICAND];
  else
    [self->_bitsMinorPartPopUpButton selectItemWithTag:tag];

  NSUInteger bitsCount = getMinorPartBitsCountForBitInterpretation(&self->bitInterpretation, tag);
  self->_bitsCountTextField.objectValue = @(bitsCount);
  self->_bitsCountStepper.objectValue = @(bitsCount);
  if (tag == CHALK_NUMBER_PART_MINOR_SIGN)
    self->_minorPartColorWell.color = self->signColor;
  else if (tag == CHALK_NUMBER_PART_MINOR_EXPONENT)
    self->_minorPartColorWell.color = self->exponentColor;
  else if (tag == CHALK_NUMBER_PART_MINOR_SIGNIFICAND)
    self->_minorPartColorWell.color = self->significandColor;

  self->_bitsCountTextField.enabled =
    hasNumber && !getEncodingIsStandard(self->bitInterpretation.numberEncoding) &&
    (self->bitInterpretation.numberEncoding.encodingType != CHALK_NUMBER_ENCODING_GMP_CUSTOM) &&
    !((tag == CHALK_NUMBER_PART_MINOR_SIGN) && (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM) && (self->bitInterpretation.numberEncoding.encodingVariant. integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED)) &&
    !((tag == CHALK_NUMBER_PART_MINOR_EXPONENT) && (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM));
  self->_bitsCountStepper.enabled =
    hasNumber && !getEncodingIsStandard(self->bitInterpretation.numberEncoding) &&
    (self->bitInterpretation.numberEncoding.encodingType != CHALK_NUMBER_ENCODING_GMP_CUSTOM) &&
    !((tag == CHALK_NUMBER_PART_MINOR_SIGN) && (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM) && (self->bitInterpretation.numberEncoding.encodingVariant. integerStandardVariantEncoding == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM_VARIANT_UNSIGNED)) &&
    !((tag == CHALK_NUMBER_PART_MINOR_EXPONENT) && (self->bitInterpretation.numberEncoding.encodingType == CHALK_NUMBER_ENCODING_INTEGER_CUSTOM));
  self->_minorPartColorWellButton.enabled = hasNumber && ((chalk_number_part_minor_type_t)self->_bitsMinorPartPopUpButton.selectedTag != CHALK_NUMBER_PART_MINOR_UNDEFINED);
  self->_minorPartColorWell.enabled = hasNumber && ((chalk_number_part_minor_type_t)self->_bitsMinorPartPopUpButton.selectedTag != CHALK_NUMBER_PART_MINOR_UNDEFINED);
}
//end updateControls

-(void) userDefaultsDidChange:(NSNotification*)notification
{
  [self updateGuiForPreferences];
}
//end userDefaultsDidChange:

-(void) updateGuiForPreferences
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  self.signColor = preferencesController.bitInterpretationSignColor;
  self.exponentColor = preferencesController.bitInterpretationExponentColor;
  self.significandColor = preferencesController.bitInterpretationSignificandColor;
}
//end updateGuiForPreferences

@end
