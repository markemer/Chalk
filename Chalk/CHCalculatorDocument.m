//
//  CHCalculatorDocument.m
//  Chalk
//
//  Created by Pierre Chatelier on 12/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHCalculatorDocument.h"

#import "CHAppDelegate.h"
#import "CHBoolTransformer.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkIdentifierVariable.h"
#import "CHChalkItemDependencyManager.h"
#import "CHChalkOperatorManager.h"
#import "CHChalkToken.h"
#import "CHChalkValue.h"
#import "CHChalkValueList.h"
#import "CHChalkValueMatrix.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueNumberRaw.h"
#import "CHChalkValueToStringTransformer.h"
#import "CHComputationConfiguration.h"
#import "CHComputationConfigurationEntity.h"
#import "CHComputationEntryEntity.h"
#import "CHComputedValueEntity.h"
#import "CHDigitsInspectorControl.h"
#import "CHDocumentDataEntity.h"
#import "CHGmpPool.h"
#import "CHInspectorView.h"
#import "CHParseConfiguration.h"
#import "CHParser.h"
#import "CHParserAssignationNode.h"
#import "CHParserAssignationDynamicNode.h"
#import "CHParserEnumerationNode.h"
#import "CHParserFunctionNode.h"
#import "CHParserIdentifierNode.h"
#import "CHParserValueNode.h"
#import "CHPreferencesController.h"
#import "CHPresentationConfiguration.h"
#import "CHPresentationConfigurationEntity.h"
#import "CHProgressIndicator.h"
#import "CHStreamWrapper.h"
#import "CHSVGRenderer.h"
#import "CHTableView.h"
#import "CHUserFunctionEntity.h"
#import "CHUserFunctionItem.h"
#import "CHUserVariableEntity.h"
#import "CHUserVariableItem.h"
#import "CHUtils.h"
#import "CHWebView.h"
#import "CHWebViewScrollView.h"

#import "JSDictionary.h"

#import "NSAttributedStringExtended.h"
#import "NSIndexSetExtended.h"
#import "NSManagedObjectContextExtended.h"
#import "NSMenuExtended.h"
#import "NSMutableArrayExtended.h"
#import "NSNumberFormatterExtended.h"
#import "NSObjectExtended.h"
#import "NSSegmentedControlExtended.h"
#import "NSStringExtended.h"
#import "NSString+HTML.h"
#import "NSViewExtended.h"
#import "NSWorkspaceExtended.h"

@interface CHCalculatorDocument ()

@property(nonatomic,retain) CHComputationEntryEntity* currentComputationEntry;

-(void) _displayComputationEntries;
-(JSDictionary*) jsDictionaryFromComputationEntry:(CHComputationEntryEntity*)computationEntry;
-(void) reloadWebContent;
-(void) mathjaxDidFinishLoading;
-(void) mathjaxGroupDidEnd;
-(void) mathjaxDidEndTypesetting;
-(void) mathjaxReportedError:(NSString*)message;
-(void) webViewEntryWithUid:(id)uid didChangeCustomAnnotation:(id)value visible:(id)visible;
-(void) webViewEntryDidSwitchDisplay;
-(void) webViewEntrySelectionDidChangeToAge:(id)age flag:(id)flag;
-(void) webViewEntryShouldRemoveAge:(id)age;
-(void) webViewSetCSS:(NSString*)cssFilePath;
-(void) viewFrameDidChange:(NSNotification*)notification;
-(NSInteger) createUniqueIdentifier;
-(void) computeWithInput:(NSString*)input computeMode:(chalk_compute_mode_t)computeMode;
-(void) computeComputationEntry:(CHComputationEntryEntity*)computationEntry isNew:(BOOL)isNew;
-(void) computeComputationEntry:(CHComputationEntryEntity*)computationEntry isNew:(BOOL)isNew didEndWithParser:(CHParser*)parser;
-(void) refreshComputationEntry:(CHComputationEntryEntity*)computationEntry computationConfiguration:(CHComputationConfiguration*)computationConfiguration presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) updateDocumentControlsForComputationConfiguration:(CHComputationConfiguration*)computationConfiguration
                                presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
                                               chalkValue:(CHChalkValue*)chalkValue;
-(void) currentComputationEntryDidChange:(NSNotification*)notification;
-(IBAction) updateDocumentControls:(id)sender;
-(void) userDefaultsDidChange:(NSNotification*)notification;
-(void) updateGuiForPreferences;
-(void) prepareInputField:(CHComputationEntryEntity* _Nullable)computationEntry;
@end

@implementation CHCalculatorDocument

@synthesize inspectorRightView;
@synthesize inspectorLeftView;
@synthesize inspectorBottomView;

@synthesize currentComputationEntry;
@synthesize defaultComputationConfiguration;
@synthesize defaultPresentationConfiguration;
@dynamic    currentComputationConfiguration;
@dynamic    currentPresentationConfiguration;
@synthesize isComputing;

@synthesize currentTheme;

+(void) initialize
{
  [self exposeBinding:@"isComputing"];
}
//end initialize:
 
+(BOOL) isSelectorExcludedFromWebScript:(SEL)sel
{
  BOOL result = YES;
  BOOL included =
    (sel == @selector(jsConsoleLog:)) ||
    (sel == @selector(mathjaxDidFinishLoading)) ||
    (sel == @selector(mathjaxGroupDidEnd)) ||
    (sel == @selector(mathjaxDidEndTypesetting)) ||
    (sel == @selector(mathjaxReportedError:)) ||
    (sel == @selector(webViewEntryDidSwitchDisplay)) ||
    (sel == @selector(webViewEntrySelectionDidChangeToAge:flag:)) ||
    (sel == @selector(webViewEntryWithUid:didChangeCustomAnnotation:visible:)) ||
    (sel == @selector(webViewEntryShouldRemoveAge:));
  result = !included;
  return result;
}
//end isSelectorExcludedFromWebScript:

-(void) updateChangeCount:(NSDocumentChangeType)change
{
  if (self.isDefaultDocument)
  {
    NSError* error = nil;
    [self writeSafelyToURL:self.fileURL ofType:[[self class] defaultDocumentType] forSaveOperation:NSAutosaveInPlaceOperation error:&error];
    if (error)
      DebugLog(0, @"updateChangeCount save:<%@>", error);
    [super updateChangeCount:NSChangeCleared];
  }//end if (self.isDefaultDocument)
  else
    [super updateChangeCount:change];
}
//end updateChangeCount:

-(void) jsConsoleLog:(NSString*)message
{
  DebugLog(0, @"jsConsoleLog : <%@>", message);
}
//end jsConsoleLog:

-(void) mathjaxDidFinishLoading
{
  DebugLog(1, @"mathjaxDidFinishLoading");
  [self reloadWebContent];
  [self->inputTextField bind:NSEnabledBinding toObject:self withKeyPath:@"isComputing" options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
  [self.windowForSheet makeFirstResponder:self->inputTextField];
}
//end mathjaxDidFinishLoading

-(void) _displayComputationEntries
{
  BOOL displayByUid = YES;
  if (displayByUid)
  {
    DebugLog(1, @"By uniqueIdentifier");
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"uniqueIdentifier" ascending:YES]];
    fetchRequest.includesPendingChanges = YES;
    NSError* error = nil;
    NSArray* computationEntries = nil;
    @try{
      error = nil;
      @synchronized(self.managedObjectContext)
      {
        computationEntries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
      }//end @synchronized(self.managedObjectContext)
      DebugLog(1, @"there are %@ results", @(computationEntries.count));
      [computationEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHComputationEntryEntity* computationEntry = obj;
        DebugLog(1, @"%@ : %p(uid = %@, creation date = %@, modification date = %@)",
          @(idx), computationEntry, @(computationEntry.uniqueIdentifier), computationEntry.dateCreation, computationEntry.dateModification);
      }];
    }
    @catch(NSException* e){
    }
  }//end if (displayByUid)
  BOOL displayByCreationDate = YES;
  if (displayByCreationDate)
  {
    DebugLog(1, @"By creation date");
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreation" ascending:YES]];
    fetchRequest.includesPendingChanges = YES;
    NSError* error = nil;
    NSArray* computationEntries = nil;
    @try{
      error = nil;
      @synchronized(self.managedObjectContext)
      {
        computationEntries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
      }//end @synchronized(self.managedObjectContext)
      DebugLog(1, @"there are %@ results", @(computationEntries.count));
      [computationEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHComputationEntryEntity* computationEntry = obj;
        DebugLog(1, @"%@ : %p(uid = %@, creation date = %@, modification date = %@)",
          @(idx), computationEntry, @(computationEntry.uniqueIdentifier), computationEntry.dateCreation, computationEntry.dateModification);
      }];
    }
    @catch(NSException* e){
    }
  }//end if (displayByCreationDate)

}
//end _displayComputationEntries

-(JSDictionary*) jsDictionaryFromComputationEntry:(CHComputationEntryEntity*)computationEntry
{
  JSDictionary* result = !computationEntry ? nil :
    [JSDictionary jsDictionaryWithDictionary:@{
      @"uid":@(computationEntry.uniqueIdentifier),
      @"customAnnotation":[NSObject nullAdapter:computationEntry.customAnnotation],
      @"customAnnotationVisible":@(computationEntry.customAnnotationVisible),
      @"inputRawHTMLString":[NSObject nullAdapter:computationEntry.inputRawHTMLString],
      @"inputInterpretedHTMLString":[NSObject nullAdapter:computationEntry.inputInterpretedHTMLString],
      @"inputInterpretedTeXString":[NSObject nullAdapter:computationEntry.inputInterpretedTeXString],
      @"outputHTMLString":[NSObject nullAdapter:computationEntry.outputHTMLString],
      @"outputTeXString":[NSObject nullAdapter:computationEntry.outputTeXString],
      @"outputHtmlCumulativeFlags":[NSObject nullAdapter:computationEntry.outputHtmlCumulativeFlags],
      @"output2HTMLString":[NSObject nullAdapter:computationEntry.output2HTMLString],
      @"output2TeXString":[NSObject nullAdapter:computationEntry.output2TeXString],
      @"output2HtmlCumulativeFlags":[NSObject nullAdapter:computationEntry.output2HtmlCumulativeFlags]
    }];
  return result;
}
//end jsDictionaryFromComputationEntry:

-(void) reloadWebContent
{
  self->disablingView.hidden = NO;
  NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
  fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"uniqueIdentifier" ascending:YES]];
  fetchRequest.includesPendingChanges = YES;
  NSError* error = nil;
  NSArray* computationEntries = nil;
  @try{
    error = nil;
    @synchronized(self.managedObjectContext)
    {
      computationEntries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }//end @synchronized(self.managedObjectContext)
    if (error)
      DebugLog(0, @"reloadWebContent error <%@>", error);
  }
  @catch(NSException* e){
  }

  NSMutableIndexSet* indices = [NSMutableIndexSet indexSet];
  NSMutableArray* entries = [NSMutableArray array];
  [computationEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHComputationEntryEntity* computationEntry = [obj dynamicCastToClass:[CHComputationEntryEntity class]];
    if (computationEntry)
    {
      [indices addIndex:computationEntry.uniqueIdentifier];
      JSDictionary* jsDict = [self jsDictionaryFromComputationEntry:computationEntry];
      [entries addObject:self->outputWebView.useWKView ? jsDict.dictionary : jsDict];
    }//end if (computationEntry)
  }];//end for each computationEntry

  DebugLog(1, @"load %@ entries", @(entries.count));
  DebugLog(1, @">beginMathjaxGroup");
  [self->outputWebView evaluateJavaScriptFunction:@"beginMathjaxGroup" withJSONArguments:nil wait:YES];
  DebugLog(1, @"<beginMathjaxGroup");
  DebugLog(1, @">addEntries");
  [self->outputWebView evaluateJavaScriptFunction:@"addEntries" withJSONArguments:entries wait:YES];
  DebugLog(1, @"<addEntries");
  DebugLog(1, @">endMathjaxGroup");
  [self->outputWebView evaluateJavaScriptFunction:@"endMathjaxGroup" withJSONArguments:nil wait:YES];
  DebugLog(1, @"<endMathjaxGroup");
}
//end reloadWebContent

-(void) mathjaxGroupDidEnd
{
  DebugLog(1, @"mathjaxGroupDidEnd");
  [self windowDidResize:[NSNotification notificationWithName:NSWindowDidResizeNotification object:self.windowForSheet]];
  [self->progressIndicator stopAnimation:self];
  self->disablingView.hidden = YES;
}
//end mathjaxGroupDidEnd

-(void) mathjaxDidEndTypesetting
{
  DebugLog(1, @"mathjaxDidEndTypesetting");
}
//end mathjaxDidEndTypesetting

-(void) mathjaxReportedError:(NSString*)string
{
  DebugLog(0, @"mathjaxReportedError = <%@>", string);
}
//end mathjaxReportedError:

-(void) webViewEntryDidSwitchDisplay
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self->outputWebView setNeedsDisplay:YES];
  });
}
//end webViewEntryDidSwitchDisplay

