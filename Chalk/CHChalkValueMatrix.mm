//
//  CHChalkValueMatrix.m
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueMatrix.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkValueIndexRange.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueSubscript.h"
#import "CHComputationConfiguration.h"
#import "CHGmpPool.h"
#import "CHParserFunctionNode.h"
#import "CHParserOperatorNode.h"
#import "CHPresentationConfiguration.h"
#import "CHStreamWrapper.h"
#import "CHUtils.h"
#import "NSArrayExtended.h"
#import "NSCoderExtended.h"
#import "NSObjectExtended.h"

#include <vector>

class MatrixIndices
{
  public:
    MatrixIndices(NSUInteger nbRows, NSUInteger nbCols)
                 :nbRows(nbRows),nbCols(nbCols)
    {
      dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      this->indices.resize(this->nbRows);
      dispatch_apply_gmp(this->nbRows, queue, ^(size_t rowIndex) {
        __block std::vector<NSUInteger>& row = this->indices[rowIndex];
        row.resize(this->nbCols);
        dispatch_applyWithOptions_gmp(this->nbCols, queue, DISPATCH_OPTION_SYNCHRONOUS, ^(size_t colIndex) {
          row[colIndex] = rowIndex*this->nbCols+colIndex;
        });
      });
    }//end MatrixIndices()
  public:
    NSUInteger getIndex(NSUInteger row, NSUInteger col) const {return this->indices[row][col];}
  public:
    void swapRows(NSUInteger row1, NSUInteger row2) {
      if (row1 != row2)
        this->indices[row1].swap(this->indices[row2]);
    }//end swapRows()
    void swapCols(NSUInteger col1, NSUInteger col2) {
      if (col1 != col2)
      {
        dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_applyWithOptions_gmp(this->nbRows, queue, DISPATCH_OPTION_SYNCHRONOUS, ^(size_t rowIndex) {
          std::vector<NSUInteger>& row = this->indices[rowIndex];
          std::swap(row[col1], row[col2]);
        });
      }//end if (col1 != col2)
    }//end swapCols()
    void removeRow(NSUInteger row) {
      this->indices.erase(this->indices.begin()+row);
      --this->nbRows;
    }//end removeRow()
    void removeCol(NSUInteger col) {
        dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_applyWithOptions_gmp(this->nbRows, queue, DISPATCH_OPTION_SYNCHRONOUS, ^(size_t rowIndex) {
          std::vector<NSUInteger>& row = this->indices[rowIndex];
          row.erase(row.begin()+col);
        });
        --this->nbCols;
    }//end removeCol()
  public:
    NSUInteger getNbRows(void) const {return this->nbRows;}
    NSUInteger getNbCols(void) const {return this->nbCols;}
  private:
    NSUInteger nbRows;
    NSUInteger nbCols;
    std::vector<std::vector<NSUInteger> > indices;
};
//end class MatrixIndices

void printMatrix(NSArray* values, NSUInteger rowsCount, NSUInteger colsCount, const MatrixIndices* indices, NSRange rowRange, NSRange colRange,
                 CHChalkContext* context)
{
  if (values && indices)
  {
    CHStreamWrapper* stream = [[CHStreamWrapper alloc] init];
    stream.stringStream = [NSMutableString string];
    [stream writeString:@"("];
    for(NSUInteger row = rowRange.location ; row<rowRange.location+rowRange.length ; ++row)
    {
      [stream writeString:@"("];
      for(NSUInteger col = colRange.location ; col<colRange.location+colRange.length ; ++col)
      {
        if (col != colRange.location)
          [stream writeString:@","];
        NSUInteger index = !indices ? row*colsCount+col : indices->getIndex(row, col);
        [[values objectAtIndex:index] writeToStream:stream context:context presentationConfiguration:nil];
      }//end for each col
      [stream writeString:@")"];
    }//end for each row
    [stream writeString:@")"];
    [stream release];
  }//end if (values && indices)
}
//end printMatrix()

