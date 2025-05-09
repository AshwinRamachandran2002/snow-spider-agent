WITH most_preferred_payment AS (
  SELECT t."product_category_name", t."payment_type"
  FROM (
    SELECT p."product_category_name", pay."payment_type", COUNT(*) AS "payment_count",
           ROW_NUMBER() OVER (
             PARTITION BY p."product_category_name"
             ORDER BY COUNT(*) DESC NULLS LAST
           ) AS "rank"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" o
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_PRODUCTS" p
      ON o."product_id" = p."product_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" pay
      ON o."order_id" = pay."order_id"
    GROUP BY p."product_category_name", pay."payment_type"
  ) t
  WHERE t."rank" = 1
),
total_payments AS (
  SELECT "order_id", SUM("payment_installments") AS "total_installments"
  FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS"
  GROUP BY "order_id"
),
order_total_installments AS (
  SELECT DISTINCT
    p."product_category_name",
    o."order_id",
    pay."payment_type",
    total_payments."total_installments"
  FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_ITEMS" o
  JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_PRODUCTS" p
    ON o."product_id" = p."product_id"
  JOIN total_payments
    ON o."order_id" = total_payments."order_id"
  JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" pay
    ON o."order_id" = pay."order_id"
)
SELECT
  mpp."product_category_name" AS "Product_Category_Name",
  mpp."payment_type" AS "Payment_Method",
  ROUND(AVG(oti."total_installments"), 4) AS "Average_Total_Payment_Count"
FROM order_total_installments oti
JOIN most_preferred_payment mpp
  ON oti."product_category_name" = mpp."product_category_name"
    AND oti."payment_type" = mpp."payment_type"
GROUP BY mpp."product_category_name", mpp."payment_type"
ORDER BY mpp."product_category_name" NULLS LAST;