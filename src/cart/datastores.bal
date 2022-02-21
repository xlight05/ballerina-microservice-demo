public type DataStore object {
    function add(string userId, string productId, int quantity);

    function emptyCart(string userId);

    function getCart(string userId) returns Cart;
};

public class InMemoryStore {
    *DataStore;
    map<Cart> store = {};

    function add(string userId, string productId, int quantity) {
        if (self.store.hasKey(userId)) {
            Cart existingCart = self.store.get(userId);
            CartItem[] existingItems = existingCart.items;
            CartItem[] matchedItem = from CartItem item in existingItems
            where item.product_id == productId
            limit 1
            select item;
            if (matchedItem.length()==1) {
                //Update Quantitly
                CartItem item = matchedItem[0];
                if (item.product_id == productId) {
                    item.quantity = item.quantity + quantity;
                }
            } else {
                //Add item
                CartItem newItem = {product_id: productId, quantity: quantity};
                existingItems.push(newItem);
            }
        } else {
            //Add Cart
            Cart newItem = {
                user_id: userId,
                items: [{product_id: productId, quantity: quantity}]
            };
            self.store[userId] = newItem;
        }
    }

    function emptyCart(string userId) {
        _ = self.store.remove(userId);
    }

    function getCart(string userId) returns Cart{
        return self.store.get(userId);
    }
}

public class RedisStore {
    //TODO impl
    *DataStore;
    map<Cart> store = {};

    function add(string userId, string productId, int quantity) {
        if (self.store.hasKey(userId)) {
            Cart existingCart = self.store.get(userId);
            CartItem[] existingItems = existingCart.items;
            boolean isitemExist = false;
            foreach CartItem item in existingItems {
                if (item.product_id == productId) {
                    isitemExist = true;
                }
            }
            if (isitemExist) {
                //Update Quantitly
                //TODO see if we can reduce code
                foreach CartItem item in existingItems {
                    if (item.product_id == productId) {
                        item.quantity = item.quantity + quantity;
                    }
                }
            } else {
                //Add item
                CartItem newItem = {product_id: productId, quantity: quantity};
                existingItems.push(newItem);
            }
        } else {
            //Add Cart
            Cart newItem = {
                user_id: userId,
                items: [{product_id: productId, quantity: quantity}]
            };
            self.store[userId] = newItem;
        }
    }

    function emptyCart(string userId) {
        _ = self.store.remove(userId);
    }

    function getCart(string userId) returns Cart{
        return self.store.get(userId);
    }
}
