import ballerina/test;
 @test:Config {}
 function recommandTest() returns error?{
     RecommendationServiceClient ep = check new ("http://localhost:9090");
     ListRecommendationsRequest req = {
         user_id: "1",
         product_ids: ["2ZYFJ3GM2N", "LS4PSXUNUM"]
     };
     ListRecommendationsResponse listProducts = check ep->ListRecommendations(req);
     test:assertEquals(listProducts.product_ids.length(), 7);
 }