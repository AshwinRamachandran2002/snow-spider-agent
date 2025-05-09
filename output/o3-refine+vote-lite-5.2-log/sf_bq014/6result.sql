WITH "valid_orders" AS (          -- all orders that are NOT cancelled / returned
    SELECT
        "o"."order_id",
        "o"."user_id",
        "o"."created_at"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" AS "o"
    WHERE "o"."status" <> 'Cancelled'
      AND "o"."returned_at" IS NULL
),
"first_orders" AS (               -- first valid order for every customer
    SELECT
        "t"."order_id",
        "t"."user_id"
    FROM (
        SELECT
            "vo".*,
            ROW_NUMBER() OVER (PARTITION BY "vo"."user_id"
                               ORDER BY "vo"."created_at") AS "rn"
        FROM "valid_orders" AS "vo"
    ) AS "t"
    WHERE "t"."rn" = 1
),
"first_order_items" AS (          -- items belonging to those first orders
    SELECT
        "fo"."user_id",
        "oi"."order_id",
        "oi"."product_id",
        "oi"."sale_price"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS "oi"
    JOIN "first_orders" AS "fo"
      ON "fo"."order_id" = "oi"."order_id"
    WHERE "oi"."status" <> 'Cancelled'
      AND "oi"."returned_at" IS NULL
),
"category_customers" AS (         -- number of distinct customers per category
    SELECT
        "p"."category",
        COUNT(DISTINCT "foi"."user_id") AS "customer_cnt"
    FROM "first_order_items" AS "foi"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS "p"
      ON "p"."id" = "foi"."product_id"
    GROUP BY "p"."category"
),
"top_category" AS (               -- category with the highest customer count
    SELECT "cc"."category"
    FROM "category_customers" AS "cc"
    ORDER BY "cc"."customer_cnt" DESC NULLS LAST, "cc"."category"
    FETCH FIRST 1 ROW ONLY
)
SELECT
    "tc"."category"          AS "product_category_with_most_first_time_customers",
    SUM("foi"."sale_price")  AS "total_revenue"
FROM "first_order_items" AS "foi"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS "p"
  ON "p"."id" = "foi"."product_id"
JOIN "top_category" AS "tc"
  ON "tc"."category" = "p"."category"
GROUP BY "tc"."category";