/*  Lowest-profit product(s) sold in each 2020 month.
    For every month that contains at least one sale, we find the minimum
    (retail_price – cost) among the products sold that month and list all
    product names that share that minimum value, in chronological order.
*/
WITH monthly_sales AS (          -- 2020 sales with month stamp
    SELECT  "product_id",
            TO_CHAR(TO_TIMESTAMP_NTZ("sold_at" / 1e6),'YYYY-MM') AS "sale_month"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE   "sold_at" BETWEEN 1577836800000000       -- 2020-01-01
                           AND 1609459199000000       -- 2020-12-31
),
product_profit AS (              -- attach profit for each product sold
    SELECT  ms."sale_month",
            p."id"                      AS "product_id",
            p."name",
            (p."retail_price" - p."cost") AS "profit"
    FROM    monthly_sales ms
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
            ON p."id" = ms."product_id"
),
min_profit_per_month AS (        -- month-specific minimum profit
    SELECT  "sale_month",
            MIN("profit") AS "min_profit"
    FROM    product_profit
    GROUP BY "sale_month"
)
SELECT  pp."sale_month",
        LISTAGG(DISTINCT pp."name", ', ')
            WITHIN GROUP (ORDER BY pp."name") AS "product_names"
FROM    product_profit        pp
JOIN    min_profit_per_month  mp
          ON pp."sale_month" = mp."sale_month"
         AND pp."profit"     = mp."min_profit"
GROUP BY pp."sale_month"
ORDER BY pp."sale_month";