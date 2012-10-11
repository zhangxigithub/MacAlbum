//
//  User.m
//  renrenalbum
//
//  Created by 张玺 on 12-10-10.
//  Copyright (c) 2012年 张玺. All rights reserved.
//


#define kPhotoURL @"http://photo.renren.com/photo/%@/photo-%@"
//owner,photo

#define kAlbumURL @"http://photo.renren.com/photo/%@/album-%@?curPage=%d"
//owner,album,page

#define kAlbumList @"http://photo.renren.com/photo/%@/album/relatives"
//owner




#import "User.h"
#import "TFHpple.h"
#import "ZXConfig.h"

@interface User ()

@end

@implementation User

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
    self.userLabel.stringValue = self.userName;
    self.window.title = self.userName;
    
    
    
    NSMutableArray *title = [NSMutableArray array];
    for(NSDictionary *album in self.albums)
    {
        [title addObject:[album objectForKey:@"title"]];
    }
    
    
    [self.albumPopUp addItemsWithTitles:title];
}

- (IBAction)checkAll:(id)sender {
    
    BOOL all = [[NSNumber numberWithInt:self.selectAll.intValue] boolValue];
    if(all)
        [self.albumPopUp setEnabled:NO];
    else
        [self.albumPopUp setEnabled:YES];
}

- (IBAction)download:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = self.userName;
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if(result == 0) return ;
        
        
        
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager createDirectoryAtURL:panel.URL
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        
        
        BOOL all = [[NSNumber numberWithInt:self.selectAll.intValue] boolValue];
        
        if(all)
        {
            BACK(^{ [self downloadAll:panel.URL];});
        }else
        {
            NSDictionary *dic = [self.albums objectAtIndex:self.albumPopUp.indexOfSelectedItem];
            NSString *albumName = [dic objectForKey:@"title"];
            NSString *albumID = [dic objectForKey:@"id"];
            
            BACK(^{
                
                NSSet *imageURLs = [self imagesInAlbum:albumID];
                [self downloadSet:imageURLs toURL:[panel.URL URLByAppendingPathComponent:albumName]];
                NSLog(@"%@",imageURLs);
            });
            
        }
        
        
        
    }];
}

-(void)downloadAll:(NSURL *)url
{
    for (NSDictionary *album in self.albums)
    {
        NSString *albumName = [album objectForKey:@"title"];
        NSString *albumID   = [album objectForKey:@"id"];
        
        NSSet *imageURLs = [self imagesInAlbum:albumID];
        
        [self downloadSet:imageURLs toURL:[url URLByAppendingPathComponent:albumName]];
        
        NSLog(@"%@",imageURLs);
    }
}


static int count;

-(void)downloadSet:(NSSet *)set toURL:(NSURL *)url
{
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtURL:url
      withIntermediateDirectories:YES
                       attributes:nil
                            error:nil];
    for(NSString *image in set)
    {
        [self downloadImage:image to:url];
    }
}

-(void)download:(NSString *)image atURL:(NSURL *)position
{
    
    NSURL *imageURL = [NSURL URLWithString:image];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil
                                                     error:nil];
    
    NSURL *newFile = [position URLByAppendingPathComponent:[image lastPathComponent]];
    
    [data writeToURL:newFile atomically:NO];
}

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
            
            
        }else if([image isKindOfClass:[NSSet class]])
        {
            [self download:[url URLByAppendingPathComponent:[NSString stringWithFormat:@"%d",album++]] withSet:image];
        }
    }
}

-(NSSet *)imagesInAlbum:(NSString *)album
{
    NSMutableSet *images = [NSMutableSet set];
    for(int i =0;i<=5;i++)
    {
        NSString *url = [NSString stringWithFormat:kAlbumURL,self.userID,album,i];
        [images addObjectsFromArray:[self imagesInPage:url]];
    }
    return images;
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
            [images addObject:[urls objectAtIndex:0]];
        }
    }
    return images;
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
    s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}

-(void)finish:(BOOL)finish
{
    if(finish)
    {
        [self.downloadButton setHidden:NO];
        [self.statusBar setHidden:YES];
    }else
    {
        [self.downloadButton setHidden:YES];
        [self.statusBar setHidden:NO];
    }
}
@end
