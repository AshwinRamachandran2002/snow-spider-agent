/* -------------------------------------------------------------
   Lowest-profit product(s) whose 2020 sales covered the greatest
   possible number of distinct months (i.e., every month in which
   ANY sale occurred).  Results are shown month-by-month in
   chronological order.
   ------------------------------------------------------------- */
WITH sales_2020 AS (                    -- every 2020 sale (month-granular)
    SELECT
        "product_id",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("sold_at" / 1000000)) AS "sale_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE "sold_at" IS NOT NULL
      AND YEAR(TO_TIMESTAMP_NTZ("sold_at" / 1000000)) = 2020
),

product_month_counts AS (               -- how many 2020 months each product sold in
    SELECT
        "product_id",
        COUNT(DISTINCT "sale_month") AS "cnt_months"
    FROM sales_2020
    GROUP BY "product_id"
),

max_months AS (                         -- highest month-coverage achieved by any product
    SELECT MAX("cnt_months") AS "max_cnt"
    FROM product_month_counts
),

best_coverage_products AS (             -- products that achieved that maximum coverage
    SELECT pm."product_id"
    FROM product_month_counts pm
    JOIN max_months m
      ON pm."cnt_months" = m."max_cnt"
),

profit_tbl AS (                         -- profit for those best-coverage products
    SELECT
        p."id"                                    AS "product_id",
        p."name",
        (p."retail_price" - p."cost")             AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    JOIN best_coverage_products bcp
      ON p."id" = bcp."product_id"
),

min_profit AS (                         -- minimum profit among best-coverage products
    SELECT MIN("profit") AS "min_profit"
    FROM profit_tbl
)

SELECT
    s."sale_month",
    pt."name"  AS "product_name"
FROM sales_2020           s
JOIN profit_tbl           pt  ON pt."product_id" = s."product_id"
JOIN min_profit           mp  ON pt."profit"     = mp."min_profit"
ORDER BY s."sale_month";                 -- chronological order