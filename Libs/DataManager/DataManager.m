//
//  DataManager.m
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "DataManager.h"
#import "LocalStorage.h"

static NSString* _head = @"_datamanager_";

#define MIN_DATA_FETCH_TIME 5.0

static DataManager* _manager;

@interface DataManager (Private)

- (NSString*)_keyPath:(DataMapper*)mapper params:(NSDictionary*)params;
- (NSString*)_keyHead:(NSString*)key;
- (void)_upToTime;

@end

@implementation DataManager (Private)

- (NSString*)_keyHead:(NSString *)key{
    return [_head stringByAppendingFormat:@"_%@",key];
}

- (NSString*)_keyPath:(DataMapper *)mapper params:(NSDictionary *)params{
    NSString* key = mapper.key;
    return [NSString stringWithFormat:@"%@_%@",[self _keyHead:key],[mapper keyPathForParams:[DataMapper normalParams:params]]];
}

- (void)_upToTime{
    for (NSString* infoKey in _autoList) {
        DataInfo* info = [_autoList objectForKey:infoKey];
        if ([info expired]) {
            [self getValue:info.key params:info.params handler:nil useCache:NO];
        }
    }
}

@end

@implementation DataManager

@synthesize mappers = _mappers;
@synthesize timer = _timer;
@synthesize autoList = _autoList;

#pragma mark - construct methods

- (id)init
{
    self = [super init];
    if (self) {
        self.mappers = [NSMutableDictionary dictionaryWithCapacity:100];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:MIN_DATA_FETCH_TIME/2.0 target:self selector:@selector(_upToTime) userInfo:nil repeats:YES];
        self.autoList = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    
    return self;
}

+ (id)manager{
    if (!_manager) {
        _manager = [[self alloc] init];
    }
    return _manager;
}

#pragma mark - DataMapperDelegate

- (void)mapperStateChanged:(DataMapper *)mapper params:(NSDictionary *)params{
    DataOption* option = [mapper option:params];
    if (!option.needsCache) {
        LocalStorage* localStorage = [LocalStorage instance];
        StoreType storeType = DISK;
        if (option.cacheType == CACHE_MEM) {
            storeType = MEM;
        }
        [localStorage delete:[self _keyPath:mapper params:params] storeType:storeType];
    }
    [self refershAutoList];
}

#pragma mark -

- (void)refershAutoList{
    [self.autoList removeAllObjects];
    LocalStorage* localStorage = [LocalStorage instance];
    for (NSString* key in _mappers) {
        DataMapper* mapper = [_mappers objectForKey:key];
        for (NSString* pkey in mapper.autoList) {
            NSDictionary* params = [mapper.autoList objectForKey:pkey];
            NSString* keyPath = [self _keyPath:mapper params:params];
            DataOption* option = [mapper option:params];
            StoreType storeType = DISK;
            if (option.cacheType == CACHE_MEM) {
                storeType = MEM;
            }
            NSDictionary* dict = [localStorage getValue:keyPath storeType:storeType];
            DataInfo* info = [[[DataInfo alloc] init] autorelease];
            if (dict) {
                DataInfo* storeData = [DataInfo dataInfoWithDictionary:dict];
                info.updateTime = storeData.updateTime;
                info.expireAfter = storeData.expireAfter > MIN_DATA_FETCH_TIME?storeData.expireAfter:MIN_DATA_FETCH_TIME;
            }
            info.key = mapper.key;
            info.params = params;
            [_autoList setObject:info forKey:keyPath];
        }
    }
}

- (void)addMapper:(DataMapper *)mapper{
    if (!mapper.key) {
        return;
    }
    [_mappers setObject:mapper forKey:mapper.key];
    mapper.delegate = self;
    [self refershAutoList];
}

- (void)getValue:(NSString *)key params:(NSDictionary *)params handler:(DataHandler)handler useCache:(BOOL)useCache{
    DataMapper* mapper = [_mappers objectForKey:key];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = key;
    info.params = params;
    
    if (!mapper) {
        NSError* error = [NSError errorWithDomain:@"DataManager" code:DATA_ERROR_NOMAPPER userInfo:nil];
        if (handler) {
            handler(info,error);
        }
        return;
    }
    
    LocalStorage* localStorage = [LocalStorage instance];
    NSString* keyPath = [self _keyPath:mapper params:params];
    DataOption* option =  [mapper option:params];
    StoreType storeType = DISK;
    if (option.cacheType == CACHE_MEM) {
        storeType = MEM;
    }


    if (useCache && option.needsCache) {
        NSDictionary* infoDict = [localStorage getValue:keyPath storeType:storeType];
        if (infoDict) {
            DataInfo* dataInfo = [DataInfo dataInfoWithDictionary:infoDict];
            if (![dataInfo expired]) {
                if (handler) {
                    dataInfo.data = mapper.decoder(dataInfo.data);
                    dataInfo.key = info.key;
                    dataInfo.params = info.params;
                    handler(dataInfo,nil);
                }
                return;
            }
        }
    }

    
    [mapper getValue:params handler:^(DataInfo* dataInfo,NSError* error){
        dataInfo.key = info.key;
        dataInfo.params = info.params;
        NSString* keyPath = [self _keyPath:mapper params:params];
        if (!error) {
            if (option.needsCache) {
                [localStorage store:[dataInfo dictionaryValue] forKey:keyPath storeType:storeType];
            }
            DataInfo* autoInfo = [_autoList objectForKey:keyPath];
            if (autoInfo) {
                autoInfo.updateTime = [[NSDate date] timeIntervalSince1970];
                autoInfo.expireAfter = (dataInfo.expireAfter > MIN_DATA_FETCH_TIME)?dataInfo.expireAfter:MIN_DATA_FETCH_TIME;
            }
        }
        if (handler) {
            dataInfo.data = mapper.decoder(dataInfo.data);
            handler(dataInfo,error);
        }
    }];
}

