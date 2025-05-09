/* Lowest-profit product(s) for every month of calendar-year 2020 */
WITH sold_2020 AS (      -- inventory items that were actually sold in 2020
    SELECT
        "product_id",
        TO_TIMESTAMP_NTZ("sold_at" / 1000000) AS "sold_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE "sold_at" BETWEEN 1577836800000000    -- 2020-01-01 00:00:00
                       AND 1609459199000000    -- 2020-12-31 23:59:59
),
profit_data AS (        -- add product info & profit
    SELECT
        DATE_TRUNC('month', s."sold_ts")            AS "month",
        p."name"                                    AS "product_name",
        (p."retail_price" - p."cost")               AS "profit"
    FROM sold_2020 s
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON s."product_id" = p."id"
),
monthly_min AS (        -- minimum profit realised in each month
    SELECT
        "month",
        MIN("profit") AS "min_profit"
    FROM profit_data
    GROUP BY "month"
)
SELECT DISTINCT         -- final list: month & lowest-profit product name(s)
       m."month",
       pd."product_name"
FROM monthly_min m
JOIN profit_data pd
  ON  pd."month"  = m."month"
  AND pd."profit" = m."min_profit"
ORDER BY m."month";