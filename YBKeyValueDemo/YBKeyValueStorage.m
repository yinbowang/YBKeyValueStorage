//
//  YBKeyValueStorage.m
//  YBKeyValueDemo
//
//  Created by wyb on 2017/7/18.
//  Copyright © 2017年 中天易观. All rights reserved.
//

#import "YBKeyValueStorage.h"
#import "FMDB.h"

//doc目录
#define DOCUMENTPATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]

static NSString *DefaultDataBaseName = @"yb.sqlite";

@interface YBKeyValueStorage ()

@property(nonatomic,strong)FMDatabaseQueue *dataBaseQueue;

@end

@implementation YBKeyValueStorage

- (instancetype)init
{
    return [self initDatabaseWithName:DefaultDataBaseName];
}

- (instancetype)initDatabaseWithName:(NSString *)dbName
{
    self = [super init];
    if (self) {
        
        NSString *dataBasePath = [DOCUMENTPATH stringByAppendingPathComponent:dbName];
        NSLog(@"%@",dataBasePath);
        //之前创建过数据库，就销毁了
        if (self.dataBaseQueue) {
            [self close];
        }
        //重新创建一个。
        self.dataBaseQueue = [FMDatabaseQueue databaseQueueWithPath:dataBasePath];
        
    }
    return self;
}

- (instancetype)initDatabaseWithPath:(NSString *)dbPath
{
    self = [super init];
    if (self) {
        
        NSLog(@"%@",dbPath);
        //之前创建过数据库，就销毁了
        if (self.dataBaseQueue) {
            [self close];
        }
        //重新创建一个。
        self.dataBaseQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        
    }
    return self;
}

- (BOOL)checkTableName:(NSString *)tableName
{
    if (tableName.length == 0 || [tableName rangeOfString:@" "].location != NSNotFound){
        NSLog(@"表格式不对OR表不能为空");
        return NO;
    }
    return YES;
}

#pragma mark- 创建表
- (void)creatTableWithName:(NSString *)tableName
{
    //表名称不能有空格
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return;
    }
    //sql语句创建表格
    NSString *sqlString = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)",tableName];
    __block BOOL isSuccess;
    
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        //创建表
        isSuccess = [db executeUpdate:sqlString];
    }];
    
    if (isSuccess == YES) {
        NSLog(@"创建表成功了");
    }else{
        NSLog(@"创建表失败了");
    }
    
}

- (BOOL)isTableExistsWithTableName:(NSString *)tableName
{
    //表名称不能有空格
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return NO;
    }
    
    __block BOOL isExist;
    
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        //创建表
        isExist = [db tableExists:tableName];
    }];
    
    if (isExist == NO) {
        NSLog(@"表不在当前数据库");
    }else{
        NSLog(@"表在当前数据库");
    }
    
    return isExist;
    
}

- (void)cleanTableContentWithTableName:(NSString *)tableName
{
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return;
    }
    
    NSString *sqlString = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
    __block BOOL isSuccess;
    
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        isSuccess = [db executeUpdate:sqlString];
    }];
    
    if (isSuccess == NO) {
        NSLog(@"清空表内容失败了");
    }else{
        NSLog(@"清空表内容成功了");
    }
}

- (void)dropTableWithTableName:(NSString *)tableName
{
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return;
    }
    
    NSString *sqlString = [NSString stringWithFormat:@"DROP TABLE '%@'",tableName];
    __block BOOL isSuccess;
    
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        isSuccess = [db executeUpdate:sqlString];
    }];
    
    if (isSuccess == NO) {
        NSLog(@"删除表失败了");
    }else{
        NSLog(@"删除表成功了");
    }
}

- (void)close{
    
    [self.dataBaseQueue close];
    self.dataBaseQueue = nil;
}

- (void)insertValue:(id)value forKey:(NSString *)key intoTable:(NSString *)tableName
{
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return;
    }
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&error];
    if (error ) {
        NSLog(@"获取json data失败");
    }
    NSString *jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    // replace into （insert into 的增强版）如果发现表中已经有此行数据（根据主键或者唯一索引判断）则先删除此行数据，然后插入新的数据。否则，直接插入新数据。
    NSString *sqlString = [NSString stringWithFormat:@"REPLACE INTO %@ (key, value) values (?, ?)",tableName];
    
    __block BOOL isSuccess;
    
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        isSuccess = [db executeUpdate:sqlString,key,jsonString];
    }];
    
    if (isSuccess == YES) {
        NSLog(@"插入或者替换数据成功了");
    }else{
        NSLog(@"插入或者替换数据失败了");
    }
    
}

- (id)getValueByKey:(NSString *)key fromTable:(NSString *)tableName
{
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return nil;
    }
    NSString *sqlString = [NSString stringWithFormat:@"SELECT value from %@ where key = ?",tableName];
    
    __block NSString *jsonString;
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        FMResultSet *set = [db executeQuery:sqlString,key];
        if ([set next]) {
            jsonString = [set stringForColumn:@"value"];
        }
        [set close];
    }];
    
    if (jsonString) {
        NSError *error;
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        id value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            NSLog(@"解析json失败getValueByKey");
            return nil;
        }
        return value;
        
    }else{
        return nil;
    }
    
    
    
}

- (NSArray *)getAllValuesFromTable:(NSString *)tableName
{
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return nil;
    }
    NSString *sqlString = [NSString stringWithFormat:@"SELECT * from %@",tableName];
    
    __block NSString *jsonString;
    __block NSMutableArray *jsonStringArray = [NSMutableArray array];
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        FMResultSet *set = [db executeQuery:sqlString];
        while([set next]) {
            jsonString = [set stringForColumn:@"value"];
            [jsonStringArray addObject:jsonString];
        }
        [set close];
    }];
    
    NSError *error;
    NSMutableArray *valuesArray = [NSMutableArray array];
    for (NSString *jsonStr in jsonStringArray) {
        
        NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        id value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            NSLog(@"解析jsonStr失败getAllValuesFromTable");
            return nil;
        }
        [valuesArray addObject:value];
    }
    
    return valuesArray;
    

}

- (void)removeValueByKey:(NSString *)key fromTable:(NSString *)tableName
{
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return;
    }
    
    NSString *sqlString = [NSString stringWithFormat:@"DELETE from %@ where key = ?",tableName];
    __block BOOL isSuccess;
    
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        isSuccess = [db executeUpdate:sqlString,key];
    }];
    
    if (isSuccess == YES) {
        NSLog(@"删除数据成功了");
    }else{
        NSLog(@"删除数据失败了");
    }
}

- (void)removeValuesByKeyArray:(NSArray *)keys fromTable:(NSString *)tableName
{
    BOOL nameIsTrue = [self checkTableName:tableName];
    if (nameIsTrue == NO) {
        return;
    }
    NSMutableString *keysString = [NSMutableString string];
    for (NSString *key in keys) {
        NSString *subkey = [NSString stringWithFormat:@" '%@' ",key];
        if (keysString.length == 0) {
            [keysString appendString:subkey];
        }else{
            [keysString appendString:@","];
            [keysString appendString:subkey];
        }
    }
    
    NSString *sqlString = [NSString stringWithFormat:@"DELETE from %@ where key in ( %@ )",tableName,keysString];
    __block BOOL isSuccess;
    
    [self.dataBaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        isSuccess = [db executeUpdate:sqlString,keysString];
    }];
    
    if (isSuccess == YES) {
        NSLog(@"批量删除数据成功了");
    }else{
        NSLog(@"批量删除数据失败了");
    }
    
    
}













@end
