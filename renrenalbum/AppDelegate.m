//
//  AppDelegate.m
//  renrenalbum
//
//  Created by 张玺 on 12-10-9.
//  Copyright (c) 2012年 张玺. All rights reserved.
//


#define kPhotoURL @"http://photo.renren.com/photo/%@/photo-%@"
//owner,photo

#define kAlbumURL @"http://photo.renren.com/photo/%@/album-%@?curPage=%d"
//owner,album,page

#define kAlbumList @"http://photo.renren.com/photo/%@/album/relatives"
//owner




#import "AppDelegate.h"
#import "TFHpple.h"
#import "JSONKit.h"
#import "AFNetworking.h"
#import "ZXConfig.h"

@implementation AppDelegate


-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if(flag == NO)
    {
        [self.window makeKeyAndOrderFront:nil];
    }
    return YES;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    allPhoto = [NSMutableSet set];

    //NSLog(@"%@",[self web:@"http://photo.renren.com/photo/270840245/album-514738413"]);
    
    login = [[Login alloc] initWithWindowNibName:@"Login"];
    [login showWindow:nil];
}

-(NSArray *)getAlbumList:(NSString *)user
{
    NSString *url = [NSString stringWithFormat:kAlbumList,user];
    NSLog(@"%@",url);
    [self web:url];
    NSLog(@"first get web");
    [NSThread sleepForTimeInterval:1];
    
    NSData *webData = [self webData:url];
    
    NSString *str = [[NSString alloc] initWithData:webData encoding:NSUTF8StringEncoding];
    [str writeToFile:[NSString stringWithFormat:@"%@/log.txt",NSHomeDirectory()]
          atomically:YES
            encoding:NSUTF8StringEncoding
               error:nil];
    
    TFHpple * doc       = [[TFHpple alloc] initWithHTMLData:webData];
    NSLog(@"second get web");
    NSLog(@"1");
    NSMutableArray *albumName = [NSMutableArray array];
    NSMutableArray *albumID   = [NSMutableArray array];
    

    
    NSArray * idElements    = [doc searchWithXPathQuery:@"//a[@class='album-title']"];
    NSArray * nameElements  = [doc searchWithXPathQuery:@"//span[@class='album-name']"];
    NSArray * userElements  = [doc searchWithXPathQuery:@"//ul[@class='nav-tabs']/li/a/strong"];
    
    
    
    for(TFHppleElement * element in idElements)
    {
        NSString *name = [element objectForKey:@"href"];
        NSLog(@"%@",name);
        NSRange start = [name rangeOfString:@"album-"];
        
        
        if(start.location<=name.length)
        {
            name = [name substringFromIndex:start.location+start.length];
            name = [name substringToIndex:9];
            
            [albumID addObject:name];
        }
    }
    
    for(TFHppleElement * element in nameElements)
    {
        NSString *name = [[[element children] lastObject] content];
        if(name != Nil)
            [albumName addObject:name];
    }
    
    TFHppleElement * element = [[userElements lastObject] firstChild];
    NSString *userName = [element content];
    
    NSLog(@"%@\n%@",albumID,albumName);
    NSLog(@"%ld,%ld",albumID.count,albumName.count);
    
    //NSLog(@"%@",elements);
    NSMutableArray *albums = [NSMutableArray array];
    for(int i = 0;i<albumID.count;i++)
    {
        NSDictionary *album = @{@"title":[albumName objectAtIndex:i],@"id":[albumID objectAtIndex:i]};
        [albums addObject:album];
    }
    
    
    if(userName != nil)
    {
        userWC = [[User alloc] initWithWindowNibName:@"User"];
        userWC.albums   = albums;
        userWC.userName = userName;
        userWC.userID   = self.idLabel.stringValue;
        MAIN(^{[userWC showWindow:nil];});
        
    }else
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"获取失败"
                                         defaultButton:@"哦"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
    }
    
    
    return nil;
}


-(NSArray *)albumList:(NSString *)user
{
    NSString *url = [NSString stringWithFormat:kAlbumList,user];
    [self web:url];
    [NSThread sleepForTimeInterval:1];
    NSString *str = [self web:url];
    NSRange start = [str rangeOfString:@"data-wiki="];
    NSLog(@"%ld,%ld",start.location,start.length);
    
    if(start.location + start.length > str.length) return nil;
    
    NSString *str2 = [str substringFromIndex:start.location+start.length];
    
    NSArray *urls = [str2 componentsSeparatedByString:@">"];
    if(urls.count > 1)
    {
        NSString *s = [urls objectAtIndex:0];
        s = [s stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        s = [s stringByReplacingOccurrencesOfString:@"{"  withString:@""];
        s = [s stringByReplacingOccurrencesOfString:@"}"  withString:@""];
        s = [s stringByReplacingOccurrencesOfString:@":"  withString:@""];
        
        NSArray *a = [s componentsSeparatedByString:@","];
        NSLog(@"%@",a);
        return a;
        
    }
    return nil;
}
-(NSArray *)imagesInPage:(NSString *)pageURL
{
    NSMutableArray *images =[NSMutableArray array];
    NSData  * data = [self webData:pageURL];
    
    TFHpple * doc       = [[TFHpple alloc] initWithHTMLData:data];
    NSArray * elements  = [doc searchWithXPathQuery:@"//img"];
    
    
    for(TFHppleElement * element in elements)
    {
        NSString *str =[[element attributes] objectForKey:@"data-photo"];
        
        NSRange start = [str rangeOfString:@"large:'"];
        NSString *str2 = [str substringFromIndex:start.location+start.length];
        NSArray *urls = [str2 componentsSeparatedByString:@"'"];
        if(urls.count > 1)
        {
            //NSLog(@"%@",[urls objectAtIndex:0]);
            [images addObject:[urls objectAtIndex:0]];
        }
    }
    return images;
}

-(NSString *)web:(NSString *)url
{
    
    NSString *s = [[NSString alloc] initWithData:[self webData:url] encoding:NSUTF8StringEncoding];
    return s;
}
-(NSData *)webData:(NSString *)url
{
    NSURLRequest *request =  [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    
    NSData *data =  [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:nil
                                                      error:nil];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
   // NSLog(@"%@",s);
    s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}



- (IBAction)home:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://zhangxi.me"]];
}

- (IBAction)search:(id)sender {
    BACK(^{
    [self.searchButton setTitle:@"获取中..."];
    [self.searchButton setEnabled:NO];
    [self getAlbumList:self.idLabel.stringValue];
    [self.searchButton setEnabled:YES];
    self.searchButton.title = @"获取相册";
        });
}

- (IBAction)showLogin:(id)sender {
    login = [[Login alloc] initWithWindowNibName:@"Login"];
    [login showWindow:nil];
}

- (IBAction)myAlbum:(id)sender {
   }
@end