-(void) webViewEntrySelectionDidChangeToAge:(id)age flag:(id)flag
{
  DebugLog(1, @"webViewEntrySelectionDidChangeToAge:%@", age);
  //[self commitChangesIntoManagedObjectContext:nil];//required for fetchOffset to work correctly in later queries
  if (DebugLogLevel >= 2)
    [self _displayComputationEntries];
  NSUInteger ageInteger = [[age dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  self.currentComputationEntry = [self chalkContext:self->chalkContext computationEntryForAge:ageInteger];
  DebugLog(1, @"self.currentComputationEntry.uniqueIdentifier:%@", @(self.currentComputationEntry.uniqueIdentifier));
  [self updateDocumentControlsForComputationConfiguration:self.currentComputationConfiguration presentationConfiguration:self.currentPresentationConfiguration chalkValue:self.currentComputationEntry.chalkValue1];

  NSString* string =
    [flag isEqual:@(1.)] ? self.currentComputationEntry.inputRawString :
    [flag isEqual:@(2.)] ? self.currentComputationEntry.outputRawString :
    self.currentComputationEntry.inputRawString;
  if (string)
  {
    BOOL oldInhibateInputTextChange = self->inhibateInputTextChange;
    self->inhibateInputTextChange = YES;
    NSText* textEditor = self->inputTextField.currentEditor;
    if (!textEditor)
      self->inputTextField.stringValue = !string ? @"" : string;
    else//if (textEditor)
    {
      textEditor.string = !string ? @"" : string;
      //[textEditor replaceCharactersInRange:textEditor.selectedRange withString:(!string ? @"" : string)];
      //textEditor.selectedRange = NSMakeRange(selectedRange.location, string.length);
    }//end if (textEditor)
    self->inhibateInputTextChange = oldInhibateInputTextChange;
  }//end if (string)
  if (self.currentComputationEntry)
  {
    [self.windowForSheet makeFirstResponder:self->inputTextField];
    NSText* textEditor = self->inputTextField.currentEditor;
    textEditor.selectedRange = NSMakeRange(textEditor.string.length, 0);
  }//end if (self.currentComputationEntry)
}
//end webViewEntrySelectionDidChangeToAge:flag:

-(void) webViewEntryWithUid:(id)uid didChangeCustomAnnotation:(id)value visible:(id)visible
{
  NSNumber* uidNumber = [uid dynamicCastToClass:[NSNumber class]];
  NSString* uidString = [uid dynamicCastToClass:[NSString class]];
  NSInteger uidInteger =
    uidNumber ? uidNumber.integerValue :
    uidString ? uidString.integerValue :
    0;
  CHComputationEntryEntity* computationEntry = [self chalkContext:self->chalkContext computationEntryForUid:uidInteger];
  [self.undoManager beginUndoGrouping];
  DebugLog(1, @"(%@) old customAnnotation = %@, old customAnnotationVisible = %@", uid, computationEntry.customAnnotation, @(computationEntry.customAnnotationVisible));
  [[self.undoManager prepareWithInvocationTarget:self] webViewEntryWithUid:uid didChangeCustomAnnotation:computationEntry.customAnnotation visible:@(computationEntry.customAnnotationVisible)];
  NSString* customAnnotation = [value dynamicCastToClass:[NSString class]];
  BOOL customAnnotationVisible = [[visible dynamicCastToClass:[NSNumber class]] boolValue];
  DebugLog(1, @"(%@) customAnnotation = %@, customAnnotationVisible = %@", uid, customAnnotation, @(customAnnotationVisible));
  computationEntry.customAnnotation = customAnnotation;
  computationEntry.customAnnotationVisible = customAnnotationVisible;
  [self->outputWebView evaluateJavaScriptFunction:@"updateEntryAnnotation" withJSONArguments:@[uid, customAnnotation, @(customAnnotationVisible)] wait:YES];
  [self.undoManager endUndoGrouping];
}
//end webViewEntryWithUid:didChangeCustomAnnotation:visible:

-(void) webViewInsertEntry:(CHComputationEntryEntity*)computationEntry atAge:(id)age
{
  DebugLog(1, @">webViewInsertEntry:%p(uid=%@) atAge:%@ (%@)", computationEntry, @(computationEntry.uniqueIdentifier), age, self.undoManager.isUndoing ? @"undoing" : self.undoManager.isRedoing ? @"redoing" : @"");
  [self.undoManager beginUndoGrouping];
  [[self.undoManager prepareWithInvocationTarget:self] webViewRemoveEntry:computationEntry];
  DebugLog(1, @"computationEntry.uniqueId : %@", @(computationEntry.uniqueIdentifier));
  [self logComputationEntries];
  if (!self.undoManager.isUndoing && !self.undoManager.isRedoing)
  {
    DebugLog(1, @"insertObject");
    [self.managedObjectContext insertObject:computationEntry];
  }//end if (!self.undoManager.isUndoing && !self.undoManager.isRedoing)
  [self logComputationEntries];

  JSDictionary* entryJSDictionary = [self jsDictionaryFromComputationEntry:computationEntry];
  if (age && entryJSDictionary)
  {
    NSArray* args = self->outputWebView.useWKView ? @[age, entryJSDictionary.dictionary] : @[age, entryJSDictionary];
    [self->outputWebView evaluateJavaScriptFunction:@"addEntry" withJSONArguments:args wait:YES];
  }//end if (age && entryJSDictionary)
  [self.undoManager endUndoGrouping];
  DebugLog(1, @"<webViewInsertEntry:atAge:");
}
//end webViewInsertEntry:atAge:

-(void) webViewRemoveEntry:(CHComputationEntryEntity*)computationEntry
{
  DebugLog(1, @">webViewRemoveEntry (%@) : %@", self.undoManager.isUndoing ? @"undoing" : self.undoManager.isRedoing ? @"redoing" : @"", @(computationEntry.uniqueIdentifier));
  [self.undoManager beginUndoGrouping];
  NSNumber* uid = !computationEntry ? nil : @(computationEntry.uniqueIdentifier);
  NSUInteger age = [self->chalkContext ageForComputationEntry:computationEntry];
  [[self.undoManager prepareWithInvocationTarget:self] webViewInsertEntry:computationEntry atAge:@(age)];
  DebugLog(1, @"computationEntry.uniqueId : %@, age %@", uid, @(age));
  [self logComputationEntries];
  NSArray* args = !uid ? nil : @[uid];
  if (args)
    [self->outputWebView evaluateJavaScriptFunction:@"removeEntryFromUid" withJSONArguments:args wait:YES];
  if (!self.undoManager.isUndoing && !self.undoManager.isRedoing)
  {
    DebugLog(1, @"delete object");
    [self.managedObjectContext deleteObject:computationEntry];
  }//end if (!self.undoManager.isUndoing && !self.undoManager.isRedoing)
  [self logComputationEntries];
  [self.undoManager endUndoGrouping];
  DebugLog(1, @"<webViewRemoveEntry");
}
//end webViewRemoveEntry:

-(void) webViewEntryShouldRemoveAge:(id)age
{
  DebugLog(1, @"webViewEntryShouldRemoveAge (%@): %@", self.undoManager.isUndoing ? @"undoing" : self.undoManager.isRedoing ? @"redoing" : @"", age);
  NSUInteger ageInteger = [[age dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
  DebugLog(1, @">webViewRemoveEntryAtAge (%@) : %@", self.undoManager.isUndoing ? @"undoing" : self.undoManager.isRedoing ? @"redoing" : @"", age);
  [self.undoManager beginUndoGrouping];
  CHComputationEntryEntity* computationEntry = [self chalkContext:self->chalkContext computationEntryForAge:ageInteger];
  [self webViewRemoveEntry:computationEntry];
  [self.undoManager endUndoGrouping];
}
//end webViewEntryShouldRemoveAge:

-(NSURL*) calculatorHTMLURL
{
  NSURL* result = [[NSBundle mainBundle] URLForResource:@"calculator" withExtension:@"html" subdirectory:@"Web"];
  return result;
}
//end calculatorHTMLURL

-(void) webViewSetCSS:(NSString*)cssFilePath
{
  NSString* calculatorHTML = [[self calculatorHTMLURL] path];
  NSString* calculatorFolder = [calculatorHTML stringByDeletingLastPathComponent];
  NSString* cssRelativeFilePath = !calculatorFolder ? nil :
    [cssFilePath stringByReplacingOccurrencesOfString:calculatorFolder withString:@""];
  cssRelativeFilePath = [cssRelativeFilePath stringByReplacingOccurrencesOfString:@"/" withString:@"" options:NSAnchoredSearch range:cssRelativeFilePath.range];
  if (![NSString isNilOrEmpty:cssRelativeFilePath])
  {
    NSString* jsCommand = [NSString stringWithFormat:@"$('link[href]').attr('href', '%@')", cssRelativeFilePath];
    [self->outputWebView evaluateJavaScript:jsCommand];
  }//end if (![NSString isNilOrEmpty:cssRelativeFilePath])
}
//end webViewSetCSS:

-(void) webViewUpdateEntry:(CHComputationEntryEntity*)computationEntry
{
  [self.undoManager beginUndoGrouping];
  [[self.undoManager prepareWithInvocationTarget:self] webViewUpdateEntry:computationEntry];
  DebugLog(1, @"webViewUpdateEntry %p (uid = %@)", computationEntry, @(computationEntry.uniqueIdentifier));
  NSArray* args = @[
    @(computationEntry.uniqueIdentifier),
    [NSObject nullAdapter:computationEntry.inputRawHTMLString],
    [NSObject nullAdapter:computationEntry.inputInterpretedHTMLString],
    [NSObject nullAdapter:computationEntry.inputInterpretedTeXString],
    [NSObject nullAdapter:computationEntry.outputHTMLString],
    [NSObject nullAdapter:computationEntry.outputTeXString],
    [NSObject nullAdapter:computationEntry.outputHtmlCumulativeFlags],
    [NSNull null], [NSNull null], [NSNull null]];
  [self->outputWebView evaluateJavaScriptFunction:@"updateEntry" withJSONArguments:args wait:YES];
  [self updateDocumentControlsForComputationConfiguration:computationEntry.computationConfiguration.computationConfiguration presentationConfiguration:computationEntry.presentationConfiguration.presentationConfiguration chalkValue:computationEntry.chalkValue1];
  if (DebugLogLevel >= 1)
    [self _displayComputationEntries];
  [self.undoManager endUndoGrouping];
}
//end webViewUpdateEntry:

-(void) webViewUpdateEntry2:(CHComputationEntryEntity*)computationEntry
{
  [self.undoManager beginUndoGrouping];
  [[self.undoManager prepareWithInvocationTarget:self] webViewUpdateEntry2:computationEntry];
  DebugLog(1, @"webViewUpdateEntry2 %p (uid = %@)", computationEntry, @(computationEntry.uniqueIdentifier));
  NSArray* args = @[
    @(computationEntry.uniqueIdentifier),
    [NSNull null], [NSNull null], [NSNull null],
    [NSObject nullAdapter:computationEntry.outputHTMLString],
    [NSObject nullAdapter:computationEntry.outputTeXString],
    [NSObject nullAdapter:computationEntry.outputHtmlCumulativeFlags],
    [NSNull null], [NSNull null], [NSNull null]];
  [self->outputWebView evaluateJavaScriptFunction:@"updateEntry" withJSONArguments:args wait:YES];
  [self updateDocumentControlsForComputationConfiguration:computationEntry.computationConfiguration.computationConfiguration presentationConfiguration:computationEntry.presentationConfiguration.presentationConfiguration chalkValue:computationEntry.chalkValue1];
  [self currentComputationEntryDidChange:nil];
  if (DebugLogLevel >= 1)
    [self _displayComputationEntries];
  [self.undoManager endUndoGrouping];
}
//end webViewUpdateEntry2:

+(NSManagedObjectModel*) managedObjectModel
{
  NSManagedObjectModel* result = nil;
  NSString* momName = NSStringFromClass([self class]);
  DebugLog(1, @"loading managedObjectModel <%@>", momName);
  NSURL* fileURL = [[NSBundle mainBundle] URLForResource:momName withExtension:@"momd"];
  result = !fileURL ? nil : [[[NSManagedObjectModel alloc] initWithContentsOfURL:fileURL] autorelease];
  return result;
}
//end managedObjectModel

+(NSString*) defaultDocumentFileName
{
  NSString* result = @"Calculator.chalk";
  return result;
}
//end defaultDocumentFileName

-(id) init
{
  if (!((self = [super init])))
    return nil;
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  self->defaultComputationConfiguration = [preferencesController.computationConfigurationCurrent copy];
  self->defaultPresentationConfiguration = [preferencesController.presentationConfigurationCurrent copy];
  self->chalkIdentifierManager = [[CHChalkIdentifierManager identifierManagerWithDefaults:YES] retain];
  self->chalkOperatorManager = [[CHChalkOperatorManager operatorManagerWithDefaults:YES] retain];
  self->chalkContext = [[CHChalkContext alloc] initWithGmpPool:[[[CHGmpPool alloc] initWithCapacity:1024] autorelease]];
  self->chalkContext.undoManager = self.undoManager;
  self->chalkContext.identifierManager = self->chalkIdentifierManager;
  self->chalkContext.operatorManager = self->chalkOperatorManager;
  self->chalkContext.delegate = self;
  self->userVariableItemsController = [[NSArrayController alloc] init];
  self->userVariableItemsController.editable = YES;
  self->userVariableItemsController.objectClass = [CHUserVariableItem class];
  self->userVariableItemsController.selectsInsertedObjects = YES;
  self->userVariableItemsController.preservesSelection = YES;
  self->userVariableItemsController.sortDescriptors =
    @[[NSSortDescriptor sortDescriptorWithKey:CHUserVariableItemNameKey ascending:YES]];
  self->userVariableItemsController.automaticallyRearrangesObjects = YES;
  self->userVariableItemsController.automaticallyPreparesContent = YES;
  self->dependencyManager = [[CHChalkItemDependencyManager alloc] init];
  [self->chalkContext.identifierManager.variablesIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkIdentifierVariable* identifier = [obj dynamicCastToClass:[CHChalkIdentifierVariable class]];
    CHUserVariableItem* userVariableItem = !identifier ? nil :
      [[[CHUserVariableItem alloc] initWithIdentifier:identifier isDynamic:NO input:nil evaluatedValue:nil context:self->chalkContext managedObjectContext:self.managedObjectContext] autorelease];
    if (userVariableItem)
    {
      [self->dependencyManager addItem:userVariableItem];
      [self->userVariableItemsController addObject:userVariableItem];
    }//end if (userVariableItem)
  }];//end for each variableIdentifier
  
  self->userFunctionItemsController = [[NSArrayController alloc] init];
  self->userFunctionItemsController.editable = YES;
  self->userFunctionItemsController.objectClass = [CHUserFunctionItem class];
  self->userFunctionItemsController.selectsInsertedObjects = YES;
  self->userFunctionItemsController.preservesSelection = YES;
  self->userFunctionItemsController.sortDescriptors =
    @[[NSSortDescriptor sortDescriptorWithKey:CHUserFunctionItemNameKey ascending:YES]];
  self->userFunctionItemsController.automaticallyRearrangesObjects = YES;
  self->userFunctionItemsController.automaticallyPreparesContent = YES;

  self->chalkValueToStringTransformer = [[CHChalkValueToStringTransformer alloc] initWithContext:self->chalkContext];
  
  self->availableThemes = [[NSMutableArray alloc] init];
  NSArray* cssFiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"css" inDirectory:@"Web"];
  [cssFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString* cssPath = [obj dynamicCastToClass:[NSString class]];
    if ([[cssPath lastPathComponent] isMatchedByRegex:@"calculator\\-theme-(.*)\\.css"])
      [self->availableThemes addObject:cssPath];
  }];
  
  return self;
}
//end init

-(void) dealloc
{
  [self->currentTheme release];
  self->currentTheme = nil;
  [self->availableThemes release];
  [self->svgRenderer dealloc];
  [self->defaultComputationConfiguration release];
  [self->defaultPresentationConfiguration release];
  [self->computeChalkContext release];
  [self->eventMonitor release];
  [self->currentComputationEntry release];
  self->currentComputationEntry = nil;
  [self->digitsInspectorControl release];
  [self->chalkValueToStringTransformer release];
  [self->userVariableItemsController release];
  [self->userFunctionItemsController release];
  [self->dependencyManager release];
  [self->chalkIdentifierManager release];
  [self->chalkOperatorManager release];
  [self->ans0 release];
  [self->chalkContext release];
  self->chalkContext = nil;
  [super dealloc];
}
//end dealloc

-(NSString*) windowNibName
{
  return @"CHCalculatorDocument";
}
//end windowNibName

-(BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  BOOL result = [super validateMenuItem:menuItem];
  if (menuItem.action == @selector(runPageLayout:))
  {
    menuItem.title = NSLocalizedString(@"Page Setup...", @"");
    result = YES;
  }//end if (menuItem.action == @selector(runPageLayout:))
  else if (menuItem.action == @selector(printDocument:))
  {
    menuItem.title = NSLocalizedString(@"Print...", @"");
    result = YES;
  }//end if (menuItem.action == @selector(printDocument:))
  else if (menuItem.action == @selector(calculatorRemoveCurrentItem:))
  {
    result = (self.currentComputationEntry != nil);
  }//end if (menuItem.action == @selector(calculatorRemoveCurrentItem:))
  else if (menuItem.action == @selector(calculatorRemoveAllItems:))
  {
    result = (self.currentComputationEntry != nil);
    if (!result)
    {
      NSError* error = nil;
      NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
      fetchRequest.includesPendingChanges = YES;
      
      NSUInteger count = 0;
      @try{
        error = nil;
        count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
        result |= (count > 0);
      }
      @catch(NSException* e){
        DebugLog(0, @"exception : <%@>", e);
      }
    }//end if (!result)
  }//end if (menuItem.action == @selector(calculatorRemoveAllItems:))
  return result;
}
//end validateMenuItem:

-(void) canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void*)contextInfo
{
  if (self.isDefaultDocument)
  {
    [self.windowForSheet orderOut:self];
    [self stopComputing:self];
  }//end if (self.isDefaultDocument)
  else
    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}
//end canCloseDocumentWithDelegate:shouldCloseSelector:contextInfo:

-(void) close
{
  [self stopComputing:self];
  self.currentComputationEntry = nil;
  [self->scheduledComputationEntry release];
  self->scheduledComputationEntry = nil;
  self.currentTheme = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self->inspectorBottomView];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTableViewSelectionDidChangeNotification object:self->userVariableItemsTableView];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTableViewSelectionDidChangeNotification object:self->userFunctionItemsTableView];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
  [super close];
}
//end close

