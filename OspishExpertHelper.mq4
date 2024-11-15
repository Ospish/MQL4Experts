#include "OspishLib.mq4"

input int Reserve = 0;

//+------------------------------------------------------------------+
// Get info about current orders
// @var type:
// countBuy - buy order count
// countSell - sell order count
// volumeBuy - sell order count
// volumeSell - sell order count
// volumeBuyStr - sell order count
// volumeSellStr - sell order count
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
        return NormalizeDouble(AccountEquity() / riskValue() / 2000, 2);

    if (type == "riskEquity")
        return MathAbs((buyVol-sellVol) / (AccountEquity() / riskValue() / 2000));

    if (type == "riskBalance")
        return MathAbs((buyVol-sellVol) / (AccountBalance() / riskValue() / 2000));

    return "";
}

//
// start function - executed every tick
//
int loopcount, lastPosition, position = 0;
bool buttonsInitialized = false;
void start() {
    string wentTodayStr, wentMonthStr, wentMonthDailyStr, riskResult, orderVolumeBuy, orderVolumeSell, rule1Text, rule2Text, rule3Text, rule1Font, rule2Font, font, fontBold = "", lastOrderStr = "Last Order: Never";
    int chartID, chartHeight, orderCountBuy, orderCountSell = 0, UIFirstXStartPoint, UISecondXStartPoint, UIThirdXStartPoint, UIFirstYStartPoint, UISecondYStartPoint, UIThirdYStartPoint, lastOrderOpenTime;
    double safeVolume, riskEquity, riskBalance = 0.0;
    color riskColor, orderCountColor, orderVolumeColor, rule1Color, rule2Color;
    datetime lastOrderTime = D'';

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
        if (AccountMargin() > 0 )
            rule1Text = "1. No Adding Below 3000% (" + NormalizeDouble(AccountEquity() / AccountMargin() * 100, 2) + ")";
        else
            rule1Text = "1. No Adding Below 3000%";
        rule2Text = "2. Have Reserve (" + Reserve + ")";
        rule3Text = "3. No Deposit After Margin Call";
        font = "Source Code Pro";
        fontBold = "Source Code Pro Black";
        chartHeight = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
        riskColor = clrGreen;
        rule1Color = rule2Color = orderCountColor = clrBlack;
        rule1Font = rule2Font = fontBold;

        if (riskValue() > 0)
            riskResult = NormalizeDouble(riskEquity, 2) + "x ("+ NormalizeDouble(riskBalance, 2)+"x)";
        //else riskResult = NormalizeDouble(riskBalance, 2);

        OrderSelect( ( OrdersTotal()-1 ), SELECT_BY_POS);

        position = orderCountBuy - orderCountSell;
        //lastOrderOpenTime = OrderOpenTime();
        if (lastPosition > position && lastPosition != 0) {
            Print("Position " + position+" Last Position " + lastPosition);
            drawArrowDown();
        }
        if (lastPosition < position && lastPosition != 0) {
            Print("Position " + position+" Last Position " + lastPosition);
            drawArrowUp();
        }
        lastPosition = position;

        if (lastOrderOpenTime != OrderOpenTime()) {
            lastOrderStr = "Last Order: " + TimeToString(OrderOpenTime());
        }

        if (riskResult > 1)
            riskColor = clrGoldenrod;
        if (riskResult >= 2)
            riskColor = clrRed;

        if (AccountMargin() > 0 && AccountEquity() / AccountMargin() * 100 < 3000) {
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

        orderVolumeBuy = getString(orderVolumeBuy);
        orderVolumeSell = getString(orderVolumeSell);

        UIFirstXStartPoint = 210;
        if (Symbol() == "BITCOIN")
            UIFirstXStartPoint = 240;
        UIFirstYStartPoint = 15;

        UISecondXStartPoint = 3;
        UISecondYStartPoint = 80;

        UIThirdXStartPoint = 410;
        UIThirdYStartPoint = 15;

        double low = iLow(NULL,PERIOD_D1,0);        // Last candles low
        double high = iHigh(NULL,PERIOD_D1,0);
        double wentToday;

        wentToday = pointMultiplier()*(high - low);
        wentTodayStr = "Went today: " + wentToday;

//        low = iLow(NULL,PERIOD_MN1,0);        // Last candles low
//        high = iHigh(NULL,PERIOD_MN1,0);
//        wentMonthDailyStr = "Went daily for last month: " + pointMultiplier()*(high - low);

        int wentMonthMedian, went3MonthMedian, wentMonthMax, went3MonthMax;
        string wentMonthMedianStr, went3MonthMedianStr, wentDiffStr, wentMonthMaxStr, went3MonthMaxStr, wentMonthMaxTime, went3MonthMaxTime;
        for (int i = 0; i < 20; i++) {
            low = iLow(NULL,PERIOD_D1,i);        // Last candles low
            high = iHigh(NULL,PERIOD_D1,i);
            wentMonthMedian += pointMultiplier() * (high - low);
            if (wentMonthMax < pointMultiplier() * (high - low)) {
                wentMonthMax = pointMultiplier() * (high - low);
                wentMonthMaxTime = TimeToString(iTime(NULL,PERIOD_D1,i));
            }
        }
        for (int i2 = 0; i2 < 60; i2++) {
            low = iLow(NULL,PERIOD_D1,i2);        // Last candles low
            high = iHigh(NULL,PERIOD_D1,i2);
            went3MonthMedian += pointMultiplier() * (high - low);
            if (went3MonthMax < pointMultiplier() * (high - low)) {
                went3MonthMax = pointMultiplier() * (high - low);
                went3MonthMaxTime = TimeToString(iTime(NULL,PERIOD_D1,i2));
            }
        }
        wentMonthMedianStr = "Went month (median): " + wentMonthMedian/20;
        went3MonthMedianStr = "Went 3 month (median): " + went3MonthMedian/60;
        wentMonthMaxStr = "Went month (max): " + wentMonthMax + " " + wentMonthMaxTime;
        went3MonthMaxStr = "Went 3 month (max): " + went3MonthMax + " " + went3MonthMaxTime;

        double pointsLeft, lineCoords, spread;
        string printMsg;
        if ((double)orderVolumeResult != 0)
            pointsLeft = AccountEquity()/(double)MathAbs(orderVolumeResult) - 100;
        else
            pointsLeft = 0;

        if (loopcount % 10 == 0) {
            ObjectDelete("Death Line"); //draw a line
            if (orderVolumeResult != 0) {
                if (orderVolumeResult < 0) {
                    lineCoords = Ask + pointsLeft / pointMultiplier() ;
                }
                if (orderVolumeResult > 0) {
                    lineCoords = Bid - pointsLeft / pointMultiplier();
                }
                ObjectCreate("Death Line", OBJ_HLINE, 0, 0, lineCoords); //draw a line
                ObjectSet("Death Line", OBJPROP_COLOR,Red);
                ObjectSet("Death Line", OBJPROP_WIDTH,2);
            }
        }

        color spreadColor;
        spread = MarketInfo(Symbol(), MODE_SPREAD);
        if (spread > 40)
            spreadColor = clrRed;
        else if (spread > 35)
            spreadColor = clrYellow;
        else
            spreadColor = clrBlack;

        wentDiffStr = NormalizeDouble(wentToday/(wentMonthMedian/20)*100, 2) + "% went today";
        // -----
        RefreshLabel("EA_orderCount_label", "Orders: ", UIFirstXStartPoint, UIFirstYStartPoint, fontBold, 11, clrBlack);
        RefreshLabel("EA_orderCount_value1", orderCountBuy, UIFirstXStartPoint + 70, UIFirstYStartPoint + 2, font, 10, clrBlue);
        RefreshLabel("EA_orderCount_value2", orderCountSell, UIFirstXStartPoint + 110, UIFirstYStartPoint + 2, font);
        RefreshLabel("EA_orderCount_value3", orderCountResult, UIFirstXStartPoint + 150, UIFirstYStartPoint + 2, fontBold, 10, orderCountColor);

        RefreshLabel("EA_orderVolume_label", "Volume: ", UIFirstXStartPoint, UIFirstYStartPoint + 20, fontBold, 11, clrBlack);
        RefreshLabel("EA_orderVolume_value1", orderVolumeBuy, UIFirstXStartPoint + 70, UIFirstYStartPoint + 20 + 2, font, 10, clrBlue);
        RefreshLabel("EA_orderVolume_value2", orderVolumeSell, UIFirstXStartPoint + 110, UIFirstYStartPoint + 20 + 2, font);
        RefreshLabel("EA_orderVolume_value3", getString(MathAbs(orderVolumeResult)), UIFirstXStartPoint + 150, UIFirstYStartPoint + 20 + 2, fontBold, 10, orderVolumeColor);

        RefreshLabel("EA_safeVolume_label", "Safe Volume: ", UIFirstXStartPoint, UIFirstYStartPoint + 40, fontBold, 11, clrBlack);
        RefreshLabel("EA_safeVolume_value", safeVolume, UIFirstXStartPoint + 115, UIFirstYStartPoint + 42, fontBold, 10, clrBlack);

        RefreshLabel("EA_risk_label", "Risk: ", UIFirstXStartPoint, UIFirstYStartPoint + 60, fontBold, 11, clrBlack);
        RefreshLabel("EA_risk_value", riskResult + " " + riskValue(), UIFirstXStartPoint + 50, UIFirstYStartPoint + 62, fontBold, 10, riskColor);
        RefreshLabel("EA_points_left", "Points left: " + pointsLeft, UIFirstXStartPoint, UIFirstYStartPoint + 80, fontBold, 11, clrBlack);

        RefreshLabel("EA_spread", "Spread: " + spread, UIFirstXStartPoint, UIFirstYStartPoint + 100, fontBold, 11, spreadColor);
        // -----
        RefreshLabel("EA_last_order_time", lastOrderStr, UIThirdXStartPoint, UIThirdYStartPoint, fontBold, 11, clrBlack);

        RefreshLabel("EA_went_today", wentTodayStr, UIThirdXStartPoint, UIThirdYStartPoint + 20, fontBold, 11, clrBlack);
        RefreshLabel("EA_went_daily_last_month", wentMonthMedianStr, UIThirdXStartPoint, UIThirdYStartPoint + 40, fontBold, 11, clrBlack);
        RefreshLabel("EA_went_diff", wentDiffStr, UIThirdXStartPoint, UIThirdYStartPoint + 60, fontBold, 11, clrBlack);
        RefreshLabel("EA_went_daily_last_month_max", wentMonthMaxStr, UIThirdXStartPoint, UIThirdYStartPoint + 80, fontBold, 11, clrBlack);
        RefreshLabel("EA_went_daily_last_3_months", went3MonthMedianStr, UIThirdXStartPoint, UIThirdYStartPoint + 100, fontBold, 11, clrBlack);
        RefreshLabel("EA_went_daily_last_3_months_max", went3MonthMaxStr, UIThirdXStartPoint, UIThirdYStartPoint + 120, fontBold, 11, clrBlack);
        // -----
        RefreshLabel("EA_symbol", Symbol(), UISecondXStartPoint + 116, UISecondYStartPoint, fontBold, 16, clrRed);
        // -----
        RefreshLabel("EA_rule1", rule1Text, 15, chartHeight - 70, rule1Font, 10, rule1Color);
        RefreshLabel("EA_rule2", rule2Text, 15, chartHeight - 50, rule2Font, 10, rule2Color);
        RefreshLabel("EA_rule3", rule3Text, 15, chartHeight - 30, fontBold, 10, clrBlack);

        if ( ObjectFind(chartID, "Evacuate") >= 0 ) {
            ObjectDelete(chartID, "Evacuate");
        }

        int buttonWidth = 80;
        int buttonHeight = 30;

        RefreshButton("Evacuate", UISecondXStartPoint, UISecondYStartPoint, buttonWidth, buttonHeight, "Evacuate");
        RefreshButton("Clear_arrows", UISecondXStartPoint,  UISecondYStartPoint + buttonHeight + 10, buttonWidth, buttonHeight, "Clear Arrows");
        //RefreshButton("Arrow_down", UIFirstXStartPoint, 125 + buttonHeight + 10, buttonWidth, buttonHeight, "Arrow Down");

        //Print("Labels updated");
    }

    Sleep(500);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
//--- Check the event by pressing a mouse button
    if (id==CHARTEVENT_OBJECT_CLICK) {
        string clickedChartObject=sparam;
        //--- If you click on the object with the name buttonID
        if (clickedChartObject=="Evacuate") {
            //--- State of the button - pressed or not
            //selected=ObjectGetInteger(0,"Evacuate",OBJPROP_STATE);
            //--- log a debug message
            Print("Evacuating...");
            PlaySound("expert.wav");
            CloseOrders();
        }
        if (clickedChartObject=="Clear_arrows") {
            for (int i =ObjectsTotal()-1; i>=0; i--){
                string name  = ObjectName(i);
                Print(name + (TimeCurrent() - ObjectGet(name, OBJPROP_TIME1)));
                if (StringFind("Arrow_", name) > -1 && TimeCurrent() - ObjectGet(name, OBJPROP_TIME1) > 86400*2) {
                    Print(ObjectGet(name, OBJPROP_TIME1));
                    ObjectDelete(0, name);
                }
            }
        }
        if (clickedChartObject=="Arrow_up") {
         drawArrowUp();
        }
        if (clickedChartObject=="Arrow_down") {
         drawArrowDown();
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

void RefreshButton(string labelID, int x, int y, int buttonWidth, int buttonHeight, string labelText ) {
    int chartID = 0;

    if ( ObjectFind(chartID, labelID) >= 0 ) {
        ObjectDelete(chartID, labelID);
    }
    ButtonCreate(labelID, x, y, buttonWidth, buttonHeight, labelText );
}
void RefreshLine(string labelID, int x, int y, int buttonWidth, int buttonHeight, string labelText ) {
    int chartID = 0;

    if ( ObjectFind(chartID, labelID) >= 0 ) {
        ObjectDelete(chartID, labelID);
    }
    ButtonCreate(labelID, x, y, buttonWidth, buttonHeight, labelText );
}

string getString(string str) {
    str = (string)NormalizeDouble(str, 2);
    if (str == "0")
        str = "0.00";
    if (StringLen(str) == 3)
        str = str + "0";
    return str;
}

void drawArrowUp() {
   //--- State of the button - pressed or not
   //selected=ObjectGetInteger(0,"Arrow_up",OBJPROP_STATE);
   string objName = "Arrow_Buy_" + rand();
   //--- log a debug message
   Print("Arrow up...");
   PlaySound("alert.wav");
   ObjectCreate(objName, OBJ_ARROW, 0, TimeCurrent(), Ask); //draw an up arrow
   ObjectSet(objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(objName, OBJPROP_ARROWCODE, SYMBOL_ARROWUP);
   ObjectSet(objName, OBJPROP_COLOR,Blue);
}

void drawArrowDown() {
   //--- State of the button - pressed or not
   //selected=ObjectGetInteger(0,"Arrow_down",OBJPROP_STATE);
   string objName = "Arrow_Sell_" + rand();
   //--- log a debug message
   Print("Arrow down...");
   PlaySound("news.wav");
   ObjectCreate(objName, OBJ_ARROW, 0, TimeCurrent(), Bid); //draw an up arrow
   ObjectSet(objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(objName, OBJPROP_ARROWCODE, SYMBOL_ARROWDOWN);
   ObjectSet(objName, OBJPROP_COLOR,Red);
}

int riskValue() {
    if (Symbol() == "GBPUSD" || Symbol() == "EURUSD")
        return 1;
    if (Symbol() == "XAUUSD")
        return 4;
    if (Symbol() == "BITCOIN")
        return 15;
    return 999;
}

int pointMultiplier() {
    if (Symbol() == "GBPUSD" || Symbol() == "EURUSD")
        return 100000;
    if (Symbol() == "USDJPY")
        return 1000;
    if (Symbol() == "XAUUSD")
        return 100;
    if (Symbol() == "BITCOIN")
        return 1;
    return 100000;
}