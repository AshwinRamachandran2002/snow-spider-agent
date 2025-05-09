WITH monthly_product_profit AS (
    /* 1.  Aggregate cost and profit per product and calendar month                */
    SELECT
        -- convert micro-second epoch to timestamp and truncate to first day of month
        TRUNC(
            TO_TIMESTAMP_NTZ("created_at" / 1000000),      -- μs → s → TIMESTAMP
            'MONTH'
        )                                   AS "order_month",
        oi."product_id"                     AS "product_id",
        SUM(p."cost")                       AS "total_cost",
        SUM(oi."sale_price" - p."cost")     AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
      ON oi."product_id" = p."id"
    GROUP BY
        1, 2
),
ranked AS (
    /* 2.  Rank products by profit within each month                               */
    SELECT
        "order_month",
        "product_id",
        "total_cost",
        "total_profit",
        RANK() OVER (
            PARTITION BY "order_month"
            ORDER BY "total_profit" DESC NULLS LAST
        ) AS "rnk"
    FROM monthly_product_profit
)
-- 3. Pick the #1 product per month (rnk = 1) prior to 2024-01 and show results
SELECT
    TO_CHAR("order_month", 'YYYY-MM') AS "month",
    "product_id",
    "total_cost",
    "total_profit"
FROM ranked
WHERE "rnk" = 1
  AND "order_month" < DATE '2024-01-01'
ORDER BY
    "order_month";