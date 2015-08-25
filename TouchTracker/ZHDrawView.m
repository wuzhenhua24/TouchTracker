//
//  ZHDrawView.m
//  TouchTracker
//
//  Created by wuzhenhua on 15/8/23.
//  Copyright (c) 2015年 wu. All rights reserved.
//

#import "ZHDrawView.h"
#import "ZHLine.h"

@interface ZHDrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;

@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;

@property (nonatomic, weak) ZHLine *selectedLine;

@end

@implementation ZHDrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.linesInProgress = [[NSMutableDictionary alloc] init];
        self.finishedLines = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor grayColor];
        
        self.multipleTouchEnabled = YES;
        
        
        
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan = YES;
        [self addGestureRecognizer:doubleTapRecognizer];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan = YES;
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        
        [self addGestureRecognizer:tapRecognizer];
        
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        
        [self addGestureRecognizer:pressRecognizer];
        
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        self.moveRecognizer.delegate = self;
        self.moveRecognizer.cancelsTouchesInView = NO;
        
        [self addGestureRecognizer:self.moveRecognizer];
    }
    
    return self;
}


- (void)strokeLine:(ZHLine *)line
{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

- (void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] set];
    
    for (ZHLine *line in self.finishedLines) {
        [[self colorBasedOnAngleWithLine:line] set];
        [self strokeLine:line];
    }
    
    
    [[UIColor redColor] set];
    
    for (NSValue *key in self.linesInProgress) {
        [self strokeLine:self.linesInProgress[key]];
    }
    
    if (self.selectedLine) {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
    
//    float f = 0.0;
//    for (int i = 0; i < 10000; i++) {
//        f = f + sin(sin(time(NULL) + i));
//    }
//    NSLog(@"f = %f",f);
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self];
        
        ZHLine *line = [[ZHLine alloc] init];
        line.begin = location;
        line.end = location;
        
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        self.linesInProgress[key] = line;
    }
    
    [self setNeedsDisplay];
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        ZHLine *line = self.linesInProgress[key];
        line.end = [touch locationInView:self];
    }
    
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        ZHLine *line = self.linesInProgress[key];
        
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}


-(UIColor *) colorBasedOnAngleWithLine:(ZHLine *) line
{
    float angleVal = atan2f(line.end.y - line.begin.y, line.end.x - line.end.y);
    
    NSLog(@"angleVal=%f",angleVal);
    angleVal = fabs(angleVal);
    if (angleVal > 2.5)
    {
        return [UIColor cyanColor];
    }
    else if ( angleVal < 1.5)
    {
        return [UIColor orangeColor];
    }else
        return [UIColor purpleColor];
}


- (void)doubleTap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized double tap");
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

- (void)tap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");
    CGPoint point = [gr locationInView:self];
    self.selectedLine = [self lineAtPoint:point];
    
    if (self.selectedLine) {
        [self becomeFirstResponder];
        
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        
        menu.menuItems = @[deleteItem];
        
        [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        
        [menu setMenuVisible:YES];
    } else {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
    
}

- (ZHLine *)lineAtPoint:(CGPoint)p
{
    for (ZHLine *l in self.finishedLines) {
        CGPoint start = l.begin;
        CGPoint end = l.end;
        
        for (float t = 0.0; t <= 1.0; t+= 0.05) {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            
            if (hypot(x - p.x, y - p.y)) {
                return  l;
            }
        }
    }
    
    return nil;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}


- (void)deleteLine:(id)sender
{
    [self.finishedLines removeObject:self.selectedLine];
    
    [self setNeedsDisplay];
}

- (void)longPress:(UIGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        } else if (gr.state == UIGestureRecognizerStateEnded)
            self.selectedLine = nil;
    }
    
    [self setNeedsDisplay];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.moveRecognizer) {
        return YES;
    }
    
    return NO;
}


- (void)moveLine:(UIPanGestureRecognizer *)gr
{
    if (!self.selectedLine) {
        return;
    }
    
    if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gr translationInView:self];
        
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        begin.x += translation.x;
        begin.y += translation.y;
        
        end.x += translation.x;
        end.y += translation.y;
        
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
        
        [self setNeedsDisplay];
        
        [gr setTranslation:CGPointZero inView:self];
    }
}



@end
