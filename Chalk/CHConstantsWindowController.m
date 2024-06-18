//  CHConstantsWindowController.m
// Chalk
//
//  Created by Pierre Chatelier on 1/04/05.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.

#import "CHConstantsWindowController.h"

#import "CHAppDelegate.h"
#import "CHCalculatorDocument.h"
#import "CHChalkUtils.h"
#import "CHTextFieldCell.h"
#import "CHConstantDescription.h"
#import "CHConstantDescriptionPresenter.h"
#import "CHConstantsProvider.h"
#import "CHConstantsProviderManager.h"
#import "CHGenericTransformer.h"
#import "CHUnit.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@interface CHConstantsWindowController ()
-(NSArray*) constantDescriptionsFromSelection:(NSArray**)outStringDescriptions;
-(NSArray*) constantDescriptionsFromIndices:(NSIndexSet*)indices outStringDescriptions:(NSArray**)outStringDescriptions;
-(void) updateConstantsController;
-(void) updateControls;
-(void) windowEventOccured:(NSNotification*)notification;
@end

@implementation CHConstantsWindowController

-(id) init
{
  if ((!(self = [super initWithWindowNibName:@"CHConstantsWindowController"])))
    return nil;
  self->constantSymbolManager = [[CHConstantSymbolManager sharedManager] retain];
  self->constantSymbolManager.delegate = self;
  self->constantsProviderManager = [[CHConstantsProviderManager sharedConstantsProviderManager] retain];
  self->constantsProvidersArrayController = [[NSArrayController alloc] init];
  self->constantsProvidersArrayController.automaticallyRearrangesObjects = YES;
  self->constantsProvidersArrayController.objectClass = [CHConstantsProvider class];
  self->constantsArrayController = [[NSArrayController alloc] init];
  self->constantsArrayController.automaticallyRearrangesObjects = YES;
  self->constantsProvidersArrayController.objectClass = [CHConstantDescriptionPresenter class];
  [self->constantsProvidersArrayController addObjects:self->constantsProviderManager.constantsProviders];
  return self;
}
//end init

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->constantSymbolManager release];
  [self->constantsArrayController release];
  [self->constantsProvidersArrayController release];
  [self->constantsProviderManager release];
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  [super awakeFromNib];
  
  self.window.title = NSLocalizedString(@"Constants manager", @"");
  
  [self->constantsProvidersComboBox bind:NSContentValuesBinding toObject:self->constantsProvidersArrayController withKeyPath:@"arrangedObjects.nameNotEmpty" options:nil];
  [self->constantsProvidersComboBox bind:NSEnabledBinding toObject:self->constantsProvidersArrayController withKeyPath:@"arrangedObjects" options:@{NSValueTransformerBindingOption:[CHGenericTransformer transformerWithBlock:^id(id object) {
      return [NSNumber numberWithBool:([[object dynamicCastToClass:[NSArray class]] count] > 1)];
    } reverse:nil]}];
    
  self->constantsProvidersLoadButton.title = [NSString stringWithFormat:@"%@...", NSLocalizedString(@"Load", "")];
  [self->constantsProvidersLoadButton sizeToFit];
  self->constantsProvidersLoadButton.hidden = YES;
  
  [self->constantsTableView setDelegate:self];
  [self->constantsTableView setDataSource:self];
  for(NSTableColumn* tableColumn in self->constantsTableView.tableColumns)
  {
    tableColumn.title = NSLocalizedString([tableColumn.identifier capitalizedString], @"");
    tableColumn.headerCell.alignment = NSTextAlignmentCenter;
  }

  NSTableColumn* tableColumn = nil;
  tableColumn = [self->constantsTableView tableColumnWithIdentifier:@"name"];
  tableColumn.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:tableColumn.identifier ascending:YES comparator:^(id  _Nonnull obj1, id  _Nonnull obj2) {
      NSComparisonResult result = NSOrderedSame;
      NSString* string1 = [obj1 dynamicCastToClass:[NSString class]];
      NSString* string2 = [obj2 dynamicCastToClass:[NSString class]];
      result = !string1 && !string2 ? NSOrderedSame :
        !string1 ? NSOrderedAscending :
        !string2 ? NSOrderedDescending :
        [string1 compare:string2 options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
      return result;
  }];
  tableColumn = [self->constantsTableView tableColumnWithIdentifier:@"units"];
  tableColumn.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:@"selectedUnitRichDescription" ascending:YES comparator:^(id  _Nonnull obj1, id  _Nonnull obj2) {
      NSComparisonResult result = NSOrderedSame;
      NSString* string1 = [[obj1 dynamicCastToClass:[NSAttributedString class]] string];
      NSString* string2 = [[obj2 dynamicCastToClass:[NSAttributedString class]] string];
      result = !string1 && !string2 ? NSOrderedSame :
        !string1 ? NSOrderedAscending :
        !string2 ? NSOrderedDescending :
        [string1 compare:string2 options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
      return result;
  }];
  tableColumn = [self->constantsTableView tableColumnWithIdentifier:@"value"];
  tableColumn.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:tableColumn.identifier ascending:YES comparator:^(id  _Nonnull obj1, id  _Nonnull obj2) {
      NSComparisonResult result = NSOrderedSame;
      NSString* string1 = [obj1 dynamicCastToClass:[NSString class]];
      NSString* string2 = [obj2 dynamicCastToClass:[NSString class]];
      result = [@(string1.doubleValue) compare:@(string2.doubleValue)];
      return result;
  }];
  tableColumn = [self->constantsTableView tableColumnWithIdentifier:@"uncertainty"];
  tableColumn.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:tableColumn.identifier ascending:YES comparator:^(id  _Nonnull obj1, id  _Nonnull obj2) {
      NSComparisonResult result = NSOrderedSame;
      NSString* string1 = [obj1 dynamicCastToClass:[NSString class]];
      NSString* string2 = [obj2 dynamicCastToClass:[NSString class]];
      result = [@(string1.doubleValue) compare:@(string2.doubleValue)];
      return result;
  }];

  [self->constantsTableView bind:NSContentBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects" options:nil];
  [self->constantsTableView bind:NSSelectionIndexesBinding toObject:self->constantsArrayController withKeyPath:@"selectionIndexes" options:nil];
  [self->constantsArrayController bind:NSSortDescriptorsBinding toObject:self->constantsTableView withKeyPath:@"sortDescriptors" options:nil];
  [self->constantsArrayController setSortDescriptors:@[[self->constantsTableView tableColumnWithIdentifier:@"name"].sortDescriptorPrototype]];

  [[self->constantsTableView tableColumnWithIdentifier:@"name"] bind:NSValueBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects.name" options:nil];
  [[self->constantsTableView tableColumnWithIdentifier:@"value"] bind:NSValueBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects.value" options:nil];
  [[self->constantsTableView tableColumnWithIdentifier:@"uncertainty"] bind:NSValueBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects.uncertainty" options:nil];
  [[self->constantsTableView tableColumnWithIdentifier:@"units"] bind:NSContentValuesBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects.commonUnitsRichDescriptions" options:nil];
  [[self->constantsTableView tableColumnWithIdentifier:@"units"] bind:NSValueBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects.selectedUnitRichDescription" options:nil];
  [[self->constantsTableView tableColumnWithIdentifier:@"units"] bind:NSEnabledBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects.commonUnitsRichDescriptions.@count" options:@{NSValueTransformerBindingOption:
              [CHGenericTransformer transformerWithBlock:^id(id value) {
                NSNumber* count = [value dynamicCastToClass:[NSNumber class]];
                return @([count unsignedIntegerValue]>1);
              } reverse:nil]}];
  [[self->constantsTableView tableColumnWithIdentifier:@"symbol"] bind:NSValueBinding toObject:self->constantsArrayController withKeyPath:@"arrangedObjects.texSymbolImage" options:nil];
  [[self->constantsTableView tableColumnWithIdentifier:@"symbol"] sizeToFit];
  [self->constantRichDescriptionTextField bind:NSValueBinding toObject:self->constantsArrayController withKeyPath:@"selection.richDescription" options:nil];
  
  self->constantsAddToCurrentCalculatorDocumentButton.title = NSLocalizedString(@"Add selection to current calculator document", "");
  [self->constantsAddToCurrentCalculatorDocumentButton sizeToFit];
  NSRect frame = self->constantsAddToCurrentCalculatorDocumentButton.frame;
  frame.origin.x = (self->constantsAddToCurrentCalculatorDocumentButton.superview.frame.size.width-frame.size.width)/2;
  self->constantsAddToCurrentCalculatorDocumentButton.frame = frame;
  
  if (self->constantsProviderManager.constantsProviders.count > 0)
  {
    [self->constantsProvidersComboBox selectItemAtIndex:0];
    [self updateConstantsController];
  }//end if (self->constantsProviderManager.constantsProviders.count > 0)
  
  [self updateControls];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowEventOccured:) name:NSApplicationDidUpdateNotification object:NSApp];
}
//end awakeFromNib

-(void) windowEventOccured:(NSNotification*)notification
{
  [self updateControls];
}
//end windowEventOccured:

-(void) updateControls
{
  CHCalculatorDocument* calculatorDocument = [CHAppDelegate appDelegate].currentCalculatorDocument;
  NSUInteger selectedConstantsDescriptionPresenters = self->constantsArrayController.selectedObjects.count;
  self->constantsAddToCurrentCalculatorDocumentButton.enabled =
    calculatorDocument && (selectedConstantsDescriptionPresenters > 0);
}
//end updateControls

-(IBAction) constantsProviderLoad:(id)sender
{
  NSOpenPanel* openPanel = [NSOpenPanel openPanel];
  openPanel.canChooseDirectories = NO;
  openPanel.canChooseFiles = YES;
  openPanel.allowsMultipleSelection = YES;
  [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
    if (result == NSModalResponseOK)
    {
      CHConstantsProvider* lastNewConstantProvider = nil;
      for(NSURL* url in openPanel.URLs)
      {
        CHConstantsProvider* constantsProvider = [[[CHConstantsProvider alloc] initWithURL:url] autorelease];
        if (constantsProvider)
        {
          lastNewConstantProvider = constantsProvider;
          [self->constantsProvidersArrayController addObject:constantsProvider];
        }//end if (constantsProvider)
      }//end for each URL
      if (lastNewConstantProvider)
      {
        [self->constantsProvidersComboBox selectItemAtIndex:[[self->constantsProvidersArrayController arrangedObjects] indexOfObject:lastNewConstantProvider]];
        [self updateConstantsController];
      }//end if (lastNewConstantProvider)
    }//end if (result == NSModalResponseOK)
  }];
}
//end constantsProviderLoad:

-(IBAction) constantsProviderChanged:(id)sender
{
  if (sender == self->constantsProvidersComboBox)
    [self updateConstantsController];
}
//end constantsProviderChanged:

-(IBAction) constantsSearchFieldChanged:(id)sender
{
  NSSearchField* searchField = [sender dynamicCastToClass:[NSSearchField class]];
  NSArray* components = [searchField.stringValue componentsSeparatedByRegex:@"\\s"];
  NSPredicate* predicate = !components.count ? nil :
    [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
    BOOL result = NO;
    CHConstantDescriptionPresenter* constantsDescriptionPresenter = [evaluatedObject dynamicCastToClass:[CHConstantDescriptionPresenter class]];
    for(NSString* pattern in components)
    {
      result |= ([constantsDescriptionPresenter.name rangeOfString:pattern options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location != NSNotFound);
      if (result)
        break;
    }//end for each pattern
    return result;
  }];
  self->constantsArrayController.filterPredicate = predicate;
}
//end constantsSearchFieldChanged:

-(void) updateConstantsController
{
  [self->constantsArrayController setContent:nil];
  CHConstantsProvider* constantsProvider = [self->constantsProvidersArrayController.arrangedObjects objectAtIndex:[self->constantsProvidersComboBox indexOfSelectedItem]]; 
  for(CHConstantDescription* constantDescription in constantsProvider.constantDescriptions)
  {
    CHConstantDescriptionPresenter* constantDescriptionPresenter =
      [[[CHConstantDescriptionPresenter alloc] initWithConstantDescription:constantDescription constantSymbolManager:constantSymbolManager] autorelease];
    if (constantDescriptionPresenter)
      [self->constantsArrayController addObject:constantDescriptionPresenter];
  }//end for each constantDescription
  
  NSMutableString* informationString = [NSMutableString string];
  NSString* author = constantsProvider.author;
  NSString* version = constantsProvider.version;
  [informationString appendFormat:@"%@:", NSLocalizedString(@"author", "")];
  [informationString appendString:![NSString isNilOrEmpty:author] ? author : @"-"];
  [informationString appendString:@"\t"];
  [informationString appendFormat:@"%@:", NSLocalizedString(@"version", "")];
  [informationString appendString:![NSString isNilOrEmpty:version] ? version : @"-"];

  self->constantsProviderInfoTextField.stringValue = [[informationString copy] autorelease];
  [self->constantsProviderInfoTextField sizeToFit];
}
//end updateConstantsController

//initializes the controls with default values
-(void) windowDidLoad
{
}
//end windowDidLoad

-(void) windowWillClose:(NSNotification *)aNotification
{
}
//end windowWillClose:

-(void) constantSymbolManager:(CHConstantSymbolManager*)constantSymbolManager didEndRenderTexSymbol:(NSString*)texSymbol
{
  bool shouldUpdate = OSAtomicCompareAndSwap32(0, 1, &self->reloadDataLevel);
  if (shouldUpdate)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self->constantsTableView reloadData];
      OSAtomicCompareAndSwap32(1, 0, &self->reloadDataLevel);
    });
  }//end if (shouldUpdate)
}
//end constantSymbolManager:didEndRenderTexSymbol:

-(BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  BOOL result = YES;
  if ([menuItem action] == @selector(copy:))
  {
    NSArray* selectedConstantsDescriptionPresenters = self->constantsArrayController.selectedObjects;
    result = (selectedConstantsDescriptionPresenters.count > 0);
  }//end if ([menuItem action] == @selector(copy:))
  return result;
}
//end validateMenuItem:

-(IBAction) copy:(id)sender
{
  NSArray* constantDescriptionsStrings = nil;
  NSArray* constantDescriptionsPlists = [self constantDescriptionsFromSelection:&constantDescriptionsStrings];
  if (constantDescriptionsStrings || constantDescriptionsPlists)
  {
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    if (constantDescriptionsStrings)
    {
      [pboard addTypes:@[NSPasteboardTypeString] owner:nil];
      [pboard setString:[constantDescriptionsStrings componentsJoinedByString:@"\n"] forType:NSPasteboardTypeString];
    }//end if (constantDescriptionsStrings)
    if (constantDescriptionsPlists)
    {
      [pboard addTypes:@[CHPasteboardTypeConstantDescriptions] owner:nil];
      [pboard setPropertyList:constantDescriptionsPlists forType:CHPasteboardTypeConstantDescriptions];
    }//end if (constantDescriptionsPlists)
  }//end if (constantDescriptionsStrings || constantDescriptionsPlists)
}
//end copy:

