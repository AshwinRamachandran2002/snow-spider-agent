WITH profit_by_month_product AS (
    /* 1.  Compute total cost and profit per month & product                          */
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1000000))  AS month_start,
        p."id"                                                        AS product_id,
        p."name"                                                      AS product_name,
        SUM(p."cost")                                                 AS total_cost,
        SUM(oi."sale_price" - p."cost")                               AS total_profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   AS oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      AS p
          ON oi."product_id" = p."id"
    /*  Only include months strictly prior to January‑2024                             */
    WHERE DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
          < DATE '2024-01-01'
    GROUP BY
        month_start,
        product_id,
        product_name
),
ranked AS (
    /* 2. Rank products in each month by total profit (highest first)                 */
    SELECT
        month_start,
        product_name,
        total_cost,
        total_profit,
        RANK() OVER (PARTITION BY month_start ORDER BY total_profit DESC) AS profit_rank
    FROM profit_by_month_product
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM')           AS "month",
    product_name                              AS "top_product_name",
    ROUND(total_cost  , 4)                    AS "total_cost",
    ROUND(total_profit, 4)                    AS "total_profit"
FROM ranked
WHERE profit_rank = 1               /* keep only the most profitable product each month */
ORDER BY month_start;