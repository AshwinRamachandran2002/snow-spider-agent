SELECT
  oi."seller_id" AS "Seller_ID",
  ROUND(SUM(oi."price"), 4) AS "Total_Sales",
  ROUND(AVG(oi."price"), 4) AS "Average_Item_Price",
  ROUND(AVG(r."review_score"), 4) AS "Average_Review_Score",
  ROUND(AVG(DATEDIFF('hour', TRY_TO_TIMESTAMP(o."order_approved_at"), TRY_TO_TIMESTAMP(o."order_delivered_carrier_date"))), 4) AS "Packing_Time"
FROM
  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_ITEMS" oi
JOIN
  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDERS" o
  ON oi."order_id" = o."order_id"
JOIN
  ELECTRONIC_SALES.ELECTRONIC_SALES."ORDER_REVIEWS" r
  ON o."order_id" = r."order_id"
WHERE
  TRY_TO_TIMESTAMP(o."order_approved_at") IS NOT NULL
  AND TRY_TO_TIMESTAMP(o."order_delivered_carrier_date") IS NOT NULL
GROUP BY
  oi."seller_id"
HAVING
  COUNT(*) > 100
ORDER BY
  "Total_Sales" DESC NULLS LAST;