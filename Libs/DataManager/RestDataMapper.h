//
//  RestDataMapper.h
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "DataMapper.h"
#import "HServer.h"

@interface RestDataMapper : DataMapper{
    NSString* _urlTemplate;
}

@property (nonatomic,retain) NSString* urlTemplate;

- (id)initWithKey:(NSString *)key urlTemplate:(NSString*)urlTemplate;
- (HttpRequest*)generateRequest:(NSDictionary*)params method:(NSString*)method;

@end
