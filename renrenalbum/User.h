//
//  User.h
//  renrenalbum
//
//  Created by 张玺 on 12-10-10.
//  Copyright (c) 2012年 张玺. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface User : NSWindowController
{
    long int total;
    BOOL needCancel;
}

@property(nonatomic,strong) NSArray *albums;
@property(nonatomic,strong) NSString *userName;
@property(nonatomic,strong) NSString *userID;


@property (weak) IBOutlet NSTextField *userLabel;

@property (weak) IBOutlet NSPopUpButton *albumPopUp;
@property (weak) IBOutlet NSButton *selectAll;


@property (weak) IBOutlet NSButton *downloadButton;

@property (weak) IBOutlet NSButton *cancel;
@property (weak) IBOutlet NSProgressIndicator *statusBar;

- (IBAction)checkAll:(id)sender;

- (IBAction)cancelDownload:(id)sender;

- (IBAction)download:(id)sender;

@end
