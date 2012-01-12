//
//  LocalStorage.m
//  AR
//
//  Created by wang  chao on 11-12-13.
//  Copyright 2011年 bupt. All rights reserved.
//

#import "LocalStorage.h"
#import "SFHFKeychainUtils.h"

#define OBJ_TYPE_STRING @"string"
#define OBJ_TYPE_ARRAY @"array"
#define OBJ_TYPE_DICT @"dict"
#define OBJ_TYPE_IMAGE @"image"
#define OBJ_TYPE_DATA @"data"
#define OBJ_TYPE_OTHER @"other"

#define STORE_PATH @"localStorage_w"

static LocalStorage* _instance;

@interface LocalStorage (Private) 

- (NSString*)_documentPath;
- (NSString*)_storePath;
- (NSString*)_indexPath;
- (NSString*)_contentPath;
- (NSDictionary*)_keysOfPrefix:(NSString*)prefix type:(StoreType)type;

@end

@implementation LocalStorage (Private)

- (NSString*)_documentPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	return documentPath;
}
- (NSString*)_storePath{
    return [[self _documentPath] stringByAppendingPathComponent:STORE_PATH];
}
- (NSString*)_indexPath{
    return [[self _storePath] stringByAppendingPathComponent:@"index.plist"];
}
- (NSString*)_contentPath{
    return [[self _storePath] stringByAppendingPathComponent:@"content"];
}

- (NSString*)_generatePathWithHash:(NSUInteger)hash{
    NSString* hashString = [NSString stringWithFormat:@"%08x",hash];
    NSRange range;
    range.length = 2;
    range.location = 0;
    NSString* p0 = [hashString substringWithRange:range];
    range.location = 2;
    NSString* p1 = [hashString substringWithRange:range];
    range.location = 4;
    NSString* p2 = [hashString substringWithRange:range];
    range.location = 6;
    NSString* p3 = [hashString substringWithRange:range];
    NSString* path = [NSString stringWithFormat:@"%@/%@/%@/%@",p0,p1,p2,p3];
    return [[self _contentPath] stringByAppendingPathComponent:path];
}

- (NSDictionary*)_keysOfPrefix:(NSString *)prefix type:(StoreType)type{
    NSMutableDictionary* ret = [NSMutableDictionary dictionary];
    NSDictionary* keys = (type == MEM)?_memStore:_diskIndex;
    for (NSString* key in keys) {
        if([key hasPrefix:prefix]){
            [ret setObject:[keys objectForKey:key] forKey:key];
        }
    }
    return ret;
}

@end

@implementation LocalStorage

@synthesize memStore = _memStore;

- (id)init
{
    self = [super init];
    if (self) {
        _memStore = [NSMutableDictionary dictionaryWithCapacity:20];
        [_memStore retain];
        _diskIndex = [NSMutableDictionary dictionaryWithContentsOfFile:[self _indexPath]];
        if(!_diskIndex){
            _diskIndex = [NSMutableDictionary dictionaryWithCapacity:20];
        }
        [_diskIndex retain];
    }
    
    return self;
}

- (NSString*)storePath{
    return [self _storePath];
}

+ (id)instance{
    if (!_instance) {
        _instance = [[LocalStorage alloc] init];
    }
    return _instance;
}

- (BOOL)store:(id)object forKey:(NSString *)key{
    return [self store:object forKey:key storeType:DISK];
}

- (BOOL)delete:(NSString *)key{
    return [self delete:key storeType:DISK];
}

- (id)getValue:(NSString*)key{
    return [self getValue:key storeType:DISK];
}

- (NSString*)filePath:(NSString *)key{
    NSDictionary* info = [_diskIndex objectForKey:key];
    if (!info) {
        return nil;
    }
    return [info objectForKey:@"path"];
}

- (BOOL)storeEncrypt:(NSString*)object forKey:(NSString*)key{
    if([SFHFKeychainUtils storeUsername:key andPassword:object forServiceName:@"localStorage" updateExisting:YES error:nil]){
        return [self store:@"<Encrypt>" forKey:key];
    }
    return NO;
}

- (NSString*)getEncrypt:(NSString*)key{
    if ([_diskIndex objectForKey:key]) {
        return [SFHFKeychainUtils getPasswordForUsername:key andServiceName:@"localStorage" error:nil];
    }
    return nil;
}

- (BOOL)deleteEncrypt:(NSString *)key{
    if([SFHFKeychainUtils deleteItemForUsername:key andServiceName:@"localStorage" error:nil]){
        return [self delete:key];
    }
    return NO;
}

- (void)clean{
    [self clean:DISK];
}

- (void)cleanPrefix:(NSString*)prefix{
    [self cleanPrefix:prefix type:DISK];    
}

