SELECT ROUND(AVG("revenue_growth_rate"), 4) AS "Average_Monthly_Revenue_Growth_Rate"
FROM (
    SELECT 
        mr."month",
        mr."monthly_revenue",
        LAG(mr."monthly_revenue") OVER (ORDER BY mr."month") AS "previous_month_revenue",
        CASE 
            WHEN LAG(mr."monthly_revenue") OVER (ORDER BY mr."month") = 0 THEN NULL
            ELSE (mr."monthly_revenue" - LAG(mr."monthly_revenue") OVER (ORDER BY mr."month")) / LAG(mr."monthly_revenue") OVER (ORDER BY mr."month")
        END AS "revenue_growth_rate"
    FROM (
        SELECT 
            DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) AS "month",
            SUM(oi."sale_price") AS "monthly_revenue"
        FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p ON oi."product_id" = p."id"
        WHERE 
            o."delivered_at" IS NOT NULL
            AND p."category" = (
                SELECT "category"
                FROM (
                    SELECT 
                        "category",
                        AVG("growth_rate") AS "avg_growth_rate"
                    FROM (
                        SELECT 
                            "category",
                            "month",
                            "order_count",
                            LAG("order_count") OVER (PARTITION BY "category" ORDER BY "month") AS "previous_order_count",
                            CASE 
                                WHEN LAG("order_count") OVER (PARTITION BY "category" ORDER BY "month") = 0 THEN NULL
                                ELSE ("order_count" - LAG("order_count") OVER (PARTITION BY "category" ORDER BY "month")) / LAG("order_count") OVER (PARTITION BY "category" ORDER BY "month")
                            END AS "growth_rate"
                        FROM (
                            SELECT 
                                p."category",
                                DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) AS "month",
                                COUNT(DISTINCT o."order_id") AS "order_count"
                            FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
                            JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
                            JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p ON oi."product_id" = p."id"
                            WHERE o."delivered_at" IS NOT NULL
                            GROUP BY p."category", "month"
                        ) AS monthly_orders
                    ) AS order_growth_rates
                    WHERE "growth_rate" IS NOT NULL
                    GROUP BY "category"
                ) AS avg_growth_per_category
                ORDER BY "avg_growth_rate" DESC NULLS LAST
                LIMIT 1
            )
        GROUP BY "month"
    ) AS mr
) AS revenue_growth_rates
WHERE "revenue_growth_rate" IS NOT NULL;