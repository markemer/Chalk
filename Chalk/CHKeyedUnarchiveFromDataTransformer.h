//
//  CHKeyedUnarchiveFromDataTransformer.h
//  Chalk
//
//  Created by Pierre Chatelier on 24/04/09.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CHKeyedUnarchiveFromDataTransformer : NSValueTransformer {
}

+(NSString*) name;
+(id) transformer;

@end