CHChalkValue* getMaxMagnitudeColElement(NSArray* values, NSUInteger rowsCount, NSUInteger colsCount,
                                        const MatrixIndices* indices, NSRange rowRange, NSRange colRange,
                                        NSUInteger* outRow, NSUInteger* outCol)
{
  CHChalkValue* result = nil;
  NSUInteger resultRow = 0;
  NSUInteger resultCol = 0;
  if (values && rowsCount && colsCount && rowRange.length && colRange.length)
  {
    __block CHChalkValueNumberGmp* globalMaxElement = nil;
    __block NSUInteger globalMaxElementRowIndex = 0;
    __block NSUInteger globalMaxElementColIndex = 0;
    dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply_gmp(rowRange.length, queue, ^(size_t _row) {
      NSUInteger rowIndex = rowRange.location+_row;
      CHChalkValueNumberGmp* localMaxElement = nil;
      NSUInteger localMaxElementRowIndex = 0;
      NSUInteger localMaxElementColIndex = 0;
      if (colRange.length == 1)
      {
        NSUInteger index = indices ? indices->getIndex(rowIndex, colRange.location) : rowIndex*colsCount+colRange.location;
        CHChalkValue* value = [values objectAtIndex:index];
        CHChalkValueScalar* valueScalar = [value dynamicCastToClass:[CHChalkValueScalar class]];
        CHChalkValue* absValue = !valueScalar ? nil :
          [CHParserFunctionNode combineAbs:@[valueScalar] token:nil context:nil];
        CHChalkValueNumberGmp* absValueGmp = [absValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
        localMaxElement = [absValueGmp retain];
        localMaxElementRowIndex = rowIndex;
        localMaxElementColIndex = colRange.location;
      }//end if (colRange.length == 1)
      else//if (colRange.length > 1)
      {
        for(NSUInteger colIndex = colRange.location ; colIndex<colRange.location+colRange.length ; ++colIndex)
        {
          @autoreleasepool {
            NSUInteger index = indices ? indices->getIndex(rowIndex, colIndex) : rowIndex*colsCount+colIndex;
            CHChalkValue* value = [values objectAtIndex:index];
            CHChalkValueScalar* valueScalar = [value dynamicCastToClass:[CHChalkValueScalar class]];
            CHChalkValue* absValue = !valueScalar ? nil :
              [CHParserFunctionNode combineAbs:@[valueScalar] token:nil context:nil];
            CHChalkValueNumberGmp* absValueGmp = [absValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            const chalk_gmp_value_t* absValueGmpValue = absValueGmp.valueConstReference;
            const chalk_gmp_value_t* localMaxElementGmpValue = localMaxElement.valueConstReference;
            int cmp = !localMaxElementGmpValue ? 0 : chalkGmpValueCmp(localMaxElementGmpValue, absValueGmpValue, [CHGmpPool peek]);
            BOOL updateMax = (!localMaxElementGmpValue || (cmp<0) ||
                ((cmp == 0) && (rowIndex<localMaxElementRowIndex)) ||
                ((cmp == 0) && (rowIndex==localMaxElementRowIndex) && (colIndex<localMaxElementColIndex)));
            if (updateMax)
            {
              localMaxElementRowIndex = rowIndex;
              localMaxElementColIndex = colIndex;
              [localMaxElement release];
              localMaxElement = [absValueGmp retain];
            }//end if (updateMax)
          }//end @autoreleasepool
        }//end for each col
      }//end if (colRange.length > 1)
      @synchronized(values)
      {
        const chalk_gmp_value_t* localMaxElementGmpValue = localMaxElement.valueConstReference;
        const chalk_gmp_value_t* globalMaxElementGmpValue = globalMaxElement.valueConstReference;
        int cmp = !globalMaxElementGmpValue ? 0 : chalkGmpValueCmp(globalMaxElementGmpValue, localMaxElementGmpValue, [CHGmpPool peek]);
        BOOL updateMax = (!globalMaxElementGmpValue || (cmp<0) ||
            ((cmp == 0) && (localMaxElementRowIndex<globalMaxElementRowIndex)) ||
            ((cmp == 0) && (localMaxElementRowIndex==globalMaxElementRowIndex) && (localMaxElementColIndex<globalMaxElementColIndex)));
        if (updateMax)
        {
          globalMaxElementRowIndex = localMaxElementRowIndex;
          globalMaxElementColIndex = localMaxElementColIndex;
          [globalMaxElement release];
          globalMaxElement = [localMaxElement retain];
        }//end if (updateMax)
      }//end @synchronized(values)
      [localMaxElement release];
    });//end for each row
    [globalMaxElement release];
    resultRow = globalMaxElementRowIndex;
    resultCol = globalMaxElementColIndex;
    NSUInteger index = indices ? indices->getIndex(resultRow, resultCol) : resultRow*colsCount+resultCol;
    result = [values objectAtIndex:index];
  }//end if (values && rowsCount && colsCount && rowRange.length && colRange.length)
  if (outRow)
    *outRow = resultRow;
  if (outCol)
    *outCol = resultCol;
  return result;
}
//end getMaxMagnitudeColElement()

CHChalkValue* getMaxMagnitudeElement(NSArray* values, const MatrixIndices* indices, NSUInteger* outRowIndex, NSUInteger* outColIndex, BOOL bottomLeftSearch)
{
  CHChalkValue* result = nil;
  NSUInteger resultRowIndex = 0;
  NSUInteger resultColIndex = 0;
  if (indices && indices->getNbRows() && indices->getNbCols())
  {
    __block CHChalkValueNumberGmp* globalMaxElement = nil;
    __block NSUInteger globalMaxElementRowIndex = 0;
    __block NSUInteger globalMaxElementColIndex = 0;
    dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply_gmp(indices->getNbRows(), queue, ^(size_t rowIndex) {
      CHChalkValueNumberGmp* localMaxElement = nil;
      NSUInteger localMaxElementRowIndex = 0;
      NSUInteger localMaxElementColIndex = 0;
      if (indices->getNbCols() == 1)
      {
        NSUInteger matrixValueIndex = indices->getIndex(rowIndex, 0);
        CHChalkValue* value = [values objectAtIndex:matrixValueIndex];
        CHChalkValueScalar* valueScalar = [value dynamicCastToClass:[CHChalkValueScalar class]];
        CHChalkValue* absValue = !valueScalar ? nil :
          [CHParserFunctionNode combineAbs:@[valueScalar] token:nil context:nil];
        CHChalkValueNumberGmp* absValueGmp = [absValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
        localMaxElement = [absValueGmp retain];
        localMaxElementRowIndex = rowIndex;
        localMaxElementColIndex = 0;
      }//end if (indices->getNbCols() == 1)
      else//if (indices->getNbCols() > 1)
      {
        NSUInteger colIndexBegin = 0;
        NSUInteger colIndexEnd   = bottomLeftSearch ? rowIndex+1 : indices->getNbCols();
        for(NSUInteger colIndex = colIndexBegin ; colIndex<colIndexEnd ; ++colIndex)
        {
          @autoreleasepool {
            NSUInteger matrixValueIndex = indices->getIndex(rowIndex, colIndex);
            CHChalkValue* value = [values objectAtIndex:matrixValueIndex];
            CHChalkValueScalar* valueScalar = [value dynamicCastToClass:[CHChalkValueScalar class]];
            CHChalkValue* absValue = !valueScalar ? nil :
              [CHParserFunctionNode combineAbs:@[valueScalar] token:nil context:nil];
            CHChalkValueNumberGmp* absValueGmp = [absValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
            const chalk_gmp_value_t* absValueGmpValue = absValueGmp.valueConstReference;
            const chalk_gmp_value_t* localMaxElementGmpValue = localMaxElement.valueConstReference;
            int cmp = !localMaxElementGmpValue ? 0 : chalkGmpValueCmp(localMaxElementGmpValue, absValueGmpValue, [CHGmpPool peek]);
            BOOL updateMax = (!localMaxElementGmpValue || (cmp<0) ||
                ((cmp == 0) && (rowIndex<localMaxElementRowIndex)) ||
                ((cmp == 0) && (rowIndex==localMaxElementRowIndex) && (colIndex<localMaxElementColIndex)));
            if (updateMax)
            {
              localMaxElementRowIndex = rowIndex;
              localMaxElementColIndex = colIndex;
              [localMaxElement release];
              localMaxElement = [absValueGmp retain];
            }//end if (updateMax)
          }//end @autoreleasepool
        }//end for each col
      }//end if (indices->getNbCols() > 1)
      @synchronized(values)
      {
        const chalk_gmp_value_t* localMaxElementGmpValue = localMaxElement.valueConstReference;
        const chalk_gmp_value_t* globalMaxElementGmpValue = globalMaxElement.valueConstReference;
        int cmp = !globalMaxElementGmpValue ? 0 : chalkGmpValueCmp(globalMaxElementGmpValue, localMaxElementGmpValue, [CHGmpPool peek]);
        BOOL updateMax = (!globalMaxElementGmpValue || (cmp<0) ||
            ((cmp == 0) && (localMaxElementRowIndex<globalMaxElementRowIndex)) ||
            ((cmp == 0) && (localMaxElementRowIndex==globalMaxElementRowIndex) && (localMaxElementColIndex<globalMaxElementColIndex)));
        if (updateMax)
        {
          globalMaxElementRowIndex = localMaxElementRowIndex;
          globalMaxElementColIndex = localMaxElementColIndex;
          [globalMaxElement release];
          globalMaxElement = [localMaxElement retain];
        }//end if (updateMax)
      }//end @synchronized(values)
      [localMaxElement release];
    });//end for each row
    [globalMaxElement release];
    resultRowIndex = globalMaxElementRowIndex;
    resultColIndex = globalMaxElementColIndex;
    NSUInteger matrixValueIndex = indices->getIndex(resultRowIndex, resultColIndex);
    result = [values objectAtIndex:matrixValueIndex];
  }//end if (indices && indices->getNbRows() && indices->getNbCols())
  if (outRowIndex)
    *outRowIndex = resultRowIndex;
  if (outColIndex)
    *outColIndex = resultColIndex;
  return result;
}
//end getMaxMagnitudeElement()

void analyzeMatrix(NSArray* values, NSUInteger rowsCount, NSUInteger colsCount, BOOL* outIsLZero, BOOL* outIsUZero, BOOL* outIsDiag, BOOL* outIsDiagZero, BOOL* outHasDiagZero)
{
  if (values)
  {
    __block BOOL hasLNonZero = NO;
    __block BOOL hasUNonZero = NO;
    __block BOOL hasDiagZero = NO;
    __block BOOL hasDiagNonZero = NO;
    [values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSUInteger row = idx/colsCount;
      NSUInteger col = idx%colsCount;
      BOOL isInL = (col<row);
      BOOL isInU = (col>row);
      BOOL isInDiag = (col == row);
      BOOL isZero = ((CHChalkValue*)[obj dynamicCastToClass:[CHChalkValue class]]).isZero;
      if (isZero && isInDiag)
        hasDiagZero = YES;
      else if (!isZero)
      {
        if (isInL)
          hasLNonZero = YES;
        else if (isInU)
          hasUNonZero = YES;
        else if (isInDiag)
          hasDiagNonZero = YES;
      }//end if (!isZero)
    }];
    if (outIsLZero)
      *outIsLZero = !hasLNonZero;
    if (outIsUZero)
      *outIsUZero = !hasUNonZero;
    if (outIsDiag)
      *outIsDiag = !hasLNonZero && !hasUNonZero;
    if (outIsDiagZero)
      *outIsDiagZero = !hasDiagNonZero;
    if (outHasDiagZero)
      *outHasDiagZero = hasDiagZero;
  }//end if (values)
}
//end analyzeMatrix()

@implementation CHChalkValueMatrix

@synthesize rowsCount;
@synthesize colsCount;
@synthesize values;

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) identity:(NSUInteger)dimension context:(CHChalkContext*)context
{
  CHChalkValueMatrix* result = nil;
  if (dimension && (dimension<(NSUIntegerMax/dimension)))//no overflow
  {
    @autoreleasepool {
      NSNull* null = [NSNull null];
      CHChalkValueNumberGmp* zero = [[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] integer:0 naturalBase:context.computationConfiguration.baseDefault context:context];
      CHChalkValueNumberGmp* one = [[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] integer:1 naturalBase:context.computationConfiguration.baseDefault context:context];
      NSUInteger size = dimension*dimension;
      NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:size];
      for(NSUInteger i = 0 ; values && i<size ; ++i)
        [values addObject:null];
      __block BOOL error = NO;
      [values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger row = idx/dimension;
        NSUInteger col = idx%dimension;
        CHChalkValueNumberGmp* value = [((row == col) ? one : zero) copy];
        if (value)
          [values replaceObjectAtIndex:idx withObject:value];
        else//if (!value)
        {
          error = YES;
          *stop = YES;
        }//end if (!value)
        [value release];
      }];//end for each element
      if (error)
      {
        [values release];
        values = nil;
      }//end if (error)
      [zero release];
      [one release];
      result = !values ? nil :
        [[[self class] alloc] initWithToken:[CHChalkToken chalkTokenEmpty] rowsCount:dimension colsCount:dimension values:values context:nil];
      [values release];
    }//end @autoreleasepool
  }//end if (dimension && (dimension<(NSUIntegerMax/dimension)))//no overflow
  return [result autorelease];
}
//end identity:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken rowsCount:(NSUInteger)aRowsCount colsCount:(NSUInteger)aColsCount value:(CHChalkValueScalar*)value
                      context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->rowsCount = aRowsCount;
  self->colsCount = aColsCount;
  NSUInteger size = self->rowsCount*self->colsCount;
  CHChalkValueScalar* fillValue = value ? value : [CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context];
  __block BOOL error = NO;
  self->values = [[NSMutableArray alloc] initWithCapacity:size];
  NSNull* null = [NSNull null];
  for(NSUInteger i = 0 ; self->values && i<size ; ++i)
    [self->values addObject:null];
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValueScalar* fillValueClone = [fillValue copy];
    if (fillValueClone)
      [self->values replaceObjectAtIndex:idx withObject:fillValueClone];
    else//if (!fillValueClone)
    {
      error = YES;
      *stop = YES;
    }//end if (!fillValueClone)
    [fillValueClone release];
  }];//end for each element
  if (error)
  {
    [self->values release];
    self->values = nil;
  }//end if (error)
  [self->values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    self->evaluationComputeFlags |= ((CHChalkValue*)[obj dynamicCastToClass:[CHChalkValue class]]).evaluationComputeFlags;
  }];
  if (!self->values)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:aToken.range] context:context];
    [self release];
    return nil;
  }//end if (!self->values)
  return self;
}
//end initWithToken:rowsCount:colsCount:value:context:

