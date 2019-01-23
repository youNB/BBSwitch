//
//  BBSwitch.h
//  BBSwitch
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
    由于涉及到离屏渲染，不建议在UITableView/UICollectionView里面大量使用
*/

@interface BBSwitch : UIView
@property(nonatomic, assign) BOOL on;

- (void)setOn:(BOOL)on animation:(BOOL)animation;

- (void)setSelectImage:(UIImage *)image;

- (void)setNormalImage:(UIImage *)image;

- (void)setSelectColor:(UIColor *)color;

- (void)setNormalColor:(UIColor *)color;

- (void)addTarget:(id)target selector:(SEL)selector;

@end

