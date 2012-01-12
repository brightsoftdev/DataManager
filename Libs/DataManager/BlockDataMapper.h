//
//  BlockDataMapper.h
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "DataMapper.h"

typedef DataInfo* (^BlockDataGetter)(DataMapper* mapper,NSDictionary* params);

@interface BlockDataMapper : DataMapper{
    BlockDataGetter _getter;
}

@property (nonatomic,copy) BlockDataGetter getter;

- (id)initWithKey:(NSString *)key getter:(BlockDataGetter)getter;

@end
