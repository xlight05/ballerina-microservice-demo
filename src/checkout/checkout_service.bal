import ballerina/grpc;
import ballerina/uuid;
import ballerina/log;

listener grpc:Listener ep = new (9094);

configurable string cartUrl = "localhost";
final CartServiceClient cartClient = check new ("http://" + cartUrl + ":9092");
configurable string catalogUrl = "localhost";
final ProductCatalogServiceClient catalogClient = check new ("http://" + catalogUrl + ":9091");
configurable string currencyUrl = "localhost";
final CurrencyServiceClient currencyClient = check new ("http://" + currencyUrl + ":9093");
configurable string shippingUrl = "localhost";
final ShippingServiceClient shippingClient = check new ("http://" + shippingUrl + ":9095");
configurable string paymentUrl = "localhost";
final PaymentServiceClient paymentClient = check new ("http://" + paymentUrl + ":9096");
configurable string emailUrl = "localhost";
final EmailServiceClient emailClient = check new ("http://" + emailUrl + ":9097");

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "CheckoutService" on ep {

    isolated remote function PlaceOrder(PlaceOrderRequest value) returns PlaceOrderResponse|error {
        log:printInfo("Getting user card");
        string orderId = uuid:createType1AsString();
        //Get Cart of the user
        CartItem[] userCartItems = check getUserCart(value.user_id, value.user_currency);
        //Order items to user currencey 
        OrderItem[] orderItems = check prepOrderItems(userCartItems, value.user_currency);
        //Get shipping costs and convert to user currencey
        Money shippingPrice = check convertCurrency(check quoteShipping(value.address, userCartItems), value.user_currency);

        //Calcuale total cost
        Money totalCost = {
            currency_code: value.user_currency,
            units: 0,
            nanos: 0
        };
        totalCost = sum(totalCost, shippingPrice);
        foreach OrderItem item in orderItems {
            Money multPrice = multiplySlow(item.cost, item.item.quantity);
            totalCost = sum(totalCost, multPrice);
        }

        string transactionId = check chargeCard(totalCost, value.credit_card);
        log:printInfo("payment went through " + transactionId);
        string shippingTrackingId = check shipOrder(value.address, userCartItems);
        check emptyUserCart(value.user_id);

        OrderResult orderRes = {
            order_id: orderId,
            shipping_tracking_id: shippingTrackingId,
            shipping_cost: shippingPrice,
            shipping_address: value.address,
            items: orderItems
        };

        check confirmationMail(value.email, orderRes);

        return {
            'order: orderRes
        };
    }
}

isolated function getUserCart(string userId, string userCurrency) returns CartItem[]|error {
    GetCartRequest user1 = {user_id: userId};
    Cart|grpc:Error cart = cartClient->GetCart(user1);
    if (cart is grpc:Error) {
        log:printError("failed to call getCart of cart service", 'error = cart);
        return cart;
    }
    return cart.items;
}

isolated function prepOrderItems(CartItem[] items, string userCurrency) returns OrderItem[]|error {
    OrderItem[] orderItems = [];
    foreach CartItem item in items {
        GetProductRequest req = {id: item.product_id};
        Product|grpc:Error product = catalogClient->GetProduct(req);
        if (product is grpc:Error) {
            log:printError("failed to call getProduct from catalog service", 'error = product);
            return product;
        }

        CurrencyConversionRequest req1 = {
            'from: product.price_usd,
            to_code: userCurrency
        };

        Money|grpc:Error money = currencyClient->Convert(req1);
        if (money is grpc:Error) {
            log:printError("failed to call convert from currency service", 'error = money);
            return money;
        }
        orderItems.push({
            item: item,
            cost: money
        });
    }
    return orderItems;
}

isolated function quoteShipping(Address address, CartItem[] items) returns Money|error {
    GetQuoteRequest req = {
        address: address,
        items: items
    };
    GetQuoteResponse|grpc:Error getQuoteResponse = shippingClient->GetQuote(req);
    if (getQuoteResponse is grpc:Error) {
        log:printError("failed to call getQuote from shipping service", 'error = getQuoteResponse);
        return getQuoteResponse;
    }
    return getQuoteResponse.cost_usd;
}

isolated function convertCurrency(Money usd, string userCurrency) returns Money|error {
    CurrencyConversionRequest req1 = {
        'from: usd,
        to_code: userCurrency
    };
    Money|grpc:Error convert = currencyClient->Convert(req1);
    if (convert is grpc:Error) {
        log:printError("failed to call convert from currency service", 'error = convert);
        return convert;
    }
    return currencyClient->Convert(req1);
}

isolated function chargeCard(Money total, CreditCardInfo card) returns string|error {
    ChargeRequest req = {
        amount: total,
        credit_card: card
    };
    ChargeResponse|grpc:Error chargeResponse = paymentClient->Charge(req);
    if (chargeResponse is grpc:Error) {
        log:printError("failed to call charge from payment service", 'error = chargeResponse);
        return chargeResponse;
    }
    return chargeResponse.transaction_id;
}

isolated function shipOrder(Address address, CartItem[] items) returns string|error {
    ShipOrderRequest req = {};
    ShipOrderResponse|grpc:Error getSupportedCurrenciesResponse = shippingClient->ShipOrder(req);
    if (getSupportedCurrenciesResponse is grpc:Error) {
        log:printError("failed to call shipOrder from shipping service", 'error = getSupportedCurrenciesResponse);
        return getSupportedCurrenciesResponse;
    }
    return getSupportedCurrenciesResponse.tracking_id;
}

isolated function emptyUserCart(string userId) returns error? {
    EmptyCartRequest req = {
        user_id: userId
    };
    Empty|grpc:Error emptyCart = cartClient->EmptyCart(req);
    if (emptyCart is grpc:Error) {
        log:printError("failed to call emptyCart from cart service", 'error = emptyCart);
        return emptyCart;
    }
}

isolated function confirmationMail(string email, OrderResult orderRes) returns error? {
    SendOrderConfirmationRequest req = {
        email: email,
        'order: orderRes
    };
    Empty|grpc:Error sendOrderConfirmation = emailClient->SendOrderConfirmation(req);
    if (sendOrderConfirmation is grpc:Error) {
        log:printError("failed to call sendOrderConfirmation from email service", 'error = sendOrderConfirmation);
        return sendOrderConfirmation;
    }
}