-(instancetype) initWithToken:(CHChalkToken*)aToken rowsCount:(NSUInteger)aRowsCount colsCount:(NSUInteger)aColsCount values:(NSArray*)aValues
                      context:(CHChalkContext*)context
{
  if (!((self = [super initWithToken:aToken context:context])))
    return nil;
  self->rowsCount = aRowsCount;
  self->colsCount = aColsCount;
  NSUInteger size = self->rowsCount*self->colsCount;
  if (aValues.count == size)
    self->values = [CHChalkValue copyValues:aValues withZone:nil];
  else if (!aValues)
  {
    @autoreleasepool{
      CHChalkValueNumberGmp* zero = [CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context];
      self->values = [[NSMutableArray alloc] initWithCapacity:size];
      NSNull* null = [NSNull null];
      for(NSUInteger i = 0 ; self->values && i<size ; ++i)
        [self->values addObject:null];
      __block BOOL error = NO;
      [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHChalkValueScalar* fillValueClone = [zero copy];
        if (fillValueClone)
          [self->values replaceObjectAtIndex:idx withObject:fillValueClone];
        else//if (!fillValueClone)
        {
          error = YES;
          *stop = YES;
        }//end if (!fillValueClone)
        [fillValueClone release];
      }];//end for each element
      if (error)
      {
        [self->values release];
        self->values = nil;
      }//end if (error)
    }//end @autoreleasepool
  }//end if (!aValues)
  else
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorMatrixMalformed range:aToken.range] context:context];
  [self->values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    self->evaluationComputeFlags |= ((CHChalkValue*)[obj dynamicCastToClass:[CHChalkValue class]]).evaluationComputeFlags;
  }];
  if (!self->values)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:aToken.range] context:context];
    [self release];
    return nil;
  }//end if (!self->values)
  return self;
}
//end initWithToken:rowsCount:colsCount:context:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->rowsCount = [aDecoder decodeUnsignedIntegerForKey:@"rowsCount"];
  self->colsCount = [aDecoder decodeUnsignedIntegerForKey:@"colsCount"];
  self->values = [[aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:@"values"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeUnsignedInteger:self->rowsCount forKey:@"rowsCount"];
  [aCoder encodeUnsignedInteger:self->colsCount forKey:@"colsCount"];
  [aCoder encodeObject:self->values forKey:@"values"];
}
//end encodeWithCoder:

-(void) dealloc
{
  [self->values release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueMatrix* result = [super copyWithZone:zone];
  if (result)
  {
    result->rowsCount = self->rowsCount;
    result->colsCount = self->colsCount;
    result->values = [CHChalkValue copyValues:self->values withZone:zone];
    if (!result->values && self->values)
    {
      [result release];
      result = nil;
    }//end if (!result->values)
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueMatrix* dstMatrix = !result ? nil : [dst dynamicCastToClass:[CHChalkValueMatrix class]];
  if (result && dstMatrix)
  {
    dstMatrix->rowsCount = self->rowsCount;
    self->rowsCount = 0;
    dstMatrix->colsCount = self->colsCount;
    self->colsCount = 0;
    [dstMatrix->values release];
    dstMatrix->values = self->values;
    self->values = nil;
  }//end if (result && dstMatrix)
  return result;
}
//end moveTo:

-(BOOL) isZero
{
  BOOL result = NO;
  __block BOOL isNotZero = NO;
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* element = [obj dynamicCastToClass:[CHChalkValue class]];
    BOOL elementIsZero = element.isZero;
    if (!elementIsZero)
    {
      isNotZero = YES;
      *stop = YES;
    }//end if (!elementIsZero)
  }];
  result = !isNotZero;
  return result;
}
//end isZero

-(BOOL) isOne:(BOOL*)isOneIgnoringSign;
{
  BOOL result = NO;
  __block BOOL isNotIdentity = NO;
  __block BOOL hadToIgnoreSign = NO;
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* element = [obj dynamicCastToClass:[CHChalkValue class]];
    NSUInteger row = !self->colsCount ? 0 : idx/self->colsCount;
    NSUInteger col = !self->colsCount ? 0 : idx%self->colsCount;
    BOOL elementIsOneIgnoringSign = NO;
    BOOL elementIsOk = (row != col) ? element.isZero :
      ([element isOne:isOneIgnoringSign ? &elementIsOneIgnoringSign : 0] && (!isOneIgnoringSign || elementIsOneIgnoringSign));
    if (!elementIsOk)
    {
      isNotIdentity = YES;
      *stop = YES;
    }//end if (!elementIsOk)
    else if (isOneIgnoringSign && elementIsOneIgnoringSign)
      hadToIgnoreSign = YES;
  }];
  result = !isNotIdentity;
  if (isOneIgnoringSign)
    *isOneIgnoringSign = hadToIgnoreSign;
  return result;
}
//end isOne:

-(BOOL) negate
{
  BOOL result = NO;
  __block BOOL error = NO;
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* element = [obj dynamicCastToClass:[CHChalkValue class]];
    BOOL negated = [element negate];
    if (!negated)
    {
      error = YES;
      *stop = YES;
    }}];
  result = !error;
  return result;
}
//end negate

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context
{
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* value = [obj dynamicCastToClass:[CHChalkValue class]];
    [value adaptToComputeMode:computeMode context:context];
  }];
}
//end adaptToComputeMode:context:

-(CHChalkValue*) valueAtSubscript:(CHChalkValueSubscript*)subscript context:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (subscript.count == 0)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:subscript.token.range] context:context];
  }//end if (subscript.count == 0)
  if (subscript.count >= 1)
  {
    id indexObject = [subscript indexAtIndex:0];
    NSNumber* indexNumber = [indexObject dynamicCastToClass:[NSNumber class]];
    CHChalkValueIndexRange* indexRange = [indexObject dynamicCastToClass:[CHChalkValueIndexRange class]];
    NSRange range =
      indexNumber ? NSMakeRange(indexNumber.unsignedIntegerValue, 1) :
      indexRange ? indexRange.joker ? NSMakeRange(0, self->rowsCount) : indexRange.range :
      NSRangeZero;
    if (indexNumber || indexRange)
    {
      if (range.location+range.length > self->rowsCount)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
      else//if (range.location+range.length <= self->values.count)
      {
        NSArray* subArray = [self->values subarrayWithRange:NSMakeRange(range.location*self->colsCount, range.length*self->colsCount)];
        result = !subArray ? nil :
          [[[[self class] alloc] initWithToken:subscript.token rowsCount:range.length colsCount:self->colsCount values:subArray context:(CHChalkContext*)context] autorelease];
        if (!result)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:subscript.token.range] context:context];
      }//end if (range.location+range.length <= self->rowsCount)
    }//end if (indexNumber || indexRange)
    else//if (!indexNumber && !indexRange)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:subscript.token.range] context:context];
  }//end if (subscript.count >= 1)
  if (subscript.count >= 2)
  {
    CHChalkValueMatrix* intermediateMatrix = [result dynamicCastToClass:[CHChalkValueMatrix class]];
    result = nil;
    id indexObject = [subscript indexAtIndex:1];
    NSNumber* indexNumber = [indexObject dynamicCastToClass:[NSNumber class]];
    CHChalkValueIndexRange* indexRange = [indexObject dynamicCastToClass:[CHChalkValueIndexRange class]];
    NSRange range =
      indexNumber ? NSMakeRange(indexNumber.unsignedIntegerValue, 1) :
      indexRange ? indexRange.joker ? NSMakeRange(0, intermediateMatrix.colsCount) : indexRange.range :
      NSRangeZero;
    if (!intermediateMatrix)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown range:subscript.token.range] context:context];
    else if (indexNumber || indexRange)
    {
      if (range.location+range.length > self->colsCount)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
      else//if (range.location+range.length <= self->values.count)
      {
        NSMutableArray* subArray = [NSMutableArray arrayWithCapacity:range.length*intermediateMatrix->rowsCount];
        for(NSUInteger row = 0 ; row<intermediateMatrix->rowsCount ; ++row)
          for(NSUInteger col = range.location ; col<range.location+range.length ; ++col)
            [subArray addObject:[intermediateMatrix->values objectAtIndex:row*intermediateMatrix->colsCount+col]];
        result = !subArray ? nil :
          [[[[self class] alloc] initWithToken:subscript.token rowsCount:intermediateMatrix->rowsCount colsCount:range.length values:subArray context:(CHChalkContext*)context] autorelease];
        if (!result)
          [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:subscript.token.range] context:context];
      }//end if (range.location+range.length <= self->rowsCount)
    }//end if (indexNumber || indexRange)
    else//if (!indexNumber && !indexRange)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:subscript.token.range] context:context];
  }//end if (subscript.count == 2)
  if (subscript.count >= 3)
  {
    result = nil;
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:subscript.token.range] context:context];
  }//end if (subscript.count >= 3)
  CHChalkValueMatrix* resultMatrix = [result dynamicCastToClass:[CHChalkValueMatrix class]];
  if (resultMatrix && (resultMatrix.rowsCount == 1) && (resultMatrix.colsCount == 1))
    result = [resultMatrix valueAtRow:0 col:0];
  return result;
}
//end valueAtSubscript:

-(BOOL) setValue:(CHChalkValue*)value atSubscript:(CHChalkValueSubscript*)subscript context:(CHChalkContext*)context
{
  BOOL result = NO;
  NSMutableArray* intermediateIndices = [NSMutableArray array];
  NSUInteger intermediateRowsCount = 0;
  NSUInteger intermediateColsCount = 0;
  if (subscript.count == 0)
  {
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:subscript.token.range] context:context];
  }//end if (subscript.count == 0)
  if (subscript.count >= 1)
  {
    id indexObject = [subscript indexAtIndex:0];
    NSNumber* indexNumber = [indexObject dynamicCastToClass:[NSNumber class]];
    CHChalkValueIndexRange* indexRange = [indexObject dynamicCastToClass:[CHChalkValueIndexRange class]];
    NSRange range =
      indexNumber ? NSMakeRange(indexNumber.unsignedIntegerValue, 1) :
      indexRange ? indexRange.joker ? NSMakeRange(0, self->rowsCount) : indexRange.range :
      NSRangeZero;
    if (!intermediateIndices)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:subscript.token.range] context:context];
    else if (indexNumber || indexRange)
    {
      if (range.location+range.length > self->rowsCount)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
      else//if (range.location+range.length <= self->values.count)
      {
        intermediateRowsCount = range.length;
        intermediateColsCount = self->colsCount;
        for(NSUInteger row = range.location ; row<range.location+range.length ; ++row)
          for(NSUInteger col = 0 ; col<self->colsCount ; ++col)
            [intermediateIndices addObject:@(row*self->colsCount+col)];
      }//end if (range.location+range.length <= self->rowsCount)
    }//end if (indexNumber || indexRange)
    else//if (!indexNumber && !indexRange)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:subscript.token.range] context:context];
  }//end if (subscript.count >= 1)
  if (subscript.count >= 2)
  {
    NSMutableArray* newIntermediateIndices = [NSMutableArray array];
    id indexObject = [subscript indexAtIndex:1];
    NSNumber* indexNumber = [indexObject dynamicCastToClass:[NSNumber class]];
    CHChalkValueIndexRange* indexRange = [indexObject dynamicCastToClass:[CHChalkValueIndexRange class]];
    NSRange range =
      indexNumber ? NSMakeRange(indexNumber.unsignedIntegerValue, 1) :
      indexRange ? indexRange.joker ? NSMakeRange(0, intermediateColsCount) : indexRange.range :
      NSRangeZero;
    if (!intermediateIndices || !newIntermediateIndices)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation range:subscript.token.range] context:context];
    else if (indexNumber || indexRange)
    {
      if (range.location+range.length > intermediateColsCount)
        [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch range:subscript.token.range] context:context];
      else//if (range.location+range.length <= intermediateColsCount)
      {
        NSUInteger newIntermediateRowsCount = intermediateRowsCount;
        NSUInteger newIntermediateColsCount = range.length;
        for(NSUInteger row = 0 ; row<intermediateRowsCount ; ++row)
          for(NSUInteger col = range.location ; col<range.location+range.length ; ++col)
            [newIntermediateIndices addObject:[intermediateIndices objectAtIndex:row*intermediateColsCount+col]];
        intermediateIndices = newIntermediateIndices;
        intermediateRowsCount = newIntermediateRowsCount;
        intermediateColsCount = newIntermediateColsCount;
      }//end if (range.location+range.length <= intermediateColsCount)
    }//end if (indexNumber || indexRange)
    else//if (!indexNumber && !indexRange)
      [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:subscript.token.range] context:context];
  }//end if (subscript.count == 2)
  if (subscript.count >= 3)
    [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsCountError range:subscript.token.range] context:context];
  
  if (intermediateIndices)
  {
    NSUInteger valuesCount = intermediateRowsCount*intermediateColsCount;
    if (!valuesCount){
    }
    else if (valuesCount == 1)
    {
      NSUInteger index = [[intermediateIndices firstObject] unsignedIntegerValue];
      NSUInteger row = !self->colsCount ? 0 : index/self->colsCount;
      NSUInteger col = !self->colsCount ? 0 : index%self->colsCount;
      result = [self setValue:value atRow:row col:col];
    }//end if (valuesCount == 1)
    else//if (valuesCount > 1)
    {
      __block BOOL error = NO;
      [intermediateIndices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSUInteger index = [[obj dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
        NSUInteger row = index/self->colsCount;
        NSUInteger col = index%self->colsCount;
        CHChalkValue* valueToSet = [value copyWithZone:nil];
        error |= ![self setValue:valueToSet atRow:row col:col];
        [valueToSet release];
      }];
      result = !error;
    }//end if (valuesCount > 1)
  }//end if (intermediateIndices)

  return result;
}
//end setValue:atSubscript:

-(CHChalkValue*) valueAtRow:(NSUInteger)row col:(NSUInteger)col
{
  CHChalkValue* result = nil;
  if ((row < self->rowsCount) && (col < colsCount))
  {
    NSUInteger index = row*self->colsCount+col;
    id element = [self->values objectAtIndex:index];
    result = [element dynamicCastToClass:[CHChalkValue class]];
  }//end if ((row < self->rowsCount) && (col < colsCount))
  return result;
}
//end valueAtRow:col:

-(BOOL) setValue:(CHChalkValue*)value atRow:(NSUInteger)row col:(NSUInteger)col
{
  BOOL result = NO;
  if (value && (row < self->rowsCount) && (col < colsCount))
  {
    NSUInteger index = row*self->colsCount+col;
    [self->values replaceObjectAtIndex:index withObject:value];
    result = YES;
  }//end if ((row < self->rowsCount) && (col < colsCount))
  return result;
}
//end setValue:atRow:col:

-(void) fill:(CHChalkValue*)value context:(CHChalkContext*)context
{
  [self->values enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkValue* valueClone = [value copy];
    if (valueClone)
      [self->values replaceObjectAtIndex:idx withObject:valueClone];
    {
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                             replace:NO];
      *stop = YES;
    }//end if (!valueClone)
    [valueClone release];
  }];
}
//end fill:context:

-(CHChalkValue*) traceWithContext:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (self->rowsCount != self->colsCount)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch]
                           replace:NO];
  else//if (self->rowsCount == self->colsCount)
  {
    NSMutableArray* diagonalArray = [[NSMutableArray alloc] initWithCapacity:self->rowsCount];
    if (!diagonalArray)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                             replace:NO];
    else//if (diagonalArray)
    {
      for(NSUInteger i = 0 ; i<self->rowsCount ; ++i)
        [diagonalArray addObject:[self valueAtRow:i col:i]];
      result = [CHParserOperatorNode combineAdd:diagonalArray operatorToken:[CHChalkToken chalkTokenEmpty] context:context];
    }//end if (diagonalArray)
    [diagonalArray release];
  }//end if (self->rowsCount == self->colsCount)
  return result;
}
//end traceWithContext:

