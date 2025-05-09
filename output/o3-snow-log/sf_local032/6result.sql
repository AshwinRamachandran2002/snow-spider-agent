WITH delivered_orders AS (   -- only delivered orders
    SELECT 
        "order_id",
        "customer_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDERS"
    WHERE "order_status" = 'delivered'
),

delivered_order_items AS (   -- items that belong to delivered orders
    SELECT 
        oi."seller_id",
        oi."order_id",
        do."customer_id",
        oi."price",
        oi."freight_value"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_ITEMS"  oi
    JOIN delivered_orders                                           do
      ON oi."order_id" = do."order_id"
),

items_with_unique_customer AS (   -- attach the customer_unique_id
    SELECT 
        doi."seller_id",
        doi."order_id",
        c."customer_unique_id",
        doi."price",
        doi."freight_value"
    FROM delivered_order_items                                      doi
    JOIN BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_CUSTOMERS" c
      ON doi."customer_id" = c."customer_id"
),

five_star_orders AS (    -- delivered orders that received a 5-star review
    SELECT DISTINCT "order_id"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_ORDER_REVIEWS"
    WHERE "review_score" = 5
),

five_star_items AS (     -- sellers that participated in those 5-star orders
    SELECT 
        doi."seller_id",
        doi."order_id"
    FROM delivered_order_items doi
    JOIN five_star_orders      fso
      ON doi."order_id" = fso."order_id"
),

-- 1. distinct customer_unique_id per seller
unique_customers AS (
    SELECT 
        "seller_id",
        COUNT(DISTINCT "customer_unique_id") AS value
    FROM items_with_unique_customer
    GROUP BY "seller_id"
),

-- 2. profit (SUM(price-freight_value)) per seller
profit_per_seller AS (
    SELECT
        "seller_id",
        SUM("price" - "freight_value") AS value
    FROM delivered_order_items
    GROUP BY "seller_id"
),

-- 3. distinct delivered orders per seller
orders_per_seller AS (
    SELECT
        "seller_id",
        COUNT(DISTINCT "order_id") AS value
    FROM delivered_order_items
    GROUP BY "seller_id"
),

-- 4. 5-star ratings per seller
five_star_per_seller AS (
    SELECT
        "seller_id",
        COUNT(DISTINCT "order_id") AS value
    FROM five_star_items
    GROUP BY "seller_id"
),

-- pick the top seller for each metric
top_unique_customers AS (
    SELECT 
        'Most Distinct Customers'  AS description,
        "seller_id",
        value
    FROM unique_customers
    QUALIFY value = MAX(value) OVER ()
),

top_profit AS (
    SELECT 
        'Highest Profit'           AS description,
        "seller_id",
        value
    FROM profit_per_seller
    QUALIFY value = MAX(value) OVER ()
),

top_orders AS (
    SELECT 
        'Most Distinct Orders'     AS description,
        "seller_id",
        value
    FROM orders_per_seller
    QUALIFY value = MAX(value) OVER ()
),

top_five_star AS (
    SELECT 
        'Most 5-Star Ratings'      AS description,
        "seller_id",
        value
    FROM five_star_per_seller
    QUALIFY value = MAX(value) OVER ()
)

-- final result
SELECT * FROM top_unique_customers
UNION ALL
SELECT * FROM top_profit
UNION ALL
SELECT * FROM top_orders
UNION ALL
SELECT * FROM top_five_star;