-(NSInteger) createUniqueIdentifier
{
  NSInteger result = 0;

  NSError* error = nil;
  NSArray* fetchResult = nil;
  NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
  fetchRequest.includesPendingChanges = YES;
  NSUInteger count = 0;
  @try{
    error = nil;
    count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    DebugLog(1, @"there are %@ entities", @(count));
    if (error)
      DebugLog(1, @"countForFetchRequest error <%@>", error);
  }
  @catch(NSException* e){
    DebugLog(0, @"exception : <%@>", e);
  }

  NSExpression* keyExpression = [NSExpression expressionForKeyPath:@"uniqueIdentifier"];
  NSExpression* maxExpression = [NSExpression expressionForFunction:@"max:" arguments:@[keyExpression]];
  NSExpressionDescription* maxExpressionDescription = [[[NSExpressionDescription alloc] init] autorelease];
  [maxExpressionDescription setName:@"maxUniqueIdentifier"];
  [maxExpressionDescription setExpression:maxExpression];
  [maxExpressionDescription setExpressionResultType:NSInteger64AttributeType];
  
  fetchRequest.resultType = NSDictionaryResultType;
  fetchRequest.propertiesToFetch = @[maxExpressionDescription];
  @try{
    error = nil;
    @synchronized(self.managedObjectContext)
    {
      fetchResult = !count ? nil : [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }//end @synchronized(self.managedObjectContext)
    DebugLog(1, @"fetchResult = %@", fetchResult);
    if (error)
      DebugLog(1, @"countForFetchRequest = %@, error = <%@>", @(count), error);
  }
  @catch(NSException* e){
    DebugLog(0, @"exception : <%@>", e);
  }

  NSDictionary* fetchedDictionary = [fetchResult.lastObject dynamicCastToClass:[NSDictionary class]];
  NSNumber* fetchedUniqueIdentifier = [[fetchedDictionary objectForKey:@"maxUniqueIdentifier"] dynamicCastToClass:[NSNumber class]];
  result =
    fetchedUniqueIdentifier ? fetchedUniqueIdentifier.integerValue+1 :
    1;
  DebugLog(1, @"self->currentUniqueIdentifier = %@", @(result));

  return result;
}
//end createUniqueIdentifier

-(BOOL) configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(nullable NSString *)configuration storeOptions:(nullable NSDictionary<NSString *, id> *)storeOptions error:(NSError **)error
{
  BOOL result = NO;
  NSMutableDictionary<NSString *, id>* newStoreOptions = [NSMutableDictionary dictionary];
  if (storeOptions)
    [newStoreOptions addEntriesFromDictionary:storeOptions];
  NSDictionary* defaultOptions = @{
    NSSQLitePragmasOption:@{@"journal_mode":@"DELETE"},
    NSMigratePersistentStoresAutomaticallyOption:@YES,
    NSInferMappingModelAutomaticallyOption:@YES};
  [newStoreOptions addEntriesFromDictionary:defaultOptions];
  result = [super configurePersistentStoreCoordinatorForURL:url ofType:fileType modelConfiguration:configuration storeOptions:newStoreOptions error:error];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
  self->userVariableItemsTableView.undoManager = self.undoManager;
  self->userFunctionItemsTableView.undoManager = self.undoManager;
  return result;
}
//end configurePersistentStoreCoordinatorForURL:ofType:modelConfiguration:storeOptions:error:

-(BOOL) readFromURL:(NSURL*)absoluteURL ofType:(NSString *)typeName error:(NSError * _Nullable *)error
{
  BOOL result = NO;
  result = [super readFromURL:absoluteURL ofType:typeName error:error];
  return result;
}
//end readFromURL:ofType:error:

-(BOOL) revertToContentsOfURL:(NSURL*)url ofType:(NSString *)typeName error:(NSError **)outError
{
  BOOL result = NO;
  result = [super revertToContentsOfURL:url ofType:typeName error:outError];
  return result;
}
//end revertToContentsOfURL:ofType:error:

-(void) windowControllerDidLoadNib:(NSWindowController*)aController
{
  [super windowControllerDidLoadNib:aController];

  [self.windowForSheet makeFirstResponder:self->inputTextField];
  [self.undoManager disableUndoRegistration];
  
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  NSData* settingsData = [CHDocumentDataEntity getDataInManagedObjectContext:self.managedObjectContext];

  self->themesToolbarItem.label = NSLocalizedString(@"Theme", @"");
  __block NSString* defaultTheme = nil;
  [self->availableThemes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString* cssFilePath = [obj dynamicCastToClass:[NSString class]];
    NSString* cssFileName = cssFilePath.lastPathComponent;
    if ([cssFileName isEqualToString:@"calculator-theme-default.css"])
      defaultTheme = cssFilePath;
  }];
  if (!defaultTheme)
    defaultTheme = self->availableThemes.firstObject;
  [defaultTheme retain];
  [self->availableThemes removeObject:defaultTheme];
  [self->availableThemes insertObject:defaultTheme atIndex:0];
  [defaultTheme release];

  [self->availableThemes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString* cssFilePath = [obj dynamicCastToClass:[NSString class]];
    NSString* name = [[[cssFilePath captureComponentsMatchedByRegex:@"calculator\\-theme-(.*)\\.css"] lastObject] dynamicCastToClass:[NSString class]];
    if (![NSString isNilOrEmpty:name])
      [self->themesPopUpButton.menu addItemWithTitle:name tag:(NSInteger)idx action:@selector(toolbarAction:) target:self];
  }];
  
  [self->outputWebView setExternalObject:self forJSKey:@"calculatorDocument"];
  self->outputWebView.webDelegate = self;
  self.currentTheme = defaultTheme;

  self->inputTextField.enabled = NO;

  if (!self->digitsInspectorControl)
    self->digitsInspectorControl = [[CHDigitsInspectorControl alloc] initWithNibName:@"CHDigitsInspectorControl" bundle:[NSBundle mainBundle]];
  [self->inspectorBottomView addSubview:self->digitsInspectorControl.view];
  [self->inspectorBottomView centerInParentHorizontally:YES vertically:NO];
  self->digitsInspectorControl.view.autoresizingMask = NSViewWidthSizable;
  [self->digitsInspectorControl.view centerInParentHorizontally:YES vertically:NO];
  self->digitsInspectorControl.view.frame = self->inspectorBottomView.frame;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self->inspectorBottomView];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
  self->digitsInspectorControl.delegate = self;

  self->computeOptionSoftFloatDisplayBitsLabel.stringValue = NSLocalizedString(@"Digits displayed", @"");
  self->computeOptionOutputBaseLabel.stringValue = NSLocalizedString(@"Output base", @"");
  self->computeOptionIntegerGroupSizeLabel.stringValue = NSLocalizedString(@"Group digits by", @"");
  
  self->inputPopUpButton.title = NSLocalizedString(@"Input...", @"");
  self->outputPopUpButton.title = NSLocalizedString(@"Output...", @"");
  self->inputColorColorWell.color = preferencesController.exportInputColor;
  self->outputColorColorWell.color = preferencesController.exportOutputColor;

  NSMenuItem* firstMenuItem = nil;
  firstMenuItem = [[self->inputPopUpButton.menu.itemArray.firstObject retain] autorelease];
  [self->inputPopUpButton.menu removeAllItems];
  [self->inputPopUpButton.menu addItem:firstMenuItem];
  [self->inputPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy to clipboard as PDF", @"")
    tag:CHALK_EXPORT_FORMAT_PDF action:@selector(feedPasteboard:) target:self];
  [self->inputPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy to clipboard as SVG", @"")
    tag:CHALK_EXPORT_FORMAT_SVG action:@selector(feedPasteboard:) target:self];
  [self->inputPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy to clipboard as string", @"")
    tag:CHALK_EXPORT_FORMAT_STRING action:@selector(feedPasteboard:) target:self];
  firstMenuItem = [[self->outputPopUpButton.menu.itemArray.firstObject retain] autorelease];
  [self->outputPopUpButton.menu removeAllItems];
  [self->outputPopUpButton.menu addItem:firstMenuItem];
  [self->outputPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy to clipboard as PDF", @"")
    tag:CHALK_EXPORT_FORMAT_PDF action:@selector(feedPasteboard:) target:self];
  [self->outputPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy to clipboard as SVG", @"")
    tag:CHALK_EXPORT_FORMAT_SVG action:@selector(feedPasteboard:) target:self];
  [self->outputPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy to clipboard as string", @"")
    tag:CHALK_EXPORT_FORMAT_STRING action:@selector(feedPasteboard:) target:self];

  self->variablesLabel.stringValue = NSLocalizedString(@"Variables", @"");
  self->userVariableItemsTableView.arrayController = self->userVariableItemsController;
  [[self->userVariableItemsTableView tableColumnWithIdentifier:CHUserVariableItemIsDynamicKey].headerCell setStringValue:NSLocalizedString(@"Dyn.", @"")];
  [[self->userVariableItemsTableView tableColumnWithIdentifier:CHUserVariableItemNameKey].headerCell setStringValue:NSLocalizedString(@"Name", @"")];
  [[self->userVariableItemsTableView tableColumnWithIdentifier:CHUserVariableItemEvaluatedValueAttributedStringKey].headerCell setStringValue:NSLocalizedString(@"Value", @"")];
  self->userVariableItemsTableView.delegate = self;
  self->userVariableItemsTableView.dataSource = self;
  self->userVariableItemsTableView.target = self;
  self->userVariableItemsTableView.doubleAction = @selector(doubleAction:);
  self->userVariableItemsTableView.undoManager = self.undoManager;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:self->userVariableItemsTableView];

  self->functionsLabel.stringValue = NSLocalizedString(@"Functions", @"");
  self->userFunctionItemsTableView.arrayController = self->userFunctionItemsController;
  [[self->userFunctionItemsTableView tableColumnWithIdentifier:CHUserFunctionItemNameKey].headerCell setStringValue:NSLocalizedString(@"Name", @"")];
  [[self->userFunctionItemsTableView tableColumnWithIdentifier:CHUserFunctionItemDefinitionKey].headerCell setStringValue:NSLocalizedString(@"Definition", @"")];
  self->userFunctionItemsTableView.delegate = self;
  self->userFunctionItemsTableView.dataSource = self;
  self->userFunctionItemsTableView.target = self;
  self->userFunctionItemsTableView.doubleAction = @selector(doubleAction:);
  self->userFunctionItemsTableView.undoManager = self.undoManager;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:self->userFunctionItemsTableView];

  [self->inputProgressIndicator bind:@"animated" toObject:self withKeyPath:@"isComputing" options:nil];
  NSSegmentedCell* computeModeSegmentedCell = [self->computeOptionComputeModeSegmentedControl.cell dynamicCastToClass:[NSSegmentedCell class]];
  [computeModeSegmentedCell setTag:CHALK_COMPUTE_MODE_EXACT forSegment:0];
  [computeModeSegmentedCell setTag:CHALK_COMPUTE_MODE_APPROX_BEST forSegment:1];
  [computeModeSegmentedCell setTag:CHALK_COMPUTE_MODE_APPROX_INTERVALS forSegment:2];
  [computeModeSegmentedCell setToolTip:NSLocalizedString(@"Exact mode, does not accept rounding or approximations", @"") forSegment:0];
  [computeModeSegmentedCell setToolTip:NSLocalizedString(@"Approximation mode, exact as long as possible but performs approximations when needed", @"") forSegment:1];
  [computeModeSegmentedCell setToolTip:NSLocalizedString(@"Interval mode, exact as long as possible but performs approximations when needed, and reports uncertainty", @"") forSegment:2];
  [self->progressIndicator startAnimation:self];
  
  self->computeOptionSoftFloatDisplayBitsLabel.toolTip = NSLocalizedString(@"__DISPLAY_BITS__", @"");
  self->computeOptionSoftFloatDisplayBitsSlider.toolTip = NSLocalizedString(@"__DISPLAY_BITS__", @"");
  self->computeOptionSoftFloatDisplayBitsStepper.toolTip = NSLocalizedString(@"__DISPLAY_BITS__", @"");
  self->computeOptionSoftFloatDisplayBitsTextField.toolTip = NSLocalizedString(@"__DISPLAY_BITS__", @"");

  self->inputComputeButton.toolTip = NSLocalizedString(@"Press alt and shift to change computation mode", @"");
 
  if (!self->outputWebView.URL)
  {
    NSURLCache* sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSURL* webPageUrl = [self calculatorHTMLURL];
    @try{
      NSHTTPCookieStorage* cookieJar = !webPageUrl ? nil : [NSHTTPCookieStorage sharedHTTPCookieStorage];
      NSArray* cookies = [cookieJar cookiesForURL:[NSURL URLWithString:webPageUrl.absoluteString]];
      for(NSHTTPCookie* cookie in cookies)
        [cookieJar deleteCookie:cookie];
    }
    @catch(NSException* e){
      DebugLog(0, @"deleteCookie exception <%@>", e);
    }
    self->outputWebView.URL = webPageUrl;
  }//end if (!self->outputWebView.URL)
  self.windowForSheet.delegate = self;
  
  NSButton* inspectorLeftToolbarItemButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
  inspectorLeftToolbarItemButton.image = [NSImage imageNamed:@"inspector-left-off"];
  inspectorLeftToolbarItemButton.alternateImage = [NSImage imageNamed:@"inspector-left-on"];
  inspectorLeftToolbarItemButton.imagePosition = NSImageOnly;
  inspectorLeftToolbarItemButton.bordered = NO;
  inspectorLeftToolbarItemButton.buttonType = NSToggleButton;
  inspectorLeftToolbarItemButton.state = self->inspectorLeftView.hidden ? NSOffState : NSOnState;
  inspectorLeftToolbarItemButton.target = self;
  inspectorLeftToolbarItemButton.action = @selector(toolbarAction:);
  [[inspectorLeftToolbarItemButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
  self->inspectorLeftToolbarItem.view = inspectorLeftToolbarItemButton;
  [inspectorLeftToolbarItemButton release];
  
  NSButton* inspectorRightToolbarItemButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
  inspectorRightToolbarItemButton.image = [NSImage imageNamed:@"inspector-right-off"];
  inspectorRightToolbarItemButton.alternateImage = [NSImage imageNamed:@"inspector-right-on"];
  inspectorRightToolbarItemButton.imagePosition = NSImageOnly;
  inspectorRightToolbarItemButton.bordered = NO;
  inspectorRightToolbarItemButton.buttonType = NSToggleButton;
  inspectorRightToolbarItemButton.state = self->inspectorRightView.hidden ? NSOffState : NSOnState;
  inspectorRightToolbarItemButton.target = self;
  inspectorRightToolbarItemButton.action = @selector(toolbarAction:);
  [[inspectorRightToolbarItemButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
  self->inspectorRightToolbarItem.view = inspectorRightToolbarItemButton;
  [inspectorRightToolbarItemButton release];
  
  NSButton* inspectorBottomToolbarItemButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
  inspectorBottomToolbarItemButton.image = [NSImage imageNamed:@"inspector-bottom-off"];
  inspectorBottomToolbarItemButton.alternateImage = [NSImage imageNamed:@"inspector-bottom-on"];
  inspectorBottomToolbarItemButton.imagePosition = NSImageOnly;
  inspectorBottomToolbarItemButton.bordered = NO;
  inspectorBottomToolbarItemButton.buttonType = NSToggleButton;
  inspectorBottomToolbarItemButton.state = self->inspectorBottomView.hidden ? NSOffState : NSOnState;
  inspectorBottomToolbarItemButton.target = self;
  inspectorBottomToolbarItemButton.action = @selector(toolbarAction:);
  [[inspectorBottomToolbarItemButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
  self->inspectorBottomToolbarItem.view = inspectorBottomToolbarItemButton;
  [inspectorBottomToolbarItemButton release];

  self->inspectorLeftView.anchor = CHINSPECTOR_ANCHOR_LEFT;
  self->inspectorRightView.anchor = CHINSPECTOR_ANCHOR_RIGHT;
  self->inspectorBottomView.anchor = CHINSPECTOR_ANCHOR_BOTTOM;
  self->inspectorLeftView.delegate = self;
  self->inspectorRightView.delegate = self;
  self->inspectorBottomView.delegate = self;
  [self inspectorVisibilityDidChange:nil];
  
  NSError* error = nil;
  [self.managedObjectContext.undoManager disableUndoRegistration];
  NSDictionary* settingsPlist = !settingsData ? nil : [NSPropertyListSerialization propertyListWithData:settingsData options:NSPropertyListImmutable format:0 error:&error];
  NSNumber* inspectorLeftVisible = [[settingsPlist objectForKey:@"inspectorLeftVisible"] dynamicCastToClass:[NSNumber class]];
  NSNumber* inspectorRightVisible = [[settingsPlist objectForKey:@"inspectorRightVisible"] dynamicCastToClass:[NSNumber class]];
  NSNumber* inspectorBottomVisible = [[settingsPlist objectForKey:@"inspectorBottomVisible"] dynamicCastToClass:[NSNumber class]];
  if (inspectorLeftVisible)
    self->inspectorLeftView.visible = inspectorLeftVisible.boolValue;
  else
    self->inspectorLeftView.visible = NO;
  if (inspectorRightVisible)
    self->inspectorRightView.visible = inspectorRightVisible.boolValue;
  else
    self->inspectorRightView.visible = YES;
  if (inspectorBottomVisible)
    self->inspectorBottomView.visible = inspectorBottomVisible.boolValue;
  else
    self->inspectorBottomView.visible = NO;
  [self.managedObjectContext.undoManager enableUndoRegistration];

  [self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:nil]];

  [self updateGuiForPreferences];
  [self.undoManager enableUndoRegistration];
  self->nibLoaded = YES;

  [self.undoManager removeAllActions];
  NSArray* documents = [[NSDocumentController sharedDocumentController] documents];
  if (!documents.count || ((documents.count == 1) && (documents.lastObject == self)))
    self.fileURL = [CHCalculatorDocument defaultDocumentFileURL];
//  self.isAutosaveDocument |= !self.fileURL && !self.autosavedContentsFileURL;
  
  if (!self->eventMonitor)
  {
    __weak __block CHCalculatorDocument* document = self;
    self->eventMonitor = [[NSEvent addLocalMonitorForEventsMatchingMask:NSFlagsChangedMask
              handler:^(NSEvent *incomingEvent) {
                CHCalculatorDocument* localDocument = document;
                if (localDocument->nibLoaded)
                  [localDocument updateDocumentControls:localDocument->eventMonitor];
                return incomingEvent;
              }] retain];
  }//end if (!self->eventMonitor)
  [self performSelector:@selector(updateGUIFromManagedObjectContext) withObject:nil afterDelay:0];
}
//end windowControllerDidLoadNib:

-(void) updateGUIFromManagedObjectContext
{
  if (self.managedObjectContext)
  {
    [self->dependencyManager removeAllItems];
    self->userVariableItemsController.content = [NSMutableArray array];
    self->userFunctionItemsController.content = [NSMutableArray array];
      
    BOOL loadUserVariableItems = YES;
    if (loadUserVariableItems)
    {
      [self.undoManager disableUndoRegistration];
      NSError* error = nil;
      NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHUserVariableEntity entityName]];
      fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifierName" ascending:YES]];
      fetchRequest.includesPendingChanges = YES;
      NSArray* userVariableEntities = nil;
      @synchronized(self.managedObjectContext)
      {
        userVariableEntities = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
      }//end @synchronized(self.managedObjectContext)
      NSMutableArray* updatedUserVariableItems = [NSMutableArray array];
      [userVariableEntities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHUserVariableEntity* userVariableEntity = [obj dynamicCastToClass:[CHUserVariableEntity class]];
        CHUserVariableItem* userVariableItem = !userVariableEntity ? nil :
          [[[CHUserVariableItem alloc] initWithUserVariableEntity:userVariableEntity context:self->chalkContext] autorelease];
        if (userVariableItem)
        {
          userVariableItem.evaluatedValue = userVariableEntity.chalkValue1;
          [self->dependencyManager addItem:userVariableItem];
          [self->userVariableItemsController addObject:userVariableItem];
          [updatedUserVariableItems addObject:userVariableItem];
        }//end if (userVariableItem)
      }];//end for each userVariableEntity
      [updatedUserVariableItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHUserVariableItem* userVariableItem = [obj dynamicCastToClass:[CHUserVariableItem class]];
        [userVariableItem refreshIdentifierDependencies];
      }];
      NSMutableArray* dirtyUserVariableItems = [NSMutableArray array];
      NSArray* dirtyIdentifiers = [self->dependencyManager identifierDependentObjectsToUpdateFrom:updatedUserVariableItems];
      [dirtyIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
        if (![updatedUserVariableItems containsObject:identifierDependent])
          [identifierDependent refreshIdentifierDependencies];
        [dirtyUserVariableItems safeAddObject:[obj dynamicCastToClass:[CHUserVariableItem class]]];
      }];//end for each curveItem
      [dirtyUserVariableItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[obj dynamicCastToClass:[CHUserVariableItem class]] performEvaluation];
      }];//end for each dirtyUserVariableItem
      [self->userVariableItemsTableView reloadData];
      [self.undoManager enableUndoRegistration];
    }//end if (loadUserVariableItems)
    
    BOOL loadUserFunctionsItems = YES;
    if (loadUserFunctionsItems)
    {
      [self.undoManager disableUndoRegistration];
      NSError* error = nil;
      NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHUserFunctionEntity entityName]];
      fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifierName" ascending:YES]];
      fetchRequest.includesPendingChanges = YES;
      NSArray* userFunctionEntities = nil;
      @synchronized(self.managedObjectContext)
      {
        userFunctionEntities = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
      }//end @synchronized(self.managedObjectContext)
      [userFunctionEntities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CHUserFunctionEntity* userFunctionEntity = [obj dynamicCastToClass:[CHUserFunctionEntity class]];
        CHUserFunctionItem* userFunctionItem = !userFunctionEntity ? nil :
          [[[CHUserFunctionItem alloc] initWithUserFunctionEntity:userFunctionEntity context:self->chalkContext] autorelease];
        if (userFunctionItem)
          [self->userFunctionItemsController addObject:userFunctionItem];
      }];//end for each userVariableEntity
      [self->userFunctionItemsTableView reloadData];
      [self.undoManager enableUndoRegistration];
    }//end if (loadUserFunctionsItems)
    
    [self updateDocumentControlsForComputationConfiguration:self.currentComputationConfiguration presentationConfiguration:self.currentPresentationConfiguration chalkValue:self.currentComputationEntry.chalkValue1];
  }//end if (self.managedObjectContext)
}
//end updateGUIFromManagedObjectContext

