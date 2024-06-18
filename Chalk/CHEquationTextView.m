//
//  CHEquationTextView.m
//  Chalk
//
//  Created by Pierre Chatelier on 04/05/2017.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHEquationTextView.h"

@interface CHEquationTextView ()
@property (readonly,copy) NSArray* pasteboardTypesToDelegate;
@end

@implementation CHEquationTextView

@synthesize pasteboardDelegate;
@dynamic pasteboardTypesToDelegate;

-(NSArray*) pasteboardTypesToDelegate
{
  NSArray* result = @[(NSString*)kUTTypePDF, NSURLPboardType, @"public.file-url", NSFilenamesPboardType];
  return result;
}
//end pasteboardTypesToDelegate

-(void) awakeFromNib
{
  [super awakeFromNib];
  NSMutableArray* joinedArrays = [NSMutableArray arrayWithArray:[self registeredDraggedTypes]];
  [joinedArrays addObjectsFromArray:self.pasteboardTypesToDelegate];
  [self registerForDraggedTypes:joinedArrays];
}
//end awakeFromNib

-(BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  BOOL result = [super validateMenuItem:menuItem];
  if (menuItem.action == @selector(paste:))
  {
    if (!result)
    {
      NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
      NSString* type = [pasteboard availableTypeFromArray:self.pasteboardTypesToDelegate];
      result |= (type != nil);
    }//end if (!result)
  }//end if (menuItem.action == @selector(paste:))
  else if (menuItem.action == @selector(copy:))
  {
    result |= YES;
  }//end if (menuItem.action == @selector(copy:))
  return result;
}
//end validateMenuItem:

-(IBAction) copy:(id)sender
{
  [super copy:sender];
  NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
  NSString* type = [pasteboard availableTypeFromArray:@[NSStringPboardType]];
  if (!type)
  {
    BOOL delegated = NO;
    if ([(id)self.pasteboardDelegate respondsToSelector:@selector(copyDelegated:pasteboard:)])
      delegated = [self.pasteboardDelegate copyDelegated:sender pasteboard:pasteboard];
    else if ([(id)self.pasteboardDelegate respondsToSelector:@selector(copy:)])
    {
      [(id)self.pasteboardDelegate copy:sender];
      delegated = YES;
    }//end if ([self.pasteboardDelegate respondsToSelector:@selector(copy:)])
  }//end if (!type)
}
//end copy:

-(IBAction) paste:(id)sender
{
  NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
  NSString* type = [pasteboard availableTypeFromArray:self.pasteboardTypesToDelegate];
  BOOL delegated = NO;
  if (type)
  {
    if ([(id)self.pasteboardDelegate respondsToSelector:@selector(pasteDelegated:pasteboard:)])
      delegated = [self.pasteboardDelegate pasteDelegated:sender pasteboard:pasteboard];
    else if ([(id)self.pasteboardDelegate respondsToSelector:@selector(paste:)])
    {
      [(id)self.pasteboardDelegate paste:sender];
      delegated = YES;
    }//end if ([self.pasteboardDelegate respondsToSelector:@selector(paste:)])
  }//end if (type)
  if (!delegated)
    [super paste:sender];
}
//end paste:

@end
