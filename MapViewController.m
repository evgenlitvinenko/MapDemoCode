//
//  MapViewController.m
//
//  Created by Евгений Литвиненко on 12/3/14.
//  Copyright (c) 2014 Opinit Inc. All rights reserved.
//

#import "MapViewController.h"
#import <QuartzCore/QuartzCore.h>

#import <CoreLocation/CoreLocation.h>
#import "Model.h"
#import "User.h"
#import <mapKit/MKAnnotation.h>

#import "ADBaseAnnotation.h"
#import "TSDemoClusteredAnnotationView.h"

#import "Post.h"
#import <MapKit/MapKit.h>
#import "TSClusterMapView.h"

#import "Image+States.h"


#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface MapViewController () <MKMapViewDelegate, TSClusterMapViewDelegate>

@property (nonatomic,   weak) IBOutlet TSClusterMapView *map;
@property (nonatomic, strong) UIImageView *imageOnClick;
@property (nonatomic, strong) UIView *imageBackground;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) NSMutableDictionary* vibesAnnotationDictionary;
@property (nonatomic, strong) NSMutableDictionary* postsAnnotationDictionary;
@property (nonatomic, strong) NSMutableDictionary* annotationDictionary;

@property (nonatomic, strong) ADBaseAnnotation *allAnnotation;
@property (nonatomic, strong) ADBaseAnnotation *postsAnnotation;
@property (nonatomic, strong) ADBaseAnnotation *vibesAnnotation;

@property (nonatomic, strong) UIImage *onePhoto;
@property (nonatomic, strong) UIImage *threeAndMorePhoto;
@property (nonatomic, strong) UIImage *twoPhoto;
@property (nonatomic, strong) UIImage *widthoutPhoto;

@end

@implementation MapViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.user.username uppercaseString];
    
    self.vibesAnnotationDictionary = self.postsAnnotationDictionary = self.annotationDictionary = [[NSMutableDictionary alloc] init];
                       
    self.map.delegate = self;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideImage)];
    self.tapGestureRecognizer.enabled = NO;
    [self.map addGestureRecognizer:self.tapGestureRecognizer];
    
    self.map.clusterDiscrimination = 0.9;
    self.map.clusterEdgeBufferSize = ADClusterBufferMedium;
    self.map.clusterPreferredVisibleCount = 100;
    
    switch (self.mapType) {
        case allAnnotationType:{
            [self getAllContent];
            break;
        }
        case vibeAnnotationType:{
            [self getVibesMap];
            break;
        }
        case postsAnnotationType:{
            [self getPostsMap];
            break;
        }
        case vibesForPostAnnotationType:{
            [self getVibesForPost:self.postMap];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Create Annotations

- (void)getAllContent{
    [self getPostsMap];
    [self getVibesMap];
    [self.map addClusteredAnnotation:self.postsAnnotation];
    [self.map addClusteredAnnotation:self.vibesAnnotation];
    [self zoomToFitMapAnnotations:self.map];
}

- (void)getPostsMap{
    //- getting locations from server side (API)
    //- generating annotation that will be used in map
    [[Model sharedObject] getPostsWithLocationsForUser:self.user block:^(NSArray *posts, NSUInteger count) {
        
        for (int i = 0; i < posts.count ; i++) {
            Post *post = posts[i];
            
            NSMutableDictionary* coordDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[post.latitude stringValue],@"latitude",[post.longtitude stringValue],@"longitude", nil];
            
            NSMutableDictionary *annotationDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:coordDictionary,@"coordinates",@"name",@"name", nil];;
            self.postsAnnotationDictionary = annotationDictionary;
            
            self.postsAnnotation = [[ADBaseAnnotation alloc] initWithDictionary:self.postsAnnotationDictionary];
            self.postsAnnotation.post = post;
            self.postsAnnotation.type = @"postAnnotation";
            [self.map addClusteredAnnotation:self.postsAnnotation];
        }
        
        [self zoomToFitMapAnnotations:self.map];
    }];
}

