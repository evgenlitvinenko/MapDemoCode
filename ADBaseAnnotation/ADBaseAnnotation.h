//
//  ADClusterableAnnotation.h
//  ADClusterMapView
//
//  Created by Patrick Nollet on 27/06/11.
//  Copyright 2011 Applidium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Post;

@interface ADBaseAnnotation : NSObject <MKAnnotation>

- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) NSDictionary *vibe;
@property (nonatomic, strong) NSString *type;

- (id)initWithCoordinates:(CLLocationCoordinate2D)location title:(NSString *)title subtitle:(NSString *)subtitle;

@end
