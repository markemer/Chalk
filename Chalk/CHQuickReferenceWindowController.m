//
//  CHQuickReferenceWindowController.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/17.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHQuickReferenceWindowController.h"

#import "CHUtils.h"
#import "JSDictionary.h"

#import "NSObjectExtended.h"

#import <JavaScriptCore/JavaScriptCore.h>

@interface CHHelpEntry : NSObject
@property(copy) NSPredicate* predicate;
@property(copy) NSString* name;
@property(copy) NSString* displayName;
@property(readonly) BOOL isLeaf;
@property(readonly) BOOL isMatching;
-(BOOL) matchesPredicate:(NSPredicate*)predicate;
@end
@implementation CHHelpEntry
@synthesize name;
@synthesize displayName;
@dynamic isLeaf;

-(void) dealloc {self.predicate=nil;self.name=nil;self.displayName=nil;[super dealloc];}
-(BOOL) isLeaf {return YES;}
-(BOOL) isMatching {return [self matchesPredicate:self.predicate];}
-(BOOL) matchesPredicate:(NSPredicate*)predicate {return !predicate || [predicate evaluateWithObject:self];}
@end

@interface CHHelpCategory : CHHelpEntry {
  NSMutableArray* children;
}
@property(retain)   NSMutableArray* children;
@property(copy)     NSArray* childrenFiltered;
@property(readonly) NSUInteger count;
@end
@implementation CHHelpCategory
@synthesize children;
@dynamic childrenFiltered;
@dynamic count;
-(instancetype) init
{
  if (!((self = [super init])))
    return self;
  self->children = [[NSMutableArray alloc] init];
  return self;
}
-(void) dealloc {[self->children release]; [super dealloc];}
-(BOOL) isLeaf {return NO;}
-(NSArray*) childrenFiltered {
  NSArray* result = [[self->children filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [evaluatedObject matchesPredicate:self.predicate];
  }]] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    CHHelpEntry* entry1 = [obj1 dynamicCastToClass:[CHHelpEntry class]];
    CHHelpEntry* entry2 = [obj2 dynamicCastToClass:[CHHelpEntry class]];
    return [entry1.displayName caseInsensitiveCompare:entry2.displayName];
  }];
  return result;
}
-(NSUInteger) count {
return self.childrenFiltered.count;
}
-(BOOL) matchesPredicate:(NSPredicate*)predicate
{
  __block BOOL result = [super matchesPredicate:predicate];
  if (!result)
  [self->children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
    result |= [obj matchesPredicate:predicate];
    *stop = result;
  }];
  return result;
}//end matchesPredicate:
-(NSString*) description {return [NSString stringWithFormat:@"(%@,%@,%@)", self.name, self.displayName, self->children];}
@end

@interface CHTreeController : NSTreeController
@property(nonatomic,copy) NSPredicate* predicate;
@end
@implementation CHTreeController
@synthesize predicate;
-(void) dealloc {self.predicate=nil;[super dealloc];}
-(void) setPredicate:(NSPredicate*)value {
  [self.content enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [obj setPredicate:value];
  }];
}

@end

@interface CHTreeNodeColorTransformer : NSValueTransformer
+(NSString*) name;

+(id) transformer;
-(id) init;
@end

@implementation CHTreeNodeColorTransformer
+(void) initialize
{
  [self setValueTransformer:[self transformer] forName:[self name]];
}
//end initialize

+(NSString*) name
{
  NSString* result = [self className];
  return result;
}
//end name

+(Class) transformedValueClass
{
  return [NSColor class];
}
//end transformedValueClass

+(BOOL) allowsReverseTransformation
{
  return NO;
}
//end allowsReverseTransformation

+(id) transformer
{
  id result = [[[[self class] alloc] init] autorelease];
  return result;
}
//end transformer

-(id) init
{
  if ((!(self = [super init])))
    return nil;
  return self;
}
//end init

-(id) transformedValue:(id)value
{
  id result = [NSColor textColor];
  CHHelpCategory* helpCategory = [value dynamicCastToClass:[CHHelpCategory class]];
  if (helpCategory && !helpCategory.childrenFiltered.count)
    result = [NSColor disabledControlTextColor];
  return result;
}
//end transformedValue:

@end

@interface CHQuickReferenceWindowController ()
-(void) loadHelpFromJS;
@end

@implementation CHQuickReferenceWindowController

+(BOOL) isSelectorExcludedFromWebScript:(SEL)sel
{
  BOOL result = YES;
  BOOL included = NO;
  result = !included;
  return result;
}
//end isSelectorExcludedFromWebScript:

-(id) init
{
  if ((!(self = [super initWithWindowNibName:@"CHQuickReferenceWindowController"])))
    return nil;
  self->treeController = [[CHTreeController alloc] init];
  self->treeController.preservesSelection = YES;
  self->treeController.childrenKeyPath = @"childrenFiltered";
  self->treeController.leafKeyPath = @"isLeaf";
  self->treeController.countKeyPath = @"count";
  return self;
}
//end init