- (void)getVibesMap{
    //- getting locations from server side (API)
    //- generating annotation that will be used in map
    [[Model sharedObject] getVibesOnMapForUser:self.user block:^(BOOL status, NSArray *array) {
        if (status) {
            for (int i = 0; i < array.count; i++) {
                
                NSString *latitude = [[array objectAtIndex:i] objectForKey:@"latitude"];
                NSString *longitude = [[array objectAtIndex:i] objectForKey:@"longitude"];
                NSString *score = [[array objectAtIndex:i] objectForKey:@"score"];
                
                NSMutableDictionary *coordDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys: latitude, @"latitude", longitude, @"longitude", nil];
                
                NSMutableDictionary *annotationDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:coordDictionary,@"coordinates",@"name",@"name", score, @"score", nil];
                self.vibesAnnotation.vibe = [annotationDictionary mutableCopy];
                self.vibesAnnotationDictionary = annotationDictionary;
                self.postsAnnotation.type = @"vibeAnnotation";
                self.vibesAnnotation = [[ADBaseAnnotation alloc] initWithDictionary:self.vibesAnnotationDictionary];
                [self.map addClusteredAnnotation:self.vibesAnnotation];
            }
            [self zoomToFitMapAnnotations:self.map];
        }
    }];
}

- (void)getVibesForPost:(Post*)post{
    //- getting list of comments for posts
    [[Model sharedObject] getVibesOnMapForPost:self.postMap block:^(BOOL status, NSArray *array) {
        if (status) {
            for (int i = 0; i < array.count; i++) {
                
                NSString *latitude = [[array objectAtIndex:i] objectForKey:@"latitude"];
                NSString *longitude = [[array objectAtIndex:i] objectForKey:@"longitude"];
                NSString *score = [[array objectAtIndex:i] objectForKey:@"score"];
                
                NSMutableDictionary *coordDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys: latitude, @"latitude", longitude, @"longitude", nil];
                
                NSMutableDictionary *annotationDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:coordDictionary,@"coordinates",@"name",@"name", score, @"score", nil];
                self.vibesAnnotation.vibe = [annotationDictionary mutableCopy];
                self.vibesAnnotationDictionary = annotationDictionary;
                self.postsAnnotation.type = @"vibeAnnotation";
                self.vibesAnnotation = [[ADBaseAnnotation alloc] initWithDictionary:self.vibesAnnotationDictionary];
                [self.map addClusteredAnnotation:self.vibesAnnotation];
            }
            [self zoomToFitMapAnnotations:self.map];
        }
    }];
}

- (void)clearAnnotation{
    [self.map removeAnnotations:self.map.annotations];
    [self zoomToFitMapAnnotations:self.map];
}

-(void)zoomToFitMapAnnotations:(MKMapView*)aMapView{
    if([aMapView.annotations count] == 0)
        return;

    [aMapView showAnnotations:aMapView.annotations animated:YES];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    // - creating and managing custom map annotation (pin)
    // - works as in Intsgram

    MKAnnotationView *annotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([ADBaseAnnotation class])];
    
    UIImageView* postImageView = (UIImageView*) [annotationView viewWithTag:1];
    UIImageView* bGImageView = (UIImageView*) [annotationView viewWithTag:2];
    
    if (!annotationView) {
     
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:NSStringFromClass([ADBaseAnnotation class])];
        annotationView.frame = CGRectMake(0, 0, 50, 50);
        
        bGImageView  = [[UIImageView alloc] init];
        bGImageView.tag = 2;
        bGImageView.frame = annotationView.frame;
        [annotationView addSubview:bGImageView];
        [annotationView sendSubviewToBack:bGImageView];
        
        postImageView = [[UIImageView alloc] init];
        postImageView.tag = 1;
        float annotationViewWidthHeight = annotationView.frame.size.width;
        postImageView.frame = CGRectMake(
                                        annotationViewWidthHeight/10,
                                        annotationViewWidthHeight/10,
                                        annotationViewWidthHeight - annotationViewWidthHeight/5,
                                        annotationViewWidthHeight - annotationViewWidthHeight/5
                                        
                                         );
        [annotationView addSubview:postImageView];
        [annotationView bringSubviewToFront:postImageView];
    }
    
    annotationView.canShowCallout = NO;
    
    postImageView.image = nil;
    bGImageView.image = nil;
    
    if ([annotation isKindOfClass:[ADBaseAnnotation class]]) {
        
        //post view
        
        ADBaseAnnotation *an = (ADBaseAnnotation*)annotation;
        if (an.post) {
            Post *post = an.post;
            Image *image = [post.images.allObjects firstObject];
            
            if (image.thumbnailUrl.length) {
                [[Model sharedObject] loadImage:image forPost:post block:^(Post *post) {
                    postImageView.image = nil;
                    bGImageView.image = self.onePhoto;
                    if (image.thumbnail)
                        postImageView.image = image.thumbnail;
                    else{
                        postImageView.image = self.widthoutPhoto;
                    }
                }];
                
            } else {
                
                bGImageView.image = self.widthoutPhoto;
                postImageView.image = nil;
            }
        }
        
        //comment view
        
        if (an.vibe){
            bGImageView.image = nil;
            if([[an.vibe objectForKey:@"score"] integerValue] == 1)
                NSLog(@"1");
            
            postImageView.image = [self makeSmileColorForType:[[an.vibe objectForKey:@"score"] integerValue]];
        }
        
    }

    return annotationView;
}

