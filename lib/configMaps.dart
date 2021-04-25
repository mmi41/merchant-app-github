import 'package:firebase_auth/firebase_auth.dart';
import 'package:merchant_app/Models/allUsers.dart';

String mapKey= "AIzaSyD_bnDNR4cR_iqeLpfDCA5e9sNQBG4m48g";

User firebaseUser;

Users userCurrentInfo;

String serverToken = "key=AAAAwToWVHo:APA91bHH-_MSvnUn5iw5Jt2rrb1nCrs1ttIl1RdMW967iuWpzFkNBuT8ayN3DQwEpkRd8rNVVNY8Q_mwO7zRk6fDEh0T0DIhh_yszNFokYsmcid2_qV7-69MLAtgFJdPufFcYpbwA6Fh";

int driverRequestTimeOut = 30;

String statusRide = "";

String vehicleDetailsDriver = "";

String driverFirstName = "";

String driverLastName = "";

String driverPhone = "";

String rideStatus ="Driver is on the way!";

double starCounter = 0.0;

String title = "";

