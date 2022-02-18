import ballerina/grpc;
import ballerina/io;
import ballerina/log;

listener grpc:Listener ep = new (9091);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "ProductCatalogService" on ep {
    Product[] products = [];
    function init() returns error?{
        string jsonFilePath = "./resources/products.json";
        json|io:Error productsJson = io:fileReadJson(jsonFilePath);
        if productsJson is io:Error {
            log:printError("Product list read failed", 'error=productsJson);
            return productsJson;
        }
        Product[]|error products = self.parseProductJson(productsJson);
        if products is error {
            log:printError("Product list parsing failed", 'error=products);
            return products;
        }
        self.products = products;
    }


    isolated remote function ListProducts(Empty value) returns ListProductsResponse|error {
        return {products: self.products};
    }

    isolated function parseProductJson(json productRead) returns Product[]|error {
        Product[] products = [];
        json[] productsJson = <json[]> check productRead.products;
        foreach json productJson in productsJson {
            Product product = {
                id: check productJson.id,
                name: check productJson.name,
                description: check productJson.description,
                picture: check productJson.picture,
                price_usd: check self.parseMoneyJson(check productJson.priceUsd),
                categories: check (check productJson.categories).cloneWithType()
            };
            products.push(product);
        }
        return products;
    }

    isolated function parseMoneyJson(json moenyJson) returns Money|error {
        return {
            currency_code: check moenyJson.currencyCode,
            units: check moenyJson.units,
            nanos: check moenyJson.nanos
        };
    }

    isolated remote function GetProduct(GetProductRequest value) returns Product|error {
        foreach Product product in self.products {
            if (product.id == value.id) {
                return product;
            }
        }
        return {};
    }
    isolated remote function SearchProducts(SearchProductsRequest value) returns SearchProductsResponse|error {
        Product[] productResults = [];
        Product[] products = self.products;
        foreach Product product in products {
            if product.name.toLowerAscii().includes(value.query.toLowerAscii()) || product.description.toLowerAscii().includes(value.query.toLowerAscii()) {
                productResults.push(product);
            }
        }
        return {
            results: productResults
        };
    }
}