- (UIImage*)makeSmileColorForType:(NSUInteger)type {
    
    //choose image for comment view
    
    UIImage *image = [[UIImage alloc] init];
    
    switch (type) {
        case 2:{
            image = [UIImage imageNamed:@"explore3dLove"];
            break;
        }
        case 1:{
            image = [UIImage imageNamed:@"explore3dCry"];
            break;
        }
        case 0:{
            image = [UIImage imageNamed:@"explore3dNothing"];
            break;
        }
        case -1:{
            image = [UIImage imageNamed:@"explore3dSad"];
            break;
        }
        case -2:{
            image = [UIImage imageNamed:@"explore3dAngry"];
            break;
        }
        default:{
            image = nil;
            break;
        }
    }
    return image;
}


#pragma mark - ADClusterMapView Delegate

- (MKAnnotationView *)mapView:(TSClusterMapView *)mapView viewForClusterAnnotation:(id<MKAnnotation>)annotation {
    
    //Clustering annotation, group them in claster. Like in instagram
    
    TSDemoClusteredAnnotationView * annotationViewCluster = (TSDemoClusteredAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([TSDemoClusteredAnnotationView class])];
    
    ADClusterAnnotation *cluster = (ADClusterAnnotation *)annotation;
    
    NSUInteger count = cluster.clusterCount;
    
    UILabel *label = (UILabel*)[annotationViewCluster viewWithTag:1];
    UIImageView* countImageView = (UIImageView*) [annotationViewCluster viewWithTag:2];
    UIImageView* postImageView = (UIImageView*) [annotationViewCluster viewWithTag:3];
    UIImageView* bGImageView = (UIImageView*) [annotationViewCluster viewWithTag:4];
    
    if (!annotationViewCluster) {
        
        annotationViewCluster = [[TSDemoClusteredAnnotationView alloc] initWithAnnotation:annotation
                                                         reuseIdentifier:NSStringFromClass([TSDemoClusteredAnnotationView class])];
    

        annotationViewCluster.frame = CGRectMake(0, 0, 50, 50);
        
        bGImageView  = [[UIImageView alloc] init];
        bGImageView.tag = 4;
        bGImageView.frame = annotationViewCluster.frame;
        [annotationViewCluster addSubview:bGImageView];
        [annotationViewCluster sendSubviewToBack:bGImageView];
        
        countImageView = [[UIImageView alloc] init] ;
        countImageView.tag = 2;
        if (count > 9) {
            countImageView.frame = CGRectMake(annotationViewCluster.frame.size.width*3/4,-annotationViewCluster.frame.size.height/8,annotationViewCluster.frame.size.width*2/5,annotationViewCluster.frame.size.height/3);
            [countImageView setImage:[UIImage imageNamed:@"countBGBig"]];
        } else {
            countImageView.frame = CGRectMake(annotationViewCluster.frame.size.width*3/4,-annotationViewCluster.frame.size.height/8,annotationViewCluster.frame.size.width/3,annotationViewCluster.frame.size.height/3);
            [countImageView setImage:[UIImage imageNamed:@"countBGSmall"]];
        }
        [annotationViewCluster addSubview:countImageView];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,countImageView.frame.size.width,countImageView.frame.size.height)];
        label.tag = 1;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:13];
        label.textColor = [UIColor whiteColor];
        label.center = countImageView.center;
        label.text = [NSString stringWithFormat:@"%lu",(unsigned long)count];
        [annotationViewCluster addSubview:label];
        [annotationViewCluster bringSubviewToFront:label];
        
        
        postImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NewPostButtonFilter"]];
        postImageView.tag = 3;
        float wh = annotationViewCluster.frame.size.width;
   
        postImageView.frame = CGRectMake(9.0, 9.0, wh - 18.0, wh - 18.0);
        
        [annotationViewCluster addSubview:postImageView];
        [annotationViewCluster insertSubview:postImageView belowSubview:countImageView];
    }
    
    ADClusterAnnotation *claster = annotation;
    
    if (!claster.cluster)
        return annotationViewCluster;
    
    NSArray *annotations = claster.originalAnnotations;
    
    [self placeImagesForAnnotation:annotations];
    
    switch (count) {
        case 0:
            bGImageView.image = self.widthoutPhoto;                         break;
        case 1:
            bGImageView.image = self.onePhoto;                              break;
        case 2:
            bGImageView.image = self.twoPhoto;                              break;
        default:
            bGImageView.image = self.threeAndMorePhoto;                     break;
    }
    
    postImageView.image = nil;
    
    annotationViewCluster.frame = CGRectMake(0, 0, 50, 50);
    
    if (count >9) {
        countImageView.frame = CGRectMake(annotationViewCluster.frame.size.width*3/4,-annotationViewCluster.frame.size.height/8,annotationViewCluster.frame.size.width*2/5,annotationViewCluster.frame.size.height/3);
        [countImageView setImage:[UIImage imageNamed:@"countBGBig"]];
    } else {
        countImageView.frame = CGRectMake(annotationViewCluster.frame.size.width*3/4,-annotationViewCluster.frame.size.height/8,annotationViewCluster.frame.size.width/3,annotationViewCluster.frame.size.height/3);
        [countImageView setImage:[UIImage imageNamed:@"countBGSmall"]];
    }
    
    label.center = countImageView.center;
    label.text = [NSString stringWithFormat:@"%lu",(unsigned long)count];
    
    if ([annotations.firstObject isKindOfClass:[ADBaseAnnotation class]]) {
        
        ADBaseAnnotation *an = (ADBaseAnnotation*)claster.originalAnnotations.firstObject;
        Post *post = an.post;
        Image *image = [post.images.allObjects firstObject];
       
        if (image.thumbnailUrl.length) {
            [[Model sharedObject] loadImage:image forPost:post block:^(Post *post) {
                
                if (image.thumbnail)
                    postImageView.image = image.thumbnail;
                else
                    postImageView.image = self.widthoutPhoto;
            }];
            
        } else {
            postImageView.image = self.widthoutPhoto;
        }
    }

    return annotationViewCluster;
}

