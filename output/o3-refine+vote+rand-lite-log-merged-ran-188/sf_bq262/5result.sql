WITH order_items_2019 AS (  /*  Every line‑item that belongs to an order created Jun‑Dec 2019  */
    SELECT
        oi."order_id",
        TO_CHAR( DATE_TRUNC('month',
                 TO_TIMESTAMP_NTZ( o."created_at" / 1000000 ) ) , 'YYYY-MM')               AS "month",
        p."category"                                                                     AS "product_category",
        oi."sale_price",
        COALESCE(ii."cost", p."cost", 0)                                                 AS "cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS        oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS             o  ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS           p  ON oi."product_id" = p."id"
    LEFT JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii ON oi."inventory_item_id" = ii."id"
    /* orders created between 2019‑06‑01 (inclusive) and 2020‑01‑01 (exclusive) */
    WHERE o."created_at" >= 1559347200000000      -- 2019-06-01 00:00:00 UTC in µs
      AND o."created_at" <  1577836800000000      -- 2020-01-01 00:00:00 UTC in µs
),

monthly AS (   /*  aggregate per month & category  */
    SELECT
        "month",
        "product_category",
        COUNT( DISTINCT "order_id")                                     AS total_orders,
        ROUND( SUM("sale_price")                         , 4)           AS total_revenue,
        ROUND( SUM("sale_price" - "cost")                , 4)           AS total_profit
    FROM order_items_2019
    GROUP BY "month", "product_category"
),

with_growth AS (   /*  MoM growth using June as the baseline (lag)  */
    SELECT
        m."month",
        m."product_category",
        m.total_orders,
        m.total_revenue,
        m.total_profit,

        ROUND( (m.total_orders  - LAG(m.total_orders)  OVER (PARTITION BY m."product_category" ORDER BY m."month"))
               / NULLIF( LAG(m.total_orders)  OVER (PARTITION BY m."product_category" ORDER BY m."month"), 0), 4)
               AS orders_mom_growth,

        ROUND( (m.total_revenue - LAG(m.total_revenue) OVER (PARTITION BY m."product_category" ORDER BY m."month"))
               / NULLIF( LAG(m.total_revenue) OVER (PARTITION BY m."product_category" ORDER BY m."month"), 0), 4)
               AS revenue_mom_growth,

        ROUND( (m.total_profit  - LAG(m.total_profit)  OVER (PARTITION BY m."product_category" ORDER BY m."month"))
               / NULLIF( LAG(m.total_profit)  OVER (PARTITION BY m."product_category" ORDER BY m."month"), 0), 4)
               AS profit_mom_growth
    FROM monthly m
)

SELECT
    "month",
    "product_category",
    total_orders,
    total_revenue,
    total_profit,
    orders_mom_growth,
    revenue_mom_growth,
    profit_mom_growth
FROM with_growth
WHERE "month" <> '2019-06'          -- omit June from the final output
ORDER BY "month", "product_category";