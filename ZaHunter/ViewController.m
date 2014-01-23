//
//  ViewController.m
//  ZaHunter
//
//  Created by Kagan Riedel on 1/22/14.
//  Copyright (c) 2014 Kagan Riedel. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, UIActionSheetDelegate>
{
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    NSArray *pizzaResults;
    __weak IBOutlet UITableView *pizzaTableView;
    NSTimeInterval totalPizzaingTime;
    UILabel *myFooterView;
    __weak IBOutlet UISegmentedControl *segmentedControl;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    segmentedControl.tintColor = [UIColor orangeColor];
    
    
    pizzaResults = [NSArray new];
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    
    myFooterView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 300)]; //not sure why I had to set this.
    
    pizzaTableView.tableFooterView = myFooterView;
    [myFooterView setFont:[UIFont fontWithName:@"modius'pizzatype'" size:30]];
    [myFooterView setTextColor:[UIColor redColor]];
    myFooterView.numberOfLines = 0;
}


-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    UIActionSheet *sheet = [UIActionSheet new];
    sheet.title = @"Can't find your location";
    [sheet addButtonWithTitle:@"OK"];
    sheet.delegate = self;
    [sheet showInView:self.view];
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations)
    {
        if (location.verticalAccuracy > 1000 || location.horizontalAccuracy > 1000)
        {
            continue;
        }
        currentLocation = location;
        [locationManager stopUpdatingLocation];
        break;
    }
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    CLLocationCoordinate2D coordinate = [currentLocation coordinate];
    request.region = MKCoordinateRegionMake(coordinate, span);
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
     {
         pizzaResults = response.mapItems;
         pizzaResults = [pizzaResults sortedArrayUsingComparator:^NSComparisonResult(MKMapItem* obj1, MKMapItem* obj2)
                         {
                             return [currentLocation distanceFromLocation:obj1.placemark.location] - [currentLocation distanceFromLocation:obj2.placemark.location];
                         }];
        pizzaResults = [pizzaResults subarrayWithRange:NSMakeRange(0, 4)];
         
        [pizzaTableView reloadData];
         [self getTotalEatingTime:MKDirectionsTransportTypeWalking];
     }];
}

- (IBAction)onChangeSegmentedControl:(UISegmentedControl *)sender
{
    totalPizzaingTime = 0;
    if (sender.selectedSegmentIndex == 0)
    {
        [self getTotalEatingTime:MKDirectionsTransportTypeWalking];
    } else if (sender.selectedSegmentIndex == 1)
    {
        [self getTotalEatingTime:MKDirectionsTransportTypeAutomobile];
    }
}

-(void)getTotalEatingTime:(MKDirectionsTransportType)transportType
{
    MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
    for (MKMapItem *result in pizzaResults) {
        MKDirectionsRequest *request = [MKDirectionsRequest new];
        request.transportType = transportType;
        request.source = source;
        request.destination = result;
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error)
         {
             MKRoute *route = response.routes.firstObject;
             totalPizzaingTime += route.expectedTravelTime/60 + 50;
             myFooterView.text = [NSString stringWithFormat:@"Your total pizzaing time is: %i minutes",(int)totalPizzaingTime];
         }];
        source = result;
    }
}

#pragma mark UITableViewDelegate & Datasource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZaCell"];
    MKMapItem *pizzaResult = [pizzaResults objectAtIndex:indexPath.row];
    cell.textLabel.text = pizzaResult.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%f",[currentLocation distanceFromLocation:pizzaResult.placemark.location] ];
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return pizzaResults.count;
}



@end
