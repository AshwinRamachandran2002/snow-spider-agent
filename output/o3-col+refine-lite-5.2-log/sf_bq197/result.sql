/*  Best‑selling product for every month prior to July 2024  */
WITH agg AS (     -- aggregate monthly unit & revenue totals
    SELECT  DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))  AS "order_month",
            p."id"                                                       AS "product_id",
            COUNT(*)                                                     AS "units_sold",
            SUM(oi."sale_price")                                         AS "revenue"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
            ON oi."product_id" = p."id"
    WHERE   oi."status" = 'Complete'
      AND   p."brand"   IS NOT NULL
      AND   DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) < DATE '2024-07-01'
    GROUP BY 1, 2
),
ranked AS (       -- rank products inside each month
    SELECT  agg.*,
            ROW_NUMBER() OVER (PARTITION BY agg."order_month"
                               ORDER BY agg."units_sold" DESC,
                                        agg."revenue"    DESC)           AS rn
    FROM    agg
)
SELECT  ranked."order_month"                          AS "month",
        prod."name"                                   AS "product_name",
        prod."brand",
        prod."category",
        ranked."units_sold"                           AS "total_sales",
        ROUND(ranked."revenue", 2)                    AS "rounded_total_revenue",
        'Complete'                                    AS "order_status"
FROM    ranked
JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" prod
        ON ranked."product_id" = prod."id"
WHERE   ranked.rn = 1
ORDER BY ranked."order_month";