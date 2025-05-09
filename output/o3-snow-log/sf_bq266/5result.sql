WITH order_sales_2020 AS (
    SELECT
        oi."product_id",
        p."name"                                         AS "product_name",
        p."retail_price" - p."cost"                      AS "profit",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) AS "month"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON oi."product_id" = p."id"
    WHERE oi."status" <> 'Cancelled'
      AND DATE_PART('year', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000)) = 2020
),

monthly_min_profit AS (
    SELECT
        "month",
        MIN("profit") AS "min_profit"
    FROM order_sales_2020
    GROUP BY "month"
)

SELECT DISTINCT
       TO_CHAR(mmp."month", 'YYYY-MM') AS "month",
       os."product_name"
FROM monthly_min_profit  mmp
JOIN order_sales_2020    os
     ON  os."month"  = mmp."month"
     AND os."profit" = mmp."min_profit"
ORDER BY "month" ASC;