-(CHChalkValue*) determinantWithContext:(CHChalkContext*)context
{
  CHChalkValue* result = nil;
  if (!self->rowsCount || !self->colsCount || (self->rowsCount != self->colsCount))
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch]
                           replace:NO];
  else//if (self->rowsCount && self->colsCount && (self->rowsCount == self->colsCount))
  {
    if (self->rowsCount == 1)
    {
      result = [[[[self->values objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]] copy] autorelease];
      if (!result)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                               replace:NO];
    }//end if (self->rowsCount == 1)
    else if (self->rowsCount == 2)
    {
      @autoreleasepool {
        CHChalkValue* a = [self valueAtRow:0 col:0];
        CHChalkValue* b = [self valueAtRow:0 col:1];
        CHChalkValue* c = [self valueAtRow:1 col:0];
        CHChalkValue* d = [self valueAtRow:1 col:1];
        CHChalkValue* product1 = !a || !d ? nil :
          [CHParserOperatorNode combineMul:@[a,d] operatorToken:[CHChalkToken chalkTokenEmpty] context:context];
        CHChalkValue* product2 = !a || !b ? nil :
          [CHParserOperatorNode combineMul:@[b,c] operatorToken:[CHChalkToken chalkTokenEmpty] context:context];
        result = !product1 || !product2 ? nil :
          [CHParserOperatorNode combineSub:@[product1,product2] operatorToken:[CHChalkToken chalkTokenEmpty] context:context];
        if (!result)
          [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown]
                                 replace:NO];
        [result retain];
      }//end @autoreleasepool
      [result autorelease];
    }//end if (self->rowsCount == 2)
    else//if (self->rowsCount > 2)
    {
      BOOL isLZero = NO;
      BOOL isUZero = NO;
      BOOL isDiag = NO;
      BOOL isDiagZero = NO;
      BOOL hasDiagZero = NO;
      analyzeMatrix(self->values, self->rowsCount, self->colsCount, &isLZero, &isUZero, &isDiag, &isDiagZero, &hasDiagZero);
      if ((isLZero || isUZero) && hasDiagZero)
        result = [CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context];
      else if (isLZero || isUZero)
      {
        @autoreleasepool {
          NSMutableArray* diagonal = [[NSMutableArray alloc] initWithCapacity:self->rowsCount];
          for(NSUInteger index = 0 ; index<self->rowsCount ; ++index)
            [diagonal addObject:[self valueAtRow:index col:index]];
          result = !diagonal ? nil : [CHParserOperatorNode combineMul:diagonal operatorToken:[CHChalkToken chalkTokenEmpty] context:context];
          [diagonal release];
          if (!result)
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                                   replace:NO];
           [result retain];
        }//end @autoreleasepool
        [result autorelease];
      }//end if (isLZero || isUZero)
      else//if not well-known matrix
      {
        NSMutableArray* valuesTmp = [self->values mutableCopy];
        MatrixIndices* indices = new MatrixIndices(self->rowsCount, self->colsCount);
        if (valuesTmp && indices)
        {
          dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
          BOOL invertSign = NO;
          NSUInteger pivotIndexRow = 0;
          NSUInteger pivotIndexCol = 0;
          CHChalkValue* pivot = getMaxMagnitudeElement(valuesTmp, indices, &pivotIndexRow, &pivotIndexCol, NO);
          while(pivot && !pivot.isZero)
          {
            @autoreleasepool {
              CHChalkValue* newResult = !result ? [pivot copy] :
                [[CHParserOperatorNode combineMul:@[result,pivot] operatorToken:nil context:context] retain];
              [result release];
              result = newResult;
              NSUInteger lastRow = indices->getNbRows()-1;
              NSUInteger lastCol = indices->getNbCols()-1;
              invertSign ^= (lastRow != pivotIndexRow)^(lastCol != pivotIndexCol);
              indices->swapRows(lastRow, pivotIndexRow);
              indices->swapCols(lastCol, pivotIndexCol);
              dispatch_apply_gmp(indices->getNbRows()-1, queue, ^(size_t rowIndex) {
                CHChalkValue* linePivot = [valuesTmp objectAtIndex:indices->getIndex(rowIndex, lastCol)];
                dispatch_applyWithOptions_gmp(indices->getNbCols(), queue, DISPATCH_OPTION_NONE, ^(size_t colIndex) {
                  CHChalkValue* elementOfPivotLine = [valuesTmp objectAtIndex:indices->getIndex(lastRow, colIndex)];
                  CHChalkValue* elementOfCurrentLine = [valuesTmp objectAtIndex:indices->getIndex(rowIndex, colIndex)];
                  CHChalkValue* factor = !linePivot || !pivot ? nil :
                    linePivot.isZero ? linePivot :
                    [CHParserOperatorNode combineDiv:@[linePivot,pivot] operatorToken:nil context:context];
                  CHChalkValue* delta = !elementOfCurrentLine || !factor ? nil :
                    elementOfCurrentLine.isZero ? elementOfCurrentLine :
                    factor.isZero ? factor :
                    [CHParserOperatorNode combineMul:@[elementOfPivotLine,factor] operatorToken:nil context:context];
                  CHChalkValue* newElementOfCurrentLine = !elementOfCurrentLine || !delta ? nil :
                    delta.isZero ? elementOfCurrentLine :
                    [CHParserOperatorNode combineSub:@[elementOfCurrentLine,delta] operatorToken:nil context:context];
                  newElementOfCurrentLine.evaluationComputeFlags |=
                    elementOfPivotLine.evaluationComputeFlags |
                    elementOfCurrentLine.evaluationComputeFlags |
                    factor.evaluationComputeFlags |
                    delta.evaluationComputeFlags;
                  if (newElementOfCurrentLine)
                    [valuesTmp replaceObjectAtIndex:indices->getIndex(rowIndex, colIndex) withObject:newElementOfCurrentLine];
                });//end for each col
              });//end for each row
              indices->removeRow(lastRow);
              indices->removeCol(lastCol);
            }//end @autoreleasepool
            pivot = getMaxMagnitudeElement(valuesTmp, indices, &pivotIndexRow, &pivotIndexCol, YES);
          }//end while(pivot && !pivot.isZero)
          if (pivot.isZero){
            [result release];
            result = [[CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context] retain];
          }
          else if (invertSign)
            [result negate];
        }//end if (valuesTmp && indices)
        delete indices;
        [valuesTmp release];
        [result autorelease];
      }//end if not well-known matrix
    }//end if (self->rowsCount > 2)
  }//end if (self->rowsCount && self->colsCount && (self->rowsCount == self->colsCount))
  return result;
}
//end maxMagnitudeElement:

-(CHChalkValueMatrix*) transposedWithContext:(CHChalkContext*)context
{
  CHChalkValueMatrix* result = [[self copy] autorelease];
  result = [result transposeWithContext:context];
  return result;
}
//end transposedWithContext:

-(CHChalkValueMatrix*) transposeWithContext:(CHChalkContext*)context
{
  CHChalkValueMatrix* result = self;
  NSMutableArray* transposedArray = [[NSMutableArray alloc] initWithCapacity:self->values.count];
  if (!transposedArray)
    result = nil;
  else//if (transposedArray)
  {
    for(NSUInteger col = 0 ; col<self->colsCount ; ++col)
    {
      for(NSUInteger row = 0 ; row<self->rowsCount ; ++row)
      {
        [transposedArray addObject:[self valueAtRow:row col:col]];
      }
    }//end for each row
    [self->values setArray:transposedArray];
    std::swap(self->rowsCount, self->colsCount);
    [transposedArray release];
  }//end if (transposedArray)
  return result;
}
//end transposeWithContext:

