WITH order_item_detail AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))  AS order_month,
        oi."product_id",
        p."name"                                                          AS product_name,
        oi."sale_price",
        p."cost"                                                          AS product_cost
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
      ON oi."product_id" = p."id"
    WHERE DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) < '2024-01-01'
), 

monthly_product_agg AS (
    SELECT
        order_month,
        "product_id",
        product_name,
        SUM(product_cost)                         AS total_cost,
        SUM(oi."sale_price" - product_cost)       AS total_profit
    FROM order_item_detail  oi
    GROUP BY order_month, "product_id", product_name
), 

ranked_products AS (
    SELECT
        order_month,
        "product_id",
        product_name,
        total_cost,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY order_month ORDER BY total_profit DESC) AS rn
    FROM monthly_product_agg
)

SELECT
    TO_CHAR(order_month, 'YYYY-MM') AS "month",
    "product_id",
    product_name,
    total_cost,
    total_profit
FROM ranked_products
WHERE rn = 1
ORDER BY order_month;