-(NSArray*) constantDescriptionsFromSelection:(NSArray**)outStringDescriptions
{
  NSArray* result = nil;
  NSArray* selectedConstantsDescriptionPresenters = self->constantsArrayController.selectedObjects;
  NSMutableArray* constantDescriptionsStrings = !selectedConstantsDescriptionPresenters.count ? nil :
    [NSMutableArray arrayWithCapacity:selectedConstantsDescriptionPresenters.count];
  NSMutableArray* constantDescriptionsPlists = !selectedConstantsDescriptionPresenters.count ? nil :
    [NSMutableArray arrayWithCapacity:selectedConstantsDescriptionPresenters.count];
  for(CHConstantDescriptionPresenter* constantDescriptionPresenter in selectedConstantsDescriptionPresenters)
  {
    CHConstantDescription* constantDescription = constantDescriptionPresenter.constantDescription;
    NSString* stringValueDescription = constantDescription.stringValueDescription;
    id plistValueDescription = constantDescription.plistValueDescription;
    [constantDescriptionsStrings safeAddObject:stringValueDescription];
    [constantDescriptionsPlists safeAddObject:plistValueDescription];
  }//end constantDescriptionPresenter
  if (outStringDescriptions)
    *outStringDescriptions = [[constantDescriptionsStrings copy] autorelease];
  result = [[constantDescriptionsPlists copy] autorelease];
  return result;
}
//end constantDescriptionsFromSelection:

