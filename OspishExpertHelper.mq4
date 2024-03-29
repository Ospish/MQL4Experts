#include "OspishLib.mq4"

input int Reserve = 0;

//+------------------------------------------------------------------+
// Calculate open positions
// returns orders number (negative if short)
//+------------------------------------------------------------------+
string orderInfo(string type = "count") {
    string buyStr, sellStr;
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

    buyStr = getString(buyVol);
    sellStr = getString(sellVol);

    if (type == "countBuy")
        return buys;

    if (type == "countSell")
        return sells;

    if (type == "volumeBuy")
        return NormalizeDouble(buyVol, 2);

    if (type == "volumeSell")
        return NormalizeDouble(sellVol, 2);

    if (type == "volumeBuyStr")
        return buyStr;

    if (type == "volumeSellStr")
        return sellStr;

    if (type == "safeVolume")
        return NormalizeDouble(AccountEquity() / 2000, 2);

    if (type == "riskEquity")
        return MathAbs((buyVol-sellVol) / (AccountEquity() / 2000));

    if (type == "riskBalance")
        return MathAbs((buyVol-sellVol) / (AccountBalance() / 2000));

    return "";
}

//
// start function - executed every tick
//
int loopcount = 0;
void start() {
    string riskResult, orderVolumeBuy, orderVolumeSell, rule1Text, rule2Text, rule3Text, rule1Font, rule2Font, font, fontBold = "";
    int chartID, chartHeight, orderCountBuy, orderCountSell = 0;
    double safeVolume, riskEquity, riskBalance = 0.0;
    color riskColor, orderCountColor, orderVolumeColor, rule1Color, rule2Color;

    loopcount++;
    //Print("Loopcount: " + loopcount);

    if (loopcount % 2 == 0) {
        orderCountBuy = orderInfo("countBuy");
        orderCountSell = orderInfo("countSell");
        orderVolumeBuy = orderInfo("volumeBuy");
        orderVolumeSell = orderInfo("volumeSell");
        safeVolume = orderInfo("safeVolume");
        riskEquity = orderInfo("riskEquity");
        riskBalance = orderInfo("riskBalance");
        rule1Text = "1. No Adding Below 3000% (" + NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2) + ")";
        rule2Text = "2. Have Reserve (" + Reserve + ")";
        rule3Text = "3. No Deposit After Margin Call";
        font = "Source Code Pro";
        fontBold = "Source Code Pro Black";
        chartHeight = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
        riskColor = clrGreen;
        rule1Color = rule2Color = orderCountColor = clrBlack;
        rule1Font = rule2Font = fontBold;

        if (riskEquity > riskBalance)
            riskResult = NormalizeDouble(riskEquity, 2) + "x ("+ NormalizeDouble(riskBalance, 2)+"x)";
        else riskResult = NormalizeDouble(riskBalance, 2);

        if (riskResult > 1)
            riskColor = clrGoldenrod;
        if (riskResult >= 2)
            riskColor = clrRed;

        if (AccountEquity() / AccountMargin() * 100 < 3000) {
            rule1Color = clrRed;
            rule1Font = fontBold;
        }

        if (Reserve == 0) {
            rule2Color = clrRed;
            rule2Font = fontBold;
        }

        int orderCountResult = orderCountBuy-orderCountSell;
        if (orderCountResult < 0)
            orderCountColor = clrRed;
        if (orderCountResult > 0)
            orderCountColor = clrBlue;
        orderCountResult = MathAbs(orderCountResult);

        string orderVolumeResult = (double)orderVolumeBuy - (double)orderVolumeSell;
        if (orderVolumeResult < 0)
            orderVolumeColor = clrRed;
        if (orderVolumeResult > 0)
            orderVolumeColor = clrBlue;
        orderVolumeResult = getString(MathAbs(orderVolumeResult));

        orderVolumeBuy = getString(orderVolumeBuy);
        orderVolumeSell = getString(orderVolumeSell);

        RefreshLabel("EA_orderCount_label", "Orders: ", 200, 20, fontBold, 11, clrBlack);
        RefreshLabel("EA_orderCount_value1", orderCountBuy, 270, 22, font, 10, clrBlue);
        RefreshLabel("EA_orderCount_value2", orderCountSell, 310, 22, font);
        RefreshLabel("EA_orderCount_value3", orderCountResult, 350, 22, fontBold, 10, orderCountColor);
        RefreshLabel("EA_orderVolume_label", "Volume: ", 200, 40, fontBold, 11, clrBlack);
        RefreshLabel("EA_orderVolume_value1", orderVolumeBuy, 270, 42, font, 10, clrBlue);
        RefreshLabel("EA_orderVolume_value2", orderVolumeSell, 310, 42, font);
        RefreshLabel("EA_orderVolume_value3", orderVolumeResult, 350, 42, fontBold, 10, orderVolumeColor);
        RefreshLabel("EA_safeVolume_label", "Safe Volume: ", 200, 60, fontBold, 11, clrBlack);
        RefreshLabel("EA_safeVolume_value", safeVolume, 315, 62, fontBold, 10, clrBlack);
        RefreshLabel("EA_risk_label", "Risk: ", 200, 80, fontBold, 11, clrBlack);
        RefreshLabel("EA_risk_value", riskResult, 250, 82, fontBold, 10, riskColor);

        RefreshLabel("EA_rule1", rule1Text, 15, chartHeight - 70, rule1Font, 10, rule1Color);
        RefreshLabel("EA_rule2", rule2Text, 15, chartHeight - 50, rule2Font, 10, rule2Color);
        RefreshLabel("EA_rule3", rule3Text, 15, chartHeight - 30, fontBold, 10, clrBlack);

        if ( ObjectFind(chartID, "Evacuate") >= 0 ) {
            ObjectDelete(chartID, "Evacuate");
        }

        ButtonCreate("Evacuate", 200, 110, 80, 30, "Evacuate");

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

void RefreshLabel(string labelID, string labelText, int x, int y, string fontName, int fontSize = 10, color clr = clrRed ) {
    int chartID = 0;

    if ( ObjectFind(chartID, labelID) >= 0 ) {
        ObjectDelete(chartID, labelID);
    }
    LabelCreate(labelID, labelText, x, y, fontName, fontSize, clr);
}

string getString(string str) {
    str = (string)NormalizeDouble(str, 2);
    if (str == "0")
        str = "0.00";
    if (StringLen(str) == 3)
        str = str + "0";
    return str;
}
