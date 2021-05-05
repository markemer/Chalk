//
//  CHAppDelegate.m
//  Chalk
//
//  Created by Pierre Chatelier on 22/04/13.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHAppDelegate.h"

#import "CHCalculatorDocument.h"
#import "CHDragFilterWindowController.h"
#import "CHEquationDocument.h"
#import "CHGraphDocument.h"
#import "CHInspectorView.h"
#import "CHPreferencesController.h"
#import "CHPreferencesWindowController.h"
#import "CHQuickReferenceWindowController.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"
#import "NSWorkspaceExtended.h"

@interface CHAppDelegate ()
@property(readonly,assign) NSDocument* hiddenDocument;
@property(readonly,assign) CHCalculatorDocument* hiddenCalculatorDocument;
@end

@implementation CHAppDelegate

@dynamic    preferencesWindowController;
@dynamic    quickReferenceWindowController;
@synthesize sparkleUpdater;

@dynamic    hiddenCalculatorDocument;

+(CHAppDelegate*) appDelegate
{
  CHAppDelegate* result = [(id)[NSApp delegate] dynamicCastToClass:[CHAppDelegate class]];
  return result;
}
//end appDelegate

-(id) init
{
  if (!(self = [super init]))
    return nil;
  return self;
}
//end init

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->dragFilterWindowController release];
  [self->preferencesWindowController release];
  [self->quickReferenceWindowController release];
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  [super awakeFromNib];
  [CHPreferencesController sharedPreferencesController];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishRestoringWindows:) name:NSApplicationDidFinishRestoringWindowsNotification object:nil];
}
//end awakeFromNib

-(void) applicationDidFinishLaunching:(NSNotification*)notification
{
  DebugLog(1, @"applicationDidFinishLaunching");
}
//end applicationDidFinishLaunching:

-(void) applicationDidFinishRestoringWindows:(NSNotification*)notification
{
  NSArray* documents = [[NSDocumentController sharedDocumentController] documents];
  if (!documents.count)
    [self newCalculatorDocument:nil];
}
//end applicationDidFinishRestoringWindows:

-(void) applicationWillTerminate:(NSNotification *)notification
{
  NSArray* documents = [[NSDocumentController sharedDocumentController] documents];
  [documents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHCalculatorDocument* document = [obj dynamicCastToClass:[CHCalculatorDocument class]];
    [document saveGUIState:nil saveDocument:YES];
  }];
}
//end applicationWillTerminate:

-(BOOL) applicationShouldOpenUntitledFile:(NSApplication*)sender
{
  BOOL result = YES;
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  BOOL hasHiddenDocuments = (self.hiddenDocument != nil);
  result &= !documentController.documents.count && !hasHiddenDocuments;
  if (result || hasHiddenDocuments)
  {
    CHCalculatorDocument* hiddenCalculatorDocument = self.hiddenCalculatorDocument;
    if (hiddenCalculatorDocument)
    {
      NSWindowAnimationBehavior oldAnimationBehaviour = hiddenCalculatorDocument.windowForSheet.animationBehavior;
      hiddenCalculatorDocument.windowForSheet.animationBehavior = NSWindowAnimationBehaviorNone;
      [hiddenCalculatorDocument.windowForSheet makeKeyAndOrderFront:self];
      result = !hiddenCalculatorDocument.windowForSheet.isVisible;
      hiddenCalculatorDocument.windowForSheet.animationBehavior = oldAnimationBehaviour;
      result = NO;
    }//end if (hiddenCalculatorDocument)
  }//end if (result || hasHiddenDocuments)
  return result;
}
//end applicationShouldOpenUntitledFile:

-(BOOL) applicationOpenUntitledFile:(NSApplication*)sender
{
  [self newCalculatorDocument:sender];
  return YES;
}
//end applicationOpenUntitledFile:

-(BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
  BOOL result = YES;
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  CHPersistentDocument* persistentDocument = [currentDocument dynamicCastToClass:[CHPersistentDocument class]];
  CHCalculatorDocument* calculatorDocument = [currentDocument dynamicCastToClass:[CHCalculatorDocument class]];
  CHEquationDocument* equationDocument = [currentDocument dynamicCastToClass:[CHEquationDocument class]];
  CHGraphDocument* graphDocument = [currentDocument dynamicCastToClass:[CHGraphDocument class]];
  if (menuItem.action == @selector(saveDocument:))
    result = persistentDocument && (!persistentDocument.isDefaultDocument || [persistentDocument isDocumentEdited]);
  else if (menuItem.action == @selector(runPageLayout:))
  {
    menuItem.title = NSLocalizedString(@"Page Setup...", @"");
    result = [calculatorDocument validateMenuItem:menuItem] || [graphDocument validateMenuItem:menuItem];
  }//end if (menuItem.action == @selector(runPageLayout:))
  else if (menuItem.action == @selector(printDocument:))
  {
    menuItem.title = NSLocalizedString(@"Print...", @"");
    result = [calculatorDocument validateMenuItem:menuItem] || [graphDocument validateMenuItem:menuItem];
  }//end if (menuItem.action == @selector(printDocument:))
  else if (menuItem.action == @selector(toggleInspectorCompute:))
  {
    menuItem.hidden = !calculatorDocument;
    menuItem.title = calculatorDocument.inspectorRightView.visible ?
      NSLocalizedString(@"Hide compute inspector", @"") :
      NSLocalizedString(@"Show compute inspector", @"");
    result = [calculatorDocument validateMenuItem:menuItem];
  }//end if (menuItem.action == @selector(toggleInspectorCompute:))
  else if (menuItem.action == @selector(toggleInspectorVariables:))
  {
    menuItem.hidden = !calculatorDocument && !graphDocument;
    menuItem.title =
      calculatorDocument ?
        calculatorDocument.inspectorLeftView.visible ?
          NSLocalizedString(@"Hide variables inspector", @"") :
          NSLocalizedString(@"Show variables inspector", @"") :
      graphDocument ?
        graphDocument.inspectorLeftView.visible ?
          NSLocalizedString(@"Hide variables inspector", @"") :
          NSLocalizedString(@"Show variables inspector", @"") :
      menuItem.title;
    result =
      [calculatorDocument validateMenuItem:menuItem] ||
      [graphDocument validateMenuItem:menuItem];
  }//end if (menuItem.action == @selector(toggleInspectorVariables:))
  else if (menuItem.action == @selector(toggleInspectorBits:))
  {
    menuItem.hidden = !calculatorDocument;
    menuItem.title = calculatorDocument.inspectorBottomView.visible ?
      NSLocalizedString(@"Hide bits inspector", @"") :
      NSLocalizedString(@"Show bits inspector", @"");
    result = [calculatorDocument validateMenuItem:menuItem];
  }//end if (menuItem.action == @selector(toggleInspectorBits:))
  else if (menuItem.action == @selector(toggleInspectorAxes:))
  {
     menuItem.hidden = !graphDocument;
     menuItem.title = graphDocument.inspectorLeftView.visible ?
      NSLocalizedString(@"Hide axes inspector", @"") :
      NSLocalizedString(@"Show axes inspector", @"");
    result = [graphDocument validateMenuItem:menuItem];
  }//end if (menuItem.action == @selector(toggleInspectorAxes:))
  else if (menuItem.action == @selector(calculatorRemoveCurrentItem:))
    result = [calculatorDocument validateMenuItem:menuItem];
  else if (menuItem.action == @selector(calculatorRemoveAllItems:))
    result = [calculatorDocument validateMenuItem:menuItem];
  else if (menuItem.action == @selector(renderEquationDocument:))
    result = [equationDocument validateMenuItem:menuItem];
  return result;
}
//end validateMenuItem:

-(IBAction) makeDonation:(id)sender//display info panel
{
  NSString* urlString = NSLocalizedString(@"https://pierre.chachatelier.fr/chalk/chalk-donations.php", @"");
  NSURL* webSiteURL = [NSURL URLWithString:urlString];
  BOOL ok = [[NSWorkspace sharedWorkspace] openURL:webSiteURL];
  if (!ok)
  {
    NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"),
                    [NSString stringWithFormat:NSLocalizedString(@"An error occured while trying to reach %@.\nYou should check your network.", @""),
                     [webSiteURL absoluteString]],
                    @"OK", nil, nil);
  }//end if (!ok)
}
//end makeDonation:

-(IBAction) showPreferencesPane:(id)sender
{
  [self.preferencesWindowController.window makeKeyAndOrderFront:self];
}
//end showPreferencesPane:

-(void) showPreferencesPaneWithItemIdentifier:(NSString*)itemIdentifier options:(id)options//showPreferencesPane + select one pane
{
  [self showPreferencesPane:self];
  [self.preferencesWindowController selectPreferencesPaneWithItemIdentifier:itemIdentifier options:options];
}
//end showPreferencesPaneWithItemIdentifier:

-(IBAction) openWebSite:(id)sender
{
  NSString* urlString = NSLocalizedString(@"https://pierre.chachatelier.fr/chalk/index.php", @"");
  NSURL* webSiteURL = [NSURL URLWithString:urlString];
  BOOL ok = [[NSWorkspace sharedWorkspace] openURL:webSiteURL];
  if (!ok)
  {
    NSRunAlertPanel(NSLocalizedString(@"Error", @"Error"),
                   [NSString stringWithFormat:NSLocalizedString(@"An error occured while trying to reach %@.\nYou should check your network.", @""),
                                              [webSiteURL absoluteString]],
                    @"OK", nil, nil);
  }//end if (!ok)
}
//end openWebSite:

-(IBAction) checkUpdates:(id)sender
{
  if (!sender)
    [self->sparkleUpdater checkForUpdatesInBackground];
  else
    [self->sparkleUpdater checkForUpdates:sender];
}
//end checkUpdates:

-(IBAction) showHelp:(id)sender
{
  NSURL* webPageUrl = [[NSBundle mainBundle] URLForResource:@"chalk-doc" withExtension:@"html" subdirectory:@"Chalk"];
  __block NSError* error = nil;
  NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
  NSDictionary<NSWorkspaceLaunchConfigurationKey, id>* configuration = @{};
  if ([workspace respondsToSelector:@selector(openURL:options:configuration:error:)])
    [workspace openURL:webPageUrl options:NSWorkspaceLaunchWithoutAddingToRecents configuration:configuration error:&error];
  else
    [workspace openURL:webPageUrl];
  if (error)
    DebugLog(0, @"showHelp error = <%@>", error);
}
//end showHelp:

-(CHDragFilterWindowController*) dragFilterWindowController
{
  if (!self->dragFilterWindowController)
    self->dragFilterWindowController = [[CHDragFilterWindowController alloc] init];
  return self->dragFilterWindowController;
}
//end quickReferenceWindowController

-(CHQuickReferenceWindowController*) quickReferenceWindowController
{
  if (!self->quickReferenceWindowController)
    self->quickReferenceWindowController = [[CHQuickReferenceWindowController alloc] init];
  return self->quickReferenceWindowController;
}
//end quickReferenceWindowController

-(IBAction) toggleInspectorCompute:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  CHCalculatorDocument* currentCalculatorDocument = [currentDocument dynamicCastToClass:[CHCalculatorDocument class]];
  currentCalculatorDocument.inspectorRightView.visible = !currentCalculatorDocument.inspectorRightView.visible;
}
//end toggleInspectorCompute:

-(IBAction) toggleInspectorVariables:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  CHCalculatorDocument* currentCalculatorDocument = [currentDocument dynamicCastToClass:[CHCalculatorDocument class]];
  CHGraphDocument* currentGraphDocument = [currentDocument dynamicCastToClass:[CHGraphDocument class]];
  currentCalculatorDocument.inspectorLeftView.visible = !currentCalculatorDocument.inspectorLeftView.visible;
  currentGraphDocument.inspectorLeftView.visible = !currentGraphDocument.inspectorLeftView.visible;
}
//end toggleInspectorVariables:

-(IBAction) toggleInspectorBits:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  CHCalculatorDocument* currentCalculatorDocument = [currentDocument dynamicCastToClass:[CHCalculatorDocument class]];
  currentCalculatorDocument.inspectorBottomView.visible = !currentCalculatorDocument.inspectorBottomView.visible;
}
//end toggleInspectorBits:

-(IBAction) toggleInspectorAxes:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  CHGraphDocument* currentGraphDocument = [currentDocument dynamicCastToClass:[CHGraphDocument class]];
  currentGraphDocument.inspectorRightView.visible = !currentGraphDocument.inspectorRightView.visible;
}
//end toggleInspectorAxes:

-(IBAction) showQuickHelp:(id)sender
{
  [self.quickReferenceWindowController.window makeKeyAndOrderFront:self];
}
//end showQuickHelp:

-(IBAction) newDocument:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  CHCalculatorDocument* currentCalculatorDocument = [currentDocument dynamicCastToClass:[CHCalculatorDocument class]];
  CHEquationDocument* currentEquationDocument = [currentDocument dynamicCastToClass:[CHEquationDocument class]];
  CHGraphDocument* currentGraphDocument = [currentDocument dynamicCastToClass:[CHGraphDocument class]];
  if (currentCalculatorDocument)
    [self newCalculatorDocument:sender];
  else if (currentEquationDocument)
    [self newEquationDocument:sender];
  else if (currentGraphDocument)
    [self newGraphDocument:sender];
  else
    [self newCalculatorDocument:sender];
}
//end newDocument:

-(IBAction) saveDocument:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  [currentDocument saveDocument:sender];
}
//end saveDocument:

-(NSDocument*) hiddenDocument
{
  __block NSDocument* result = nil;
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  [documentController.documents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSDocument* document = [obj dynamicCastToClass:[NSDocument class]];
    result = !document.windowForSheet.isVisible ? document : nil;
    *stop = (result != nil);
  }];
  return result;
}
//end hiddenDocument

-(CHCalculatorDocument*) hiddenCalculatorDocument
{
  __block CHCalculatorDocument* result = nil;
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  [documentController.documents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHCalculatorDocument* calculatorDocument = [obj dynamicCastToClass:[CHCalculatorDocument class]];
    result = !calculatorDocument.windowForSheet.isVisible ? calculatorDocument : nil;
    *stop = (result != nil);
  }];
  return result;
}
//end hiddenCalculatorDocument

