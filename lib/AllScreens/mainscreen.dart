import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:merchant_app/AllScreens/HistoryScreen.dart';
import 'package:merchant_app/AllScreens/profileTabPage.dart';
import 'package:merchant_app/AllScreens/ratingScreen.dart';
import 'package:merchant_app/AllScreens/searchScreen.dart';
import 'package:merchant_app/AllWidgets/Divider.dart';
import 'package:merchant_app/AllWidgets/noDriverAvailableDialog.dart';
import 'package:merchant_app/AllWidgets/progressDialog.dart';
import 'package:merchant_app/Assistants%20/assistantMethods.dart';
import 'package:merchant_app/Assistants%20/geoFireAssistant.dart';
import 'package:merchant_app/DataHandler/appData.dart';
import 'package:merchant_app/Models/directDetails.dart';
import 'package:merchant_app/Models/nearbyAvailableDrivers.dart';
import 'package:merchant_app/configMaps.dart';
import 'package:provider/provider.dart';
import 'package:merchant_app/AllWidgets/orderComplete.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'loginScreen.dart';


class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set <Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set <Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double driverDetailsContainerHeight  = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference rideRequestRef;

  List<NearbyAvailableDrivers> availableDrivers;

  String state = "normal";

  StreamSubscription<Event> rideStreamSubscription;

  bool isRequestingPositionDetails = false;

  String uFirstName = "";
  String uLastName = "";




  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Delivery Requests").push();

    var pickUp = Provider
        .of<AppData>(context, listen: false)
        .pickUpLocation;
    var dropOff = Provider
        .of<AppData>(context, listen: false)
        .dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),

    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),

    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "merchant_first_name": userCurrentInfo.firstname,
      "merchant_last_name": userCurrentInfo.lastname,
      "shop_name": userCurrentInfo.shopname,
      "merchant_phone_number": userCurrentInfo.phone,
      "shop_location": pickUp.placeName,
      "dropoff_location": dropOff.placeName,

    };
    rideRequestRef.set(rideInfoMap);

    rideStreamSubscription = rideRequestRef.onValue.listen((event) async {
      if(event.snapshot.value == null){
        return;
      }
      if(event.snapshot.value["vehicle_details"] != null)
      {
        setState(() {
          vehicleDetailsDriver = event.snapshot.value["vehicle_details"].toString();
        });
      }
      if(event.snapshot.value["driver_first_name"] != null)
      {
        setState(() {
          driverFirstName = event.snapshot.value["driver_first_name"].toString();
        });
      }
      if(event.snapshot.value["driver_last_name"] != null)
      {
        setState(() {
          driverLastName = event.snapshot.value["driver_last_name"].toString();
        });
      }
      if(event.snapshot.value["driver_phone"] != null)
      {
        setState(() {
          driverPhone = event.snapshot.value["driver_phone"].toString();
        });
      }
      if(event.snapshot.value["driver_location"] != null)
      {
        double driverLat = double.parse(event.snapshot.value["driver_location"]["latitude"].toString());
        double driverLng = double.parse(event.snapshot.value["driver_location"]["longitude"].toString());
        LatLng driverCurrentLocation = LatLng (driverLat, driverLng);
        if(statusRide == "accepted")
        {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        }
        else if(statusRide == "onride")
        {
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        }
        else if(statusRide == "arrived")
        {
          setState(() {
            rideStatus = "Delivering to Customer ";
          });
        }
      }
      if(event.snapshot.value["status"] != null)
      {
        statusRide = event.snapshot.value["status"].toString();
      }
      if(statusRide == "accepted") {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofileMarker();
      }
      if(statusRide == "ended") {
        //OrderComplete();
        var res = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => OrderComplete(),
        );

        String driverId = "";

        if (res=="close"){
          if(event.snapshot.value["driver_id"] != null){
            driverId =event.snapshot.value["driver_id"].toString();
          }

          Navigator.of(context).push(MaterialPageRoute(builder: (context) => RatingScreen(driverId: driverId)));

          rideRequestRef.onDisconnect();
          rideRequestRef = null;
          rideStreamSubscription.cancel();
          rideStreamSubscription = null;
          resetApp();
        }

      }


    });
  }

  void deleteGeofileMarker(){
    setState(() {
      markersSet.removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }
  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async
  {
    if(isRequestingPositionDetails == false)
    {
      isRequestingPositionDetails = true;

      var positionUserLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);
      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, positionUserLatLng);
      if(details == null)
      {
        return;
      }
      setState(() {
        rideStatus = "Driver is on the way! - " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async
  {
    if(isRequestingPositionDetails == false)
    {
      isRequestingPositionDetails = true;

      var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffUserLatLng = LatLng(dropOff.latitude, dropOff.longitude);

      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, dropOffUserLatLng);
      if(details == null)
      {
        return;
      }
      setState(() {
        rideStatus = "Driver completed  the order !";
      });

      isRequestingPositionDetails = false;
    }
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
    //setState(() {
      //state = "normal";
    //});
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  void  displayDriverDetailsContainer(){
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 290.0;
      driverDetailsContainerHeight  = 350.0;
    });

  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;
      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();

      statusRide ="";
      driverFirstName ="";
      driverLastName='';
      driverPhone="";
      vehicleDetailsDriver="";
      rideStatus ="Driver is on the way!";
      driverDetailsContainerHeight = 0.0;
    });
    locatePosition();
  }


  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 240.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }


  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
    LatLng latLatPosition = LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition = new CameraPosition(
        target: latLatPosition, zoom: 14);
    newGoogleMapController.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition));
    String address = await AssistantMethods.searchCoordinateAddress(
        position, context);
    print("This is your Address:: " + address);

    initGeoFireListner();

    uFirstName = userCurrentInfo.firstname;
    uLastName = userCurrentInfo.lastname;

    AssistantMethods.retrieveHistoryInfo(context);

  }


  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        color: Colors.white,
        width: 290.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/user_icon.png", height: 55.0, width: 55.0,),
                      SizedBox(width: 16.0,),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(uFirstName +" "+uLastName , style: TextStyle(
                              fontSize: 16.0, color: Colors.amber),),
                          SizedBox(height: 6.0,),
                          GestureDetector(

                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileTabPage()));
                              },

                              child: Text("View Profile")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(height: 12.0,),
              ListTile(
                leading: Icon(Icons.history),
                title: GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>HistoryScreen()));
                  },
                  child: Text(
                    "Orders History", style: TextStyle(fontSize: 16.0),),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: GestureDetector(

                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileTabPage()));
                  },

                    child: Text("Visit Profile", style: TextStyle(fontSize: 16.0),)),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.arrow_back),
                  title: Text("Sign Out", style: TextStyle(fontSize: 16.0),),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              setState(() {
                bottomPaddingOfMap = 300.0;
              });
              locatePosition();
            },

          ),

          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState.openDrawer();
                }
                else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),
                      Text(
                        "Hello Merchant!", style: TextStyle(fontSize: 18.0),),
                      Text("Where would you like to send the order?",
                        style: TextStyle(fontSize: 20.0),),
                      SizedBox(height: 20.0),

                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));
                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.amber,),
                                SizedBox(width: 10.0,),
                                Text("Select Customer's Location"),
                              ],
                            ),
                          ),

                        ),
                      ),
                      SizedBox(height: 24.0),
                      Row(
                        children: [
                          Icon(Icons.store, color: Colors.red,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  Provider
                                      .of<AppData>(context)
                                      .pickUpLocation != null
                                      ? Provider
                                      .of<AppData>(context)
                                      .pickUpLocation
                                      .placeName
                                      : "Add your shop location"
                              ),
                              SizedBox(height: 4.0,),
                              Text(" Your Shop Location ",
                                style: TextStyle(
                                    fontSize: 13.0, color: Colors.black54),)
                            ],
                          ),

                        ],
                      ),
                      SizedBox(height: 10.0),
                      DividerWidget(),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Icon(Icons.store, color: Colors.red,),
                          SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Second Shop Location"),
                              SizedBox(height: 4.0,),
                              Text("Second Shop Location",
                                style: TextStyle(
                                    fontSize: 13.0, color: Colors.black54),)
                            ],
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),

                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.amber,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset(
                                "images/driver_moto1.png", height: 70.0,
                                width: 80.0,),
                              SizedBox(width: 16.0,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Driver",
                                    style: TextStyle(fontSize: 15.0),),
                                  Text(((tripDirectionDetails != null)
                                      ? tripDirectionDetails.distanceText
                                      : ""), style: TextStyle(
                                      fontSize: 15.0, color: Colors.black),),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0,),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckAlt, size: 18.0,
                              color: Colors.black,),
                            SizedBox(height: 1.0,),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.0,),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: RaisedButton(
                          onPressed: () {

                            displayRequestRideContainer();
                            availableDrivers = GeoFireAssistant.nearByAvailableDriversList;
                            searchNearestDriver();
                          },
                          color: Colors.orange,
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Request Driver", style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),),
                                Icon(FontAwesomeIcons.motorcycle,
                                  color: Colors.white, size: 26.0,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(height: 12.0,),

                    SizedBox(
                      width: double.infinity,
                      child: ColorizeAnimatedTextKit(
                        onTap: () {
                          print(" Tap Event");
                        },
                        text: [
                          "Finding a Driver!",
                          "Please Wait... ",
                        ],
                        textStyle: TextStyle(
                          fontSize: 35.0,
                        ),
                        colors: [
                          Colors.amber,
                          Colors.orange,
                        ],
                        textAlign: TextAlign.center,
                        alignment: AlignmentDirectional.topStart,
                      ),

                    ),
                    SizedBox(height: 22.0,),

                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(width: 2.0, color: Colors.black),
                        ),
                        child: Icon(Icons.close, size: 26.0,),
                      ),
                    ),
                    SizedBox(height: 10.0,),
                    Container(
                      width: double.infinity,
                      child: Text("Cancel Request", textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: driverDetailsContainerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(rideStatus,textAlign: TextAlign.center, style: TextStyle(fontSize: 20.0),),

                      ],
                    ),
                    SizedBox(height: 22.0,),
                    Divider(height: 2.0,thickness: 2.0,),
                    Text(vehicleDetailsDriver,style: TextStyle(color: Colors.grey,fontSize: 17.0),),
                    Text(driverFirstName+" "+driverLastName,style: TextStyle(fontSize: 20.0),),
                    SizedBox(height: 22.0,),
                    Divider(height: 2.0,thickness: 2.0,),
                    SizedBox(height: 22.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: RaisedButton(
                            shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(24.0),
                            ),
                            onPressed: () async
                            {
                              launch(('tel://${driverPhone}'));
                            },
                            color: Colors.black87,
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text("Call Driver   ", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                  Icon(Icons.call, color: Colors.white, size: 26.0,),
                                ],
                              ),
                            ),
                          ),
                        ),

                      ],

                    ),


                  ],
                ),
              ),

            ),
          ),


        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos = Provider
        .of<AppData>(context, listen: false)
        .pickUpLocation;
    var finalPos = Provider
        .of<AppData>(context, listen: false)
        .dropOffLocation;
    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Please wait...",)
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });
    Navigator.pop(context);
    print("This is the encoded points ::");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List <PointLatLng> decodedPolyLinePointsResult = polylinePoints
        .decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(
            LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    }

    else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    }

    else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    }

    else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController.animateCamera(
        CameraUpdate.newLatLngBounds(latLngBounds, 70));


    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: InfoWindow(
          title: initialPos.placeName, snippet: "  My Shop Location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
          title: finalPos.placeName, snippet: "DropOff Location"),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
        fillColor: Colors.yellow,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.yellowAccent,
        circleId: CircleId("pickUpId")

    );

    Circle dropOffLocCircle = Circle(
        fillColor: Colors.deepPurple,
        center: dropOffLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple,
        circleId: CircleId("dropOffId")

    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  void initGeoFireListner() {
    Geofire.initialize("availableDrivers");

    Geofire.queryAtLocation(
        currentPosition.latitude, currentPosition.longitude, 15).listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.nearByAvailableDriversList.add(
                nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();

            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();

            break;
        }
      }

      setState(() {});
    });
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });
    Set <Marker> tMarkers = Set <Marker>();
    for (NearbyAvailableDrivers driver in GeoFireAssistant
        .nearByAvailableDriversList) {
      LatLng driverAvailablePosition = LatLng(
          driver.latitude, driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvailablePosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        rotation: AssistantMethods.createRandomNumber(360),
      );
      tMarkers.add(marker);
    }
    setState(() {
      markersSet = tMarkers;
    });
  }

  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverAvailableDialog()
    );
  }

  void searchNearestDriver() {
    if (availableDrivers.length == 0) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers[0];
    notifyDriver(driver);
    availableDrivers.removeAt(0);
  }

  void notifyDriver(NearbyAvailableDrivers driver) {
    driversRef.child(driver.key).child("newRide").set(rideRequestRef.key);

    driversRef.child(driver.key).child("token").once().then((
        DataSnapshot snap) {
      if (snap.value != null) {
        String token = snap.value.toString();
        AssistantMethods.sendNotificationToDriver(
            token, context, rideRequestRef.key);
      }
      //else{
        //return;
      //}
      //const oneSecondPassed = Duration(seconds: 1);
      //var timer = Timer.periodic(oneSecondPassed, (timer) {
        //if(state != "requesting")
        //{
          //driversRef.child(driver.key).child("newRide").set("cancelled");
          //driversRef.child(driver.key).child("newRide").onDisconnect();
          //driverRequestTimeOut = 30;
          //timer.cancel();
        //}

        //driverRequestTimeOut = driverRequestTimeOut - 1;

        //driversRef.child(driver.key).child("newRide").onValue.listen((event) {
          //if(event.snapshot.value.toString() == "accepted")
          //{
            //driversRef.child(driver.key).child("newRide").onDisconnect();
            //driverRequestTimeOut = 30;
            //timer.cancel();
          //}
        //});

        //if(driverRequestTimeOut == 0)
        //{
          //driversRef.child(driver.key).child("newRide").set("timeout");
          //driversRef.child(driver.key).child("newRide").onDisconnect();
          //driverRequestTimeOut = 30;
          //timer.cancel();

          //searchNearestDriver();
        //}
      //});
    });
  }
}
