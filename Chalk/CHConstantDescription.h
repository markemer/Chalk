//
//  CHConstantDescription.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHUnit;

@interface CHConstantDescription : NSObject {
  NSString* uid;
  NSString* name;
  NSString* shortName;
  NSString* value;
  NSString* uncertainty;
  NSString* description;
  NSString* texSymbol;
  NSArray<NSString*>* categories;
  NSArray<CHUnit*>* commonUnits;
  NSArray<NSAttributedString*>* commonUnitsRichDescriptions_cached;
}

@property(nonatomic, readonly, copy) NSString* uid;
@property(nonatomic, readonly, copy) NSString* name;
@property(nonatomic, readonly, copy) NSString* shortName;
@property(nonatomic, readonly, copy) NSString* value;
@property(nonatomic, readonly, copy) NSString* uncertainty;
@property(nonatomic, readonly, copy) NSString* description;
@property(nonatomic, readonly, copy) NSString* texSymbol;
@property(nonatomic, readonly, copy) NSArray<NSString*>* categories;
@property(nonatomic, readonly, copy) NSArray<CHUnit*>* commonUnits;
@property(nonatomic, readonly, copy) NSArray<NSAttributedString*>* commonUnitsRichDescriptions;

-(instancetype) initWithUid:(NSString*)aUid plist:(id)plist;
-(instancetype) initWithPlistValueDescription:(id)plist;

-(NSString*) stringValueDescription;
-(id) plistValueDescription;

@end

NS_ASSUME_NONNULL_END