- (void)placeImagesForAnnotation:(NSArray*)annotations{
    
    __block NSInteger postsAnnotation = 0;
    __block NSInteger vibeAnnotations = 0;
    
    [annotations enumerateObjectsUsingBlock:^(ADBaseAnnotation *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[ADBaseAnnotation class]]) {
            if (obj.post.postId.stringValue.length>0) {
                postsAnnotation = postsAnnotation + 1;
            }else if([obj.vibe valueForKey:@"score"]){
                vibeAnnotations = vibeAnnotations + 1;
            }
        }
    }];
    
    self.onePhoto = self.threeAndMorePhoto = self.twoPhoto = self.widthoutPhoto = nil;
    
    if (postsAnnotation>0 && vibeAnnotations>0){
        self.onePhoto = self.widthoutPhoto = nil;
        self.threeAndMorePhoto = self.twoPhoto =  [UIImage imageNamed:@"postAndVibes"];
    }else if (vibeAnnotations>0){
        self.onePhoto = self.widthoutPhoto = nil;
        
        ADBaseAnnotation *an = annotations.firstObject;
        
        NSInteger score = -3;
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSString *scoreString = [NSString stringWithFormat:@"%@", [an.vibe valueForKey:@"score"]];
        NSNumber *myNumber = [f numberFromString:scoreString];
        
        score = myNumber.integerValue;
        
        __block BOOL egualScore = NO;
        
        [annotations enumerateObjectsUsingBlock:^(ADBaseAnnotation *obj, NSUInteger idx, BOOL *stop) {
            
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            NSString *scoreString = [NSString stringWithFormat:@"%@", [obj.vibe valueForKey:@"score"]];
            NSNumber *thisScore = [f numberFromString:scoreString];
            
            if (thisScore.integerValue == score)
                egualScore = YES;
            else{
                egualScore = NO;
                *stop = YES;
            }
        }];
        
        if (egualScore)
            self.threeAndMorePhoto = self.twoPhoto = [self makeSmileColorForType:score];
        else
            self.threeAndMorePhoto = self.twoPhoto = [UIImage imageNamed:@"manySmiles"];
            
    }else if (postsAnnotation>0){
        self.onePhoto = [UIImage imageNamed:@"onePhoto"];
        self.threeAndMorePhoto = [UIImage imageNamed:@"ThreeAndMorePhotos"];
        self.twoPhoto = [UIImage imageNamed:@"TwoPhotos"];
        self.widthoutPhoto = [UIImage imageNamed:@"WithoutPhoto"];
    }
}

