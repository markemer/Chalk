//
//  CHEquationDocument.m
//  Chalk
//
//  Created by Pierre Chatelier on 12/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHEquationDocument.h"

#import "CHAppDelegate.h"
#import "CHUtils.h"
#import "CHEquationImageView.h"
#import "CHEquationTextView.h"

#import "NSColorExtended.h"
#import "NSObjectExtended.h"
#import "NSViewExtended.h"

#import <stdio.h>

@interface CHEquationDocument ()
-(void) updateControls;
@end

@implementation CHEquationDocument

+(NSString*) defaultDocumentType
{
  NSString* result = [NSString stringWithFormat:@"%@_Plist", NSStringFromClass([self class])];
  return result;
}
//end defaultDocumentType

-(id) init
{
  if (!((self = [super init])))
    return nil;
    dispatch_async(dispatch_get_main_queue(), ^() {
  self->mathMLRenderer = [[CHMathMLRenderer alloc] init];
  self->mathMLRenderer.delegate = self;
  });
  dispatch_async(dispatch_get_main_queue(), ^() {
  self->svgRenderer = [[CHSVGRenderer alloc] init];
  self->svgRenderer.delegate = self;
  });
  return self;
}
//end init

-(void) dealloc
{
  [self->loadedEquationGeneratorDict release];
  self->svgRenderer.delegate = nil;
  [self->svgRenderer release];
  [super dealloc];
}
//end dealloc

-(NSString*) windowNibName
{
  return @"CHEquationDocument";
}
//end windowNibName

-(void) windowControllerDidLoadNib:(NSWindowController *)windowController
{
  self->inputTextView.string = @"%some TeX code\n\\frac{1}{2}";
  self->inputTextView.pasteboardDelegate = self->imageView;
  self->renderButton.title = NSLocalizedString(@"Render", @"");
  [self->renderButton sizeToFit];
  [self->renderButton centerInParentHorizontally:YES vertically:NO];
  self->imageView.document = self;
  
  if (self->loadedEquationGeneratorDict)
  {
    NSString* version = [[self->loadedEquationGeneratorDict objectForKey:@"version"] dynamicCastToClass:[NSString class]];
    DebugLog(1, @"version = %@", version);
    NSData* colorAsData = [[self->loadedEquationGeneratorDict objectForKey:@"colorData"] dynamicCastToClass:[NSData class]];
    NSColor* color = !colorAsData ? nil :[NSColor colorWithData:colorAsData];
    NSString* inputString = [[self->loadedEquationGeneratorDict objectForKey:@"inputString"] dynamicCastToClass:[NSString class]];
    if (inputString)
      self->inputTextView.string = inputString;
    if (color)
      self->foregroundColorColorWell.color = color;
    [self->loadedEquationGeneratorDict release];
    self->loadedEquationGeneratorDict = nil;
    if (inputString)
      [self renderAction:self];
  }//end if (self->loadedEquationGeneratorDict)
}
//end windowControllerDidLoadNib:

-(BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  BOOL result = [super validateMenuItem:menuItem];
  if (menuItem.action == @selector(runPageLayout:))
  {
    menuItem.title = NSLocalizedString(@"Page Setup...", @"");
    result = NO;
  }//end if (menuItem.action == @selector(runPageLayout:))
  else if (menuItem.action == @selector(printDocument:))
  {
    menuItem.title = NSLocalizedString(@"Print...", @"");
    result = NO;
  }//end if (menuItem.action == @selector(printDocument:))
  else if (menuItem.action == @selector(renderEquationDocument:))
  {
    result = (self->inputTextView.string.length != 0);
  }//end if (menuItem.action == @selector(renderEquationDocument:))
  return result;
}
//end validateMenuItem:

+(BOOL) autosavesInPlace
{
  return NO;
}
//end autosavesInPlace

+(BOOL) autosavesDrafts
{
  return YES;
}
//end autosavesDrafts

-(BOOL) readFromURL:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError
{
  BOOL result = NO;
  NSData* data = !url ? nil : [NSData dataWithContentsOfURL:url];
  NSPropertyListFormat propertyListFormat = NSPropertyListBinaryFormat_v1_0;
  id plist = !data ? nil : [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&propertyListFormat error:outError];
  NSDictionary* dict = [plist dynamicCastToClass:[NSDictionary class]];
  NSDictionary* chalkDict = [[dict objectForKey:@"chalk"] dynamicCastToClass:[NSDictionary class]];
  NSDictionary* equationGeneratorDict = [[chalkDict objectForKey:@"equationGenerator"] dynamicCastToClass:[NSDictionary class]];
  [self->loadedEquationGeneratorDict release];
  self->loadedEquationGeneratorDict = [equationGeneratorDict copy];
  result = (equationGeneratorDict != nil);
  return result;
}
//end readFromURL:ofType:error:

