//
//  CHChalkErrorURLContent.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkErrorURLContent.h"

#import "NSCoderExtended.h"

@implementation CHChalkErrorURLContent

@synthesize url;
@synthesize urlContentRanges;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithDomain:(NSString*)aDomain reason:(NSString*)aReason range:(NSRange)aRange url:(NSURL*)aUrl urlContentRange:(NSRange)aUrlContentRange
{
  return [self initWithDomain:aDomain reason:aReason range:aRange url:aUrl urlContentRanges:[NSIndexSet indexSetWithIndexesInRange:aUrlContentRange]];
}
//end initWithDomain:reason:range:url:urlContentRange:

-(instancetype) initWithDomain:(NSString*)aDomain reason:(NSString*)aReason range:(NSRange)aRange url:(NSURL*)aUrl urlContentRanges:(NSIndexSet*)aUrlContentRanges
{
  if (!((self = [super initWithDomain:aDomain reason:aReason range:aRange])))
    return nil;
  self->url = [aUrl copy];
  self->urlContentRanges = [aUrlContentRanges mutableCopy];
  return self;
}
//end initWithDomain:reason:range::url:urlContentRanges:

-(instancetype) initWithDomain:(NSString*)aDomain reason:(NSString*)aReason ranges:(NSIndexSet*)aRanges url:(NSURL*)aUrl urlContentRange:(NSRange)aUrlContentRange
{
  return [self initWithDomain:aDomain reason:aReason ranges:aRanges url:aUrl urlContentRanges:[NSIndexSet indexSetWithIndexesInRange:aUrlContentRange]];
}
//end initWithDomain:reason:ranges:url:urlContentRange:

-(instancetype) initWithDomain:(NSString*)aDomain reason:(NSString*)aReason ranges:(NSIndexSet*)aRanges url:(NSURL*)aUrl urlContentRanges:(NSIndexSet*)aUrlContentRanges
{
  if (!((self = [super initWithDomain:aDomain reason:aReason ranges:aRanges])))
    return nil;
  self->url = [aUrl copy];
  self->urlContentRanges = [aUrlContentRanges mutableCopy];
  return self;
}
//end initWithDomain:reason:ranges:url:urlContentRanges:

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->url = [[aDecoder decodeObjectOfClass:[NSURL class] forKey:@"url"] copy];
  self->urlContentRanges = [[aDecoder decodeObjectOfClass:[NSMutableIndexSet class] forKey:@"urlContentRanges"] copy];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self->url forKey:@"url"];
  [aCoder encodeObject:self->urlContentRanges forKey:@"urlContentRanges"];
}
//end encodeWithCoder:*/

-(void) dealloc
{
  [self->url release];
  [self->urlContentRanges release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone *)zone
{
  CHChalkErrorURLContent* result = [super copyWithZone:zone];
  if (result)
  {
    result->url = [self->url copyWithZone:zone];
    result->urlContentRanges = self->urlContentRanges;
  }//end if (result)
  return result;
}
//end copyWithZone:

-(NSString*) description
{
  NSMutableString* result = [NSMutableString stringWithString:[super description]];
  [result appendFormat:@";%@:", self->urlContentRanges];
  [result appendFormat:@"<%@>", self->url];
  return [[result copy] autorelease];
}
//end description


@end
