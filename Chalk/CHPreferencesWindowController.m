//  PreferencesWindowController.m
// Chalk
//
//  Created by Pierre Chatelier on 1/04/05.
//  Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011 Pierre Chatelier. All rights reserved.

//The preferences controller centralizes the management of the preferences pane

#import "CHPreferencesWindowController.h"

#import "CHActionObject.h"
#import "CHAppDelegate.h"
#import "CHArrayController.h"
#import "CHBoolTransformer.h"
#import "CHChalkUtils.h"
#import "CHGenericTransformer.h"
#import "CHIsNotEqualToTransformer.h"
#import "CHKeyedUnarchiveFromDataTransformer.h"
#import "CHPreferencesController.h"
#import "CHStepperNumber.h"
#import "CHTableView.h"
#import "NSArrayExtended.h"
#import "NSColorExtended.h"
#import "NSNumberExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"
#import "NSUserDefaultsControllerExtended.h"
#import "NSViewExtended.h"

#import <Sparkle/Sparkle.h>

NSString* GeneralToolbarItemIdentifier = @"GeneralToolbarItemIdentifier";
NSString* EditionToolbarItemIdentifier = @"EditionToolbarItemIdentifier";
NSString* WebToolbarItemIdentifier     = @"WebToolbarItemIdentifier";

@interface CHPreferencesWindowController ()
@end

@implementation CHPreferencesWindowController

