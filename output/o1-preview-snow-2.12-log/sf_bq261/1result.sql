SELECT
    TO_CHAR("order_month", 'YYYY-MM-DD') AS "Month",
    "product_name" AS "Product_Name",
    ROUND("total_cost", 4) AS "Total_Cost",
    ROUND("total_profit", 4) AS "Total_Profit"
FROM
(
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)) AS "order_month",
        p."name" AS "product_name",
        SUM(p."cost") AS "total_cost",
        SUM(oi."sale_price" - p."cost") AS "total_profit",
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6))
            ORDER BY SUM(oi."sale_price" - p."cost") DESC NULLS LAST
        ) AS "rank"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON oi."product_id" = p."id"
    WHERE TO_TIMESTAMP_NTZ(oi."created_at" / 1e6) < '2024-01-01'
    GROUP BY "order_month", p."name"
)
WHERE "rank" = 1
ORDER BY "order_month" ASC;