/*  Products with the lowest profit (retail_price ‑ cost) in every month of 2020 */
WITH sales_2020 AS (   -- all inventory items that were actually sold in 2020
    SELECT
        ii."product_id",
        DATE_TRUNC('MONTH',
                   TO_TIMESTAMP_NTZ(ii."sold_at" / 1000000)) AS "sale_month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  AS ii
    WHERE ii."sold_at" IS NOT NULL
      AND YEAR(TO_TIMESTAMP_NTZ(ii."sold_at" / 1000000)) = 2020
),
product_profit AS (    -- one row per product per month with its profit
    SELECT DISTINCT
        s."sale_month",
        p."name"  AS "product_name",
        (p."retail_price" - p."cost") AS "profit"
    FROM sales_2020                                       AS s
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"  AS p
          ON p."id" = s."product_id"
),
ranked AS (            -- rank products by (lowest) profit within each month
    SELECT
        "sale_month",
        "product_name",
        "profit",
        RANK() OVER (PARTITION BY "sale_month"
                     ORDER BY "profit" ASC) AS rnk
    FROM product_profit
)
SELECT
    TO_CHAR("sale_month", 'YYYY-MM') AS "MONTH",
    "product_name"                   AS "PRODUCT_NAME"
FROM ranked
WHERE rnk = 1                       -- keep only the lowest-profit product(s)
ORDER BY "sale_month";