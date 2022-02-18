import ballerina/grpc;

listener grpc:Listener adListener = new (9099);

@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_DEMO, descMap: getDescriptorMapDemo()}
service "AdService" on adListener {
    AdStore store;

    function init() {
        self.store = new AdStore();
    }

    remote function GetAds(AdRequest request) returns AdResponse|error? {
        Ad[] ads = [];
        foreach string category in request.context_keys {
            Ad[] availableAds = self.store.getAdsByCategory(category);
            availableAds.forEach(function (Ad ad) {
                ads.push(ad);
            });
        }
        if ads.length() == 0 {
            ads = check self.store.getRandomAds();
        }
        AdResponse response = {
            ads: ads
        };
        return response;
    }
}