- (void)getValue:(NSString*)key params:(NSDictionary*)params handler:(DataHandler)handler{
    [self getValue:key params:params handler:handler useCache:YES];
}

- (DataInfo*)getValue:(NSString*)key params:(NSDictionary*)params{
    DataMapper* mapper = [_mappers objectForKey:key];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = key;
    info.params = params;
    
    if (!mapper) {
        return nil;
    }
    
    LocalStorage* localStorage = [LocalStorage instance];
    NSString* keyPath = [self _keyPath:mapper params:params];
    DataOption* option =  [mapper option:params];
    StoreType storeType = DISK;
    if (option.cacheType == CACHE_MEM) {
        storeType = MEM;
    }
    DataInfo* ret = [[[DataInfo alloc] init] autorelease];
    if (option.needsCache) {
        NSDictionary* infoDict = [localStorage getValue:keyPath storeType:storeType];
        if (infoDict) {
            DataInfo* dataInfo = [DataInfo dataInfoWithDictionary:infoDict];
            if (![dataInfo expired]) {
                dataInfo.data = mapper.decoder(dataInfo.data);
                if (dataInfo.data) {
                    ret = dataInfo;
                    ret.key = info.key;
                    ret.params = info.params;
                }
            }
        }
    }
    
    if (!ret.data) {
        NSDictionary* infoDict = [[mapper getValue:params] dictionaryValue];
        if (infoDict) {
            DataInfo* dataInfo = [DataInfo dataInfoWithDictionary:infoDict];
            if (![dataInfo expired]) {
                dataInfo.data = mapper.decoder(dataInfo.data);
                if (dataInfo.data) {
                    ret = dataInfo;
                    ret.key = info.key;
                    ret.params = info.params;
                }
            }
        }
    }
    return ret;
}

- (void)updateValue:(NSString *)key params:(NSDictionary *)params value:(id)value handler:(DataHandler)handler{
    DataMapper* mapper = [_mappers objectForKey:key];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = key;
    info.params = params;
    
    if (!mapper) {
        NSError* error = [NSError errorWithDomain:@"DataManager" code:DATA_ERROR_NOMAPPER userInfo:nil];
        if (handler) {
            handler(info,error);
        }
        return;
    }
    
    LocalStorage* localStorage = [LocalStorage instance];
    NSString* keyPath = [self _keyPath:mapper params:params];
    DataOption* option =  [mapper option:params];
    StoreType storeType = DISK;
    if (option.cacheType == CACHE_MEM) {
        storeType = MEM;
    }
    
    [mapper updateValue:params value:value handler:^(DataInfo* dataInfo,NSError* error){
        if (!error) {
            if (dataInfo.data && option.needsCache) {
                [localStorage store:[dataInfo dictionaryValue] forKey:keyPath storeType:storeType];
            }else{
                [localStorage delete:keyPath storeType:storeType];
            }
            DataInfo* autoInfo = [_autoList objectForKey:keyPath];
            if (autoInfo) {
                autoInfo.updateTime = [[NSDate date] timeIntervalSince1970];
                autoInfo.expireAfter = (info.expireAfter > MIN_DATA_FETCH_TIME)?dataInfo.expireAfter:MIN_DATA_FETCH_TIME;
            }
        }
        dataInfo.key = info.key;
        dataInfo.params = info.params;
        if (handler) {
            handler(dataInfo,error);
        }
    }];
}

- (void)cleanCache{
    LocalStorage* localStorage = [LocalStorage instance];
    [localStorage cleanPrefix:_head type:MEM];
    [localStorage cleanPrefix:_head type:DISK];
}

- (void)cleanCache:(NSString *)key{
    LocalStorage* localStorage = [LocalStorage instance];
    [localStorage cleanPrefix:[self _keyHead:key] type:MEM];
    [localStorage cleanPrefix:[self _keyHead:key] type:DISK];
}

- (void)cleanCache:(NSString *)key params:(NSDictionary *)params{
    LocalStorage* localStorage = [LocalStorage instance];
    DataMapper* mapper = [_mappers objectForKey:key];
    if (mapper) {
        [localStorage cleanPrefix:[self _keyPath:mapper params:params] type:MEM];
        [localStorage cleanPrefix:[self _keyPath:mapper params:params] type:DISK];
    }
}


#pragma mark - manage memory

- (void)dealloc{
    [_timer release];
    [_mappers release];
    [_autoList release];
    [super dealloc];
}

@end