-(void) webviewDidLoad:(CHWebView* _Nonnull)webview
{
  NSError* error = nil;

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, webview.useWKView ? 0 : 1000000000Ull/10), dispatch_get_main_queue(), ^() {
    [webview evaluateJavaScriptFunction:@"configureMathJax" withJSONArguments:@[@"mathjax/current/tex-svg-full.js"] wait:NO];
  });

  NSData* settingsData = [CHDocumentDataEntity getDataInManagedObjectContext:self.managedObjectContext];
  NSDictionary* settingsPlist = !settingsData ? nil :[NSPropertyListSerialization propertyListWithData:settingsData options:NSPropertyListImmutable format:0 error:&error];
  NSString* savedTheme = [[settingsPlist objectForKey:@"currentTheme"] dynamicCastToClass:[NSString class]];
  if (savedTheme && [self->availableThemes containsObject:savedTheme])
    self.currentTheme = savedTheme;

  NSString* jsCode =
    [NSString stringWithFormat:
      @"setLocalizedString('%@','%@');"\
      @"setLocalizedString('%@','%@');"\
      @"setLocalizedString('%@','%@');",
      @"output",
      [NSLocalizedString(@"output", @"") stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"],
      @"output from bits inspector",
      [NSLocalizedString(@"output from bits inspector", @"") stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"],
      @"type any custom annotation here",
      [NSLocalizedString(@"type any custom annotation here", @"") stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
  [webview evaluateJavaScript:jsCode];
}
//end webviewDidLoad:

-(void) jsDidLoad:(CHWebView* _Nonnull)webview
{
  DebugLog(1, @"jsDidLoad");
  if (DebugLogLevel >= 1)
    [webview evaluateJavaScript:@"debugLogEnable([true,true])"];
  [webview setExternalObject:self forJSKey:@"calculatorDocument"];
}
//end jsDidLoad:

-(void) windowDidResize:(NSNotification*)notification
{
  [self->outputWebView setScrollerElasticity:NSScrollElasticityNone];
}
//end windowDidResize:

-(void) windowWillClose:(NSNotification*)notification
{
  if (self->eventMonitor)
  {
    [NSEvent removeMonitor:self->eventMonitor];
    [self->eventMonitor release];
    self->eventMonitor = nil;
  }//end if (self->eventMonitor)
  [self->outputWebView setExternalObject:nil forJSKey:@"calculatorDocument"];
  self->outputWebView.webDelegate = nil;
  [self saveGUIState:nil saveDocument:NO];
}
//end windowWillClose:

-(void) viewFrameDidChange:(NSNotification*)notification
{
  if (notification.object == self->inspectorBottomView)
    [self->digitsInspectorControl.view centerInParentHorizontally:YES vertically:NO];
}
//end viewFrameDidChange:

-(IBAction) changeColor:(id)sender
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  if (sender == self->inputColorColorWell)
    preferencesController.exportInputColor = self->inputColorColorWell.color;
  else if (sender == self->outputColorColorWell)
    preferencesController.exportOutputColor = self->outputColorColorWell.color;
}
//end changeColor:

-(IBAction) toolbarAction:(id)sender
{
  if (self->isAnimating)
    dispatch_after(.1, dispatch_get_main_queue(), ^{
      [self toolbarAction:sender];
    });
  else if ((sender == self->inspectorLeftToolbarItem)  || (sender == self->inspectorLeftToolbarItem.view))
    self->inspectorLeftView.visible = !self->inspectorLeftView.visible;
  else if ((sender == self->inspectorRightToolbarItem)  || (sender == self->inspectorRightToolbarItem.view))
    self->inspectorRightView.visible = !self->inspectorRightView.visible;
  else if ((sender == self->inspectorBottomToolbarItem)  || (sender == self->inspectorBottomToolbarItem.view))
    self->inspectorBottomView.visible = !self->inspectorBottomView.visible;
  else if ([self->themesPopUpButton.menu.itemArray containsObject:sender])
  {
    NSInteger tag = [sender tag];
    NSString* cssFilePath = (tag >= 0) && (tag < self->availableThemes.count) ? [self->availableThemes objectAtIndex:tag] : nil;
    self.currentTheme = cssFilePath;
  }//end if (sender == self->themesPopUpButton)
}
//end toolbarAction:

-(void) inspectorVisibilityDidChange:(NSNotification*)notification
{
  id sender = notification.object;
  BOOL isLeftSender = !sender || (sender == self->inspectorLeftView);
  BOOL isRightSender = !sender || (sender == self->inspectorRightView);
  BOOL isBottomSender = !sender || (sender == self->inspectorBottomView);
  BOOL isInspectorLeftViewHidden = self->inspectorLeftView.hidden;
  BOOL isInspectorRightViewHidden = self->inspectorRightView.hidden;
  BOOL isInspectorBottomViewHidden = self->inspectorBottomView.hidden;
  BOOL nextInspectorLeftViewHidden  = isLeftSender ? !inspectorLeftView.visible : isInspectorLeftViewHidden;
  BOOL nextInspectorRightViewHidden = isRightSender ? !inspectorRightView.visible : isInspectorRightViewHidden;
  BOOL nextInspectorBottomViewHidden = isBottomSender ? !inspectorBottomView.visible : isInspectorBottomViewHidden;
  
  CGFloat leftWidth = nextInspectorLeftViewHidden ? 0 : [self->inspectorLeftView.subviews.firstObject frame].size.width;
  CGFloat rightWidth = nextInspectorRightViewHidden ? 0 : [self->inspectorRightView.subviews.firstObject frame].size.width;
  NSSize bottomSize = nextInspectorBottomViewHidden ? NSZeroSize : [self->digitsInspectorControl.view.subviews.firstObject frame].size;
  CGSize centerMinSize = CGSizeMake(64, 64);
  NSSize windowMinSize = NSMakeSize(
    MAX(leftWidth+centerMinSize.width+rightWidth, bottomSize.width),
    bottomSize.height+centerMinSize.height);
  NSWindow* window = self.windowForSheet;
  NSRect minRect = [window frameRectForContentRect:NSMakeRect(0, 0, windowMinSize.width, windowMinSize.height)];
  window.minSize = minRect.size;

  CGRect nextWindowFrame = window.frame;
  nextWindowFrame.size.width = MAX(nextWindowFrame.size.width, windowMinSize.width);
  nextWindowFrame.size.height = MAX(nextWindowFrame.size.height, windowMinSize.height);
  CGRect nextContentFrame = [window contentRectForFrameRect:nextWindowFrame];
  [window setFrame:nextWindowFrame display:YES animate:YES];

  CGRect currCenterViewFrame     = NSRectToCGRect(self->centerView.frame);
  CGRect currInspectorLeftFrame  = NSRectToCGRect(self->inspectorLeftView.frame);
  CGRect currInspectorRightFrame = NSRectToCGRect(self->inspectorRightView.frame);
  CGRect currInspectorBottomFrame = NSRectToCGRect(self->inspectorBottomView.frame);
  CGRect nextCenterViewFrame     = currCenterViewFrame;
  CGRect nextInspectorLeftFrame  = currInspectorLeftFrame;
  CGRect nextInspectorRightFrame = currInspectorRightFrame;
  CGRect nextInspectorBottomFrame = currInspectorBottomFrame;
  CGRect contentFrame =
    NSRectToCGRect(((NSView*)[window.contentView dynamicCastToClass:[NSView class]]).frame);

  if (!nextInspectorLeftViewHidden)
    nextInspectorLeftFrame.origin.x = 0;
  else//if (nextInspectorLeftViewHidden)
    nextInspectorLeftFrame.origin.x = -nextInspectorLeftFrame.size.width;

  if (!nextInspectorRightViewHidden)
    nextInspectorRightFrame.origin.x = nextContentFrame.size.width-nextInspectorRightFrame.size.width;
  else//if (nextInspectorRightViewHidden)
    nextInspectorRightFrame.origin.x = nextContentFrame.size.width;

  if (!nextInspectorBottomViewHidden)
    nextInspectorBottomFrame.origin.y = 0;
  else//if (nextInspectorBottomViewHidden)
    nextInspectorBottomFrame.origin.y = -nextInspectorBottomFrame.size.height;

  nextCenterViewFrame.origin.x = CGRectGetMaxX(nextInspectorLeftFrame);
  nextCenterViewFrame.size.width =
    CGRectGetMinX(nextInspectorRightFrame)-CGRectGetMaxX(nextInspectorLeftFrame);
  nextCenterViewFrame.origin.y = CGRectGetMaxY(nextInspectorBottomFrame);
  nextCenterViewFrame.size.height =
    contentFrame.size.height-CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorLeftFrame.origin.y = CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorLeftFrame.size.height =
    contentFrame.size.height-CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorRightFrame.origin.y = CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorRightFrame.size.height =
    contentFrame.size.height-CGRectGetMaxY(nextInspectorBottomFrame);

  if (!nextInspectorLeftViewHidden)
    self->inspectorLeftView.hidden = nextInspectorLeftViewHidden;
  if (!nextInspectorRightViewHidden)
    self->inspectorRightView.hidden = nextInspectorRightViewHidden;
  if (!nextInspectorBottomViewHidden)
    self->inspectorBottomView.hidden = nextInspectorBottomViewHidden;
  
  BOOL shouldAnimate = self->nibLoaded && (notification != nil);
  if (!shouldAnimate)
  {
    self->inspectorLeftView.hidden = nextInspectorLeftViewHidden;
    self->inspectorRightView.hidden = nextInspectorRightViewHidden;
    self->inspectorBottomView.hidden = nextInspectorBottomViewHidden;
    [self->inspectorLeftView setFrame:NSRectFromCGRect(nextInspectorLeftFrame)];
    [self->centerView setFrame:NSRectFromCGRect(nextCenterViewFrame)];
    [self->inspectorRightView setFrame:NSRectFromCGRect(nextInspectorRightFrame)];
    [self->inspectorBottomView setFrame:NSRectFromCGRect(nextInspectorBottomFrame)];
  }//end if (!shouldAnimate)
  else//if (shouldAnimate)
  {
    self->isAnimating = YES;
    NSResponder* oldFirstResponder = [self.windowForSheet firstResponder];
    NSText* oldFirstResponderAsText = [oldFirstResponder dynamicCastToClass:[NSText class]];
    BOOL isFieldEditor = oldFirstResponderAsText.isFieldEditor;
    NSResponder* fieldEditorDelegateResponder = [(NSObject*)oldFirstResponderAsText.delegate dynamicCastToClass:[NSResponder class]];
    [self.windowForSheet makeFirstResponder:nil];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
      if (nextInspectorLeftViewHidden)
        self->inspectorLeftView.hidden = nextInspectorLeftViewHidden;
      if (nextInspectorRightViewHidden)
        self->inspectorRightView.hidden = nextInspectorRightViewHidden;
      if (nextInspectorBottomViewHidden)
        self->inspectorBottomView.hidden = nextInspectorBottomViewHidden;
      if (fieldEditorDelegateResponder)
        [self.windowForSheet makeFirstResponder:fieldEditorDelegateResponder];
      else if (oldFirstResponder && !isFieldEditor)
        [self.windowForSheet makeFirstResponder:oldFirstResponder];
      self->isAnimating = NO;
    }];//end setCompletionHandler:
    [[NSAnimationContext currentContext] setDuration:0.5];
    [[self->inspectorLeftView animator] setFrame:NSRectFromCGRect(nextInspectorLeftFrame)];
    [[self->centerView animator] setFrame:NSRectFromCGRect(nextCenterViewFrame)];
    [[self->inspectorRightView animator] setFrame:NSRectFromCGRect(nextInspectorRightFrame)];
    [[self->inspectorBottomView animator] setFrame:NSRectFromCGRect(nextInspectorBottomFrame)];
    [NSAnimationContext endGrouping];
  }//end if (shouldAnimate)
  
  [[self->inspectorLeftToolbarItem.view dynamicCastToClass:[NSButton class]] setState:nextInspectorLeftViewHidden ? NSOffState : NSOnState];
  [[self->inspectorRightToolbarItem.view dynamicCastToClass:[NSButton class]] setState:nextInspectorRightViewHidden ? NSOffState : NSOnState];
  [[self->inspectorBottomToolbarItem.view dynamicCastToClass:[NSButton class]] setState:nextInspectorBottomViewHidden ? NSOffState : NSOnState];
  if (notification && self->nibLoaded)
    [self saveGUIState:nil saveDocument:YES];
  
  if (isBottomSender && !nextInspectorBottomViewHidden)
    [self currentComputationEntryDidChange:nil];//force inspector refresh
}
//end inspectorVisibilityDidChange:

-(NSString*) currentTheme
{
  return [[self->currentTheme copy] autorelease];
}
//end currentTheme

-(void) setCurrentTheme:(NSString*)value
{
  if (![value isEqualToString:self->currentTheme])
  {
    [self->currentTheme release];
    self->currentTheme = [value copy];
    NSInteger tag = !self->currentTheme ? 0 : [self->availableThemes indexOfObject:self->currentTheme];
    if (tag != NSNotFound)
      [self->themesPopUpButton selectItemWithTag:tag];
    [self webViewSetCSS:self->currentTheme];
  }//end if (![value isEqualToString:self->currentTheme])
}
//end setCurrentTheme:

-(IBAction) addUserVariableItem:(id)sender
{
  if (sender == self->userVariableItemsAddButton)
  {
    [self.undoManager beginUndoGrouping];
    CHChalkIdentifierManager* identifierManager = self->chalkContext.identifierManager;
    NSString* unusedIdentifierName = [identifierManager unusedIdentifierNameWithTokenOption:YES];
    CHChalkIdentifier* identifier = !unusedIdentifierName ? nil :
      [[CHChalkIdentifierVariable alloc] initWithName:unusedIdentifierName caseSensitive:YES tokens:@[unusedIdentifierName] symbol:unusedIdentifierName symbolAsText:unusedIdentifierName symbolAsTeX:unusedIdentifierName];
    BOOL added = [identifierManager addIdentifier:identifier replace:NO preventTokenConflict:YES];
    [identifier release];//still retained by identifier manager on  success
    if (!added)
      identifier = nil;
    CHUserVariableItem* userVariableItem = !identifier ? nil :
      [[[CHUserVariableItem alloc] initWithIdentifier:identifier isDynamic:NO input:nil evaluatedValue:nil context:self->chalkContext managedObjectContext:self.managedObjectContext] autorelease];
    [userVariableItem setInput:@"0" parse:YES evaluate:YES];
    NSArray* newItems = !userVariableItem ? nil : @[userVariableItem];
    [self addUserVariableItems:newItems];
    [self.undoManager endUndoGrouping];
  }//end if (sender == self->userVariableItemsAddButton)
}
//end addUserVariableItem:

-(void) addUserVariableItems:(NSArray* _Nullable)items
{
  [self.undoManager beginUndoGrouping];
  [[self.undoManager prepareWithInvocationTarget:self] removeUserVariableItems:items];
  for(id object in items)
  {
    CHUserVariableItem* userVariableItem = [object dynamicCastToClass:[CHUserVariableItem class]];
    if (userVariableItem)
    {
      [self->dependencyManager addItem:userVariableItem];
      [self->userVariableItemsController addObject:userVariableItem];
      __block BOOL hasDirtyUserVariableItem = NO;
      NSMutableArray* dirtyUserVariableItems = [NSMutableArray array];
      [self->dependencyManager.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
        if ([identifierDependent hasIdentifierDependencyByTokens:userVariableItem.identifier.tokens])
        {
          [identifierDependent refreshIdentifierDependencies];
          hasDirtyUserVariableItem |= [obj isKindOfClass:[CHUserVariableItem class]];
          [dirtyUserVariableItems safeAddObject:[obj dynamicCastToClass:[CHUserVariableItem class]]];
        }//end if ([curveItem hasIdentifierDependencyByTokens:identifier.tokens])
      }];//end for each curveItem
      if (hasDirtyUserVariableItem)
      {
        [dirtyUserVariableItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHUserVariableItem* userVariableItem = [obj dynamicCastToClass:[CHUserVariableItem class]];
          if (userVariableItem.isDynamic)
            [userVariableItem performEvaluation];
        }];//end for each dirtyUserVariableItem
      }//end if (hasDirtyUserVariableItem)
    }//end if (userVariableItem)
  }//end for each userVariableItem
  [self.undoManager endUndoGrouping];
  [self->userVariableItemsTableView setNeedsDisplay:YES];
}
//end addUserVariableItems:

-(IBAction) removeUserVariableItem:(id _Nullable)sender
{
  if (sender == self->userVariableItemsRemoveButton)
  {
    NSArray* selectedObjects = [self->userVariableItemsController.arrangedObjects objectsAtIndexes:self->userVariableItemsController.selectionIndexes];
    [self removeUserVariableItems:selectedObjects];
  }//end if (sender == self->userVariableItemsRemoveButton)
}
//end removeUserVariableItem:

-(void) removeUserVariableItems:(NSArray* _Nullable)items
{
  [self.undoManager beginUndoGrouping];
  [[self.undoManager prepareWithInvocationTarget:self] addUserVariableItems:items];
  NSArray* dirtyIdentifiers = [self->dependencyManager identifierDependentObjectsToUpdateFrom:items];
  [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHUserVariableItem* userVariableItem = [obj dynamicCastToClass:[CHUserVariableItem class]];
    if (userVariableItem && !userVariableItem.isProtected)
    {
      [self->dependencyManager removeItem:userVariableItem];
      [self->userVariableItemsController removeObject:userVariableItem];
      [self->chalkContext.identifierManager removeIdentifier:userVariableItem.identifier];
      [userVariableItem removeFromManagedObjectContext];
    }//end if (userVariableItem && !userVariableItem.isProtected)
  }];//end for each selected object
  [dirtyIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
    [identifierDependent refreshIdentifierDependencies];
  }];//end for each dependency
  [self.undoManager endUndoGrouping];
  [self->userVariableItemsTableView setNeedsDisplay:YES];
  [self commitChangesIntoManagedObjectContext:nil];
}
//end removeUserVariableItems:

-(IBAction) addUserFunctionItem:(id _Nullable)sender
{
}
//end addUserFunctionItem:

-(void) addUserFunctionItems:(NSArray* _Nullable)items
{
  [self.undoManager beginUndoGrouping];
  [[self.undoManager prepareWithInvocationTarget:self] removeUserVariableItems:items];
  for(id object in items)
  {
    CHUserFunctionItem* userFunctionItem = [object dynamicCastToClass:[CHUserFunctionItem class]];
    if (userFunctionItem)
      [self->userFunctionItemsController addObject:userFunctionItem];
  }//end for each userFunctionItem
  [self.undoManager endUndoGrouping];
  [self->userFunctionItemsTableView setNeedsDisplay:YES];
}
//end addUserFunctionItems:

