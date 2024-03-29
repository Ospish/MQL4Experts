#define MAGICMA 20050610

extern double LotSize = 0.01;
input int TakeProfitRange = 100;

//+------------------------------------------------------------------+
// Calculate open positions
// return orders number (negative if short)
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol) {
    int buys = 0,
        sells = 0;

    // Loop through orders
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

//+-----------------------------------
// Check for open order conditions
//+-----------------------------------
void CheckForOpen() {
    double RSI;

    // Get default H4 RSI value
    RSI = iRSI(NULL, 240, 14, PRICE_CLOSE, 0);

   // Sell conditions
   if (CalculateCurrentOrders(Symbol()) == 0 && 72 < RSI) {
      CreateOrder(0, 1, 1, "H4:72");
   }
   if (CalculateCurrentOrders(Symbol()) == 1 && 74 < RSI) {
      CreateOrder(0, 2, 1.5, "H4:74");
   }

   // Buy conditions
   if (CalculateCurrentOrders(Symbol()) == 0 && 28 > RSI) {
      CreateOrder(1, 1, 1, "H4:28");
   }
   if (CalculateCurrentOrders(Symbol()) == -1 && 26 > RSI) {
      CreateOrder(1, 2, 1.5, "H4:26");
   }
}

//+------------------------
// Order making function
// type: 0 - sell, 1 - buy
// sizeX: lot size multiplier
// takeX: take profit range multiplier
//+------------------------
int CreateOrder(int type, float sizeX, float takeX, string comment = "") {
   PlaySound("Alert2.wav");
   string message;
   int result;
   double takeProfit;
   if (type == 1) {
      message = "MakeBuy";
      takeProfit = NormalizeDouble(Bid+TakeProfitRange*Point,Digits);
      result = OrderSend(Symbol(), OP_BUY, LotSize*sizeX, Ask, 3, 0, takeProfit*takeX, comment, MAGICMA, 0, Blue);
   }
   else if (type == 0) {
      message = "MakeSell";
      takeProfit = NormalizeDouble(Ask-TakeProfitRange*Point,Digits);
      result = OrderSend(Symbol(), OP_SELL, LotSize*sizeX, Bid, 3, 0, takeProfit*takeX, comment, MAGICMA, 0, Red);
   }
   MessageBox(message,NULL,0);
   return result;
}

//+------------------------------------
// Check for close order conditions
//+------------------------------------
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

        // Wait
        Sleep(5000);

        // If there's no orders, look to make one
        CheckForOpen();
        // Else look to close
        //else CheckForClose();
    }
}
