type AddToCartRequest record{|
    string productId;
    int quantity;
|};

type CheckoutRequest record {|
    string email;
    string street_address;
    int zip_code;
    string city;
    string state;
    string country;
    string credit_card_number;
    int credit_card_expiration_month;
    int credit_card_expiration_year;
    int credit_card_cvv;
|};