WITH valid_orders AS (
    SELECT
        "order_id",
        "user_id",
        "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" <> 'Cancelled'
      AND "returned_at" IS NULL
),
first_orders AS (
    SELECT
        "user_id",
        MIN("created_at") AS "first_created_at"
    FROM valid_orders
    GROUP BY "user_id"
),
first_order_ids AS (
    SELECT
        vo."order_id",
        vo."user_id"
    FROM valid_orders vo
    JOIN first_orders fo
      ON  fo."user_id"      = vo."user_id"
     AND fo."first_created_at" = vo."created_at"
),
first_order_items AS (
    SELECT
        oi."order_id",
        oi."user_id",
        oi."product_id",
        oi."sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN first_order_ids foi
      ON foi."order_id" = oi."order_id"
    WHERE oi."returned_at" IS NULL
),
category_stats AS (
    SELECT
        p."category",
        COUNT(DISTINCT foi."user_id") AS "customer_count",
        SUM(foi."sale_price")        AS "revenue"
    FROM first_order_items foi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON p."id" = foi."product_id"
    GROUP BY p."category"
),
top_category AS (
    SELECT
        "category",
        "revenue"
    FROM category_stats
    ORDER BY "customer_count" DESC NULLS LAST,
             "revenue"        DESC NULLS LAST
    LIMIT 1
)
SELECT
    "category",
    ROUND("revenue", 4) AS "revenue"
FROM top_category;