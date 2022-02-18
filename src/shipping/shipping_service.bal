import ballerina/grpc;
import ballerina/lang.'string as str;
import ballerina/random;

listener grpc:Listener ep = new (9095);
@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "ShippingService" on ep {

    isolated remote function GetQuote(GetQuoteRequest value) returns GetQuoteResponse|error {
        CartItem[] items = value.items;
        int count = 0;
        float cost = 0.0;
        foreach CartItem item in items {
            count += item.quantity;
        }

        if (count != 0) {
            cost = 8.99; //Adds fixed Price
        }
        float cents = cost % 1;
        int dollars = <int> (cost - cents);

        Money money = {currency_code: "USD",nanos: <int> cents*10000000, units: dollars};

        return {
            cost_usd: money
        };
    }
    isolated remote function ShipOrder(ShipOrderRequest value) returns ShipOrderResponse|error {
        Address ress = value.address;
        string baseAddress = ress.street_address +", "+ ress.city+ ", "+ ress.state;
        string trackingId = self.generateRandomLetter() + self.generateRandomLetter() + "-" + baseAddress.length().toString() + self.generateRandomNumber(3) + "-" + (baseAddress.length()/2).toString() + self.generateRandomNumber(7);
        return {tracking_id: trackingId};
    }

    isolated function generateRandomLetter() returns string {
        int randomLetterCodePoint = checkpanic random:createIntInRange(65,91);
        return checkpanic str:fromCodePointInt(randomLetterCodePoint);
    }


    isolated function generateRandomNumber(int digit) returns string {
        string out= "";
        foreach int item in 0...digit {
            int randomInt = checkpanic random:createIntInRange(0,10);
            out += randomInt.toString();
        }
        return out;
    }
}