-(id) init
{
  if ((!(self = [super initWithWindowNibName:@"CHPreferencesWindowController"])))
    return nil;
  self->emptyView = [[NSView alloc] initWithFrame:NSZeroRect];
  self->toolbarItems = [[NSMutableDictionary alloc] init];
  self->basesConflictingForPrefixes = [[NSMutableIndexSet alloc] init];
  self->basesConflictingForSuffixes = [[NSMutableIndexSet alloc] init];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:)
                                               name:NSApplicationWillTerminateNotification object:nil];
  return self;
}
//end init

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  NSUserDefaultsController* userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsDigitsBaseKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsDigitsBaseKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsDigitsBaseKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsDigitsBaseKey]];
  [userDefaultsController removeObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHBasePrefixesSuffixesKey]];
  [self->basesConflictingForPrefixes release];
  [self->basesConflictingForSuffixes release];
  [self->emptyView release];
  [self->viewsMinSizes release];
  [self->toolbarItems release];
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  self->viewsMinSizes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
    [NSValue valueWithSize:[self->generalView frame].size], GeneralToolbarItemIdentifier,
    [NSValue valueWithSize:[self->editionView frame].size], EditionToolbarItemIdentifier,
    [NSValue valueWithSize:[self->webView frame].size], WebToolbarItemIdentifier,
    nil];

  NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier:@"preferencesToolbar"];
  [toolbar setDelegate:self];
  NSWindow* window = [self window];
  [window setTitle:NSLocalizedString(@"Preferences", @"")];
  [window setDelegate:self];
  [window setToolbar:toolbar];
  [window setShowsToolbarButton:NO];
  [toolbar setSelectedItemIdentifier:GeneralToolbarItemIdentifier];
  [self toolbarHit:[self->toolbarItems objectForKey:[toolbar selectedItemIdentifier]]];
  [toolbar release];
  
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  NSUserDefaultsController* userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
  NSRect frame = NSZeroRect;
  NSView* parentView = nil;
  
  //General
  self->computationLimitsBox.title = NSLocalizedString(@"Computation limits", @"");
  NSNumber* softIntegerMaxBitsMinimum = self->softIntegerMaxBitsNumberFormatter.minimum;
  NSNumber* softIntegerMaxBitsMaximum = self->softIntegerMaxBitsNumberFormatter.maximum;
  self->softIntegerMaxBitsStepper.minValue = !softIntegerMaxBitsMinimum ? @(2) :
    softIntegerMaxBitsMinimum;
  self->softIntegerMaxBitsStepper.maxValue = !softIntegerMaxBitsMaximum ? @(NSUIntegerMax) :
    softIntegerMaxBitsMaximum;
  self->softIntegerMaxBitsLabel.stringValue =
    [NSString stringWithFormat:@"%@ :",
       NSLocalizedString(@"Soft max integer bits", @"")];
  [self->softIntegerMaxBitsTextField bind:NSValueBinding toObject:userDefaultsController
                              withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsKey]
                                  options:nil];
  [self->softIntegerMaxBitsStepper bind:NSValueBinding toObject:userDefaultsController
                            withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsKey]
                                options:nil];
  self->softIntegerMaxBitsDigitsInBaseLabel.stringValue = NSLocalizedString(@"Digits in base", @"");
  [self->softIntegerMaxBitsDigitsInBaseBaseTextField bind:NSValueBinding toObject:userDefaultsController
                              withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsDigitsBaseKey]
                                  options:nil];
  [self->softIntegerMaxBitsDigitsInBaseBaseStepper bind:NSValueBinding toObject:userDefaultsController
                            withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsDigitsBaseKey]
                                options:nil];
  self->softIntegerMaxBitsDigitsMinButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softIntegerMaxBits;
    preferencesController.softIntegerMaxBits = MAX(2, prevPowerOfTwo(value, YES));
  }] retain];
  [self->softIntegerMaxBitsDigitsMinButton setAction:@selector(action:)];
  self->softIntegerMaxBitsDigitsMaxButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softIntegerMaxBits;
    preferencesController.softIntegerMaxBits = (2*value < value) ? NSUIntegerMax : nextPowerOfTwo(value, YES);
  }] retain];
  [self->softIntegerMaxBitsDigitsMaxButton setAction:@selector(action:)];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsKey]
                              options:NSKeyValueObservingOptionInitial context:0];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerMaxBitsDigitsBaseKey]
                              options:NSKeyValueObservingOptionInitial context:0];

  self->softIntegerDenominatorMaxBitsLabel.stringValue =
    [NSString stringWithFormat:@"%@ :",
       NSLocalizedString(@"Soft max integer denominator bits", @"")];
  [self->softIntegerDenominatorMaxBitsTextField bind:NSValueBinding toObject:userDefaultsController
                              withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsKey]
                                  options:nil];
  [self->softIntegerDenominatorMaxBitsStepper bind:NSValueBinding toObject:userDefaultsController
                            withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsKey]
                                options:nil];
  self->softIntegerDenominatorMaxBitsDigitsInBaseLabel.stringValue = NSLocalizedString(@"Digits in base", @"");
  [self->softIntegerDenominatorMaxBitsDigitsInBaseBaseTextField bind:NSValueBinding toObject:userDefaultsController
                              withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsDigitsBaseKey]
                                  options:nil];
  [self->softIntegerDenominatorMaxBitsDigitsInBaseBaseStepper bind:NSValueBinding toObject:userDefaultsController
                            withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsDigitsBaseKey]
                                options:nil];
  self->softIntegerDenominatorMaxBitsDigitsMinButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softIntegerDenominatorMaxBits;
    preferencesController.softIntegerDenominatorMaxBits = MAX(2, prevPowerOfTwo(value, YES));
  }] retain];
  [self->softIntegerDenominatorMaxBitsDigitsMinButton setAction:@selector(action:)];
  self->softIntegerDenominatorMaxBitsDigitsMaxButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softIntegerDenominatorMaxBits;
    preferencesController.softIntegerDenominatorMaxBits = MIN(preferencesController.softIntegerMaxBits, (2*value < value) ? NSUIntegerMax : nextPowerOfTwo(value, YES));
  }] retain];
  [self->softIntegerDenominatorMaxBitsDigitsMaxButton setAction:@selector(action:)];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsKey]
                              options:NSKeyValueObservingOptionInitial context:0];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftIntegerDenominatorMaxBitsDigitsBaseKey]
                              options:NSKeyValueObservingOptionInitial context:0];

  self->softFloatSignificandBitsLabel.stringValue =
    [NSString stringWithFormat:@"%@ :",
      NSLocalizedString(@"Soft float significand bits", @"")];
  [self->softFloatSignificandBitsTextField bind:NSValueBinding toObject:userDefaultsController
                                    withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsKey]
                                        options:nil];
  [self->softFloatSignificandBitsStepper bind:NSValueBinding toObject:userDefaultsController
                                  withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsKey]
                                      options:nil];
  self->softFloatSignificandBitsDigitsInBaseLabel.stringValue = NSLocalizedString(@"Digits in base", @"");
  [self->softFloatSignificandBitsDigitsInBaseBaseTextField bind:NSValueBinding toObject:userDefaultsController
                                                    withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsDigitsBaseKey]
                                                        options:nil];
  [self->softFloatSignificandBitsDigitsInBaseBaseStepper bind:NSValueBinding toObject:userDefaultsController
                                                  withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsDigitsBaseKey]
                                                      options:nil];
  self->softFloatSignificandBitsDigitsMinButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softFloatSignificandBits;
    preferencesController.softFloatSignificandBits = MAX(2, prevPowerOfTwo(value, YES));
  }] retain];
  [self->softFloatSignificandBitsDigitsMinButton setAction:@selector(action:)];
  self->softFloatSignificandBitsDigitsMaxButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softFloatSignificandBits;
    preferencesController.softFloatSignificandBits = (2*value < value) ? NSUIntegerMax : nextPowerOfTwo(value, YES);
  }] retain];
  [self->softFloatSignificandBitsDigitsMaxButton setAction:@selector(action:)];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsKey]
                              options:NSKeyValueObservingOptionInitial context:0];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsDigitsBaseKey]
                              options:NSKeyValueObservingOptionInitial context:0];

  self->softFloatDisplayBitsLabel.stringValue =
    [NSString stringWithFormat:@"%@ :",
      NSLocalizedString(@"Digits displayed", @"")];
  [self->softFloatDisplayBitsTextField bind:NSValueBinding toObject:userDefaultsController
                                    withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsKey] options:nil];
  [self->softFloatDisplayBitsTextField bind:NSMaxValueBinding toObject:userDefaultsController
                                withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsKey] options:nil];
  [self->softFloatDisplayBitsStepper bind:NSValueBinding toObject:userDefaultsController
                                withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsKey] options:nil];
  [self->softFloatDisplayBitsStepper bind:NSMaxValueBinding toObject:userDefaultsController
                                withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatSignificandBitsKey] options:nil];
  self->softFloatDisplayBitsDigitsInBaseLabel.stringValue = NSLocalizedString(@"Digits in base", @"");
  [self->softFloatDisplayBitsDigitsInBaseBaseTextField bind:NSValueBinding toObject:userDefaultsController
                                                   withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsDigitsBaseKey]
                                                       options:nil];
  [self->softFloatDisplayBitsDigitsInBaseBaseStepper bind:NSValueBinding toObject:userDefaultsController
                                              withKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsDigitsBaseKey]
                                                  options:nil];
  self->softFloatDisplayBitsDigitsMinButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softFloatDisplayBits;
    preferencesController.softFloatDisplayBits = MAX(2, prevPowerOfTwo(value, YES));
  }] retain];
  [self->softFloatDisplayBitsDigitsMinButton setAction:@selector(action:)];
  self->softFloatDisplayBitsDigitsMaxButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSUInteger value = preferencesController.softFloatDisplayBits;
    preferencesController.softFloatDisplayBits = MIN(preferencesController.softFloatSignificandBits, (2*value < value) ? NSUIntegerMax : nextPowerOfTwo(value, YES));
  }] retain];
  [self->softFloatDisplayBitsDigitsMaxButton setAction:@selector(action:)];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsKey]
                              options:NSKeyValueObservingOptionInitial context:0];
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHSoftFloatDisplayBitsDigitsBaseKey]
                              options:NSKeyValueObservingOptionInitial context:0];

  self->computationBehaviourBox.title = NSLocalizedString(@"Computation behaviour", @"");
  self->raiseErrorOnNaNCheckBox.title = NSLocalizedString(@"Raise error on NaN", @"");
  [self->raiseErrorOnNaNCheckBox sizeToFit];
  [self->raiseErrorOnNaNCheckBox bind:NSValueBinding toObject:userDefaultsController
                       withKeyPath:[userDefaultsController adaptedKeyPath:CHPropagateNaNKey]
                           options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];

  self->baseUseLowercaseCheckBox.title = NSLocalizedString(@"Use lowercase", @"");
  [self->baseUseLowercaseCheckBox sizeToFit];
  [self->baseUseLowercaseCheckBox bind:NSValueBinding toObject:userDefaultsController
                       withKeyPath:[userDefaultsController adaptedKeyPath:CHBaseUseLowercaseKey]
                           options:nil];

  self->baseUseDecimalExponentCheckBox.title = NSLocalizedString(@"Use decimal exponent", @"");
  [self->baseUseDecimalExponentCheckBox sizeToFit];
  [self->baseUseDecimalExponentCheckBox bind:NSValueBinding toObject:userDefaultsController
                       withKeyPath:[userDefaultsController adaptedKeyPath:CHBaseUseDecimalExponentKey]
                           options:nil];
  
  float rightMargin = self->computationLimitsDefaultsButton.superview.bounds.size.width-CGRectGetMaxX(self->computationLimitsDefaultsButton.frame);
  self->computationLimitsDefaultsButton.title = NSLocalizedString(@"defaults", @"");
  [self->computationLimitsDefaultsButton sizeToFit];
  frame = self->computationLimitsDefaultsButton.frame;
  frame.origin.x = self->computationLimitsDefaultsButton.superview.bounds.size.width-rightMargin-frame.size.width;
  self->computationLimitsDefaultsButton.frame = frame;
  self->computationLimitsDefaultsButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSDictionary* defaults = [CHPreferencesController defaults];
    preferencesController.softIntegerMaxBits = [[defaults objectForKey:CHSoftIntegerMaxBitsKey] floatValue];
    preferencesController.softIntegerDenominatorMaxBits = [[defaults objectForKey:CHSoftIntegerDenominatorMaxBitsKey] floatValue];
    preferencesController.softFloatSignificandBits = [[defaults objectForKey:CHSoftFloatSignificandBitsKey] floatValue];
    preferencesController.softFloatDisplayBits = [[defaults objectForKey:CHSoftFloatDisplayBitsKey] floatValue];
  }] retain];
  [self->computationLimitsDefaultsButton setAction:@selector(action:)];

  //Edition
  [userDefaultsController addObserver:self forKeyPath:[userDefaultsController adaptedKeyPath:CHBasePrefixesSuffixesKey] options:NSKeyValueObservingOptionInitial context:0];
  self->basePrefixesSuffixesTableView.delegate = self;
  self->basePrefixesSuffixesTableView.arrayController = preferencesController.basePrefixesSuffixesController;
  self->basePrefixesSuffixesTableView.doubleAction = @selector(doubleAction:);
  [[self->basePrefixesSuffixesTableView tableColumnWithIdentifier:CHBaseBaseKey].headerCell setStringValue:NSLocalizedString(@"Base", @"")];
  [[self->basePrefixesSuffixesTableView tableColumnWithIdentifier:CHBasePrefixesKey].headerCell setStringValue:NSLocalizedString(@"Prefixes", @"")];
  [[self->basePrefixesSuffixesTableView tableColumnWithIdentifier:CHBaseSuffixesKey].headerCell setStringValue:NSLocalizedString(@"Suffixes", @"")];
  typedef id (^filter_t)(id object);
  filter_t (^filterGenerator)(BOOL, BOOL) = ^filter_t(BOOL prefix, BOOL suffix) {
    NSDictionary* attributesOk = @{NSForegroundColorAttributeName:[NSColor textColor]};
    NSDictionary* attributesNonOk = @{NSForegroundColorAttributeName:[NSColor redColor]};
    NSAttributedString* attributedSeparator =
      [[[NSAttributedString alloc] initWithString:@";" attributes:attributesOk] autorelease];
    filter_t result = ^id(id object) {
      id result = nil;
      NSArray* components = [object dynamicCastToClass:[NSArray class]];
      NSMutableAttributedString* attributedString = [[[NSMutableAttributedString alloc] init] autorelease];
      [components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString* token = [obj dynamicCastToClass:[NSString class]];
        if (![NSString isNilOrEmpty:token])
        {
          BOOL ok = (!prefix ? YES : chalkGmpBaseIsValidPrefix(token)) &&
                    (!suffix ? YES : chalkGmpBaseIsValidSuffix(token));
          NSAttributedString* attributedToken =
            [[[NSAttributedString alloc] initWithString:token
                                             attributes:(ok ? attributesOk : attributesNonOk)] autorelease];
          if (attributedString.length)
            [attributedString appendAttributedString:attributedSeparator];
          [attributedString appendAttributedString:attributedToken];
        }//end if (![NSString isNilOrEmpty:token])
      }];
      NSMutableParagraphStyle * paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
      [paragraphStyle setAlignment:NSCenterTextAlignment];
      [attributedString addAttributes:@{NSParagraphStyleAttributeName:paragraphStyle}
        range:NSMakeRange(0, attributedString.length)];
      result = attributedString;
      return result;
    };
    return [[result copy] autorelease];
  };//end filterGenerator

  filter_t filterPrefix = filterGenerator(YES, NO);
  filter_t filterSuffix = filterGenerator(NO, YES);
  
  filter_t (^reverseFilterGenerator)(BOOL, BOOL) = ^filter_t(BOOL prefix, BOOL suffix) {
    filter_t result = ^id(id object) {
      id result = nil;
      NSAttributedString* attributedString = [object dynamicCastToClass:[NSAttributedString class]];
      NSString* string = attributedString ? [attributedString string] :
        [object dynamicCastToClass:[NSString class]];
      result = [[string componentsSeparatedByString:@";" allowEmpty:NO] arrayByRemovingDuplicates];
      return result;
    };
    return [[result copy] autorelease];
  };
  
  filter_t reverseFilterPrefix = reverseFilterGenerator(YES, NO);
  filter_t reverseFilterSuffix = reverseFilterGenerator(NO, YES);

  CHGenericTransformer* genericTransformerPrefix = [CHGenericTransformer transformerWithBlock:filterPrefix reverse:reverseFilterPrefix];
  CHGenericTransformer* genericTransformerSuffix = [CHGenericTransformer transformerWithBlock:filterSuffix reverse:reverseFilterSuffix];
  [self->basePrefixesSuffixesTableView setValueTransformer:genericTransformerPrefix forKey:CHBasePrefixesKey];
  [self->basePrefixesSuffixesTableView setValueTransformer:genericTransformerSuffix forKey:CHBaseSuffixesKey];

  self->parsingAndInterpretationBox.title = NSLocalizedString(@"Parsing and interpretation", @"");
  self->parseModeLabel.stringValue = NSLocalizedString(@"Parse mode :", @"");
  [self->parseModeLabel sizeToFit];
  [self->parseModePopUpButton removeAllItems];
  [self->parseModePopUpButton addItemWithTitle:NSLocalizedString(@"Infix notation (standard)", @"")];
  [[self->parseModePopUpButton lastItem] setTag:CHALK_PARSE_MODE_INFIX];
  [self->parseModePopUpButton addItemWithTitle:NSLocalizedString(@"Reverse Polish notation (RPN)", @"")];
  [[self->parseModePopUpButton lastItem] setTag:CHALK_PARSE_MODE_RPN];
  [self->parseModePopUpButton bind:NSSelectedTagBinding toObject:preferencesController withKeyPath:CHParseModeKey options:nil];
  [self->parseModePopUpButton sizeToFit];
  CGRect parseModeLabelFrame = NSRectToCGRect(self->parseModeLabel.frame);
  CGRect parseModePopUpFrame = NSRectToCGRect(self->parseModePopUpButton.frame);
  self->parseModePopUpButton.frame = NSMakeRect(
    CGRectGetMaxX(parseModeLabelFrame),
    self->parseModePopUpButton.frame.origin.y,
    self->parseModeLabel.superview.frame.size.width-CGRectGetMinX(parseModeLabelFrame)-CGRectGetMaxX(parseModeLabelFrame),
    parseModePopUpFrame.size.height);
  
  self->nextInputModeLabel.stringValue = [NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Prepare next input", @"")];
  [self->nextInputModeLabel sizeToFit];
  [self->nextInputModePopUpButton removeAllItems];
  [self->nextInputModePopUpButton addItemWithTitle:NSLocalizedString(@"Empty", @"")];
  [[self->nextInputModePopUpButton lastItem] setTag:CHALK_NEXTINPUT_MODE_BLANK];
  [self->nextInputModePopUpButton addItemWithTitle:NSLocalizedString(@"Previous input", @"")];
  [[self->nextInputModePopUpButton lastItem] setTag:CHALK_NEXTINPUT_MODE_PREVIOUS_INPUT];
  [self->nextInputModePopUpButton addItemWithTitle:@"output(1)"];
  [[self->nextInputModePopUpButton lastItem] setTag:CHALK_NEXTINPUT_MODE_FUNCTION_OUTPUT];
  [self->nextInputModePopUpButton bind:NSSelectedTagBinding toObject:preferencesController withKeyPath:CHNextInputModeKey options:nil];
  [self->nextInputModePopUpButton sizeToFit];
  CGRect nextInputModeLabelFrame = NSRectToCGRect(self->nextInputModeLabel.frame);
  CGRect nextInputModePopUpFrame = NSRectToCGRect(self->nextInputModePopUpButton.frame);
  self->nextInputModePopUpButton.frame = NSMakeRect(
    CGRectGetMaxX(nextInputModeLabelFrame),
    self->nextInputModePopUpButton.frame.origin.y,
    self->nextInputModeLabel.superview.frame.size.width-CGRectGetMinX(nextInputModeLabelFrame)-CGRectGetMaxX(nextInputModeLabelFrame),
    nextInputModePopUpFrame.size.height);

  self->parsingAndInterpretationDefaultsButton.title = NSLocalizedString(@"defaults", @"");
  [self->parsingAndInterpretationDefaultsButton sizeToFit];
  frame = NSRectToCGRect(self->parsingAndInterpretationDefaultsButton.frame);
  self->parsingAndInterpretationDefaultsButton.frame = CGRectMake(
    self->parsingAndInterpretationDefaultsButton.superview.frame.size.width-20-frame.size.width,
    frame.origin.y,
    frame.size.width,
    frame.size.height);
  self->parsingAndInterpretationDefaultsButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    NSDictionary* defaults = [CHPreferencesController defaults];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[defaults objectForKey:CHParseModeKey] forKey:CHParseModeKey];
    [userDefaults setObject:[defaults objectForKey:CHBaseUseLowercaseKey] forKey:CHBaseUseLowercaseKey];
    [userDefaults setObject:[defaults objectForKey:CHBaseUseDecimalExponentKey] forKey:CHBaseUseDecimalExponentKey];
    [userDefaults setObject:[defaults objectForKey:CHBasePrefixesSuffixesKey] forKey:CHBasePrefixesSuffixesKey];
  }] retain];
  self->parsingAndInterpretationDefaultsButton.action = @selector(action:);
  
  self->bitInspectorBox.title = NSLocalizedString(@"Bits inspector", @"");
  [self->bitInterpretationSignColorColorWell bind:NSValueBinding toObject:preferencesController withKeyPath:CHBitInterpretationSignColorKey options:nil];
  [self->bitInterpretationExponentColorColorWell bind:NSValueBinding toObject:preferencesController withKeyPath:CHBitInterpretationExponentColorKey options:nil];
  [self->bitInterpretationSignificandColorColorWell bind:NSValueBinding toObject:preferencesController withKeyPath:CHBitInterpretationSignificandColorKey options:nil];
  self->bitInterpretationSignColorLabel.stringValue = NSLocalizedString(@"Color for sign bits", @"");
  [self->bitInterpretationSignColorLabel sizeToFit];
  self->bitInterpretationExponentColorLabel.stringValue = NSLocalizedString(@"Color for exponent bits", @"");
  [self->bitInterpretationExponentColorLabel sizeToFit];
  self->bitInterpretationSignificandColorLabel.stringValue = NSLocalizedString(@"Color for significand bits", @"");
  [self->bitInterpretationSignificandColorLabel sizeToFit];
  self->bitInterpretationColorsDefaultsButton.title = NSLocalizedString(@"defaults", @"");
  [self->bitInterpretationColorsDefaultsButton sizeToFit];
  frame = NSRectToCGRect(self->bitInterpretationColorsDefaultsButton.frame);
  self->bitInterpretationColorsDefaultsButton.frame = CGRectMake(
    self->bitInterpretationColorsDefaultsButton.superview.frame.size.width-20-frame.size.width,
    frame.origin.y,
    frame.size.width,
    frame.size.height);
  self->bitInterpretationColorsDefaultsButton.target = [[CHActionObject actionObjectWithActionBlock:^(id sender) {
    CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
    NSDictionary* defaults = [preferencesController defaults];
    preferencesController.bitInterpretationSignColor =
     [NSColor colorWithData:[[defaults objectForKey:CHBitInterpretationSignColorKey] dynamicCastToClass:[NSData class]]];
    preferencesController.bitInterpretationExponentColor =
     [NSColor colorWithData:[[defaults objectForKey:CHBitInterpretationExponentColorKey] dynamicCastToClass:[NSData class]]];
    preferencesController.bitInterpretationSignificandColor =
     [NSColor colorWithData:[[defaults objectForKey:CHBitInterpretationSignificandColorKey] dynamicCastToClass:[NSData class]]];
  }] retain];
  self->bitInterpretationColorsDefaultsButton.action = @selector(action:);

  //Web
  [self->updatesCheckUpdatesButton setTitle:NSLocalizedString(@"Automatically check updates", @"")];
  [self->updatesCheckUpdatesButton bind:NSValueBinding toObject:[(CHAppDelegate*)[NSApp delegate] sparkleUpdater]
                            withKeyPath:@"automaticallyChecksForUpdates"
                                options:[NSDictionary dictionaryWithObjectsAndKeys:
                                         [CHBoolTransformer transformerWithFalseValue:[NSNumber numberWithInt:NSOffState] trueValue:[NSNumber numberWithInt:NSOnState]],
                                         NSValueTransformerBindingOption, nil]];
  [self->updatesCheckUpdatesButton sizeToFit];
  parentView = [self->updatesCheckUpdatesButton superview];
  frame = [parentView frame];
  frame.size.width = [self->updatesCheckUpdatesButton frame].size.width+2*8;
  [parentView setFrame:frame];
  [self->updatesCheckUpdatesButton centerInParentHorizontally:YES vertically:NO];
  [self->updatesCheckUpdatesNowButton setTitle:NSLocalizedString(@"Check now...", @"")];
  [self->updatesCheckUpdatesNowButton setTarget:[NSApp delegate]];
  [self->updatesCheckUpdatesNowButton setAction:@selector(checkUpdates:)];
  [self->updatesCheckUpdatesNowButton sizeToFit];
  [self->updatesCheckUpdatesNowButton centerInParentHorizontally:YES vertically:NO];
  [self->updatesVisitWebSiteButton setTitle:NSLocalizedString(@"Visit web site...", @"")];
  [self->updatesVisitWebSiteButton setTarget:[NSApp delegate]];
  [self->updatesVisitWebSiteButton setAction:@selector(openWebSite:)];
  [self->updatesVisitWebSiteButton sizeToFit];
  [self->updatesVisitWebSiteButton centerInParentHorizontally:YES vertically:NO];
}
//end awakeFromNib

