import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:merchant_app/AllScreens/loginScreen.dart';
import 'package:merchant_app/AllScreens/mainscreen.dart';
import 'package:merchant_app/AllWidgets/progressDialog.dart';
import 'package:merchant_app/main.dart';

class RegistrationScreen extends StatelessWidget {

  TextEditingController firstnameTextEditingController = TextEditingController();
  TextEditingController lastnameTextEditingController = TextEditingController();
  TextEditingController shopnameTextEditingController = TextEditingController();
  TextEditingController shoplocationTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();



  static const String idScreen = "register";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(height: 30.0, ),
              Image(
                image: AssetImage("images/store.png"),
                width: 500.0,
                height: 350.0,
                alignment: Alignment.center,
              ),
              SizedBox(height: 1.0, ),
              Text(
                "Merchant Registration",
                style: TextStyle(fontSize: 24.0),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 1.0, ),
                    TextField(
                      controller: firstnameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "First Name",
                        labelStyle: TextStyle(fontSize: 20.0),
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 30.0,),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0, ),
                    TextField(
                      controller: lastnameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Last Name",
                        labelStyle: TextStyle(fontSize: 20.0),
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 30.0,),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0, ),
                    TextField(
                      controller: shopnameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Shop Name",
                        labelStyle: TextStyle(fontSize: 20.0),
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 30.0,),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0, ),
                    TextField(
                      controller: shoplocationTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Shop Location",
                        labelStyle: TextStyle(fontSize: 20.0),
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 30.0,),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0, ),
                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        labelStyle: TextStyle(fontSize: 20.0),
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 30.0,),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0, ),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(fontSize: 20.0),
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 30.0,),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 1.0, ),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(fontSize: 20.0),
                        hintStyle: TextStyle(color: Colors.blue, fontSize: 30.0,),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),

                    SizedBox(height: 20.0, ),
                    RaisedButton(
                      color: Colors.amber,
                      child: Container(
                        height: 50.0,
                        child: Center(
                          child: Text(
                              "Register Account",
                              style: TextStyle(fontSize: 18.0,)
                          ),
                        ),
                      ),
                      shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(24.0),
                      ),
                      onPressed: (){
                        if(phoneTextEditingController.text.length <8)
                        {
                          displayToastMessage("Phone number must be 8 digits", context);
                        }
                        else if(!emailTextEditingController.text.contains("@"))
                        {
                          displayToastMessage("Invalid Email Address", context);
                        }
                        else if(firstnameTextEditingController.text.isEmpty)
                        {
                          displayToastMessage("First Name is Required", context);
                        }
                        else if(lastnameTextEditingController.text.isEmpty)
                        {
                          displayToastMessage("Last Name is Required", context);
                        }
                        else if(shopnameTextEditingController.text.isEmpty)
                        {
                          displayToastMessage("Shop Name is Required", context);
                        }
                        else if(shoplocationTextEditingController.text.isEmpty)
                        {
                          displayToastMessage("Shop Location is Required", context);
                        }
                        else if(passwordTextEditingController.text.length <6)
                        {
                          displayToastMessage("Password number must be atleast 6 characters", context);
                        }
                        else
                        {
                          registerNewUser(context);
                        }
                      },
                    ),

                  ],
                ) ,
              ),
              FlatButton(onPressed:(){
                Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
              } ,
                child: Text(
                    "Already Have An Account? Login Here!",
                    style: TextStyle(fontSize: 18.0,)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(message: "Registering, Please Wait...",);
        }
    );

    final User firebaseUser = (await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text
    ).catchError((errMsg){
      Navigator.pop(context);
      displayToastMessage("Error:" + errMsg.toString(), context);
    })).user;
    if (firebaseUser != null)
    {
      Map userDataMap = {
        "first_name": firstnameTextEditingController.text.trim(),
        "last_name": lastnameTextEditingController.text.trim(),
        "shop_name": shopnameTextEditingController.text.trim(),
        "shop_location": shoplocationTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
      };

      usersRef.child(firebaseUser.uid).set(userDataMap);
      displayToastMessage("Account has been created successfully!", context);
      Navigator.pushNamedAndRemoveUntil(context, MainScreen.idScreen, (route) => false);
    }
    else
    {
      Navigator.pop(context);
      displayToastMessage("Account has not been created", context);
    }
  }
}

displayToastMessage(String message, BuildContext context){
  Fluttertoast.showToast(msg: message);

}
