WITH first_valid_orders AS (          -- a customer's first order that is neither cancelled nor returned
    SELECT  "order_id",
            "user_id"
    FROM   (
            SELECT  "order_id",
                    "user_id",
                    "created_at",
                    ROW_NUMBER() OVER (PARTITION BY "user_id"
                                       ORDER BY "created_at") AS rn
            FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
            WHERE  "status"      <> 'Cancelled'
              AND  "returned_at" IS NULL
           )
    WHERE  rn = 1
),

first_order_items AS (               -- items in those first valid orders
    SELECT  f."user_id",
            oi."order_id",
            oi."product_id",
            oi."sale_price"
    FROM   first_valid_orders f
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
           ON oi."order_id" = f."order_id"
    WHERE  oi."status"      <> 'Cancelled'
      AND  oi."returned_at" IS NULL
),

items_with_category AS (             -- add product category
    SELECT  i."user_id",
            p."category",
            i."sale_price"
    FROM   first_order_items i
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
           ON p."id" = i."product_id"
),

category_customer_counts AS (        -- number of customers whose first order included each category
    SELECT  "category",
            COUNT(DISTINCT "user_id") AS customer_count
    FROM    items_with_category
    GROUP BY "category"
),

top_category AS (                    -- category with the most such customers
    SELECT  "category"
    FROM    category_customer_counts
    ORDER BY customer_count DESC NULLS LAST
    LIMIT 1
)

-- revenue produced by that top category in those first orders
SELECT  tc."category",
        ccc.customer_count,
        SUM(iwc."sale_price") AS revenue
FROM    top_category tc
JOIN    category_customer_counts ccc   ON ccc."category" = tc."category"
JOIN    items_with_category      iwc   ON iwc."category" = tc."category"
GROUP BY tc."category", ccc.customer_count;