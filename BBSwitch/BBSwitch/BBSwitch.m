//
//  BBSwitch.m
//  BBSwitch
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import "BBSwitch.h"

#define switch_border_width   2.0f
#define switch_anim_duration  0.3f
#define switch_shadow_opacity 0.25f

#define RGB(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define RGB_16(value, a) [UIColor colorWithRed:(value >> 16)/255.0 green:(value >> 8 & 0xff)/255.0 blue:(value & 0xff)/255.0 alpha:(a)]

@interface BBSwitch ()<CAAnimationDelegate>
@property(nonatomic, strong) UIImageView *select_image_view;
@property(nonatomic, strong) UIImageView *normal_image_view;
@property(nonatomic, strong) CAShapeLayer *cicle_shape;
@property(nonatomic, strong) CAShapeLayer *mask_shape;

@property(nonatomic, strong) UIColor *normal_color;
@property(nonatomic, strong) UIColor *select_color;

@property(nonatomic, assign) CGRect hit_bounds;

@property(nonatomic, weak)   id target;
@property(nonatomic, assign) SEL selector;

- (CGSize)size;
- (CGFloat)radius;
- (CGFloat)length;
- (CGFloat)height;
- (UIBezierPath *)left_path;
- (UIBezierPath *)right_path;
- (UIBezierPath *)open_path;
- (UIBezierPath *)close_path;
- (UIBezierPath *)whole_path;
- (UIBezierPath *)zero_path;
@end

@implementation BBSwitch

- (CGSize)size{
    static dispatch_once_t once_t = 0;
    static CGSize SIZE;
    dispatch_once(&once_t, ^{
        UISwitch *s = [[UISwitch alloc]init];
        SIZE = s.bounds.size;
    });
    return SIZE;
}

- (CGFloat)radius{
    return self.size.height/2-switch_border_width;
}

- (CGFloat)length{
    return 1.2*self.size.height;
}

- (CGFloat)height{
    return self.size.height-2*switch_border_width;
}

//cicle_path
- (UIBezierPath *)left_path{
    CGRect frame  = CGRectMake(switch_border_width, switch_border_width, self.height, self.height);
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.radius];
}

- (UIBezierPath *)right_path{
    CGRect frame = CGRectMake(self.size.width-self.height-switch_border_width, switch_border_width, self.height, self.height);
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.radius];
}

- (UIBezierPath *)open_path{
    CGRect frame  = CGRectMake(self.size.width-self.length-switch_border_width, switch_border_width, self.length, self.height);
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.radius];
}

- (UIBezierPath *)close_path{
    CGRect frame = CGRectMake(switch_border_width, switch_border_width, self.length, self.height);
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.radius];
}

//mask_path
- (UIBezierPath *)whole_path{
    CGRect frame = self.normal_image_view.bounds;
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.radius];
}

- (UIBezierPath *)zero_path{
    CGRect frame = CGRectMake(self.size.width-self.height/2-switch_border_width, self.height/2, 0, 0);
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:0.0f];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if([super initWithFrame:frame]){
        self.layer.cornerRadius  = self.size.height/2;
        self.layer.borderWidth   = switch_border_width;
        self.layer.masksToBounds = YES;
        
        self.select_image_view = [[UIImageView alloc]initWithFrame:self.bounds];
        self.select_image_view.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.select_image_view];
        
        self.normal_image_view = [[UIImageView alloc]initWithFrame:self.bounds];
        self.normal_image_view.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.normal_image_view];
        
        [self setSelectColor:RGB_16(0x79d672, 1)];
        [self setNormalColor:RGB_16(0xc6c6c6, 1)];
        
        self.mask_shape = [CAShapeLayer layer];
        self.mask_shape.fillColor = UIColor.whiteColor.CGColor;
        [self.normal_image_view.layer setMask:self.mask_shape];
        
        self.cicle_shape = [CAShapeLayer layer];
        self.cicle_shape.fillColor   = UIColor.whiteColor.CGColor;
        self.cicle_shape.shadowColor = UIColor.blackColor.CGColor;
        self.cicle_shape.shadowOffset  = CGSizeZero;
        self.cicle_shape.shadowOpacity = switch_shadow_opacity;
        [self.layer addSublayer:self.cicle_shape];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self
                                                                             action:@selector(tapForSelf)];
        [self addGestureRecognizer:tap];
        [self setOn:NO animation:NO];
    }
    return self;
}