-(IBAction) newCalculatorDocument:(id)sender
{
  CHCalculatorDocument* hiddenCalculatorDocument = self.hiddenCalculatorDocument;
  if (hiddenCalculatorDocument)
  {
    NSWindowAnimationBehavior oldAnimationBehaviour = hiddenCalculatorDocument.windowForSheet.animationBehavior;
    hiddenCalculatorDocument.windowForSheet.animationBehavior = NSWindowAnimationBehaviorNone;
    [hiddenCalculatorDocument.windowForSheet makeKeyAndOrderFront:self];
    hiddenCalculatorDocument.windowForSheet.animationBehavior = oldAnimationBehaviour;
  }//end if (hiddenCalculatorDocument)
  else//if (!hiddenCalculatorDocument)
  {
    NSURL* defaultCalculatorURL = [CHCalculatorDocument defaultDocumentFileURL];
    NSError* error1 = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:[defaultCalculatorURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error1];
    if (error1)
      DebugLog(0, @"createDirectoryAtURL error = %@", error1);
    NSString* filePath = [NSString stringWithUTF8String:defaultCalculatorURL.filePathURL.fileSystemRepresentation];

    BOOL canLoadDefaultCalculator = defaultCalculatorURL && [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    NSUInteger calculatorDocumentsCount = 0;
    NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
    for(NSDocument* document in documentController.documents)
      calculatorDocumentsCount += ([document dynamicCastToClass:[CHCalculatorDocument class]] ? 1 : 0);
    BOOL shouldLoadCalculatorURL = !calculatorDocumentsCount;
    NSError* error = nil;
    NSDocument* document =
      canLoadDefaultCalculator && shouldLoadCalculatorURL ?
        [documentController makeDocumentWithContentsOfURL:defaultCalculatorURL ofType:[CHCalculatorDocument defaultDocumentType] error:&error] :
        [documentController makeUntitledDocumentOfType:[CHCalculatorDocument defaultDocumentType] error:&error];
    if (error)
      DebugLog(0, @"error = %@", error);
    if (document)
    {
      if (shouldLoadCalculatorURL && !canLoadDefaultCalculator)
      {
        [document writeToURL:defaultCalculatorURL ofType:[CHCalculatorDocument defaultDocumentType] forSaveOperation:NSSaveAsOperation originalContentsURL:nil error:&error];
        if (error)
          DebugLog(0, @"error = %@", error);
      }//enbd if (shouldLoadCalculatorURL && !canLoadDefaultCalculator)
      else if (shouldLoadCalculatorURL)
        document.fileURL = defaultCalculatorURL;
      @try{
        [documentController addDocument:document];
        [document makeWindowControllers];
        [document showWindows];
      }
      @catch(NSException* e){
      }
    }//end if (document)
  }//end if (!hiddenCalculatorDocument)
}
//end newCalculatorDocument:

-(IBAction) newGraphDocument:(id)sender
{
  NSError* error = nil;
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* document = [documentController makeUntitledDocumentOfType:[CHGraphDocument defaultDocumentType] error:&error];
  if (document)
  {
    [documentController addDocument:document];
    [document makeWindowControllers];
    [document showWindows];
  }//end if (document)
}
//end newGraphDocument:

-(IBAction) newEquationDocument:(id)sender
{
  NSError* error = nil;
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* document = [documentController makeUntitledDocumentOfType:[CHEquationDocument defaultDocumentType] error:&error];
  if (document)
  {
    [documentController addDocument:document];
    [document makeWindowControllers];
    [document showWindows];
  }//end if (document)
}
//end newEquationDocument:

-(IBAction) renderEquationDocument:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSDocument* currentDocument = documentController.currentDocument;
  CHEquationDocument* equationDocument = [currentDocument dynamicCastToClass:[CHEquationDocument class]];
  [equationDocument renderAction:self];
}
//end renderEquationDocument:

-(CHPreferencesWindowController*) preferencesWindowController
{
  if (!self->preferencesWindowController)
    self->preferencesWindowController = [[CHPreferencesWindowController alloc] init];
  return self->preferencesWindowController;
}
//end preferencesWindowController

-(IBAction) calculatorRemoveCurrentItem:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSArray* documents = documentController.documents;
  NSDocument* currentDocument = documentController.currentDocument;
  if (!currentDocument && documents.count)
    currentDocument = [documents.lastObject dynamicCastToClass:[NSDocument class]];
  CHCalculatorDocument* calculatorDocument = [currentDocument dynamicCastToClass:[CHCalculatorDocument class]];
  [calculatorDocument removeCurrentEntry:sender];
}
//end calculatorRemoveCurrentItem:

-(IBAction) calculatorRemoveAllItems:(id)sender
{
  NSDocumentController* documentController = [NSDocumentController sharedDocumentController];
  NSArray* documents = documentController.documents;
  NSDocument* currentDocument = documentController.currentDocument;
  if (!currentDocument && documents.count)
    currentDocument = [documents.lastObject dynamicCastToClass:[NSDocument class]];
  CHCalculatorDocument* calculatorDocument = [currentDocument dynamicCastToClass:[CHCalculatorDocument class]];
  [calculatorDocument removeAllEntries:sender];
}
//end calculatorRemoveAllItems:

@end