-(IBAction) removeUserFunctionItem:(id _Nullable)sender
{
  if (sender == self->userFunctionItemsRemoveButton)
  {
    NSArray* selectedObjects = [self->userFunctionItemsController.arrangedObjects objectsAtIndexes:self->userFunctionItemsController.selectionIndexes];
    [self removeUserFunctionItems:selectedObjects];
  }//end if (sender == self->userFunctionItemsRemoveButton)
}
//end removeUserFunctionItem:

-(void) removeUserFunctionItems:(NSArray* _Nullable)items
{
  [self.undoManager beginUndoGrouping];
  [[self.undoManager prepareWithInvocationTarget:self] addUserFunctionItems:items];
  [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHUserFunctionItem* userFunctionItem = [obj dynamicCastToClass:[CHUserFunctionItem class]];
    if (userFunctionItem && !userFunctionItem.isProtected)
    {
      [self->userFunctionItemsController removeObject:userFunctionItem];
      [self->chalkContext.identifierManager removeIdentifier:userFunctionItem.identifier];
      [userFunctionItem removeFromManagedObjectContext];
    }//end if (userFunctionItem && !userFunctionItem)
  }];//end for each selected object
  [self.undoManager endUndoGrouping];
  [self->userFunctionItemsTableView setNeedsDisplay:YES];
  [self commitChangesIntoManagedObjectContext:nil];
}
//end removeUserFunctionItems:

-(void) controlTextDidChange:(NSNotification*)notification
{
  if (notification.object == self->inputTextField)
  {
    if (!self->inhibateInputTextChange)
    {
      [self->ans0 release];
      self->ans0 = [self->inputTextField.stringValue copy];
    }//end if (!self->inhibateInputTextChange)
  }//end if (notification.object == self->inputTextField)
}
//end controlTextDidChange:

-(CHComputationConfiguration*) currentComputationConfiguration
{
  CHComputationConfiguration* result = self.currentComputationEntry.computationConfiguration.computationConfiguration;
  if (!result)
    result = self.defaultComputationConfiguration;
  return result;
}
//end currentComputationConfiguration

-(CHPresentationConfiguration*) currentPresentationConfiguration
{
  CHPresentationConfiguration* result = self.currentComputationEntry.presentationConfiguration.presentationConfiguration;
  if (!result)
    result = self.defaultPresentationConfiguration;
  return result;
}
//end currentPresentationConfiguration

-(chalk_compute_mode_t) currentComputeMode
{
  chalk_compute_mode_t result = self.currentComputationConfiguration.computeMode;
  NSEventModifierFlags modifierFlags = [NSEvent modifierFlags];
  BOOL isAlt = ((modifierFlags & NSAlternateKeyMask) != 0);
  BOOL isShift = ((modifierFlags & NSShiftKeyMask) != 0);
  switch(result)
  {
    case CHALK_COMPUTE_MODE_UNDEFINED:
      break;
    case CHALK_COMPUTE_MODE_EXACT:
      result =
        isAlt && isShift ? CHALK_COMPUTE_MODE_APPROX_INTERVALS :
        isAlt ? CHALK_COMPUTE_MODE_APPROX_BEST :
        result;
      break;
    case CHALK_COMPUTE_MODE_APPROX_INTERVALS:
      result =
        isAlt && isShift ? CHALK_COMPUTE_MODE_EXACT :
        isAlt ? CHALK_COMPUTE_MODE_APPROX_BEST :
        result;
      break;
    case CHALK_COMPUTE_MODE_APPROX_BEST:
      result =
        isAlt && isShift ? CHALK_COMPUTE_MODE_EXACT :
        isAlt ? CHALK_COMPUTE_MODE_APPROX_INTERVALS :
        result;
      break;
  }//end switch(result)
  return result;
}
//end currentComputeMode

-(IBAction) startComputing:(id _Nullable)sender
{
  if (self.isComputing)
    [self stopComputing:self];
  else//if (!self.isComputing)
  {
    NSString* input = [self->inputTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self computeWithInput:input computeMode:self.currentComputeMode];
  }//end if (!self.isComputing)
}
//end startComputing:

-(IBAction) stopComputing:(id _Nullable)sender
{
  if (self.isComputing)
  {
    self->inputComputeButtonProgressIndicator.hidden = NO;
    self->inputComputeButtonProgressIndicator.animated = YES;
    self->inputComputeButton.enabled = NO;
    @synchronized(self)
    {
      [self->computeChalkContext.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUserCancellation] replace:NO];
    }//end @synchronized(self)
  }//end if (self.isComputing)
}
//end stopComputing:

-(void) computeWithInput:(NSString*)input computeMode:(chalk_compute_mode_t)computeMode
{
  NSInteger newUniqueIdentifier = [self createUniqueIdentifier];
  DebugLog(1, @">computeWithInput(%@)", input);
  CHComputationEntryEntity* computationEntry = !self.managedObjectContext ? nil :
    [[NSEntityDescription insertNewObjectForEntityForName:[CHComputationEntryEntity entityName]
       inManagedObjectContext:self.managedObjectContext]
     dynamicCastToClass:[CHComputationEntryEntity class]];
  DebugLog(1, @"computationEntry = %@", computationEntry);
  if (computationEntry)
  {
    [self->chalkContext reset];
    computationEntry.uniqueIdentifier = newUniqueIdentifier;
    NSDate* now = [NSDate date];
    computationEntry.dateCreation = now;
    computationEntry.dateModification = now;
    computationEntry.computationConfiguration.computationConfiguration = self.defaultComputationConfiguration;
    computationEntry.computationConfiguration.computeMode = computeMode;
    computationEntry.presentationConfiguration.presentationConfiguration = self.defaultPresentationConfiguration;
    computationEntry.inputRawString = [[input copy] autorelease];
    [self computeComputationEntry:computationEntry isNew:YES];
  }//end if (computationEntry)
  DebugLog(1, @"<computeWithInput(%@)", input);
}
//end computeWithInput:computeMode:

-(void) computeComputationEntry:(CHComputationEntryEntity*)computationEntry isNew:(BOOL)isNew
{
  if (self.isComputing)
  {
    DebugLog(1, @"skip computation");
    self->scheduledComputationEntry = computationEntry;
  }//end if (self.isComputing)
  else if (computationEntry)
  {
    DebugLog(1, @"self.isComputing <= YES");
    self.isComputing = YES;
    //[self.undoManager beginUndoGrouping];
    dispatch_async_gmp(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      DebugLog(1, @"dispatch_async_gmp(compute...)");
      NSString* input = computationEntry.inputRawString;
      CHChalkContext* localContext = [[self->chalkContext copy] autorelease];
      [localContext reset];
      CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
      localContext.basePrefixesSuffixes = preferencesController.basePrefixesSuffixes;
      localContext.parseConfiguration.parseMode = preferencesController.parseMode;
      [localContext.errorContext reset:input];
      localContext.computationConfiguration.plist = computationEntry.computationConfiguration.plist;
      localContext.presentationConfiguration.plist = computationEntry.presentationConfiguration.plist;
      DebugLog(1, @"query referenceAge");
      localContext.referenceAge = [self chalkContext:nil ageForComputationEntry:computationEntry];
      DebugLog(1, @"referenceAge = %@", @(localContext.referenceAge));
      [self->computeChalkContext release];
      self->computeChalkContext = [localContext retain];
      [CHGmpPool push:[localContext gmpPool]];

      DebugLog(1, @"parse...");
      CHParser* parser = [[[CHParser alloc] init] autorelease];
      [parser parseTo:parser fromString:input context:localContext];
      CHChalkError* parseError = localContext.errorContext.error;
      NSArray* rootNodes = parser.rootNodes;
      CHParserNode* parserNode = parseError ? nil : [rootNodes.firstObject dynamicCastToClass:[CHParserNode class]];
      mpfr_clear_flags();
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(YES);
      [parserNode performEvaluationWithContext:localContext lazy:NO];
      chalkGmpFlagsRestore(oldFlags);
      DebugLog(1, @"... parse done");
      dispatch_async_gmp(dispatch_get_main_queue(), ^{
        DebugLog(1, @"dispatch_async_gmp(computeComputationEntry...)");
        [self computeComputationEntry:computationEntry isNew:isNew didEndWithParser:parser];
      });
    });
  }//end if (computationEntry)
}
//end computeComputationEntry:isNew:
    
-(void) computeComputationEntry:(CHComputationEntryEntity*)computationEntry isNew:(BOOL)isNew didEndWithParser:(CHParser*)parser
{
  [self.undoManager beginUndoGrouping];
  CHChalkContext* localContext = self->computeChalkContext;
  CHChalkError* parseError = [[localContext.errorContext.error copy] autorelease];
  if (computationEntry)
  {
    self->computeChalkContext = nil;
    NSString* input = computationEntry.inputRawString;
    NSArray* rootNodes = parser.rootNodes;
    CHParserNode* parserNode = parseError ? nil : [rootNodes.firstObject dynamicCastToClass:[CHParserNode class]];
    CHParserAssignationNode* assignationNode = [parserNode dynamicCastToClass:[CHParserAssignationNode class]];
    BOOL assignationDynamic = [assignationNode isKindOfClass:[CHParserAssignationDynamicNode class]];
    NSMutableArray* updatedUserVariableItems = [NSMutableArray array];
    if (assignationNode)
    {
      NSArray* children = assignationNode.children;
      if (children.count == 2)
      {
        CHParserIdentifierNode* leftIdentifier =
          [[children objectAtIndex:0] dynamicCastToClass:[CHParserIdentifierNode class]];
        CHParserFunctionNode* leftFunction =
          [[children objectAtIndex:0] dynamicCastToClass:[CHParserFunctionNode class]];
        BOOL isVariableIdentifier = leftIdentifier && !leftFunction;
        BOOL isFunctionIdentifier = (leftFunction != nil);
        CHParserNode* rightNode =
          [[children objectAtIndex:1] dynamicCastToClass:[CHParserNode class]];
        CHChalkIdentifier* identifier =
          isVariableIdentifier ? [leftIdentifier identifierWithContext:localContext] :
          isFunctionIdentifier ? [leftFunction identifierWithContext:localContext] :
          nil;
        CHChalkIdentifierFunction* identifierFunction = [identifier dynamicCastToClass:[CHChalkIdentifierFunction class]];
        NSRange assignationRange = assignationNode.token.range;
        NSString* rightExpression = !rightNode ? nil :
          (assignationRange.location == NSNotFound) ? nil :
          [input substringFromIndex:assignationRange.location+assignationRange.length];
        if (rightExpression)
        {
          if (isVariableIdentifier)
          {
            CHUserVariableItem* userVariableItem = !rightExpression || !identifier ? nil :
              [(NSObject*)[self->dependencyManager objectForIdentifier:identifier] dynamicCastToClass:[CHUserVariableItem class]];
            [self.undoManager beginUndoGrouping];
            if (userVariableItem)
              [userVariableItem setInput:rightExpression parserNode:rightNode];
            else//if (!userVariableItem)
            {
              userVariableItem = [[[CHUserVariableItem alloc] initWithIdentifier:identifier isDynamic:NO input:nil evaluatedValue:nil context:localContext managedObjectContext:self.managedObjectContext] autorelease];
              if (userVariableItem)
              {
                [userVariableItem setInput:rightExpression parserNode:rightNode];
                [self addUserVariableItems:@[userVariableItem]];
              }//end if (userVariableItem)
            }//end if (!userVariableItem)
            [updatedUserVariableItems safeAddObject:userVariableItem];
            userVariableItem.isDynamic = assignationDynamic;
            [self.undoManager endUndoGrouping];
          }//end if (isVariableIdentifier)
          else if (isFunctionIdentifier)
          {
            __block CHUserFunctionItem* userFunctionItem = nil;
            if (rightExpression && identifierFunction)
            {
              [[self->userFunctionItemsController arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CHUserFunctionItem* existingUserFunctionItem = [obj dynamicCastToClass:[CHUserFunctionItem class]];
                if ([existingUserFunctionItem.identifier isEqualTo:identifierFunction])
                  userFunctionItem = existingUserFunctionItem;
                *stop |= (userFunctionItem != nil);
              }];
            }//end if (rightExpression && identifierFunction)
            [self.undoManager beginUndoGrouping];
            if (userFunctionItem)
            {
              userFunctionItem.argumentNames = identifierFunction.argumentNames;
              userFunctionItem.definition = identifierFunction.definition;
            }//end if (userFunctionItem)
            else//if (!userFunctionItem)
            {
              userFunctionItem = [[[CHUserFunctionItem alloc] initWithIdentifier:identifierFunction context:localContext managedObjectContext:self.managedObjectContext] autorelease];
              if (userFunctionItem)
                [self addUserFunctionItems:@[userFunctionItem]];
            }//end if (!userFunctionItem)
            [self.undoManager endUndoGrouping];
          }//end if (isFunctionIdentifier)
          else
          {
            [localContext.errorContext setError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorParseError range:parserNode.token.range] replace:NO];
            parseError = [[localContext.errorContext.error copy] autorelease];
          }
        }//end if (rightExpression)
      }//end if (children.count == 2)
    }//end if (assignationNode)
    
    NSArray* identifiersToUpdate = [self->dependencyManager identifierDependentObjectsToUpdateFrom:updatedUserVariableItems];
    [identifiersToUpdate enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHUserVariableItem* userVariableItem = [obj dynamicCastToClass:[CHUserVariableItem class]];
      if (userVariableItem.isDynamic)
        [userVariableItem performEvaluation];
    }];//end for each identifiersToUpdate
    [self->dependencyManager updateCircularDependencies];
    [self->dependencyManager updateIdentifiers:identifiersToUpdate];
    [self->userVariableItemsTableView reloadData];
    
    CHChalkValue* chalkValue = parserNode.evaluatedValue;
    [chalkValue adaptToComputeMode:localContext.computationConfiguration.computeMode context:localContext];
    parserNode.evaluationComputeFlags |= chalkValue.evaluationComputeFlags;
    computationEntry.chalkValue1 = chalkValue;

    CHStreamWrapper* stream = [[[CHStreamWrapper alloc] init] autorelease];

    //input raw
    [stream reset];
    NSMutableString* inputRawHTMLString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = inputRawHTMLString;
    if (!parseError)
      [stream writeString:input];
    else//if (parseError)
    {
      NSIndexSet* errorRanges = parseError.ranges;
      [errorRanges enumerateRangesWithin:input.range usingBlock:^(NSRange range, BOOL inside, BOOL *stop) {
        if (inside)
          [stream writeString:@"<span class=\"errorFlag\">"];
        [stream writeString:[input substringWithRange:range]];
        if (inside)
          [stream writeString:@"</span>"];
      }];//end for each range
    }//end if (parseError)
    computationEntry.inputRawHTMLString = [[inputRawHTMLString copy] autorelease];

    CHPresentationConfiguration* presentationConfiguration = [CHPresentationConfiguration presentationConfiguration];
    
    //input
    localContext.outputRawToken = YES;
    //input parsed HTML
    [stream reset];
    NSMutableString* inputInterpretedHTMLString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = inputInterpretedHTMLString;
    if (!parseError)
    {
      presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_HTML;
      [parserNode writeToStream:stream context:localContext presentationConfiguration:presentationConfiguration];
    }//end if (!parseError)
    computationEntry.inputInterpretedHTMLString = [[inputInterpretedHTMLString copy] autorelease];

    //input parsed TEX
    [stream reset];
    NSMutableString* inputInterpretedTeXString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = inputInterpretedTeXString;
    if (!parseError && !localContext.errorContext.hasError)
    {
      presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_TEX;
      [parserNode writeToStream:stream context:localContext presentationConfiguration:presentationConfiguration];
    }//end if (!parseError && !localContext.errorContext.hasError)
    computationEntry.inputInterpretedTeXString = [[inputInterpretedTeXString copy] autorelease];
    
    //output
    presentationConfiguration.plist = computationEntry.presentationConfiguration.plist;
    localContext.outputRawToken = NO;
    
    //output RAW
    [stream reset];
    NSMutableString* outputRawString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = outputRawString;
    if (parseError)
      [stream writeString:[parseError.friendlyDescription encodeHTMLCharacterEntities]];
    else//if (!parseError)
    {
      if (localContext.errorContext.hasError)
        [stream writeString:localContext.errorContext.error.friendlyDescription];
      else//if (!localContext.errorContext.hasError)
      {
        presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_STRING;
        [chalkValue writeToStream:stream context:localContext presentationConfiguration:presentationConfiguration];
      }//end if (!localContext.errorContext.hasError)
    }//end if (!parseError)
    computationEntry.outputRawString = [[outputRawString copy] autorelease];

    //output HTML
    [stream reset];
    NSMutableString* outputHTMLString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = outputHTMLString;
    if (parseError)
      [stream writeString:[parseError.friendlyDescription encodeHTMLCharacterEntities]];
    else//if (!parseError)
    {
      if (localContext.errorContext.hasError)
        [stream writeString:[localContext.errorContext.error.friendlyDescription encodeHTMLCharacterEntities]];
      else//if (!localContext.errorContext.hasError)
      {
        presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_HTML;
        [chalkValue writeToStream:stream context:localContext presentationConfiguration:presentationConfiguration];
      }//end if (!localContext.errorContext.hasError)
    }//end if (!parseError)
    computationEntry.outputHTMLString = [[outputHTMLString copy] autorelease];
    
    //output TeX
    [stream reset];
    NSMutableString* outputTeXString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = outputTeXString;
    if (!parseError && !localContext.errorContext.hasError)
    {
      presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_TEX;
      [chalkValue writeToStream:stream context:localContext presentationConfiguration:presentationConfiguration];
    }//end if (!parseError && !localContext.errorContext.hasError)
    computationEntry.outputTeXString = [[outputTeXString copy] autorelease];
    
    CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
    if ([preferencesController shouldEasterEgg])
    {
      NSString* easterEggMessage = NSLocalizedString(@"You could take a pen and a paper. You are just lazy today.", @"");
      computationEntry.outputHTMLString = easterEggMessage;
      computationEntry.outputRawString = easterEggMessage;
      computationEntry.outputTeXString = [NSString stringWithFormat:@"\\textrm{%@}", easterEggMessage];
    }//end if ([preferencesController shouldEasterEgg])

    CHChalkValueNumberRaw* chalkValueRaw = [chalkValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
    const chalk_raw_value_t* chalkValueRawValue = chalkValueRaw.valueConstReference;
    const chalk_bit_interpretation_t* bitInterpretation = !chalkValueRawValue ? 0 : &chalkValueRawValue->bitInterpretation;
    NSString* outputHtmlCumulativeFlags = (!bitInterpretation && !parserNode.evaluationComputeFlagsCumulated )? @"" :
      chalkGmpComputeFlagsGetHTML(parserNode.evaluationComputeFlagsCumulated, bitInterpretation, YES);
    computationEntry.outputHtmlCumulativeFlags = [[outputHtmlCumulativeFlags copy] autorelease];
    
    computationEntry.dateModification = [NSDate date];
    
    BOOL oldValue = self->inhibateInputTextChange;
    self->inhibateInputTextChange = YES;
    if (isNew)
      [self webViewInsertEntry:computationEntry atAge:@(0)];
    else//if (age)
      [self webViewUpdateEntry:computationEntry];
    self->inhibateInputTextChange = oldValue;
    [CHGmpPool pop];

    [localContext release];
    [self commitChangesIntoManagedObjectContext:^{[self currentComputationEntryDidChange:nil];}];
  }//end if (computationEntry)
  self->inputComputeButtonProgressIndicator.animated = NO;
  self->inputComputeButtonProgressIndicator.hidden = YES;
  self->inputComputeButton.enabled = YES;
  self.isComputing = NO;
  if (parseError)
  {
    [self.windowForSheet makeFirstResponder:self->inputTextField];
    NSText* textEditor = self->inputTextField.currentEditor;
    NSString* string = textEditor.string;
    string = !string ? @"" : string;
    textEditor.string = string;
    NSIndexSet* parseErrorRanges = parseError.ranges;
    __block NSRange firstErrorRange = NSRangeZero;
    [parseErrorRanges enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
      firstErrorRange = range;
      
      *stop = YES;
    }];
    NSRange fullRange = textEditor.string.range;
    textEditor.selectedRange = NSIntersectionRange(firstErrorRange, fullRange);
  }//end if (parseError)
  else if (isNew && computationEntry)
  {
    [self->outputWebView evaluateJavaScriptFunction:@"selectionSetAge" withJSONArguments:@[@1] wait:YES];
    [self prepareInputField:computationEntry];
  }//end if (isNew && computationEntry && !parseError)
  if (self->scheduledComputationEntry)
  {
    [self computeComputationEntry:self->scheduledComputationEntry isNew:NO];
    self->scheduledComputationEntry = nil;
  }//end if (self->scheduledComputationEntry)
  [self.undoManager endUndoGrouping];
}
//end computeComputationEntry:isNew:didEndWithParser:

