/* Top-3 most-profitable products per month (Jan-2019 ‑ Aug-2022) */
WITH order_sales AS (       /* 1. completed, non-returned order items */
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP("OI"."created_at" / 1000000)
        )                                 AS sale_month,
        "OI"."product_id",
        "OI"."sale_price",
        "II"."cost"                      AS item_cost
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS      AS "OI"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS           AS "O"
           ON "OI"."order_id" = "O"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS  AS "II"
           ON "OI"."inventory_item_id" = "II"."id"
    WHERE "O"."status"       NOT IN ('Cancelled', 'Returned')
      AND "OI"."status"      NOT IN ('Cancelled', 'Returned')
      AND "OI"."returned_at" IS NULL
      AND TO_TIMESTAMP("OI"."created_at" / 1000000)
            BETWEEN '2019-01-01' AND '2022-08-31 23:59:59'
), profit_by_product AS (    /* 2. revenue & cost per product per month */
    SELECT
        sale_month,
        "P"."name"                        AS product_name,
        SUM(OS."sale_price")              AS revenue,
        SUM(OS.item_cost)                 AS cost
    FROM order_sales OS
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS AS "P"
          ON OS."product_id" = "P"."id"
    GROUP BY sale_month, product_name
), ranked AS (               /* 3. rank products by monthly profit */
    SELECT
        sale_month,
        product_name,
        revenue - cost                       AS profit,
        DENSE_RANK() OVER (
            PARTITION BY sale_month
            ORDER BY revenue - cost DESC
        )                                    AS rnk
    FROM profit_by_product
)
SELECT
    TO_CHAR(sale_month, 'YYYY-MM')  AS month,
    product_name,
    ROUND(profit, 4)                AS profit
FROM ranked
WHERE rnk <= 3
ORDER BY sale_month, rnk NULLS LAST;