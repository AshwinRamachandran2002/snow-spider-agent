/* 1.  Capture every product that recorded at least one sale in each
       calendar month of 2020 (defined by ORDER_ITEMS.CREATED_AT).        */
/* 2.  Calculate the profit of every product (retail_price ‑ cost).       */
/* 3.  For every month, find the minimum profit among products that sold. */
/* 4.  Return the product name(s) that reach this minimum for the month,  */
/*     ordered chronologically.                                           */

WITH sales_2020 AS (          -- every product that sold in 2020
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP("created_at" / 1000000))   AS "month",
        "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE EXTRACT(year FROM TO_TIMESTAMP("created_at" / 1000000)) = 2020
          AND COALESCE("status", '') <> 'Cancelled'        -- count only real sales
),
product_profit AS (           -- profit for every product in catalogue
    SELECT
        "id"                  AS "product_id",
        "name"                AS "product_name",
        ("retail_price" - "cost") AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"
),
monthly_min_profit AS (       -- minimum profit per month among sold items
    SELECT
        s."month",
        MIN(pp."profit")      AS "min_profit"
    FROM sales_2020           AS s
    JOIN product_profit       AS pp
      ON pp."product_id" = s."product_id"
    GROUP BY s."month"
)
SELECT
    m."month",
    pp."product_name",
    pp."profit"               AS "lowest_profit"
FROM sales_2020               AS s
JOIN product_profit           AS pp
  ON pp."product_id" = s."product_id"
JOIN monthly_min_profit       AS m
  ON m."month" = s."month"
 AND m."min_profit" = pp."profit"     -- keep only product(s) with lowest profit
GROUP BY m."month", pp."product_name", pp."profit"
ORDER BY m."month" ASC;               -- chronological order