-(void) prepareInputField:(CHComputationEntryEntity* _Nullable)computationEntry
{
  [self.windowForSheet makeFirstResponder:self->inputTextField];
  NSText* textEditor = self->inputTextField.currentEditor;
  NSString* string = textEditor.string;
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_nextinput_mode_t nextInputMode = preferencesController.nextInputMode;
  if (nextInputMode == CHALK_NEXTINPUT_MODE_BLANK)
  {
    string = !string ? nil : @"";
    if (string)
    {
      textEditor.string = string;
      textEditor.selectedRange = NSMakeRange(0, textEditor.string.length);
    }//end if (string)
  }//end if (nextInputMode == CHALK_NEXTINPUT_MODE_BLANK)
  else if (nextInputMode == CHALK_NEXTINPUT_MODE_PREVIOUS_INPUT)
  {
    string = !string ? nil : computationEntry.inputRawString;
    if (string)
    {
      textEditor.string = string;
      textEditor.selectedRange = NSMakeRange(0, textEditor.string.length);
    }//end if (string)
  }//end if (nextInputMode == CHALK_NEXTINPUT_MODE_PREVIOUS_INPUT)
  else if (nextInputMode == CHALK_NEXTINPUT_MODE_FUNCTION_OUTPUT)
  {
    string = !string ? nil : @"output(1)";
    if (string)
    {
      textEditor.string = string;
      textEditor.selectedRange = NSMakeRange(textEditor.string.length, 0);
    }//end if (string)
  }//end if (nextInputMode == CHALK_NEXTINPUT_MODE_FUNCTION_OUTPUT)
}
//end prepareInputField:

-(IBAction) modifyComputationEntry:(id _Nullable)sender
{
  CHComputationConfiguration* newComputationConfiguration = self.currentComputationConfiguration;
  CHPresentationConfiguration* newPresentationConfiguration = self.currentPresentationConfiguration;

  if ((sender == self->computeOptionSoftFloatDisplayBitsSlider) || (sender == self->computeOptionSoftFloatDisplayBitsTextField) || (sender == self->computeOptionSoftFloatDisplayBitsStepper))
  {
    int base = !newPresentationConfiguration ? 10 : newPresentationConfiguration.base;
    NSUInteger softFloatSignificandBits = newComputationConfiguration.softFloatSignificandBits;
    NSUInteger softFloatDisplayDigits = 0;
    if (sender == self->computeOptionSoftFloatDisplayBitsSlider)
    {
      CGFloat sliderNormalizedValue =
        (self->computeOptionSoftFloatDisplayBitsSlider.doubleValue-self->computeOptionSoftFloatDisplayBitsSlider.minValue)/
        (self->computeOptionSoftFloatDisplayBitsSlider.maxValue-self->computeOptionSoftFloatDisplayBitsSlider.minValue);
      NSUInteger softFloatDisplayBits = MPFR_PREC_MIN+sliderNormalizedValue*(MAX(MPFR_PREC_MIN, softFloatSignificandBits)-MPFR_PREC_MIN);
      softFloatDisplayDigits = MAX(chalkGmpGetMaximumExactDigitsCountFromBitsCount(softFloatDisplayBits, base), chalkGmpGetMinRoundingDigitsCount());
    }//end if (sender == self->computeOptionSoftFloatDisplayBitsSlider)
    else if (sender == self->computeOptionSoftFloatDisplayBitsTextField)
    {
      NSNumberFormatter* formatter =
        [self->computeOptionSoftFloatDisplayBitsTextField.formatter dynamicCastToClass:[NSNumberFormatter class]];
      softFloatDisplayDigits =
        [formatter numberFromString:self->computeOptionSoftFloatDisplayBitsTextField.stringValue].unsignedIntegerValue;
    }//end if (sender == self->computeOptionSoftFloatDisplayBitsTextField)
    else if (sender == self->computeOptionSoftFloatDisplayBitsStepper)
    {
      softFloatDisplayDigits = [[self->computeOptionSoftFloatDisplayBitsStepper.objectValue dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
    }//end if (sender == self->computeOptionSoftFloatDisplayBitsStepper)
    mpfr_prec_t softFloatDisplayBits = chalkGmpGetRequiredBitsCountForDigitsCount(softFloatDisplayDigits, base);
    softFloatDisplayBits = MIN(MAX(MPFR_PREC_MIN, softFloatDisplayBits), softFloatSignificandBits);
    NSUInteger nbDigits = chalkGmpGetMaximumExactDigitsCountFromBitsCount(softFloatDisplayBits, base);
    if (nbDigits < softFloatDisplayDigits)
    {
      mpfr_prec_t offset = 1;
      BOOL stop = (softFloatDisplayBits+offset <= MPFR_PREC_MIN) || (softFloatDisplayBits+offset >= softFloatSignificandBits);
      while(!stop)
      {
        softFloatDisplayBits =
          chalkGmpGetRequiredBitsCountForDigitsCount(softFloatDisplayDigits+(offset++), base);
        softFloatDisplayBits =
          MIN(MAX(MPFR_PREC_MIN, softFloatDisplayBits), softFloatSignificandBits);
        stop |= (softFloatDisplayBits+offset <= MPFR_PREC_MIN) || (softFloatDisplayBits+offset >= softFloatSignificandBits);
        nbDigits = chalkGmpGetMaximumExactDigitsCountFromBitsCount(softFloatDisplayBits, base);
        stop |= (nbDigits >= softFloatDisplayDigits);
      }//end while(!stop)
    }//end if (nbDigits < softFloatDisplayDigits)
    else if (nbDigits > softFloatDisplayDigits)
    {
      mpfr_prec_t offset = 1;
      BOOL stop = (softFloatDisplayBits-offset <= MPFR_PREC_MIN) || (softFloatDisplayBits-offset >= softFloatSignificandBits);
      while(!stop)
      {
        softFloatDisplayBits =
          chalkGmpGetRequiredBitsCountForDigitsCount(softFloatDisplayDigits-(offset++), base);
        softFloatDisplayBits =
          MIN(MAX(MPFR_PREC_MIN, softFloatDisplayBits), softFloatSignificandBits);
        stop |= (softFloatDisplayBits-offset <= MPFR_PREC_MIN) || (softFloatDisplayBits-offset >= softFloatSignificandBits);
        nbDigits = chalkGmpGetMaximumExactDigitsCountFromBitsCount(softFloatDisplayBits, base);
        stop |= (nbDigits <= softFloatDisplayDigits);
      }//end while(!stop)
    }//end if (nbDigits > softFloatDisplayDigits)
    newPresentationConfiguration.softFloatDisplayBits = softFloatDisplayBits;
  }//end if ((sender == self->computeOptionSoftFloatDisplayBitsTextField) || (sender == self->computeOptionSoftFloatDisplayBitsStepper))
  else if (sender == self->computeOptionComputeModeSegmentedControl)
  {
    chalk_compute_mode_t computeMode = (chalk_compute_mode_t)self->computeOptionComputeModeSegmentedControl.selectedSegmentTag;
    if (!self.currentComputationEntry)
      self->defaultComputationConfiguration.computeMode = computeMode;
    else//if (self->computationEntrySelected)
      newComputationConfiguration.computeMode = computeMode;
    [self updateDocumentControls:sender];
  }//end if (sender == self->computeOptionComputeModeSegmentedControl)
  else if ((sender == self->computeOptionOutputBaseTextField) || (sender == self->computeOptionOutputBaseStepper))
  {
    NSUInteger softFloatSignificandBits = newComputationConfiguration.softFloatSignificandBits;
    int newValue =
      (sender == self->computeOptionOutputBaseTextField) ?
        (int)self->computeOptionOutputBaseTextField.integerValue :
      (sender == self->computeOptionOutputBaseStepper) ?
        (int)self->computeOptionOutputBaseStepper.integerValue :
      10;
    newPresentationConfiguration.base = newValue;
    NSNumberFormatter* formatter =
      [self->computeOptionSoftFloatDisplayBitsTextField.formatter dynamicCastToClass:[NSNumberFormatter class]];
    NSUInteger softFloatDisplayDigits =
      [formatter numberFromString:self->computeOptionSoftFloatDisplayBitsTextField.stringValue].unsignedIntegerValue;
    mpfr_prec_t softFloatDisplayBits =
      chalkGmpGetRequiredBitsCountForDigitsCount(softFloatDisplayDigits, newPresentationConfiguration.base);
    softFloatDisplayBits =
      MIN(MAX(MPFR_PREC_MIN, softFloatDisplayBits), softFloatSignificandBits);
    newPresentationConfiguration.softFloatDisplayBits = softFloatDisplayBits;
  }//end if ((sender == self->computeOptionOutputBaseTextField) || (sender == self->computeOptionOutputBaseStepper))
  else if ((sender == self->computeOptionIntegerGroupSizeTextField) || (sender == self->computeOptionIntegerGroupSizeStepper))
  {
    NSInteger newValue =
      (sender == self->computeOptionIntegerGroupSizeTextField) ?
        self->computeOptionIntegerGroupSizeTextField.integerValue :
      (sender == self->computeOptionIntegerGroupSizeStepper) ?
        self->computeOptionIntegerGroupSizeStepper.integerValue :
      0;
    newPresentationConfiguration.integerGroupSize = newValue;
  }//end if ((sender == self->computeOptionIntegerGroupSizeTextField) || (sender == self->computeOptionIntegerGroupSizeStepper))
  
  if (self.currentComputationEntry)
    [self refreshComputationEntry:self.currentComputationEntry computationConfiguration:newComputationConfiguration presentationConfiguration:newPresentationConfiguration];
  else//if (!self.currentComputationEntry)
  {
    self.defaultComputationConfiguration = newComputationConfiguration;
    self.defaultPresentationConfiguration = newPresentationConfiguration;
    ++self->isUpdatingPreferences;
    CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
    preferencesController.computationConfigurationCurrent = self.defaultComputationConfiguration;
    preferencesController.presentationConfigurationCurrent = self.defaultPresentationConfiguration;
    --self->isUpdatingPreferences;
    [self updateDocumentControlsForComputationConfiguration:self.defaultComputationConfiguration presentationConfiguration:self.defaultPresentationConfiguration chalkValue:nil];
  }//end if (!self.currentComputationEntry)
}
//end modifyComputationEntry:

-(void) refreshComputationEntry:(CHComputationEntryEntity*)computationEntry computationConfiguration:(CHComputationConfiguration*)computationConfiguration presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self.undoManager beginUndoGrouping];

  CHComputationConfigurationEntity* currentComputationConfigurationEntity = computationEntry.computationConfiguration;
  CHComputationConfiguration* currentComputationConfiguration =
    [CHComputationConfiguration computationConfigurationWithPlist:currentComputationConfigurationEntity.plist];
  CHPresentationConfigurationEntity* currentPresentationConfigurationEntity = computationEntry.presentationConfiguration;
  CHPresentationConfiguration* currentPresentationConfiguration = [CHPresentationConfiguration presentationConfigurationWithPlist:currentPresentationConfigurationEntity.plist];

  BOOL computationConfigurationWillChange = ![computationConfiguration isEqualTo:currentComputationConfiguration];
  BOOL presentationConfigurationWillChange = ![presentationConfiguration isEqualTo:currentPresentationConfiguration];
  
  if (computationConfigurationWillChange)
  {
    [[self.undoManager prepareWithInvocationTarget:self] refreshComputationEntry:computationEntry computationConfiguration:nil presentationConfiguration:currentPresentationConfiguration];
    currentComputationConfigurationEntity.computationConfiguration = computationConfiguration;
    [self computeComputationEntry:computationEntry isNew:NO];
  }//end if (computationConfigurationWillChange)
  else if (presentationConfigurationWillChange)
  {
    [[self.undoManager prepareWithInvocationTarget:self] refreshComputationEntry:computationEntry computationConfiguration:computationConfiguration presentationConfiguration:nil];
    if (self.undoManager.isUndoing)
      [self webViewUpdateEntry2:computationEntry];
    currentPresentationConfigurationEntity.presentationConfiguration = presentationConfiguration;

    self->chalkContext.computationConfiguration.plist = computationEntry.computationConfiguration.plist;
    self->chalkContext.presentationConfiguration.plist = computationEntry.presentationConfiguration.plist;
    [self->chalkContext invalidateCaches];
    CHChalkError* parseError = nil;
    CHChalkValue* chalkValue = computationEntry.chalkValue1;

    CHStreamWrapper* stream = [[[CHStreamWrapper alloc] init] autorelease];
    //output
    self->chalkContext.outputRawToken = NO;
    
    //output RAW
    [stream reset];
    NSMutableString* outputRawString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = outputRawString;
    if (parseError)
      [stream writeString:[parseError.friendlyDescription encodeHTMLCharacterEntities]];
    else//if (!parseError)
    {
      if (self->chalkContext.errorContext.hasError)
        [stream writeString:self->chalkContext.errorContext.error.friendlyDescription];
      else//if (!localContext.errorContext.hasError)
      {
        presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_STRING;
        [chalkValue writeToStream:stream context:self->chalkContext presentationConfiguration:presentationConfiguration];
      }//end if (!localContext.errorContext.hasError)
    }//end if (!parseError)
    computationEntry.outputRawString = [[outputRawString copy] autorelease];

    //output HTML
    [stream reset];
    NSMutableString* outputHTMLString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = outputHTMLString;
    if (parseError)
      [stream writeString:[parseError.friendlyDescription encodeHTMLCharacterEntities]];
    else//if (!parseError)
    {
      if (self->chalkContext.errorContext.hasError)
        [stream writeString:[self->chalkContext.errorContext.error.friendlyDescription encodeHTMLCharacterEntities]];
      else//if (!self->chalkContext.errorContext.hasError)
      {
        presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_HTML;
        [chalkValue writeToStream:stream context:self->chalkContext presentationConfiguration:presentationConfiguration];
      }//end if (!self->chalkContext.errorContext.hasError)
    }//end if (!parseError)
    computationEntry.outputHTMLString = [[outputHTMLString copy] autorelease];
    
    //output TeX
    [stream reset];
    NSMutableString* outputTeXString = [[[NSMutableString alloc] init] autorelease];
    stream.stringStream = outputTeXString;
    if (!parseError && !self->chalkContext.errorContext.hasError)
    {
      presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_TEX;
      [chalkValue writeToStream:stream context:self->chalkContext presentationConfiguration:presentationConfiguration];
    }//end if (!parseError && !self->chalkContext.errorContext.hasError)
    computationEntry.outputTeXString = [[outputTeXString copy] autorelease];

   chalk_compute_flags_t evaluationComputeFlagsCumulated = chalkValue.evaluationComputeFlags;
   CHChalkValueNumberRaw* chalkValueRaw = [chalkValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
   const chalk_raw_value_t* chalkValueRawValue = chalkValueRaw.valueConstReference;
   const chalk_bit_interpretation_t* bitInterpretation = !chalkValueRawValue ? 0 : &chalkValueRawValue->bitInterpretation;
    NSString* outputHtmlCumulativeFlags = (!bitInterpretation && !evaluationComputeFlagsCumulated) ? @"" :
      chalkGmpComputeFlagsGetHTML(evaluationComputeFlagsCumulated, bitInterpretation, YES);
    computationEntry.outputHtmlCumulativeFlags = [[outputHtmlCumulativeFlags copy] autorelease];
    
    BOOL oldValue = self->inhibateInputTextChange;
    self->inhibateInputTextChange = YES;
    if (!self.undoManager.isUndoing)
      [self webViewUpdateEntry2:computationEntry];
    self->inhibateInputTextChange = oldValue;
  }//end if (presentationConfigurationWillChange)
  [self.undoManager endUndoGrouping];
}
//end refreshComputationEntry:computationConfiguration:presentationConfiguration

-(void) updateDocumentControlsForComputationConfiguration:(CHComputationConfiguration*)computationConfiguration
                                presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
                                               chalkValue:(CHChalkValue*)chalkValue
{
  NSUInteger softFloatDisplayBits = presentationConfiguration.softFloatDisplayBits;
  NSUInteger softFloatSignificandBits = computationConfiguration.softFloatSignificandBits;
  CHChalkValueNumberGmp* valueGmp = [chalkValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  CHChalkValueNumberRaw* valueRaw = [chalkValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
  const chalk_gmp_value_t* gmpValue = valueGmp.valueConstReference;
  const chalk_raw_value_t* rawValue = valueRaw.valueConstReference;
  BOOL hasComputationConfiguration = (computationConfiguration != nil);
  BOOL hasPresentationConfiguration = (presentationConfiguration != nil);
  BOOL isInteger =
    (gmpValue && ((gmpValue->type == CHALK_VALUE_TYPE_INTEGER) || (gmpValue->type == CHALK_VALUE_TYPE_FRACTION))) ||
    (rawValue && getEncodingIsInteger(rawValue->bitInterpretation.numberEncoding));
  BOOL allowSelectNumberOfDigits = !isInteger || (computationConfiguration.computeMode != CHALK_COMPUTE_MODE_EXACT);
  NSNumberFormatter* formatter =
    [self->computeOptionSoftFloatDisplayBitsTextField.formatter dynamicCastToClass:[NSNumberFormatter class]];
  self->computeOptionSoftFloatDisplayBitsSlider.enabled = hasPresentationConfiguration && allowSelectNumberOfDigits;
  self->computeOptionSoftFloatDisplayBitsSlider.minValue = 1.*MPFR_PREC_MIN;
  self->computeOptionSoftFloatDisplayBitsSlider.maxValue = 1.*softFloatSignificandBits;
  self->computeOptionSoftFloatDisplayBitsSlider.doubleValue =
    (softFloatDisplayBits == MPFR_PREC_MIN) ? self->computeOptionSoftFloatDisplayBitsSlider.minValue :
    (softFloatDisplayBits == softFloatSignificandBits) ? self->computeOptionSoftFloatDisplayBitsSlider.maxValue :
    self->computeOptionSoftFloatDisplayBitsSlider.minValue+
    ((1.*(softFloatDisplayBits-MPFR_PREC_MIN))/(1.*(softFloatSignificandBits-MPFR_PREC_MIN)))*
    (self->computeOptionSoftFloatDisplayBitsSlider.maxValue-self->computeOptionSoftFloatDisplayBitsSlider.minValue);
  formatter.minimum = [NSNumber numberWithUnsignedInteger:MPFR_PREC_MIN];
  formatter.maximum = [NSNumber numberWithUnsignedInteger:softFloatSignificandBits];
  NSUInteger nbDigits = chalkGmpGetMaximumExactDigitsCountFromBitsCount(softFloatDisplayBits, !presentationConfiguration ? 10 : presentationConfiguration.base);
  self->computeOptionSoftFloatDisplayBitsStepper.enabled = hasPresentationConfiguration && allowSelectNumberOfDigits;
  self->computeOptionSoftFloatDisplayBitsStepper.objectValue = @(nbDigits);
  self->computeOptionSoftFloatDisplayBitsTextField.enabled = hasPresentationConfiguration && allowSelectNumberOfDigits;
  NSString* softFloatDisplayBitsString = !allowSelectNumberOfDigits ? @"-" :
    [formatter stringFromNumber:[formatter clip:[NSNumber numberWithUnsignedInteger:nbDigits]]];
  self->computeOptionSoftFloatDisplayBitsTextField.stringValue = softFloatDisplayBitsString;
  self->computeOptionComputeModeSegmentedControl.enabled = hasComputationConfiguration;
  [self->computeOptionComputeModeSegmentedControl selectSegmentWithTag:(NSInteger)self.currentComputeMode];
  self->computeOptionOutputBaseTextField.enabled = hasComputationConfiguration;
  [self->computeOptionOutputBaseTextField setStringValue:@(presentationConfiguration.base).stringValue];
  self->computeOptionOutputBaseStepper.enabled = hasComputationConfiguration;
  [self->computeOptionOutputBaseStepper setIntegerValue:@(presentationConfiguration.base).integerValue];
  self->computeOptionIntegerGroupSizeTextField.enabled = hasPresentationConfiguration;
  [self->computeOptionIntegerGroupSizeTextField setStringValue:@(presentationConfiguration.integerGroupSize).stringValue];
  self->computeOptionIntegerGroupSizeStepper.enabled = hasPresentationConfiguration;
  [self->computeOptionIntegerGroupSizeStepper setIntegerValue:@(presentationConfiguration.integerGroupSize).integerValue];
  
  CHComputationEntryEntity* computationEntry = self.currentComputationEntry;
  NSString* inputTexString = computationEntry.inputInterpretedTeXString;
  NSString* outputTexString = computationEntry.outputTeXString;
  self->inputPopUpButton.enabled = (inputTexString.length > 0);
  self->outputPopUpButton.enabled = (outputTexString.length > 0);
  self->inputColorColorWell.enabled = (inputTexString.length > 0);
  self->outputColorColorWell.enabled = (outputTexString.length > 0);

  [self updateDocumentControls:self];
}
//end updateComputationEntryControls:

-(IBAction) updateDocumentControls:(id _Nullable)sender
{
  chalk_compute_mode_t computeMode = self.currentComputeMode;
  if (self.isComputing)
  {
    self->inputComputeButton.imagePosition = NSImageOnly;
    self->inputComputeButton.image = [NSImage imageNamed:@"stop"];
  }//if (self.isComputing)
  else//if (!self.isComputing)
  {
    self->inputComputeButton.imagePosition = NSNoImage;
    self->inputComputeButton.title =
      [self->computeOptionComputeModeSegmentedControl labelForSegment:
       [self->computeOptionComputeModeSegmentedControl segmentForTag:(NSInteger)computeMode]];
  }//end if (!self.isComputing)
  self->userVariableItemsTableView.enabled = !self.isComputing;
  self->userVariableItemsAddButton.enabled = !self.isComputing;
  self->userFunctionItemsTableView.enabled = !self.isComputing;
  [self tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:nil]];
}
//end updateDocumentControls:

-(IBAction) removeCurrentEntry:(id _Nullable)sender
{
  CHComputationEntryEntity* computationEntryToRemove = self.currentComputationEntry;
  NSUInteger age = [self->chalkContext ageForComputationEntry:computationEntryToRemove];
  CHComputationEntryEntity* nextComputationEntry = [self->chalkContext computationEntryForAge:age+1];
  [self webViewRemoveEntry:computationEntryToRemove];
  self.currentComputationEntry = nextComputationEntry;
}
//end removeCurrentEntry:

-(IBAction) removeAllEntries:(id _Nullable)sender
{
  NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Do you really want to remove all entries ?", @"")
      defaultButton:NSLocalizedString(@"Remove", @"")
    alternateButton:NSLocalizedString(@"Do not remove", @"")
        otherButton:NSLocalizedString(@"Cancel", @"")
    informativeTextWithFormat:NSLocalizedString(@"This cannot be undone", @"")];
  [alert beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK)
    {
      NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
      fetchRequest.returnsObjectsAsFaults = YES;
      fetchRequest.includesPendingChanges = YES;
      NSError* error = nil;
      NSArray* objects = nil;
      @synchronized(self.managedObjectContext)
      {
        objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          NSManagedObject* managedObject = [obj dynamicCastToClass:[NSManagedObject class]];
          if (managedObject)
            [self.managedObjectContext deleteObject:managedObject];
        }];//end for each managedObject
      }//end @synchronized(self.managedObjectContext)
      [self->outputWebView evaluateJavaScriptFunction:@"removeAllEntries" withJSONArguments:nil wait:YES];
      [self.undoManager removeAllActions];
    }//end if (returnCode == NSModalResponseOK)
  }];//end beginSheetModalForWindow:completionHandler:
}
//end removeAllEntries:

-(IBAction) doubleAction:(id _Nullable)sender
{
  if (sender == self->userVariableItemsTableView)
  {
    if (!self.isComputing)
    {
      NSInteger clickedRow = self->userVariableItemsTableView.clickedRow;
      NSInteger clickedColumn = self->userVariableItemsTableView.clickedColumn;
      if ((clickedRow >= 0) && (clickedColumn >= 0))
      {
        CHUserVariableItem* userVariableItem = [self->userVariableItemsController.arrangedObjects objectAtIndex:clickedRow];
        self->inputTextField.stringValue = userVariableItem.inputWithAssignation;
        [self.windowForSheet makeFirstResponder:self->inputTextField];
      }//end if ((clickedRow >= 0) && (clickedColumn >= 0))
    }//end if (!self.isComputing)
  }//end if (sender == self->userVariableItemsTableView)
  else if (sender == self->userFunctionItemsTableView)
  {
    if (!self.isComputing)
    {
      NSInteger clickedRow = self->userFunctionItemsTableView.clickedRow;
      NSInteger clickedColumn = self->userFunctionItemsTableView.clickedColumn;
      if ((clickedRow >= 0) && (clickedColumn >= 0))
      {
        CHUserFunctionItem* userVariableItem = [self->userFunctionItemsController.arrangedObjects objectAtIndex:clickedRow];
        self->inputTextField.stringValue = userVariableItem.inputWithAssignation;
        [self.windowForSheet makeFirstResponder:self->inputTextField];
      }//end if ((clickedRow >= 0) && (clickedColumn >= 0))
    }//end if (!self.isComputing)
  }//end if (sender == self->userFunctionItemsTableView)
}
//end doubleAction:

-(IBAction) saveGUIState:(id _Nullable)sender saveDocument:(BOOL)saveDocument
{
  [self.undoManager disableUndoRegistration];
  NSString* version = [[NSBundle mainBundle].infoDictionary objectForKey:(NSString*)kCFBundleVersionKey];
  NSDictionary* information = [NSDictionary dictionaryWithObjectsAndKeys:
    !version ? @"" : version, @"version",
    NSStringFromRect(self.windowForSheet.frame), @"windowFrame",
    @(self->inspectorLeftView.visible), @"inspectorLeftVisible",
    @(self->inspectorRightView.visible), @"inspectorRightVisible",
    @(self->inspectorBottomView.visible), @"inspectorBottomVisible",
    self.currentTheme, @"currentTheme",
    nil
  ];
  NSError* error = nil;
  NSData* data = [NSPropertyListSerialization dataWithPropertyList:information format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
  [CHDocumentDataEntity setData:data inManagedObjectContext:self.managedObjectContext];
  if (saveDocument)
    [self commitChangesIntoManagedObjectContext:nil];
  else if (self.managedObjectContext.persistentStoreCoordinator.persistentStores.firstObject != nil)
  {
    NSError* error = nil;
    DebugLog(1, @"save");
    @synchronized(self.managedObjectContext)
    {
      [self.managedObjectContext save:&error];
    }//end @synchronized(self.managedObjectContext)
    if (error)
      DebugLog(0, @"save : <%@>", error);
  }//end if (self.managedObjectContext.persistentStoreCoordinator.persistentStores.firstObject != nil)
  [self.undoManager enableUndoRegistration];
}
//end saveGUIState:saveDocument:

-(void) setIsComputing:(BOOL)value
{
  BOOL didChange = NO;
  if (value != self->isComputing)
  {
    @synchronized(self)
    {
      if (value != self->isComputing)
      {
        [self willChangeValueForKey:@"isComputing"];
        self->isComputing = value;
        didChange = YES;
        [self didChangeValueForKey:@"isComputing"];
      }//end if (value != self->isComputing)
    }//end @synchronized(self)
  }//end if (value != self->isComputing)
  if (didChange)
    [self updateDocumentControls:self];
}
//end setIsComputing:

-(void) setCurrentComputationEntry:(CHComputationEntryEntity*)value
{
  if (value != self->currentComputationEntry)
  {
    [self->currentComputationEntry release];
    self->currentComputationEntry = [value retain];
    [self currentComputationEntryDidChange:nil];
  }//end if (value != self->currentComputationEntry)
}
//end setCurrentComputationEntry:

-(void) currentComputationEntryDidChange:(NSNotification*)notification
{
  CHChalkValue* chalkValue = self->currentComputationEntry.chalkValue1;
  CHChalkValueEnumeration* listValue = [chalkValue dynamicCastToClass:[CHChalkValueEnumeration class]];
  CHChalkValueMatrix* matrixValue = [chalkValue dynamicCastToClass:[CHChalkValueMatrix class]];
  if (listValue && (listValue.count == 1))
    chalkValue = [[listValue.values objectAtIndex:0] dynamicCastToClass:[CHChalkValue class]];
  else if (matrixValue && ((matrixValue.rowsCount == 1) && (matrixValue.colsCount == 1)))
    chalkValue = [[matrixValue valueAtRow:0 col:0] dynamicCastToClass:[CHChalkValue class]];
  CHChalkValueNumberGmp* gmpValue = [chalkValue dynamicCastToClass:[CHChalkValueNumberGmp class]];
  CHChalkValueNumberRaw* rawValue = [chalkValue dynamicCastToClass:[CHChalkValueNumberRaw class]];
  self->digitsInspectorControl.chalkContext = self->chalkContext;
  CHComputationConfiguration* computationConfiguration = self->currentComputationEntry.computationConfiguration.computationConfiguration;
  if (!self->inspectorBottomView.visible){
  }
  else if (gmpValue.valueConstReference)
    [self->digitsInspectorControl setGmpValue:gmpValue.valueConstReference computationConfiguration:computationConfiguration];
  else if (rawValue.valueConstReference)
    [self->digitsInspectorControl setRawValue:rawValue.valueConstReference computationConfiguration:computationConfiguration];
  else
    [self->digitsInspectorControl setGmpValue:0 computationConfiguration:computationConfiguration];
}
//end currentComputationEntryDidChange:

-(void) digitsInspector:(CHDigitsInspectorControl*)digitsInspector didUpdateRawValue:(const chalk_raw_value_t*)outputRawValue gmpValue:(const chalk_gmp_value_t*)outputGmpValue
{
  BOOL digitsInspectorVisible = !self->inspectorBottomView.hidden;
  if (digitsInspectorVisible)
  {
    CHComputationEntryEntity* computationEntry = self.currentComputationEntry;
    if (computationEntry)
    {
      chalk_gmp_value_t chalkGmpValue = {0};
      chalkGmpValueSet(&chalkGmpValue, outputGmpValue, self->chalkContext.gmpPool);
      CHChalkValueNumberGmp* chalkValue2 = [[[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:&chalkGmpValue naturalBase:self->chalkContext.computationConfiguration.baseDefault context:self->chalkContext] autorelease];
      computationEntry.chalkValue2 = chalkValue2;
      chalkGmpValueClear(&chalkGmpValue, YES, self->chalkContext.gmpPool);

      CHPresentationConfiguration* presentationConfiguration = computationEntry.presentationConfiguration.presentationConfiguration;

      CHStreamWrapper* streamWrapper = [[CHStreamWrapper alloc] init];
      
      CHChalkError* error = nil;
      if (!error)
        error = digitsInspector.inputConversionError;
      if (!error)
        error = digitsInspector.outputConversionError;
      
      if (error)
      {
        [streamWrapper reset];
        NSMutableString* mutableString = [[NSMutableString alloc] init];
        streamWrapper.stringStream = mutableString;
        [streamWrapper writeString:[error.friendlyDescription encodeHTMLCharacterEntities]];
        computationEntry.output2RawString = mutableString;
        computationEntry.output2HTMLString = mutableString;
        computationEntry.output2TeXString = @"";
        [mutableString release];
      }//end if (error)
      else//if (!error)
      {
        {
          [streamWrapper reset];
          NSMutableString* mutableString = [[NSMutableString alloc] init];
          streamWrapper.stringStream = mutableString;
          presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_TEX;
          [CHChalkValueNumberGmp writeToStream:streamWrapper context:self->chalkContext value:outputGmpValue token:[CHChalkToken chalkTokenEmpty] presentationConfiguration:presentationConfiguration];
          computationEntry.output2TeXString = mutableString;
          [mutableString release];
        }
        {
          [streamWrapper reset];
          NSMutableString* mutableString = [[NSMutableString alloc] init];
          streamWrapper.stringStream = mutableString;
          presentationConfiguration.description = CHALK_VALUE_DESCRIPTION_HTML;
          [CHChalkValueNumberGmp writeToStream:streamWrapper context:self->chalkContext value:outputGmpValue token:[CHChalkToken chalkTokenEmpty] presentationConfiguration:presentationConfiguration];
          computationEntry.output2HTMLString = mutableString;
          [mutableString release];
        }
      }//end if (!error)
      
      {
        const chalk_bit_interpretation_t* bitInterpretation = !outputRawValue ? 0 : &outputRawValue->bitInterpretation;
        chalk_compute_flags_t flags =
          digitsInspector.inputConversionResult.computeFlags |
          digitsInspector.outputConversionResult.computeFlags;
        computationEntry.output2HtmlCumulativeFlags = chalkGmpComputeFlagsGetHTML(flags, bitInterpretation, YES);
      }

      [streamWrapper release];

      BOOL oldValue = self->inhibateInputTextChange;
      self->inhibateInputTextChange = YES;
      NSArray* args = @[
        @(computationEntry.uniqueIdentifier),
        [NSNull null], [NSNull null], [NSNull null],
        [NSObject nullAdapter:computationEntry.outputHTMLString],
        [NSObject nullAdapter:computationEntry.outputTeXString],
        [NSObject nullAdapter:computationEntry.outputHtmlCumulativeFlags],
        [NSObject nullAdapter:computationEntry.output2HTMLString],
        [NSObject nullAdapter:computationEntry.output2TeXString],
        [NSObject nullAdapter:computationEntry.output2HtmlCumulativeFlags]];
      [self->outputWebView evaluateJavaScriptFunction:@"updateEntry" withJSONArguments:args wait:YES];
      self->inhibateInputTextChange = oldValue;
    }//end if (computationEntry)
  }//end if (digitsInspectorVisible)
}
//end digitsInspector:didUpdateRawValue:GmpValue:

-(void) managedObjectContextDidChangeNotification:(NSNotification*)notification
{
  __block BOOL hasUserVariable = NO;
  __block BOOL hasUserFunction = NO;
  void (^b)(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) = ^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
    NSManagedObject* managedObject = [obj dynamicCastToClass:[NSManagedObject class]];
    hasUserVariable |= ([managedObject class] == [CHUserVariableEntity class]);
    hasUserFunction |= ([managedObject class] == [CHUserFunctionEntity class]);
  };
  [[notification.userInfo objectForKey:NSInsertedObjectsKey] enumerateObjectsUsingBlock:b];
  [[notification.userInfo objectForKey:NSUpdatedObjectsKey] enumerateObjectsUsingBlock:b];
  [[notification.userInfo objectForKey:NSDeletedObjectsKey] enumerateObjectsUsingBlock:b];
  if (hasUserVariable)
    [self->userVariableItemsTableView reloadData];
  if (hasUserFunction)
    [self->userFunctionItemsTableView reloadData];
}
//end managedObjectContextDidChangeNotification:

-(void) logComputationEntries
{
  if (DebugLogLevel >= 2)
  {
    dispatch_with_main_option(DISPATCH_MAIN, ^(){
      NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
      fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"uniqueIdentifier" ascending:NO]];
      fetchRequest.includesPendingChanges = YES;
      NSArray* fetchResult = nil;
      NSError* error = nil;
      @synchronized(self.managedObjectContext)
      {
        fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
      }//end @synchronized(self.managedObjectContext)
      printf("logComputationEntries : ");
      printf("[");
      for(CHComputationEntryEntity* entry in fetchResult)
        printf("(%p%s)uid=%lu,", entry, entry.isFault ? "(fault)" : "", entry.uniqueIdentifier);
      printf("]\n");
    });
  }//end if (DebugLogLevel >= 2)
}
//end logComputationEntries

