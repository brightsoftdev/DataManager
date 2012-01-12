//
//  BlockDataMapper.m
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "BlockDataMapper.h"

@implementation BlockDataMapper

@synthesize getter = _getter;


- (id)initWithKey:(NSString *)key getter:(BlockDataGetter)getter{
    if ([super initWithKey:key]) {
        self.getter = getter;
    }
    return self;
}

- (void)setGetter:(BlockDataGetter)getter{
    if (!getter) {
        getter = ^(DataMapper* mapper,NSDictionary* params){
            DataInfo* info = [[[DataInfo alloc] init] autorelease];
            info.key = mapper.key;
            info.params = params;
            return info;
        };
    }
    [_getter autorelease];
    _getter = [getter copy];
}

- (void)_getValue:(NSDictionary *)params handler:(DataHandler)handler{
    dispatch_async(dispatch_queue_create(NULL, NULL), ^{
        DataInfo* info = _getter(self,params);
        dispatch_sync(dispatch_get_main_queue(), ^{
            info.key = _key;
            info.params = params;
            info.updateTime = [[NSDate date] timeIntervalSince1970];
            if (handler) {
                handler(info,nil);
            }
        });
    });
}

- (void)dealloc{
    [_getter release];
    [super dealloc];
}

@end
