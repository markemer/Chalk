//
//  CHUnitElementDescription.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <gmp.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHUnitElementDescription : NSObject {
  NSString* uid;
  NSString* name;
  mpq_t power;
}

@property(nonatomic,readonly,copy) NSString* uid;
@property(nonatomic,readonly,copy) NSString* name;
@property(nonatomic,readonly)      mpq_srcptr power;
@property(nonatomic,readonly)      BOOL isValid;

-(instancetype) initWithPlist:(id)plist;
-(void) addPower:(mpq_srcptr)otherPower;

@end

NS_ASSUME_NONNULL_END
