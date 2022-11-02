#include "OspishLib.mq4"

//+------------------------------------------------------------------+
// Calculate open positions
// returns orders number (negative if short)
//+------------------------------------------------------------------+
string orderInfo(string type = "count") {
    int buys = 0, sells = 0;
    double buyVol = 0.0, sellVol = 0.0;

    // Loop through orders
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) break;

        if (OrderSymbol() == Symbol()) {
            if (OrderType() == OP_BUY) {
                buys++;
                buyVol += OrderLots();
            }
            if (OrderType() == OP_SELL) {
                sells++;
                sellVol += OrderLots();
            }
        }
    }

    if (type == "count")
        return "Buy "+(string)buys + " " + "Sell "+(string)sells;

    if (type == "volume")
        return "Buy "+(string)buyVol + " " + "Sell "+(string)sellVol;


    return "";
}

//
// start function - executed every tick
//
int loopcount = 0;
void start() {
    string orderCount = "", orderVolume = "";
    int chartID = 0;

    loopcount++;
    //Print("Loopcount: " + loopcount);

    if (loopcount % 2 == 0) {
        orderCount = orderInfo("count");
        orderVolume = orderInfo("volume");

        if ( ObjectFind(chartID, "EA_orderCount_label") >= 0 ) {
            ObjectDelete(chartID, "EA_orderCount_label");
            ObjectDelete(chartID, "EA_orderCount_value");
        }
        if ( ObjectFind(chartID, "EA_orderVolume_label") >= 0 ) {
            ObjectDelete(chartID, "EA_orderVolume_label");
            ObjectDelete(chartID, "EA_orderVolume_value");
        }
        if ( ObjectFind(chartID, "Evacuate") >= 0 ) {
            ObjectDelete(chartID, "Evacuate");
        }

        LabelCreate("EA_orderCount_label", "Orders: ", 200, 20, "Source Code Pro Black", 11);
        LabelCreate("EA_orderCount_value", orderCount, 270, 22, "Source Code Pro");
        LabelCreate("EA_orderVolume_label", "Volume: ", 200, 40, "Source Code Pro Black", 11);
        LabelCreate("EA_orderVolume_value", orderVolume, 270, 42, "Source Code Pro");

        ButtonCreate("Evacuate", 200, 70, 80, 30, "Evacuate");

        Print("Labels updated");
    }

    Sleep(500);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
  string buttonID="Evacuate";
//--- Check the event by pressing a mouse button
   if(id==CHARTEVENT_OBJECT_CLICK) {
      string clickedChartObject=sparam;
      //--- If you click on the object with the name buttonID
      if(clickedChartObject==buttonID) {

         //--- State of the button - pressed or not
         bool selected=ObjectGetInteger(0,buttonID,OBJPROP_STATE);
         //--- log a debug message
         Print("Evacuating...");
         PlaySound("expert.wav");
         CloseOrders();

        }
      ChartRedraw();// Forced redraw all chart objects
     }
}
