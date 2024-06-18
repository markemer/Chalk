//
//  CHDigitsGroupView.m
//  Chalk
//
//  Created by Pierre Chatelier on 25/03/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHDigitsGroupView.h"

#import "CHDigitsGroupNavigatorView.h"
#import "CHDigitView.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"

@interface CHDigitsGroupView ()
-(void) customInit;
-(void) refreshPresentation;
-(NSUInteger) convertIndexToVisual:(NSUInteger)index;
-(NSUInteger) convertIndexFromVisual:(NSUInteger)index;
@end

@implementation CHDigitsGroupView

@synthesize navigatorView;
@synthesize delegate;
@synthesize digitsGroupIndex;

-(instancetype) initWithCoder:(NSCoder*)coder
{
  if (!((self = [super initWithCoder:coder])))
    return nil;
  [self customInit];
  return self;
}
//end initWithCoder:

-(instancetype) initWithFrame:(NSRect)frameRect
{
  if (!((self = [super initWithFrame:frameRect])))
    return nil;
  [self customInit];
  return self;
}
//end initWithCoder:

-(void) customInit
{
  self->rowsCount = 2;
  [self invalidatePresentation];
}
//end customInit

-(void) dealloc
{
  [self->digitViews release];
  [self->hintViews release];
  [super dealloc];
}
//end dealloc

-(void) invalidatePresentation
{
  self->presentationIsDirty = YES;
  if (!self->digitViews.count)
    [self refreshPresentation];
}
//end invalidatePresentation

-(void) setNavigatorView:(CHDigitsGroupNavigatorView*)value
{
  if (value != self->navigatorView)
  {
    self->navigatorView = value;
    [self invalidatePresentation];
  }//end if (value != self->navigatorView)
}
//end setNavigatorView:

-(void) setDigitsGroupIndex:(NSUInteger)value
{
  if (value != self->digitsGroupIndex)
  {
    self->digitsGroupIndex = value;
    [self updateControls];
  }//end if (value != self->digitsGroupIndex)
}
//end setDigitsGroupIndex:

-(NSUInteger) convertIndexToVisual:(NSUInteger)index
{
  NSUInteger result = 0;
  NSUInteger negativeBitsOffset = 0;
  NSUInteger bitsPerDigit = self->navigatorView.bitsPerDigit;
  NSUInteger indexInBits = index*bitsPerDigit;
  chalk_number_part_minor_type_t minorPartsVisible = self->navigatorView.minorPartsVisible;
  const chalk_bit_interpretation_t* inputBitInterpretation = self->navigatorView.inputBitInterpretation;
  NSUInteger minorPartsCount = getMinorPartOrderedCountForBitInterpretation(inputBitInterpretation);
  for(NSUInteger i = 0 ; (i<minorPartsCount) ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForBitInterpretation(inputBitInterpretation, i);
    NSRange minorPartBitsRange = getMinorPartBitsRangeForBitInterpretation(inputBitInterpretation, minorPart);
    BOOL isMinorPartVisible = ((minorPart & minorPartsVisible) != 0);
    if (!isMinorPartVisible)
    {
      if (indexInBits >= NSMaxRange(minorPartBitsRange))
        negativeBitsOffset += minorPartBitsRange.length;
    }//end if (!isMinorPartVisible)
  }//end for each minorPart
  NSUInteger negativeOffset = (negativeBitsOffset+bitsPerDigit-1)/bitsPerDigit;
  result = (index < negativeOffset) ? 0 : (index-negativeOffset);
  return result;
}
//end convertIndexToVisual:

-(NSUInteger) convertIndexFromVisual:(NSUInteger)index
{
  NSUInteger result = 0;
  NSUInteger bitsPerDigit = self->navigatorView.bitsPerDigit;
  NSUInteger indexInBits = index*bitsPerDigit;
  NSUInteger indexInBitsWithOffset = indexInBits;
  chalk_number_part_minor_type_t minorPartsVisible = self->navigatorView.minorPartsVisible;
  const chalk_bit_interpretation_t* inputBitInterpretation = self->navigatorView.inputBitInterpretation;
  NSUInteger minorPartsCount = getMinorPartOrderedCountForBitInterpretation(inputBitInterpretation);
  BOOL done = NO;
  for(NSUInteger i = 0 ; !done && (i<minorPartsCount) ; ++i)
  {
    chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForBitInterpretation(inputBitInterpretation, i);
    NSRange minorPartBitsRange = getMinorPartBitsRangeForBitInterpretation(inputBitInterpretation, minorPart);
    done |= (indexInBitsWithOffset < minorPartBitsRange.location);
    if (!done)
    {
      BOOL isMinorPartVisible = ((minorPart & minorPartsVisible) != 0);
      if (!isMinorPartVisible)
        indexInBitsWithOffset = (NSUIntegerMax-indexInBitsWithOffset < minorPartBitsRange.length) ? NSUIntegerMax : (indexInBitsWithOffset+minorPartBitsRange.length);
    }//end if (!done)
  }//end for each minorPart
  result = (indexInBitsWithOffset+bitsPerDigit-1)/bitsPerDigit;
  return result;
}
//end convertIndexFromVisual:

