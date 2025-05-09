WITH monthly_product_profit AS (
    /* 1.  Calculate total cost and total profit per product for every month
          (using ORDER_ITEMS creation date, all statuses included)           */
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ("created_at" / 1000000))     AS month_start,
        p."id"                                                   AS product_id,
        p."name"                                                 AS product_name,
        SUM(p."cost")                                            AS total_cost,
        SUM(COALESCE(oi."sale_price",0) - p."cost")              AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
          ON oi."product_id" = p."id"
    WHERE TO_TIMESTAMP_NTZ(oi."created_at" / 1000000) < '2024-01-01'
    GROUP BY month_start, p."id", p."name"
),
ranked_products AS (
    /* 2. Rank products inside each month by their total profit (highest first) */
    SELECT
        month_start,
        product_id,
        product_name,
        total_cost,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY month_start
                           ORDER BY total_profit DESC, product_id ASC) AS rn
    FROM monthly_product_profit
)
SELECT
    TO_CHAR(month_start,'YYYY-MM')         AS "month",
    product_id,
    product_name,
    ROUND(total_cost,   4)                 AS total_cost,
    ROUND(total_profit, 4)                 AS total_profit
FROM ranked_products
WHERE rn = 1       -- keep only the top‑profit product per month
ORDER BY month_start;