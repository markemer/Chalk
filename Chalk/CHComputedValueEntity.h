//
//  CHComputedValueEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 12/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

@class CHChalkValue;

@interface CHComputedValueEntity : NSManagedObject {
  CHChalkValue* chalkValue;
}

+(NSString*) entityName;

@property(nonatomic,retain) NSData* data;
@property(nonatomic,retain) CHChalkValue* chalkValue;

@end
