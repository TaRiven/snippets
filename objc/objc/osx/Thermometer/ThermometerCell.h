//
//  ThermometerCell.h
//  Thermometer
//
//  Created by Dustin Sallings on Sat Mar 22 2003.
//  Copyright (c) 2003 SPY internetworking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "Thermometer.h"

@interface ThermometerCell : NSButtonCell
{
    bool celsius;

    NSImage *cImage;
    NSImage *fImage;
    Thermometer *therm;
    bool _showTrend;
}

-(void)setCelsius;
-(void)setFarenheit;
-(void)setCImage: (NSImage *)to;
-(void)setFImage: (NSImage *)to;
-(void)setTherm: (Thermometer *)t;
-(id)therm;

-(void)newReading:(float)r;


@end
