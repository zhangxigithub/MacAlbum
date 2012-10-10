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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    allPhoto = [NSMutableSet set];
    count = 0;
    //NSLog(@"%@",[self web:@"http://photo.renren.com/photo/270840245/album-514738413"]);
    
    
}

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if(flag == NO)
    {
        [self.window makeKeyAndOrderFront:nil];
    }
    return YES;
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
    
    
    return data;
}
-(NSSet *)getUser:(NSString *)user withAlbum:(NSString *)album
{
    for(int i = 1;i<=5;i++)
    {
        NSString *url   = [NSString stringWithFormat:kAlbumURL,user,album,i];
        
        NSArray *images = [self imagesInPage:url];
        
        return [NSSet setWithArray:images];
        //[allPhoto addObjectsFromArray:images];
        
        NSLog(@"%ld",allPhoto.count);
    }
    
    
    
    
}
- (IBAction)start:(id)sender {
    
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = self.ownerLable2.stringValue;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if(result == 0) return ;
        [self.but1 setEnabled:NO];
        [self.but2 setEnabled:NO];
       
        BACK(^{
            
            self.stateLabel.stringValue = @"获取中...";
            NSArray *albumList =  [self albumList:self.ownerLable2.stringValue];
            
            for(NSString *album in albumList)
            {
                NSSet *set =[self getUser:self.ownerLable2.stringValue
                    withAlbum:album];
                [allPhoto addObject:set];
            }
            
            
            [self download:panel.URL withSet:allPhoto];
            count = 0;
            self.stateLabel.stringValue = @"完成";
            [allPhoto removeAllObjects];
        });
        
    }];
}

- (IBAction)start2:(id)sender {
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = self.albumLable.stringValue;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if(result == 0) return ;
        self.stateLabel.stringValue = @"获取中...";
        
        [self.but1 setEnabled:NO];
        [self.but2 setEnabled:NO];
        
        BACK(^{
            NSSet *set =[self getUser:self.ownerLable.stringValue withAlbum:self.albumLable.stringValue];
            for(id obj in set)
            {
                [allPhoto addObject:obj];
            }
            
            [self download:panel.URL withSet:allPhoto];
            count = 0;
            self.stateLabel.stringValue = @"完成";
            [allPhoto removeAllObjects];
        });
    }];
    
    
}
 static int count;
-(void)download:(NSURL *)url withSet:(NSSet *)array
{
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtURL:url
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];
   
    int album = 0;
    
    for(id image in array)
    {
        count ++;
        
        if([image isKindOfClass:[NSString class]])
        {
            [self downloadImage:image to:url];
           
            self.stateLabel.stringValue = [NSString stringWithFormat:@"下载..%d/%d",count,[self count]];
        }else if([image isKindOfClass:[NSSet class]])
        {
            [self download:[url URLByAppendingPathComponent:[NSString stringWithFormat:@"%d",album++]] withSet:image];
        }
        
        
        
    }
    [self.but1 setEnabled:YES];
    [self.but2 setEnabled:YES];

}

-(void)downloadImage:(NSString *)image to:(NSURL *)url
{
    NSURL *imageURL = [NSURL URLWithString:image];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:nil];
    
    NSURL *newFile = [url URLByAppendingPathComponent:[image lastPathComponent]];
    
    [data writeToURL:newFile atomically:NO];
    
}
-(int)count
{
    int count = 0;
    for(id obj in allPhoto)
    {
        if([obj isKindOfClass:[NSString class]])
        {
            count ++;
        }else if([obj isKindOfClass:[NSSet class]])
        {
            NSSet *set = obj;
            count += set.count;
        }
    }
    return count;
}

- (IBAction)home:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://zhangxi.me"]];
}
@end
