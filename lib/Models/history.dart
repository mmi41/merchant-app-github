import 'package:firebase_database/firebase_database.dart';

class History
{
  String shopName;
  String createdAt;
  String status;
  String dropOff;
  String pickup;

  History({this.shopName, this.createdAt, this.status, this.dropOff, this.pickup});

  History.fromSnapshot(DataSnapshot snapshot)
  {
    shopName = snapshot.value["shop_name"];
    createdAt = snapshot.value["created_at"];
    status = snapshot.value["status"];
    dropOff = snapshot.value["dropoff_location"];
    pickup = snapshot.value["shop_location"];
  }
}