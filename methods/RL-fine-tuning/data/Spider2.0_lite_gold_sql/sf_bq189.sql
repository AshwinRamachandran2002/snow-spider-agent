WITH monthly_order_counts AS (
    SELECT
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) AS "Month",
        COUNT(DISTINCT o."order_id") AS "Order_Count"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
            ON o."order_id" = oi."order_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
            ON oi."product_id" = p."id"
    WHERE
        o."delivered_at" IS NOT NULL
    GROUP BY
        p."category",
        "Month"
),
order_growth_rates AS (
    SELECT
        "category",
        "Month",
        "Order_Count",
        LAG("Order_Count") OVER (
            PARTITION BY "category"
            ORDER BY "Month"
        ) AS "Prev_Order_Count"
    FROM
        monthly_order_counts
),
order_growth_calculated AS (
    SELECT
        "category",
        "Month",
        "Order_Count",
        "Prev_Order_Count",
        CASE
            WHEN "Prev_Order_Count" IS NULL OR "Prev_Order_Count" = 0 THEN NULL
            ELSE ("Order_Count" - "Prev_Order_Count") / "Prev_Order_Count"
        END AS "Order_Growth_Rate"
    FROM
        order_growth_rates
),
avg_order_growth_rate_by_category AS (
    SELECT
        "category",
        ROUND(AVG("Order_Growth_Rate"), 4) AS "Avg_Order_Growth_Rate"
    FROM
        order_growth_calculated
    WHERE
        "Order_Growth_Rate" IS NOT NULL
    GROUP BY
        "category"
),
highest_growth_category AS (
    SELECT
        "category"
    FROM
        avg_order_growth_rate_by_category
    ORDER BY
        "Avg_Order_Growth_Rate" DESC NULLS LAST
    LIMIT 1
),
monthly_revenues AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) AS "Month",
        SUM(oi."sale_price") AS "Revenue"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
            ON o."order_id" = oi."order_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
            ON oi."product_id" = p."id"
        JOIN highest_growth_category hgc
            ON p."category" = hgc."category"
    WHERE
        o."delivered_at" IS NOT NULL
    GROUP BY
        "Month"
),
revenue_growth_rates AS (
    SELECT
        "Month",
        "Revenue",
        LAG("Revenue") OVER (
            ORDER BY "Month"
        ) AS "Prev_Revenue"
    FROM
        monthly_revenues
),
revenue_growth_calculated AS (
    SELECT
        "Month",
        "Revenue",
        "Prev_Revenue",
        CASE
            WHEN "Prev_Revenue" IS NULL OR "Prev_Revenue" = 0 THEN NULL
            ELSE ("Revenue" - "Prev_Revenue") / "Prev_Revenue"
        END AS "Revenue_Growth_Rate"
    FROM
        revenue_growth_rates
)
SELECT
    ROUND(AVG("Revenue_Growth_Rate"), 4) AS "Average_Monthly_Revenue_Growth_Rate"
FROM
    revenue_growth_calculated
WHERE
    "Revenue_Growth_Rate" IS NOT NULL
;