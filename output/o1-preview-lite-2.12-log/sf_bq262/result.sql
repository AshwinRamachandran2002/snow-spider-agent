WITH june_data AS (
    SELECT
        p."category" AS "Product_Category",
        COUNT(DISTINCT o."order_id") AS "June_Total_Orders",
        SUM(oi."sale_price") AS "June_Total_Revenue",
        SUM(oi."sale_price" - p."cost") AS "June_Total_Profit"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p ON oi."product_id" = p."id"
    WHERE
        TO_TIMESTAMP_NTZ(o."created_at" / 1e6) BETWEEN '2019-06-01' AND '2019-06-30'
    GROUP BY
        p."category"
),
monthly_data AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM') AS "Month",
        p."category" AS "Product_Category",
        COUNT(DISTINCT o."order_id") AS "Total_Orders",
        SUM(oi."sale_price") AS "Total_Revenue",
        SUM(oi."sale_price" - p."cost") AS "Total_Profit"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi ON o."order_id" = oi."order_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p ON oi."product_id" = p."id"
    WHERE
        TO_TIMESTAMP_NTZ(o."created_at" / 1e6) BETWEEN '2019-07-01' AND '2019-12-31'
    GROUP BY
        "Month", p."category"
)
SELECT
    md."Month",
    md."Product_Category",
    md."Total_Orders",
    md."Total_Revenue",
    md."Total_Profit",
    ROUND(((md."Total_Orders" - jd."June_Total_Orders") / NULLIF(jd."June_Total_Orders", 0)) * 100, 4) AS "MoM_Growth_Orders(%)",
    ROUND(((md."Total_Revenue" - jd."June_Total_Revenue") / NULLIF(jd."June_Total_Revenue", 0)) * 100, 4) AS "MoM_Growth_Revenue(%)",
    ROUND(((md."Total_Profit" - jd."June_Total_Profit") / NULLIF(jd."June_Total_Profit", 0)) * 100, 4) AS "MoM_Growth_Profit(%)"
FROM
    monthly_data md
    LEFT JOIN june_data jd ON md."Product_Category" = jd."Product_Category"
ORDER BY
    md."Month" ASC,
    md."Product_Category" ASC;