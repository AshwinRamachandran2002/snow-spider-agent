WITH sales_2020 AS (   -- every order‐item sold in 2020
    SELECT
        "product_id",
        TO_CHAR(TO_TIMESTAMP_LTZ("created_at"/1000000), 'YYYY-MM') AS "sale_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE TO_CHAR(TO_TIMESTAMP_LTZ("created_at"/1000000), 'YYYY') = '2020'
),
product_profit AS (    -- distinct products, their profit, and the month of sale
    SELECT DISTINCT
        s."sale_month",
        p."id"                         AS "product_id",
        p."name"                       AS "product_name",
        (p."retail_price" - p."cost")  AS "profit"
    FROM sales_2020 s
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON p."id" = s."product_id"
    WHERE p."retail_price" IS NOT NULL
      AND p."cost"         IS NOT NULL
),
lowest_profit AS (     -- lowest profit recorded in each month
    SELECT
        "sale_month",
        MIN("profit") AS "min_profit"
    FROM product_profit
    GROUP BY "sale_month"
)
SELECT
    pp."sale_month",
    pp."product_name"
FROM product_profit pp
JOIN lowest_profit lp
  ON pp."sale_month" = lp."sale_month"
 AND pp."profit"     = lp."min_profit"
ORDER BY
    pp."sale_month" ASC,
    pp."product_name";