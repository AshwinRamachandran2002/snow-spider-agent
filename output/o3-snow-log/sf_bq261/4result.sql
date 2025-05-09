/* -------------------------------------------------------
   Top-profit product for each month before 2024-01
   (profit = Σ(sale_price – product_cost))
-------------------------------------------------------*/
WITH order_items_enriched AS (           -- add cost & month
    SELECT
        oi."product_id",
        p."name"          AS "product_name",
        p."cost"          AS "product_cost",
        oi."sale_price",
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP(oi."created_at" / 1000000)
        )                 AS month_start
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
      ON oi."product_id" = p."id"
    WHERE oi."created_at" IS NOT NULL
),

product_month_profit AS (                -- sum by product & month
    SELECT
        month_start,
        "product_id",
        "product_name",
        SUM("product_cost")                    AS total_cost,
        SUM("sale_price" - "product_cost")     AS total_profit
    FROM order_items_enriched
    WHERE month_start < DATE '2024-01-01'
    GROUP BY month_start, "product_id", "product_name"
),

ranked AS (                              -- pick best per month
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY month_start
            ORDER BY total_profit DESC NULLS LAST
        ) AS rn
    FROM product_month_profit
)

SELECT
    TO_CHAR(month_start, 'YYYY-MM') AS "month",
    "product_name",
    ROUND(total_cost , 4)           AS "total_cost",
    ROUND(total_profit, 4)          AS "total_profit"
FROM ranked
WHERE rn = 1
ORDER BY month_start;