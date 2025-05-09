WITH complete_orders AS (   -- all orders completed before 01‑Jul‑2024
    SELECT  "order_id",
            "created_at"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE   "status" = 'Complete'
      AND   TO_TIMESTAMP_NTZ("created_at"/1000000) < '2024-07-01'
), 
order_lines AS (           -- order lines for those orders
    SELECT  oi."order_id",
            oi."product_id",
            oi."sale_price",
            TO_CHAR( TO_TIMESTAMP_NTZ(co."created_at"/1000000) , 'YYYY-MM')  AS "month"
    FROM    complete_orders  co
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
           ON oi."order_id" = co."order_id"
), 
monthly_product_sales AS ( -- aggregate volume & revenue per product per month
    SELECT  ol."month",
            p."name"                         AS "product_name",
            p."brand",
            p."category",
            COUNT(*)                         AS total_sales,
            SUM(ol."sale_price")             AS total_revenue
    FROM    order_lines          ol
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"  p
           ON p."id" = ol."product_id"
    WHERE   p."brand" IS NOT NULL            -- exclude un‑branded products
    GROUP BY ol."month", p."name", p."brand", p."category"
), 
ranked_products AS (        -- pick top seller each month (volume, then revenue)
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY "month"
                               ORDER BY total_sales DESC,
                                        total_revenue DESC) AS rn
    FROM    monthly_product_sales
)
SELECT  "month",
        "product_name",
        "brand",
        "category",
        total_sales,
        ROUND(total_revenue, 4)  AS total_revenue,
        'Complete'               AS order_status
FROM    ranked_products
WHERE   rn = 1
ORDER BY "month" ASC;