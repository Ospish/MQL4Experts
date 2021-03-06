#define MAGICMA 20050610

extern double LotSize = 0.1;
input double Lots = 0.1;
input double MaximumRisk = 0.02;
input double DecreaseFactor = 3;

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol) {
    int buys = 0,
        sells = 0;
    //----
    for (int i = 0; i < OrdersTotal(); i++) {
        if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) break;
        if (OrderSymbol() == Symbol() && OrderMagicNumber() == MAGICMA) {
            if (OrderType() == OP_BUY) buys++;
            if (OrderType() == OP_SELL) sells++;
        }
    }
    //---- return orders volume
    if (buys > 0) return (buys);
    else return (-sells);
}

//+------------------------------------------------------------------+
//| Order making function                                            |
//+------------------------------------------------------------------+
int MakeOrder(int type) {
    if (type == 1) {
        return OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, 0, 0, "", MAGICMA, 0, Blue);
    }
    else if (type == 0) {
        return OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, 0, 0, "", MAGICMA, 0, Red);
    }
    else return 1;
}

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized() {
    double lot = Lots;
    int orders = HistoryTotal(); // history orders total
    int losses = 0;              // number of losses orders without a break

    //---- select lot size
    lot = NormalizeDouble(AccountFreeMargin() * MaximumRisk / 1000.0, 1);
    //---- calcuulate number of losses orders without a break
    if (DecreaseFactor > 0)
    {
    for (int i = orders - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false) { Print("Error in history!"); break; }
        if (OrderSymbol() != Symbol() || OrderType() > OP_SELL) continue;
        if (OrderProfit() > 0) break;
        if (OrderProfit() < 0) losses++;
    }
    if (losses > 1) lot = NormalizeDouble(lot - lot * losses / DecreaseFactor, 1);
    }
    // Return lot size
    if (lot < 0.1) lot = 0.1;
    return (lot);
}


//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen() {
    double RSI;

    // Get RSI value
    RSI = iRSI(NULL, 0, 14, PRICE_CLOSE, 0);

    int result;

    // Sell conditions
    if (70 < RSI) {
        PlaySound("Alert2.wav");
        MessageBox("MakeSell",NULL,0);
        result = MakeOrder(0);
        return;
    }
    // Buy conditions
    if (30 > RSI) {
        PlaySound("Alert2.wav");
        MessageBox("MakeBuy",NULL,0);
        result = MakeOrder(0);
        return;
    }
}
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose() {
    double RSI;
    MessageBox("Close",NULL,0);

    // Get RSI value
    RSI = iRSI(NULL, 0, 14, PRICE_CLOSE, 0);

    for (int i=0; i<OrdersTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
        if (OrderMagicNumber() != MAGICMA || OrderSymbol() != Symbol()) continue;
        // Check order type
        if (OrderType() == OP_BUY) {
            if(Open[1] > RSI && Close[1] < RSI) OrderClose(OrderTicket(), OrderLots(), Bid, 3, White);
            break;
        }
        if (OrderType() == OP_SELL) {
            if (Open[1] < RSI && Close[1] > RSI) OrderClose(OrderTicket(), OrderLots(), Ask, 3, White);
            break;
        }
    }
}


//+------------------------------------------------------------------+
//| Start function                                                   |
//+------------------------------------------------------------------+
void start() {
    while (true) {
        //---- check for history and trading
        // if (Bars < 100 || IsTradeAllowed() == false) {
        //   return;
        //}

        //Calculate open orders for current symbol
        CheckForOpen();

        // Wait
        Sleep(5000);

        if (CalculateCurrentOrders(Symbol()) == 0) MakeOrder(1);

        // If there's no orders, look to make one
        if (CalculateCurrentOrders(Symbol()) == 0) CheckForOpen();
        // Else look to close
        else CheckForClose();
    }
}
