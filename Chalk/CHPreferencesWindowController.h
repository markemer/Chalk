//  CHPreferencesWindowController.h
// Chalk
//
//  Created by Pierre Chatelier on 1/04/05.
//  Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011 Pierre Chatelier. All rights reserved.

//The preferences controller centralizes the management of the preferences pane

#import <Cocoa/Cocoa.h>

#import "CHPreferencesController.h"

extern NSString* GeneralToolbarItemIdentifier;
extern NSString* WebToolbarItemIdentifier;

@class CHStepperNumber;
@class CHTableView;

@interface CHPreferencesWindowController : NSWindowController <NSPopoverDelegate, NSTableViewDelegate, NSToolbarDelegate, NSWindowDelegate> {
  IBOutlet NSView*        generalView;
  IBOutlet NSView*        editionView;
  IBOutlet NSView*        webView;
  NSView*                 emptyView;
  NSMutableDictionary*    toolbarItems;
  NSMutableDictionary*    viewsMinSizes;
  
  //
  IBOutlet NSNumberFormatter* baseFormatter;
  
  //general view
  IBOutlet NSBox*       computationLimitsBox;
  IBOutlet NSTextField* softIntegerMaxBitsLabel;
  IBOutlet NSNumberFormatter* softIntegerMaxBitsNumberFormatter;
  IBOutlet NSTextField* softIntegerMaxBitsTextField;
  IBOutlet CHStepperNumber* softIntegerMaxBitsStepper;
  IBOutlet NSTextField* softIntegerMaxBitsDigitsInBaseLabel;
  IBOutlet NSTextField* softIntegerMaxBitsDigitsInBaseBaseTextField;
  IBOutlet NSStepper*   softIntegerMaxBitsDigitsInBaseBaseStepper;
  IBOutlet NSTextField* softIntegerMaxBitsDigitsInBaseTextField;
  IBOutlet NSButton*    softIntegerMaxBitsDigitsMinButton;
  IBOutlet NSButton*    softIntegerMaxBitsDigitsMaxButton;

  IBOutlet NSTextField* softIntegerDenominatorMaxBitsLabel;
  IBOutlet NSNumberFormatter* softIntegerDenominatorMaxBitsNumberFormatter;
  IBOutlet NSTextField* softIntegerDenominatorMaxBitsTextField;
  IBOutlet CHStepperNumber*   softIntegerDenominatorMaxBitsStepper;
  IBOutlet NSTextField* softIntegerDenominatorMaxBitsDigitsInBaseLabel;
  IBOutlet NSTextField* softIntegerDenominatorMaxBitsDigitsInBaseBaseTextField;
  IBOutlet NSStepper*   softIntegerDenominatorMaxBitsDigitsInBaseBaseStepper;
  IBOutlet NSTextField* softIntegerDenominatorMaxBitsDigitsInBaseTextField;
  IBOutlet NSButton*    softIntegerDenominatorMaxBitsDigitsMinButton;
  IBOutlet NSButton*    softIntegerDenominatorMaxBitsDigitsMaxButton;

  IBOutlet NSTextField* softFloatSignificandBitsLabel;
  IBOutlet NSNumberFormatter* softFloatSignificandBitsNumberFormatter;
  IBOutlet NSTextField* softFloatSignificandBitsTextField;
  IBOutlet CHStepperNumber*   softFloatSignificandBitsStepper;
  IBOutlet NSTextField* softFloatSignificandBitsDigitsInBaseLabel;
  IBOutlet NSTextField* softFloatSignificandBitsDigitsInBaseBaseTextField;
  IBOutlet NSStepper*   softFloatSignificandBitsDigitsInBaseBaseStepper;
  IBOutlet NSTextField* softFloatSignificandBitsDigitsInBaseTextField;
  IBOutlet NSButton*    softFloatSignificandBitsDigitsMinButton;
  IBOutlet NSButton*    softFloatSignificandBitsDigitsMaxButton;

  IBOutlet NSTextField* softFloatDisplayBitsLabel;
  IBOutlet NSNumberFormatter* softFloatDisplayBitsNumberFormatter;
  IBOutlet NSTextField* softFloatDisplayBitsTextField;
  IBOutlet CHStepperNumber*   softFloatDisplayBitsStepper;
  IBOutlet NSTextField* softFloatDisplayBitsDigitsInBaseLabel;
  IBOutlet NSTextField* softFloatDisplayBitsDigitsInBaseBaseTextField;
  IBOutlet NSStepper*   softFloatDisplayBitsDigitsInBaseBaseStepper;
  IBOutlet NSTextField* softFloatDisplayBitsDigitsInBaseTextField;
  IBOutlet NSButton*    softFloatDisplayBitsDigitsMinButton;
  IBOutlet NSButton*    softFloatDisplayBitsDigitsMaxButton;

  IBOutlet NSButton* computationLimitsDefaultsButton;

  IBOutlet NSBox*    computationBehaviourBox;
  IBOutlet NSButton* raiseErrorOnNaNCheckBox;
  
  //edition view
  IBOutlet NSBox*         parsingAndInterpretationBox;
  IBOutlet NSTextField*   parseModeLabel;
  IBOutlet NSPopUpButton* parseModePopUpButton;
  IBOutlet NSButton*      baseUseLowercaseCheckBox;
  IBOutlet NSButton*      baseUseDecimalExponentCheckBox;
  IBOutlet CHTableView*   basePrefixesSuffixesTableView;
  IBOutlet NSView*        basePrefixesSuffixesDetailView;
  IBOutlet CHTableView*   basePrefixesSuffixesDetailTableView;
  IBOutlet NSButton*      basePrefixesSuffixesDetailAddButton;
  IBOutlet NSButton*      basePrefixesSuffixesDetailRemoveButton;
  IBOutlet NSTextField*   nextInputModeLabel;
  IBOutlet NSPopUpButton* nextInputModePopUpButton;
  IBOutlet NSButton*      parsingAndInterpretationDefaultsButton;
  
  IBOutlet NSBox*         bitInspectorBox;
  IBOutlet NSColorWell*   bitInterpretationSignColorColorWell;
  IBOutlet NSTextField*   bitInterpretationSignColorLabel;
  IBOutlet NSColorWell*   bitInterpretationExponentColorColorWell;
  IBOutlet NSTextField*   bitInterpretationExponentColorLabel;
  IBOutlet NSColorWell*   bitInterpretationSignificandColorColorWell;
  IBOutlet NSTextField*   bitInterpretationSignificandColorLabel;
  IBOutlet NSButton*      bitInterpretationColorsDefaultsButton;

  //web view
  IBOutlet NSButton* updatesCheckUpdatesButton;
  IBOutlet NSButton* updatesCheckUpdatesNowButton;
  IBOutlet NSButton* updatesVisitWebSiteButton;
  
  NSMutableIndexSet* basesConflictingForPrefixes;
  NSMutableIndexSet* basesConflictingForSuffixes;
}

-(IBAction) toolbarHit:(id)sender;

-(IBAction) doubleAction:(id)sender;

-(IBAction) updatesCheckNow:(id)sender;
-(IBAction) updatesVisitWebSite:(id)sender;

-(void) selectPreferencesPaneWithItemIdentifier:(NSString*)itemIdentifier options:(id)options;

@end
