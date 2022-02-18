import ballerina/grpc;
import ballerina/log;
configurable string currencyUrl = "localhost";
final CurrencyServiceClient currencyClient = check new ("http://" + currencyUrl + ":9093");
configurable string catalogUrl = "localhost";
final ProductCatalogServiceClient catalogClient = check new ("http://" + catalogUrl + ":9091");

isolated function getSupportedCurrencies() returns string[]|error {
    //TODO Report tooling match is not supported
    GetSupportedCurrenciesResponse|grpc:Error supportedCurrencies = currencyClient->GetSupportedCurrencies({});

    if (supportedCurrencies is grpc:Error) {
        log:printError("failed to call getSupportedCurrencies from currency service", 'error = supportedCurrencies);
        return supportedCurrencies;
    }
    return supportedCurrencies.currency_codes;
}

isolated function getProducts() returns Product[]|error {
    ListProductsResponse|grpc:Error products = catalogClient->ListProducts({});

    if (products is grpc:Error) {
        log:printError("failed to call listProducts from catalog service", 'error = products);
        return products;
    }
    return products.products;
}

isolated function getProduct(string prodId) returns Product|error {
    GetProductRequest req = {
        id: prodId
    };
    Product|grpc:Error product = catalogClient->GetProduct(req);

    if (product is grpc:Error) {
        log:printError("failed to call getProduct from catalog service", 'error = product);
        return product;
    }
    return product;
}