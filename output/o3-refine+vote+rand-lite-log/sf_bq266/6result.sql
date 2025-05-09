WITH order_sales_2020 AS (      -- all order–item rows that actually represent a sale in 2020
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ("created_at" / 1000000))                 AS sale_month,
        "product_id",
        p."name"                                                                     AS product_name,
        (p."retail_price" - p."cost")                                                AS profit
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"      p
          ON oi."product_id" = p."id"
    -- keep only rows whose order happened in calendar‑year 2020 and was not cancelled
    WHERE TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at" / 1000000), 'YYYY') = '2020'
      AND oi."status" <> 'Cancelled'
), min_profit_per_month AS (     -- lowest profit observed in each month
    SELECT
        sale_month,
        MIN(profit) AS min_profit
    FROM order_sales_2020
    GROUP BY sale_month
)
SELECT
    TO_CHAR(m.sale_month, 'YYYY-MM')  AS month_yyyy_mm,
    s.product_name,
    s.profit
FROM order_sales_2020        s
JOIN min_profit_per_month    m
     ON  s.sale_month = m.sale_month
     AND s.profit      = m.min_profit
ORDER BY
    m.sale_month,
    s.product_name;