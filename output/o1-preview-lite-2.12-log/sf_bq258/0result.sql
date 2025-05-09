WITH category_monthly AS (
  SELECT
    EXTRACT(YEAR FROM TO_TIMESTAMP("ORDERS"."delivered_at" / 1e6)) AS "Year",
    EXTRACT(MONTH FROM TO_TIMESTAMP("ORDERS"."delivered_at" / 1e6)) AS "Month",
    "PRODUCTS"."category" AS "Category",
    SUM("ORDER_ITEMS"."sale_price") AS "Total_Revenue",
    COUNT(DISTINCT "ORDERS"."order_id") AS "Total_Completed_Orders",
    SUM("PRODUCTS"."cost") AS "Total_Cost"
  FROM
    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS 
      ON "ORDERS"."order_id" = "ORDER_ITEMS"."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS 
      ON "ORDER_ITEMS"."product_id" = "PRODUCTS"."id"
  WHERE
    "ORDERS"."status" = 'Complete'
    AND TO_TIMESTAMP("ORDERS"."delivered_at" / 1e6) < '2022-01-01'
  GROUP BY
    "Year",
    "Month",
    "Category"
),
category_monthly_with_lag AS (
  SELECT
    *,
    LAG("Total_Revenue") OVER (
      PARTITION BY "Category"
      ORDER BY "Year", "Month"
    ) AS "Previous_Total_Revenue",
    LAG("Total_Completed_Orders") OVER (
      PARTITION BY "Category"
      ORDER BY "Year", "Month"
    ) AS "Previous_Total_Orders"
  FROM category_monthly
)
SELECT
  "Year",
  "Month",
  "Category",
  "Total_Revenue",
  "Total_Completed_Orders",
  (("Total_Revenue" - "Previous_Total_Revenue") / NULLIF("Previous_Total_Revenue", 0)) * 100 AS "Revenue_MoM_Growth(%)",
  (("Total_Completed_Orders" - "Previous_Total_Orders") / NULLIF("Previous_Total_Orders", 0)) * 100 AS "Orders_MoM_Growth(%)",
  "Total_Cost",
  ("Total_Revenue" - "Total_Cost") AS "Total_Profit",
  (("Total_Revenue" - "Total_Cost") / NULLIF("Total_Cost", 0)) AS "Profit_to_Cost_Ratio"
FROM category_monthly_with_lag
ORDER BY
  "Year",
  "Month",
  "Category";