- (BOOL)store:(id)object forKey:(NSString*)key storeType:(StoreType)type{
    NSString* objType = nil;
    NSString* extension = @"";
    BOOL success = NO;
    
    if ([object isKindOfClass:[NSString class]]) {
        objType = OBJ_TYPE_STRING;
        extension = @".txt";
    }else if([object isKindOfClass:[NSArray class]]){
        objType = OBJ_TYPE_ARRAY;
        extension = @".plist";
    }else if([object isKindOfClass:[NSDictionary class]]){
        objType = OBJ_TYPE_DICT;
        extension = @".plist";
    }else if([object isKindOfClass:[UIImage class]]){
        objType = OBJ_TYPE_IMAGE;
        extension = @".png";
    }else if([object isKindOfClass:[NSData class]]){
        objType = OBJ_TYPE_DATA;
        extension = @".data";
    }else{
        objType = OBJ_TYPE_OTHER;
        if (type == DISK) {
            NSString* msg = [NSString stringWithFormat:@"Disk storage can only be NSString,NSArray,UIImage,NSData or their sub classes"];
            NSException* e = [NSException exceptionWithName:@"Not disk storage exception" reason:msg userInfo:nil];
            @throw e;
        }
    }
    
    if (type == MEM) {
        [_memStore setObject:object forKey:key];
        success = YES;
    }else{
        NSString* directory = [self _generatePathWithHash:[key hash]];
        NSString* fileName = [@"data" stringByAppendingString:extension];
        NSString* filePath = [directory stringByAppendingPathComponent:fileName];
        
        NSFileManager* fmanager = [NSFileManager defaultManager]; 
        if(![fmanager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]){
            return NO;
        }
        
        if ([objType isEqualToString:OBJ_TYPE_STRING]) {
            success = [object writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }else if([objType isEqualToString:OBJ_TYPE_ARRAY]){
            success = [(NSArray*)object writeToFile:filePath atomically:YES];
        }else if([objType isEqualToString:OBJ_TYPE_DICT]){
            success = [(NSDictionary*)object writeToFile:filePath atomically:YES];
        }else if([objType isEqualToString:OBJ_TYPE_DATA]){
            success = [(NSData*)object writeToFile:filePath atomically:YES];
        }else if([objType isEqualToString:OBJ_TYPE_IMAGE]){
            NSData* data = UIImagePNGRepresentation((UIImage*)object);
            success = [data writeToFile:filePath atomically:YES];
        }
        
        if (success) {
            //update index
            NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         filePath,@"path",
                                         objType,@"type",
                                         nil];
            [_diskIndex setObject:dict forKey:key];
            NSMutableDictionary* backIndex = [NSMutableDictionary dictionaryWithDictionary:_diskIndex];
            success = [_diskIndex writeToFile:[self _indexPath] atomically:YES];
            if (!success) {
                [backIndex retain];
                [_diskIndex release];
                _diskIndex = backIndex;
            }
        }
    }
    
    return success;
}

- (BOOL)delete:(NSString *)key storeType:(StoreType)type{
    if (!_diskIndex) {
        return YES;
    }
    if (type == MEM) {
        [_memStore removeObjectForKey:key];
        return YES;
    }else{
        NSMutableDictionary* backIndex = [NSMutableDictionary dictionaryWithDictionary:_diskIndex];
        [_diskIndex removeObjectForKey:key];
        if ([_diskIndex writeToFile:[self _indexPath] atomically:YES]) {
            NSFileManager* fmanager = [NSFileManager defaultManager]; 
            NSDictionary* dict = [backIndex objectForKey:key];
            NSString* path = [dict objectForKey:@"path"];
            [fmanager removeItemAtPath:path error:nil];
        }else{
            [backIndex retain];
            [_diskIndex release];
            _diskIndex = backIndex;
            return NO;
        }
    }
    return NO;
}

- (id)getValue:(NSString*)key storeType:(StoreType)type{
    id ret = nil;
    if (type == MEM) {
        return [_memStore objectForKey:key];
    }else{
        NSDictionary* info = [_diskIndex objectForKey:key];
        if (!info) {
            return nil;
        }
        NSString* path = [info objectForKey:@"path"];
        NSString* objType = [info objectForKey:@"type"];
        if ([objType isEqualToString:OBJ_TYPE_STRING]) {
            NSString* string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            ret = string;
        }else if([objType isEqualToString:OBJ_TYPE_ARRAY]){
            NSMutableArray* array = [NSArray arrayWithContentsOfFile:path];
            ret = array;
        }else if([objType isEqualToString:OBJ_TYPE_DICT]){
            NSMutableDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:path];
            ret = dict;
        }else if([objType isEqualToString:OBJ_TYPE_DATA]){
            NSData* data = [NSData dataWithContentsOfFile:path];
            ret = data;
        }else if([objType isEqualToString:OBJ_TYPE_IMAGE]){
            UIImage* image = [UIImage imageWithContentsOfFile:path];
            ret = image;
        }
        return ret;
    }
    return nil;
}



- (void)clean:(StoreType)type{
    if (type == MEM) {
        [_memStore removeAllObjects];
    }else{
        [_diskIndex removeAllObjects];
        NSFileManager* fmanager = [NSFileManager defaultManager]; 
        [fmanager removeItemAtPath:[self _storePath] error:nil];
    }
}

- (void)cleanPrefix:(NSString*)prefix type:(StoreType)type{
    NSDictionary* keys = [self _keysOfPrefix:prefix type:type];
    for (NSString* key in keys) {
        [self delete:key storeType:type];
    }
}

- (void)dealloc{
    [_memStore release];
    [_diskIndex release];
    [super dealloc];
}

@end
