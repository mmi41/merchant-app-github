import 'package:flutter/material.dart';
import 'package:merchant_app/Assistants%20/assistantMethods.dart';
import 'package:merchant_app/Models/history.dart';

class HistoryItem extends StatelessWidget
{
  final History history;
  HistoryItem({this.history});

  @override
  Widget build(BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                child: Row(
                  children: <Widget>[

                    Image.asset('images/store.png', height: 16, width: 16,),
                    SizedBox(width: 2,),
                    Expanded(child: Container(child: Text(history.shopName, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15),))),
                    SizedBox(width: 10,),

                    Image.asset('images/pickicon.png', height: 16, width: 16,),
                    SizedBox(width: 2,),
                    Expanded(child: Container(child: Text(history.pickup, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15),))),
                    SizedBox(width: 5,),

                  ],
                ),
              ),

              SizedBox(height: 10,),

              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Text("Delivered to: ", style: TextStyle(fontSize: 15.0),),
                  SizedBox(width: 80,),
                  Image.asset('images/desticon.png', height: 16, width: 16,),
                  SizedBox(width: 5,),

                  Text(history.dropOff, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15),),
                ],
              ),

              SizedBox(height: 5,),

              Text(AssistantMethods.formatTripDate(history.createdAt), style: TextStyle(color: Colors.grey),),
            ],
          ),
        ],
      ),
    );
  }
}
