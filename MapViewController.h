//
//  MapViewController.h
//  Opinit
//
//  Created by Евгений Литвиненко on 12/3/14.
//  Copyright (c) 2014 Opinit Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Post, User, TSClusterMapView;

typedef enum{
    allAnnotationType = 0,
    vibeAnnotationType,
    postsAnnotationType,
    vibesForPostAnnotationType
}MapType;

@interface MapViewController : UIViewController 

@property (strong, nonatomic) Post *postMap;
@property (strong, nonatomic) User *user;

@property (assign, nonatomic) MapType mapType;

@end
