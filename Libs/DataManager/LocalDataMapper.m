//
//  LocalDataMapper.m
//  RemoteControl
//
//  Created by wang  chao on 12-1-6.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "LocalDataMapper.h"
#import "LocalStorage.h"

static NSString* _head = @"__local_store__";

@implementation LocalDataMapper

- (NSString*)keyPathForLocalStore:(NSDictionary*)params{
    NSString* localKeyPath = [self keyPathForParams:params];
    localKeyPath = [_head stringByAppendingFormat:@"%@_%@",self.key,localKeyPath];
    return localKeyPath;
}

#pragma mark - override

- (id)initWithKey:(NSString *)key{
    if ([super initWithKey:key]) {
        DataOption* option = [[[DataOption alloc] init] autorelease];
        option.needsCache = NO;
        self.defaultOption = option;
    }
    return self;
}

- (void)_getValue:(NSDictionary *)params handler:(DataHandler)handler{
    NSString* keyPath = [self keyPathForLocalStore:params];
    LocalStorage* localStorage = [LocalStorage instance];
    id data = [localStorage getValue:keyPath];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = self.key;
    info.params = params;
    info.updateTime = [[NSDate date] timeIntervalSince1970];
    info.data = data;
    handler(info,nil);
}

- (DataInfo*)getValue:(NSDictionary *)params{
    NSString* keyPath = [self keyPathForLocalStore:params];
    LocalStorage* localStorage = [LocalStorage instance];
    id data = [localStorage getValue:keyPath];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = self.key;
    info.params = params;
    info.updateTime = [[NSDate date] timeIntervalSince1970];
    info.data = data;
    return info;
}

- (void)_updateValue:(NSDictionary *)params value:(id)value handler:(DataHandler)handler{
    NSString* keyPath = [self keyPathForLocalStore:params];
    LocalStorage* localStorage = [LocalStorage instance];
    [localStorage store:value forKey:keyPath];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = self.key;
    info.params = params;
    info.updateTime = [[NSDate date] timeIntervalSince1970];
    info.data = value;
    handler(info,nil);
}

- (void)clean{
    LocalStorage* localStorage = [LocalStorage instance];
    [localStorage cleanPrefix:_head];
}

@end