-(CHChalkValueMatrix*) invertedWithContext:(CHChalkContext*)context;
{
  CHChalkValueMatrix* result = nil;
  if (self->rowsCount != self->colsCount)
    [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorDimensionsMismatch]
                           replace:NO];
  else if (self->rowsCount == 0)
  {
    result = [[self copy] autorelease];
    if (!result)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                             replace:NO];
  }//end if (self->rowsCount == 0)
  else if (self->rowsCount == 1)
  {
    CHChalkValue* element = [self valueAtRow:0 col:0];
    CHChalkValue* invertedElement = !element ? nil :
      element.isZero ? nil :
      [CHParserFunctionNode combineInv:@[element] token:self->token context:context];
    CHChalkValueScalar* invertedElementScalar = [invertedElement dynamicCastToClass:[CHChalkValueScalar class]];
    result = !invertedElementScalar ? nil :
      [[[CHChalkValueMatrix alloc] initWithToken:self->token rowsCount:1 colsCount:1 value:invertedElementScalar context:context] autorelease];
    if (!element)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown]
                             replace:NO];
    else if (!invertedElement && element.isZero)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorMatrixNotInvertible]
                             replace:NO];
    else if (!invertedElement)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorUnknown]
                             replace:NO];
    else if (!result)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorAllocation]
                             replace:NO];
  }//end if (self->rowsCount == 1)
  else//if (self->rowsCount > 1)
  {
    BOOL isLZero = NO;
    BOOL isUZero = NO;
    BOOL isDiag = NO;
    BOOL isDiagZero = NO;
    BOOL hasDiagZero = NO;
    analyzeMatrix(self->values, self->rowsCount, self->colsCount, &isLZero, &isUZero, &isDiag, &isDiagZero, &hasDiagZero);
    if (isLZero && isUZero && isDiagZero)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorMatrixNotInvertible]
                             replace:NO];
    else if (isDiag && hasDiagZero)
      [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorMatrixNotInvertible]
                             replace:NO];
    else if (isDiag)
    {
      CHChalkValueMatrix* workMatrix = [self copy];
      if (!workMatrix)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                               replace:NO];
      else//if (workMatrix)
      {
        @autoreleasepool {
          dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
          __block volatile BOOL stop = NO;
          dispatch_applyWithOptions_gmp(self->rowsCount, queue, DISPATCH_OPTION_NONE, ^(size_t index) {
            if (!stop)
            {
              CHChalkValue* value = [workMatrix valueAtRow:index col:index];
              CHChalkValue* invValue = !value ? nil :
                [CHParserFunctionNode combineInv:@[value] token:self->token context:context];
              if (invValue)
                [workMatrix setValue:invValue atRow:index col:index];
              else//if (!invValue)
              {
                stop = YES;
                [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorUnknown]
                                       replace:NO];
              }//end if (!invValue)
            }//end if (!stop)
          });
          if (stop)
          {
            [workMatrix release];
            workMatrix = nil;
          }//end if (stop)
        }//end @autoreleasepool
      }//end if (workMatrix)
      result = [workMatrix autorelease];
    }//end if (isDiag)
    else//if not well known matrix
    {
      NSMutableArray* workValues = [self->values mutableCopy];
      CHChalkValueMatrix* identity = [[self class] identity:self->rowsCount context:context];
      NSMutableArray* identityValues = identity->values;
      MatrixIndices* workIndices = new(std::nothrow) MatrixIndices(self->rowsCount, self->colsCount);
      MatrixIndices* identityIndices = new(std::nothrow) MatrixIndices(self->rowsCount, self->colsCount);
      if (!workValues || !workIndices || !identityIndices)
        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                               replace:NO];
      else//if (workValues && workIndices && identityIndices)
      {
        dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        NSUInteger pivotRow = 0;
        NSUInteger pivotSearchRow = 0;
        NSUInteger pivotSearchCol = 0;
        BOOL stop = NO;
        for(NSUInteger col = 0 ; !stop && (pivotRow<self->rowsCount) && (col<self->colsCount) ; ++col, ++pivotRow)
        {
          CHChalkValue* pivot = getMaxMagnitudeColElement(workValues, self->rowsCount, self->colsCount, workIndices,
                                                          NSMakeRange(pivotRow, self->rowsCount-pivotRow), NSMakeRange(col, 1),
                                                          &pivotSearchRow, &pivotSearchCol);
          if (!pivot)
          {
            stop = YES;
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown]
                                   replace:NO];
          }//end if (!pivot)
          else if (pivot.isZero)
          {
            stop = YES;
            [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainNumeric reason:CHChalkErrorMatrixNotInvertible]
                                   replace:NO];
          }//end if (pivot.isZero)
          else//if (!pivot.isZero)
          {
            workIndices->swapRows(pivotRow, pivotSearchRow);
            identityIndices->swapRows(pivotRow, pivotSearchRow);
            __block volatile BOOL stop = NO;
            if (!stop)
            dispatch_applyWithOptions_gmp(self->colsCount, queue, DISPATCH_OPTION_NONE, ^(size_t colIndex) {
              if (!stop)
              {
                NSUInteger workIndex = workIndices->getIndex(pivotRow, colIndex);
                NSUInteger identityIndex = identityIndices->getIndex(pivotRow, colIndex);
                CHChalkValue* workElement = [workValues objectAtIndex:workIndex];
                CHChalkValue* workElementDivided = !workElement || !pivot ? nil :
                  [CHParserOperatorNode combineDiv:@[workElement,pivot] operatorToken:self->token context:context];
                CHChalkValue* identityElement = [identityValues objectAtIndex:identityIndex];
                CHChalkValue* identityElementDivided = !identityElement || !pivot ? nil :
                  [CHParserOperatorNode combineDiv:@[identityElement,pivot] operatorToken:self->token context:context];
                if (!workElementDivided || !identityElementDivided)
                {
                  stop = YES;
                  [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown]
                                         replace:NO];
                }//end if (!workElementDivided || !identityElementDivided)
                else//if (workElementDivided && identityElementDivided)
                {
                  [workValues replaceObjectAtIndex:workIndex withObject:workElementDivided];
                  [identityValues replaceObjectAtIndex:identityIndex withObject:identityElementDivided];
                }//end if (workElementDivided && identityElementDivided)
                workElementDivided.evaluationComputeFlags |=
                  workElement.evaluationComputeFlags;
                identityElementDivided.evaluationComputeFlags |=
                  identityElement.evaluationComputeFlags;
              }//end if (!stop)
            });
            if (!stop)
            dispatch_applyWithOptions_gmp(self->rowsCount, queue, DISPATCH_OPTION_SYNCHRONOUS, ^(size_t rowIndex) {
              if (!stop && (rowIndex != pivotRow))
              {
                CHChalkValue* currentLinePivotElement = [[workValues objectAtIndex:workIndices->getIndex(rowIndex, col)] retain];
                if (!currentLinePivotElement){
                }
                else if (currentLinePivotElement.isZero){
                }
                else//if (!currentLinePivotElement.isZero)
                {
                  dispatch_applyWithOptions_gmp(self->colsCount, queue, DISPATCH_OPTION_NONE, ^(size_t colIndex) {
                    if (!stop)
                    {
                      CHChalkValue* workPivotLineElement = [workValues objectAtIndex:workIndices->getIndex(pivotRow, colIndex)];
                      CHChalkValue* identityPivotLineElement = [identityValues objectAtIndex:workIndices->getIndex(pivotRow, colIndex)];
                      NSUInteger workIndex = workIndices->getIndex(rowIndex, colIndex);
                      NSUInteger identityIndex = identityIndices->getIndex(rowIndex, colIndex);
                      BOOL workElementWillBeSetToZero = (colIndex == col);
                      CHChalkValue* workElement = workElementWillBeSetToZero ? nil : [workValues objectAtIndex:workIndex];
                      CHChalkValue* identityElement = [identityValues objectAtIndex:identityIndex];
                      CHChalkValue* workProduct = workElementWillBeSetToZero ? nil :
                        !currentLinePivotElement || !workPivotLineElement ? nil :
                        [CHParserOperatorNode combineMul:@[currentLinePivotElement,workPivotLineElement] operatorToken:self->token context:context];
                      CHChalkValue* identityProduct = !currentLinePivotElement || !identityPivotLineElement ? nil :
                        [CHParserOperatorNode combineMul:@[currentLinePivotElement,identityPivotLineElement] operatorToken:self->token context:context];
                      CHChalkValue* workSub = workElementWillBeSetToZero ? nil :
                        !workElement || !workProduct ? nil :
                        [CHParserOperatorNode combineSub:@[workElement,workProduct] operatorToken:self->token context:context];
                      CHChalkValue* identitySub = !identityElement || !identityProduct ? nil :
                        [CHParserOperatorNode combineSub:@[identityElement,identityProduct] operatorToken:self->token context:context];
                      CHChalkValue* newWorkElement =
                        workElementWillBeSetToZero ? [CHChalkValueNumberGmp zeroWithToken:[CHChalkToken chalkTokenEmpty] context:context] :
                        workSub;
                      if (workElementWillBeSetToZero && !newWorkElement)
                      {
                        stop = YES;
                        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorAllocation]
                                               replace:NO];
                      }//end if (workElementWillBeSetToZero && !newWorkElement)
                      else if ((!workElementWillBeSetToZero && !workSub) || !identitySub)
                      {
                        stop = YES;
                        [context.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnknown]
                                               replace:NO];
                      }//end if ((!workElementWillBeSetToZero && !workSub) || !identitySub)
                      else//if (workSub && identitySub)
                      {
                        [workValues replaceObjectAtIndex:workIndex withObject:newWorkElement];
                        [identityValues replaceObjectAtIndex:identityIndex withObject:identitySub];
                      }//end if (workSub && identitySub)
                      newWorkElement.evaluationComputeFlags |=
                        workProduct.evaluationComputeFlags |
                        workSub.evaluationComputeFlags |
                        workElement.evaluationComputeFlags;
                      identitySub.evaluationComputeFlags |=
                        identityProduct.evaluationComputeFlags |
                        identityElement.evaluationComputeFlags;
                    }//end if (!stop)
                  });//end for each col
                }//end if (!currentLinePivotElement.isZero)
                [currentLinePivotElement release];
              }//end if (!stop && (rowIndex != pivotRow))
            });//end for each row
          }//end if (!pivot.isZero)
        }//end for each col
        if (!stop)//make output matrix
        {
          dispatch_applyWithOptions_gmp(self->rowsCount*self->colsCount, queue, DISPATCH_OPTION_NONE, ^(size_t index) {
            NSUInteger row = index/self->colsCount;
            NSUInteger col = index%self->colsCount;
            NSUInteger indirectIndex = identityIndices->getIndex(row, col);
            [workValues replaceObjectAtIndex:index withObject:[identityValues objectAtIndex:indirectIndex]];
          });
          identityValues = nil;
          [identity->values release];
          identity->values = workValues;
          workValues = nil;
          result = identity;
        }//end if (!stop)
      }//end if (workValues && workIndices && identityIndices)
      [workValues release];
      if (workIndices)
        delete workIndices;
      if (identityIndices)
        delete identityIndices;
    }//end if not well known matrix
  }//end if (self->rowsCount == self->colsCount)
  return result;
}
//end invertedWithContext:

-(CHChalkValueMatrix*) invertWithContext:(CHChalkContext*)context;
{
  CHChalkValueMatrix* result = nil;
  CHChalkValueMatrix* inverted = [self invertedWithContext:context];
  if (inverted)
    result = [inverted moveTo:self] ? self : nil;
  return result;
}
//end invertWithContext:

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    [stream writeString:@"\\begin{pmatrix}"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"<mrow><mo>(</mo><mtable>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    [stream writeString:@"<table>"];
  else
    [stream writeString:@"("];
}
//end writeHeaderToStream:context:description:

-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
    [stream writeString:@"\\end{pmatrix}"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
    [stream writeString:@"</mtable><mo>(</mo></mrow>"];
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
    [stream writeString:@"</table>"];
  else
    [stream writeString:@")"];
}
//end writeFooterToStream:context:description:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  {
    for(NSUInteger row = 0 ; row<self->rowsCount ; ++row)
    {
      NSRange rowRange = NSMakeRange(row*self->colsCount, self->colsCount);
      if (rowRange.length)
      {
        CHChalkValue* elementValue = [[self->values objectAtIndex:rowRange.location] dynamicCastToClass:[CHChalkValue class]];
        [elementValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        for(NSUInteger col = rowRange.location+1 ; col<rowRange.location+rowRange.length ; ++col)
        {
          CHChalkValue* elementValue = [[self->values objectAtIndex:col] dynamicCastToClass:[CHChalkValue class]];
          [stream writeString:@" & "];
          [elementValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        }//end for each col
      }//end if (rowRange.length)
      [stream writeString:@"\\\\"];
    }//end for each row
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_TEX)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  {
    for(NSUInteger row = 0 ; row<self->rowsCount ; ++row)
    {
      [stream writeString:@"<mtr>"];
      NSRange rowRange = NSMakeRange(row*self->colsCount, self->colsCount);
      for(NSUInteger col = rowRange.location ; col<rowRange.location+rowRange.length ; ++col)
      {
        CHChalkValue* elementValue = [[self->values objectAtIndex:col] dynamicCastToClass:[CHChalkValue class]];
        [stream writeString:@"<mtd>"];
        [elementValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        [stream writeString:@"</mtd>"];
      }//end for each col
      [stream writeString:@"</mtr>"];
    }//end for each row
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_MATHML)
  else if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  {
    for(NSUInteger row = 0 ; row<self->rowsCount ; ++row)
    {
      [stream writeString:@"<tr>"];
      NSRange rowRange = NSMakeRange(row*self->colsCount, self->colsCount);
      if (rowRange.length)
      {
        for(NSUInteger col = rowRange.location ; col<rowRange.location+rowRange.length ; ++col)
        {
          [stream writeString:@"<td>"];
          CHChalkValue* elementValue = [[self->values objectAtIndex:col] dynamicCastToClass:[CHChalkValue class]];
          [elementValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
          [stream writeString:@"</td>"];
        }//end for each col
      }//end if (rowRange.length)
      [stream writeString:@"</tr>"];
    }//end for each row
  }//end if (presentationConfiguration.description == CHALK_VALUE_DESCRIPTION_HTML)
  else
  {
    for(NSUInteger row = 0 ; row<self->rowsCount ; ++row)
    {
      [stream writeString:@"("];
      NSRange rowRange = NSMakeRange(row*self->colsCount, self->colsCount);
      if (rowRange.length)
      {
        CHChalkValue* elementValue = [[self->values objectAtIndex:rowRange.location] dynamicCastToClass:[CHChalkValue class]];
        [elementValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        for(NSUInteger col = rowRange.location+1 ; col<rowRange.location+rowRange.length ; ++col)
        {
          CHChalkValue* elementValue = [[self->values objectAtIndex:col] dynamicCastToClass:[CHChalkValue class]];
          [stream writeString:@","];
          [elementValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
        }//end for each col
      }//end if (rowRange.length)
      [stream writeString:@")"];
    }//end for each row
  }//end if (...)
}
//end writeToStream:description:

@end
