WITH monthly_product_profit AS (
    SELECT 
        DATE_TRUNC(
            'month', 
            TO_TIMESTAMP("oi"."created_at" / 1000000)
        )                                             AS "month_start",
        "oi"."product_id"                             AS "product_id",
        "p"."name"                                    AS "product_name",
        SUM("oi"."sale_price")                        AS "total_revenue",
        SUM("ii"."cost")                              AS "total_cost",
        SUM("oi"."sale_price") - SUM("ii"."cost")     AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS       AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS            AS "o"
         ON "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS   AS "ii"
         ON "oi"."inventory_item_id" = "ii"."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS          AS "p"
         ON "oi"."product_id" = "p"."id"
    WHERE 
          TO_TIMESTAMP("oi"."created_at" / 1000000) >= '2019-01-01' 
      AND TO_TIMESTAMP("oi"."created_at" / 1000000) <  '2022-09-01'
      -- exclude cancelled / returned orders or items
      AND "o"."status"      NOT IN ('Cancelled', 'Returned')
      AND "oi"."status"     NOT IN ('Cancelled', 'Returned')
      AND "oi"."returned_at" IS NULL
    GROUP BY 
        "month_start",
        "oi"."product_id",
        "p"."name"
), ranked_products AS (
    SELECT
        "month_start",
        "product_id",
        "product_name",
        "profit",
        ROW_NUMBER() OVER (
            PARTITION BY "month_start" 
            ORDER BY "profit" DESC NULLS LAST, "product_name"
        ) AS "rank_in_month"
    FROM monthly_product_profit
)
SELECT
    "month_start",
    "product_name",
    "product_id",
    "profit"
FROM ranked_products
WHERE "rank_in_month" <= 3
ORDER BY 
    "month_start",
    "rank_in_month";