-(NSArray*) constantDescriptionsFromIndices:(NSIndexSet*)indices outStringDescriptions:(NSArray**)outStringDescriptions
{
  NSArray* result = nil;
  NSArray* selectedConstantsDescriptionPresenters = [[self->constantsArrayController arrangedObjects] objectsAtIndexes:indices];
  NSMutableArray* constantDescriptionsStrings = !selectedConstantsDescriptionPresenters.count ? nil :
    [NSMutableArray arrayWithCapacity:selectedConstantsDescriptionPresenters.count];
  NSMutableArray* constantDescriptionsPlists = !selectedConstantsDescriptionPresenters.count ? nil :
    [NSMutableArray arrayWithCapacity:selectedConstantsDescriptionPresenters.count];
  for(CHConstantDescriptionPresenter* constantDescriptionPresenter in selectedConstantsDescriptionPresenters)
  {
    CHConstantDescription* constantDescription = constantDescriptionPresenter.constantDescription;
    NSString* stringValueDescription = constantDescription.stringValueDescription;
    id plistValueDescription = constantDescription.plistValueDescription;
    [constantDescriptionsStrings safeAddObject:stringValueDescription];
    [constantDescriptionsPlists safeAddObject:plistValueDescription];
  }//end constantDescriptionPresenter
  if (outStringDescriptions)
    *outStringDescriptions = [[constantDescriptionsStrings copy] autorelease];
  result = [[constantDescriptionsPlists copy] autorelease];
  return result;
}
//end constantDescriptionsFromSelection:

-(IBAction) constantsAddToCurrentCalculatorDocument:(id)sender
{
  CHCalculatorDocument* calculatorDocument = [CHAppDelegate appDelegate].currentCalculatorDocument;
  if (calculatorDocument)
  {
    NSArray* constantDescriptionsPlists = [self constantDescriptionsFromSelection:nil];
    [calculatorDocument addConstantUserVariableItems:constantDescriptionsPlists];
  }//end if (calculatorDocument)
}
//end constantsAddToCurrentCalculatorDocument:

-(IBAction) doubleClick:(id)sender
{
  if (sender == self->constantsTableView)
  {
    CHCalculatorDocument* calculatorDocument = [CHAppDelegate appDelegate].currentCalculatorDocument;
    if (calculatorDocument)
    {
      NSInteger clickedRow = self->constantsTableView.clickedRow;
      NSIndexSet* indices = (clickedRow<0) ? nil : [NSIndexSet indexSetWithIndex:clickedRow];
      NSArray* constantDescriptionsPlists = [self constantDescriptionsFromIndices:indices outStringDescriptions:nil];
      [calculatorDocument addConstantUserVariableItems:constantDescriptionsPlists];
    }//end if (calculatorDocument)
  }//end if (sender == self->constantsTableView)
}
//end doubleClick:

#pragma mark NSTableViewDelegate

-(void) tableViewSelectionDidChange:(NSNotification*)notification
{
  if (notification.object == self->constantsTableView)
    [self updateControls];
}
//end tableViewSelectionDidChange:

-(nullable NSCell*) tableView:(NSTableView *)tableView dataCellForTableColumn:(nullable NSTableColumn*)tableColumn row:(NSInteger)row
{
  NSCell* result = nil;
  if (tableView == self->constantsTableView)
  {
    if (!tableColumn){
    }
    else if ([tableColumn.identifier isEqualToString:@"units"])
    {
      CHConstantDescriptionPresenter* constantDescriptionPresenter = [self->constantsArrayController.arrangedObjects objectAtIndex:row];
      NSArray<NSAttributedString*>* commonUnitsRichDescriptions = constantDescriptionPresenter.commonUnitsRichDescriptions;
      if (commonUnitsRichDescriptions.count > 1)
        result = nil;
      else//if (commonUnitsRichDescriptions.count < 1)
        result = [[[CHTextFieldCell alloc] init] autorelease];
    }//end if ([tableColumn.identifier isEqualToString:@"units"])
  }//end if (tableView == self->constantsTableView)
  return result;
}
//end tableView:dataCellForTableColumn:row:

#pragma mark NSTableViewDataSource
-(NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
  return 0;
}
//end numberOfRowsInTableView:

-(nullable id) tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
  return nil;
}
//end tableView:objectValueForTableColumn:row:

-(id<NSPasteboardWriting>) tableView:(NSTableView*)tableView pasteboardWriterForRow:(NSInteger)row
{
  id<NSPasteboardWriting> result = nil;
  if (tableView == self->constantsTableView)
     result = [self->constantsArrayController.arrangedObjects objectAtIndex:row];
  return result;
}
//end tableView:pasteboardWriterForRow:
              
@end
