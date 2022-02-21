import ballerina/random;

readonly class AdStore {

    map<Ad[]> & readonly ads;
    private final int MAX_ADS_TO_SERVE = 2;

    isolated function init() {
        self.ads =  getAds().cloneReadOnly();
    }

    public isolated function getRandomAds() returns Ad[]|random:Error {
        Ad[] allAds = [];

        //TODO issue can we not pass array to varargs
        foreach Ad[] ads in self.ads {
            foreach Ad ad in ads {
                allAds.push(ad);
            }
        }

        Ad[] randomAds = [];
        foreach int i in 0 ..< self.MAX_ADS_TO_SERVE {
            randomAds.push(allAds[check random:createIntInRange(0, allAds.length())]);
        }
        return randomAds;
    }

    public isolated function getAdsByCategory(string category) returns Ad[] {
        return self.ads.get(category);
    }
}

isolated function getAds() returns map<Ad[]> {
    Ad hairdryer = {
        redirect_url: "/product/2ZYFJ3GM2N",
        text: "Hairdryer for sale. 50% off."
    };
    Ad tankTop = {
        redirect_url: "/product/66VCHSJNUP",
        text: "Tank top for sale. 20% off."
    };
    Ad candleHolder = {
        redirect_url: "/product/0PUK6V6EV0",
        text: "Candle holder for sale. 30% off."
    };
    Ad bambooGlassJar = {
        redirect_url: "/product/9SIQT8TOJO",
        text: "Bamboo glass jar for sale. 10% off."
    };
    Ad watch = {
        redirect_url: "/product/1YMWWN1N4O",
        text: "Watch for sale. Buy one, get second kit for free"
    };
    Ad mug = {
        redirect_url: "/product/6E92ZMYYFZ",
        text: "Mug for sale. Buy two, get third one for free"
    };
    Ad loafers = {
        redirect_url: "/product/L9ECAV7KIM",
        text: "Loafers for sale. Buy one, get second one for free"
    };
    return {
        "clothing": [tankTop],
        "accessories": [watch],
        "footwear": [loafers],
        "hair": [hairdryer],
        "decor": [candleHolder],
        "kitchen":[bambooGlassJar, mug]
    };
}