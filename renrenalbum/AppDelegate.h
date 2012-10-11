//
//  AppDelegate.h
//  renrenalbum
//
//  Created by 张玺 on 12-10-9.
//  Copyright (c) 2012年 张玺. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "User.h"
#import "Login.h"
@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSMutableSet *allPhoto;
    User *userWC;
    Login *login;
}
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *ownerLable;
@property (weak) IBOutlet NSTextField *ownerLable2;

@property (weak) IBOutlet NSTextField *albumLable;
- (IBAction)start:(id)sender;
- (IBAction)start2:(id)sender;

@property (weak) IBOutlet NSTextField *stateLabel;

@property (weak) IBOutlet NSButton *but1;

@property (weak) IBOutlet NSButton *but2;

@property (weak) IBOutlet NSTextField *idLabel;

@property (weak) IBOutlet NSButton *searchButton;

- (IBAction)home:(id)sender;

- (IBAction)search:(id)sender;

- (IBAction)showLogin:(id)sender;
- (IBAction)myAlbum:(id)sender;

@end
