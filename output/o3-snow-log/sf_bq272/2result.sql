/*  Top-3 most profitable products (by month)  */
/*  Period covered : 2019-01 through 2022-08    */

WITH per_item AS (                -- profit components by product & month
    SELECT
        DATE_TRUNC('month'
          , TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000) )          AS "order_month",
        "oi"."product_id"                                            AS "product_id",
        SUM("oi"."sale_price")                                       AS "total_sales",
        SUM("ii"."cost")                                             AS "total_cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"       AS "o"
         ON  "oi"."order_id" = "o"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" AS "ii"
         ON  "oi"."inventory_item_id" = "ii"."id"
    WHERE
          "oi"."status"  NOT IN ('Cancelled', 'Returned')         -- exclude cancelled / returned items
      AND "o"."status"   NOT IN ('Cancelled', 'Returned')         -- exclude cancelled / returned orders
      AND TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000)
              BETWEEN '2019-01-01' AND '2022-08-31 23:59:59'      -- required period
    GROUP BY
        "order_month",
        "oi"."product_id"
),

profit_calc AS (                 -- calculate profit and rank inside each month
    SELECT
        "pi"."order_month",
        "p"."name"                                  AS "product_name",
        ("pi"."total_sales" - "pi"."total_cost")    AS "profit",
        ROW_NUMBER() OVER (
              PARTITION BY "pi"."order_month"
              ORDER BY ("pi"."total_sales" - "pi"."total_cost") DESC
        )                                           AS "rn"
    FROM per_item               AS "pi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" AS "p"
         ON  "pi"."product_id" = "p"."id"
)

SELECT
    TO_CHAR("order_month", 'YYYY-MM')  AS "month",
    "product_name",
    ROUND("profit", 4)                AS "profit"
FROM profit_calc
WHERE "rn" <= 3                       -- top-3 per month
ORDER BY
    "order_month",
    "profit" DESC NULLS LAST;