-(BOOL) writeToURL:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError
{
  BOOL result = NO;
  NSMutableDictionary* equationGeneratorDict = [NSMutableDictionary dictionary];
  NSString* version = [[NSBundle mainBundle].infoDictionary objectForKey:(NSString*)kCFBundleVersionKey];
  if (version)
    [equationGeneratorDict setObject:version forKey:@"version"];
  NSData* colorData = self->foregroundColorColorWell.color.colorAsData;
  if (colorData)
    [equationGeneratorDict setObject:colorData forKey:@"colorData"];
  NSString* inputString = self->inputTextView.string;
  if (inputString)
    [equationGeneratorDict setObject:inputString forKey:@"inputString"];
  NSDictionary* dict = !equationGeneratorDict ? nil :
    @{
      @"chalk":@{
        @"equationGenerator":equationGeneratorDict
      }
    };
  NSData* plistData = !dict ? nil :
    [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 options:0 error:outError];
  result = [plistData writeToURL:url atomically:YES];
  return result;
}
//end writeToURL:ofType:error:

-(IBAction) renderAction:(id)sender
{
  NSString* inputString = self->inputTextView.string;
  NSColor* foregroundColor = self->foregroundColorColorWell.color;
  NSData* metadata = [CHSVGRenderer metadataFromInputString:inputString foregroundColor:foregroundColor];
  [self->mathMLRenderer render:inputString foregroundColor:foregroundColor format:CHALK_EXPORT_FORMAT_PDF metadata:metadata feedPasteboard:NO];
  [self->svgRenderer render:inputString foregroundColor:foregroundColor format:CHALK_EXPORT_FORMAT_PDF metadata:metadata feedPasteboard:NO];
}
//end renderAction:

-(void) svgRenderer:(CHSVGRenderer*)renderer didEndRender:(chalk_export_format_t)format;
{
  dispatch_after(0, dispatch_get_main_queue(), ^{
    NSString* svgString = renderer.lastSvgString;
    NSData* pdfData = renderer.lastPDFData;
    NSImage* image = [[[NSImage alloc] initWithData:pdfData] autorelease];
    imageView.svgString = svgString;
    imageView.pdfData = pdfData;
    [imageView setImage:image];
    [self updateControls];
  });
}
//end svgRenderer:didEndRender:

-(void) mathMLRenderer:(CHMathMLRenderer*)renderer didEndRender:(chalk_export_format_t)format;
{
  dispatch_after(0, dispatch_get_main_queue(), ^{
    NSString* mathMLString = renderer.lastMathMLString;
    imageView.mathMLString = mathMLString;
    [self updateControls];
  });
}
//end mathMLRenderer:didEndRender:

-(void) updateControls
{
  NSString* lastErrorString = self->svgRenderer.lastErrorString;
  self->errorTextField.hidden = !lastErrorString.length;
  self->errorTextField.stringValue = !lastErrorString ? @"" : lastErrorString;
}
//end updateControls

-(IBAction) copy:(id)sender
{
  [self->imageView copy:sender];
}
//end copy:

-(IBAction) paste:(id)sender
{
  [self->imageView paste:sender];
}
//end paste:

-(BOOL) applyState:(NSData*)pdfData
{
  BOOL result = NO;
  NSDictionary* metadata = nil;
  if (!metadata)
    metadata = [CHSVGRenderer chalkMetadataFromPDFData:pdfData];
  NSString* inputString = [[metadata objectForKey:@"inputString"] dynamicCastToClass:[NSString class]];
  NSData* foregroundColorAsData = [[metadata objectForKey:@"foregroundColor"] dynamicCastToClass:[NSData class]];
  NSColor* foregroundColor = [NSColor colorWithData:foregroundColorAsData];
  if (inputString)
    self->inputTextView.string = inputString;
  if (foregroundColor)
    self->foregroundColorColorWell.color = foregroundColor;
  NSImage* image = !pdfData ? nil : [[[NSImage alloc] initWithData:pdfData] autorelease];
  if (image)
    self->imageView.image = image;
  result = inputString || foregroundColor || image;
  return result;
}
//end applyState:

@end