#pragma mark CHChalkContextHistoryDelegate

-(NSUInteger) chalkContext:(CHChalkContext*)chalkContext ageForComputationEntry:(CHComputationEntryEntity*)computationEntry
{
  __block NSUInteger result = 0;
  dispatch_with_main_option(DISPATCH_MAIN, ^(){
    NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"uniqueIdentifier" ascending:NO]];
    fetchRequest.propertiesToFetch = @[@"uniqueIdentifier"];
    fetchRequest.includesPendingChanges = YES;
    NSError* error = nil;
    DebugLog(1, @"ageForComputationEntry:%p", computationEntry);
    DebugLog(1, @"fetch...");
    NSArray* fetchResult = nil;
    @synchronized(self.managedObjectContext)
    {
      fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }//end @synchronized(self.managedObjectContext)
    DebugLog(1, @"...fetchResult = %@", fetchResult);
    NSUInteger index = [fetchResult indexOfObject:computationEntry];
    result = (index == NSNotFound) ? 0 : index+1;
  });
  return result;
}
//end chalkContext:ageForComputationEntry:

-(CHComputationEntryEntity*) chalkContext:(CHChalkContext*)aChalkContext computationEntryForAge:(NSUInteger)age
{
  __block CHComputationEntryEntity* result = nil;
  DebugLog(1, @">chalkContext:computationEntryForAge:%@", @(age));
  if (age)
  {
    dispatch_with_main_option(DISPATCH_MAIN, ^(){
      NSUInteger referenceAge = aChalkContext.referenceAge;
      NSUInteger absoluteAge = referenceAge+age;
      NSUInteger ageAsOffset = !absoluteAge ? 0 : (absoluteAge-1);
      DebugLog(1, @"referenceAge %@, absoluteAge %@, ageAsOffset %@", @(referenceAge), @(absoluteAge), @(ageAsOffset));
      NSError* error = nil;
      NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
      fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"uniqueIdentifier" ascending:NO]];
      fetchRequest.includesPendingChanges = YES;
      NSArray* fetchResult = nil;
      @synchronized(self.managedObjectContext)
      {
        BOOL hasChanges = self.managedObjectContext.hasChanges;
        if (hasChanges)//BUG in fetchOffset when there are changes
        {
          DebugLog(1, @"hasChanges");
          [self logComputationEntries];
          fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
          DebugLog(1, @"there are %@ results", @(fetchResult.count));
          result = (ageAsOffset >= fetchResult.count) ? fetchResult.lastObject :
            [[fetchResult objectAtIndex:ageAsOffset] dynamicCastToClass:[CHComputationEntryEntity class]];
          DebugLog(1, @"result = %p", result);
        }//end if (self.managedObjectContext.hasChanges)
        else//if (!self.managedObjectContext.hasChanges)
        {
          DebugLog(1, @"!hasChanges, using fetch offset");
          [self logComputationEntries];
          fetchRequest.fetchOffset = ageAsOffset;
          fetchRequest.fetchLimit = 1;
          fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
          DebugLog(1, @"there are %@ results", @(fetchResult.count));
          result = [fetchResult.lastObject dynamicCastToClass:[CHComputationEntryEntity class]];
          DebugLog(1, @"result = %p", result);
        }//end if (!self.managedObjectContext.hasChanges)
      }//end @synchronized(self.managedObjectContext)
    });
  }//end if (age)
  DebugLog(1, @"<chalkContext:computationEntryForAge:%@", @(age));
  return result;
}
//end chalkContext:computationEntryForAge:

-(CHComputationEntryEntity*) chalkContext:(CHChalkContext*)aChalkContext computationEntryForUid:(NSInteger)uid
{
  __block CHComputationEntryEntity* result = nil;
  DebugLog(1, @">chalkContext:computationEntryForUid:%@", @(uid));
  if (uid)
  {
    dispatch_with_main_option(DISPATCH_MAIN, ^(){
      NSError* error = nil;
      NSFetchRequest* fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[CHComputationEntryEntity entityName]];
      fetchRequest.includesPendingChanges = YES;
      fetchRequest.predicate = [NSPredicate predicateWithFormat:@"uniqueIdentifier == %@", @(uid)];
      NSArray* fetchResult = nil;
      @synchronized(self.managedObjectContext)
      {
        fetchResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
      }//end @synchronized(self.managedObjectContext)
      result = [fetchResult.lastObject dynamicCastToClass:[CHComputationEntryEntity class]];
    });
  }//end if (uid)
  DebugLog(1, @"<chalkContext:computationEntryForUid:%@", @(uid));
  return result;
}
//end chalkContext:computationEntryForUid:

-(void) userDefaultsDidChange:(NSNotification*)notification
{
  if (!self->isUpdatingPreferences)
  {
    [self updateGuiForPreferences];
    CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
    self.defaultComputationConfiguration = preferencesController.computationConfigurationCurrent;
    self.defaultPresentationConfiguration = preferencesController.presentationConfigurationCurrent;
    [self updateDocumentControlsForComputationConfiguration:self.currentComputationConfiguration presentationConfiguration:self.currentPresentationConfiguration chalkValue:self.currentComputationEntry.chalkValue1];
  }//end if (!self->isUpdatingPreferences)
}
//end userDefaultsDidChange:

-(void) updateGuiForPreferences
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  chalk_parse_mode_t parseMode = preferencesController.parseMode;
  NSString* hint = nil;
  switch(parseMode)
  {
    case CHALK_PARSE_MODE_UNDEFINED:
      break;
    case CHALK_PARSE_MODE_INFIX:
      hint = NSLocalizedString(@"Expression", @"");
      break;
    case CHALK_PARSE_MODE_RPN:
      hint = NSLocalizedString(@"Expression (RPN mode)", @"");
      break;
  }//end switch(parseMode)
  NSAttributedString* attributedString = !hint ? nil :
    [[[NSAttributedString alloc] initWithString:hint attributes:@{NSFontAttributeName:[NSFont controlContentFontOfSize:[NSFont systemFontSize]],NSForegroundColorAttributeName:[NSColor disabledControlTextColor]}] autorelease];
  [[self->inputTextField cell] setPlaceholderAttributedString:attributedString];
}
//end updateGuiForPreferences

#pragma mark NSControlTextEditingDelegate
-(BOOL) control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)command
{
  BOOL result = NO;
  if (command == @selector(insertNewlineIgnoringFieldEditor:))
  {
    [self startComputing:control];
    result = YES;
  }//end if (command == @selector(insertLineBreak:))
  else if (command == @selector(moveUp:))
  {
    [[[self->outputWebView evaluateJavaScriptFunction:@"selectionGetAge" withJSONArguments:nil wait:YES] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
    [[[self->outputWebView evaluateJavaScriptFunction:@"selectionSetAgeOlder" withJSONArguments:nil wait:YES] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
    NSText* textEditor = self->inputTextField.currentEditor;
    NSString* candidateString = self.currentComputationEntry.inputRawString;
    if (candidateString)
    {
      textEditor.string = candidateString;
      textEditor.selectedRange = NSMakeRange(0, textEditor.string.length);
    }//end if (candidateString)
    result = YES;
  }//end if (command == @selector(moveUp:))
  else if (command == @selector(moveDown:))
  {
    NSUInteger oldAge = [[[self->outputWebView evaluateJavaScriptFunction:@"selectionGetAge" withJSONArguments:nil wait:YES] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
    [[[self->outputWebView evaluateJavaScriptFunction:@"selectionSetAgeNewer" withJSONArguments:nil wait:YES] dynamicCastToClass:[NSNumber class]] unsignedIntegerValue];
    if (oldAge > 1)
    {
      NSText* textEditor = self->inputTextField.currentEditor;
      NSString* candidateString = self.currentComputationEntry.inputRawString;
      if (candidateString)
      {
        textEditor.string = candidateString;
        textEditor.selectedRange = NSMakeRange(0, textEditor.string.length);
      }//end if (candidateString)
    }//end if (oldAge > 1)
    else if ((oldAge == 1) && self->ans0)
    {
      NSText* textEditor = self->inputTextField.currentEditor;
      if (self->ans0)
      {
        textEditor.string = self->ans0;
        textEditor.selectedRange = NSMakeRange(0, textEditor.string.length);
      }//end if (self->ans0)
    }//end if ((oldAge == 1) && self->ans0)
    result = YES;
  }//end if (command == @selector(moveDown:))
  else if (command == @selector(deleteToBeginningOfLine:))
  {
    if (([NSEvent modifierFlags] & NSCommandKeyMask) != 0)
    {
      id age = [self->outputWebView evaluateJavaScriptFunction:@"selectionGetAge" withJSONArguments:nil wait:YES];
      NSNumber* ageNumber = [age dynamicCastToClass:[NSNumber class]];
      if (ageNumber)
      {
        NSUInteger ageInteger = ageNumber.unsignedIntegerValue;
        CHComputationEntryEntity* computationEntry = [self chalkContext:self->chalkContext computationEntryForAge:ageInteger];
        NSNumber* uid = !computationEntry ? nil : @(computationEntry.uniqueIdentifier);
        NSArray* args = !uid ? nil : @[uid];
        id ok = !args ? @NO : [self->outputWebView evaluateJavaScriptFunction:@"removeEntryFromUid" withJSONArguments:args wait:YES];
        result = [[ok dynamicCastToClass:[NSNumber class]] boolValue];
      }//end if (ageNumber)
    }//end if (([NSEvent modifierFlags] & NSCommandKeyMask) != 0)
  }//end if (command == @selector(deleteBackward:))
  return result;
}
//end control:textView:doCommandBySelector:

#pragma mark NSTableViewDelegate

-(void) tableViewSelectionDidChange:(NSNotification*)notification
{
  id object = notification.object;
  if (!object || (object == self->userVariableItemsTableView))
  {
    NSArray* selectedObjects = [self->userVariableItemsController.arrangedObjects objectsAtIndexes:self->userVariableItemsController.selectionIndexes];
    __block BOOL hasNonProtectedItem = NO;
    [selectedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHUserVariableItem* userVariableItem = [obj dynamicCastToClass:[CHUserVariableItem class]];
      hasNonProtectedItem |= userVariableItem && !userVariableItem.isProtected;
      *stop |= hasNonProtectedItem;
    }];
    self->userVariableItemsRemoveButton.enabled = hasNonProtectedItem && !self.isComputing;
  }//end if (!object || (object == self->userVariableItemsTableView))
  if (!object || (object == self->userFunctionItemsTableView))
  {
    NSArray* selectedObjects = [self->userFunctionItemsController.arrangedObjects objectsAtIndexes:self->userFunctionItemsController.selectionIndexes];
    __block BOOL hasNonProtectedItem = NO;
    [selectedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHUserFunctionItem* userFunctionItem = [obj dynamicCastToClass:[CHUserFunctionItem class]];
      hasNonProtectedItem |= userFunctionItem && !userFunctionItem.isProtected;
      *stop |= hasNonProtectedItem;
    }];
    self->userFunctionItemsRemoveButton.enabled = hasNonProtectedItem && !self.isComputing;
  }//end if (!object || (object == self->userFunctionItemsTableView))
}
//end tableViewSelectionDidChange:

-(void) tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
  if (tableView == self->userVariableItemsTableView)
  {
    CHUserVariableItem* userVariableItem = [[self->userVariableItemsController.arrangedObjects objectAtIndex:row] dynamicCastToClass:[CHUserVariableItem class]];
    BOOL hasError = !userVariableItem.isProtected && (userVariableItem.parseError != nil);
    BOOL circularDependency = userVariableItem.hasCircularDependency;
    NSTextFieldCell* textFieldCell = [cell dynamicCastToClass:[NSTextFieldCell class]];
    textFieldCell.textColor = userVariableItem.isProtected ? [NSColor disabledControlTextColor] : [NSColor textColor];
    textFieldCell.backgroundColor = hasError || circularDependency ? [NSColor colorWithCalibratedRed:253/255. green:177/255. blue:179/255. alpha:1.] : [NSColor clearColor];
    textFieldCell.drawsBackground = hasError || circularDependency;
  }//end if (tableView == self->userVariableItemsTableView)
  else if (tableView == self->userFunctionItemsTableView)
  {
    CHUserFunctionItem* userFunctionItem = [[self->userFunctionItemsController.arrangedObjects objectAtIndex:row] dynamicCastToClass:[CHUserFunctionItem class]];
    NSTextFieldCell* textFieldCell = [cell dynamicCastToClass:[NSTextFieldCell class]];
    textFieldCell.textColor = userFunctionItem.isProtected ? [NSColor disabledControlTextColor] : [NSColor textColor];
  }//end if (tableView == self->userFunctionItemsTableView)
}
//end tableView:willDisplayCell:forTableColumn:row:

#pragma mark NSTableViewDataSource
-(void) tableView:(NSTableView*)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
  if ([tableColumn.identifier isEqualToString:CHUserVariableItemIsDynamicKey])
  {
    CHUserVariableItem* userVariableItem = [[self->userVariableItemsController.arrangedObjects objectAtIndex:row] dynamicCastToClass:[CHUserVariableItem class]];
    if (userVariableItem.isDynamic)
    {
      [userVariableItem performEvaluation];
      NSArray* updatedUserVariableItems = @[userVariableItem];
      NSMutableArray* dirtyUserVariableItems = [NSMutableArray array];
      NSArray* dirtyIdentifiers = [self->dependencyManager identifierDependentObjectsToUpdateFrom:updatedUserVariableItems];
      [dirtyIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
        if (![updatedUserVariableItems containsObject:identifierDependent])
          [identifierDependent refreshIdentifierDependencies];
        [dirtyUserVariableItems safeAddObject:[obj dynamicCastToClass:[CHUserVariableItem class]]];
      }];//end for each curveItem
      [dirtyUserVariableItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[obj dynamicCastToClass:[CHUserVariableItem class]] performEvaluation];
      }];//end for each dirtyUserVariableItem
      [self->userVariableItemsTableView reloadData];
    }//end if (userVariableItem)
  }//end if ([tableColumn.identifier isEqualToString:CHUserVariableItemIsDynamicKey])
}
//end tableView:setObjectValue:forTableColumn:row:

-(IBAction) feedPasteboard:(id _Nullable)sender
{
  NSMenuItem* senderAsMenuItem = [sender dynamicCastToClass:[NSMenuItem class]];
  BOOL isInput = (senderAsMenuItem.menu == self->inputPopUpButton.menu);
  BOOL isOutput = (senderAsMenuItem.menu == self->outputPopUpButton.menu);
  chalk_export_format_t format = (chalk_export_format_t)senderAsMenuItem.tag;
  
  NSString* string = nil;
  NSColor* foregroundColor = nil;
  CHComputationEntryEntity* computationEntry = self.currentComputationEntry;
  if (isInput)
  {
    string = (format == CHALK_EXPORT_FORMAT_STRING) ? computationEntry.inputRawString :
     computationEntry.inputInterpretedTeXString;
    foregroundColor = self->inputColorColorWell.color;
  }//end if (isInput)
  else if (isOutput)
  {
    string = (format == CHALK_EXPORT_FORMAT_STRING) ? computationEntry.outputRawString :
     computationEntry.outputTeXString;
    foregroundColor = self->outputColorColorWell.color;
  }//end if (isOutput)

  if ((format != CHALK_EXPORT_FORMAT_UNDEFINED) && string.length)
  {
    self->svgRenderer = [[CHSVGRenderer alloc] init];
    NSData* metadata = [CHSVGRenderer metadataFromInputString:string foregroundColor:foregroundColor];
    [self->svgRenderer render:string foregroundColor:foregroundColor format:format metadata:metadata feedPasteboard:YES];
  }//end if ((format != CHALK_EXPORT_FORMAT_UNDEFINED) && string.length)
}
//end feedPasteboard:

-(void) printOperationDidRun:(NSPrintOperation*)printOperation success:(BOOL)success contextInfo:(void*)contextInfo
{
}
//end printOperationDidRun:success:contextInfo:

-(IBAction) printDocument:(id _Nullable)sender
{
  //[self->outputWebView print:sender];
  NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
  printInfo.horizontalPagination = NSFitPagination;
  printInfo.verticalPagination = NSAutoPagination;
  printInfo.orientation = NSPortraitOrientation;
  NSPrintOperation* printOperation = [self->outputWebView.webFrame.frameView printOperationWithPrintInfo:printInfo];
  //[printOperation runOperation];
  [printOperation runOperationModalForWindow:self.windowForSheet
                                  delegate:self 
                            didRunSelector:@selector(printOperationDidRun:success:contextInfo:)
                               contextInfo:nil];
}
//end printDocument:

@end
