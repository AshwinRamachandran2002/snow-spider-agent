SELECT
  TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1e6)), 'Mon-YYYY') AS "Month",
  ROUND(SUM(oi."sale_price"), 4) AS "Total_Sales",
  ROUND(SUM(ii."cost"), 4) AS "Total_Cost",
  COUNT(DISTINCT o."order_id") AS "Number_of_Complete_Orders",
  ROUND(SUM(oi."sale_price" - ii."cost"), 4) AS "Total_Profit",
  ROUND(SUM(oi."sale_price" - ii."cost") / NULLIF(SUM(ii."cost"), 0), 4) AS "Profit_to_Cost_Ratio"
FROM
  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi ON o."order_id" = oi."order_id"
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii ON oi."inventory_item_id" = ii."id"
WHERE
  o."status" = 'Complete' AND
  o."created_at" BETWEEN 1672531200000000 AND 1704067199000000 AND
  ii."product_category" = 'Sleep & Lounge'
GROUP BY
  1
ORDER BY
  TO_DATE("Month", 'Mon-YYYY');