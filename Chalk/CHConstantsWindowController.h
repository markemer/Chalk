//  CHPreferencesWindowController.h
// Chalk
//
//  Created by Pierre Chatelier on 1/04/05.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.

//The preferences controller centralizes the management of the preferences pane

#import <Cocoa/Cocoa.h>

#import "CHConstantsProvider.h"
#import "CHConstantSymbolManager.h"

@class CHConstantsProviderManager;

@interface CHConstantsWindowController : NSWindowController <NSWindowDelegate,NSTableViewDelegate,NSTableViewDataSource,CHConstantSymbolManagerDelegate> {
  IBOutlet NSComboBox*  constantsProvidersComboBox;
  IBOutlet NSButton*    constantsProvidersLoadButton;
  IBOutlet NSTextField* constantsProviderInfoTextField;
  IBOutlet NSTableView* constantsTableView;
  IBOutlet NSTextField* constantRichDescriptionTextField;
  IBOutlet NSButton*    constantsAddToCurrentCalculatorDocumentButton;
  CHConstantsProviderManager* constantsProviderManager;
  NSArrayController* constantsProvidersArrayController;
  NSArrayController* constantsArrayController;
  CHConstantSymbolManager* constantSymbolManager;
  int32_t reloadDataLevel;
}

-(IBAction) constantsProviderLoad:(id)sender;
-(IBAction) constantsProviderChanged:(id)sender;
-(IBAction) constantsSearchFieldChanged:(id)sender;
-(IBAction) constantsAddToCurrentCalculatorDocument:(id)sender;
-(IBAction) doubleClick:(id)sender;

@end
