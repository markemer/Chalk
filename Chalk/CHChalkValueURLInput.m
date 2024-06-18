//
//  CHChalkValueURLInput.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueURLInput.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkErrorURLContent.h"
#import "CHChalkToken.h"
#import "CHParser.h"
#import "CHParserContext.h"
#import "CHParserNode.h"
#import "NSObjectExtended.h"

@implementation CHChalkValueURLInput

@synthesize urlValue;

+(BOOL) supportsSecureCoding {return YES;}

-(instancetype) initWithCoder:(NSCoder*)aDecoder
{
  if (!((self = [super initWithCoder:aDecoder])))
    return nil;
  self->urlValue = [[aDecoder decodeObjectOfClass:[CHChalkValue class] forKey:@"urlValue"] retain];
  return self;
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self->urlValue forKey:@"urlValue"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkValueURLInput* result = [super copyWithZone:zone];
  if (result)
  {
    [result->urlValue release];
    result->urlValue = [self->urlValue copyWithZone:zone];
  }//end if (result)
  return result;
}
//end copyWithZone:

-(BOOL) moveTo:(CHChalkValue*)dst
{
  BOOL result = [super moveTo:dst];
  CHChalkValueURLInput* dstURLInput = !result ? nil : [dst dynamicCastToClass:[CHChalkValueURLInput class]];
  if (result && dstURLInput)
  {
    [dstURLInput->urlValue release];
    dstURLInput->urlValue = self->urlValue;
    self->urlValue = nil;
  }//end if (result && dstURLInput)
  return result;
}
//end moveTo:

-(void) dealloc
{
  [self->urlValue release];
  self->urlValue = nil;
  [super dealloc];
}
//end dealloc

-(void) performEvaluationWithContext:(CHChalkContext*)context
{
  [self->urlValue release];
  self->urlValue = nil;
  if (!context.errorContext.hasError)
  {
    if (!self->url)
      [context.errorContext setError:
        [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainDataAccess reason:CHChalkErrorDataOpen range:self->token.range]
        replace:NO];
    else//if (self->url)
    {
      CHParserNode* parserRootNode = nil;
      CHParser* parser = [[CHParser alloc] init];
      if (!self->url.isFileReferenceURL && !self->url.fileURL)
      {
        NSError* error = nil;
        NSData* data = [NSData dataWithContentsOfURL:self->url options:NSDataReadingUncached error:&error];
        if (!data)
          [context.errorContext setError:
            [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainDataAccess reason:CHChalkErrorDataOpen range:self->token.range]
            replace:NO];
        else if (data)
        {
          NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          [parser parseTo:parser fromString:string context:context];
          [string release];
        }//end if (data)
      }//end if (!self->url.isFileReferenceURL && !self->url.fileURL)
      else//if (self->url.isFileReferenceURL && self->fileURL)
      {
        const char* filePath = [self->url fileSystemRepresentation];
        int fd = open(filePath, O_RDONLY);
        if (fd<0)
          [context.errorContext setError:
            [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainDataAccess reason:CHChalkErrorDataOpen range:self->token.range]
            replace:NO];
        else//if (fd>=0)
        {
          [parser parseTo:parser fromFileDescriptor:fd context:context];
          close(fd);
        }//end if (fd>=0)
      }//end if (self->url.isFileReferenceURL && self->fileURL)
      parserRootNode = [parser.rootNodes.firstObject retain];
      if (parserRootNode)
      {
        [parserRootNode performEvaluationWithContext:context lazy:YES];
        self->urlValue = [parserRootNode.evaluatedValue retain];
        [parserRootNode release];
      }//end if (parserRootNode)
      else if (context.errorContext.hasError)
      {
        CHChalkError* prevError = context.errorContext.error;
        CHChalkErrorURLContent* newError = [[CHChalkErrorURLContent alloc] initWithDomain:prevError.domain reason:prevError.reason range:token.range url:url urlContentRanges:prevError.ranges];
        if (newError)
          [context.errorContext setError:newError replace:YES];
        [newError release];
      }//end if (context.errorContext.hasError)
      [parser release];
    }//end if (self->url)
  }//end else if (operand1String)
}
//end performEvaluationWithContext:

@end