-(void) dealloc
{
  [self->outlineView unbind:NSContentBinding];
  [self->outlineView.tableColumns[[self->outlineView columnWithIdentifier:@"name"]] unbind:NSValueBinding];
  [self->treeController removeObserver:self forKeyPath:@"selectedObjects"];
  [self->treeController release];
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  self.window.title = NSLocalizedString(@"Chalk quick help", @"");
  self->searchField.target = self;
  self->searchField.action = @selector(controlTextDidEndEditing:);
  self->searchField.delegate = self;
  NSTableColumn* column = [self->outlineView.tableColumns.firstObject dynamicCastToClass:[NSTableColumn class]];
  NSTableHeaderCell* headerCell = [column.headerCell dynamicCastToClass:[NSTableHeaderCell class]];
  headerCell.stringValue = NSLocalizedString(@"Categories", @"");
  [self->outlineView bind:NSContentBinding toObject:self->treeController withKeyPath:@"arrangedObjects" options:nil];
  [self->outlineView bind:NSSelectionIndexPathsBinding toObject:self->treeController withKeyPath:@"selectionIndexPaths" options:nil];
  [self->outlineView.tableColumns[[self->outlineView columnWithIdentifier:@"name"]] bind:NSValueBinding toObject:treeController withKeyPath:@"arrangedObjects.displayName" options:nil];
  [self->outlineView.tableColumns[[self->outlineView columnWithIdentifier:@"name"]] bind:NSTextColorBinding toObject:treeController withKeyPath:@"arrangedObjects.self" options:@{NSValueTransformerBindingOption:[CHTreeNodeColorTransformer transformer]}];
  [self->treeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:0];
  self->webView.webDelegate = self;
  if (!self->webView.URL)
  {
    NSURL* webPageUrl = [[NSBundle mainBundle] URLForResource:@"chalk-quick-reference" withExtension:@"html" subdirectory:@"Chalk"];
    self->webView.URL = webPageUrl;
  }//end if (!self->webView.URL)
}
//end awakeFromNib

-(void) webviewDidLoad:(CHWebView * _Nonnull)webview
{
  DebugLog(1, @"webviewDidLoad");
  [self performSelector:@selector(loadHelpFromJS) withObject:nil afterDelay:0];
}
//end webviewDidLoad:

-(void) jsDidLoad:(CHWebView* _Nonnull)webview
{
  DebugLog(1, @"jsDidLoad");
}
//end jsDidLoad:

-(void) loadHelpFromJS
{
  id jsCategories = [self->webView evaluateJavaScriptFunction:@"getCategories" withJSONArguments:nil wait:YES];
  NSArray* categories = nil;
  if (!categories)
    categories = [jsCategories dynamicCastToClass:[NSArray class]];
  if (!categories)
    categories = [[jsCategories JSValue] toArray];
  CHHelpCategory* allCategory = [[[CHHelpCategory alloc] init] autorelease];
  allCategory.name = @"all";
  allCategory.displayName = NSLocalizedString(@"All_fem", @"All_fem");
  NSMutableArray* helpCategories = [NSMutableArray array];
  for(NSDictionary* category in categories)
  {
    CHHelpCategory* helpCategory = [[[CHHelpCategory alloc] init] autorelease];
    helpCategory.name = category[@"name"];
    helpCategory.displayName = category[@"displayName"];
    [helpCategories addObject:helpCategory];
    id jsEntries = [self->webView evaluateJavaScriptFunction:@"getEntriesForCategory" withJSONArguments:@[helpCategory.name] wait:YES];
    NSArray* entries = nil;
    if (!entries)
      entries = [jsEntries dynamicCastToClass:[NSArray class]];
    if (!entries)
      entries = [[jsEntries JSValue] toArray];
    for(NSDictionary* entry in entries)
    {
      CHHelpEntry* helpEntry = [[[CHHelpEntry alloc] init] autorelease];
      helpEntry.name = entry[@"entry_id"];
      helpEntry.displayName = entry[@"entry_name"];
      [helpCategory.children addObject:helpEntry];
      __block BOOL alreadyContained = NO;
      [allCategory.children enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        CHHelpEntry* entry = [obj dynamicCastToClass:[CHHelpEntry class]];
        alreadyContained |= [entry.name isEqualToString:helpEntry.name];
        *stop |= alreadyContained;
      }];
      if (!alreadyContained)
        [allCategory.children addObject:helpEntry];
    }//end for each entry
  }
  [helpCategories insertObject:allCategory atIndex:0];
  self->treeController.content = helpCategories;
  [self->outlineView reloadData];
}
//end loadHelpFromJS

-(void) controlTextDidEndEditing:(NSNotification*)obj
{
  NSPredicate* predicate = nil;
  if ([self->searchField.stringValue isEqualToString:@""])
    predicate = nil;
  else
    predicate = [NSPredicate predicateWithFormat:@"displayName contains[cd] %@", [self->searchField stringValue]];
  self->treeController.predicate = predicate;
  [self->treeController rearrangeObjects];
  [self->outlineView reloadData];
}
//end controlTextDidBeginEditing:

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  id selection = self->treeController.selectedObjects.lastObject;
  CHHelpCategory* category = [selection dynamicCastToClass:[CHHelpCategory class]];
  CHHelpEntry* entry = [selection dynamicCastToClass:[CHHelpEntry class]];
  if (category)
    [self->webView evaluateJavaScriptFunction:@"displayCategory" withJSONArguments:@[category.name] wait:NO];
  else if (entry)
    [self->webView evaluateJavaScriptFunction:@"displayEntry" withJSONArguments:@[entry.name] wait:NO];
}
//end observeValueForKeyPath:

@end
