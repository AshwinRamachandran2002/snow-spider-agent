WITH sale_items AS (   -- order‑level records that occurred during 2020
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at"/1000000)) AS "sale_month",
        "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE DATE_PART('year', TO_TIMESTAMP_NTZ("created_at"/1000000)) = 2020
          AND "status" NOT IN ('Cancelled','Returned')          -- keep only real sales
),
product_profit AS (     -- profit (retail – cost) for every product
    SELECT
        "id"  AS "product_id",
        "name" AS "product_name",
        ("retail_price" - "cost") AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"
),
month_min_profit AS (   -- minimum profit observed in each month
    SELECT
        s."sale_month",
        MIN(p."profit") AS "min_profit"
    FROM sale_items         s
    JOIN product_profit p ON s."product_id" = p."product_id"
    GROUP BY s."sale_month"
),
month_lowest_products AS (  -- products whose profit equals that month’s minimum
    SELECT DISTINCT
        m."sale_month",
        p."product_name"
    FROM month_min_profit m
    JOIN sale_items      s ON s."sale_month" = m."sale_month"
    JOIN product_profit  p ON s."product_id" = p."product_id"
    WHERE p."profit" = m."min_profit"
)
SELECT
    TO_CHAR("sale_month", 'YYYY-MM') AS "month",
    "product_name"
FROM month_lowest_products
ORDER BY "sale_month" ASC, "product_name";