//
//  CHConstantDescriptionPresenter.m
//  Chalk
//
//  Created by Pierre Chatelier on 28/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHConstantDescriptionPresenter.h"

#import "CHChalkUtils.h"
#import "CHConstantDescription.h"
#import "CHConstantSymbolManager.h"
#import "CHUnit.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHConstantDescriptionPresenter

@dynamic constantDescription;
@dynamic name;
@dynamic value;
@dynamic uncertainty;
@dynamic richDescription;
@dynamic commonUnitsRichDescriptions;
@dynamic texSymbolImage;

@dynamic selectedUnitRichDescription;

-(instancetype) initWithConstantDescription:(CHConstantDescription*)aConstantDescription constantSymbolManager:(CHConstantSymbolManager*)aConstantSymbolManager;
{
  if (!((self = [super init])))
    return nil;
  self->constantDescription = [aConstantDescription retain];
  self->constantSymbolManager = [aConstantSymbolManager retain];
  NSString* descriptionString = self->constantDescription.description;
  NSArray* components = [descriptionString componentsMatchedByRegex:@"\\$(.*)\\$" options:0 range:descriptionString.range capture:1 error:nil];
  for(NSString* texExpression in components)
    [self->constantSymbolManager submit:texExpression];
  return self;
}
//end initWithConstantDescription:

-(void) dealloc
{
  [self->constantDescription release];
  [self->constantSymbolManager release];
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHConstantDescriptionPresenter* result = [self initWithConstantDescription:self->constantDescription constantSymbolManager:self->constantSymbolManager];
  if (result)
    result->selectedUnitIndex = self->selectedUnitIndex;
  return result;
}
//end copyWithZone:

-(CHConstantDescription*) constantDescription {return [[self->constantDescription retain] autorelease];}
-(NSString*) name {return [self->constantDescription name];}
-(NSString*) value {return [self->constantDescription value];}
-(NSString*) uncertainty {return [self->constantDescription uncertainty];}
-(NSArray<NSAttributedString*>*) commonUnitsRichDescriptions {return [self->constantDescription commonUnitsRichDescriptions];}

-(NSAttributedString*) richDescription
{
  NSAttributedString* result = nil;
  NSString* description = self->constantDescription.description;
  NSMutableAttributedString* rtfd = !description ? nil :
    [[[NSMutableAttributedString alloc] initWithString:self->constantDescription.description attributes:nil] autorelease];
  NSString* rtfdString = rtfd.string;
  NSRange searchRange = rtfdString.range;
  NSRange texExpressionRange = [rtfdString rangeOfRegex:@"\\$(.*)\\$" options:0 inRange:searchRange capture:0 error:nil];
  while(texExpressionRange.length != 0)
  {
    NSString* texExpression = [rtfdString substringWithRange:NSMakeRange(texExpressionRange.location+1, texExpressionRange.length-2)];
    NSDictionary* renderedInformation = nil;
    NSImage* image = !texExpression ? nil : [self->constantSymbolManager imageForTexSymbol:texExpression renderedInformation:&renderedInformation];
    NSData* pdfData = !texExpression ? nil : [self->constantSymbolManager pdfDataForTexSymbol:texExpression];
    NSTextAttachment* textAttachment = !pdfData ? nil : [[[NSTextAttachment alloc] initWithData:pdfData ofType:(NSString*)kUTTypePDF] autorelease];
    textAttachment.image = image;
    NSSize imageSize = {
      [[[renderedInformation objectForKey:@"width"] dynamicCastToClass:[NSNumber class]] doubleValue],
      [[[renderedInformation objectForKey:@"height"] dynamicCastToClass:[NSNumber class]] doubleValue]};
    double baseline = [[[renderedInformation objectForKey:@"baseline"] dynamicCastToClass:[NSNumber class]] doubleValue];
    CGFloat renderingfontSize = [NSFont systemFontSize];
    CGFloat renderingEx = [[NSFont systemFontOfSize:renderingfontSize] xHeight];
    CGSize renderingSize = {imageSize.width*renderingEx, imageSize.height*renderingEx};
    if (!imageSize.width*imageSize.height)
    {
      imageSize = image.size;
      double aspectRatio = !imageSize.height ? 0. : imageSize.width/imageSize.height;
      renderingSize = CGSizeMake(aspectRatio*renderingEx, renderingEx);
    }//end if (!imageSize.width*imageSize.height)
    textAttachment.bounds = NSMakeRect(0, baseline*renderingEx, renderingSize.width, renderingSize.height);
    NSAttributedString* attributedTextAttachement = !textAttachment ? nil : [NSAttributedString attributedStringWithAttachment:textAttachment];
    if (!attributedTextAttachement)
      searchRange = NSMakeRange(NSMaxRange(texExpressionRange), searchRange.length-NSMaxRange(texExpressionRange));
    else//if (attributedTextAttachement)
    {
      [rtfd replaceCharactersInRange:texExpressionRange withAttributedString:attributedTextAttachement];
      rtfdString = rtfd.string;
      searchRange = rtfdString.range;
    }//end if (attributedTextAttachement)
    texExpressionRange = [rtfdString rangeOfRegex:@"\\$(.*)\\$" options:0 inRange:searchRange capture:0 error:nil];
  }//end while(texExpressionRange.length != 0)
  result = [[rtfd copy] autorelease];
  return result;
}
//end richDescription

-(NSAttributedString*) selectedUnitRichDescription
{
  NSAttributedString* result = nil;
  NSArray<NSAttributedString*>* commonUnitsRichDescriptions = [self commonUnitsRichDescriptions];
  if (self->selectedUnitIndex < commonUnitsRichDescriptions.count)
    result = [commonUnitsRichDescriptions objectAtIndex:self->selectedUnitIndex];
  return result;
}
//end selectedUnitRichDescription

-(void) setSelectedUnitRichDescription:(NSAttributedString*)value
{
  NSArray<NSAttributedString*>* commonUnitsRichDescriptions = [self commonUnitsRichDescriptions];
  self->selectedUnitIndex = [commonUnitsRichDescriptions indexOfObjectIdenticalTo:value];
}
//end setSelectedUnitRichDescription

-(NSImage*) texSymbolImage
{
  NSImage* result = [self->constantSymbolManager imageForTexSymbol:self->constantDescription.texSymbol renderedInformation:nil];
  return result;
}
//end texSymbolImage

-(NSArray<NSPasteboardType>*) writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
  return @[NSPasteboardTypeString, CHPasteboardTypeConstantDescriptions];
}
//end writableTypesForPasteboard:

-(nullable id) pasteboardPropertyListForType:(NSPasteboardType)type
{
  id result = nil;
  if ([type isEqualTo:NSPasteboardTypeString])
    result = self.constantDescription.stringValueDescription;
  else if ([type isEqualTo:CHPasteboardTypeConstantDescriptions])
    result = self.constantDescription.plistValueDescription;
  return result;
}
//end pasteboardPropertyListForType:

@end
