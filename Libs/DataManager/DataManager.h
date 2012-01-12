//
//  DataManager.h
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataMapper.h"
#import "RestDataMapper.h"
#import "BlockDataMapper.h"
#import "LocalDataMapper.h"


@interface DataManager : NSObject<DataMapperDelegate>{
    NSMutableDictionary* _mappers;
    NSTimer* _timer;
    NSMutableDictionary* _autoList;
}

@property (nonatomic,retain) NSMutableDictionary* mappers; 
@property (nonatomic,retain) NSMutableDictionary* autoList;
@property (nonatomic,retain) NSTimer* timer;

+ (id)manager;
- (DataInfo*)getValue:(NSString*)key params:(NSDictionary*)params;
- (void)getValue:(NSString*)key params:(NSDictionary*)params handler:(DataHandler)handler;
- (void)getValue:(NSString*)key params:(NSDictionary*)params handler:(DataHandler)handler useCache:(BOOL)useCache;
- (void)updateValue:(NSString*)key params:(NSDictionary*)params value:(id)value handler:(DataHandler)handler;
- (void)addMapper:(DataMapper*)mapper;
- (void)refershAutoList;

- (void)cleanCache;
- (void)cleanCache:(NSString*)key;
- (void)cleanCache:(NSString*)key params:(NSDictionary*)params;


@end
