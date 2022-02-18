import ballerina/grpc;
import ballerina/log;

listener grpc:Listener ep = new (9090);
configurable string catalogUrl = "localhost";
final ProductCatalogServiceClient catalogClient = check new ("http://"+catalogUrl+":9091");

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "RecommendationService" on ep {

    isolated remote function ListRecommendations(ListRecommendationsRequest value) returns ListRecommendationsResponse|error {
        string[] productIds = value.product_ids;
        ListProductsResponse|grpc:Error listProducts = catalogClient->ListProducts({});
        if (listProducts is grpc:Error) {
            log:printError("failed to call ListProducts of catalog service", 'error=listProducts);
            return listProducts;
        }
        Product[] products = listProducts.products;
        string[] recommandProductIds = [];

        //Remove existing products in the cart from recommandations
        foreach Product product in products {
            string productId = product.id;
            boolean isExist = false;
            foreach string userProductIds in productIds {
                if (userProductIds == productId) {
                    isExist = true;
                }
            }
            if (!isExist) {
                recommandProductIds.push(product.id);
            }
        }
        return {
            product_ids: recommandProductIds
        };
    }
}

