import ballerina/grpc;
import ballerina/io;
import ballerina/lang.'float as float;

listener grpc:Listener ep = new (9093);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "CurrencyService" on ep {
    map<string> currencyMap;

    function init() returns error? {
        string jsonFilePath = "./data/currency_conversion.json";
        json currencyJson = check io:fileReadJson(jsonFilePath);
        self.currencyMap = check currencyJson.cloneWithType();
    }

    remote function GetSupportedCurrencies(Empty value) returns GetSupportedCurrenciesResponse|error {
        return {currency_codes: self.currencyMap.keys()};
        
    }
    remote function Convert(CurrencyConversionRequest value) returns Money|error {
        Money moneyFrom = value.'from;

        final float fractionSize = float:pow(10, 9);
        //From Unit
        float pennys = <float> moneyFrom.nanos / fractionSize;
        float totalUSD = <float> moneyFrom.units + pennys;

        //UNIT Euro
        float rate = check float:fromString(self.currencyMap.get(moneyFrom.currency_code));
        float euroAmount = totalUSD/rate;

        //UNIT to Target
        float targetRate = check float:fromString(self.currencyMap.get(value.to_code));
        float targetAmount = euroAmount*targetRate;

        int newUnits = <int> targetAmount.floor();
        int newNanos = <int> float:floor((targetAmount-<float>newUnits)*fractionSize);

        Money money = {
            currency_code: value.to_code,
            nanos: newNanos,
            units: newUnits
        };
        return money;
    }
}