//initializes the controls with default values
-(void) windowDidLoad
{
  NSPoint topLeftPoint  = [[self window] frame].origin;
  topLeftPoint.y       += [[self window] frame].size.height;
  //[[self window] setFrameAutosaveName:@"preferences"];
  [[self window] setFrameTopLeftPoint:topLeftPoint];
}
//end windowDidLoad

-(void) windowWillClose:(NSNotification *)aNotification
{
  [[NSUserDefaults standardUserDefaults] synchronize];
}
//end windowWillClose:

-(NSSize) windowWillResize:(NSWindow*)window toSize:(NSSize)proposedFrameSize
{
  NSSize result = proposedFrameSize;
  if (window == [self window])
  {
    if (![window showsResizeIndicator])
    {
      result = [window frame].size;
      [window setFrameOrigin:[window frame].origin];
    }//end if (![window showsResizeIndicator])
  }//end if (window == [self window])
  return result;
}
//end windowWillResize:toSize:

-(NSArray*) toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
  return @[GeneralToolbarItemIdentifier, EditionToolbarItemIdentifier, WebToolbarItemIdentifier];
}
//end toolbarDefaultItemIdentifiers:

-(NSArray*) toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
  return [self toolbarDefaultItemIdentifiers:toolbar];
}
//end toolbarAllowedItemIdentifiers:

-(NSArray*) toolbarSelectableItemIdentifiers:(NSToolbar*)toolbar
{
  return [self toolbarDefaultItemIdentifiers:toolbar];
}
//end toolbarSelectableItemIdentifiers:
 
-(NSToolbarItem*) toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
  NSToolbarItem* item = [toolbarItems objectForKey:itemIdentifier];
  if (!item)
  {
    item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    
    NSString* label = nil;
    NSImage* image = nil;
    if ([itemIdentifier isEqualToString:GeneralToolbarItemIdentifier])
    {
      image = [NSImage imageNamed:@"NSPreferencesGeneral"];
      label = NSLocalizedString(@"General", @"");
    }//end if ([itemIdentifier isEqualToString:GeneralToolbarItemIdentifier])
    else if ([itemIdentifier isEqualToString:EditionToolbarItemIdentifier])
    {
      image = [NSImage imageNamed:@"editionToolbarItem"];
      label = NSLocalizedString(@"Edition", @"");
    }//end if ([itemIdentifier isEqualToString:WebToolbarItemIdentifier])
    else if ([itemIdentifier isEqualToString:WebToolbarItemIdentifier])
    {
      image = [NSImage imageNamed:@"webToolbarItem"];
      label = NSLocalizedString(@"Web", @"");
    }//end if ([itemIdentifier isEqualToString:WebToolbarItemIdentifier])
    [item setLabel:label];
    [item setImage:image];

    [item setTarget:self];
    [item setAction:@selector(toolbarHit:)];
    [toolbarItems setObject:item forKey:itemIdentifier];
  }//end if (item)
  return item;
}
//end toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:

