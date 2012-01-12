//
//  DataMapper.m
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "DataMapper.h"

@implementation DataInfo

@synthesize updateTime = _updateTime;
@synthesize expireAfter = _expireAfter;
@synthesize data = _data;
@synthesize key = _key;
@synthesize params = _params;

+ (id)dataInfoWithDictionary:(NSDictionary *)dictionary{
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    [info loadDictionary:dictionary];
    return info;
}

- (id)init{
    if ([super init]) {
        [self clean];
    }
    return self;
}

- (NSMutableDictionary*)dictionaryValue{
    NSMutableDictionary* ret = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithDouble:_updateTime],@"updateTime",
                                [NSNumber numberWithDouble:_expireAfter],@"expireAfter",
                                _data,@"data",
                                _key,@"key",
                                _params,@"params",
                                nil];
    return ret;
}

- (void)loadDictionary:(NSDictionary*)dict{
    self.updateTime = [[dict objectForKey:@"updateTime"] doubleValue];
    self.expireAfter = [[dict objectForKey:@"expireAfter"] doubleValue];
    self.data = [dict objectForKey:@"data"];
    self.params = [dict objectForKey:@"params"];
    self.key = [dict objectForKey:@"key"];
}

- (void)clean{
    self.updateTime = -1;
    self.expireAfter = -1;
    self.data = nil;
    self.params = nil;
    self.key = nil;
}

- (BOOL)expired{
    if (_expireAfter <= 0) {
        return NO;
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (_expireAfter + _updateTime <= now) {
        return YES;
    }
    return NO;
}

@end

@implementation DataOption

@synthesize setExpireAfter = _setExpireAfter;
@synthesize expireAfter = _expireAfter;
@synthesize autoFetch = _autoFetch;
@synthesize needsCache = _needsCache;
@synthesize cacheType = _cacheType;

- (id)init{
    if ([super init]) {
        [self clean];
    }
    return self;
}

- (void)clean{
    self.setExpireAfter = NO;
    self.expireAfter = -1;
    self.autoFetch = NO;
    self.needsCache = YES;
    self.cacheType = CACHE_DISK;
}

+ (id)optionFromOption:(DataOption *)option{
    DataOption* ret = [[[DataOption alloc] init] autorelease];
    if (!option) {
        return ret;
    }
    ret.setExpireAfter = option.setExpireAfter;
    ret.expireAfter = option.expireAfter;
    ret.autoFetch = option.autoFetch;
    ret.needsCache = option.needsCache;
    ret.cacheType = option.cacheType;
    return ret;
}

@end

@implementation DataMapper

@synthesize key = _key;
@synthesize options = _options;
@synthesize autoList = _autoList;
@synthesize delegate = _delegate;
@synthesize decoder = _decoder;
@synthesize defaultOption = _defaultOption;

- (id)initWithKey:(NSString*)key{
    self = [super init];
    if (self) {
        self.key = key;
        self.options = [NSMutableDictionary dictionaryWithCapacity:10];
        self.autoList = [NSMutableDictionary dictionaryWithCapacity:10];
        self.decoder = NULL;
    }
    return self;
}

- (void)setDecoder:(DataDecoder)decoder{
    if (!decoder) {
        decoder = ^(id data){return data;};
    }
    [_decoder autorelease];
    _decoder = [decoder copy];
}


- (void)addOption:(DataOption *)option forParams:(NSDictionary *)params{
    NSString* keyPath = [self keyPathForParams:[DataMapper normalParams:params]];
    if (option.autoFetch) {
        [_autoList setObject:params forKey:keyPath];
    }else{
        [_autoList removeObjectForKey:keyPath];
    }
    [_options setObject:option forKey:keyPath];
    [_delegate mapperStateChanged:self params:params];
}

- (void)removeOption:(DataOption *)option forParams:(NSDictionary *)params{
    NSString* keyPath = [self keyPathForParams:[DataMapper normalParams:params]];
    [_autoList removeObjectForKey:keyPath];
    [_delegate mapperStateChanged:self params:params];
}

- (DataOption*)option:(NSDictionary *)params{
    NSString* keyPath = [self keyPathForParams:[DataMapper normalParams:params]];
    DataOption* ret = [_options objectForKey:keyPath];
    if (!ret) {
        ret = self.defaultOption;
    }
    return ret;
}

- (NSString*)keyPathForParams:(NSDictionary *)params{
    NSDictionary* normalParams = [DataMapper normalParams:params];
    NSString* ret = @"__";
    for (NSString* key in normalParams) {
        ret = [ret stringByAppendingFormat:@"%@|%@_",key,[normalParams objectForKey:key]];
    }
    return ret;
}

- (DataInfo*)getValue:(NSDictionary*)params{
    return nil;
}

- (void)getValue:(NSDictionary *)params handler:(DataHandler)handler{
    [self _getValue:params handler:^(DataInfo* info,NSError* error){
        DataOption* option = [self option:params];
        if (option) {
            if (option.setExpireAfter) {
                info.expireAfter = option.expireAfter;
            }
        }
        if (handler) {
            handler(info,error);
        }
    }];
}

- (void)_getValue:(NSDictionary *)params handler:(DataHandler)handler{
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = _key;
    info.params = params;
    NSError* error = [[NSError alloc] initWithDomain:@"DataMapper" code:DATA_ERROR_NOTIMPLEMENT userInfo:nil];
    [error autorelease];
    if (handler) {
        handler(info,error);
    }
}

- (void)updateValue:(id)params value:(id)value handler:(DataHandler)handler{
    [self _updateValue:params value:value handler:^(DataInfo* info,NSError* error){
        if (handler) {
            handler(info,error);
        }
    }];
}

- (void)_updateValue:(NSDictionary*)params value:(id)value handler:(DataHandler)handler{
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = _key;
    info.params = params;
    NSError* error = [[NSError alloc] initWithDomain:@"DataMapper" code:DATA_ERROR_NOTIMPLEMENT userInfo:nil];
    [error autorelease];
    if (handler) {
        handler(info,error);
    }
}

+ (NSDictionary*)normalParams:(NSDictionary *)params{
    NSMutableDictionary* ret = [NSMutableDictionary dictionaryWithCapacity:10];
    for (NSString* key in params) {
        NSString* head = [key substringToIndex:1];
        if (![head isEqualToString:@"_"]) {
            [ret setObject:[params objectForKey:key] forKey:key];
        }
    }
    return ret;
}

+ (NSDictionary*)hiddenParams:(NSDictionary *)params{
    NSMutableDictionary* ret = [NSMutableDictionary dictionaryWithCapacity:10];
    for (NSString* key in params) {
        NSString* head = [key substringToIndex:1];
        if ([head isEqualToString:@"_"]) {
            [ret setObject:[params objectForKey:key] forKey:[key substringFromIndex:1]];
        }
    }
    return ret;
}

- (DataOption*)defaultOption{
    DataOption* ret = [DataOption optionFromOption:_defaultOption];
    return ret;
}



- (void)dealloc{
    [_key release];
    [_options release];
    [_decoder release];
    [_defaultOption release];
    [super dealloc];
}

@end
