WITH monthly_data AS (
  SELECT
    TO_VARCHAR(TO_TIMESTAMP(oi."created_at" / 1e6), 'YYYY-MM') AS "Month",
    p."category" AS "Product_Category",
    COUNT(DISTINCT oi."order_id") AS "Total_Orders",
    SUM(oi."sale_price") AS "Total_Revenue",
    SUM(oi."sale_price" - p."cost") AS "Total_Profit"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p ON oi."product_id" = p."id"
  WHERE TO_VARCHAR(TO_TIMESTAMP(oi."created_at" / 1e6), 'YYYY-MM') BETWEEN '2019-06' AND '2019-12'
  GROUP BY "Month", "Product_Category"
),
june_data AS (
  SELECT 
    "Product_Category",
    "Total_Orders" AS "June_Total_Orders",
    "Total_Revenue" AS "June_Total_Revenue",
    "Total_Profit" AS "June_Total_Profit"
  FROM monthly_data
  WHERE "Month" = '2019-06'
)
SELECT
  md."Month",
  md."Product_Category",
  md."Total_Orders",
  md."Total_Revenue",
  md."Total_Profit",
  CASE 
    WHEN jd."June_Total_Orders" IS NOT NULL AND jd."June_Total_Orders" != 0 THEN 
      ROUND(((md."Total_Orders" - jd."June_Total_Orders") / jd."June_Total_Orders") * 100, 4)
    ELSE NULL 
  END AS "MoM_Growth_Orders(%)",
  CASE 
    WHEN jd."June_Total_Revenue" IS NOT NULL AND jd."June_Total_Revenue" != 0 THEN 
      ROUND(((md."Total_Revenue" - jd."June_Total_Revenue") / jd."June_Total_Revenue") * 100, 4)
    ELSE NULL 
  END AS "MoM_Growth_Revenue(%)",
  CASE 
    WHEN jd."June_Total_Profit" IS NOT NULL AND jd."June_Total_Profit" != 0 THEN 
      ROUND(((md."Total_Profit" - jd."June_Total_Profit") / jd."June_Total_Profit") * 100, 4)
    ELSE NULL 
  END AS "MoM_Growth_Profit(%)"
FROM monthly_data md
LEFT JOIN june_data jd ON md."Product_Category" = jd."Product_Category"
WHERE md."Month" BETWEEN '2019-07' AND '2019-12'
ORDER BY md."Month", md."Product_Category";