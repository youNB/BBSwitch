//
//  ViewController.m
//  BBSwitch
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import "ViewController.h"
#import "BBSwitch.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BBSwitch *s = [[BBSwitch alloc]initWithFrame:self.view.bounds];
    [s setSelectImage:[UIImage imageNamed:@"switch_open"]];
    [s setNormalImage:[UIImage imageNamed:@"switch_close"]];
//    [s setSelectColor:UIColor.blueColor];
//    [s setNormalColor:UIColor.grayColor];
    [s addTarget:self selector:@selector(clickSwitch:)];
    [self.view addSubview:s];
}

- (void)clickSwitch:(BBSwitch *)s{
    s.on = !s.on;
}

@end