#pragma mark -

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    //select annotation
    
    if ([view.annotation isKindOfClass:[MKUserLocation class]] || [view.annotation isKindOfClass:[ADClusterAnnotation class]])
        return;
    
    ADBaseAnnotation *anotation = nil;
    if ([view.annotation isKindOfClass:[ADBaseAnnotation class]]) {
        anotation = view.annotation;
    }else if ([view.annotation isKindOfClass:[ADClusterAnnotation class]]) {
       
        ADClusterAnnotation *claster = view.annotation;
        if (!claster.cluster)
            return;
        
        NSArray *annotations = claster.originalAnnotations;
        anotation = (ADBaseAnnotation*)annotations.firstObject;
    }else{
        return;
    }
    
    Post *post = anotation.post;
    Image *image = post.images.allObjects.firstObject;

    if (!image)
        return;
    
    self.imageBackground = [[UIView alloc] initWithFrame:self.view.bounds];
    self.imageBackground.backgroundColor = [UIColor blackColor];
    self.imageBackground.userInteractionEnabled = NO;
    self.imageBackground.alpha = 0.;
    [self.view addSubview:self.imageBackground];

    self.imageOnClick = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 0, 0)];
    self.imageOnClick.image = image.thumbnail;
    self.imageOnClick.userInteractionEnabled = YES;
    [self.view addSubview:self.imageOnClick];
    [UIView animateWithDuration:0.2f animations:^{
        
        self.imageOnClick.frame = CGRectMake(10, self.view.frame.size.height/2-(self.view.frame.size.width-20)/2, self.view.frame.size.width-20, self.view.frame.size.width-20);
        self.imageBackground.alpha = 0.5;
        
    }completion:nil];
    [self.imageOnClick.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [self.imageOnClick.layer setBorderWidth: 4.0];
    
    self.tapGestureRecognizer.enabled = YES;
}


#pragma mark - Button Actions

-(void)hideImage {
   
    if (self.imageOnClick){
        self.tapGestureRecognizer.enabled = NO;
        [UIView animateWithDuration:0.2f animations:^{
            self.imageOnClick.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 0, 0);
            self.imageBackground.alpha = 0.;
        }completion:^(BOOL finished) {
            [self.imageOnClick removeFromSuperview];
            [self.imageBackground removeFromSuperview];
        }];
    }
}

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
