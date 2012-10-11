//
//  Login.m
//  renrenalbum
//
//  Created by 张 玺 on 12-10-11.
//  Copyright (c) 2012年 张玺. All rights reserved.
//

#import "Login.h"

@interface Login ()

@end

@implementation Login

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    
    
    [[self.web mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.renren.com"]]];
    
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
