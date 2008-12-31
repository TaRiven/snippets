//
//  Item.m
//  eBayWatch
//
//  Created by Dustin Sallings on Wed Mar 05 2003.
//  Copyright (c) 2003 SPY internetworking. All rights reserved.
//

#import "Item.h"


@implementation Item

-(id)initWithId: (NSString *)i description: (NSString *)d price:(float)p;
{
    description=d;
    [description retain];
    price=p;
    itemId=i;
    [itemId retain];
    return(self);
}

-(void)setPrice: (float)p
{
    price=p;
}

-(float)price
{
    return(price);
}

-(NSString *)description
{
    return(description);
}

-(NSString *)itemId
{
    return(itemId);
}

-(void)update
{
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];

    NSString *s=[[NSString alloc]
        initWithFormat: @"http://cgi.ebay.com/ws/eBayISAPI.dll?ViewItem&item=%@",
        itemId];
    NSURL *url=[[NSURL alloc] initWithString: s];
    NSLog(@"Fetching from %@", url);

    NSString *data=[[NSString alloc] initWithContentsOfURL:url];

    NSRange r=[data rangeOfString: @"Current bid"];
    if(r.location == NSNotFound) {
        NSLog(@"NOT FOUND!");
    } else {
        NSLog(@"Range:  %d for %d from %d bytes", r.location, r.length,
            [data length]);
        r.length=256;
        NSString *stmp=[data substringWithRange: r];
        NSArray *a=[stmp componentsSeparatedByString: @"\r\n"];
        NSString *lineFour=[a objectAtIndex: 4];
        // NSLog(@"Line four:  %@\n", lineFour);
        r=[lineFour rangeOfString: @"$"];
        if(r.location == NSNotFound) {
            // NSLog(@"NOT FOUND!");
        } else {
            NSString *endOfFour=[lineFour substringFromIndex: (r.location+1)];
            NSRange r2=[endOfFour rangeOfString: @"<"];
            if(r2.location == NSNotFound) {
                // NSLog(@"NOT FOUND!");
            } else {
                NSString *thePrice=[endOfFour substringToIndex: r2.location];
                // Need to pull out commas
                NSLog(@"Price input:  %@", thePrice);
                NSMutableString *priceAfter=[[NSMutableString alloc]
                    initWithCapacity: 8];
                [priceAfter appendString: thePrice];
                [priceAfter replaceOccurrencesOfString: @","
                    withString: @"" options: 0
                    range: NSMakeRange(0, [priceAfter length])];
                // Done, float it
                price=[priceAfter floatValue];
                NSLog(@"Current price:  %.02f", price);
                [priceAfter release];
            }
        }
    }

    [s release];
    [url release];
    [data release];
    [pool release];
}

@end
