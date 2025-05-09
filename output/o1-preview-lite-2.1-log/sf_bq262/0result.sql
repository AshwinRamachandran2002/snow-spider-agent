WITH MonthlyCategoryData AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000), 'YYYY-MM') AS "Month",
        TO_DATE(TO_CHAR(TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000), 'YYYY-MM-01')) AS "Month_Date",
        "p"."category" AS "Product_Category",
        COUNT(DISTINCT "oi"."order_id") AS "Order_Count",
        ROUND(SUM("oi"."sale_price"), 4) AS "Revenue",
        ROUND(SUM("oi"."sale_price" - "p"."cost"), 4) AS "Profit"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS AS "oi"
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS AS "p"
            ON "oi"."product_id" = "p"."id"
    WHERE
        TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000) BETWEEN '2019-06-01' AND '2019-12-31'
    GROUP BY
        TO_CHAR(TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000), 'YYYY-MM'),
        TO_DATE(TO_CHAR(TO_TIMESTAMP_NTZ("oi"."created_at" / 1000000), 'YYYY-MM-01')),
        "p"."category"
)

SELECT
    "Month",
    "Product_Category",
    "Order_Count",
    "Revenue",
    "Profit",
    ROUND((
        ("Order_Count" - LAG("Order_Count") OVER (PARTITION BY "Product_Category" ORDER BY "Month_Date"))
        / NULLIF(LAG("Order_Count") OVER (PARTITION BY "Product_Category" ORDER BY "Month_Date"), 0)
    ) * 100, 4) AS "Order_Count_Growth_Rate",
    ROUND((
        ("Revenue" - LAG("Revenue") OVER (PARTITION BY "Product_Category" ORDER BY "Month_Date"))
        / NULLIF(LAG("Revenue") OVER (PARTITION BY "Product_Category" ORDER BY "Month_Date"), 0)
    ) * 100, 4) AS "Revenue_Growth_Rate",
    ROUND((
        ("Profit" - LAG("Profit") OVER (PARTITION BY "Product_Category" ORDER BY "Month_Date"))
        / NULLIF(LAG("Profit") OVER (PARTITION BY "Product_Category" ORDER BY "Month_Date"), 0)
    ) * 100, 4) AS "Profit_Growth_Rate"
FROM
    MonthlyCategoryData
ORDER BY
    "Month",
    "Product_Category";