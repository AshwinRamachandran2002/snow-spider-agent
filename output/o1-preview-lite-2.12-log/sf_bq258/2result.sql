SELECT
  "Year",
  "Month",
  "Category",
  "Total_Revenue",
  "Total_Completed_Orders",
  ROUND((
    ("Total_Revenue" - LAG("Total_Revenue") OVER (PARTITION BY "Category" ORDER BY "Year", "Month")) 
    / NULLIF(LAG("Total_Revenue") OVER (PARTITION BY "Category" ORDER BY "Year", "Month"), 0)
  ) * 100, 4) AS "Revenue_MoM_Growth(%)",
  ROUND((
    ("Total_Completed_Orders" - LAG("Total_Completed_Orders") OVER (PARTITION BY "Category" ORDER BY "Year", "Month")) 
    / NULLIF(LAG("Total_Completed_Orders") OVER (PARTITION BY "Category" ORDER BY "Year", "Month"), 0)
  ) * 100, 4) AS "Orders_MoM_Growth(%)",
  "Total_Cost",
  "Total_Profit",
  ROUND(("Total_Profit" / NULLIF("Total_Cost", 0)), 4) AS "Profit_to_Cost_Ratio"
FROM (
  SELECT
    EXTRACT(YEAR FROM TO_TIMESTAMP(oi."delivered_at" / 1000000)) AS "Year",
    EXTRACT(MONTH FROM TO_TIMESTAMP(oi."delivered_at" / 1000000)) AS "Month",
    p."category" AS "Category",
    SUM(oi."sale_price") AS "Total_Revenue",
    COUNT(DISTINCT oi."order_id") AS "Total_Completed_Orders",
    SUM(p."cost") AS "Total_Cost",
    SUM(oi."sale_price" - p."cost") AS "Total_Profit"
  FROM
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS oi
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS p ON oi."product_id" = p."id"
  WHERE
    oi."status" = 'Complete'
    AND TO_TIMESTAMP(oi."delivered_at" / 1000000) < '2022-01-01'
  GROUP BY
    EXTRACT(YEAR FROM TO_TIMESTAMP(oi."delivered_at" / 1000000)),
    EXTRACT(MONTH FROM TO_TIMESTAMP(oi."delivered_at" / 1000000)),
    p."category"
) sub
ORDER BY
  "Year", "Month", "Category";