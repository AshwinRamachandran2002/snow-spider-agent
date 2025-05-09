/*  Products with the lowest profit (retail_price – cost) for every
    month in calendar-year 2020, listed chronologically              */

WITH profit_per_item AS (           -- bring every 2020 sale together
    SELECT
        TO_CHAR( TO_TIMESTAMP_NTZ(oi."created_at" / 1000000) , 'YYYY-MM')  AS "order_month",
        p."name"                                                          AS "product_name",
        p."retail_price" - p."cost"                                       AS "profit"
    FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)
              BETWEEN '2020-01-01' AND '2020-12-31 23:59:59.999'
),
month_min AS (                      -- find the minimum profit per month
    SELECT
        "order_month",
        MIN("profit") AS "min_profit"
    FROM  profit_per_item
    GROUP BY "order_month"
)

SELECT DISTINCT                     -- list product(s) that hit that minimum
       ppi."order_month",
       ppi."product_name"
FROM   profit_per_item  ppi
JOIN   month_min        mm
       ON  ppi."order_month" = mm."order_month"
       AND ppi."profit"       = mm."min_profit"
ORDER  BY ppi."order_month",
          ppi."product_name";