import 'package:flutter/material.dart';



class OrderComplete extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 22.0,),

            Text("Order Has Been Completed " ,  style: TextStyle(fontSize: 16.0),),

            SizedBox(height: 22.0,),

            Divider(thickness: 4.0,),

            SizedBox(height: 16.0,),


            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: RaisedButton(
                onPressed: () async
                {
                  Navigator.pop(context,"close");

                },
                color: Colors.amber,
                child: Padding(
                  padding: EdgeInsets.all(17.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("close", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),),
                      Icon(Icons.close, color: Colors.white, size: 26.0,),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 30.0,),
          ],
        ),
      ),
    );
  }
}


