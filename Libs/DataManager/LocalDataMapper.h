//
//  LocalDataMapper.h
//  RemoteControl
//
//  Created by wang  chao on 12-1-6.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "DataMapper.h"

@interface LocalDataMapper : DataMapper

- (NSString*)keyPathForLocalStore:(NSDictionary*)params;
- (void)clean;

@end
