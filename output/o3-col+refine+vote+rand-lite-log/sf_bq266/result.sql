/*  Products with the lowest profit (retail_price − cost) for every month that had sales in 2020,
    listed chronologically by month                                             */
WITH sales_2020 AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at" / 1000000), 'YYYY-MM')   AS "year_month",
        p."name"                                                          AS "product_name",
        (p."retail_price" - p."cost")                                     AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at" / 1000000), 'YYYY') = '2020'
),
monthly_min AS (
    SELECT
        "year_month",
        MIN("profit") AS "min_profit"
    FROM sales_2020
    GROUP BY "year_month"
)
SELECT
    s."year_month",
    s."product_name"
FROM sales_2020      s
JOIN monthly_min     m
  ON s."year_month" = m."year_month"
 AND s."profit"     = m."min_profit"
GROUP BY s."year_month", s."product_name"
ORDER BY s."year_month";