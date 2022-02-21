import ballerina/http;
import ballerina/os;

listener http:Listener ep = check new http:Listener(9098);
const string userId = "1";
const string userCurrency = "USD";
boolean is_cymbal_brand = os:getEnv("CYMBAL_BRANDING") == "true";

type ProductView record {
    Product product;
    Money price;
};
service / on ep {
    
    resource function get .() returns json|error {

        string[] supportedCurrencies = check getSupportedCurrencies();
        Product[] products = check getProducts();
        Cart cart = check getCart(userId);
        ProductView[] productView = [];
        foreach Product product in products {
            productView.push({
                product,
                price: check convertCurrency(product.price_usd, userCurrency)
            });
        }
        string platformEnv = os:getEnv("ENV_PLATFORM");
        if (platformEnv == "") {
            platformEnv = "local";
        }
        return {
            session_id : userId,
            request_id : userId,
            user_currency : userCurrency,
            show_currency : true,
            currencies : supportedCurrencies,
            products : productView.toJson(),
            cart_size : cart.items.length(),
            banner_color: os:getEnv("BANNER_COLOR"),
            ad : check chooseAd([]),
            platform_css : platformEnv,
            platform_name : platformEnv,
            is_cymbal_brand : is_cymbal_brand
        };
    }

    resource function get product/[int id]() returns json {
        return {};
    }

    resource function post setCurrency() returns json {
        return {};
    }

    resource function get logout() returns json {
        return {};
    }


    // resource function get .() returns http:Ok {
    //     return {
    //         headers: {
    //             "Content-Type": "text/html; charset=UTF-8"
    //         },
    //         body: "<h1>HI</h1>"
    //     };
    // }

    // resource function get static/[string typze]/[string no](http:Caller caller, http:Request request) {
    //     string|file:Error requestedFilePath = file:joinPath(request.rawPath);
    //     http:Response res = new;
    //     if (requestedFilePath is string) {
    //         log:printInfo(requestedFilePath);
    //         res = self.getFileAsResponse(requestedFilePath);
    //     } else {
    //         res.setTextPayload("server error occurred.");
    //         res.statusCode = 500;
    //         log:printError("unable to resolve file path", 'error = requestedFilePath);
    //     }

    //     error? clientResponse = caller->respond(res);
    //     if (clientResponse is error) {
    //         log:printError("unable respond back", 'error = clientResponse);
    //     }

    // }

    // function getFileAsResponse(string requestedFile) returns http:Response {
    //     http:Response res = new;

    //     // Figure out content-type
    //     string contentType = mime:APPLICATION_OCTET_STREAM;
    //     string fileExtension = self.getExtensionFromFile(requestedFile);
    //     if (fileExtension != "") {
    //         contentType = self.getMimeTypeByExtension(fileExtension);
    //     }
    //     string|file:Error absolutePath = file:getAbsolutePath(requestedFile.substring(1));
    //     if absolutePath is string {
    //         log:printInfo(absolutePath);
    //         boolean|file:Error exists = file:test(requestedFile.substring(1), file:EXISTS);
    //         if exists is boolean {
    //             if (exists) {
    //                 res.setFileAsPayload(requestedFile.substring(1), contentType = contentType);
    //                 return res;
    //             }
    //         }
    //     }

    //     res.setTextPayload("the server was not able to find what you were looking for.");
    //     res.statusCode = http:STATUS_NOT_FOUND;
    //     return res;
    // }

    // function getExtensionFromFile(string filename) returns string {
    //     string[] split = regex:split(filename, "\\.");
    //     return split[split.length() - 1];
    // }

    // # Get the content type using a file extension.
    // #
    // # + extension - The file extension.
    // # + return - The content type if a match is found, else application/octet-stream.
    // function getMimeTypeByExtension(string extension) returns string {
    //     final map<string> MIME_MAP = {
    //         "json": mime:APPLICATION_JSON,
    //         "xml": mime:TEXT_XML,
    //         balo: mime:APPLICATION_OCTET_STREAM,
    //         css: "text/css",
    //         gif: "image/gif",
    //         html: mime:TEXT_HTML,
    //         ico: "image/x-icon",
    //         jpeg: "image/jpeg",
    //         jpg: "image/jpeg",
    //         js: "application/javascript",
    //         png: "image/png",
    //         svg: "image/svg+xml",
    //         txt: mime:TEXT_PLAIN,
    //         woff2: "font/woff2",
    //         zip: "application/zip"
    //     };
    //     var contentType = MIME_MAP[extension.toLowerAscii()];
    //     if (contentType is string) {
    //         return contentType;
    //     } else {
    //         return mime:APPLICATION_OCTET_STREAM;
    //     }
    // }
}
