SELECT
       TO_CHAR(month_ts, 'YYYY-MM') AS "month",
       product_name                 AS "product_name"
FROM (
        SELECT
               DATE_TRUNC('month', TO_TIMESTAMP(i."sold_at" / 1e6))           AS month_ts,
               p."name"                                                      AS product_name,
               (p."retail_price" - p."cost")                                 AS profit,
               MIN(p."retail_price" - p."cost")
                 OVER (PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP(i."sold_at" / 1e6))) AS min_profit
        FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS i
        JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS        p
               ON i."product_id" = p."id"
        WHERE  i."sold_at" IS NOT NULL
          AND  TO_TIMESTAMP(i."sold_at" / 1e6) >= '2020-01-01'
          AND  TO_TIMESTAMP(i."sold_at" / 1e6) <  '2021-01-01'
     )
WHERE  profit = min_profit
GROUP BY month_ts, product_name
ORDER BY month_ts, product_name;