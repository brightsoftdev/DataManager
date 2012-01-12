//
//  DataMapper.h
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DATA_ERROR_UNKNOWN 0
#define DATA_ERROR_NOTIMPLEMENT 1
#define DATA_ERROR_NOMAPPER 2

@class DataInfo;
@class DataMapper;

typedef void (^DataHandler)(DataInfo* info,NSError* error);
typedef id (^DataDecoder)(id data);

@interface  DataInfo : NSObject{
    NSObject* _data;
    NSString* _key;
    NSDictionary* _params;
    NSTimeInterval _updateTime;
    NSTimeInterval _expireAfter;
}

@property (nonatomic,retain) NSObject* data;
@property (nonatomic,retain) NSString* key;
@property (nonatomic,retain) NSDictionary* params;
@property (nonatomic,assign) NSTimeInterval updateTime;
@property (nonatomic,assign) NSTimeInterval expireAfter;

+ (id)dataInfoWithDictionary:(NSDictionary*)dictionary;
- (void)clean;
- (NSMutableDictionary*)dictionaryValue;
- (void)loadDictionary:(NSDictionary*)dict;
- (BOOL)expired;

@end

typedef enum{
    CACHE_MEM = 1,
    CACHE_DISK
}DataCacheType;

@interface DataOption : NSObject {
    BOOL _setExpireAfter;
    NSTimeInterval _expireAfter;
    BOOL _autoFetch;
    BOOL _needsCache;
    DataCacheType _cacheType;
}
@property (nonatomic,assign) BOOL setExpireAfter;
@property (nonatomic,assign) NSTimeInterval expireAfter;
@property (nonatomic,assign) BOOL autoFetch;
@property (nonatomic,assign) BOOL needsCache;
@property (nonatomic,assign) DataCacheType cacheType;

- (void)clean;
+ (id)optionFromOption:(DataOption*)option;

@end

@protocol DataMapperDelegate <NSObject>

- (void)mapperStateChanged:(DataMapper*)mapper params:(NSDictionary*)params;

@end

@interface DataMapper : NSObject{
    NSString* _key;
    NSMutableDictionary* _options;
    NSMutableDictionary* _autoList;
    id<DataMapperDelegate> _delegate;
    DataDecoder _decoder;
    
    DataOption* _defaultOption;
}

@property (nonatomic,retain) NSString* key;
@property (nonatomic,retain) NSMutableDictionary* options;
@property (nonatomic,retain) NSMutableDictionary* autoList;   
@property (nonatomic,assign) id<DataMapperDelegate> delegate;
@property (nonatomic,copy) DataDecoder decoder;
@property (nonatomic,retain) DataOption* defaultOption;


- (id)initWithKey:(NSString*)key;
- (NSString*)keyPathForParams:(NSDictionary*)params;
- (void)getValue:(NSDictionary*)params handler:(DataHandler)handler;
- (DataInfo*)getValue:(NSDictionary*)params;
- (void)updateValue:(NSDictionary*)params value:(id)value handler:(DataHandler)handler;
- (void)addOption:(DataOption*)option forParams:(NSDictionary*)params;
- (void)removeOption:(DataOption*)option forParams:(NSDictionary*)params;
- (DataOption*)option:(NSDictionary*)params;
//needs to be overried
- (void)_getValue:(NSDictionary*)params handler:(DataHandler)handler;
- (void)_updateValue:(NSDictionary*)params value:(id)value handler:(DataHandler)handler;

+ (NSDictionary*)normalParams:(NSDictionary*)params;
+ (NSDictionary*)hiddenParams:(NSDictionary*)params;

@end
