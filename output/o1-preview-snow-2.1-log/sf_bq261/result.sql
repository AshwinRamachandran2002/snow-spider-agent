WITH monthly_profit AS (
  SELECT 
    DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6)) AS "Month",
    oi."product_id" AS "Product_ID",
    ROUND(SUM(ii."cost"), 4) AS "Total_Cost",
    ROUND(SUM(oi."sale_price" - ii."cost"), 4) AS "Total_Profit"
  FROM 
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS oi
  JOIN 
    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" AS ii 
      ON oi."inventory_item_id" = ii."id"
  WHERE 
    TO_TIMESTAMP(oi."created_at" / 1e6) < '2024-01-01'
  GROUP BY 
    "Month", oi."product_id"
)
SELECT 
  "Month", 
  "Product_ID", 
  "Total_Cost", 
  "Total_Profit"
FROM (
  SELECT 
    mp.*,
    RANK() OVER (
      PARTITION BY mp."Month" 
      ORDER BY mp."Total_Profit" DESC NULLS LAST
    ) AS "Profit_Rank"
  FROM 
    monthly_profit mp
)
WHERE 
  "Profit_Rank" = 1
ORDER BY 
  "Month";