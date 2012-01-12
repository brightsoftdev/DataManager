//
//  LocalStorage.h
//  AR
//
//  Created by wang  chao on 11-12-13.
//  Copyright 2011年 bupt. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    MEM = 1,
    DISK
}StoreType;

@interface LocalStorage : NSObject{
    NSMutableDictionary* _memStore;
    NSMutableDictionary* _diskIndex;
}

@property (nonatomic,readonly) NSDictionary* memStore;


+ (id)instance;

- (NSString*)storePath;

- (BOOL)store:(id)object forKey:(NSString*)key;
- (BOOL)delete:(NSString*)key;
- (id)getValue:(NSString*)key;
- (BOOL)storeEncrypt:(NSString*)object forKey:(NSString*)key;
- (NSString*)getEncrypt:(NSString*)key;
- (BOOL)deleteEncrypt:(NSString*)key;
- (NSString*)filePath:(NSString*)key;
- (void)clean;
- (void)cleanPrefix:(NSString*)prefix;


- (BOOL)store:(id)object forKey:(NSString*)key storeType:(StoreType)type;
- (BOOL)delete:(NSString*)key storeType:(StoreType)type;
- (id)getValue:(NSString*)key storeType:(StoreType)type;
- (void)clean:(StoreType)type;
- (void)cleanPrefix:(NSString*)prefix type:(StoreType)type;

@end
