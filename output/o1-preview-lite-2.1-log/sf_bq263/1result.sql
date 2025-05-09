SELECT
  TO_VARCHAR(DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)), 'Mon-YYYY') AS "Month",
  ROUND(SUM(oi."sale_price"), 4) AS "Total_Sales",
  ROUND(SUM(ii."cost"), 4) AS "Total_Costs",
  COUNT(DISTINCT oi."order_id") AS "Completed_Order_Count",
  ROUND(SUM(oi."sale_price" - ii."cost"), 4) AS "Profit",
  ROUND(SUM(oi."sale_price" - ii."cost") / SUM(oi."sale_price"), 4) AS "Profit_Margin"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p ON oi."product_id" = p."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii ON oi."inventory_item_id" = ii."id"
WHERE p."category" = 'Sleep & Lounge'
  AND oi."status" = 'Complete'
  AND TO_TIMESTAMP(oi."created_at" / 1000000) >= '2023-01-01'
  AND TO_TIMESTAMP(oi."created_at" / 1000000) < '2024-01-01'
GROUP BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000))
ORDER BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000));