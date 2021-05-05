//
//  CHStreamWrapper.m
//  Chalk
//
//  Created by Pierre Chatelier on 17/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHStreamWrapper.h"

#import "CHUtils.h"
#import "NSAttributedStringExtended.h"
#import "NSMutableAttributedStringExtended.h"
#import "NSMutableDataExtended.h"
#import "NSMutableStringExtended.h"

@implementation CHStreamWrapper

@synthesize attributedStringStream;
@synthesize stringStream;
@synthesize dataStream;
@synthesize fileStream;
@dynamic    currentAttributes;

-(void) dealloc
{
  [self reset];
  [super dealloc];
}
//end dealloc

-(NSDictionary*) currentAttributes
{
  NSDictionary* result = nil;
  NSAttributedString* currentAttributedString = self->attributedStringStream;
  NSRange lastCharacterRange = !currentAttributedString.length ? NSRangeZero : NSMakeRange(currentAttributedString.length-1, 1);
  result = !lastCharacterRange.length ? @{} : [currentAttributedString fontAttributesInRange:lastCharacterRange];
  return result;
}
//end currentAttributes

-(void) reset
{
  [self->attributedStringStream release];
  self->attributedStringStream = nil;
  [self->stringStream release];
  self->stringStream = nil;
  [self->dataStream release];
  self->dataStream = nil;
  self->fileStream = 0;
}
//end reset

-(void) writeAttributedString:(NSAttributedString*)attributedString
{
  if (attributedString)
  {
    @autoreleasepool
    {
      if (self->attributedStringStream)
        [self->attributedStringStream appendAttributedString:attributedString];
      if (self->stringStream)
        [self->stringStream appendString:[attributedString string]];
      NSData* data = nil;
      NSError* error = nil;
      NSDictionary<NSAttributedStringDocumentAttributeKey, id>* documentAttributes = @{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType};
      if (self->dataStream)
      {
        if (!data && attributedString)
          data = [attributedString dataFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:documentAttributes error:&error];
        [self->dataStream appendData:data];
      }//end if (self->dataStream)
      if (self->fileStream)
      {
        if (!data && attributedString)
          data = [attributedString dataFromRange:NSMakeRange(0, [attributedString length]) documentAttributes:documentAttributes error:&error];
        fwrite([data bytes], [data length], sizeof(unsigned char), self->fileStream);
      }//end if (self->fileStream)
    }//end @autoreleasepool
  }//end if (attributedString)
}
//end writeAttributedString:

-(void) writeAttributedString:(NSAttributedString*)attributedString bold:(BOOL)bold italic:(BOOL)italic
{
  @autoreleasepool {
    NSAttributedString* newAttributedString = attributedString;
    if (bold || italic)
    {
      NSDictionary* currentFontAttributes = self.currentAttributes;
      NSMutableDictionary* newFontAttributes = [[currentFontAttributes mutableCopy] autorelease];
      if (bold)
        [newFontAttributes setObject:@{NSFontSymbolicTrait:@(NSFontBoldTrait)} forKey:NSFontTraitsAttribute];
      if (italic)
        [newFontAttributes setObject:@{NSFontSymbolicTrait:@(NSFontItalicTrait)} forKey:NSFontTraitsAttribute];
      NSMutableAttributedString* newMutableAttributedString = [[newAttributedString mutableCopy] autorelease];
      [newMutableAttributedString addAttributes:newFontAttributes range:NSMakeRange(0, newMutableAttributedString.length)];
      newAttributedString = newMutableAttributedString;
    }//end if (bold || italic)
    [self writeAttributedString:newAttributedString];
  }//end @autoreleasepool
}
//end writeAttributedString:bold:italic:

-(void) writeString:(NSString*)string bold:(BOOL)bold italic:(BOOL)italic
{
  @autoreleasepool {
    NSMutableDictionary* attributes = nil;
    if (bold || italic)
    {
      attributes = [NSMutableDictionary dictionaryWithCapacity:2];
      if (bold)
        [attributes setObject:@{NSFontSymbolicTrait:@(NSFontBoldTrait)} forKey:NSFontTraitsAttribute];
      if (italic)
        [attributes setObject:@{NSFontSymbolicTrait:@(NSFontItalicTrait)} forKey:NSFontTraitsAttribute];
    }//end if (bold || italic)
    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
    [self writeAttributedString:attributedString];
    [attributedString release];
  }//end @autoreleasepool
}
//end writeString:bold:italic:

-(void) writeString:(NSString*)string
{
  if (string)
  {
    @autoreleasepool
    {
      if (self->attributedStringStream && string)
        [self->attributedStringStream appendAttributedString:[NSAttributedString attributedStringWithString:string]];
      if (self->stringStream)
        [self->stringStream appendString:string];
      NSData* data = nil;
      if (self->dataStream)
      {
        if (!data)
          data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self->dataStream appendData:data];
      }//end if (self->dataStream)
      if (self->fileStream)
      {
        if (!data)
          data = [string dataUsingEncoding:NSUTF8StringEncoding];
        fwrite([data bytes], [data length], sizeof(unsigned char), self->fileStream);
      }//end if (self->fileStream)
    }//end @autoreleasepool
  }//end if (string)
}
//end writeString:

-(void) writeString:(NSString*)string groupSize:(NSInteger)groupSize groupOffset:(NSUInteger)groupOffset space:(NSString*)space
{
  NSUInteger stringLength = string.length;
  if (!groupSize)
    [self writeString:string];
  else if (stringLength<=ABS(groupSize))
    [self writeString:string];
  else if (groupSize > 0)
  {
    BOOL groupWritten = NO;
    NSUInteger groupsOffset = (stringLength+groupOffset)%groupSize;
    NSRange range = NSMakeRange(0, groupsOffset);
    if (range.length)
    {
      [self writeString:[string substringWithRange:range]];
      groupWritten = YES;
      range.location += range.length;
      range.length = MIN(groupSize, stringLength-range.location);
    }//end if (range.length)
    while(range.location<stringLength)
    {
      if (groupWritten)
        [self writeString:space];
      [self writeString:[string substringWithRange:range]];
      groupWritten |= (range.length > 0);
      range.location += range.length;
      range.length = MIN(groupSize, stringLength-range.location);
    }//end while(range.location<stringLength)
  }//end if (groupSize > 0)
  else if (groupSize < 0)
  {
    BOOL groupWritten = NO;
    NSUInteger absGroupSize = ABS(groupSize);
    NSRange range = NSMakeRange(0, absGroupSize);
    while(range.location<stringLength)
    {
      if (groupWritten)
        [self writeString:space];
      [self writeString:[string substringWithRange:range]];
      groupWritten |= (range.length > 0);
      range.location += range.length;
      range.length = MIN(absGroupSize, stringLength-range.location);
    }//end while(range.location<stringLength)
  }//end if (groupSize < 0)
}
//end writeString:

-(BOOL) writeCharacter:(char)character count:(NSUInteger)count
{
  BOOL result = NO;
  BOOL error = NO;
  if (self->attributedStringStream)
    error |= ![self->attributedStringStream appendCharacter:character count:count];
  if (self->stringStream)
    error |= ![self->stringStream appendCharacter:character count:count];
  if (self->dataStream)
    error |= ![self->dataStream appendCharacter:character count:count];
  if (self->fileStream)
  {
    int character2 = character;
    while(!error && count--)
      error |= (fputc(character2, self->fileStream) == EOF);
  }//end if (self->fileStream)
  result = !error;
  return result;
}
//end writeCharacter:count:

-(BOOL) writeCharacter:(char)character count:(NSUInteger)count groupSize:(NSInteger)groupSize groupOffset:(NSUInteger)groupOffset space:(NSString*)space
{
  BOOL result = NO;
  if (!groupSize || count<ABS(groupSize))
    result = [self writeCharacter:character count:count];
  else if (groupSize > 0)
  {
    NSUInteger groupsOffset = (count+groupOffset)%groupSize;
    [self writeCharacter:character count:groupsOffset];
    BOOL groupWritten = (groupsOffset != 0);
    count -= groupsOffset;
    while(count)
    {
      if (groupWritten)
        [self writeString:space];
      [self writeCharacter:character count:MIN(count, groupSize)];
      groupWritten = YES;
      count = (count<=groupSize) ? 0 : (count-groupSize);
    }//end while(count)
  }//end if (groupSize > 0)
  else if (groupSize < 0)
  {
    NSUInteger absGroupSize = ABS(groupSize);
    NSUInteger groupsOffset = (groupOffset)%absGroupSize;
    [self writeCharacter:character count:groupsOffset];
    BOOL groupWritten = (groupsOffset != 0);
    count -= groupsOffset;
    while(count)
    {
      if (groupWritten)
        [self writeString:space];
      [self writeCharacter:character count:MIN(count, absGroupSize)];
      groupWritten = YES;
      count = (count<=absGroupSize) ? 0 : (count-absGroupSize);
    }//end while(count)
  }//end if (groupSize < 0)
  return result;
}
//end writeCharacter:count:

@end
