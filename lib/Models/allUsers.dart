import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Users{
  String id;
  String email;
  String firstname;
  String lastname;
  String phone;
  String shoplocation;
  String shopname;

  Users({this.id, this.email, this.firstname, this.lastname, this.phone, this.shoplocation,this.shopname});

  Users.fromSnapshot(DataSnapshot dataSnapshot){
    id = dataSnapshot.key;
    email = dataSnapshot.value["email"];
    firstname = dataSnapshot.value["first_name"];
    lastname = dataSnapshot.value["last_name"];
    phone = dataSnapshot.value["phone"];
    shoplocation = dataSnapshot.value["shop_location"];
    shopname = dataSnapshot.value["shop_name"];
  }


}