-(void) refreshPresentation
{
  NSInteger digitsOrder = self->navigatorView.digitsOrder;
  NSUInteger digitsGroupSize = self->navigatorView.digitsGroupSize;
  [self->digitViews release];
  self->digitViews = [[NSMutableArray alloc] initWithCapacity:digitsGroupSize];
  [self->hintViews release];
  self->hintViews = [[NSMutableArray alloc] initWithCapacity:digitsGroupSize];
  [[[self.subviews copy] autorelease] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [obj removeFromSuperview];
  }];
  NSUInteger nbCols = !self->rowsCount ? 0 : (digitsGroupSize+self->rowsCount-1)/self->rowsCount;
  NSUInteger colsGroupCount = 4;
  NSUInteger nbGroupsPerCol = MAX(1, (nbCols+colsGroupCount-1)/colsGroupCount);
  NSSize containerSize = self.bounds.size;
  NSSize itemSize = NSMakeSize(16, 20);
  CGFloat colGroupOffset = 8;
  CGFloat rowOffset = 16;
  NSSize itemsSize =
    NSMakeSize(
      itemSize.width*nbCols+(nbGroupsPerCol-1)*colGroupOffset,
      itemSize.height*self->rowsCount+(self->rowsCount-1)*rowOffset);
  NSSize margins = NSMakeSize((containerSize.width-itemsSize.width)/2, containerSize.height-itemsSize.height);
  NSUInteger index = 0;
  for(NSUInteger i = 0 ; i<self->rowsCount ; ++i)
  {
    CGFloat offset = 0;
    for(NSUInteger j = 0 ; (j<nbCols) && (index<digitsGroupSize) ; ++j, ++index)
    {
      if (j && !(j%colsGroupCount))
        offset += colGroupOffset;
      NSUInteger i2 = (digitsOrder == 0) ? i : (self->rowsCount-1-i);
      NSRect itemFrame = (digitsOrder == 0) ?
        NSMakeRect(margins.width+itemsSize.width-(j+1)*itemSize.width-offset,
                   margins.height+i2*itemSize.height+i2*rowOffset,
                   itemSize.width, itemSize.height) :
        NSMakeRect(margins.width+j*itemSize.width+offset,
                   margins.height+i2*itemSize.height+i2*rowOffset,
                   itemSize.width, itemSize.height);
      if (!j || !(j%8) || (j+1 == nbCols) || (index+1 == digitsGroupSize))
      {
        NSRect hintFrame = itemFrame;
        NSTextField* hintView = [[NSTextField alloc] initWithFrame:hintFrame];
        hintView.backgroundColor = [NSColor clearColor];
        hintView.bordered = NO;
        hintView.editable = NO;
        [hintView.cell setAlignment:NSCenterTextAlignment];
        [hintView.cell setControlSize:NSSmallControlSize];
        CGFloat fontSize = MIN(7, [NSFont systemFontSizeForControlSize:NSMiniControlSize]);
        NSFont* hintFont = [NSFont fontWithName:@"Helvetica" size:fontSize];
        [hintView.cell setFont:hintFont];
        hintView.stringValue = @(self->digitsGroupIndex*digitsGroupSize+index).stringValue;
        [hintView sizeToFit];
        hintFrame = hintView.frame;
        hintFrame.origin.x -= MAX(0, hintFrame.size.width-itemFrame.size.width);
        hintFrame.origin.y -= hintFrame.size.height;
        hintView.frame = hintFrame;
        hintView.tag = (NSInteger)index;
        [self->hintViews addObject:hintView];
        [self addSubview:hintView];
        [hintView release];
      }//end if (!j || !(j%16) || (j+1 == nbCols) || (index+1 == digitsGroupSize))
      CHDigitView* digitView = [[CHDigitView alloc] initWithFrame:itemFrame];
      digitView.enabled = NO;
      //[digitView.cell setAlignment:NSCenterTextAlignment];
      //digitView.font = [NSFont fontWithName:@"Helvetica" size:[NSFont systemFontSizeForControlSize:NSMiniControlSize]/2];
      digitView.stringValue = @"0";
      //digitView.alignment = NSCenterTextAlignment;
      digitView.clickDelegate = self;
      [self addSubview:digitView];
      [self->digitViews addObject:digitView];
      [digitView release];
    }//end for j
  }//end for i
  self->presentationIsDirty = NO;
  [self updateControls];
}
//end refreshPresentation

