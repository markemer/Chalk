//
//  CHConstantSymbolManager.m
//  Chalk
//
//  Created by Pierre Chatelier on 28/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHConstantSymbolManager.h"

#import "CHUtils.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHConstantSymbolManager

@synthesize delegate;

+(instancetype) sharedManager
{
  static CHConstantSymbolManager* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      instance = [[CHConstantSymbolManager alloc] init];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sharedManager

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  self->texImages = [[NSMutableDictionary alloc] init];
  self->renderQueue = [[NSMutableArray alloc] init];
  self->renderer = [[CHSVGRenderer alloc] init];
  self->renderer.renderScale = 1./50;
  self->renderer.delegate = self;
  return self;
}
//end init

-(void) dealloc
{
  self.delegate = nil;
  [self->renderer release];
  [self->texImages release];
  [self->renderQueue release];
  [super dealloc];
}
//end dealloc

-(NSImage*) imageForTexSymbol:(NSString*)symbol renderedInformation:(NSDictionary**)outRenderedInformation;
{
  NSImage* result = nil;
  if (![NSString isNilOrEmpty:symbol])
  {
    @synchronized(self->texImages)
    {
      NSDictionary* imageDict = [self->texImages objectForKey:symbol];
      result = [[[imageDict objectForKey:@"image"] retain] autorelease];
      if (outRenderedInformation && result)
      {
        NSDictionary* renderedInformation = [[[[imageDict objectForKey:@"renderedInformation"] retain] autorelease] dynamicCastToClass:[NSDictionary class]];
        *outRenderedInformation = [[renderedInformation copy] autorelease];
      }//end if (outRenderedInformation && result)
    }//end @synchronized(self->texImages)
    if (!result)
      [self submit:symbol];
  }//end if (![NSString isNilOrEmpty:symbol])
  return result;
}
//end imageForTexSymbol:renderedInformation:

-(NSData*) pdfDataForTexSymbol:(NSString*)symbol
{
  NSData* result = nil;
  if (![NSString isNilOrEmpty:symbol])
  {
    @synchronized(self->texImages)
    {
      NSDictionary* imageDict = [self->texImages objectForKey:symbol];
      result = [[[imageDict objectForKey:@"pdfData"] retain] autorelease];
    }//end @synchronized(self->texImages)
    if (!result)
      [self submit:symbol];
  }//end if (![NSString isNilOrEmpty:symbol])
  return result;
}
//end pdfDataForTexSymbol:

-(void) submit:(NSString*)symbol
{
  if (![NSString isNilOrEmpty:symbol])
  {
    BOOL isAlreadyRendering = NO;
    @synchronized(self->renderQueue)
    {
      isAlreadyRendering = [self->renderQueue containsObject:symbol];
      if (!isAlreadyRendering)
        [self->renderQueue addObject:symbol];
    }//end @synchronized(self->renderQueue)
    if (!isAlreadyRendering)
      [self->renderer render:symbol foregroundColor:[NSColor controlTextColor] format:CHALK_EXPORT_FORMAT_PDF metadata:nil feedPasteboard:NO];
  }//end if (![NSString isNilOrEmpty:symbol])
}
//end submit:

-(void) svgRenderer:(CHSVGRenderer*)renderer didEndRender:(chalk_export_format_t)format
{
  NSData* pdfData = [[self->renderer.lastPDFData copy] autorelease];
  NSDictionary* renderedInformation = [[self->renderer.lastRenderedInformation copy] autorelease];
  NSImage* image = !pdfData ? nil : [[[NSImage alloc] initWithData:pdfData] autorelease];
  if (image)
  {
    NSString* symbol = nil;
    @synchronized(self->renderQueue)
    {
      symbol = self->renderQueue.firstObject;
    }//end @synchronized(self->renderQueue)
    if (symbol)
    {
      @synchronized(self->texImages)
      {
        [self->texImages setObject:@{@"pdfData":pdfData, @"image":image, @"renderedInformation":!renderedInformation ? [NSNull null] : renderedInformation} forKey:symbol];
      }//end @synchronized(self->texImages)
      @synchronized(self->renderQueue)
      {
        [self->renderQueue removeObject:symbol];
      }//end @synchronized(self->renderQueue)
      [self->delegate constantSymbolManager:self didEndRenderTexSymbol:symbol];
    }//end if (symbol)
  }//end if (image)
}
//end svgRenderer:didEndRender:

@end