- (void)setFrame:(CGRect)frame{
    self.hit_bounds = CGRectMake(-frame.size.width/2, -frame.size.height/2, frame.size.width, frame.size.height);
    
    CGFloat X = frame.origin.x+frame.size.width/2-self.size.width/2;
    CGFloat Y = frame.origin.y+frame.size.height/2-self.size.height/2;
    
    CGRect real_frame = CGRectMake(X, Y, self.size.width, self.size.height);
    [super setFrame:real_frame];
}

- (void)setOn:(BOOL)on{
    [self setOn:on animation:YES];
}

- (void)setOn:(BOOL)on animation:(BOOL)animation{
    _on = on;
    if(animation){
        [self cicleMoveAnimation];//cicle_shape移位动画
        [self maskShapeAnimation];//遮罩动画
        [self colorAnimation];    //背景色动画
    }
    else{//不动画
        [self cicleMovePosition];
        [self maskShapePosition];
        [self colorPosition];
    }
}

- (void)cicleMovePosition{
    UIBezierPath *path = self.on ? self.right_path : self.left_path;
    self.cicle_shape.path = path.CGPath;
}

- (void)maskShapePosition{
    UIBezierPath *path = self.on ? self.zero_path : self.whole_path;
    self.mask_shape.path = path.CGPath;
}

- (void)colorPosition{
    self.layer.borderColor = (self.on ? self.select_color : self.normal_color).CGColor;
}

- (void)cicleMoveAnimation{
    UIBezierPath *left  = (__bridge UIBezierPath *)self.left_path.CGPath;
    UIBezierPath *right = (__bridge UIBezierPath *)self.right_path.CGPath;
    UIBezierPath *open  = (__bridge UIBezierPath *)self.open_path.CGPath;
    UIBezierPath *close = (__bridge UIBezierPath *)self.close_path.CGPath;
    
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    anim.delegate = self;
    anim.values = self.on ? @[left, close, open, right]
                          : @[right, open, close, left];
    anim.keyTimes = @[@0.0, @0.3, @0.7, @1.0];
    anim.duration = switch_anim_duration;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    [self.cicle_shape addAnimation:anim forKey:@"anim"];
}

- (void)maskShapeAnimation{
    UIBezierPath *whole = (__bridge UIBezierPath *)self.whole_path.CGPath;
    UIBezierPath *zero  = (__bridge UIBezierPath *)self.zero_path.CGPath;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    anim.delegate  = self;
    anim.fromValue = self.on ? whole : zero;
    anim.toValue   = self.on ? zero  : whole;
    anim.duration  = switch_anim_duration;
    anim.removedOnCompletion = NO;
    anim.fillMode = kCAFillModeForwards;
    [self.mask_shape addAnimation:anim forKey:@"anim"];
}

- (void)colorAnimation{
    CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    basic.fromValue = (__bridge UIColor *)(self.on ? self.normal_color : self.select_color).CGColor;
    basic.toValue  = (__bridge UIColor *)(self.on ? self.select_color : self.normal_color).CGColor;
    basic.duration = switch_anim_duration;
    basic.removedOnCompletion = NO;
    basic.fillMode = kCAFillModeForwards;
    [self.layer addAnimation:basic forKey:@"color"];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)tapForSelf{
    if(!self.target || !self.selector){self.on = !self.on; return;} //说明需要进行交互
    if(![self.target respondsToSelector:self.selector]){self.on = !self.on; return;}//说明不会响应
    [self.target performSelector:self.selector withObject:self];
}
#pragma clang diagnostic pop

- (void)setSelectImage:(UIImage *)image{
    self.select_image_view.image = image;
}

- (void)setNormalImage:(UIImage *)image{
    self.normal_image_view.image = image;
}

- (void)setSelectColor:(UIColor *)color{
    self.select_color = color;
    self.select_image_view.backgroundColor = color;
    self.layer.borderColor = (self.on ? self.select_color : self.normal_color).CGColor;
}

- (void)setNormalColor:(UIColor *)color{
    self.normal_color = color;
    self.normal_image_view.backgroundColor = color;
    self.layer.borderColor = (self.on ? self.select_color : self.normal_color).CGColor;
}

- (void)addTarget:(id)target selector:(SEL)selector{
    self.target   = target;
    self.selector = selector;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    return CGRectContainsPoint(self.hit_bounds, point) ? self : nil;
}

//delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    UIBezierPath *cicle_path = self.on ? self.right_path : self.left_path;
    self.cicle_shape.path = cicle_path.CGPath;
    
    UIBezierPath *mask_path = self.on ? self.zero_path : self.whole_path;
    self.mask_shape.path = mask_path.CGPath;
    
    self.layer.borderColor = (self.on ? self.select_color : self.normal_color).CGColor;
}

@end
