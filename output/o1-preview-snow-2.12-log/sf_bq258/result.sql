SELECT
    "year",
    "month",
    "category",
    "total_revenue",
    "total_completed_orders",
    ROUND(
        (("total_revenue" - LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "year", "month"))
         / NULLIF(LAG("total_revenue") OVER (PARTITION BY "category" ORDER BY "year", "month"), 0)) * 100,
        4
    ) AS "Revenue_MoM_Growth(%)",
    ROUND(
        (("total_completed_orders" - LAG("total_completed_orders") OVER (PARTITION BY "category" ORDER BY "year", "month"))
         / NULLIF(LAG("total_completed_orders") OVER (PARTITION BY "category" ORDER BY "year", "month"), 0)) * 100,
        4
    ) AS "Orders_MoM_Growth(%)",
    ROUND("total_cost", 4) AS "total_cost",
    ROUND("total_profit", 4) AS "total_profit",
    ROUND("profit_to_cost_ratio", 4) AS "profit_to_cost_ratio"
FROM (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ(o."delivered_at" / 1e6)) AS "year",
        EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ(o."delivered_at" / 1e6)) AS "month",
        p."category",
        SUM(oi."sale_price") AS "total_revenue",
        COUNT(DISTINCT o."order_id") AS "total_completed_orders",
        SUM(p."cost") AS "total_cost",
        SUM(oi."sale_price" - p."cost") AS "total_profit",
        SUM(oi."sale_price" - p."cost") / NULLIF(SUM(p."cost"), 0) AS "profit_to_cost_ratio"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
    JOIN
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
        ON oi."order_id" = o."order_id"
    JOIN
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
        ON oi."product_id" = p."id"
    WHERE
        o."status" = 'Complete'
        AND TO_TIMESTAMP_NTZ(o."delivered_at" / 1e6) < '2022-01-01'
    GROUP BY
        "year", "month", p."category"
) base_data
ORDER BY
    "year", "month", "category";