-(void) updateControls
{
  if (self->presentationIsDirty)
    [self refreshPresentation];
  NSUInteger digitsGroupSize = self->navigatorView.digitsGroupSize;
  NSUInteger bitsPerDigit = self->navigatorView.bitsPerDigit;
  const chalk_bit_interpretation_t* inputBitInterpretation = self->navigatorView.inputBitInterpretation;
  const chalk_bit_interpretation_t* outputBitInterpretation = self->navigatorView.outputBitInterpretation;
  const chalk_raw_value_t* inputRawValue = self->navigatorView.inputRawValue;
  chalk_raw_value_t* outputRawValue = self->navigatorView.outputRawValue;
  [self->digitViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHDigitView* digitView = obj;
    mp_bitcnt_t digitIndexVisual = self->digitsGroupIndex*digitsGroupSize+idx;
    mp_bitcnt_t digitIndexNatural = [self convertIndexFromVisual:digitIndexVisual];
    digitView.digitIndexNatural = digitIndexNatural;
    digitView.digitIndexVisual = digitIndexVisual;
    chalk_number_part_minor_type_t digitMinorPart1 = CHALK_NUMBER_PART_MINOR_UNDEFINED;
    for(NSUInteger i = 0 ; i<bitsPerDigit ; ++i)
      digitMinorPart1 |= getMinorPartForBit(digitIndexNatural*bitsPerDigit+i, inputBitInterpretation);
    chalk_number_part_minor_type_t digitMinorPart2 = CHALK_NUMBER_PART_MINOR_UNDEFINED;
    for(NSUInteger i = 0 ; i<bitsPerDigit ; ++i)
      digitMinorPart2 |= getMinorPartForBit(digitIndexNatural*bitsPerDigit+i, outputBitInterpretation);
    NSMutableArray* backColors1 = [NSMutableArray array];
    NSMutableArray* backColors2 = [NSMutableArray array];
    NSUInteger minorPartsCount1 = getMinorPartOrderedCountForBitInterpretation(inputBitInterpretation);
    for(NSUInteger i = 0 ; (i<minorPartsCount1) ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForBitInterpretation(inputBitInterpretation, i);
      if (digitMinorPart1 & minorPart)
      {
        NSColor* color =
          (minorPart == CHALK_NUMBER_PART_MINOR_SIGN) ? self->navigatorView.signColor1 :
          (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT) ? self->navigatorView.exponentColor1 :
          (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND) ? self->navigatorView.significandColor1 :
          [NSColor blackColor];
        [backColors1 insertObject:color atIndex:0];
      }//end if (digitMinorPart1 & minorPart)
    }//end for each minorPart
    NSUInteger minorPartsCount2 = getMinorPartOrderedCountForBitInterpretation(outputBitInterpretation);
    for(NSUInteger i = 0 ; (i<minorPartsCount2) ; ++i)
    {
      chalk_number_part_minor_type_t minorPart = getMinorPartOrderedForBitInterpretation(outputBitInterpretation, i);
      if (digitMinorPart2 & minorPart)
      {
        NSColor* color =
          (minorPart == CHALK_NUMBER_PART_MINOR_SIGN) ? self->navigatorView.signColor2 :
          (minorPart == CHALK_NUMBER_PART_MINOR_EXPONENT) ? self->navigatorView.exponentColor2 :
          (minorPart == CHALK_NUMBER_PART_MINOR_SIGNIFICAND) ? self->navigatorView.significandColor2 :
          [NSColor blackColor];
        [backColors2 insertObject:color atIndex:0];
      }//end if (digitMinorPart1 & minorPart)
    }//end for each minorPart
    if (!backColors1.count)
      [backColors1 addObject:[NSColor controlBackgroundColor]];
    if (!backColors2.count)
      [backColors2 addObject:[NSColor controlBackgroundColor]];
    digitView.backColors1 = backColors1;
    digitView.backColors2 = backColors2;

    NSString* digitString = nil;
    BOOL isDigitModified = NO;
    if (bitsPerDigit == 1)
    {
      BOOL digitValueOriginal = inputRawValue &&
       (inputRawValue->bitInterpretation.numberEncoding.encodingType != CHALK_NUMBER_ENCODING_UNDEFINED) &&
       (mpz_tstbit(inputRawValue->bits, digitIndexNatural) != 0);
      BOOL digitValueModified = outputRawValue &&
        (outputRawValue->bitInterpretation.numberEncoding.encodingType != CHALK_NUMBER_ENCODING_UNDEFINED) &&
        (mpz_tstbit(outputRawValue->bits, digitIndexNatural) != 0);
      isDigitModified = (digitValueOriginal != digitValueModified);
      digitString = digitValueModified ? @"1" : @"0";
    }//end if (bitsPerDigit == 1)
    else//if (bitsPerDigit > 1)
    {
      mpz_t inputDigitBits;
      mpz_t outputDigitBits;
      mpz_init_set_ui(inputDigitBits, 0);
      mpz_init_set_ui(outputDigitBits, 0);
      BOOL error = NO;
      if (inputRawValue)
        mpz_copyBits(inputDigitBits, 0, mpz_limbs_read(inputRawValue->bits), mpz_size(inputRawValue->bits), NSIntersectionRange(NSMakeRange(digitIndexNatural*bitsPerDigit, bitsPerDigit),
                              NSMakeRange(0, mpz_sizeinbase(inputRawValue->bits, 2))), &error);
      if (outputRawValue)
        mpz_copyBits(outputDigitBits, 0, mpz_limbs_read(outputRawValue->bits), mpz_size(outputRawValue->bits), NSIntersectionRange(NSMakeRange(digitIndexNatural*bitsPerDigit, bitsPerDigit),
                              NSMakeRange(0, mpz_sizeinbase(outputRawValue->bits, 2))), &error);
      digitString = chalkGmpGetCharacterAsLowercaseStringForBase(1<<bitsPerDigit, mpz_get_ui(outputDigitBits));
      isDigitModified = (mpz_cmp(inputDigitBits, outputDigitBits) != 0);
      mpz_clear(inputDigitBits);
      mpz_clear(outputDigitBits);
    }//end if (bitsPerDigit > 1)
    CGFloat fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
    digitView.textColor = [NSColor controlTextColor];
    digitView.stringValue = [digitString uppercaseString];
    digitView.font =
      isDigitModified ? [NSFont boldSystemFontOfSize:fontSize] :
      [NSFont systemFontOfSize:fontSize];
  }];//end or each bitView
  [self->hintViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSTextField* hintView = obj;
    hintView.stringValue = @(self->digitsGroupIndex*digitsGroupSize+(NSUInteger)hintView.tag).stringValue;
    NSRect oldHintFrame = hintView.frame;
    [hintView sizeToFit];
    NSRect newHintFrame = hintView.frame;
    newHintFrame.origin.x = oldHintFrame.origin.x+oldHintFrame.size.width-newHintFrame.size.width;
    newHintFrame.origin.y = oldHintFrame.origin.y+oldHintFrame.size.height-newHintFrame.size.height;
    hintView.frame = newHintFrame;
    hintView.textColor = [NSColor controlTextColor];
  }];//end for each hintView
}
//end updateControls

