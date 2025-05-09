WITH order_items_clean AS (
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000)) AS order_month,
        "oi"."product_id",
        "oi"."sale_price",
        "ii"."cost"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  AS "oi"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       AS "o"
          ON "oi"."order_id" = "o"."order_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" AS "ii"
          ON "oi"."inventory_item_id" = "ii"."id"
    WHERE "oi"."status"    NOT IN ('Cancelled','Returned')
      AND "oi"."returned_at" IS NULL
      AND "o"."status"     NOT IN ('Cancelled','Returned')
      AND "o"."returned_at" IS NULL
      AND DATE_TRUNC('month',
          TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000)) 
              BETWEEN '2019-01-01' AND '2022-08-01'
), monthly_profit AS (
    SELECT
        order_month,
        "p"."name"                                           AS product_name,
        SUM("oi"."sale_price") - SUM("oi"."cost")            AS profit
    FROM order_items_clean           AS "oi"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS "p"
          ON "oi"."product_id" = "p"."id"
    GROUP BY
        order_month,
        product_name
), ranked_profit AS (
    SELECT
        order_month,
        product_name,
        profit,
        ROW_NUMBER() OVER (PARTITION BY order_month 
                           ORDER BY profit DESC NULLS LAST) AS rn
    FROM monthly_profit
)
SELECT
    TO_CHAR(order_month,'YYYY-MM')  AS month,
    product_name,
    ROUND(profit,4)                 AS profit
FROM ranked_profit
WHERE rn <= 3
ORDER BY
    month,
    profit DESC NULLS LAST;