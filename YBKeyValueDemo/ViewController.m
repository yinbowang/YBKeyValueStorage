//
//  ViewController.m
//  YBKeyValueDemo
//
//  Created by wyb on 2017/7/18.
//  Copyright © 2017年 中天易观. All rights reserved.
//

#import "ViewController.h"
#import "YBKeyValueStorage.h"

static NSString *table = @"personTable";

@interface ViewController ()

@property(nonatomic,strong)YBKeyValueStorage *storage;
@property(nonatomic,assign)NSInteger count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.count = 0;
    self.storage = [[YBKeyValueStorage alloc]initDatabaseWithName:@"yb.db"];
    [self.storage isTableExistsWithTableName:table];
    
}
- (IBAction)creatTable:(id)sender {
    [self.storage creatTableWithName:table];
}

- (IBAction)dropTable:(id)sender {
    
    [self.storage dropTableWithTableName:table];
    
}
- (IBAction)cleanTable:(id)sender {
    
    [self.storage cleanTableContentWithTableName:table];
}
- (IBAction)insertOneData:(id)sender {
    self.count = self.count + 1;
    NSDictionary *person = @{@"name":@"wang",@"age":@(self.count)};
    [self.storage insertValue:person forKey:[NSString stringWithFormat:@"%ld",self.count] intoTable:table];
    
    
}
- (IBAction)getOneData:(id)sender {
    
   NSDictionary*dic = [self.storage getValueByKey:[NSString stringWithFormat:@"%ld",self.count] fromTable:table];
    NSLog(@"%@",dic);
    
}
- (IBAction)deleteOneData:(id)sender {
    
    [self.storage removeValueByKey:[NSString stringWithFormat:@"%ld",self.count] fromTable:table];
    
}
- (IBAction)deleteMoreData:(id)sender {
    
    [self.storage removeValuesByKeyArray:@[@"1",@"2"] fromTable:table];
}
- (IBAction)getAllData:(id)sender {
    
   NSArray *arr = [self.storage getAllValuesFromTable:table];
    NSLog(@"%@",arr);
    
}

@end