-(void) viewDidClick:(id)sender
{
  if (self.navigatorView.enabled)
  {
    CHDigitView* digitView = [sender dynamicCastToClass:[CHDigitView class]];
    NSUInteger digitIndexNatural = digitView.digitIndexNatural;
    BOOL digitCanBeModified = NSRangeContains(self->navigatorView.digitsRangeModifiable, digitIndexNatural);
    NSUInteger bitsPerDigit = self->navigatorView.bitsPerDigit;
    chalk_raw_value_t* outputRawValue = self->navigatorView.outputRawValue;
    if (outputRawValue && digitCanBeModified)
    {
      if (bitsPerDigit == 1)
        mpz_negbit(outputRawValue->bits, digitIndexNatural);
      else//if (bitsPerDigit != 1)
      {
        mpz_t tmp;
        mpz_init_set_ui(tmp, 0);
        BOOL error = NO;
        mpz_copyBits(tmp, 0, mpz_limbs_read(outputRawValue->bits), mpz_size(outputRawValue->bits),
                     NSIntersectionRange(NSMakeRange(digitIndexNatural*bitsPerDigit, bitsPerDigit),
                                         NSMakeRange(0, mpz_sizeinbase(outputRawValue->bits, 2))), &error);
        mpz_add_ui(tmp, tmp, 1);
        mpz_copyBits(outputRawValue->bits, digitIndexNatural*bitsPerDigit, mpz_limbs_read(tmp), mpz_size(tmp),
                     NSIntersectionRange(NSMakeRange(0, bitsPerDigit),
                                         NSMakeRange(0, mpz_sizeinbase(outputRawValue->bits, 2))), &error);
        mpz_clear(tmp);
      }//end if (bitsPerDigit != 1)
    }//end if (outputRawValue && digitCanBeModified)
    [self updateControls];
    if ([self.delegate respondsToSelector:@selector(outputRawValueDidChange:)])
      [self.delegate outputRawValueDidChange:self];
  }//end if (self.navigatorView.enabled)
}
//end viewDidClick:

@end
