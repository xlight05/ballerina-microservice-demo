import ballerina/http;
import ballerina/time;
import ballerina/os;

type CartItemView record {
    Product product;
    int quantity;
    string price;
};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"]
    }
}
service /cart on ep {

    resource function get .() returns json|error {
        string[] currencies = check getSupportedCurrencies();
        Cart cart = check getCart(userId);
        Product[] recommandations = check getRecommendations(userId, self.getProductIdFromCart(cart));
        Money shippingCost = check getShippingQuote(cart.items, userCurrency);
        Money totalPrice = {
            currency_code: userCurrency,
            nanos: 0,
            units: 0
        };
        CartItemView[] cartItems = [];
        foreach CartItem item in cart.items {
            Product product = check getProduct(item.product_id);

            Money converedPrice = check convertCurrency(product.price_usd, userCurrency);

            Money price = multiplySlow(converedPrice, item.quantity);
            string renderedPrice = renderMoney(price);
            cartItems.push({
                product,
                price: renderedPrice,
                quantity: item.quantity
            });
            totalPrice = sum(totalPrice, price);
        }
        totalPrice = sum(totalPrice, shippingCost);
        int year = time:utcToCivil(time:utcNow()).year;
        int[] years = [year, year + 1, year + 2, year + 3, year + 4];

        string platformEnv = os:getEnv("ENV_PLATFORM"); //TODO remove
        if (platformEnv == "") {
            platformEnv = "local";
        }
        return {
            session_id: userId,
            request_id: userId,
            user_currency: userCurrency,
            show_currency: true,
            currencies: currencies,
            platform_css: platformEnv,
            platform_name: platformEnv,
            is_cymbal_brand: is_cymbal_brand,
            recommendations: recommandations,
            cart_size: cart.length(),
            shipping_cost: renderMoney(shippingCost),
            total_cost: renderMoney(totalPrice),
            items: cartItems.toJson(),
            expiration_years: years
        };
    }

    function getProductIdFromCart(Cart cart) returns string[] {
        return from CartItem item in cart.items
            select item.product_id;
    }

    resource function post .(http:Request req, @http:Payload AddToCartRequest addToCartRequest) returns http:Ok|http:InternalServerError|http:BadRequest {
        Product|error product = getProduct(addToCartRequest.productId);
        if product is error {
            http:BadRequest resp = {
                body: "invalid request" + product.message()
            };
            return resp;
        }

        error? insertCartResult = insertCart(userId, addToCartRequest.productId, addToCartRequest.quantity);
        if insertCartResult is error {
            http:InternalServerError resp = {
                body: "an error occured " + insertCartResult.message()
            };
            return resp;

        }

        http:Ok resp = {
            body: "item added the cart"
        };
        return resp;
    }

    resource function post empty() returns http:Ok|http:InternalServerError {
        error? emptyCartResult = emptyCart(userId);
        if emptyCartResult is error {
            http:InternalServerError resp = {
                body: "an error occured " + emptyCartResult.message()
            };
            return resp;
        }
        http:Ok resp = {
            body: "cart emptied"
        };
        return resp;
    }

    resource function post checkout(http:Request req, @http:Payload CheckoutRequest checkoutRequest) returns http:Ok|http:InternalServerError {
        do {
            OrderResult orderResult = check checkoutCart({
                email: checkoutRequest.email,
                address: {
                    city: checkoutRequest.city,
                    country: checkoutRequest.country,
                    state: checkoutRequest.state,
                    street_address: checkoutRequest.street_address,
                    zip_code: checkoutRequest.zip_code
                },
                user_id: userId,
                user_currency: userCurrency,
                credit_card: {
                    credit_card_cvv: checkoutRequest.credit_card_cvv,
                    credit_card_expiration_month: checkoutRequest.credit_card_expiration_month,
                    credit_card_expiration_year: checkoutRequest.credit_card_expiration_year,
                    credit_card_number: checkoutRequest.credit_card_number
                }
            });

            Product[] recommendations = check getRecommendations(userId, []);
            Money totalCost = orderResult.shipping_cost;
            foreach OrderItem item in orderResult.items {
                Money multiplyRes = multiplySlow(item.cost, item.item.quantity);
                totalCost = sum(totalCost, multiplyRes);
            }
            string[] currencies = check getSupportedCurrencies();
            string platformEnv = os:getEnv("ENV_PLATFORM"); //TODO remove
            if (platformEnv == "") {
                platformEnv = "local";
            }
            json respBody = {
                session_id: userId,
                request_id: userId,
                user_currency: userCurrency,
                show_currency: true,
                currencies: currencies,
                platform_css: platformEnv,
                platform_name: platformEnv,
                is_cymbal_brand: is_cymbal_brand,
                "order": orderResult,
                total_paid: renderMoney(totalCost),
                recommendations: recommendations
            };
            http:Ok resp = {
                body: respBody
            };
            return resp;
        } on fail var e {
            http:InternalServerError resp = {
                body: "an error occured " + e.message()
            };
            return resp;
        }
    }
}
