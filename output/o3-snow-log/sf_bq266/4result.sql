/*  Lowest-profit products that registered at least one sale
    in every month of 2020, shown in chronological order       */

WITH monthly_sales AS (   -- all product sales inside 2020
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP("oi"."created_at" / 1000000)) AS "month_start",
        "p"."name"                                                   AS "product_name",
        ("p"."retail_price" - "p"."cost")                            AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  AS "oi"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     AS "p"
         ON "oi"."product_id" = "p"."id"
    WHERE "oi"."created_at"
          BETWEEN 1577836800000000          -- 2020-01-01 00:00:00 µs
              AND 1609459199000000          -- 2020-12-31 23:59:59 µs
),
monthly_min AS (          -- lowest profit recorded each month
    SELECT
        "month_start",
        MIN("profit") AS "min_profit"
    FROM monthly_sales
    GROUP BY "month_start"
)

SELECT
    TO_CHAR(ms."month_start", 'YYYY-MM') AS "month",
    ms."product_name"
FROM monthly_sales ms
JOIN monthly_min mm
  ON  ms."month_start" = mm."month_start"
  AND ms."profit"      = mm."min_profit"
ORDER BY ms."month_start" ASC,           -- chronological
         ms."product_name";