-(IBAction) toolbarHit:(id)sender
{
  NSView* view = nil;
  NSString* itemIdentifier = [sender itemIdentifier];

  if ([itemIdentifier isEqualToString:GeneralToolbarItemIdentifier])
    view = self->generalView;
  else if ([itemIdentifier isEqualToString:EditionToolbarItemIdentifier])
    view = self->editionView;
  else if ([itemIdentifier isEqualToString:WebToolbarItemIdentifier])
    view = self->webView;

  NSWindow* window = [self window];
  NSView*   contentView = [window contentView];
  if (view != contentView)
  {
    NSSize contentMinSize = [[self->viewsMinSizes objectForKey:itemIdentifier] sizeValue];
    NSRect oldContentFrame = contentView ? [contentView frame] : NSZeroRect;
    NSRect newContentFrame = !view ? NSZeroRect : [view frame];
    NSRect newFrame = [window frame];
    newFrame.size.width  += (newContentFrame.size.width  - oldContentFrame.size.width);
    newFrame.size.height += (newContentFrame.size.height - oldContentFrame.size.height);
    newFrame.origin.y    -= (newContentFrame.size.height - oldContentFrame.size.height);
    [self->emptyView setFrame:newContentFrame];
    [window setContentView:self->emptyView];
    [window setFrame:newFrame display:YES animate:YES];
    [window setContentView:view];
    [window setContentMinSize:contentMinSize];
  }//end if (view != contentView)
    
  //update from SUUpdater
  [self->updatesCheckUpdatesNowButton setEnabled:![[(CHAppDelegate*)[NSApp delegate] sparkleUpdater] updateInProgress]];
}
//end toolbarHit:

-(void) selectPreferencesPaneWithItemIdentifier:(NSString*)itemIdentifier options:(id)options
{
  [[[self window] toolbar] setSelectedItemIdentifier:itemIdentifier];
  [self toolbarHit:[toolbarItems objectForKey:itemIdentifier]];
}
//end selectPreferencesPaneWithItemIdentifier:

-(IBAction) doubleAction:(id)sender
{
  if (sender == self->basePrefixesSuffixesTableView)
  {
    NSInteger clickedRow = self->basePrefixesSuffixesTableView.clickedRow;
    NSInteger clickedColumn = self->basePrefixesSuffixesTableView.clickedColumn;
    if ((clickedRow >= 0) && (clickedColumn >= 0))
    {
      NSArray* basePrefixesSuffixes =
       [[[CHPreferencesController sharedPreferencesController] basePrefixesSuffixesController] arrangedObjects];
      NSDictionary* dict = [[basePrefixesSuffixes objectAtIndex:(NSUInteger)clickedRow] dynamicCastToClass:[NSDictionary class]];
      NSTableColumn* tableColumn = [self->basePrefixesSuffixesTableView.tableColumns objectAtIndex:clickedColumn];
      NSString* tableColumnIdentifier = tableColumn.identifier;
      BOOL isPrefixColumnIdentifier = [tableColumnIdentifier isEqualToString:CHBasePrefixesKey];
      BOOL isSuffixColumnIdentifier = [tableColumnIdentifier isEqualToString:CHBasePrefixesKey];
      NSArray* components = [[dict objectForKey:tableColumnIdentifier] dynamicCastToClass:[NSArray class]];
      NSMutableArray* componentsWrapped = [NSMutableArray array];
      for(NSString* s in components)
        [componentsWrapped addObject:[[s mutableCopy] autorelease]];
      CHArrayController* arrayController = [[[CHArrayController alloc] initWithContent:componentsWrapped] autorelease];
      arrayController.objectCreator = ^(){return [NSMutableString stringWithString:@"0&"];};
      [arrayController setAutomaticallyPreparesContent:YES];
      [arrayController setObjectClass:[NSMutableDictionary class]];
      self->basePrefixesSuffixesDetailTableView.arrayController = arrayController;
      self->basePrefixesSuffixesDetailTableView.allowDragDropMoving = YES;
      self->basePrefixesSuffixesDetailTableView.allowDeletion = YES;
      NSTableColumn* detailColumn = self->basePrefixesSuffixesDetailTableView.tableColumns.firstObject;
      [detailColumn bind:NSTextColorBinding toObject:arrayController
        withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", detailColumn.identifier]
            options:@{NSValueTransformerBindingOption:
              [CHGenericTransformer transformerWithBlock:^id(id object) {
                 NSColor* result = [NSColor textColor];
                 NSString* token = [object dynamicCastToClass:[NSString class]];
                 result =
                   isPrefixColumnIdentifier && !chalkGmpBaseIsValidPrefix(token) ? [NSColor redColor] :
                   isSuffixColumnIdentifier && !chalkGmpBaseIsValidSuffix(token) ? [NSColor redColor] :
                   result;
                  return result;
               } reverse:nil]}];

      [self->basePrefixesSuffixesDetailAddButton setTarget:arrayController];
      [self->basePrefixesSuffixesDetailAddButton setAction:@selector(add:)];
      [self->basePrefixesSuffixesDetailRemoveButton setTarget:arrayController];
      [self->basePrefixesSuffixesDetailRemoveButton setAction:@selector(remove:)];
      [self->basePrefixesSuffixesDetailRemoveButton bind:NSEnabledBinding toObject:arrayController withKeyPath:@"selectionIndexes" options:
        @{NSValueTransformerBindingOption:[CHIsNotEqualToTransformer transformerWithReference:[NSIndexSet indexSet]]}];

      NSViewController* viewController = [[[NSViewController alloc] initWithNibName:nil bundle:nil] autorelease];
      viewController.representedObject = @{@"tableView":self->basePrefixesSuffixesDetailTableView, @"rowIndex":[NSNumber numberWithInteger:clickedRow], @"identifier":tableColumnIdentifier};
      viewController.view = self->basePrefixesSuffixesDetailView;
      NSPopover* popOver = [[[NSPopover alloc] init] autorelease];
      popOver.delegate = self;
      popOver.contentViewController = viewController;
      popOver.behavior = NSPopoverBehaviorTransient;
      NSRect cellRect = NSIntersectionRect([self->basePrefixesSuffixesTableView rectOfRow:clickedRow], [self->basePrefixesSuffixesTableView rectOfColumn:clickedColumn]);
      [popOver showRelativeToRect:cellRect ofView:self->basePrefixesSuffixesTableView preferredEdge:NSRectEdgeMaxY];
    }//end if ((clickedRow >= 0) && (clickedColumn >= 0))
  }//end if (sender == self->basePrefixesSuffixesTableView)
}
//end doubleAction:

-(void) popoverDidClose:(NSNotification *)notification
{
  NSViewController* viewController =((NSPopover*)[[notification object] dynamicCastToClass:[NSPopover class]]).contentViewController;
  NSDictionary* dict = [viewController.representedObject dynamicCastToClass:[NSDictionary class]];
  CHTableView* tableView = [[dict objectForKey:@"tableView"] dynamicCastToClass:[CHTableView class]];
  if (tableView == self->basePrefixesSuffixesDetailTableView)
  {
    NSDictionary* dict = [viewController.representedObject dynamicCastToClass:[NSDictionary class]];
    NSNumber* rowIndex = [[dict objectForKey:@"rowIndex"] dynamicCastToClass:[NSNumber class]];
    NSString* identifier = [[dict objectForKey:@"identifier"] dynamicCastToClass:[NSString class]];
    if (rowIndex && identifier)
    {
      NSArray* components =
        [[tableView.arrayController valueForKeyPath:@"arrangedObjects.string"] arrayByRemovingDuplicates];
      NSArrayController* basePrefixesSuffixesArrayController =
        [[CHPreferencesController sharedPreferencesController] basePrefixesSuffixesController];
      NSMutableDictionary* basePrefixSuffix = [[[basePrefixesSuffixesArrayController.arrangedObjects objectAtIndex:rowIndex.unsignedIntegerValue] mutableCopy] autorelease];
      NSMutableArray* mutableArray = [[basePrefixesSuffixesArrayController.arrangedObjects mutableCopy] autorelease];
      [basePrefixSuffix setValue:components forKey:identifier];
      [mutableArray replaceObjectAtIndex:rowIndex.unsignedIntegerValue withObject:basePrefixSuffix];
      basePrefixesSuffixesArrayController.content = mutableArray;
    }//end if (rowIndex)
  }//end if (tableView == self->basePrefixesSuffixesDetailTableView)
}
//end popoverDidClose:

-(void) applicationWillTerminate:(NSNotification*)aNotification
{
  [[self window] makeFirstResponder:nil];//commit editing
}
//end applicationWillTerminate:

-(IBAction) updatesCheckNow:(id)sender
{
  [(CHAppDelegate*)[NSApp delegate] checkUpdates:self];
}
//end updatesCheckNow:

-(IBAction) updatesVisitWebSite:(id)sender
{
  [(CHAppDelegate*)[NSApp delegate] openWebSite:self];
}
//end updatesGotoWebSite:

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change
                       context:(void*)context
{
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  if ([keyPath endsWith:CHSoftIntegerMaxBitsKey options:0] ||
      [keyPath endsWith:CHSoftIntegerMaxBitsDigitsBaseKey options:0])
  {
    NSUInteger softIntegerMaxBitsDigitsInBase =
      chalkGmpGetMaximumDigitsCountFromBitsCount(preferencesController.softIntegerMaxBits, preferencesController.softIntegerMaxBitsDigitsBase);
    self->softIntegerMaxBitsDigitsInBaseTextField.objectValue =
      @(softIntegerMaxBitsDigitsInBase);
    NSNumber* softIntegerMaxBits = @(preferencesController.softIntegerMaxBits);
    [self->softIntegerMaxBitsTextField setStringValue:[softIntegerMaxBits stringValue]];
  }//end if ([keyPath endsWith:CHSoftIntegerMaxBits options:0] && [keyPath endsWith:CHSoftIntegerMaxBitsDigitsBase options:0])
  else if ([keyPath endsWith:CHSoftIntegerDenominatorMaxBitsKey options:0] ||
           [keyPath endsWith:CHSoftIntegerDenominatorMaxBitsDigitsBaseKey options:0])
  {
    NSUInteger softIntegerDenominatorMaxBitsDigitsInBase =
      chalkGmpGetMaximumDigitsCountFromBitsCount(preferencesController.softIntegerDenominatorMaxBits, preferencesController.softIntegerDenominatorMaxBitsDigitsBase);
    self->softIntegerDenominatorMaxBitsDigitsInBaseTextField.objectValue =
      @(softIntegerDenominatorMaxBitsDigitsInBase);
  }//end if ([keyPath endsWith:CHSoftIntegerDenominatorMaxBits options:0] && [keyPath endsWith:CHSoftIntegerDenominatorMaxBitsDigitsBase options:0])
  else if ([keyPath endsWith:CHSoftFloatSignificandBitsKey options:0] ||
           [keyPath endsWith:CHSoftFloatSignificandBitsDigitsBaseKey options:0])
  {
    NSUInteger softFloatSignificandBitsDigitsInBase =
      chalkGmpGetMaximumDigitsCountFromBitsCount(preferencesController.softFloatSignificandBits, preferencesController.softFloatSignificandBitsDigitsBase);
    self->softFloatSignificandBitsDigitsInBaseTextField.objectValue =
      @(softFloatSignificandBitsDigitsInBase);

    preferencesController.softFloatDisplayBits = MIN(preferencesController.softFloatDisplayBits, preferencesController.softFloatSignificandBits);
  }//end if ([keyPath endsWith:CHSoftFloatSignificandBits options:0] && [keyPath endsWith:CHSoftFloatSignificandBitsDigitsBase options:0])
  else if ([keyPath endsWith:CHSoftFloatDisplayBitsKey options:0] ||
           [keyPath endsWith:CHSoftFloatDisplayBitsDigitsBaseKey options:0])
  {
    NSUInteger softFloatDisplayBitsDigitsInBase =
      chalkGmpGetMaximumDigitsCountFromBitsCount(preferencesController.softFloatDisplayBits, preferencesController.softFloatDisplayBitsDigitsBase);
    self->softFloatDisplayBitsDigitsInBaseTextField.objectValue =
      @(softFloatDisplayBitsDigitsInBase);
  }//end if ([keyPath endsWith:CHSoftFloatDisplayBits options:0] && [keyPath endsWith:CHSoftFloatDisplayBitsDigitsBase options:0])
  else if ([keyPath endsWith:CHBasePrefixesSuffixesKey options:0])
  {
    [self->basesConflictingForPrefixes removeAllIndexes];
    [self->basesConflictingForSuffixes removeAllIndexes];
    NSArray* prefixesSuffixes = preferencesController.basePrefixesSuffixes;
    NSMutableArray* prefixesSuffixesSets = [NSMutableArray array];
    for(NSUInteger i = 0, count = prefixesSuffixes.count ; i<count ; ++i)
    {
      NSDictionary* dict = [[prefixesSuffixes objectAtIndex:i] dynamicCastToClass:[NSDictionary class]];
      NSNumber* base = [[dict objectForKey:CHBaseBaseKey] dynamicCastToClass:[NSNumber class]];
      NSArray* prefixes = [[dict objectForKey:CHBasePrefixesKey] dynamicCastToClass:[NSArray class]];
      NSArray* suffixes = [[dict objectForKey:CHBaseSuffixesKey] dynamicCastToClass:[NSArray class]];
      NSSet* prefixesSet = !prefixes ? [NSSet set] : [NSSet setWithArray:prefixes];
      NSSet* suffixesSet = !suffixes ? [NSSet set] : [NSSet setWithArray:suffixes];
      if (base)
        [prefixesSuffixesSets addObject:@{CHBaseBaseKey:base, CHBasePrefixesKey:prefixesSet, CHBaseSuffixesKey:suffixesSet}];
    }//end for each basePrefixSuffix
    for(NSUInteger i = 0, count = prefixesSuffixesSets.count ; i+1<count ; ++i)
    {
      NSDictionary* dict1 = [[prefixesSuffixesSets objectAtIndex:i] dynamicCastToClass:[NSDictionary class]];
      NSNumber* base1 = [[dict1 objectForKey:CHBaseBaseKey] dynamicCastToClass:[NSNumber class]];
      NSSet* prefixesSet1 = [[dict1 objectForKey:CHBasePrefixesKey] dynamicCastToClass:[NSSet class]];
      NSSet* suffixesSet1 = [[dict1 objectForKey:CHBaseSuffixesKey] dynamicCastToClass:[NSSet class]];
      for(NSUInteger j = !base1 ? count : i+1 ; j<count ; ++j)
      {
        NSDictionary* dict2 = [[prefixesSuffixesSets objectAtIndex:j] dynamicCastToClass:[NSDictionary class]];
        NSNumber* base2 = [[dict2 objectForKey:CHBaseBaseKey] dynamicCastToClass:[NSNumber class]];
        NSSet* prefixesSet2 = [[dict2 objectForKey:CHBasePrefixesKey] dynamicCastToClass:[NSSet class]];
        NSSet* suffixesSet2 = [[dict2 objectForKey:CHBaseSuffixesKey] dynamicCastToClass:[NSSet class]];
        if (base2 && prefixesSet2 && suffixesSet2)
        {
          if ([prefixesSet1 intersectsSet:prefixesSet2])
          {
            [self->basesConflictingForPrefixes addIndex:base1.unsignedIntegerValue];
            [self->basesConflictingForPrefixes addIndex:base2.unsignedIntegerValue];
          }//end if ([prefixesSet1 intersectsSet:prefixesSet2])
          if ([suffixesSet1 intersectsSet:suffixesSet2])
          {
            [self->basesConflictingForSuffixes addIndex:base1.unsignedIntegerValue];
            [self->basesConflictingForSuffixes addIndex:base2.unsignedIntegerValue];
          }//end if ([suffixesSet1 suffixesSet2])
        }//end if (base2 && prefixesSet2 && suffixesSet2)
      }//end for each prefixesSuffixesSet
    }//end for each prefixesSuffixesSet
  }//end if ([keyPath endsWith:CHBasePrefixesSuffixesKey options:0])
}
//end observeValueForKeyPath:ofObject:change:context:

#pragma mark NSTableView delegate

-(void) tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
  if (tableView == self->basePrefixesSuffixesTableView)
  {
    CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
    if ([tableColumn.identifier isEqualToString:CHBasePrefixesKey] ||
        [tableColumn.identifier isEqualToString:CHBaseSuffixesKey])
    {
      NSDictionary* dict =
        [[preferencesController.basePrefixesSuffixesController.arrangedObjects objectAtIndex:row] dynamicCastToClass:[NSDictionary class]];
      NSNumber* base = [[dict objectForKey:CHBaseBaseKey] dynamicCastToClass:[NSNumber class]];
      NSIndexSet* baseConflictsSet =
        [tableColumn.identifier isEqualToString:CHBasePrefixesKey] ? self->basesConflictingForPrefixes :
        [tableColumn.identifier isEqualToString:CHBaseSuffixesKey] ? self->basesConflictingForSuffixes :
        nil;
      BOOL conflict = [baseConflictsSet containsIndex:base.unsignedIntegerValue];
      NSTextFieldCell* textFieldCell = [cell dynamicCastToClass:[NSTextFieldCell class]];
      textFieldCell.backgroundColor = conflict ? [NSColor colorWithCalibratedRed:253/255. green:177/255. blue:179/255. alpha:1.] : [NSColor clearColor];
      textFieldCell.drawsBackground = conflict;
    }//end if (CHBasePrefixesKey || CHBaseSuffixesKey)
  }//end if (tableView == self->basePrefixesSuffixesTableView)
}
//end tableView:willDisplayCell:forTableColumn:row:


@end
